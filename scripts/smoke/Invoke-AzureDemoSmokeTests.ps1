[CmdletBinding()]
param(
    [Parameter(Mandatory)] [uri] $WebBaseUri,
    [uri] $ApiPublicUri,
    [Parameter(Mandatory)] [string] $VerifiedWebHost,
    [Parameter(Mandatory)] [string] $VerifiedApiHost,
    [Parameter(Mandatory)] [string] $TargetSubscriptionId,
    [Parameter(Mandatory)] [string] $TargetResourceGroupName,
    [Parameter(Mandatory)] [string] $TargetWebAppName,
    [Parameter(Mandatory)] [string] $TargetApiAppName,
    [Parameter(Mandatory)] [ValidateSet('production', 'staging')] [string] $TargetSlotName,
    [Parameter(Mandatory)] [string] $ExpectedCommit,
    [Parameter(Mandatory)] [string] $ArtifactManifest,
    [Parameter(Mandatory)] [string] $EvidenceDirectory,
    [string] $ProtectedEvidenceDirectory,
    [string] $InfrastructureDeploymentId,
    [string] $PipelineDefinition,
    [string] $PipelineRunId,
    [switch] $Execute
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
. (Join-Path $PSScriptRoot 'AzureDemoSmokeUtilities.ps1')
. (Join-Path $PSScriptRoot 'AzureDemoSmokeEvidenceContract.ps1')

$approvedSubscriptionId = '633398e2-6c00-4bb7-a576-2db0d210ee77'
$approvedResourceGroupName = 'Onkar.Pathre'
$approvedWebAppName = 'app-mtp-web-dev-uks-001'
$approvedApiAppName = 'app-mtp-api-dev-uks-001'
if (-not [string]::Equals($TargetSubscriptionId, $approvedSubscriptionId, [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($TargetResourceGroupName, $approvedResourceGroupName, [StringComparison]::Ordinal) -or
    -not [string]::Equals($TargetWebAppName, $approvedWebAppName, [StringComparison]::Ordinal) -or
    -not [string]::Equals($TargetApiAppName, $approvedApiAppName, [StringComparison]::Ordinal)) {
    throw 'Smoke tests refuse a subscription, resource group or application identity outside the exact approved MTP target.'
}
if (-not (Test-AzureDemoDefaultHostName -HostName $VerifiedWebHost -AppName $TargetWebAppName -SlotName $TargetSlotName) -or
    -not (Test-AzureDemoDefaultHostName -HostName $VerifiedApiHost -AppName $TargetApiAppName -SlotName $TargetSlotName)) {
    throw 'Smoke tests refuse malformed or substituted verified hostnames.'
}
Assert-AzureDemoSmokeUriTarget -Uri $WebBaseUri -VerifiedHost $VerifiedWebHost -ExpectedScheme https -RequireRootPath
if ($null -ne $ApiPublicUri) {
    Assert-AzureDemoSmokeUriTarget -Uri $ApiPublicUri -VerifiedHost $VerifiedApiHost -ExpectedScheme https -RequireRootPath
}

$manifestPath = (Resolve-Path -LiteralPath $ArtifactManifest).Path
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
try { $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -ErrorAction Stop } catch { throw 'Smoke tests require a valid immutable deployment artifact manifest.' }
if ($ExpectedCommit -cnotmatch '^[0-9a-f]{40}$' -or $manifest.schemaVersion -cne '1' -or $manifest.sourceCommit -cne $ExpectedCommit) {
    throw 'Smoke tests require an immutable deployment artifact manifest for the exact source commit.'
}
$catalog = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'smoke-checks.json') -Raw | ConvertFrom-Json
$expectedCatalog = @(1..22 | ForEach-Object { 'SMK-{0:D2}' -f $_ })
$actualCatalog = @(foreach ($catalogItem in $catalog) { [string] $catalogItem.id })
if (($actualCatalog -join '|') -cne ($expectedCatalog -join '|')) {
    throw 'Smoke check catalogue must contain SMK-01 through SMK-22 exactly once in approved order.'
}
if (-not $Execute) {
    $catalog | Format-Table id, mode, title
    Write-Output 'Plan only. No endpoint, Azure, SQL, Key Vault, Storage, Entra or Azure DevOps call was made.'
    return
}
if ([string]::IsNullOrWhiteSpace($InfrastructureDeploymentId) -or
    [string]::IsNullOrWhiteSpace($PipelineDefinition) -or
    [string]::IsNullOrWhiteSpace($PipelineRunId)) {
    throw 'Executed smoke checks require exact infrastructure-deployment and pipeline-run provenance.'
}

New-Item -ItemType Directory -Path $EvidenceDirectory -Force | Out-Null
$results = [Collections.Generic.List[object]]::new()

function New-SafeCheckDiagnostic {
    param([string] $CheckId, [string] $Path = '/', [string] $Category = 'check-execution')
    return [pscustomobject][ordered]@{
        checkId = $CheckId
        scheme = $WebBaseUri.Scheme
        hostname = $VerifiedWebHost
        path = $Path
        httpStatus = $null
        exceptionCategory = $Category
    }
}

function Write-SafeRequestDiagnostic {
    param([object] $Diagnostic)
    $status = if ($null -eq $Diagnostic.httpStatus) { 'unavailable' } else { [string] $Diagnostic.httpStatus }
    Write-Output ("Smoke HTTP diagnostic: checkId={0}; scheme={1}; hostname={2}; path={3}; httpStatus={4}; exceptionCategory={5}." -f
        $Diagnostic.checkId, $Diagnostic.scheme, $Diagnostic.hostname, $Diagnostic.path, $status, $Diagnostic.exceptionCategory)
}

function Invoke-CheckedWebRequest {
    param(
        [string] $CheckId,
        [uri] $Uri,
        [string] $Method = 'GET',
        [hashtable] $Headers = @{},
        [ValidateSet('http', 'https')] [string] $ExpectedScheme = 'https'
    )
    Assert-AzureDemoSmokeUriTarget -Uri $Uri -VerifiedHost $VerifiedWebHost -ExpectedScheme $ExpectedScheme
    $requestResult = Invoke-AzureDemoSmokeHttpRequest -CheckId $CheckId -Uri $Uri -Method $Method -Headers $Headers
    Write-SafeRequestDiagnostic $requestResult.Diagnostic
    return $requestResult
}

function Invoke-CheckedApiRequest {
    param([string] $CheckId, [uri] $Uri)
    Assert-AzureDemoSmokeUriTarget -Uri $Uri -VerifiedHost $VerifiedApiHost -ExpectedScheme https
    $requestResult = Invoke-AzureDemoSmokeHttpRequest -CheckId $CheckId -Uri $Uri
    Write-SafeRequestDiagnostic $requestResult.Diagnostic
    return $requestResult
}

function Get-ProtectedEvidenceResult {
    param([string] $Id)
    if ([string]::IsNullOrWhiteSpace($ProtectedEvidenceDirectory)) {
        return [pscustomobject]@{ Passed = $false; Summary = 'Protected runtime evidence bundle was not supplied.' }
    }
    $path = Join-Path $ProtectedEvidenceDirectory "$Id.json"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return [pscustomobject]@{ Passed = $false; Summary = 'Required protected runtime evidence record is absent.' }
    }
    try {
        Assert-AzureDemoSmokeEvidence -EvidencePath $path -EvidenceRoot $ProtectedEvidenceDirectory -CheckId $Id `
            -ExpectedSourceCommit $ExpectedCommit -ExpectedArtifactManifestSha256 $manifestHash `
            -ExpectedInfrastructureDeploymentId $InfrastructureDeploymentId -ExpectedPipelineDefinition $PipelineDefinition -ExpectedPipelineRunId $PipelineRunId `
            -ExpectedSubscriptionId $TargetSubscriptionId -ExpectedResourceGroup $TargetResourceGroupName `
            -ExpectedWebApp $TargetWebAppName -ExpectedApiApp $TargetApiAppName -ExpectedSlot $TargetSlotName `
            -ExpectedWebHost $VerifiedWebHost -ExpectedApiHost $VerifiedApiHost | Out-Null
        return [pscustomobject]@{ Passed = $true; Summary = 'Protected runtime evidence, attachments, execution origin and exact target provenance validated.' }
    }
    catch {
        return [pscustomobject]@{ Passed = $false; Summary = 'Protected runtime evidence did not satisfy the approved execution and provenance contract.' }
    }
}

function Add-Result {
    param(
        [string] $Id,
        [bool] $Passed,
        [string] $Summary,
        [object[]] $Diagnostics = @()
    )
    $record = [ordered]@{
        id = $Id
        status = if ($Passed) { 'PASS' } else { 'FAIL' }
        checkedAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
        sourceCommit = $ExpectedCommit
        artifactManifestSha256 = $manifestHash
        infrastructureDeploymentId = $InfrastructureDeploymentId
        pipeline = [ordered]@{
            definition = $PipelineDefinition
            runId = $PipelineRunId
        }
        target = [ordered]@{
            subscriptionId = $TargetSubscriptionId.ToLowerInvariant()
            resourceGroup = $TargetResourceGroupName
            webApp = $TargetWebAppName
            apiApp = $TargetApiAppName
            slot = $TargetSlotName
            webHost = $VerifiedWebHost
            apiHost = $VerifiedApiHost
        }
        summary = $Summary
        diagnostics = @($Diagnostics)
    }
    $record | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $EvidenceDirectory "$Id.json") -Encoding UTF8
    $results.Add([pscustomobject]$record)
}

foreach ($check in $catalog) {
    try {
        switch ($check.id) {
            'SMK-01' {
                $httpBuilder = [UriBuilder]::new($WebBaseUri)
                $httpBuilder.Scheme = 'http'
                $httpBuilder.Port = 80
                $http = $httpBuilder.Uri
                $response = Invoke-CheckedWebRequest -CheckId $check.id -Uri $http -ExpectedScheme http
                $platformEvidence = Get-ProtectedEvidenceResult $check.id
                $redirectPassed = Test-AzureDemoHttpsRedirectResponse -RequestUri $http -RequestResult $response
                Add-Result $check.id ($redirectPassed -and $platformEvidence.Passed) ("HTTP-to-HTTPS redirect and protected lower-TLS evidence were both required. Evidence: {0}" -f $platformEvidence.Summary) @($response.Diagnostic)
            }
            'SMK-02' {
                $health = Invoke-CheckedWebRequest $check.id ([uri]::new($WebBaseUri, '/health'))
                $home = Invoke-CheckedWebRequest $check.id $WebBaseUri
                $deep = Invoke-CheckedWebRequest $check.id ([uri]::new($WebBaseUri, '/inventory/servers'))
                $passed = $health.TransportSucceeded -and $home.TransportSucceeded -and $deep.TransportSucceeded -and
                    $health.StatusCode -eq 200 -and $home.StatusCode -eq 200 -and $deep.StatusCode -eq 200 -and
                    $home.RawContentLength -gt 0 -and $deep.RawContentLength -gt 0
                Add-Result $check.id $passed 'Web health, home and direct deep route must all return non-empty successful responses.' @($health.Diagnostic, $home.Diagnostic, $deep.Diagnostic)
            }
            'SMK-03' {
                $root = Invoke-CheckedWebRequest $check.id $WebBaseUri
                if (-not $root.TransportSucceeded -or $root.StatusCode -ne 200) {
                    Add-Result $check.id $false 'Web root did not return a usable 200 response.' @($root.Diagnostic)
                    break
                }
                $match = [regex]::Match($root.Content, '/_next/static/[^"'']*[a-f0-9]{8,}[^"'']*\.(?:js|css)', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
                if (-not $match.Success) {
                    Add-Result $check.id $false 'No hashed Next static asset was found.' @($root.Diagnostic)
                    break
                }
                $assetUri = [uri]::new($WebBaseUri, $match.Value)
                $asset = Invoke-CheckedWebRequest $check.id $assetUri
                $contentType = Get-AzureDemoSmokeHeaderValue -Response $asset -Name 'Content-Type'
                $cacheControl = Get-AzureDemoSmokeHeaderValue -Response $asset -Name 'Cache-Control'
                $contentTypePassed = $contentType -match '^(?:text/css|application/(?:javascript|x-javascript)|text/javascript)(?:;|$)'
                Add-Result $check.id ($asset.TransportSucceeded -and $asset.StatusCode -eq 200 -and $asset.RawContentLength -gt 0 -and $contentTypePassed -and $cacheControl -match '(?i)\bpublic\b' -and $cacheControl -match '(?i)\bimmutable\b') 'Hashed static asset must return non-empty content with the correct JS/CSS MIME type and immutable public cache policy.' @($root.Diagnostic, $asset.Diagnostic)
            }
            'SMK-04' {
                if ($null -eq $ApiPublicUri) {
                    $protectedEvidence = Get-ProtectedEvidenceResult $check.id
                    Add-Result $check.id $protectedEvidence.Passed $protectedEvidence.Summary
                    break
                }
                Assert-AzureDemoSmokeUriTarget -Uri $ApiPublicUri -VerifiedHost $VerifiedApiHost -ExpectedScheme https -RequireRootPath
                $response = Invoke-AzureDemoSmokeHttpRequest -CheckId $check.id -Uri $ApiPublicUri
                Write-SafeRequestDiagnostic $response.Diagnostic
                Add-Result $check.id ($response.TransportSucceeded -and $response.StatusCode -in 401, 403, 404) 'API public hostname must deny access without metadata.' @($response.Diagnostic)
            }
            'SMK-08' {
                $capabilitiesUri = [uri]::new($WebBaseUri, '/api/v1/session/capabilities')
                $baseline = Invoke-CheckedWebRequest $check.id $capabilitiesUri
                $probe = Invoke-CheckedWebRequest $check.id $capabilitiesUri 'GET' @{ 'X-Lgr-Test-Principal' = 'must-not-be-trusted'; 'X-Roles' = 'PlatformAdministrator' }
                $protectedEvidence = Get-ProtectedEvidenceResult $check.id
                $automatedPassed = $baseline.TransportSucceeded -and $probe.TransportSucceeded -and $baseline.StatusCode -eq $probe.StatusCode -and $probe.Content -notmatch 'must-not-be-trusted|PlatformAdministrator'
                Add-Result $check.id ($automatedPassed -and $protectedEvidence.Passed) ("Automated prohibited-header behavior and protected redaction evidence were both required. Evidence: {0}" -f $protectedEvidence.Summary) @($baseline.Diagnostic, $probe.Diagnostic)
            }
            'SMK-10' {
                $capabilitiesUri = [uri]::new($WebBaseUri, '/api/v1/session/capabilities')
                $originProbe = Invoke-CheckedWebRequest $check.id $capabilitiesUri 'OPTIONS' @{ Origin = 'https://unapproved.invalid'; 'Access-Control-Request-Method' = 'GET' }
                $methodProbe = Invoke-CheckedWebRequest $check.id $capabilitiesUri 'OPTIONS' @{ Origin = $WebBaseUri.GetLeftPart([UriPartial]::Authority); 'Access-Control-Request-Method' = 'TRACE' }
                $headerProbe = Invoke-CheckedWebRequest $check.id $capabilitiesUri 'OPTIONS' @{ Origin = $WebBaseUri.GetLeftPart([UriPartial]::Authority); 'Access-Control-Request-Method' = 'GET'; 'Access-Control-Request-Headers' = 'X-Roles,X-Customer-Id' }
                $sameOrigin = Invoke-CheckedWebRequest $check.id $capabilitiesUri
                $noGrant = @($originProbe, $methodProbe, $headerProbe) | Where-Object { -not [string]::IsNullOrWhiteSpace((Get-AzureDemoSmokeHeaderValue -Response $_ -Name 'Access-Control-Allow-Origin')) }
                $sameOriginPathExists = $sameOrigin.TransportSucceeded -and $sameOrigin.StatusCode -notin 404, 500, 502, 503, 504
                Add-Result $check.id ($originProbe.TransportSucceeded -and $methodProbe.TransportSucceeded -and $headerProbe.TransportSucceeded -and $noGrant.Count -eq 0 -and $sameOriginPathExists) 'Unapproved origin, method and authority headers must receive no CORS grant, while the same-origin proxy path must remain reachable.' @($originProbe.Diagnostic, $methodProbe.Diagnostic, $headerProbe.Diagnostic, $sameOrigin.Diagnostic)
            }
            'SMK-11' {
                $response = Invoke-CheckedWebRequest $check.id $WebBaseUri
                $hsts = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'Strict-Transport-Security'
                $csp = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'Content-Security-Policy'
                $nosniff = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'X-Content-Type-Options'
                $referrer = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'Referrer-Policy'
                $permissions = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'Permissions-Policy'
                $frame = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'X-Frame-Options'
                $apiLive = Invoke-CheckedApiRequest $check.id ([uri] "https://$VerifiedApiHost/health/live")
                $apiCsp = Get-AzureDemoSmokeHeaderValue -Response $apiLive -Name 'Content-Security-Policy'
                $apiPassed = $apiLive.TransportSucceeded -and $apiLive.StatusCode -eq 200 -and
                    (Get-AzureDemoSmokeHeaderValue -Response $apiLive -Name 'X-Content-Type-Options') -ceq 'nosniff' -and
                    (Get-AzureDemoSmokeHeaderValue -Response $apiLive -Name 'Referrer-Policy') -ceq 'no-referrer' -and
                    (Get-AzureDemoSmokeHeaderValue -Response $apiLive -Name 'X-Frame-Options') -ceq 'DENY' -and
                    $apiCsp -match "(?i)default-src\s+'none'" -and $apiCsp -match "(?i)frame-ancestors\s+'none'"
                $passed = $response.TransportSucceeded -and $response.StatusCode -eq 200 -and
                    $hsts -match '(?i)\bmax-age=31536000\b' -and $csp -match "(?i)frame-ancestors\s+'none'" -and
                    $nosniff -ceq 'nosniff' -and $referrer -ceq 'no-referrer' -and -not [string]::IsNullOrWhiteSpace($permissions) -and $frame -ceq 'DENY' -and $apiPassed
                Add-Result $check.id $passed 'Required web and private API HSTS/frame/MIME/referrer/permissions policies must match the approved values.' @($response.Diagnostic, $apiLive.Diagnostic)
            }
            'SMK-12' {
                $response = Invoke-CheckedWebRequest $check.id ([uri]::new($WebBaseUri, '/health'))
                $protectedEvidence = Get-ProtectedEvidenceResult $check.id
                Add-Result $check.id ($response.TransportSucceeded -and $response.StatusCode -eq 200 -and $protectedEvidence.Passed) ("Healthy ready path and protected controlled-outage/alert evidence were both required. Evidence: {0}" -f $protectedEvidence.Summary) @($response.Diagnostic)
            }
            'SMK-20' {
                $manifestText = Get-Content -LiteralPath $manifestPath -Raw
                $source = Get-ChildItem (Join-Path $PSScriptRoot '..\..\src') -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/](node_modules|bin|obj|\.next)[\\/]' }
                $forbidden = $source | Select-String -Pattern 'Password=|\.publishsettings|Authentication__Mode=LocalTest'
                $manifestPaths = @($manifest.artifacts | ForEach-Object { [string] $_.path })
                $forbiddenManifestPath = @($manifestPaths | Where-Object { $_ -match '(?i)(?:^|/)(?:appsettings\.LocalTest\.json|\.env(?:\.|$)|.*\.publishsettings|tests?|node_modules)(?:/|$)' })
                $lock = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\..\src\web\package-lock.json') -Raw | ConvertFrom-Json
                $mockerVersion = [string] $lock.packages.'node_modules/@vitest/mocker'.version
                $vitestVersion = [string] $lock.packages.'node_modules/vitest'.version
                Add-Result $check.id (-not $forbidden -and $forbiddenManifestPath.Count -eq 0 -and $manifestText -notmatch '(?i)appsettings\.LocalTest\.json|(?:^|[/"])\.env(?:[./"]|$)|\.publishsettings' -and $mockerVersion -ceq '4.1.11' -and $vitestVersion -ceq '4.1.11') 'Exact-commit source, immutable manifest paths and patched frontend lock must contain no prohibited LocalTest, environment, credential, test or development artifact.'
            }
            default {
                $protectedEvidence = Get-ProtectedEvidenceResult $check.id
                Add-Result $check.id $protectedEvidence.Passed $protectedEvidence.Summary
            }
        }
    }
    catch {
        $diagnostic = New-SafeCheckDiagnostic -CheckId $check.id
        Write-SafeRequestDiagnostic $diagnostic
        Add-Result $check.id $false 'Check execution failed; unrestricted exception details were suppressed.' @($diagnostic)
    }
}

$summaryPath = Join-Path $EvidenceDirectory 'smoke-summary.json'
$results | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
$failedChecks = @($results | Where-Object { $_.status -eq 'FAIL' })
Write-Output ("Completed {0} commit-bound smoke checks; {1} failed." -f $results.Count, $failedChecks.Count)
if ($failedChecks.Count -gt 0) {
    throw ("Azure demo smoke checks failed: {0}. Safe evidence was retained." -f (($failedChecks | ForEach-Object { $_.id }) -join ', '))
}
