[CmdletBinding()]
param([string] $Path = 'azure-pipelines.yml')

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$pipelinePath = (Resolve-Path (Join-Path $repo $Path)).Path
$text = Get-Content -LiteralPath $pipelinePath -Raw
$lines = Get-Content -LiteralPath $pipelinePath
$parameterEnvironmentScript = Join-Path $repo 'scripts\build\Test-AzureDemoParameterEnvironment.ps1'
$efArtifactScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\build\New-EfMigrationArtifacts.ps1') -Raw

if ($text.Contains("`t")) { throw 'Azure Pipelines YAML contains tab indentation.' }
if ($lines | Where-Object { $_ -match '\s+$' }) { throw 'Azure Pipelines YAML contains trailing whitespace.' }

$requiredParameterVariables = @(
    'AZDEMO_OWNER',
    'AZDEMO_COST_CENTRE',
    'AZDEMO_EXPIRY_DATE',
    'AZDEMO_ENTRA_TENANT_ID',
    'AZDEMO_SPA_CLIENT_ID',
    'AZDEMO_API_CLIENT_ID',
    'AZDEMO_SQL_ADMIN_OBJECT_ID',
    'AZDEMO_SQL_ADMIN_NAME',
    'AZDEMO_DEPLOYMENT_PRINCIPAL_OBJECT_ID',
    'AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID',
    'AZDEMO_ALERT_EMAIL'
)
$requiredParameterAssignments = @{
    AZDEMO_OWNER = "param owner = readEnvironmentVariable('AZDEMO_OWNER')"
    AZDEMO_COST_CENTRE = "param costCentre = readEnvironmentVariable('AZDEMO_COST_CENTRE')"
    AZDEMO_EXPIRY_DATE = "param expiryDate = readEnvironmentVariable('AZDEMO_EXPIRY_DATE')"
    AZDEMO_ENTRA_TENANT_ID = "param entraTenantId = readEnvironmentVariable('AZDEMO_ENTRA_TENANT_ID')"
    AZDEMO_SPA_CLIENT_ID = "param spaClientId = readEnvironmentVariable('AZDEMO_SPA_CLIENT_ID')"
    AZDEMO_API_CLIENT_ID = "param apiClientId = readEnvironmentVariable('AZDEMO_API_CLIENT_ID')"
    AZDEMO_SQL_ADMIN_OBJECT_ID = "param sqlEntraAdminObjectId = readEnvironmentVariable('AZDEMO_SQL_ADMIN_OBJECT_ID')"
    AZDEMO_SQL_ADMIN_NAME = "param sqlEntraAdminName = readEnvironmentVariable('AZDEMO_SQL_ADMIN_NAME')"
    AZDEMO_DEPLOYMENT_PRINCIPAL_OBJECT_ID = "param deploymentPrincipalObjectId = readEnvironmentVariable('AZDEMO_DEPLOYMENT_PRINCIPAL_OBJECT_ID')"
    AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID = "param migrationPrincipalObjectId = readEnvironmentVariable('AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID')"
    AZDEMO_ALERT_EMAIL = "param alertEmailAddress = readEnvironmentVariable('AZDEMO_ALERT_EMAIL')"
}
$approvedMigrationVariables = [ordered]@{
    AZDEMO_MIGRATION_PRINCIPAL_CLIENT_ID = 'f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7'
    AZDEMO_MIGRATION_PRINCIPAL_NAME = 'id-mtp-migration-dev-uks-001'
    AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID = '9b984b84-7ebe-45ca-9441-7b2f41fd8f6c'
    AZDEMO_MIGRATION_WIF_SERVICE_CONNECTION = 'sc-mtp-azure-demo-migration-dev'
}

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
    'azureSubscription: sc-mtp-azure-demo-migration-dev',
    'deployToSlotOrASE: true',
    'slotName: staging',
    'ManualValidation@0',
    'az deployment group what-if',
    'lgrtm-efbundle-linux-x64',
    'Invoke-AzureDemoSmokeTests.ps1',
    'Assert-AzureDemoRollbackTarget.ps1',
    'Assert-AzureDemoMigrationTarget.ps1',
    'Assert-AzureDemoMigrationIdentity.ps1',
    'Assert-AzureDemoSqlBootstrapEvidence.ps1',
    'Test-AzureDemoSqlBootstrapEvidence.ps1',
    'Test-AzureDemoDatabasePrincipalSql.ps1',
    'id-mtp-migration-dev-uks-001',
    'Authentication=Active Directory Workload Identity',
    'Test-AzureDemoSboms.ps1',
    "New-AzureDemoSboms.ps1 -OutputDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/sbom'",
    'publish: $(Build.SourcesDirectory)/artifacts/azure-demo-ci/sbom',
    'artifact: dependency-sboms',
    "New-AzureDemoPackages.ps1 -OutputDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages/application'",
    'Test-EfMigrationArtifactParsing.ps1',
    "New-EfMigrationArtifacts.ps1 -OutputDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages/migration'",
    "Test-AzureDemoArtifacts.ps1 -ArtifactDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages/application'",
    "Test-AzureDemoPackageGeneration.ps1 -PackageDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages'",
    'publish: $(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages',
    'az webapp deployment slot swap'
)
foreach ($fragment in $requiredFragments) {
    if (-not $text.Contains($fragment)) { throw "Azure Pipelines YAML is missing required structure: $fragment" }
}

$stagesIndex = $text.IndexOf("`nstages:", [StringComparison]::Ordinal)
if ($stagesIndex -lt 0 -or -not $text.Substring(0, $stagesIndex).Contains('- group: vg-mtp-azdemo-public')) {
    throw 'The Azure demo public variable group must be imported at pipeline scope for validation and deployment stages.'
}

function Get-YamlStepBlock([string[]] $PipelineLines, [string] $CommandPattern) {
    $commandIndexes = @(for ($index = 0; $index -lt $PipelineLines.Count; $index++) {
            if ($PipelineLines[$index] -match $CommandPattern) { $index }
        })
    if ($commandIndexes.Count -ne 1) {
        throw "Expected one pipeline command matching '$CommandPattern' but found $($commandIndexes.Count)."
    }

    $commandIndex = $commandIndexes[0]
    $stepStart = -1
    $stepIndent = -1
    for ($index = $commandIndex; $index -ge 0; $index--) {
        if ($PipelineLines[$index] -match '^(\s*)-\s+(?:task:|pwsh:|powershell:|script:|bash:)') {
            $stepStart = $index
            $stepIndent = $Matches[1].Length
            break
        }
    }
    if ($stepStart -lt 0) { throw "Could not locate the pipeline step for '$CommandPattern'." }

    $stepEnd = $PipelineLines.Count
    for ($index = $stepStart + 1; $index -lt $PipelineLines.Count; $index++) {
        if ($PipelineLines[$index] -match '^(\s*)-\s+' -and $Matches[1].Length -eq $stepIndent) {
            $stepEnd = $index
            break
        }
    }

    return ($PipelineLines[$stepStart..($stepEnd - 1)] -join "`n")
}

$parameterConsumerSteps = @(
    (Get-YamlStepBlock $lines 'az bicep build-params --file infra/bicep/parameters/azure-demo\.bicepparam')
    (Get-YamlStepBlock $lines 'az deployment group what-if .*infra/bicep/parameters/azure-demo\.bicepparam')
    (Get-YamlStepBlock $lines 'az deployment group create .*infra/bicep/parameters/azure-demo\.bicepparam')
)
foreach ($step in $parameterConsumerSteps) {
    if (-not $step.Contains('./scripts/build/Test-AzureDemoParameterEnvironment.ps1')) {
        throw 'Every Bicep parameter consumer must run the fail-closed environment preflight in the same process environment.'
    }
    foreach ($name in $requiredParameterVariables) {
        $mappingPattern = "(?m)^\s+$([regex]::Escape($name)):\s+\$\($([regex]::Escape($name))\)\s*$"
        if ([regex]::Matches($step, $mappingPattern).Count -ne 1) {
            throw "A Bicep parameter consumer does not map required process environment variable $name exactly once."
        }
    }
}

foreach ($name in $requiredParameterVariables) {
    $namedVariablePattern = "(?ms)^\s*-\s+name:\s*$([regex]::Escape($name))\s*\r?`n\s+value:"
    $hardCodedEnvironmentPattern = "(?m)^\s+$([regex]::Escape($name)):\s+(?!\$\($([regex]::Escape($name))\)\s*$).+$"
    $approvedLockedObjectId = $name -eq 'AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID' -and
        $text -match "(?ms)^\s*-\s+name:\s+AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID\s*\r?`n\s+value:\s+9b984b84-7ebe-45ca-9441-7b2f41fd8f6c\s*\r?`n\s+readonly:\s+true\s*$"
    if ((($text -match $namedVariablePattern) -and -not $approvedLockedObjectId) -or $text -match $hardCodedEnvironmentPattern) {
        throw "Azure Pipelines YAML must source $name from the variable group without a hard-coded override."
    }
}

foreach ($name in $approvedMigrationVariables.Keys) {
    $expectedValue = $approvedMigrationVariables[$name]
    $lockedVariablePattern = "(?ms)^\s*-\s+name:\s+$([regex]::Escape($name))\s*\r?`n\s+value:\s+$([regex]::Escape($expectedValue))\s*\r?`n\s+readonly:\s+true\s*$"
    if ($text -notmatch $lockedVariablePattern) {
        throw "Azure Pipelines YAML must retain exact read-only migration variable $name."
    }
}

foreach ($parameterFile in @('infra\bicep\parameters\azure-demo.bicepparam', 'infra\bicep\parameters\dev.bicepparam')) {
    $parameterText = Get-Content -LiteralPath (Join-Path $repo $parameterFile) -Raw
    foreach ($name in $requiredParameterVariables) {
        if (-not $parameterText.Contains($requiredParameterAssignments[$name])) {
            throw "$parameterFile does not assign the approved parameter from required environment variable $name."
        }
    }
    if ($parameterText -match '(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b' -or
        $parameterText -match '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b') {
        throw "$parameterFile contains a hard-coded GUID or email address."
    }
}

if (-not (Test-Path -LiteralPath $parameterEnvironmentScript -PathType Leaf)) {
    throw 'The fail-closed Azure demo parameter environment preflight script is missing.'
}

$savedEnvironment = @{}
foreach ($name in $requiredParameterVariables) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, [EnvironmentVariableTarget]::Process)
}

try {
    $validEnvironment = @{
        AZDEMO_OWNER = 'Synthetic Validation Owner'
        AZDEMO_COST_CENTRE = 'SYNTHETIC-VALIDATION'
        AZDEMO_EXPIRY_DATE = [DateTime]::UtcNow.AddYears(1).ToString('yyyy-MM-dd')
        AZDEMO_ENTRA_TENANT_ID = [Guid]::NewGuid().ToString()
        AZDEMO_SPA_CLIENT_ID = [Guid]::NewGuid().ToString()
        AZDEMO_API_CLIENT_ID = [Guid]::NewGuid().ToString()
        AZDEMO_SQL_ADMIN_OBJECT_ID = [Guid]::NewGuid().ToString()
        AZDEMO_SQL_ADMIN_NAME = 'Synthetic Validation Administrator'
        AZDEMO_DEPLOYMENT_PRINCIPAL_OBJECT_ID = [Guid]::NewGuid().ToString()
        AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID = [Guid]::NewGuid().ToString()
        AZDEMO_ALERT_EMAIL = ('{0}@{1}' -f 'pipeline-validation', 'example.invalid')
    }

    function Set-ValidParameterEnvironment {
        foreach ($name in $requiredParameterVariables) {
            [Environment]::SetEnvironmentVariable($name, $validEnvironment[$name], [EnvironmentVariableTarget]::Process)
        }
    }

    function Assert-ParameterEnvironmentRejected([string] $Name, [AllowNull()] [string] $Value) {
        Set-ValidParameterEnvironment
        [Environment]::SetEnvironmentVariable($Name, $Value, [EnvironmentVariableTarget]::Process)
        try {
            & $parameterEnvironmentScript | Out-Null
            throw "Parameter environment preflight accepted invalid variable $Name."
        }
        catch {
            if (-not $_.Exception.Message.Contains($Name)) {
                throw "Parameter environment preflight rejection did not identify variable $Name."
            }
            if (-not [string]::IsNullOrEmpty($Value) -and $_.Exception.Message.Contains($Value)) {
                throw "Parameter environment preflight disclosed the value of variable $Name."
            }
        }
    }

    Set-ValidParameterEnvironment
    & $parameterEnvironmentScript | Out-Null
    foreach ($name in $requiredParameterVariables) {
        Assert-ParameterEnvironmentRejected $name $null
    }
    Assert-ParameterEnvironmentRejected 'AZDEMO_OWNER' '   '
    Assert-ParameterEnvironmentRejected 'AZDEMO_OWNER' '$(AZDEMO_OWNER)'
    foreach ($name in @(
            'AZDEMO_ENTRA_TENANT_ID',
            'AZDEMO_SPA_CLIENT_ID',
            'AZDEMO_API_CLIENT_ID',
            'AZDEMO_SQL_ADMIN_OBJECT_ID',
            'AZDEMO_DEPLOYMENT_PRINCIPAL_OBJECT_ID',
            'AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID')) {
        Assert-ParameterEnvironmentRejected $name 'not-a-guid'
    }
    Assert-ParameterEnvironmentRejected 'AZDEMO_EXPIRY_DATE' '31/12/2099'
    Assert-ParameterEnvironmentRejected 'AZDEMO_ALERT_EMAIL' 'not-an-email-address'
}
finally {
    foreach ($name in $requiredParameterVariables) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], [EnvironmentVariableTarget]::Process)
    }
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

$migrationStep = Get-YamlStepBlock $lines "lgrtm-efbundle-linux-x64' --connection"
$seedStep = Get-YamlStepBlock $lines 'Invoke-AzureDemoSeed\.ps1 -Environment AzureDemo'
foreach ($step in @($migrationStep, $seedStep)) {
    if ($step -notmatch '^\s*- task: AzureCLI@2' -or
        $step -notmatch '(?m)^\s+azureSubscription:\s+sc-mtp-azure-demo-migration-dev\s*$' -or
        $step -notmatch '(?m)^\s+addSpnToEnvironment:\s+true\s*$' -or
        -not $step.Contains('Assert-AzureDemoMigrationIdentity.ps1') -or
        -not $step.Contains('az account get-access-token --resource https://database.windows.net/') -or
        -not $step.Contains('az account show --query tenantId') -or
        -not $step.Contains("Join-Path '`$(Agent.TempDirectory)'") -or
        -not $step.Contains('[IO.File]::WriteAllText($federatedTokenFile, $env:idToken') -or
        -not $step.Contains('Remove-Item -LiteralPath $federatedTokenFile -Force') -or
        -not $step.Contains('$env:AZURE_FEDERATED_TOKEN_FILE = $federatedTokenFile') -or
        $step.Contains('azureSubscription: sc-mtp-azure-demo-dev')) {
        throw 'Migration and seed must each authenticate and validate inside AzureCLI@2 using only the exact dedicated migration service connection.'
    }
    foreach ($name in $approvedMigrationVariables.Keys) {
        if (-not $step.Contains("${name}: `$(${name})")) {
            throw "Migration or seed task does not map approved identity variable $name."
        }
    }
    if ($step.IndexOf('chmod 600 $federatedTokenFile', [StringComparison]::Ordinal) -ge
        $step.IndexOf('[IO.File]::WriteAllText($federatedTokenFile, $env:idToken', [StringComparison]::Ordinal)) {
        throw 'The task-local federated-token file must be permission-restricted before the assertion is written.'
    }
}

if ([regex]::Matches($text, '(?m)^\s+addSpnToEnvironment:\s+true\s*$').Count -ne 2) {
    throw 'addSpnToEnvironment must be enabled only for the independently authenticated migration and seed tasks.'
}
if ($text -match '(?im)^\s*(?:[-&]\s*)?sqlcmd(?:\.exe)?(?:\s|$)' -or $text.Contains('Configure-AzureDemoDatabasePrincipals.sql -v') -or $text.Contains('AZDEMO_MIGRATION_CONNECTION_STRING')) {
    throw 'The pipeline must not automate SQL principal bootstrap or use an ambient migration connection string.'
}
if ([regex]::Matches($text, '(?m)^\s*- pwsh: ./scripts/build/Test-AzureDemoDatabasePrincipalSql\.ps1\s*$').Count -ne 1) {
    throw 'The pipeline must run the SQLCMD variable-precedence and database-principal guard contract exactly once.'
}
if (-not $text.Contains("sql-bootstrap.json' -ExpectedSourceCommit '`$(Build.SourceVersion)'")) {
    throw 'The pipeline must require independently produced, commit-bound SQL bootstrap evidence.'
}
if ($text -match '(?im)^\s*(?:Write-(?:Host|Output)|echo)\b[^\r\n]*(?:access.?token|idtoken|authorization)' -or
    $text -match '(?i)##vso\[task\.setvariable[^\]]*(?:token|credential|secret)') {
    throw 'The pipeline contains a command that could log or export a token or credential.'
}
if ([regex]::Matches($text, '(?i)\[IO\.File\]::WriteAllText\(\$federatedTokenFile, \$env:idToken').Count -ne 2 -or
    [regex]::Matches($text, '(?m)^\s+Remove-Item Env:idToken -ErrorAction SilentlyContinue').Count -ne 2 -or
    [regex]::Matches($text, '(?m)^\s+Remove-Item -LiteralPath \$federatedTokenFile -Force').Count -ne 2) {
    throw 'The federated idToken must be written only to two task-local restricted files and deleted in both tasks.'
}

if ($text.Contains("New-AzureDemoSboms.ps1 -OutputDirectory '`$(Build.ArtifactStagingDirectory)")) {
    throw 'SBOM generation must not use the artifact staging directory outside the repository workspace.'
}

$packageStageStart = $text.IndexOf('- stage: Package', [StringComparison]::Ordinal)
$packageStageEnd = $text.IndexOf('- stage: PreDeploymentGate', [StringComparison]::Ordinal)
if ($packageStageStart -lt 0 -or $packageStageEnd -le $packageStageStart) {
    throw 'The Package stage boundaries could not be identified.'
}
$packageStage = $text.Substring($packageStageStart, $packageStageEnd - $packageStageStart)
$packageRoot = '$(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages'
if ($packageStage.Contains('$(Build.ArtifactStagingDirectory)')) {
    throw 'Package generation and publication must not use Build.ArtifactStagingDirectory outside the repository workspace.'
}
if ($packageStage.IndexOf('Test-EfMigrationArtifactParsing.ps1', [StringComparison]::Ordinal) -gt
    $packageStage.IndexOf('publish: $(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages', [StringComparison]::Ordinal)) {
    throw 'The EF migration-list parsing regression must run before artifact publication.'
}
foreach ($fragment in @(
        '$project = ''src/api/LgrTransformationMigration.Api.csproj''',
        '$startupProject = ''src/api/LgrTransformationMigration.Api.csproj''',
        '$dbContext = ''LgrTransformationMigration.Api.Infrastructure.AppDbContext''',
        'dotnet build $project --configuration Release --no-restore',
        'ConvertFrom-EfMigrationListNativeResult')) {
    if (-not $efArtifactScript.Contains($fragment)) {
        throw "The EF migration artifact generator is missing its fail-closed contract fragment: $fragment"
    }
}
if ($efArtifactScript -notmatch "(?s)'migrations', 'list'.{0,500}'--no-build'.{0,200}'--no-connect'.{0,200}'--json'") {
    throw 'EF migration enumeration must use --no-build, --no-connect and --json after its explicit build.'
}
if ([regex]::Matches($packageStage, "(?m)^\s*- publish: $([regex]::Escape($packageRoot))\s*$").Count -ne 1) {
    throw 'The immutable package must be published exactly once from the repository-contained package directory.'
}
foreach ($relativePath in @('application', 'migration')) {
    if (-not $packageStage.Contains("$packageRoot/$relativePath")) {
        throw "Package generation is missing repository-contained $relativePath output."
    }
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
