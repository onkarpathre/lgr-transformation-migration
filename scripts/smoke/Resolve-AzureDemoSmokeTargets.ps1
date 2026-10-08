[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ExpectedSubscriptionId,
    [Parameter(Mandatory)] [string] $ExpectedTenantId,
    [Parameter(Mandatory)] [string] $ExpectedResourceGroupName,
    [Parameter(Mandatory)] [string] $ExpectedWebAppName,
    [Parameter(Mandatory)] [string] $ExpectedApiAppName,
    [Parameter(Mandatory)] [string] $ExpectedSlotName,
    [Parameter(Mandatory)] [string] $AccountJson,
    [Parameter(Mandatory)] [int] $AccountCommandExitCode,
    [Parameter(Mandatory)] [string] $WebProductionJson,
    [Parameter(Mandatory)] [int] $WebProductionCommandExitCode,
    [Parameter(Mandatory)] [string] $WebSlotJson,
    [Parameter(Mandatory)] [int] $WebSlotCommandExitCode,
    [Parameter(Mandatory)] [string] $ApiProductionJson,
    [Parameter(Mandatory)] [int] $ApiProductionCommandExitCode,
    [Parameter(Mandatory)] [string] $ApiSlotJson,
    [Parameter(Mandatory)] [int] $ApiSlotCommandExitCode
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
. (Join-Path $PSScriptRoot 'AzureDemoSmokeUtilities.ps1')

function ConvertFrom-RequiredAzureJson {
    param([string] $Name, [string] $Json, [int] $CommandExitCode)
    if ($CommandExitCode -ne 0) { throw "$Name Azure CLI query failed with a nonzero exit code." }
    if ([string]::IsNullOrWhiteSpace($Json)) { throw "$Name Azure CLI query returned no response." }
    try { $value = $Json | ConvertFrom-Json -ErrorAction Stop } catch { throw "$Name Azure CLI query returned malformed JSON." }
    if ($null -eq $value -or $value -is [Collections.IEnumerable] -and $value -isnot [string] -and $value -isnot [pscustomobject]) {
        throw "$Name Azure CLI query did not return one object."
    }
    return $value
}

function Assert-ExactAzureResource {
    param(
        [string] $Name,
        [object] $Resource,
        [string] $ExpectedAppName,
        [ValidateSet('production', 'staging')] [string] $SlotName
    )

    $suffix = if ($SlotName -eq 'production') { '' } else { "/slots/$SlotName" }
    $expectedId = "/subscriptions/$ExpectedSubscriptionId/resourceGroups/$ExpectedResourceGroupName/providers/Microsoft.Web/sites/$ExpectedAppName$suffix"
    $expectedName = if ($SlotName -eq 'production') { $ExpectedAppName } else { "$ExpectedAppName/$SlotName" }
    $expectedType = if ($SlotName -eq 'production') { 'Microsoft.Web/sites' } else { 'Microsoft.Web/sites/slots' }

    foreach ($propertyName in @('id', 'name', 'resourceGroup', 'type', 'defaultHostName')) {
        if ($null -eq $Resource.PSObject.Properties[$propertyName] -or [string]::IsNullOrWhiteSpace([string] $Resource.$propertyName)) {
            throw "$Name Azure CLI response is missing a required property."
        }
    }
    if (-not [string]::Equals([string] $Resource.id, $expectedId, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals([string] $Resource.name, $expectedName, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals([string] $Resource.resourceGroup, $ExpectedResourceGroupName, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals([string] $Resource.type, $expectedType, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Name Azure CLI response did not match the exact approved subscription, resource group, app and slot identity."
    }

    $hostName = [string] $Resource.defaultHostName
    if (-not (Test-AzureDemoDefaultHostName -HostName $hostName -AppName $ExpectedAppName -SlotName $SlotName)) {
        throw "$Name Azure CLI response contained an invalid or substituted default hostname."
    }
    return $hostName
}

if ($ExpectedSlotName -cne 'staging') { throw 'Only the exact approved staging slot may be resolved.' }
$subscriptionGuid = [Guid]::Empty
if (-not [Guid]::TryParseExact($ExpectedSubscriptionId, 'D', [ref] $subscriptionGuid) -or $subscriptionGuid -eq [Guid]::Empty) {
    throw 'The approved subscription ID is malformed.'
}
$tenantGuid = [Guid]::Empty
if (-not [Guid]::TryParseExact($ExpectedTenantId, 'D', [ref] $tenantGuid) -or $tenantGuid -eq [Guid]::Empty) {
    throw 'The approved tenant ID is malformed.'
}

$account = ConvertFrom-RequiredAzureJson -Name 'Account' -Json $AccountJson -CommandExitCode $AccountCommandExitCode
if ($null -eq $account.PSObject.Properties['id'] -or $null -eq $account.PSObject.Properties['tenantId'] -or
    -not [string]::Equals([string] $account.id, $ExpectedSubscriptionId, [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals([string] $account.tenantId, $ExpectedTenantId, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Authenticated Azure account did not match the exact approved subscription and tenant.'
}

$webProduction = ConvertFrom-RequiredAzureJson -Name 'Web production site' -Json $WebProductionJson -CommandExitCode $WebProductionCommandExitCode
$webSlot = ConvertFrom-RequiredAzureJson -Name 'Web staging slot' -Json $WebSlotJson -CommandExitCode $WebSlotCommandExitCode
$apiProduction = ConvertFrom-RequiredAzureJson -Name 'API production site' -Json $ApiProductionJson -CommandExitCode $ApiProductionCommandExitCode
$apiSlot = ConvertFrom-RequiredAzureJson -Name 'API staging slot' -Json $ApiSlotJson -CommandExitCode $ApiSlotCommandExitCode

[pscustomobject][ordered]@{
    SubscriptionId = $ExpectedSubscriptionId.ToLowerInvariant()
    TenantId = $ExpectedTenantId.ToLowerInvariant()
    ResourceGroupName = $ExpectedResourceGroupName
    WebAppName = $ExpectedWebAppName
    ApiAppName = $ExpectedApiAppName
    SlotName = $ExpectedSlotName
    WebProductionHost = Assert-ExactAzureResource -Name 'Web production site' -Resource $webProduction -ExpectedAppName $ExpectedWebAppName -SlotName production
    WebStagingHost = Assert-ExactAzureResource -Name 'Web staging slot' -Resource $webSlot -ExpectedAppName $ExpectedWebAppName -SlotName staging
    ApiProductionHost = Assert-ExactAzureResource -Name 'API production site' -Resource $apiProduction -ExpectedAppName $ExpectedApiAppName -SlotName production
    ApiStagingHost = Assert-ExactAzureResource -Name 'API staging slot' -Resource $apiSlot -ExpectedAppName $ExpectedApiAppName -SlotName staging
}
