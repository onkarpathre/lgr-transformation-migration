[CmdletBinding()]
param([string] $CompiledTemplatePath = '')

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$guard = Join-Path $repo 'scripts\build\Assert-AzureDemoPrivateDnsReconciliation.ps1'
$network = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\network.bicep') -Raw
$main = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\main.bicep') -Raw
$privateEndpoints = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\private-endpoints.bicep') -Raw
$pipeline = Get-Content -LiteralPath (Join-Path $repo 'azure-pipelines.yml') -Raw
$parameterFiles = @(
    Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\parameters\azure-demo.bicepparam') -Raw
    Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\parameters\dev.bicepparam') -Raw
)

$expectedLinkName = 'link-mtp-dev-vnet'
$expectedVirtualNetworkId = '/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Network/virtualNetworks/vnet-mtp-dev-uks-001'

function New-Link(
    [string] $Name = $expectedLinkName,
    [string] $VirtualNetworkId = $expectedVirtualNetworkId,
    [bool] $RegistrationEnabled = $false,
    [string] $ProvisioningState = 'Succeeded') {
    return [ordered]@{
        name = $Name
        registrationEnabled = $RegistrationEnabled
        provisioningState = $ProvisioningState
        virtualNetwork = [ordered]@{ id = $VirtualNetworkId }
    }
}

function Test-GuardAccepted([object[]] $Links) {
    $json = ConvertTo-Json -InputObject @($Links) -Depth 8 -Compress
    try {
        & $guard -LinksJson $json -ExpectedLinkName $expectedLinkName -ExpectedVirtualNetworkId $expectedVirtualNetworkId | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Assert-Contains([string] $Text, [string] $Fragment, [string] $Message) {
    if (-not $Text.Contains($Fragment)) {
        throw $Message
    }
}

if (-not (Test-GuardAccepted @(New-Link))) {
    throw 'The exact existing SQL private DNS link contract was rejected.'
}

$negativeCases = @(
    @(),
    @(New-Link -Name 'link-mtp-dev-uks-001'),
    @(New-Link -VirtualNetworkId '/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Network/virtualNetworks/vnet-other'),
    @(New-Link -RegistrationEnabled $true),
    @(New-Link -ProvisioningState 'Failed'),
    @(
        (New-Link),
        (New-Link -Name 'link-duplicate')
    )
)
$rejectedCases = @($negativeCases | Where-Object { -not (Test-GuardAccepted $_) })
if ($rejectedCases.Count -ne $negativeCases.Count) {
    throw "The SQL private DNS guard rejected $($rejectedCases.Count) of $($negativeCases.Count) invalid inventories."
}

foreach ($parameterText in $parameterFiles) {
    if ([regex]::Matches($parameterText, "sqlPrivateDnsVirtualNetworkLink:\s*'link-mtp-dev-vnet'").Count -ne 1) {
        throw 'A Bicep parameter file does not declare the exact existing SQL private DNS link identity once.'
    }
}
Assert-Contains $main "resourceNames.sqlPrivateDnsVirtualNetworkLink == 'link-mtp-dev-vnet'" 'The main template does not fail closed on the existing SQL link identity.'
Assert-Contains $main 'sql: resourceNames.sqlPrivateDnsVirtualNetworkLink' 'The main template does not pass the exact SQL link identity to the network module.'

$zoneContracts = @(
    @{ Symbol = 'appServicePrivateDnsZone'; Name = 'privateDnsZoneNames.appService'; Existing = $false },
    @{ Symbol = 'sqlPrivateDnsZone'; Name = 'privateDnsZoneNames.sql'; Existing = $true },
    @{ Symbol = 'keyVaultPrivateDnsZone'; Name = 'privateDnsZoneNames.keyVault'; Existing = $false },
    @{ Symbol = 'blobPrivateDnsZone'; Name = 'privateDnsZoneNames.blob'; Existing = $false }
)
foreach ($contract in $zoneContracts) {
    $existingSuffix = if ($contract.Existing) { ' existing' } else { '' }
    $declaration = "resource $($contract.Symbol) 'Microsoft.Network/privateDnsZones@2024-06-01'$existingSuffix = {"
    Assert-Contains $network $declaration "Private DNS zone declaration is invalid for $($contract.Symbol)."
    Assert-Contains $network "name: $($contract.Name)" "Private DNS zone name wiring is invalid for $($contract.Symbol)."
}

$linkContracts = @(
    @{ Symbol = 'sqlVirtualNetworkLink'; Parent = 'sqlPrivateDnsZone'; Name = 'virtualNetworkLinkNames.sql' },
    @{ Symbol = 'appServiceVirtualNetworkLink'; Parent = 'appServicePrivateDnsZone'; Name = 'virtualNetworkLinkNames.appService' },
    @{ Symbol = 'keyVaultVirtualNetworkLink'; Parent = 'keyVaultPrivateDnsZone'; Name = 'virtualNetworkLinkNames.keyVault' },
    @{ Symbol = 'blobVirtualNetworkLink'; Parent = 'blobPrivateDnsZone'; Name = 'virtualNetworkLinkNames.blob' }
)
foreach ($contract in $linkContracts) {
    $zoneDeclaration = "resource $($contract.Parent) "
    $linkDeclaration = "resource $($contract.Symbol) 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {"
    Assert-Contains $network $linkDeclaration "Private DNS link declaration is invalid for $($contract.Symbol)."
    Assert-Contains $network "parent: $($contract.Parent)" "Private DNS link does not use its symbolic zone parent for $($contract.Symbol)."
    Assert-Contains $network "name: $($contract.Name)" "Private DNS link name wiring is invalid for $($contract.Symbol)."
    if ($network.IndexOf($zoneDeclaration, [StringComparison]::Ordinal) -ge $network.IndexOf($linkDeclaration, [StringComparison]::Ordinal)) {
        throw "Private DNS parent must be declared before child link $($contract.Symbol)."
    }
}

if ([regex]::Matches($network, "Microsoft\.Network/privateDnsZones/virtualNetworkLinks@2024-06-01").Count -ne 4 -or
    [regex]::Matches($network, 'registrationEnabled:\s*false').Count -ne 4 -or
    [regex]::Matches($network, 'parent:\s*(?:sql|appService|keyVault|blob)PrivateDnsZone').Count -ne 4) {
    throw 'The network module must declare exactly one registration-disabled VNet link for each of the four private DNS zones.'
}

foreach ($fragment in @(
        'appService: appServicePrivateDnsZone.id',
        'sql: sqlPrivateDnsZone.id',
        'keyVault: keyVaultPrivateDnsZone.id',
        'blob: blobPrivateDnsZone.id')) {
    Assert-Contains $network $fragment "The private DNS zone ID output is missing or incorrect: $fragment"
}
foreach ($fragment in @(
        'zoneId: privateDnsZoneIds.appService',
        'zoneId: privateDnsZoneIds.keyVault',
        'zoneId: privateDnsZoneIds.blob',
        'privateDnsZoneId: privateDnsZoneIds.sql')) {
    Assert-Contains $privateEndpoints $fragment "A private-endpoint DNS-zone-group binding is missing or incorrect: $fragment"
}

$preDeploymentGate = $pipeline.Substring(
    $pipeline.IndexOf('- stage: PreDeploymentGate', [StringComparison]::Ordinal),
    $pipeline.IndexOf('- stage: MigrateAndDeploySlots', [StringComparison]::Ordinal) - $pipeline.IndexOf('- stage: PreDeploymentGate', [StringComparison]::Ordinal))
foreach ($fragment in @(
        "@{ Type = 'Microsoft.Network/privateDnsZones'; Name = 'privatelink.database.windows.net' }",
        'az network private-dns link vnet list',
        "'link-mtp-dev-vnet'",
        $expectedVirtualNetworkId,
        'Assert-AzureDemoPrivateDnsReconciliation.ps1')) {
    Assert-Contains $preDeploymentGate $fragment "The private DNS predeployment contract is missing: $fragment"
}
$guardIndex = $preDeploymentGate.IndexOf('Assert-AzureDemoPrivateDnsReconciliation.ps1', [StringComparison]::Ordinal)
$whatIfIndex = $preDeploymentGate.IndexOf('az deployment group what-if', [StringComparison]::Ordinal)
if ($guardIndex -lt 0 -or $whatIfIndex -lt 0 -or $guardIndex -ge $whatIfIndex) {
    throw 'The SQL private DNS fail-closed guard must run before ARM what-if.'
}

if ($network -match '(?i)uniqueString|newGuid|delete' -or
    $preDeploymentGate -match '(?i)private-dns[^\r\n]*(?:delete|remove)') {
    throw 'Private DNS reconciliation must use stable resource identities and must not contain a delete path.'
}

if (-not [string]::IsNullOrWhiteSpace($CompiledTemplatePath)) {
    $compiledPath = (Resolve-Path -LiteralPath $CompiledTemplatePath).Path
    $compiled = Get-Content -LiteralPath $compiledPath -Raw | ConvertFrom-Json
    $compiledNetwork = $compiled.resources.network.properties.template.resources
    $compiledZones = @($compiledNetwork.PSObject.Properties | Where-Object { $_.Value.type -eq 'Microsoft.Network/privateDnsZones' })
    $compiledLinks = @($compiledNetwork.PSObject.Properties | Where-Object { $_.Value.type -eq 'Microsoft.Network/privateDnsZones/virtualNetworkLinks' })
    if ($compiledZones.Count -ne 4 -or $compiledLinks.Count -ne 4) {
        throw 'The compiled network template must contain four private DNS zone symbols and four VNet links.'
    }
    if ($compiledNetwork.sqlPrivateDnsZone.existing -ne $true -or
        $null -ne $compiledNetwork.appServicePrivateDnsZone.existing -or
        $null -ne $compiledNetwork.keyVaultPrivateDnsZone.existing -or
        $null -ne $compiledNetwork.blobPrivateDnsZone.existing) {
        throw 'Only the SQL private DNS zone may compile as existing; the other three zones must be deployable parents.'
    }
    foreach ($contract in $linkContracts) {
        $compiledLink = $compiledNetwork.($contract.Symbol)
        if ($compiledLink.properties.registrationEnabled -ne $false) {
            throw "Compiled private DNS link must have registrationEnabled=false: $($contract.Symbol)."
        }
        if ($contract.Symbol -ne 'sqlVirtualNetworkLink' -and @($compiledLink.dependsOn) -notcontains $contract.Parent) {
            throw "Compiled private DNS child does not depend on its managed parent: $($contract.Symbol)."
        }
    }
    if (-not $compiledNetwork.sqlVirtualNetworkLink.name.Contains("parameters('virtualNetworkLinkNames').sql")) {
        throw 'The compiled SQL VNet link does not use the exact SQL-specific link identity.'
    }
}

Write-Output 'Azure demo private DNS reconciliation regression passed: 1 valid inventory accepted; 6 invalid inventories rejected; four deterministic parent/link and zone-group contracts verified.'
