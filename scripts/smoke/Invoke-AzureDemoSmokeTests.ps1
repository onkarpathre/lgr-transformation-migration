[CmdletBinding()]
param(
    [Parameter(Mandatory)] [uri] $WebBaseUri,
    [uri] $ApiPublicUri,
    [Parameter(Mandatory)] [string] $ExpectedCommit,
    [Parameter(Mandatory)] [string] $ArtifactManifest,
    [Parameter(Mandatory)] [string] $EvidenceDirectory,
    [string] $PrerequisiteEvidenceDirectory,
    [switch] $Execute
)

$ErrorActionPreference = 'Stop'
if ($WebBaseUri.Scheme -ne 'https' -or -not $WebBaseUri.Host.EndsWith('.azurewebsites.net', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Smoke tests refuse a non-HTTPS or non-App-Service web target.'
}
$manifestPath = (Resolve-Path -LiteralPath $ArtifactManifest).Path
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
$catalog = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'smoke-checks.json') -Raw | ConvertFrom-Json
if (-not $Execute) {
    $catalog | Format-Table id, mode, title
    Write-Output 'Plan only. No endpoint, Azure, SQL, Key Vault, Storage, Entra or Azure DevOps call was made.'
    return
}

New-Item -ItemType Directory -Path $EvidenceDirectory -Force | Out-Null
$results = [Collections.Generic.List[object]]::new()
function Invoke-WebRequestSafe([uri] $Uri, [string] $Method = 'GET', [hashtable] $Headers = @{}) {
    try {
        $response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -MaximumRedirection 0 -SkipHttpErrorCheck -TimeoutSec 30
        return $response
    } catch { throw "Smoke HTTP request failed without exposing request headers: $($Uri.AbsolutePath)" }
}
function Add-Result([string] $Id, [bool] $Passed, [string] $Summary) {
    $record = [ordered]@{ id = $Id; status = $(if ($Passed) { 'PASS' } else { 'FAIL' }); checkedAtUtc = [DateTimeOffset]::UtcNow.ToString('O'); sourceCommit = $ExpectedCommit; artifactManifestSha256 = $manifestHash; site = $WebBaseUri.Host; summary = $Summary }
    $record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $EvidenceDirectory "$Id.json") -Encoding UTF8
    $results.Add([pscustomobject]$record)
    if (-not $Passed) { throw "$Id failed: $Summary" }
}
function Require-Evidence([string] $Id) {
    if ([string]::IsNullOrWhiteSpace($PrerequisiteEvidenceDirectory)) { Add-Result $Id $false 'Commit-bound protected evidence was not supplied.'; return }
    $path = Join-Path $PrerequisiteEvidenceDirectory "$Id.json"
    if (-not (Test-Path -LiteralPath $path)) { Add-Result $Id $false 'Required protected evidence file is absent.'; return }
    $evidence = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $valid = $evidence.status -eq 'PASS' -and $evidence.sourceCommit -eq $ExpectedCommit -and $evidence.artifactManifestSha256 -eq $manifestHash
    Add-Result $Id $valid 'Protected specialist/tester evidence validated against commit and artifact manifest.'
}

foreach ($check in $catalog) {
    switch ($check.id) {
        'SMK-01' {
            $http = [uri]::new($WebBaseUri.AbsoluteUri.Replace('https://', 'http://'))
            $response = Invoke-WebRequestSafe $http
            Add-Result $check.id ($response.StatusCode -in 301,302,307,308 -and $response.Headers.Location -like 'https://*') 'HTTP redirects to HTTPS; lower-TLS proof remains in protected platform evidence.'
        }
        'SMK-02' {
            $health = Invoke-WebRequestSafe ([uri]::new($WebBaseUri, '/health'))
            $deep = Invoke-WebRequestSafe ([uri]::new($WebBaseUri, '/inventory/servers'))
            Add-Result $check.id ($health.StatusCode -eq 200 -and $deep.StatusCode -eq 200) 'Web health and direct deep route returned 200.'
        }
        'SMK-03' {
            $root = Invoke-WebRequestSafe $WebBaseUri
            $match = [regex]::Match($root.Content, '/_next/static/[^"'']+\.(?:js|css)')
            if (-not $match.Success) { Add-Result $check.id $false 'No hashed Next static asset was found.'; break }
            $asset = Invoke-WebRequestSafe ([uri]::new($WebBaseUri, $match.Value))
            Add-Result $check.id ($asset.StatusCode -eq 200 -and $asset.RawContentLength -gt 0 -and $asset.Headers.'Content-Type') 'Hashed static asset returned non-empty content and a MIME type.'
        }
        'SMK-04' {
            if ($null -eq $ApiPublicUri) { Require-Evidence $check.id; break }
            $response = Invoke-WebRequestSafe $ApiPublicUri
            Add-Result $check.id ($response.StatusCode -in 401,403,404) 'API public hostname denied access without metadata.'
        }
        'SMK-08' {
            $baseline = Invoke-WebRequestSafe ([uri]::new($WebBaseUri, '/api/v1/session/capabilities'))
            $probe = Invoke-WebRequestSafe ([uri]::new($WebBaseUri, '/api/v1/session/capabilities')) 'GET' @{ 'X-Lgr-Test-Principal' = 'must-not-be-trusted'; 'X-Roles' = 'PlatformAdministrator' }
            Add-Result $check.id ($baseline.StatusCode -eq $probe.StatusCode -and $probe.Content -notmatch 'must-not-be-trusted|PlatformAdministrator') 'Prohibited identity headers did not change anonymous authorization or echo values.'
        }
        'SMK-10' {
            $response = Invoke-WebRequestSafe ([uri]::new($WebBaseUri, '/api/v1/session/capabilities')) 'OPTIONS' @{ Origin = 'https://unapproved.invalid'; 'Access-Control-Request-Method' = 'GET'; 'Access-Control-Request-Headers' = 'X-Roles' }
            Add-Result $check.id (-not $response.Headers.'Access-Control-Allow-Origin') 'Unapproved origin received no CORS grant.'
        }
        'SMK-11' {
            $response = Invoke-WebRequestSafe $WebBaseUri
            $required = @('Strict-Transport-Security','Content-Security-Policy','X-Content-Type-Options','Referrer-Policy','Permissions-Policy','X-Frame-Options')
            Add-Result $check.id (-not ($required | Where-Object { -not $response.Headers.$_ })) 'Required web security headers are present.'
        }
        'SMK-12' {
            $response = Invoke-WebRequestSafe ([uri]::new($WebBaseUri, '/health'))
            Add-Result $check.id ($response.StatusCode -eq 200) 'Ready path is healthy; controlled outage and alert proof is supplied separately.'
        }
        'SMK-20' {
            $manifest = Get-Content -LiteralPath $manifestPath -Raw
            $source = Get-ChildItem (Join-Path $PSScriptRoot '..\..\src') -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/](node_modules|bin|obj|\.next)[\\/]' }
            $forbidden = $source | Select-String -Pattern 'Password=|\.publishsettings|Authentication__Mode=LocalTest'
            Add-Result $check.id (-not $forbidden -and $manifest -notmatch 'appsettings\.LocalTest\.json|\.env') 'Source/artifact manifest scan found no credential, LocalTest deployment setting, .env or publish profile.'
        }
        default { Require-Evidence $check.id }
    }
}
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'smoke-summary.json') -Encoding UTF8
Write-Output "Completed $($results.Count) commit-bound smoke checks."
