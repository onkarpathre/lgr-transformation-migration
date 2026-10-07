[CmdletBinding()]
param(
    [Parameter(Mandatory)] [uri] $ApiReadyUri,
    [Parameter(Mandatory)] [uri] $WebReadyUri,
    [Parameter(Mandatory)] [string] $VerifiedApiHost,
    [Parameter(Mandatory)] [string] $VerifiedWebHost,
    [Parameter(Mandatory)] [string] $TargetSubscriptionId,
    [Parameter(Mandatory)] [string] $TargetResourceGroupName,
    [Parameter(Mandatory)] [string] $TargetApiAppName,
    [Parameter(Mandatory)] [string] $TargetWebAppName,
    [Parameter(Mandatory)] [string] $TargetSlotName,
    [Parameter(Mandatory)] [string] $EvidencePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Post-deployment readiness requires PowerShell 7 or later.'
}

. (Join-Path $PSScriptRoot 'AzureDemoPostDeploymentReadiness.ps1')

if (Test-Path -LiteralPath $EvidencePath) {
    throw 'Post-deployment readiness requires a new evidence path for this attempt.'
}

$requiredConsecutiveSuccesses = 2
$overallDeadlineSeconds = 120
$pollIntervalSeconds = 5
$requestTimeoutSeconds = 10
$stopwatch = [Diagnostics.Stopwatch]::StartNew()

$requestInvoker = {
    param([string] $Phase, [uri] $Uri, [string] $CorrelationId, [int] $TimeoutSeconds)

    $spanId = [Guid]::NewGuid().ToString('N').Substring(0, 16)
    $requestResult = Invoke-AzureDemoSmokeHttpRequest -CheckId $Phase -Uri $Uri `
        -Headers @{ traceparent = "00-$CorrelationId-$spanId-01" } -TimeoutSec $TimeoutSeconds
    return [pscustomobject]@{
        TransportSucceeded = [bool] $requestResult.TransportSucceeded
        StatusCode = $requestResult.StatusCode
    }
}
$getElapsedMilliseconds = { return [long] $stopwatch.ElapsedMilliseconds }
$getUtcNow = { return [DateTimeOffset]::UtcNow }
$delayAction = { param([long] $Milliseconds) Start-Sleep -Milliseconds $Milliseconds }

try {
    $gateParameters = @{
        ApiReadyUri = $ApiReadyUri
        WebReadyUri = $WebReadyUri
        VerifiedApiHost = $VerifiedApiHost
        VerifiedWebHost = $VerifiedWebHost
        TargetSubscriptionId = $TargetSubscriptionId
        TargetResourceGroupName = $TargetResourceGroupName
        TargetApiAppName = $TargetApiAppName
        TargetWebAppName = $TargetWebAppName
        TargetSlotName = $TargetSlotName
        EvidencePath = $EvidencePath
        RequiredConsecutiveSuccesses = $requiredConsecutiveSuccesses
        OverallDeadlineSeconds = $overallDeadlineSeconds
        PollIntervalSeconds = $pollIntervalSeconds
        RequestTimeoutSeconds = $requestTimeoutSeconds
        RequestInvoker = $requestInvoker
        GetElapsedMilliseconds = $getElapsedMilliseconds
        GetUtcNow = $getUtcNow
        DelayAction = $delayAction
    }
    Invoke-AzureDemoPostDeploymentReadinessGate @gateParameters
}
finally {
    $stopwatch.Stop()
}
