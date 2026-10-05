[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$resolver = Join-Path $repo 'scripts\smoke\Resolve-AzureDemoSmokeTargets.ps1'
$runner = Join-Path $repo 'scripts\smoke\Invoke-AzureDemoSmokeTests.ps1'
$catalogPath = Join-Path $repo 'scripts\smoke\smoke-checks.json'
$subscriptionId = '633398e2-6c00-4bb7-a576-2db0d210ee77'
$tenantId = '11111111-2222-4333-8444-555555555555'
$resourceGroup = 'Onkar.Pathre'
$webApp = 'app-mtp-web-dev-uks-001'
$apiApp = 'app-mtp-api-dev-uks-001'

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw $Message }
}

function New-ResourceJson([string] $AppName, [string] $SlotName, [string] $HostName) {
    $slotSuffix = if ($SlotName -eq 'production') { '' } else { "/slots/$SlotName" }
    $name = if ($SlotName -eq 'production') { $AppName } else { "$AppName/$SlotName" }
    $type = if ($SlotName -eq 'production') { 'Microsoft.Web/sites' } else { 'Microsoft.Web/sites/slots' }
    return [ordered]@{
        id = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$AppName$slotSuffix"
        name = $name
        resourceGroup = $resourceGroup
        type = $type
        defaultHostName = $HostName
    } | ConvertTo-Json -Compress
}

$webProductionHost = "$webApp-csdtetbtbeh3h7fy.uksouth-01.azurewebsites.net"
$webStagingHost = "$webApp-staging-csdtetbtbeh3h7fy.uksouth-01.azurewebsites.net"
$apiProductionHost = "$apiApp-d4f5g6h7j8k9m2n3.uksouth-01.azurewebsites.net"
$apiStagingHost = "$apiApp-staging-d4f5g6h7j8k9m2n3.uksouth-01.azurewebsites.net"
$valid = @{
    ExpectedSubscriptionId = $subscriptionId
    ExpectedTenantId = $tenantId
    ExpectedResourceGroupName = $resourceGroup
    ExpectedWebAppName = $webApp
    ExpectedApiAppName = $apiApp
    ExpectedSlotName = 'staging'
    AccountJson = ([ordered]@{ id = $subscriptionId; tenantId = $tenantId } | ConvertTo-Json -Compress)
    AccountCommandExitCode = 0
    WebProductionJson = New-ResourceJson $webApp production $webProductionHost
    WebProductionCommandExitCode = 0
    WebSlotJson = New-ResourceJson $webApp staging $webStagingHost
    WebSlotCommandExitCode = 0
    ApiProductionJson = New-ResourceJson $apiApp production $apiProductionHost
    ApiProductionCommandExitCode = 0
    ApiSlotJson = New-ResourceJson $apiApp staging $apiStagingHost
    ApiSlotCommandExitCode = 0
}

$resolved = & $resolver @valid
Assert-True ($resolved.WebProductionHost -ceq $webProductionHost) 'Generated web production hostname was not retained.'
Assert-True ($resolved.WebStagingHost -ceq $webStagingHost) 'Azure-reported generated web staging hostname was not retained.'
Assert-True ($resolved.ApiProductionHost -ceq $apiProductionHost) 'Generated API production hostname was not retained.'
Assert-True ($resolved.ApiStagingHost -ceq $apiStagingHost) 'Generated API staging hostname was not retained.'

$invalidCases = @(
    @{ Name = 'nonzero account query'; Change = @{ AccountCommandExitCode = 1 } },
    @{ Name = 'empty account response'; Change = @{ AccountJson = ' ' } },
    @{ Name = 'malformed account response'; Change = @{ AccountJson = '{' } },
    @{ Name = 'wrong subscription'; Change = @{ AccountJson = '{"id":"aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee","tenantId":"11111111-2222-4333-8444-555555555555"}' } },
    @{ Name = 'wrong resource group'; Change = @{ WebSlotJson = ((New-ResourceJson $webApp staging $webStagingHost) -replace 'Onkar\.Pathre', 'Other.Group') } },
    @{ Name = 'wrong app'; Change = @{ WebSlotJson = ((New-ResourceJson $webApp staging $webStagingHost) -replace '/sites/app-mtp-web-dev-uks-001/', '/sites/app-mtp-web-dev-uks-999/') } },
    @{ Name = 'wrong slot'; Change = @{ WebSlotJson = ((New-ResourceJson $webApp staging $webStagingHost) -replace '/staging"', '/other"') } },
    @{ Name = 'substituted host'; Change = @{ WebSlotJson = New-ResourceJson $webApp staging 'other-app-staging-csdtetbtbeh3h7fy.uksouth-01.azurewebsites.net' } },
    @{ Name = 'host with scheme'; Change = @{ WebSlotJson = New-ResourceJson $webApp staging "https://$webStagingHost" } },
    @{ Name = 'host with userinfo'; Change = @{ WebSlotJson = New-ResourceJson $webApp staging "user@$webStagingHost" } },
    @{ Name = 'host with port'; Change = @{ WebSlotJson = New-ResourceJson $webApp staging "${webStagingHost}:443" } },
    @{ Name = 'arbitrary Azure hostname'; Change = @{ WebSlotJson = New-ResourceJson $webApp staging 'arbitrary.azurewebsites.net' } }
)
foreach ($case in $invalidCases) {
    $arguments = @{} + $valid
    foreach ($key in $case.Change.Keys) { $arguments[$key] = $case.Change[$key] }
    $rejected = $false
    try { & $resolver @arguments | Out-Null } catch { $rejected = $true }
    Assert-True $rejected "Resolver accepted invalid case: $($case.Name)."
}

$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$expectedCatalog = @(1..22 | ForEach-Object { 'SMK-{0:D2}' -f $_ })
$actualCatalog = @(foreach ($catalogItem in $catalog) { [string] $catalogItem.id })
Assert-True (($actualCatalog -join '|') -ceq ($expectedCatalog -join '|')) 'Smoke catalogue order or membership changed.'

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-smoke-target-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
try {
    $manifestPath = Join-Path $temporaryDirectory 'deployment-artifact-manifest.json'
    $manifestFixture = [ordered]@{ schemaVersion = '1'; sourceCommit = ('a' * 40); createdAtUtc = '2026-10-05T00:00:00Z'; artifacts = @() }
    Set-Content -LiteralPath $manifestPath -Value ($manifestFixture | ConvertTo-Json -Compress) -Encoding UTF8
    $common = @{
        TargetSubscriptionId = $subscriptionId
        TargetResourceGroupName = $resourceGroup
        TargetWebAppName = $webApp
        TargetApiAppName = $apiApp
        ExpectedCommit = ('a' * 40)
        ArtifactManifest = $manifestPath
        EvidenceDirectory = (Join-Path $temporaryDirectory 'evidence')
    }
    & $runner @common -WebBaseUri "https://$webStagingHost" -VerifiedWebHost $webStagingHost -VerifiedApiHost $apiStagingHost -TargetSlotName staging | Out-Null
    & $runner @common -WebBaseUri "https://$webProductionHost" -VerifiedWebHost $webProductionHost -VerifiedApiHost $apiProductionHost -TargetSlotName production | Out-Null

    foreach ($invalidTarget in @(
            @{ WebBaseUri = "https://$webProductionHost"; VerifiedWebHost = $webProductionHost; VerifiedApiHost = $apiProductionHost; TargetSlotName = 'staging' },
            @{ WebBaseUri = "https://$webStagingHost`:444/"; VerifiedWebHost = $webStagingHost; VerifiedApiHost = $apiStagingHost; TargetSlotName = 'staging' },
            @{ WebBaseUri = "https://user@$webStagingHost/"; VerifiedWebHost = $webStagingHost; VerifiedApiHost = $apiStagingHost; TargetSlotName = 'staging' },
            @{ WebBaseUri = "http://$webStagingHost/"; VerifiedWebHost = $webStagingHost; VerifiedApiHost = $apiStagingHost; TargetSlotName = 'staging' },
            @{ WebBaseUri = "https://$webStagingHost/?token=secret"; VerifiedWebHost = $webStagingHost; VerifiedApiHost = $apiStagingHost; TargetSlotName = 'staging' }
        )) {
        $rejected = $false
        try { & $runner @common @invalidTarget | Out-Null } catch { $rejected = $true }
        Assert-True $rejected 'Smoke runner accepted a wrong slot, unsafe URI or substituted target.'
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}

$runnerText = Get-Content -LiteralPath $runner -Raw
Assert-True ($runnerText -notmatch '(?i)\.Host\s+-like|\*\.azurewebsites\.net') 'Smoke runner contains a wildcard Azure hostname allowlist.'
Assert-True ($runnerText.Contains('Safe evidence was retained.')) 'Smoke runner does not retain a safe aggregate failure contract.'
Write-Output "Azure demo smoke target regression passed generated-host, exact-identity, staging/production, unsafe URI and catalogue-order checks ($($invalidCases.Count) invalid resolver cases)."
