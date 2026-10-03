[CmdletBinding()]
param([string] $CompiledTemplatePath = '')

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$guard = Join-Path $repo 'scripts\build\Assert-AzureDemoAppServiceSubnet.ps1'
$main = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\main.bicep') -Raw
$network = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\network.bicep') -Raw
$apps = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\appservice.bicep') -Raw
$pipeline = Get-Content -LiteralPath (Join-Path $repo 'azure-pipelines.yml') -Raw
$parameterPaths = @(
    'infra\bicep\parameters\azure-demo.bicepparam',
    'infra\bicep\parameters\dev.bicepparam'
)

$expectedVirtualNetworkName = 'vnet-mtp-dev-uks-001'
$expectedIntegrationSubnetName = 'snet-appservice'
$staleIntegrationSubnetName = 'snet-appsvc-integration'
$expectedPrivateEndpointSubnetName = 'snet-private-endpoints'
$expectedVirtualNetworkId = '/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Network/virtualNetworks/vnet-mtp-dev-uks-001'
$expectedIntegrationSubnetId = "$expectedVirtualNetworkId/subnets/$expectedIntegrationSubnetName"
$expectedPrivateEndpointSubnetId = "$expectedVirtualNetworkId/subnets/$expectedPrivateEndpointSubnetName"

function New-VirtualNetwork(
    [string] $Name = $expectedVirtualNetworkName,
    [string] $Id = $expectedVirtualNetworkId) {
    return [ordered]@{ name = $Name; id = $Id }
}

function New-Subnet(
    [string] $Name = $expectedIntegrationSubnetName,
    [string] $Id = $expectedIntegrationSubnetId,
    [string] $AddressPrefix = '10.50.1.0/24',
    [string] $ProvisioningState = 'Succeeded',
    [object[]] $Delegations = @([ordered]@{ name = 'appService'; serviceName = 'Microsoft.Web/serverFarms' }),
    [bool] $IncludeProviderManagedAssociations = $false) {
    $subnet = [ordered]@{
        name = $Name
        id = $Id
        addressPrefix = $AddressPrefix
        provisioningState = $ProvisioningState
        delegations = @($Delegations)
    }
    if ($IncludeProviderManagedAssociations) {
        $subnet['privateEndpoints'] = @([ordered]@{ id = "$Id/providers/Microsoft.Web/sites/provider-managed-metadata" })
        $subnet['serviceAssociationLinks'] = @([ordered]@{ name = 'AppServiceLink'; provisioningState = 'Succeeded' })
    }
    return $subnet
}

function New-PrivateEndpointSubnet {
    return New-Subnet -Name $expectedPrivateEndpointSubnetName -Id $expectedPrivateEndpointSubnetId -AddressPrefix '10.50.2.0/24' -Delegations @()
}

function New-PrivateEndpoint(
    [string] $Name = 'pep-api-mtp-dev-uks-001',
    [string] $SubnetId = $expectedPrivateEndpointSubnetId) {
    return [ordered]@{
        name = $Name
        id = "/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Network/privateEndpoints/$Name"
        type = 'Microsoft.Network/privateEndpoints'
        subnet = [ordered]@{ id = $SubnetId }
    }
}

function ConvertTo-ListJson([object[]] $Items) {
    return ConvertTo-Json -InputObject @($Items) -Depth 12 -Compress
}

function New-ValidArguments {
    return @{
        VirtualNetworksJson = ConvertTo-ListJson @((New-VirtualNetwork))
        SubnetsJson = ConvertTo-ListJson @(
            (New-Subnet -IncludeProviderManagedAssociations $true),
            (New-PrivateEndpointSubnet)
        )
        PrivateEndpointsJson = ConvertTo-ListJson @((New-PrivateEndpoint))
        VirtualNetworksCommandExitCode = 0
        SubnetsCommandExitCode = 0
        PrivateEndpointsCommandExitCode = 0
    }
}

function Assert-Accepted([hashtable] $Arguments, [string] $Name) {
    try {
        & $guard @Arguments | Out-Null
    }
    catch {
        throw "App Service subnet guard rejected $Name`: $($_.Exception.Message)"
    }
}

function Assert-Rejected([hashtable] $Arguments, [string] $Name) {
    $accepted = $false
    try {
        & $guard @Arguments | Out-Null
        $accepted = $true
    }
    catch {
        if ([string]::IsNullOrWhiteSpace($_.Exception.Message)) {
            throw "App Service subnet guard did not explain its rejection of $Name."
        }
    }
    if ($accepted) {
        throw "App Service subnet guard accepted $Name."
    }
}

function Assert-Contains([string] $Text, [string] $Fragment, [string] $Message) {
    if (-not $Text.Contains($Fragment)) {
        throw $Message
    }
}

$validArguments = New-ValidArguments
Assert-Accepted $validArguments 'the exact existing subnet with provider-managed App Service association metadata'

$negativeCases = @()

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @(
    (New-Subnet),
    (New-Subnet -Name $staleIntegrationSubnetName -Id "$expectedVirtualNetworkId/subnets/$staleIntegrationSubnetName"),
    (New-PrivateEndpointSubnet)
)
$negativeCases += @{ Name = 'the stale integration-subnet name'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @((New-PrivateEndpointSubnet))
$negativeCases += @{ Name = 'a missing integration subnet'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.VirtualNetworksJson = ConvertTo-ListJson @((New-VirtualNetwork -Name 'vnet-other' -Id '/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Network/virtualNetworks/vnet-other'))
$negativeCases += @{ Name = 'the wrong virtual network'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.VirtualNetworksJson = '[]'
$negativeCases += @{ Name = 'a missing virtual network'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @((New-Subnet -AddressPrefix '10.50.1.0/26'), (New-PrivateEndpointSubnet))
$negativeCases += @{ Name = 'the wrong integration prefix'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @((New-Subnet -Delegations @()), (New-PrivateEndpointSubnet))
$negativeCases += @{ Name = 'an absent delegation'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @((New-Subnet -Delegations @([ordered]@{ serviceName = 'Microsoft.ContainerInstance/containerGroups' })), (New-PrivateEndpointSubnet))
$negativeCases += @{ Name = 'the wrong delegation'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @((New-Subnet -Delegations @([ordered]@{ serviceName = 'Microsoft.Web/serverFarms' }, [ordered]@{ serviceName = 'Microsoft.ContainerInstance/containerGroups' })), (New-PrivateEndpointSubnet))
$negativeCases += @{ Name = 'an unexpected additional delegation'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @((New-Subnet -ProvisioningState 'Failed'), (New-PrivateEndpointSubnet))
$negativeCases += @{ Name = 'failed subnet provisioning'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.PrivateEndpointsJson = ConvertTo-ListJson @((New-PrivateEndpoint -SubnetId $expectedIntegrationSubnetId))
$negativeCases += @{ Name = 'an actual private endpoint in the integration subnet'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @((New-Subnet), (New-Subnet), (New-PrivateEndpointSubnet))
$negativeCases += @{ Name = 'duplicate integration-subnet matches'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.VirtualNetworksJson = ConvertTo-ListJson @((New-VirtualNetwork), (New-VirtualNetwork))
$negativeCases += @{ Name = 'duplicate virtual-network matches'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @((New-Subnet -Id "$expectedVirtualNetworkId/subnets/wrong"), (New-PrivateEndpointSubnet))
$negativeCases += @{ Name = 'the wrong integration-subnet resource ID'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @((New-Subnet))
$negativeCases += @{ Name = 'a missing private-endpoint subnet'; Arguments = $arguments }

$arguments = New-ValidArguments
$arguments.SubnetsJson = ConvertTo-ListJson @((New-Subnet), (New-Subnet -Name $expectedPrivateEndpointSubnetName -Id $expectedPrivateEndpointSubnetId -AddressPrefix '10.50.2.0/27' -Delegations @()))
$negativeCases += @{ Name = 'the wrong private-endpoint prefix'; Arguments = $arguments }

foreach ($commandExitProperty in @('VirtualNetworksCommandExitCode', 'SubnetsCommandExitCode', 'PrivateEndpointsCommandExitCode')) {
    $arguments = New-ValidArguments
    $arguments[$commandExitProperty] = 7
    $negativeCases += @{ Name = "a non-zero $commandExitProperty"; Arguments = $arguments }
}

foreach ($jsonProperty in @('VirtualNetworksJson', 'SubnetsJson', 'PrivateEndpointsJson')) {
    $arguments = New-ValidArguments
    $arguments[$jsonProperty] = ''
    $negativeCases += @{ Name = "empty $jsonProperty"; Arguments = $arguments }

    $arguments = New-ValidArguments
    $arguments[$jsonProperty] = '[invalid json]'
    $negativeCases += @{ Name = "malformed $jsonProperty"; Arguments = $arguments }
}

foreach ($case in $negativeCases) {
    Assert-Rejected $case.Arguments $case.Name
}

foreach ($parameterPath in $parameterPaths) {
    $parameterText = Get-Content -LiteralPath (Join-Path $repo $parameterPath) -Raw
    if ([regex]::Matches($parameterText, "integrationSubnet:\s*'$expectedIntegrationSubnetName'").Count -ne 1) {
        throw "$parameterPath must use the exact existing App Service integration subnet once."
    }
    if ([regex]::Matches($parameterText, "privateEndpointSubnet:\s*'$expectedPrivateEndpointSubnetName'").Count -ne 1) {
        throw "$parameterPath must retain the separate private-endpoint subnet once."
    }
    if ($parameterText.Contains($staleIntegrationSubnetName)) {
        throw "$parameterPath retains the stale App Service integration-subnet name."
    }
}

foreach ($fragment in @(
        "resourceNames.virtualNetwork == '$expectedVirtualNetworkName'",
        "resourceNames.integrationSubnet == '$expectedIntegrationSubnetName'",
        "resourceNames.privateEndpointSubnet == '$expectedPrivateEndpointSubnetName'",
        'integrationSubnetId: network.outputs.integrationSubnetId')) {
    Assert-Contains $main $fragment "The main Bicep contract is missing: $fragment"
}

foreach ($fragment in @(
        "resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing",
        "resource integrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing",
        'parent: vnet',
        'name: integrationSubnetName',
        'output integrationSubnetId string = integrationSubnet.id')) {
    Assert-Contains $network $fragment "The existing integration-subnet symbolic contract is missing: $fragment"
}
if ([regex]::Matches($network, "Microsoft\.Network/virtualNetworks/subnets@2024-05-01' existing").Count -ne 2 -or
    [regex]::Matches($network, "Microsoft\.Network/virtualNetworks/subnets@2024-05-01' =").Count -ne 0 -or
    $network -match '(?i)addressPrefix|delegations\s*:|uniqueString|newGuid|delete') {
    throw 'The network module must reference both existing subnets without creating, renaming, replacing or reshaping either subnet.'
}

if ([regex]::Matches($apps, 'virtualNetworkSubnetId:\s*integrationSubnetId').Count -ne 4) {
    throw 'Web/API production sites and staging slots must all use the approved regional-integration subnet.'
}
foreach ($resourceName in @('webConfiguration', 'webSlot', 'apiConfiguration', 'apiSlot')) {
    $resourceStart = $apps.IndexOf("resource $resourceName ", [StringComparison]::Ordinal)
    if ($resourceStart -lt 0) {
        throw "App Service resource '$resourceName' is missing."
    }
    $nextResource = $apps.IndexOf("`nresource ", $resourceStart + 1, [StringComparison]::Ordinal)
    if ($nextResource -lt 0) { $nextResource = $apps.Length }
    $resourceText = $apps.Substring($resourceStart, $nextResource - $resourceStart)
    Assert-Contains $resourceText 'virtualNetworkSubnetId: integrationSubnetId' "App Service resource '$resourceName' does not preserve the required regional VNet integration."
}

$preDeploymentGateStart = $pipeline.IndexOf('- stage: PreDeploymentGate', [StringComparison]::Ordinal)
$preDeploymentGateEnd = $pipeline.IndexOf('- stage: MigrateAndDeploySlots', [StringComparison]::Ordinal)
$preDeploymentGate = $pipeline.Substring($preDeploymentGateStart, $preDeploymentGateEnd - $preDeploymentGateStart)
$subnetGuardIndex = $preDeploymentGate.IndexOf('Assert-AzureDemoAppServiceSubnet.ps1', [StringComparison]::Ordinal)
$whatIfIndex = $preDeploymentGate.IndexOf('az deployment group what-if', [StringComparison]::Ordinal)
if ($subnetGuardIndex -lt 0 -or $whatIfIndex -lt 0 -or $subnetGuardIndex -ge $whatIfIndex) {
    throw 'The fail-closed existing-subnet validation must run before Bicep what-if.'
}

if ($main.Contains('/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77') -or
    $network.Contains('/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77') -or
    $apps.Contains('/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77')) {
    throw 'Bicep must construct the integration-subnet resource ID symbolically rather than embed the subscription ID.'
}

if (-not [string]::IsNullOrWhiteSpace($CompiledTemplatePath)) {
    $compiledPath = (Resolve-Path -LiteralPath $CompiledTemplatePath).Path
    $compiled = Get-Content -LiteralPath $compiledPath -Raw | ConvertFrom-Json
    $compiledNetwork = $compiled.resources.network.properties.template
    $compiledApps = $compiled.resources.apps.properties.template

    if ($compiledNetwork.resources.integrationSubnet.existing -ne $true -or
        $compiledNetwork.resources.privateEndpointSubnet.existing -ne $true) {
        throw 'The compiled network template must retain both subnets as existing resources.'
    }
    if (-not ([string] $compiledNetwork.outputs.integrationSubnetId.value).Contains("parameters('integrationSubnetName')")) {
        throw 'The compiled integration-subnet output must be derived from the symbolic existing subnet name.'
    }
    foreach ($resourceName in @('webConfiguration', 'webSlot', 'apiConfiguration', 'apiSlot')) {
        $compiledResource = $compiledApps.resources.$resourceName
        $compiledSubnetId = if ($resourceName -in @('webConfiguration', 'apiConfiguration')) {
            $compiledResource.properties.virtualNetworkSubnetId
        }
        else {
            $compiledResource.properties.virtualNetworkSubnetId
        }
        if ([string] $compiledSubnetId -cne "[parameters('integrationSubnetId')]") {
            throw "Compiled App Service resource '$resourceName' does not use the integrationSubnetId parameter."
        }
    }
}

Write-Output "Azure App Service integration-subnet regression passed: 1 exact inventory accepted; $($negativeCases.Count) fail-closed inventories rejected; four site/slot integrations and two existing-subnet contracts verified."
