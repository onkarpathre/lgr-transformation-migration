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
$currentDiagnostics = $null
$currentRequestUri = $null
$executionPhase = 'check-orchestration'

function New-SafeCheckDiagnostic {
    param(
        [Parameter(Mandatory)] [string] $CheckId,
        [Parameter(Mandatory)] [string] $ExecutionPhase,
        [AllowNull()] [uri] $Uri,
        [AllowNull()] [object] $HttpStatus,
        [Parameter(Mandatory)] [string] $Category,
        [AllowNull()] [object] $ErrorObject,
        [string] $ErrorIdentifier = 'unavailable'
    )
    $exception = if ($ErrorObject -is [System.Management.Automation.ErrorRecord]) {
        $ErrorObject.Exception
    }
    elseif ($ErrorObject -is [Exception]) {
        $ErrorObject
    }
    else { $null }
    $location = Get-AzureDemoSmokeSafeInvocationLocation -ErrorObject $ErrorObject
    $identifier = if ($ErrorIdentifier -cne 'unavailable') {
        $ErrorIdentifier
    }
    else {
        Get-AzureDemoSmokeSafeErrorIdentifier -ErrorObject $ErrorObject
    }
    return [pscustomobject][ordered]@{
        checkId = $CheckId
        executionPhase = $ExecutionPhase
        scheme = if ($null -eq $Uri) { 'none' } else { $Uri.Scheme }
        hostname = if ($null -eq $Uri) { 'none' } else { $Uri.DnsSafeHost }
        path = if ($null -eq $Uri) { 'none' } else { $Uri.AbsolutePath }
        httpStatus = $HttpStatus
        exceptionType = if ($null -eq $exception) { 'none' } else { Get-AzureDemoSmokeSafeTypeName -InputObject $exception }
        errorIdentifier = $identifier
        exceptionCategory = $Category
        script = $location.script
        line = $location.line
    }
}

function Write-SafeRequestDiagnostic {
    param([Parameter(Mandatory)] [object] $Diagnostic)
    $status = if ($null -eq $Diagnostic.httpStatus) { 'unavailable' } else { [string] $Diagnostic.httpStatus }
    $line = if ($null -eq $Diagnostic.line) { 'unavailable' } else { [string] $Diagnostic.line }
    $script = if ([string]::IsNullOrWhiteSpace([string] $Diagnostic.script)) { 'unavailable' } else { [string] $Diagnostic.script }
    # Information output is visible in protected logs but cannot contaminate a
    # function's success-output return value.
    Write-Information ("Smoke diagnostic: checkId={0}; executionPhase={1}; scheme={2}; hostname={3}; path={4}; httpStatus={5}; exceptionType={6}; errorIdentifier={7}; exceptionCategory={8}; script={9}; line={10}." -f
        $Diagnostic.checkId, $Diagnostic.executionPhase, $Diagnostic.scheme, $Diagnostic.hostname, $Diagnostic.path, $status,
        $Diagnostic.exceptionType, $Diagnostic.errorIdentifier, $Diagnostic.exceptionCategory, $script, $line) -InformationAction Continue
}

function Add-CurrentDiagnostic {
    param([Parameter(Mandatory)] [object] $Diagnostic)
    if ($null -eq $currentDiagnostics) { throw 'Smoke diagnostic collection was not initialised.' }
    [void] $currentDiagnostics.Add($Diagnostic)
    Write-SafeRequestDiagnostic -Diagnostic $Diagnostic
}

function Invoke-CheckedWebRequest {
    param(
        [string] $CheckId,
        [uri] $Uri,
        [string] $Method = 'GET',
        [hashtable] $Headers = @{},
        [ValidateSet('http', 'https')] [string] $ExpectedScheme = 'https'
    )
    $script:currentRequestUri = $Uri
    $script:executionPhase = 'http-request'
    Assert-AzureDemoSmokeUriTarget -Uri $Uri -VerifiedHost $VerifiedWebHost -ExpectedScheme $ExpectedScheme
    $requestResult = Invoke-AzureDemoSmokeHttpRequest -CheckId $CheckId -Uri $Uri -Method $Method -Headers $Headers
    Add-CurrentDiagnostic -Diagnostic $requestResult.Diagnostic
    return $requestResult
}

function Invoke-CheckedApiRequest {
    param([string] $CheckId, [uri] $Uri)
    $script:currentRequestUri = $Uri
    $script:executionPhase = 'http-request'
    Assert-AzureDemoSmokeUriTarget -Uri $Uri -VerifiedHost $VerifiedApiHost -ExpectedScheme https
    $requestResult = Invoke-AzureDemoSmokeHttpRequest -CheckId $CheckId -Uri $Uri
    Add-CurrentDiagnostic -Diagnostic $requestResult.Diagnostic
    return $requestResult
}

function Get-ProtectedEvidenceResult {
    param([string] $Id)
    $script:executionPhase = 'evidence-validation'
    if ([string]::IsNullOrWhiteSpace($ProtectedEvidenceDirectory)) {
        $diagnostic = New-SafeCheckDiagnostic -CheckId $Id -ExecutionPhase 'evidence-validation' -Uri $null -HttpStatus $null `
            -Category 'missing-evidence' -ErrorObject $null -ErrorIdentifier 'EVIDENCE_BUNDLE_NOT_SUPPLIED'
        Add-CurrentDiagnostic -Diagnostic $diagnostic
        return [pscustomobject]@{ Passed = $false; FailureCategory = 'missing-evidence'; Summary = 'Protected runtime evidence bundle was not supplied.' }
    }
    $path = Join-Path $ProtectedEvidenceDirectory "$Id.json"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $diagnostic = New-SafeCheckDiagnostic -CheckId $Id -ExecutionPhase 'evidence-validation' -Uri $null -HttpStatus $null `
            -Category 'missing-evidence' -ErrorObject $null -ErrorIdentifier 'EVIDENCE_RECORD_ABSENT'
        Add-CurrentDiagnostic -Diagnostic $diagnostic
        return [pscustomobject]@{ Passed = $false; FailureCategory = 'missing-evidence'; Summary = 'Required protected runtime evidence record is absent.' }
    }
    try {
        Assert-AzureDemoSmokeEvidence -EvidencePath $path -EvidenceRoot $ProtectedEvidenceDirectory -CheckId $Id `
            -ExpectedSourceCommit $ExpectedCommit -ExpectedArtifactManifestSha256 $manifestHash `
            -ExpectedInfrastructureDeploymentId $InfrastructureDeploymentId -ExpectedPipelineDefinition $PipelineDefinition -ExpectedPipelineRunId $PipelineRunId `
            -ExpectedSubscriptionId $TargetSubscriptionId -ExpectedResourceGroup $TargetResourceGroupName `
            -ExpectedWebApp $TargetWebAppName -ExpectedApiApp $TargetApiAppName -ExpectedSlot $TargetSlotName `
            -ExpectedWebHost $VerifiedWebHost -ExpectedApiHost $VerifiedApiHost | Out-Null
        return [pscustomobject]@{ Passed = $true; FailureCategory = $null; Summary = 'Protected runtime evidence, attachments, execution origin and exact target provenance validated.' }
    }
    catch {
        $diagnostic = New-SafeCheckDiagnostic -CheckId $Id -ExecutionPhase 'evidence-validation' -Uri $null -HttpStatus $null `
            -Category 'rejected-evidence' -ErrorObject $_ -ErrorIdentifier (Get-AzureDemoSmokeSafeErrorIdentifier -ErrorObject $_ -Fallback 'EVIDENCE_REJECTED')
        Add-CurrentDiagnostic -Diagnostic $diagnostic
        return [pscustomobject]@{ Passed = $false; FailureCategory = 'rejected-evidence'; Summary = 'Protected runtime evidence did not satisfy the approved execution and provenance contract.' }
    }
}

function Add-Result {
    param(
        [string] $Id,
        [bool] $Passed,
        [string] $Summary,
        [string[]] $FailureCategories = @()
    )
    $script:executionPhase = 'result-serialization'
    $distinctFailureCategories = @($FailureCategories | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
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
        failureCategories = $distinctFailureCategories
        diagnostics = @($currentDiagnostics)
    }
    $record | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $EvidenceDirectory "$Id.json") -Encoding UTF8
    $results.Add([pscustomobject]$record)
}

function Get-HttpCheckFailureCategory {
    param(
        [Parameter(Mandatory)] [object[]] $Responses,
        [Parameter(Mandatory)] [bool] $AssertionPassed,
        [int[]] $ExpectedStatusCodes = @()
    )
    if (@($Responses | Where-Object { -not $_.TransportSucceeded }).Count -gt 0) { return 'transport-failure' }
    if ($ExpectedStatusCodes.Count -gt 0 -and
        @($Responses | Where-Object { $_.StatusCode -notin $ExpectedStatusCodes }).Count -gt 0) {
        return 'application-response-failure'
    }
    if (-not $AssertionPassed -and @($Responses | Where-Object { $_.StatusCode -ge 400 -and $_.StatusCode -le 599 }).Count -gt 0) {
        return 'application-response-failure'
    }
    if (-not $AssertionPassed) { return 'assertion-failure' }
    return $null
}

foreach ($check in $catalog) {
    $currentDiagnostics = [Collections.Generic.List[object]]::new()
    $currentRequestUri = $null
    $executionPhase = 'check-orchestration'
    try {
        switch ($check.id) {
            'SMK-01' {
                $httpBuilder = [UriBuilder]::new($WebBaseUri)
                $httpBuilder.Scheme = 'http'
                $httpBuilder.Port = 80
                $http = $httpBuilder.Uri
                $response = Invoke-CheckedWebRequest -CheckId $check.id -Uri $http -ExpectedScheme http
                $platformEvidence = Get-ProtectedEvidenceResult -Id $check.id
                $executionPhase = 'response-assertion'
                $redirectPassed = Test-AzureDemoHttpsRedirectResponse -RequestUri $http -RequestResult $response
                $categories = @(
                    Get-HttpCheckFailureCategory -Responses @($response) -AssertionPassed $redirectPassed
                    if (-not $platformEvidence.Passed) { $platformEvidence.FailureCategory }
                )
                Add-Result -Id $check.id -Passed ($redirectPassed -and $platformEvidence.Passed) `
                    -Summary ("HTTP-to-HTTPS redirect and protected lower-TLS evidence were both required. Evidence: {0}" -f $platformEvidence.Summary) `
                    -FailureCategories $categories
            }
            'SMK-02' {
                $health = Invoke-CheckedWebRequest -CheckId $check.id -Uri ([uri]::new($WebBaseUri, '/health'))
                $homeResponse = Invoke-CheckedWebRequest -CheckId $check.id -Uri $WebBaseUri
                $deep = Invoke-CheckedWebRequest -CheckId $check.id -Uri ([uri]::new($WebBaseUri, '/inventory/servers'))
                $notFound = Invoke-CheckedWebRequest -CheckId $check.id -Uri ([uri]::new($WebBaseUri, '/__azure_demo_route_that_must_not_exist__'))
                $executionPhase = 'response-assertion'
                $responses = @($health, $homeResponse, $deep, $notFound)
                $expectedStatusesPassed = $health.StatusCode -eq 200 -and $homeResponse.StatusCode -eq 200 -and
                    $deep.StatusCode -eq 200 -and $notFound.StatusCode -eq 404
                $authenticationContractPassed = @(@($homeResponse, $deep, $notFound) | Where-Object {
                        $_.Content -notmatch 'Sign in required' -or
                        $_.Content -notmatch 'Restricted synthetic non-production management demo' -or
                        $_.Content -match '(?i)(?:<title>\s*500\b|\bInternal Server Error\b|\bApplication Error\b)'
                    }).Count -eq 0
                $passed = @($responses | Where-Object { -not $_.TransportSucceeded }).Count -eq 0 -and
                    $expectedStatusesPassed -and $authenticationContractPassed -and
                    $homeResponse.RawContentLength -gt 0 -and $deep.RawContentLength -gt 0 -and $notFound.RawContentLength -gt 0
                $category = if (@($responses | Where-Object { -not $_.TransportSucceeded }).Count -gt 0) { 'transport-failure' }
                    elseif (-not $expectedStatusesPassed) { 'application-response-failure' }
                    elseif (-not $passed) { 'assertion-failure' }
                    else { $null }
                Add-Result -Id $check.id -Passed $passed -Summary 'Health must pass; home and deep routes must return the signed-out Entra gate; a nonexistent route must return the same bounded auth shell with HTTP 404 and never a generic 500 page.' -FailureCategories @($category)
            }
            'SMK-03' {
                $root = Invoke-CheckedWebRequest -CheckId $check.id -Uri $WebBaseUri
                $executionPhase = 'response-assertion'
                if (-not $root.TransportSucceeded -or $root.StatusCode -ne 200) {
                    $category = Get-HttpCheckFailureCategory -Responses @($root) -AssertionPassed $false -ExpectedStatusCodes @(200)
                    Add-Result -Id $check.id -Passed $false -Summary 'Web root did not return a usable 200 response.' -FailureCategories @($category)
                    break
                }
                $match = [regex]::Match($root.Content, '/_next/static/[^"'']*[a-f0-9]{8,}[^"'']*\.(?:js|css)', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
                if (-not $match.Success) {
                    Add-Result -Id $check.id -Passed $false -Summary 'No hashed Next static asset was found.' -FailureCategories @('assertion-failure')
                    break
                }
                $assetUri = [uri]::new($WebBaseUri, $match.Value)
                $asset = Invoke-CheckedWebRequest -CheckId $check.id -Uri $assetUri
                $executionPhase = 'response-assertion'
                $contentType = Get-AzureDemoSmokeHeaderValue -Response $asset -Name 'Content-Type'
                $cacheControl = Get-AzureDemoSmokeHeaderValue -Response $asset -Name 'Cache-Control'
                $contentTypePassed = $contentType -match '^(?:text/css|application/(?:javascript|x-javascript)|text/javascript)(?:;|$)'
                $passed = $asset.TransportSucceeded -and $asset.StatusCode -eq 200 -and $asset.RawContentLength -gt 0 -and $contentTypePassed -and $cacheControl -match '(?i)\bpublic\b' -and $cacheControl -match '(?i)\bimmutable\b'
                $category = Get-HttpCheckFailureCategory -Responses @($asset) -AssertionPassed $passed -ExpectedStatusCodes @(200)
                Add-Result -Id $check.id -Passed $passed -Summary 'Hashed static asset must return non-empty content with the correct JS/CSS MIME type and immutable public cache policy.' -FailureCategories @($category)
            }
            'SMK-04' {
                if ($null -eq $ApiPublicUri) {
                    $protectedEvidence = Get-ProtectedEvidenceResult -Id $check.id
                    Add-Result -Id $check.id -Passed $protectedEvidence.Passed -Summary $protectedEvidence.Summary -FailureCategories @($protectedEvidence.FailureCategory)
                    break
                }
                Assert-AzureDemoSmokeUriTarget -Uri $ApiPublicUri -VerifiedHost $VerifiedApiHost -ExpectedScheme https -RequireRootPath
                $currentRequestUri = $ApiPublicUri
                $executionPhase = 'http-request'
                $response = Invoke-AzureDemoSmokeHttpRequest -CheckId $check.id -Uri $ApiPublicUri
                Add-CurrentDiagnostic -Diagnostic $response.Diagnostic
                $executionPhase = 'response-assertion'
                $passed = $response.TransportSucceeded -and $response.StatusCode -in 401, 403, 404
                $category = Get-HttpCheckFailureCategory -Responses @($response) -AssertionPassed $passed -ExpectedStatusCodes @(401, 403, 404)
                Add-Result -Id $check.id -Passed $passed -Summary 'API public hostname must deny access without metadata.' -FailureCategories @($category)
            }
            'SMK-08' {
                $capabilitiesUri = [uri]::new($WebBaseUri, '/api/v1/session/capabilities')
                $baseline = Invoke-CheckedWebRequest -CheckId $check.id -Uri $capabilitiesUri
                $probe = Invoke-CheckedWebRequest -CheckId $check.id -Uri $capabilitiesUri -Method 'GET' -Headers @{ 'X-Lgr-Test-Principal' = 'must-not-be-trusted'; 'X-Roles' = 'PlatformAdministrator' }
                $protectedEvidence = Get-ProtectedEvidenceResult -Id $check.id
                $executionPhase = 'response-assertion'
                $automatedPassed = $baseline.TransportSucceeded -and $probe.TransportSucceeded -and
                    $baseline.StatusCode -eq $probe.StatusCode -and $baseline.StatusCode -notin 500, 502, 503, 504 -and
                    $probe.Content -notmatch 'must-not-be-trusted|PlatformAdministrator'
                $categories = @(
                    Get-HttpCheckFailureCategory -Responses @($baseline, $probe) -AssertionPassed $automatedPassed
                    if (-not $protectedEvidence.Passed) { $protectedEvidence.FailureCategory }
                )
                Add-Result -Id $check.id -Passed ($automatedPassed -and $protectedEvidence.Passed) `
                    -Summary ("Automated prohibited-header behavior and protected redaction evidence were both required. Evidence: {0}" -f $protectedEvidence.Summary) `
                    -FailureCategories $categories
            }
            'SMK-10' {
                $capabilitiesUri = [uri]::new($WebBaseUri, '/api/v1/session/capabilities')
                $originProbe = Invoke-CheckedWebRequest -CheckId $check.id -Uri $capabilitiesUri -Method 'OPTIONS' -Headers @{ Origin = 'https://unapproved.invalid'; 'Access-Control-Request-Method' = 'GET' }
                $methodProbe = Invoke-CheckedWebRequest -CheckId $check.id -Uri $capabilitiesUri -Method 'OPTIONS' -Headers @{ Origin = $WebBaseUri.GetLeftPart([UriPartial]::Authority); 'Access-Control-Request-Method' = 'TRACE' }
                $headerProbe = Invoke-CheckedWebRequest -CheckId $check.id -Uri $capabilitiesUri -Method 'OPTIONS' -Headers @{ Origin = $WebBaseUri.GetLeftPart([UriPartial]::Authority); 'Access-Control-Request-Method' = 'GET'; 'Access-Control-Request-Headers' = 'X-Roles,X-Customer-Id' }
                $sameOrigin = Invoke-CheckedWebRequest -CheckId $check.id -Uri $capabilitiesUri
                $executionPhase = 'response-assertion'
                $noGrant = @(@($originProbe, $methodProbe, $headerProbe) | Where-Object { -not [string]::IsNullOrWhiteSpace((Get-AzureDemoSmokeHeaderValue -Response $_ -Name 'Access-Control-Allow-Origin')) })
                $sameOriginPathExists = $sameOrigin.TransportSucceeded -and $sameOrigin.StatusCode -notin 404, 500, 502, 503, 504
                $passed = $originProbe.TransportSucceeded -and $methodProbe.TransportSucceeded -and $headerProbe.TransportSucceeded -and $noGrant.Count -eq 0 -and $sameOriginPathExists
                $category = Get-HttpCheckFailureCategory -Responses @($originProbe, $methodProbe, $headerProbe, $sameOrigin) -AssertionPassed $passed
                if ($null -eq $category -and -not $passed) { $category = 'assertion-failure' }
                elseif ($category -eq 'assertion-failure' -and $sameOrigin.StatusCode -in 404, 500, 502, 503, 504) { $category = 'application-response-failure' }
                Add-Result -Id $check.id -Passed $passed -Summary 'Unapproved origin, method and authority headers must receive no CORS grant, while the same-origin proxy path must remain reachable.' -FailureCategories @($category)
            }
            'SMK-11' {
                $response = Invoke-CheckedWebRequest -CheckId $check.id -Uri $WebBaseUri
                $executionPhase = 'response-assertion'
                $hsts = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'Strict-Transport-Security'
                $csp = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'Content-Security-Policy'
                $nosniff = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'X-Content-Type-Options'
                $referrer = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'Referrer-Policy'
                $permissions = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'Permissions-Policy'
                $frame = Get-AzureDemoSmokeHeaderValue -Response $response -Name 'X-Frame-Options'
                $apiLive = Invoke-CheckedApiRequest -CheckId $check.id -Uri ([uri] "https://$VerifiedApiHost/health/live")
                $executionPhase = 'response-assertion'
                $apiCsp = Get-AzureDemoSmokeHeaderValue -Response $apiLive -Name 'Content-Security-Policy'
                $apiPassed = $apiLive.TransportSucceeded -and $apiLive.StatusCode -eq 200 -and
                    (Get-AzureDemoSmokeHeaderValue -Response $apiLive -Name 'X-Content-Type-Options') -ceq 'nosniff' -and
                    (Get-AzureDemoSmokeHeaderValue -Response $apiLive -Name 'Referrer-Policy') -ceq 'no-referrer' -and
                    (Get-AzureDemoSmokeHeaderValue -Response $apiLive -Name 'X-Frame-Options') -ceq 'DENY' -and
                    $apiCsp -match "(?i)default-src\s+'none'" -and $apiCsp -match "(?i)frame-ancestors\s+'none'"
                $passed = $response.TransportSucceeded -and $response.StatusCode -eq 200 -and
                    $hsts -match '(?i)\bmax-age=31536000\b' -and $csp -match "(?i)frame-ancestors\s+'none'" -and
                    $nosniff -ceq 'nosniff' -and $referrer -ceq 'no-referrer' -and -not [string]::IsNullOrWhiteSpace($permissions) -and $frame -ceq 'DENY' -and $apiPassed
                $category = Get-HttpCheckFailureCategory -Responses @($response, $apiLive) -AssertionPassed $passed -ExpectedStatusCodes @(200)
                Add-Result -Id $check.id -Passed $passed -Summary 'Required web and private API HSTS/frame/MIME/referrer/permissions policies must match the approved values.' -FailureCategories @($category)
            }
            'SMK-12' {
                $response = Invoke-CheckedWebRequest -CheckId $check.id -Uri ([uri]::new($WebBaseUri, '/health'))
                $protectedEvidence = Get-ProtectedEvidenceResult -Id $check.id
                $executionPhase = 'response-assertion'
                $responsePassed = $response.TransportSucceeded -and $response.StatusCode -eq 200
                $categories = @(
                    Get-HttpCheckFailureCategory -Responses @($response) -AssertionPassed $responsePassed -ExpectedStatusCodes @(200)
                    if (-not $protectedEvidence.Passed) { $protectedEvidence.FailureCategory }
                )
                Add-Result -Id $check.id -Passed ($responsePassed -and $protectedEvidence.Passed) `
                    -Summary ("Healthy ready path and protected controlled-outage/alert evidence were both required. Evidence: {0}" -f $protectedEvidence.Summary) `
                    -FailureCategories $categories
            }
            'SMK-20' {
                $executionPhase = 'source-assertion'
                $manifestText = Get-Content -LiteralPath $manifestPath -Raw
                $source = Get-ChildItem (Join-Path $PSScriptRoot '..\..\src') -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/](node_modules|bin|obj|\.next)[\\/]' }
                $forbidden = $source | Select-String -Pattern 'Password=|\.publishsettings|Authentication__Mode=LocalTest'
                $manifestPaths = @($manifest.artifacts | ForEach-Object { [string] $_.path })
                $forbiddenManifestPath = @($manifestPaths | Where-Object { $_ -match '(?i)(?:^|/)(?:appsettings\.LocalTest\.json|\.env(?:\.|$)|.*\.publishsettings|tests?|node_modules)(?:/|$)' })
                if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) {
                    throw 'SMK-20 requires PowerShell 7 hashtable-mode JSON parsing.'
                }
                $lock = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\..\src\web\package-lock.json') -Raw | ConvertFrom-Json -AsHashtable -Depth 100
                $packages = $lock['packages']
                $mocker = if ($packages -is [Collections.IDictionary]) { $packages['node_modules/@vitest/mocker'] } else { $null }
                $vitest = if ($packages -is [Collections.IDictionary]) { $packages['node_modules/vitest'] } else { $null }
                $mockerVersion = if ($mocker -is [Collections.IDictionary]) { [string] $mocker['version'] } else { '' }
                $vitestVersion = if ($vitest -is [Collections.IDictionary]) { [string] $vitest['version'] } else { '' }
                $passed = -not $forbidden -and $forbiddenManifestPath.Count -eq 0 -and $manifestText -notmatch '(?i)appsettings\.LocalTest\.json|(?:^|[/"])\.env(?:[./"]|$)|\.publishsettings' -and $mockerVersion -ceq '4.1.11' -and $vitestVersion -ceq '4.1.11'
                Add-Result -Id $check.id -Passed $passed -Summary 'Exact-commit source, immutable manifest paths and patched frontend lock must contain no prohibited LocalTest, environment, credential, test or development artifact.' -FailureCategories $(if ($passed) { @() } else { @('assertion-failure') })
            }
            default {
                $protectedEvidence = Get-ProtectedEvidenceResult -Id $check.id
                Add-Result -Id $check.id -Passed $protectedEvidence.Passed -Summary $protectedEvidence.Summary -FailureCategories @($protectedEvidence.FailureCategory)
            }
        }
    }
    catch {
        $diagnostic = New-SafeCheckDiagnostic -CheckId $check.id -ExecutionPhase $executionPhase -Uri $currentRequestUri `
            -HttpStatus $null -Category 'harness-exception' -ErrorObject $_ -ErrorIdentifier (Get-AzureDemoSmokeSafeErrorIdentifier -ErrorObject $_ -Fallback 'HARNESS_EXCEPTION')
        Add-CurrentDiagnostic -Diagnostic $diagnostic
        $preservedCategories = @(
            if (@($currentDiagnostics | Where-Object { $_.exceptionCategory -eq 'missing-evidence' }).Count -gt 0) { 'missing-evidence' }
            if (@($currentDiagnostics | Where-Object { $_.exceptionCategory -eq 'rejected-evidence' }).Count -gt 0) { 'rejected-evidence' }
            if (@($currentDiagnostics | Where-Object {
                        $_.executionPhase -eq 'http-request' -and $_.exceptionCategory -notin 'none', 'redirect-response'
                    }).Count -gt 0) { 'transport-failure' }
            'harness-exception'
        )
        Add-Result -Id $check.id -Passed $false -Summary 'Smoke harness execution failed; unrestricted exception details were suppressed.' -FailureCategories $preservedCategories
    }
}

$summaryPath = Join-Path $EvidenceDirectory 'smoke-summary.json'
$results | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
$failedChecks = @($results | Where-Object { $_.status -eq 'FAIL' })
Write-Output ("Completed {0} commit-bound smoke checks; {1} failed." -f $results.Count, $failedChecks.Count)
if ($failedChecks.Count -gt 0) {
    throw ("Azure demo smoke checks failed: {0}. Safe evidence was retained." -f (($failedChecks | ForEach-Object { $_.id }) -join ', '))
}
