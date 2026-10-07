[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
. (Join-Path $repo 'scripts\smoke\AzureDemoPostDeploymentReadiness.ps1')

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw $Message }
}

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-readiness-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null

$target = @{
    ApiReadyUri = [uri] 'https://app-mtp-api-dev-uks-001-staging.azurewebsites.net/health/ready'
    WebReadyUri = [uri] 'https://app-mtp-web-dev-uks-001-staging.azurewebsites.net/health'
    VerifiedApiHost = 'app-mtp-api-dev-uks-001-staging.azurewebsites.net'
    VerifiedWebHost = 'app-mtp-web-dev-uks-001-staging.azurewebsites.net'
    TargetSubscriptionId = '633398e2-6c00-4bb7-a576-2db0d210ee77'
    TargetResourceGroupName = 'Onkar.Pathre'
    TargetApiAppName = 'app-mtp-api-dev-uks-001'
    TargetWebAppName = 'app-mtp-web-dev-uks-001'
    TargetSlotName = 'staging'
}

function Invoke-Fixture {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [object[]] $Responses,
        [int] $DeadlineSeconds = 4,
        [switch] $ExpectFailure,
        [switch] $CaptureInformation
    )

    $state = [pscustomobject]@{ Elapsed = 0L; Index = 0; Calls = 0 }
    $path = Join-Path $temporaryDirectory "$Name.json"
    $requestInvoker = {
        param([string] $Phase, [uri] $Uri, [string] $CorrelationId, [int] $TimeoutSeconds)
        $state.Calls++
        $index = [Math]::Min($state.Index, $Responses.Count - 1)
        $response = $Responses[$index]
        $state.Index++
        if ($null -ne $response.PSObject.Properties['ElapsedMilliseconds']) {
            $state.Elapsed += [long] $response.ElapsedMilliseconds
        }
        if ($null -ne $response.PSObject.Properties['Throw'] -and $response.Throw) {
            throw [TimeoutException]::new([string] $response.Message)
        }
        return [pscustomobject]@{
            TransportSucceeded = [bool] $response.TransportSucceeded
            StatusCode = $response.StatusCode
        }
    }.GetNewClosure()
    $getElapsed = { return [long] $state.Elapsed }.GetNewClosure()
    $getUtcNow = { return [DateTimeOffset]::Parse('2026-10-07T20:17:00Z').AddMilliseconds($state.Elapsed) }.GetNewClosure()
    $delay = { param([long] $Milliseconds) $state.Elapsed += $Milliseconds }.GetNewClosure()

    $failed = $false
    $captured = @()
    try {
        $parameters = @{}
        foreach ($entry in $target.GetEnumerator()) { $parameters[$entry.Key] = $entry.Value }
        $parameters.EvidencePath = $path
        $parameters.RequiredConsecutiveSuccesses = 2
        $parameters.OverallDeadlineSeconds = $DeadlineSeconds
        $parameters.PollIntervalSeconds = 1
        $parameters.RequestTimeoutSeconds = 2
        $parameters.RequestInvoker = $requestInvoker
        $parameters.GetElapsedMilliseconds = $getElapsed
        $parameters.GetUtcNow = $getUtcNow
        $parameters.DelayAction = $delay
        if ($CaptureInformation) {
            $captured = @(Invoke-AzureDemoPostDeploymentReadinessGate @parameters 6>&1)
        }
        else {
            Invoke-AzureDemoPostDeploymentReadinessGate @parameters 6>$null
        }
    }
    catch {
        $failed = $true
        Assert-True ($_.Exception.Message -ceq 'Post-deployment readiness did not stabilize within the fixed overall deadline.') "$Name exposed an unexpected failure message."
    }

    Assert-True ($failed -eq [bool] $ExpectFailure) "$Name returned an unexpected success/failure outcome."
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "$Name did not retain readiness evidence."
    $parsed = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    [object[]] $parsedRecords = if ($parsed -is [Collections.IEnumerable] -and $parsed -isnot [string]) {
        @($parsed | ForEach-Object { $_ })
    }
    else { @($parsed) }
    return [pscustomobject]@{
        Records = [object[]] $parsedRecords
        Calls = $state.Calls
        Information = $captured
        Path = $path
    }
}

try {
    $recovery = Invoke-Fixture -Name recovery -Responses @(
        [pscustomobject]@{ TransportSucceeded = $true; StatusCode = 503 },
        [pscustomobject]@{ TransportSucceeded = $true; StatusCode = 503 },
        [pscustomobject]@{ TransportSucceeded = $true; StatusCode = 200 },
        [pscustomobject]@{ TransportSucceeded = $true; StatusCode = 200 },
        [pscustomobject]@{ TransportSucceeded = $true; StatusCode = 200 },
        [pscustomobject]@{ TransportSucceeded = $true; StatusCode = 200 })
    Assert-True ($recovery.Records.Count -eq 6) 'Readiness recovery did not require two complete consecutive healthy rounds.'
    Assert-True ((@($recovery.Records | Select-Object -Last 4 | Where-Object { $_.status -eq 200 }).Count) -eq 4) 'Readiness recovery did not end with four consecutive endpoint successes.'

    $persistent = Invoke-Fixture -Name persistent-503 -Responses @(
        [pscustomobject]@{ TransportSucceeded = $true; StatusCode = 503 }) -DeadlineSeconds 3 -ExpectFailure
    Assert-True ($persistent.Records.Count -ge 4) 'Persistent 503 did not continue probing until the fixed deadline.'
    Assert-True (@($persistent.Records | Where-Object { $_.status -ne 503 }).Count -eq 0) 'Persistent 503 evidence changed the observed status.'

    $timeout = Invoke-Fixture -Name timeout -Responses @(
        [pscustomobject]@{
            TransportSucceeded = $false
            StatusCode = $null
            ElapsedMilliseconds = 2000
            Throw = $true
            Message = 'token=must-not-appear; Password=must-not-appear'
        }) -DeadlineSeconds 2 -ExpectFailure -CaptureInformation
    Assert-True ($timeout.Records.Count -eq 1 -and $timeout.Records[0].status -ceq 'unavailable') 'Timeout was not retained as a fail-closed unavailable result.'
    Assert-True ($timeout.Records[0].phase -ceq 'api-readiness') 'Timeout evidence lost its bounded readiness phase.'
    Assert-True ([string] $timeout.Records[0].timeUtc -cmatch '^2026-10-07T20:17:02(?:\.0{7})?\+00:00$') 'Timeout evidence did not retain a safe UTC instant.'
    $serializedTimeout = Get-Content -LiteralPath $timeout.Path -Raw
    $informationText = [string]::Join([Environment]::NewLine, [string[]] @($timeout.Information | ForEach-Object { [string] $_ }))
    foreach ($forbidden in @('must-not-appear', 'token=', 'Password=', 'https://', '/health')) {
        Assert-True (-not $serializedTimeout.Contains($forbidden)) "Readiness evidence disclosed $forbidden."
        Assert-True (-not $informationText.Contains($forbidden)) "Readiness information output disclosed $forbidden."
    }
    $propertyNames = @(($timeout.Records[0].PSObject.Properties.Name | Sort-Object) -join '|')
    Assert-True ($propertyNames.Count -eq 1 -and $propertyNames[0] -ceq 'correlationId|phase|status|timeUtc') 'Readiness evidence did not retain the four-field safe schema.'
    Assert-True ([string] $timeout.Records[0].correlationId -cmatch '^[0-9a-f]{32}$') 'Readiness correlation ID was not a bounded lowercase trace identifier.'

    $substitutionPath = Join-Path $temporaryDirectory 'substitution.json'
    $substitutionCalls = 0
    $substituted = @{}
    foreach ($entry in $target.GetEnumerator()) { $substituted[$entry.Key] = $entry.Value }
    $substituted.ApiReadyUri = [uri] 'https://app-mtp-api-dev-uks-001.azurewebsites.net/health/ready'
    $substituted.VerifiedApiHost = 'app-mtp-api-dev-uks-001.azurewebsites.net'
    $substitutionRejected = $false
    try {
        Invoke-AzureDemoPostDeploymentReadinessGate @substituted -EvidencePath $substitutionPath `
            -RequiredConsecutiveSuccesses 2 -OverallDeadlineSeconds 2 -PollIntervalSeconds 1 -RequestTimeoutSeconds 1 `
            -RequestInvoker { $substitutionCalls++; [pscustomobject]@{ TransportSucceeded = $true; StatusCode = 200 } } `
            -GetElapsedMilliseconds { 0L } -GetUtcNow { [DateTimeOffset]::UtcNow } -DelayAction { param([long] $Milliseconds) }
    }
    catch { $substitutionRejected = $true }
    Assert-True $substitutionRejected 'A production-host substitution was accepted for staging readiness.'
    Assert-True ($substitutionCalls -eq 0) 'A substituted target was contacted before exact-target rejection.'
    Assert-True (-not (Test-Path -LiteralPath $substitutionPath)) 'A substituted target produced misleading readiness evidence.'

    Write-Output 'Azure demo post-deployment readiness regression passed recovery, persistent 503, deadline timeout, exact-target substitution and four-field redaction cases.'
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}
