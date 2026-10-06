[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $AccountJson,
    [Parameter(Mandatory)] [int] $AccountCommandExitCode,
    [Parameter(Mandatory)] [string] $WebSlotJson,
    [Parameter(Mandatory)] [int] $WebSlotCommandExitCode,
    [Parameter(Mandatory)] [string] $ApiSlotJson,
    [Parameter(Mandatory)] [int] $ApiSlotCommandExitCode,
    [Parameter(Mandatory)] [string] $ApiSlotSettingsJson,
    [Parameter(Mandatory)] [int] $ApiSlotSettingsCommandExitCode
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'AzureDemoStagingDeployment.ps1')

foreach ($command in @(
        @{ Name = 'account'; ExitCode = $AccountCommandExitCode },
        @{ Name = 'web staging slot'; ExitCode = $WebSlotCommandExitCode },
        @{ Name = 'API staging slot'; ExitCode = $ApiSlotCommandExitCode },
        @{ Name = 'API staging app settings'; ExitCode = $ApiSlotSettingsCommandExitCode })) {
    if ($command.ExitCode -ne 0) { throw "Applied host configuration validation rejected a failed $($command.Name) query." }
}

$account = ConvertFrom-AzureDemoJson -Json $AccountJson -Operation 'Applied host configuration account query'
$webSlot = ConvertFrom-AzureDemoJson -Json $WebSlotJson -Operation 'Applied host configuration web-slot query'
$apiSlot = ConvertFrom-AzureDemoJson -Json $ApiSlotJson -Operation 'Applied host configuration API-slot query'
$settingsObject = ConvertFrom-AzureDemoJson -Json $ApiSlotSettingsJson -Operation 'Applied host configuration app-settings query'
$settings = @(ConvertTo-AzureDemoObjectArray $settingsObject)
$webTarget = Assert-AzureDemoStagingTarget -SubscriptionId $script:AzureDemoSubscriptionId `
    -ResourceGroupName $script:AzureDemoResourceGroupName -Workload Web -AppName $script:AzureDemoWebAppName `
    -SlotName $script:AzureDemoStagingSlotName -Account $account -Resource $webSlot
$apiTarget = Assert-AzureDemoStagingTarget -SubscriptionId $script:AzureDemoSubscriptionId `
    -ResourceGroupName $script:AzureDemoResourceGroupName -Workload Api -AppName $script:AzureDemoApiAppName `
    -SlotName $script:AzureDemoStagingSlotName -Account $account -Resource $apiSlot

$expected = [ordered]@{
    AllowedHosts = $apiTarget.DefaultHostName
    AllowedOrigins__0 = "https://$($webTarget.DefaultHostName)"
    AzureDemoHostIdentity__SlotName = 'staging'
    AzureDemoHostIdentity__ApiResourceId = $apiTarget.ResourceId
    AzureDemoHostIdentity__ApiDefaultHostName = $apiTarget.DefaultHostName
    AzureDemoHostIdentity__WebResourceId = $webTarget.ResourceId
    AzureDemoHostIdentity__WebDefaultHostName = $webTarget.DefaultHostName
    SCM_DO_BUILD_DURING_DEPLOYMENT = 'false'
}
$stickyNames = @($expected.Keys | Where-Object { $_ -cne 'SCM_DO_BUILD_DURING_DEPLOYMENT' })
foreach ($name in $expected.Keys) {
    $matches = @($settings | Where-Object { [string] $_.name -ceq $name })
    if ($matches.Count -ne 1 -or [string] $matches[0].value -cne [string] $expected[$name]) {
        throw "Applied API staging host configuration is missing or incorrect for $name."
    }
    if ($name -in $stickyNames -and [bool] $matches[0].slotSetting -ne $true) {
        throw "Applied API staging host configuration is not slot-sticky for $name."
    }
}
if ($settings.Count -ne $expected.Count) { throw 'Applied API staging host configuration query returned an unexpected setting.' }

Write-Output 'Applied API staging host identity, allowlists, remote-build setting and slot stickiness match the Azure-reported slot resources.'
