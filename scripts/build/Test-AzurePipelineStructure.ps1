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
    'eq(''${{ parameters.deployAzureDemo }}'', true)',
    "eq(variables['Build.SourceBranch'], 'refs/heads/release/azure-demo-v1')",
    'environment: azure-demo-staging',
    'environment: azure-demo',
    'deployToSlotOrASE: true',
    'slotName: staging',
    'ManualValidation@0',
    'az deployment group what-if',
    'lgrtm-efbundle-linux-x64',
    'Invoke-AzureDemoSmokeTests.ps1',
    'az webapp deployment slot swap'
)
foreach ($fragment in $requiredFragments) {
    if (-not $text.Contains($fragment)) { throw "Azure Pipelines YAML is missing required structure: $fragment" }
}

$deployParameter = [regex]::Match($text, '(?ms)- name: deployAzureDemo\s+type: boolean\s+default: false')
$rollbackParameter = [regex]::Match($text, '(?ms)- name: rollbackAzureDemo\s+type: boolean\s+default: false')
if (-not $deployParameter.Success -or -not $rollbackParameter.Success) {
    throw 'Azure deployment and rollback parameters must both default to false.'
}

$swap = $text.Substring($text.IndexOf('- stage: SwapAndVerify', [StringComparison]::Ordinal),
    $text.IndexOf('- stage: Rollback', [StringComparison]::Ordinal) - $text.IndexOf('- stage: SwapAndVerify', [StringComparison]::Ordinal))
$rollback = $text.Substring($text.IndexOf('- stage: Rollback', [StringComparison]::Ordinal))
if ($swap.IndexOf('$(apiAppName)', [StringComparison]::Ordinal) -ge $swap.IndexOf('$(webAppName)', [StringComparison]::Ordinal)) {
    throw 'Approved swap order must be API before web.'
}
if ($rollback.IndexOf('$(webAppName)', [StringComparison]::Ordinal) -ge $rollback.IndexOf('$(apiAppName)', [StringComparison]::Ordinal)) {
    throw 'Approved rollback order must be web before API.'
}

Write-Output "Azure Pipelines structural contract passed for $($actualStages.Count) ordered stages."
