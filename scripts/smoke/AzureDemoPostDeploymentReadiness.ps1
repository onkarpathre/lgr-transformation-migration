$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

. (Join-Path $PSScriptRoot 'AzureDemoSmokeUtilities.ps1')

function Assert-AzureDemoPostDeploymentReadinessTarget {
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
        [Parameter(Mandatory)] [string] $TargetSlotName
    )

    $approvedSubscriptionId = '633398e2-6c00-4bb7-a576-2db0d210ee77'
    $approvedResourceGroupName = 'Onkar.Pathre'
    $approvedApiAppName = 'app-mtp-api-dev-uks-001'
    $approvedWebAppName = 'app-mtp-web-dev-uks-001'
    if (-not [string]::Equals($TargetSubscriptionId, $approvedSubscriptionId, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals($TargetResourceGroupName, $approvedResourceGroupName, [StringComparison]::Ordinal) -or
        -not [string]::Equals($TargetApiAppName, $approvedApiAppName, [StringComparison]::Ordinal) -or
        -not [string]::Equals($TargetWebAppName, $approvedWebAppName, [StringComparison]::Ordinal) -or
        -not [string]::Equals($TargetSlotName, 'staging', [StringComparison]::Ordinal)) {
        throw 'Post-deployment readiness refused a target outside the exact approved staging identity.'
    }

    if (-not (Test-AzureDemoDefaultHostName -HostName $VerifiedApiHost -AppName $TargetApiAppName -SlotName staging) -or
        -not (Test-AzureDemoDefaultHostName -HostName $VerifiedWebHost -AppName $TargetWebAppName -SlotName staging)) {
        throw 'Post-deployment readiness refused a malformed or substituted verified hostname.'
    }

    Assert-AzureDemoSmokeUriTarget -Uri $ApiReadyUri -VerifiedHost $VerifiedApiHost -ExpectedScheme https
    Assert-AzureDemoSmokeUriTarget -Uri $WebReadyUri -VerifiedHost $VerifiedWebHost -ExpectedScheme https
    if ($ApiReadyUri.AbsolutePath -cne '/health/ready' -or $WebReadyUri.AbsolutePath -cne '/health') {
        throw 'Post-deployment readiness requires the exact API and web readiness paths.'
    }
}

function Save-AzureDemoPostDeploymentReadinessEvidence {
    param(
        [Parameter(Mandatory)] [Collections.Generic.List[object]] $Records,
        [Parameter(Mandatory)] [string] $EvidencePath
    )

    $parent = Split-Path -Parent $EvidencePath
    if ([string]::IsNullOrWhiteSpace($parent)) {
        throw 'Post-deployment readiness evidence requires a parent directory.'
    }
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $serializedRecords = @($Records | ForEach-Object { $_ | ConvertTo-Json -Compress })
    $json = '[' + [string]::Join(',', [string[]] $serializedRecords) + ']'
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($EvidencePath), $json, [Text.UTF8Encoding]::new($false))
}

function Invoke-AzureDemoPostDeploymentReadinessGate {
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
        [Parameter(Mandatory)] [string] $EvidencePath,
        [Parameter(Mandatory)] [ValidateRange(2, 10)] [int] $RequiredConsecutiveSuccesses,
        [Parameter(Mandatory)] [ValidateRange(1, 3600)] [int] $OverallDeadlineSeconds,
        [Parameter(Mandatory)] [ValidateRange(0, 300)] [int] $PollIntervalSeconds,
        [Parameter(Mandatory)] [ValidateRange(1, 300)] [int] $RequestTimeoutSeconds,
        [Parameter(Mandatory)] [scriptblock] $RequestInvoker,
        [Parameter(Mandatory)] [scriptblock] $GetElapsedMilliseconds,
        [Parameter(Mandatory)] [scriptblock] $GetUtcNow,
        [Parameter(Mandatory)] [scriptblock] $DelayAction
    )

    $targetParameters = @{
        ApiReadyUri = $ApiReadyUri
        WebReadyUri = $WebReadyUri
        VerifiedApiHost = $VerifiedApiHost
        VerifiedWebHost = $VerifiedWebHost
        TargetSubscriptionId = $TargetSubscriptionId
        TargetResourceGroupName = $TargetResourceGroupName
        TargetApiAppName = $TargetApiAppName
        TargetWebAppName = $TargetWebAppName
        TargetSlotName = $TargetSlotName
    }
    Assert-AzureDemoPostDeploymentReadinessTarget @targetParameters

    $deadlineMilliseconds = [long] $OverallDeadlineSeconds * 1000L
    $pollMilliseconds = [long] $PollIntervalSeconds * 1000L
    $records = [Collections.Generic.List[object]]::new()
    $consecutiveSuccesses = 0

    while ([long] (& $GetElapsedMilliseconds) -lt $deadlineMilliseconds) {
        $roundPassed = $true
        $roundCompleted = $true
        foreach ($probe in @(
                [pscustomobject]@{ Phase = 'api-readiness'; Uri = $ApiReadyUri },
                [pscustomobject]@{ Phase = 'web-readiness'; Uri = $WebReadyUri })) {
            $remainingMilliseconds = $deadlineMilliseconds - [long] (& $GetElapsedMilliseconds)
            if ($remainingMilliseconds -lt 1000L) {
                $roundCompleted = $false
                $roundPassed = $false
                break
            }

            $correlationId = [Guid]::NewGuid().ToString('N')
            $effectiveTimeoutSeconds = [int] [Math]::Max(
                1,
                [Math]::Min($RequestTimeoutSeconds, [Math]::Floor($remainingMilliseconds / 1000.0)))
            $requestOutput = @()
            try {
                $requestOutput = @(& $RequestInvoker $probe.Phase $probe.Uri $correlationId $effectiveTimeoutSeconds)
            }
            catch {
                $requestOutput = @()
            }

            $transportSucceeded = $false
            $statusCode = 0
            if ($requestOutput.Count -eq 1 -and $null -ne $requestOutput[0]) {
                $transportProperty = $requestOutput[0].PSObject.Properties['TransportSucceeded']
                $statusProperty = $requestOutput[0].PSObject.Properties['StatusCode']
                $transportSucceeded = $null -ne $transportProperty -and
                    $transportProperty.Value -is [bool] -and $transportProperty.Value
                if ($null -ne $statusProperty) {
                    try { $statusCode = [int] $statusProperty.Value } catch { $statusCode = 0 }
                }
            }
            if ($statusCode -lt 100 -or $statusCode -gt 599) { $statusCode = 0 }

            $time = & $GetUtcNow
            if ($time -isnot [DateTimeOffset]) {
                throw 'Post-deployment readiness clock returned an invalid UTC time.'
            }
            $record = [pscustomobject][ordered]@{
                timeUtc = ([DateTimeOffset] $time).ToUniversalTime().ToString('O')
                status = if ($statusCode -eq 0) { 'unavailable' } else { $statusCode }
                phase = $probe.Phase
                correlationId = $correlationId
            }
            $records.Add($record)
            Save-AzureDemoPostDeploymentReadinessEvidence -Records $records -EvidencePath $EvidencePath
            Write-Information ($record | ConvertTo-Json -Compress) -InformationAction Continue

            if (-not $transportSucceeded -or $statusCode -ne 200) {
                $roundPassed = $false
            }
        }

        if ($roundCompleted -and $roundPassed) {
            $consecutiveSuccesses++
            if ($consecutiveSuccesses -ge $RequiredConsecutiveSuccesses) {
                return
            }
        }
        else {
            $consecutiveSuccesses = 0
        }

        $remainingAfterRound = $deadlineMilliseconds - [long] (& $GetElapsedMilliseconds)
        if ($remainingAfterRound -le 0) { break }
        $delayMilliseconds = [long] [Math]::Min($pollMilliseconds, $remainingAfterRound)
        if ($delayMilliseconds -gt 0) { & $DelayAction $delayMilliseconds }
    }

    if (-not (Test-Path -LiteralPath $EvidencePath -PathType Leaf)) {
        Save-AzureDemoPostDeploymentReadinessEvidence -Records $records -EvidencePath $EvidencePath
    }
    throw 'Post-deployment readiness did not stabilize within the fixed overall deadline.'
}
