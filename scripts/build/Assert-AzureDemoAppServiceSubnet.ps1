[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string] $VirtualNetworksJson,

    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string] $SubnetsJson,

    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string] $PrivateEndpointsJson,

    [Parameter(Mandatory = $true)]
    [int] $VirtualNetworksCommandExitCode,

    [Parameter(Mandatory = $true)]
    [int] $SubnetsCommandExitCode,

    [Parameter(Mandatory = $true)]
    [int] $PrivateEndpointsCommandExitCode
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$expectedVirtualNetworkName = 'vnet-mtp-dev-uks-001'
$expectedIntegrationSubnetName = 'snet-appservice'
$rejectedIntegrationSubnetName = 'snet-appsvc-integration'
$expectedPrivateEndpointSubnetName = 'snet-private-endpoints'
$expectedVirtualNetworkId = '/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Network/virtualNetworks/vnet-mtp-dev-uks-001'
$expectedIntegrationSubnetId = "$expectedVirtualNetworkId/subnets/$expectedIntegrationSubnetName"
$expectedPrivateEndpointSubnetId = "$expectedVirtualNetworkId/subnets/$expectedPrivateEndpointSubnetName"
$expectedIntegrationPrefix = '10.50.1.0/24'
$expectedPrivateEndpointPrefix = '10.50.2.0/24'
$expectedDelegation = 'Microsoft.Web/serverFarms'

function Normalize-ResourceId([object] $Value) {
    if ($null -eq $Value) {
        return ''
    }

    return ([string] $Value).Trim().TrimEnd('/').ToLowerInvariant()
}

function Get-PropertyValue([object] $InputObject, [string] $Name) {
    if ($null -eq $InputObject) {
        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Get-ProviderValue([object] $InputObject, [string] $Name) {
    $value = Get-PropertyValue $InputObject $Name
    if ($null -ne $value) {
        return $value
    }

    $properties = Get-PropertyValue $InputObject 'properties'
    return Get-PropertyValue $properties $Name
}

function ConvertFrom-AzureListJson([string] $Json, [string] $Description) {
    if ([string]::IsNullOrWhiteSpace($Json)) {
        throw "$Description inventory was empty."
    }

    $trimmed = $Json.Trim()
    if (-not $trimmed.StartsWith('[', [StringComparison]::Ordinal) -or
        -not $trimmed.EndsWith(']', [StringComparison]::Ordinal)) {
        throw "$Description inventory was not a JSON array."
    }

    try {
        $parsed = ConvertFrom-Json -InputObject $trimmed -ErrorAction Stop
    }
    catch {
        throw "$Description inventory was not valid JSON: $($_.Exception.Message)"
    }

    foreach ($item in $parsed) {
        $item
    }
}

function Get-SubnetPrefixes([object] $Subnet) {
    $prefixes = @()
    $addressPrefix = Get-ProviderValue $Subnet 'addressPrefix'
    if (-not [string]::IsNullOrWhiteSpace([string] $addressPrefix)) {
        $prefixes += ([string] $addressPrefix).Trim()
    }

    foreach ($addressPrefixItem in @(Get-ProviderValue $Subnet 'addressPrefixes')) {
        if (-not [string]::IsNullOrWhiteSpace([string] $addressPrefixItem)) {
            $prefixes += ([string] $addressPrefixItem).Trim()
        }
    }

    return @($prefixes | Select-Object -Unique)
}

function Assert-ExactSubnet(
    [object[]] $Subnets,
    [string] $Name,
    [string] $ExpectedId,
    [string] $ExpectedPrefix,
    [string] $Description) {
    $caseInsensitiveMatches = @($Subnets | Where-Object { [string] (Get-PropertyValue $_ 'name') -ieq $Name })
    $exactMatches = @($caseInsensitiveMatches | Where-Object { [string] (Get-PropertyValue $_ 'name') -ceq $Name })
    if ($caseInsensitiveMatches.Count -ne 1 -or $exactMatches.Count -ne 1) {
        throw "Expected exactly one $Description named '$Name'; found $($exactMatches.Count) exact match(es)."
    }

    $matchingIds = @($Subnets | Where-Object {
            (Normalize-ResourceId (Get-PropertyValue $_ 'id')) -eq (Normalize-ResourceId $ExpectedId)
        })
    if ($matchingIds.Count -ne 1 -or
        (Normalize-ResourceId (Get-PropertyValue $exactMatches[0] 'id')) -ne (Normalize-ResourceId $ExpectedId)) {
        throw "$Description '$Name' does not have the exact approved resource ID."
    }

    $prefixes = @(Get-SubnetPrefixes $exactMatches[0])
    if ($prefixes.Count -ne 1 -or $prefixes[0] -cne $ExpectedPrefix) {
        throw "$Description '$Name' must have the exact address prefix '$ExpectedPrefix'."
    }

    return $exactMatches[0]
}

if ($VirtualNetworksCommandExitCode -ne 0) {
    throw 'Azure virtual-network inventory command failed.'
}
if ($SubnetsCommandExitCode -ne 0) {
    throw 'Azure subnet inventory command failed.'
}
if ($PrivateEndpointsCommandExitCode -ne 0) {
    throw 'Azure private-endpoint inventory command failed.'
}

$virtualNetworks = @(ConvertFrom-AzureListJson $VirtualNetworksJson 'Azure virtual-network')
$subnets = @(ConvertFrom-AzureListJson $SubnetsJson 'Azure subnet')
$privateEndpoints = @(ConvertFrom-AzureListJson $PrivateEndpointsJson 'Azure private-endpoint')

$caseInsensitiveVirtualNetworks = @($virtualNetworks | Where-Object { [string] (Get-PropertyValue $_ 'name') -ieq $expectedVirtualNetworkName })
$exactVirtualNetworks = @($caseInsensitiveVirtualNetworks | Where-Object { [string] (Get-PropertyValue $_ 'name') -ceq $expectedVirtualNetworkName })
if ($caseInsensitiveVirtualNetworks.Count -ne 1 -or $exactVirtualNetworks.Count -ne 1) {
    throw "Expected exactly one virtual network named '$expectedVirtualNetworkName'; found $($exactVirtualNetworks.Count) exact match(es)."
}
$targetVirtualNetworks = @($virtualNetworks | Where-Object {
        (Normalize-ResourceId (Get-PropertyValue $_ 'id')) -eq (Normalize-ResourceId $expectedVirtualNetworkId)
    })
if ($targetVirtualNetworks.Count -ne 1 -or
    (Normalize-ResourceId (Get-PropertyValue $exactVirtualNetworks[0] 'id')) -ne (Normalize-ResourceId $expectedVirtualNetworkId)) {
    throw "Virtual network '$expectedVirtualNetworkName' does not have the exact approved resource ID."
}

$staleSubnets = @($subnets | Where-Object { [string] (Get-PropertyValue $_ 'name') -ieq $rejectedIntegrationSubnetName })
if ($staleSubnets.Count -ne 0) {
    throw "Rejected stale App Service integration subnet '$rejectedIntegrationSubnetName' is present."
}

$integrationSubnet = Assert-ExactSubnet $subnets $expectedIntegrationSubnetName $expectedIntegrationSubnetId $expectedIntegrationPrefix 'App Service integration subnet'
$null = Assert-ExactSubnet $subnets $expectedPrivateEndpointSubnetName $expectedPrivateEndpointSubnetId $expectedPrivateEndpointPrefix 'private-endpoint subnet'

if ((Get-ProviderValue $integrationSubnet 'provisioningState') -cne 'Succeeded') {
    throw "App Service integration subnet '$expectedIntegrationSubnetName' must have provisioningState=Succeeded."
}

$delegations = @(Get-ProviderValue $integrationSubnet 'delegations')
$delegationNames = @(
    foreach ($delegation in $delegations) {
        $serviceName = Get-ProviderValue $delegation 'serviceName'
        if ([string]::IsNullOrWhiteSpace([string] $serviceName)) {
            throw "App Service integration subnet '$expectedIntegrationSubnetName' returned a malformed delegation."
        }
        [string] $serviceName
    }
)
if ($delegationNames.Count -ne 1 -or $delegationNames[0] -cne $expectedDelegation) {
    throw "App Service integration subnet '$expectedIntegrationSubnetName' must contain exactly the '$expectedDelegation' delegation."
}

foreach ($privateEndpoint in $privateEndpoints) {
    $privateEndpointType = [string] (Get-PropertyValue $privateEndpoint 'type')
    $privateEndpointName = [string] (Get-PropertyValue $privateEndpoint 'name')
    $privateEndpointSubnet = Get-ProviderValue $privateEndpoint 'subnet'
    $privateEndpointSubnetId = Get-PropertyValue $privateEndpointSubnet 'id'
    if ($privateEndpointType -cne 'Microsoft.Network/privateEndpoints' -or
        [string]::IsNullOrWhiteSpace($privateEndpointName) -or
        [string]::IsNullOrWhiteSpace([string] $privateEndpointSubnetId)) {
        throw 'Azure private-endpoint inventory contained a malformed resource entry.'
    }

    if ((Normalize-ResourceId $privateEndpointSubnetId) -eq (Normalize-ResourceId $expectedIntegrationSubnetId)) {
        throw "Actual Microsoft.Network/privateEndpoints resource '$privateEndpointName' targets the App Service integration subnet."
    }
}

Write-Output "Azure App Service integration-subnet preflight passed for '$expectedVirtualNetworkName/$expectedIntegrationSubnetName'."
