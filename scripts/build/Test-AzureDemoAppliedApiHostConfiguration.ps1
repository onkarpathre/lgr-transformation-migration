[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$validator = Join-Path $PSScriptRoot '..\deployment\Assert-AzureDemoAppliedApiHostConfiguration.ps1'
$subscriptionId = '633398e2-6c00-4bb7-a576-2db0d210ee77'
$resourceGroup = 'Onkar.Pathre'
$webApp = 'app-mtp-web-dev-uks-001'
$apiApp = 'app-mtp-api-dev-uks-001'
$webHost = "$webApp-staging-csdtetbtbeh3h7fy.uksouth-01.azurewebsites.net"
$apiHost = "$apiApp-staging-athrc5epbzcdetb8.uksouth-01.azurewebsites.net"
$webId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$webApp/slots/staging"
$apiId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$apiApp/slots/staging"

function New-ResourceJson([string] $Id, [string] $Name, [string] $HostName) {
    return [ordered]@{
        id = $Id
        name = "$Name/staging"
        resourceGroup = $resourceGroup
        type = 'Microsoft.Web/sites/slots'
        defaultHostName = $HostName
    } | ConvertTo-Json -Compress
}

$settings = @(
    [ordered]@{ name = 'AllowedHosts'; value = $apiHost; slotSetting = $true },
    [ordered]@{ name = 'AllowedOrigins__0'; value = "https://$webHost"; slotSetting = $true },
    [ordered]@{ name = 'AzureDemoHostIdentity__SlotName'; value = 'staging'; slotSetting = $true },
    [ordered]@{ name = 'AzureDemoHostIdentity__ApiResourceId'; value = $apiId; slotSetting = $true },
    [ordered]@{ name = 'AzureDemoHostIdentity__ApiDefaultHostName'; value = $apiHost; slotSetting = $true },
    [ordered]@{ name = 'AzureDemoHostIdentity__WebResourceId'; value = $webId; slotSetting = $true },
    [ordered]@{ name = 'AzureDemoHostIdentity__WebDefaultHostName'; value = $webHost; slotSetting = $true },
    [ordered]@{ name = 'SCM_DO_BUILD_DURING_DEPLOYMENT'; value = 'false'; slotSetting = $false }
)
$valid = @{
    AccountJson = ([ordered]@{ id = $subscriptionId } | ConvertTo-Json -Compress)
    AccountCommandExitCode = 0
    WebSlotJson = New-ResourceJson $webId $webApp $webHost
    WebSlotCommandExitCode = 0
    ApiSlotJson = New-ResourceJson $apiId $apiApp $apiHost
    ApiSlotCommandExitCode = 0
    ApiSlotSettingsJson = ($settings | ConvertTo-Json -Compress)
    ApiSlotSettingsCommandExitCode = 0
}

& $validator @valid | Out-Null

$negativeCases = @(
    @{ Name = 'failed Azure query'; Mutate = { param($arguments) $arguments.ApiSlotSettingsCommandExitCode = 17 } },
    @{ Name = 'wrong API resource'; Mutate = { param($arguments) $arguments.ApiSlotJson = $arguments.ApiSlotJson.Replace($apiApp, 'app-other-api') } },
    @{ Name = 'wrong generated hostname'; Mutate = { param($arguments) $arguments.ApiSlotSettingsJson = $arguments.ApiSlotSettingsJson.Replace($apiHost, "$apiApp-staging-evil.uksouth-01.azurewebsites.net") } },
    @{ Name = 'non-sticky host identity'; Mutate = {
            param($arguments)
            $changed = @($settings | ForEach-Object { [ordered]@{ name = $_.name; value = $_.value; slotSetting = $_.slotSetting } })
            @($changed | Where-Object { $_.name -ceq 'AzureDemoHostIdentity__ApiDefaultHostName' })[0].slotSetting = $false
            $arguments.ApiSlotSettingsJson = $changed | ConvertTo-Json -Compress
        } },
    @{ Name = 'missing host identity'; Mutate = {
            param($arguments)
            $arguments.ApiSlotSettingsJson = @($settings | Where-Object { $_.name -cne 'AzureDemoHostIdentity__WebResourceId' }) | ConvertTo-Json -Compress
        } },
    @{ Name = 'remote build enabled'; Mutate = { param($arguments) $arguments.ApiSlotSettingsJson = $arguments.ApiSlotSettingsJson.Replace('"value":"false","slotSetting":false', '"value":"true","slotSetting":false') } }
)

foreach ($case in $negativeCases) {
    $arguments = @{} + $valid
    & $case.Mutate $arguments
    $accepted = $false
    try { & $validator @arguments | Out-Null; $accepted = $true } catch { }
    if ($accepted) { throw "Applied API host configuration validator accepted $($case.Name)." }
}

Write-Output "Applied API host configuration regression passed one valid and $($negativeCases.Count) fail-closed cases."
