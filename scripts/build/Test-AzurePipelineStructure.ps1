[CmdletBinding()]
param([string] $Path = 'azure-pipelines.yml')

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$pipelinePath = (Resolve-Path (Join-Path $repo $Path)).Path
$text = Get-Content -LiteralPath $pipelinePath -Raw
$lines = Get-Content -LiteralPath $pipelinePath

if ($text.Contains("`t")) { throw 'Azure Pipelines YAML contains tab indentation.' }
if ($lines | Where-Object { $_ -match '\s+$' }) { throw 'Azure Pipelines YAML contains trailing whitespace.' }

$expectedStages = @(
    'Validate',
    'Package',
    'PreDeploymentGate',
    'MigrateAndDeploySlots',
    'ReleaseApproval',
    'SwapAndVerify',
    'Rollback'
)
$actualStages = @($lines | ForEach-Object { if ($_ -match '^- stage:\s+([A-Za-z][A-Za-z0-9_]*)\s*$') { $Matches[1] } })
if (($actualStages -join '|') -ne ($expectedStages -join '|')) {
    throw "Azure Pipelines stage order is invalid: $($actualStages -join ', ')."
}

$requiredFragments = @(
    'name: deployAzureDemo',
    'name: rollbackAzureDemo',
    'name: rollbackReleaseIdentifier',
    'name: rollbackEnvironmentName',
    'name: rollbackResourceGroupName',
    'name: rollbackWebAppName',
    'name: rollbackApiAppName',
    'name: rollbackWebSlotName',
    'name: rollbackApiSlotName',
    'name: rollbackTargetSlotName',
    'eq(''${{ parameters.deployAzureDemo }}'', true)',
    'eq(''${{ parameters.rollbackAzureDemo }}'', true)',
    'eq(''${{ parameters.rollbackReleaseIdentifier }}'', variables[''Build.SourceVersion''])',
    'eq(''${{ parameters.rollbackEnvironmentName }}'', ''mtp-azure-demo-dev'')',
    'eq(''${{ parameters.rollbackResourceGroupName }}'', variables[''AZDEMO_RESOURCE_GROUP_NAME''])',
    'eq(''${{ parameters.rollbackWebAppName }}'', variables[''AZDEMO_WEB_APP_NAME''])',
    'eq(''${{ parameters.rollbackApiAppName }}'', variables[''AZDEMO_API_APP_NAME''])',
    'in(dependencies.SwapAndVerify.result, ''Succeeded'', ''SucceededWithIssues'', ''Failed'')',
    "eq(variables['Build.DefinitionName'], 'mtp-azure-demo-deploy')",
    "eq(variables['Build.SourceBranch'], 'refs/heads/release/azure-demo-v1')",
    'group: vg-mtp-azdemo-public',
    'environment: mtp-azure-demo-dev',
    'pool: { name: mdp-mtp-dev-uks-001 }',
    'azureSubscription: sc-mtp-azure-demo-dev',
    'deployToSlotOrASE: true',
    'slotName: staging',
    'ManualValidation@0',
    'az deployment group what-if',
    'lgrtm-efbundle-linux-x64',
    'Invoke-AzureDemoSmokeTests.ps1',
    'Assert-AzureDemoRollbackTarget.ps1',
    'Assert-AzureDemoMigrationTarget.ps1',
    'az webapp deployment slot swap'
)
foreach ($fragment in $requiredFragments) {
    if (-not $text.Contains($fragment)) { throw "Azure Pipelines YAML is missing required structure: $fragment" }
}

$obsoleteAzureDevOpsNames = @('vg-lgrtm-azdemo-public', 'environment: azure-demo-staging', 'environment: azure-demo', '$(AZDEMO_PRIVATE_AGENT_POOL)', '$(AZDEMO_WIF_SERVICE_CONNECTION)')
foreach ($name in $obsoleteAzureDevOpsNames) {
    if ($text.Contains($name)) { throw "Azure Pipelines YAML retains an obsolete Azure DevOps deployment reference: $name" }
}

$deployParameter = [regex]::Match($text, '(?ms)- name: deployAzureDemo\s+type: boolean\s+default: false')
$rollbackParameter = [regex]::Match($text, '(?ms)- name: rollbackAzureDemo\s+type: boolean\s+default: false')
if (-not $deployParameter.Success -or -not $rollbackParameter.Success) {
    throw 'Azure deployment and rollback parameters must both default to false.'
}

$swap = $text.Substring($text.IndexOf('- stage: SwapAndVerify', [StringComparison]::Ordinal),
    $text.IndexOf('- stage: Rollback', [StringComparison]::Ordinal) - $text.IndexOf('- stage: SwapAndVerify', [StringComparison]::Ordinal))
$rollback = $text.Substring($text.IndexOf('- stage: Rollback', [StringComparison]::Ordinal))
if ($swap.IndexOf('$(AZDEMO_API_APP_NAME)', [StringComparison]::Ordinal) -ge $swap.IndexOf('$(AZDEMO_WEB_APP_NAME)', [StringComparison]::Ordinal)) {
    throw 'Approved swap order must be API before web.'
}
if ($rollback.IndexOf('$(AZDEMO_WEB_APP_NAME)', [StringComparison]::Ordinal) -ge $rollback.IndexOf('$(AZDEMO_API_APP_NAME)', [StringComparison]::Ordinal)) {
    throw 'Rollback target comparisons must list the web application before the API application.'
}
if ($rollback.IndexOf('--name $env:ROLLBACK_WEB_APP', [StringComparison]::Ordinal) -ge $rollback.IndexOf('--name $env:ROLLBACK_API_APP', [StringComparison]::Ordinal)) {
    throw 'Approved rollback execution order must be web before API.'
}
if ($rollback.IndexOf('Assert-AzureDemoRollbackTarget.ps1', [StringComparison]::Ordinal) -ge $rollback.IndexOf('AzureCLI@2', [StringComparison]::Ordinal)) {
    throw 'Rollback target validation must run before any Azure task.'
}

Write-Output "Azure Pipelines structural contract passed for $($actualStages.Count) ordered stages."
