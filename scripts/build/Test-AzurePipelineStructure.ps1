[CmdletBinding()]
param([string] $Path = 'azure-pipelines.yml')

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$pipelinePath = (Resolve-Path (Join-Path $repo $Path)).Path
$text = Get-Content -LiteralPath $pipelinePath -Raw
$lines = Get-Content -LiteralPath $pipelinePath
$parameterEnvironmentScript = Join-Path $repo 'scripts\build\Test-AzureDemoParameterEnvironment.ps1'
$efArtifactScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\build\New-EfMigrationArtifacts.ps1') -Raw
$runtimeValidatorScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\build\Assert-AzureAppServiceNativeRuntimes.ps1') -Raw
$appServiceSubnetValidatorScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\build\Assert-AzureDemoAppServiceSubnet.ps1') -Raw
$privateDnsValidatorScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\build\Assert-AzureDemoPrivateDnsReconciliation.ps1') -Raw
$sqlBootstrapValidatorScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\database\Assert-AzureDemoSqlBootstrapEvidence.ps1') -Raw
$efBundleInvokerScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\database\Invoke-AzureDemoEfMigrationBundle.ps1') -Raw
$deploymentArtifactUtilitiesScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\build\AzureDemoDeploymentArtifactUtilities.ps1') -Raw
$seedPackageScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\build\New-AzureDemoSeedArtifact.ps1') -Raw
$seedInvocationScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\data\Invoke-AzureDemoSeed.ps1') -Raw
$seedResetScript = Get-Content -LiteralPath (Join-Path $repo 'scripts\data\Invoke-AzureDemoReset.ps1') -Raw
$approvedMigrationServiceConnection = 'sc-mtp-azure-demo-migration-dev-v2'
$retiredMigrationServiceConnection = 'sc-mtp-azure-demo-migration-dev'

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
    AZDEMO_MIGRATION_WIF_SERVICE_CONNECTION = $approvedMigrationServiceConnection
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
    "azureSubscription: $approvedMigrationServiceConnection",
    'deployToSlotOrASE: true',
    'slotName: staging',
    'ManualValidation@0',
    'az deployment group what-if',
    'Invoke-AzureDemoSmokeTests.ps1',
    'Assert-AzureDemoRollbackTarget.ps1',
    'Assert-AzureDemoMigrationTarget.ps1',
    'Assert-AzureDemoMigrationIdentity.ps1',
    'Test-AzureDemoEfMigrationBundleExecution.ps1',
    'Invoke-AzureDemoEfMigrationBundle.ps1',
    'Assert-AzureDemoSqlBootstrapEvidence.ps1',
    'Test-AzureDemoSqlBootstrapEvidence.ps1',
    'Test-AzureDemoDatabasePrincipalSql.ps1',
    'Test-AzureAppServiceNativeRuntimes.ps1',
    'Assert-AzureAppServiceNativeRuntimes.ps1',
    'Test-AzureDemoAppServiceSubnet.ps1',
    "Test-AzureDemoAppServiceSubnet.ps1 -CompiledTemplatePath '`$(Build.ArtifactStagingDirectory)/main.json'",
    'Assert-AzureDemoAppServiceSubnet.ps1',
    'Test-AzureDemoPrivateDnsReconciliation.ps1',
    "Test-AzureDemoPrivateDnsReconciliation.ps1 -CompiledTemplatePath '`$(Build.ArtifactStagingDirectory)/main.json'",
    'Assert-AzureDemoPrivateDnsReconciliation.ps1',
    'id-mtp-migration-dev-uks-001',
    'Authentication=Active Directory Workload Identity',
    'Test-AzureDemoSboms.ps1',
    "New-AzureDemoSboms.ps1 -OutputDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/sbom'",
    'publish: $(Build.SourcesDirectory)/artifacts/azure-demo-ci/sbom',
    'artifact: dependency-sboms',
    "New-AzureDemoPackages.ps1 -OutputDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages/application'",
    'Test-EfMigrationArtifactParsing.ps1',
    "New-EfMigrationArtifacts.ps1 -OutputDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages/migration'",
    "New-AzureDemoSeedArtifact.ps1 -PackageDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages'",
    'New-AzureDemoDeploymentArtifactManifest.ps1',
    'Assert-AzureDemoDeploymentArtifact.ps1',
    'Test-AzureDemoImmutableSeedArtifact.ps1',
    "Test-AzureDemoArtifacts.ps1 -ArtifactDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages/application'",
    "Test-AzureDemoPackageGeneration.ps1 -PackageDirectory '`$(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages'",
    'publish: $(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages',
    'az webapp deployment slot swap'
)
foreach ($fragment in $requiredFragments) {
    if (-not $text.Contains($fragment)) { throw "Azure Pipelines YAML is missing required structure: $fragment" }
}

$preDeploymentGateStart = $text.IndexOf('- stage: PreDeploymentGate', [StringComparison]::Ordinal)
$preDeploymentGateEnd = $text.IndexOf('- stage: MigrateAndDeploySlots', [StringComparison]::Ordinal)
if ($preDeploymentGateStart -lt 0 -or $preDeploymentGateEnd -le $preDeploymentGateStart) {
    throw 'The PreDeploymentGate stage boundaries could not be identified.'
}
$preDeploymentGate = $text.Substring($preDeploymentGateStart, $preDeploymentGateEnd - $preDeploymentGateStart)
$virtualNetworkListCommand = "az network vnet list --resource-group '`$(AZDEMO_RESOURCE_GROUP_NAME)' --output json --only-show-errors 2>&1"
$virtualNetworkExitCapture = '$virtualNetworksExitCode = $LASTEXITCODE'
$subnetListCommand = "az network vnet subnet list --resource-group '`$(AZDEMO_RESOURCE_GROUP_NAME)' --vnet-name 'vnet-mtp-dev-uks-001' --output json --only-show-errors 2>&1"
$subnetExitCapture = '$subnetsExitCode = $LASTEXITCODE'
$privateEndpointListCommand = "az network private-endpoint list --resource-group '`$(AZDEMO_RESOURCE_GROUP_NAME)' --output json --only-show-errors 2>&1"
$privateEndpointExitCapture = '$privateEndpointsExitCode = $LASTEXITCODE'
$appServiceSubnetValidatorInvocation = '& ./scripts/build/Assert-AzureDemoAppServiceSubnet.ps1 @subnetValidation'
foreach ($fragment in @(
        $virtualNetworkListCommand,
        $virtualNetworkExitCapture,
        $subnetListCommand,
        $subnetExitCapture,
        $privateEndpointListCommand,
        $privateEndpointExitCapture,
        'VirtualNetworksJson = [string]::Join([Environment]::NewLine, [string[]] $virtualNetworkRows)',
        'SubnetsJson = [string]::Join([Environment]::NewLine, [string[]] $subnetRows)',
        'PrivateEndpointsJson = [string]::Join([Environment]::NewLine, [string[]] $privateEndpointRows)',
        'VirtualNetworksCommandExitCode = $virtualNetworksExitCode',
        'SubnetsCommandExitCode = $subnetsExitCode',
        'PrivateEndpointsCommandExitCode = $privateEndpointsExitCode',
        $appServiceSubnetValidatorInvocation)) {
    if (-not $preDeploymentGate.Contains($fragment)) {
        throw "The PreDeploymentGate existing App Service subnet contract is missing: $fragment"
    }
}
foreach ($orderedPair in @(
        @($virtualNetworkListCommand, $virtualNetworkExitCapture),
        @($virtualNetworkExitCapture, $subnetListCommand),
        @($subnetListCommand, $subnetExitCapture),
        @($subnetExitCapture, $privateEndpointListCommand),
        @($privateEndpointListCommand, $privateEndpointExitCapture),
        @($privateEndpointExitCapture, $appServiceSubnetValidatorInvocation),
        @($appServiceSubnetValidatorInvocation, 'az deployment group what-if'))) {
    if ($preDeploymentGate.IndexOf($orderedPair[0], [StringComparison]::Ordinal) -ge
        $preDeploymentGate.IndexOf($orderedPair[1], [StringComparison]::Ordinal)) {
        throw "Existing App Service subnet inventory, native exit capture and validation order is invalid: $($orderedPair[0])."
    }
}
foreach ($fragment in @(
        "'vnet-mtp-dev-uks-001'",
        "'snet-appservice'",
        "'snet-appsvc-integration'",
        "'snet-private-endpoints'",
        "'10.50.1.0/24'",
        "'10.50.2.0/24'",
        "'Microsoft.Web/serverFarms'",
        "'Microsoft.Network/privateEndpoints'",
        '$VirtualNetworksCommandExitCode -ne 0',
        '$SubnetsCommandExitCode -ne 0',
        '$PrivateEndpointsCommandExitCode -ne 0',
        '$staleSubnets.Count -ne 0',
        '$delegationNames.Count -ne 1')) {
    if (-not $appServiceSubnetValidatorScript.Contains($fragment)) {
        throw "The App Service integration-subnet validator is missing a fail-closed contract: $fragment"
    }
}
$forbiddenMetadataCheck = 'Get-ProviderValue $integrationSubnet ''privateEndpoints'''
if ($appServiceSubnetValidatorScript.Contains($forbiddenMetadataCheck)) {
    throw 'The App Service subnet validator must not treat provider-managed subnet privateEndpoints metadata as actual private-endpoint resources.'
}
$deploymentStageStart = $text.IndexOf('- stage: MigrateAndDeploySlots', [StringComparison]::Ordinal)
if ($deploymentStageStart -lt 0 -or
    $text.IndexOf('dependsOn: PreDeploymentGate', $deploymentStageStart, [StringComparison]::Ordinal) -lt $deploymentStageStart) {
    throw 'Application deployment must remain dependent on the protected PreDeploymentGate.'
}
$subnetTestWithoutCompiled = [regex]::Matches($text, '(?m)^\s*- pwsh: ./scripts/build/Test-AzureDemoAppServiceSubnet\.ps1\s*$').Count
$subnetTestWithCompiled = [regex]::Matches($text, "Test-AzureDemoAppServiceSubnet\.ps1 -CompiledTemplatePath '`\$\(Build\.ArtifactStagingDirectory\)/main\.json'").Count
if ($subnetTestWithoutCompiled -ne 1 -or $subnetTestWithCompiled -ne 1) {
    throw 'The App Service integration-subnet regression must run once against source and once against compiled Bicep.'
}
$runtimeCommand = '$runtimeRows = @(az webapp list-runtimes --os linux --output tsv 2>&1)'
$runtimeExitCapture = '$runtimeCommandExitCode = $LASTEXITCODE'
$runtimeValidatorInvocation = '& ./scripts/build/Assert-AzureAppServiceNativeRuntimes.ps1 @runtimeValidation'
foreach ($fragment in @(
        $runtimeCommand,
        $runtimeExitCapture,
        'RuntimeRows = [string[]] $runtimeRows',
        'CommandExitCode = $runtimeCommandExitCode',
        $runtimeValidatorInvocation)) {
    if (-not $preDeploymentGate.Contains($fragment)) {
        throw "The PreDeploymentGate native-runtime contract is missing: $fragment"
    }
}
if ($preDeploymentGate.IndexOf($runtimeCommand, [StringComparison]::Ordinal) -ge
    $preDeploymentGate.IndexOf($runtimeExitCapture, [StringComparison]::Ordinal) -or
    $preDeploymentGate.IndexOf($runtimeExitCapture, [StringComparison]::Ordinal) -ge
    $preDeploymentGate.IndexOf($runtimeValidatorInvocation, [StringComparison]::Ordinal)) {
    throw 'Native-runtime output and exit status must be captured before fail-closed validation.'
}
$privateDnsListCommand = "az network private-dns link vnet list --resource-group '`$(AZDEMO_RESOURCE_GROUP_NAME)' --zone-name `$sqlPrivateDnsZoneName --output json --only-show-errors"
$privateDnsExitCapture = '$sqlPrivateDnsLinksExitCode = $LASTEXITCODE'
$privateDnsValidatorInvocation = './scripts/build/Assert-AzureDemoPrivateDnsReconciliation.ps1 -LinksJson $sqlPrivateDnsLinksJson -ExpectedLinkName $sqlPrivateDnsLinkName -ExpectedVirtualNetworkId $approvedVirtualNetworkId'
foreach ($fragment in @(
        "@{ Type = 'Microsoft.Network/privateDnsZones'; Name = 'privatelink.database.windows.net' }",
        "`$sqlPrivateDnsLinkName = 'link-mtp-dev-vnet'",
        "`$approvedVirtualNetworkId = '/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Network/virtualNetworks/vnet-mtp-dev-uks-001'",
        $privateDnsListCommand,
        $privateDnsExitCapture,
        'if ($sqlPrivateDnsLinksExitCode -ne 0)',
        '$sqlPrivateDnsLinksJson = [string]::Join([Environment]::NewLine, [string[]] $sqlPrivateDnsLinks)',
        $privateDnsValidatorInvocation)) {
    if (-not $preDeploymentGate.Contains($fragment)) {
        throw "The PreDeploymentGate private DNS reconciliation contract is missing: $fragment"
    }
}
if ($preDeploymentGate.IndexOf($privateDnsListCommand, [StringComparison]::Ordinal) -ge
    $preDeploymentGate.IndexOf($privateDnsExitCapture, [StringComparison]::Ordinal) -or
    $preDeploymentGate.IndexOf($privateDnsExitCapture, [StringComparison]::Ordinal) -ge
    $preDeploymentGate.IndexOf($privateDnsValidatorInvocation, [StringComparison]::Ordinal) -or
    $preDeploymentGate.IndexOf($privateDnsValidatorInvocation, [StringComparison]::Ordinal) -ge
    $preDeploymentGate.IndexOf('az deployment group what-if', [StringComparison]::Ordinal)) {
    throw 'SQL private DNS inventory, exit status and fail-closed validation must precede ARM what-if.'
}
foreach ($fragment in @(
        '$exactLinks.Count -ne 1',
        '$exactLinkVirtualNetwork -ne $expectedVirtualNetwork',
        '$exactLinks[0].registrationEnabled -ne $false',
        "$exactLinks[0].provisioningState -cne 'Succeeded'",
        '$targetLinks.Count -ne 1')) {
    if (-not $privateDnsValidatorScript.Contains($fragment)) {
        throw "The SQL private DNS validator is missing a fail-closed contract: $fragment"
    }
}
$colonRuntimeIdentifierPattern = '(?:NODE|DOTNETCORE):(?:24-lts|10\.0)'
if ($preDeploymentGate -match $colonRuntimeIdentifierPattern -or
    $preDeploymentGate -match '(?i)\$runtimes?\s+-notmatch') {
    throw 'PreDeploymentGate must not use colon-form runtime identifiers or array -notmatch validation.'
}
foreach ($fragment in @(
        "'NODE|24-lts'",
        "'DOTNETCORE|10.0'",
        '$CommandExitCode -ne 0',
        '$runtimeRow.IndexOf("`t", [StringComparison]::Ordinal)',
        '$runtimeRow.Substring(0, $tabIndex).Trim()',
        '$runtimeIdentifiers -notcontains $requiredRuntime')) {
    if (-not $runtimeValidatorScript.Contains($fragment)) {
        throw "The native-runtime validator is missing its fail-closed normalization contract: $fragment"
    }
}
if ($runtimeValidatorScript -match $colonRuntimeIdentifierPattern -or
    $runtimeValidatorScript -match '(?i)\$runtimes?\s+-notmatch') {
    throw 'The native-runtime validator must use pipe-form identifiers and exact membership, not array -notmatch.'
}
if ([regex]::Matches($text, '(?m)^\s*- pwsh: ./scripts/build/Test-AzureAppServiceNativeRuntimes\.ps1\s*$').Count -ne 1) {
    throw 'The executable native-runtime regression must run exactly once in pipeline validation.'
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

function Get-YamlJobBlocks([string[]] $PipelineLines) {
    $jobStarts = @(for ($index = 0; $index -lt $PipelineLines.Count; $index++) {
            if ($PipelineLines[$index] -match '^  - (?:job|deployment):\s+([A-Za-z][A-Za-z0-9_]*)\s*$') {
                [pscustomobject]@{ Index = $index; Name = $Matches[1] }
            }
        })
    $blocks = @()
    for ($jobIndex = 0; $jobIndex -lt $jobStarts.Count; $jobIndex++) {
        $start = $jobStarts[$jobIndex].Index
        $end = $PipelineLines.Count
        if ($jobIndex + 1 -lt $jobStarts.Count) { $end = $jobStarts[$jobIndex + 1].Index }
        for ($index = $start + 1; $index -lt $end; $index++) {
            if ($PipelineLines[$index] -match '^- stage:') {
                $end = $index
                break
            }
        }
        $blockLines = @($PipelineLines[$start..($end - 1)])
        $blocks += [pscustomobject]@{
            Name = $jobStarts[$jobIndex].Name
            Lines = $blockLines
            Text = $blockLines -join "`n"
        }
    }
    return $blocks
}

function Assert-SqlBootstrapEvidenceDelivery([string[]] $PipelineLines) {
    $jobBlocks = @(Get-YamlJobBlocks $PipelineLines)
    $consumerJobs = @($jobBlocks | Where-Object {
            $_.Text.Contains('sql-bootstrap.json') -or
            $_.Text.Contains('$(AZDEMO_SMOKE_PREREQUISITE_EVIDENCE)')
        })
    $consumerNames = @($consumerJobs | ForEach-Object { $_.Name })
    if (($consumerNames -join '|') -ne 'DatabaseAndSlots|Swap') {
        throw "SQL bootstrap evidence consumers are invalid: $($consumerNames -join ', ')."
    }

    foreach ($job in $consumerJobs) {
        $downloadStep = Get-YamlStepBlock $job.Lines 'DownloadSecureFile@1'
        $prepareStep = Get-YamlStepBlock $job.Lines 'Copy-Item -LiteralPath'
        $cleanupStep = Get-YamlStepBlock $job.Lines 'Remove-Item -LiteralPath \$evidenceDirectory -Recurse'
        if ([regex]::Matches($job.Text, '(?m)^\s*- task: DownloadSecureFile@1\s*$').Count -ne 1 -or
            [regex]::Matches($downloadStep, '(?m)^\s+name:\s+downloadSqlBootstrapEvidence\s*$').Count -ne 1 -or
            [regex]::Matches($downloadStep, '(?m)^\s+secureFile:\s+sql-bootstrap\.json\s*$').Count -ne 1) {
            throw "Evidence-consuming job $($job.Name) must independently download exactly Secure File sql-bootstrap.json."
        }
        foreach ($fragment in @(
                "`$evidenceDirectory = Join-Path '`$(Agent.TempDirectory)' 'azdemo-sql-bootstrap-evidence'",
                "`$evidencePath = Join-Path `$evidenceDirectory 'sql-bootstrap.json'",
                "Copy-Item -LiteralPath '`$(downloadSqlBootstrapEvidence.secureFilePath)' -Destination `$evidencePath -Force",
                'if ($IsLinux)',
                'chmod 600 -- $evidencePath',
                "if (`$LASTEXITCODE) { throw 'Could not restrict SQL bootstrap evidence permissions.' }",
                '##vso[task.setvariable variable=AZDEMO_SMOKE_PREREQUISITE_EVIDENCE]$evidenceDirectory')) {
            if (-not $prepareStep.Contains($fragment)) {
                throw "Evidence-consuming job $($job.Name) does not securely prepare job-local evidence: $fragment"
            }
        }
        foreach ($fragment in @(
                "`$evidenceDirectory = Join-Path '`$(Agent.TempDirectory)' 'azdemo-sql-bootstrap-evidence'",
                'Remove-Item -LiteralPath $evidenceDirectory -Recurse -Force -ErrorAction SilentlyContinue',
                'condition: always()')) {
            if (-not $cleanupStep.Contains($fragment)) {
                throw "Evidence-consuming job $($job.Name) does not always remove only its job-local evidence directory: $fragment"
            }
        }

        $downloadIndex = $job.Text.IndexOf('DownloadSecureFile@1', [StringComparison]::Ordinal)
        $variableIndex = $job.Text.IndexOf('##vso[task.setvariable variable=AZDEMO_SMOKE_PREREQUISITE_EVIDENCE]', [StringComparison]::Ordinal)
        $cleanupIndex = $job.Text.IndexOf('Remove-Item -LiteralPath $evidenceDirectory -Recurse', [StringComparison]::Ordinal)
        $consumerIndexes = @(for ($index = 0; $index -lt $job.Lines.Count; $index++) {
                if ($job.Lines[$index] -match 'Assert-AzureDemoSqlBootstrapEvidence\.ps1|Invoke-AzureDemoSmokeTests\.ps1') { $index }
            })
        if ($consumerIndexes.Count -eq 0) {
            throw "Evidence-consuming job $($job.Name) has no protected-evidence consumer."
        }
        $firstConsumerIndex = $job.Text.IndexOf($job.Lines[($consumerIndexes | Measure-Object -Minimum).Minimum].Trim(), [StringComparison]::Ordinal)
        $lastConsumerIndex = $job.Text.LastIndexOf($job.Lines[($consumerIndexes | Measure-Object -Maximum).Maximum].Trim(), [StringComparison]::Ordinal)
        if ($downloadIndex -lt 0 -or $variableIndex -le $downloadIndex -or $firstConsumerIndex -le $variableIndex -or $cleanupIndex -le $lastConsumerIndex) {
            throw "Evidence-consuming job $($job.Name) must download, prepare and bind evidence before every use, then clean it up."
        }

        if ($job.Name -eq 'DatabaseAndSlots' -and
            ($job.Text -notmatch '(?m)^\s+- checkout: self\s*\r?\n\s+fetchDepth: 0\s*\r?\n\s+fetchTags: false\s*$')) {
            throw 'The durable SQL evidence validation job must check out complete deterministic Git history without tags.'
        }
    }

    $pipelineText = $PipelineLines -join "`n"
    if ($pipelineText -match '(?im)^\s*- publish:\s*[^\r\n]*(?:sql-bootstrap|AZDEMO_SMOKE_PREREQUISITE_EVIDENCE|azdemo-sql-bootstrap-evidence|downloadSqlBootstrapEvidence|Agent\.TempDirectory)' -or
        $pipelineText -match '(?im)^\s+artifact:\s*[^\r\n]*sql-bootstrap' -or
        $pipelineText -match '(?im)^\s*Copy-Item[^\r\n]*(?:sql-bootstrap|downloadSqlBootstrapEvidence|AZDEMO_SMOKE_PREREQUISITE_EVIDENCE|azdemo-sql-bootstrap-evidence)[^\r\n]*(?:Build\.SourcesDirectory|System\.DefaultWorkingDirectory|Build\.ArtifactStagingDirectory|Pipeline\.Workspace)' -or
        $pipelineText -match '(?im)^\s*Copy-Item[^\r\n]*(?:Build\.SourcesDirectory|System\.DefaultWorkingDirectory|Build\.ArtifactStagingDirectory|Pipeline\.Workspace)[^\r\n]*(?:sql-bootstrap|downloadSqlBootstrapEvidence|AZDEMO_SMOKE_PREREQUISITE_EVIDENCE|azdemo-sql-bootstrap-evidence)') {
        throw 'SQL bootstrap evidence must not be published or copied into a repository or artifact workspace.'
    }
    if ($pipelineText -match '(?ms)^\s*-\s+name:\s+AZDEMO_SMOKE_PREREQUISITE_EVIDENCE\s*\r?\n\s+value:') {
        throw 'The SQL bootstrap evidence directory must be job-scoped and must not be stored as a pipeline variable.'
    }
    if ($pipelineText -match '(?im)^\s*(?:Write-Host|Write-Output|echo)\b[^\r\n]*(?:sql-bootstrap\.json|downloadSqlBootstrapEvidence\.secureFilePath)') {
        throw 'SQL bootstrap evidence content or downloaded Secure File path must not be written to pipeline logs.'
    }
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

Assert-SqlBootstrapEvidenceDelivery $lines

$migrationStep = Get-YamlStepBlock $lines 'Invoke-AzureDemoEfMigrationBundle\.ps1 -ImmutableArtifactRoot'
$seedStep = Get-YamlStepBlock $lines 'Invoke-AzureDemoSeed\.ps1 -Environment AzureDemo'
foreach ($step in @($migrationStep, $seedStep)) {
    if ($step -notmatch '^\s*- task: AzureCLI@2' -or
        $step -notmatch "(?m)^\s+azureSubscription:\s+$([regex]::Escape($approvedMigrationServiceConnection))\s*`$" -or
        $step -match "(?m)^\s+azureSubscription:\s+$([regex]::Escape($retiredMigrationServiceConnection))\s*`$" -or
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

foreach ($fragment in @(
        "-ImmutableArtifactRoot '`$(Pipeline.Workspace)/azure-demo-immutable'",
        "-DeploymentManifestPath '`$(Pipeline.Workspace)/azure-demo-immutable/deployment-artifact-manifest.json'",
        "-ExpectedSourceCommit '`$(Build.SourceVersion)'")) {
    if (-not $migrationStep.Contains($fragment)) {
        throw "Protected migration task does not use the immutable native-execution contract: $fragment"
    }
}
if ($migrationStep -match '(?m)^\s*continueOnError:\s*true\s*$' -or
    $migrationStep -match '(?m)^\s*condition:\s*(?:always|succeededOrFailed)\(\)\s*$') {
    throw 'Migration failure must prevent seed and application deployment.'
}
$bundleInvocationIndex = $migrationStep.IndexOf('Invoke-AzureDemoEfMigrationBundle.ps1', [StringComparison]::Ordinal)
foreach ($prerequisite in @(
        'Assert-AzureDemoMigrationIdentity.ps1',
        '$env:LGR_AZURE_DEMO_SQL_CONNECTION_STRING =',
        'Assert-AzureDemoMigrationTarget.ps1')) {
    $prerequisiteIndex = $migrationStep.IndexOf($prerequisite, [StringComparison]::Ordinal)
    if ($prerequisiteIndex -lt 0 -or $prerequisiteIndex -ge $bundleInvocationIndex) {
        throw "Protected migration invocation does not follow required guard: $prerequisite"
    }
}
$migrationCleanupIndex = $migrationStep.IndexOf('finally {', [StringComparison]::Ordinal)
if ($bundleInvocationIndex -lt 0 -or $migrationCleanupIndex -le $bundleInvocationIndex -or
    -not $migrationStep.Contains('Remove-Item -LiteralPath $federatedTokenFile -Force')) {
    throw 'Protected migration execution must retain finally-based credential and token-file cleanup.'
}
$migrationTaskIndex = $text.IndexOf('displayName: Execute reviewed EF bundle with dedicated migration workload identity', [StringComparison]::Ordinal)
$seedTaskIndex = $text.IndexOf('displayName: Reconcile approved synthetic seed with dedicated migration workload identity', [StringComparison]::Ordinal)
$apiDeploymentIndex = $text.IndexOf('displayName: Deploy API ZIP to staging only', [StringComparison]::Ordinal)
if ($migrationTaskIndex -lt 0 -or $seedTaskIndex -le $migrationTaskIndex -or $apiDeploymentIndex -le $seedTaskIndex) {
    throw 'Migration, seed and application deployment order must fail closed.'
}
foreach ($fragment in @(
        '$startInfo.UseShellExecute = $false',
        '$startInfo.ArgumentList.Add($argument)',
        '$process.WaitForExit()',
        '$process.ExitCode',
        "@('u+x', '--', `$bundlePath)",
        'Assert-AzureDemoDeploymentArtifact',
        'Resolve-AzureDemoArtifactPath')) {
    if (-not $efBundleInvokerScript.Contains($fragment)) {
        throw "The EF bundle native invoker is missing its fail-closed contract: $fragment"
    }
}
if (-not $efBundleInvokerScript.Contains('$artifactRoot = [IO.Path]::GetFullPath($ImmutableArtifactRoot)') -or
    $efBundleInvokerScript.Contains('(Resolve-Path -LiteralPath $ImmutableArtifactRoot')) {
    throw 'The EF bundle native invoker must preserve the lexical immutable root until symbolic-link validation.'
}
$artifactResolverStart = $deploymentArtifactUtilitiesScript.IndexOf('function Resolve-AzureDemoArtifactPath', [StringComparison]::Ordinal)
$artifactResolverEnd = $deploymentArtifactUtilitiesScript.IndexOf('function ConvertTo-AzureDemoArtifactRelativePath', [StringComparison]::Ordinal)
if ($artifactResolverStart -lt 0 -or $artifactResolverEnd -le $artifactResolverStart) {
    throw 'The immutable artifact path resolver could not be isolated.'
}
$artifactResolver = $deploymentArtifactUtilitiesScript.Substring($artifactResolverStart, $artifactResolverEnd - $artifactResolverStart)
$reparseValidationIndex = $artifactResolver.IndexOf('Assert-AzureDemoNoReparsePoints', [StringComparison]::Ordinal)
$rootExistenceIndex = $artifactResolver.IndexOf("Test-Path -LiteralPath `$root -PathType Container", [StringComparison]::Ordinal)
$candidateExistenceIndex = $artifactResolver.IndexOf("Test-Path -LiteralPath `$candidate -PathType `$PathType", [StringComparison]::Ordinal)
if (-not $deploymentArtifactUtilitiesScript.Contains('[IO.File]::GetAttributes($current)') -or
    $reparseValidationIndex -lt 0 -or
    $rootExistenceIndex -le $reparseValidationIndex -or
    $candidateExistenceIndex -le $reparseValidationIndex) {
    throw 'Immutable artifact paths must reject root, ancestor, payload and dangling links before existence checks or resolution.'
}
if ($efBundleInvokerScript -match '(?i)xdg-open|Invoke-Item|Start-Process|UseShellExecute\s*=\s*\$true') {
    throw 'The EF bundle native invoker must not use shell or file-association execution.'
}
if ([regex]::Matches($text, '(?m)^\s*- pwsh: ./scripts/build/Test-AzureDemoEfMigrationBundleExecution\.ps1\s*$').Count -ne 1) {
    throw 'The real Linux EF bundle execution regression must run exactly once in validation.'
}
$validateStage = $text.Substring(
    $text.IndexOf('- stage: Validate', [StringComparison]::Ordinal),
    $text.IndexOf('- stage: Package', [StringComparison]::Ordinal) - $text.IndexOf('- stage: Validate', [StringComparison]::Ordinal))
if (-not $validateStage.Contains('pool: { vmImage: ubuntu-latest }') -or
    -not $validateStage.Contains('Test-AzureDemoEfMigrationBundleExecution.ps1')) {
    throw 'The native EF bundle execution regression must run in the unprotected Ubuntu validation stage.'
}

foreach ($fragment in @(
        "-ImmutableArtifactRoot '`$(Pipeline.Workspace)/azure-demo-immutable'",
        "-ToolPath '`$(Pipeline.Workspace)/azure-demo-immutable/seed/AzureDemo.DataTool.dll'",
        "-ManifestPath '`$(Pipeline.Workspace)/azure-demo-immutable/demo-data/azure-demo-seed-manifest.json'",
        "-DeploymentManifestPath '`$(Pipeline.Workspace)/azure-demo-immutable/deployment-artifact-manifest.json'",
        "-ExpectedSourceCommit '`$(Build.SourceVersion)'")) {
    if (-not $seedStep.Contains($fragment)) {
        throw "Protected seed task does not use the immutable seed contract: $fragment"
    }
}
if ($seedStep -match '(?i)\bdotnet\s+(?:run|restore|build)\b' -or
    $seedStep -match '(?i)tools[\\/]AzureDemo\.DataTool[\\/]AzureDemo\.DataTool\.csproj') {
    throw 'Protected seed deployment must not run, restore or build the source project.'
}
foreach ($script in @($seedInvocationScript, $seedResetScript)) {
    if ($script -match '(?i)\bdotnet\s+(?:run|restore|build)\b' -or
        $script -match '(?i)AzureDemo\.DataTool\.csproj|Build\.SourcesDirectory') {
        throw 'Seed and reset scripts must not contain a source, restore or build fallback.'
    }
}

if ($text -match "(?m)^\s+azureSubscription:\s+$([regex]::Escape($retiredMigrationServiceConnection))\s*`$") {
    throw 'The pipeline retains an executable reference to the retired dedicated migration service connection.'
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
if ([regex]::Matches($text, '(?m)^\s*- pwsh: \./scripts/database/Assert-AzureDemoSqlBootstrapEvidence\.ps1').Count -ne 1) {
    throw 'The pipeline must run durable SQL bootstrap evidence validation exactly once before migration.'
}
$sqlBootstrapInvocation = Get-YamlStepBlock $lines 'Assert-AzureDemoSqlBootstrapEvidence\.ps1 -EvidencePath'
foreach ($fragment in @(
        "-ExpectedReleaseCommit '`$(Build.SourceVersion)'",
        "-RepositoryRoot '`$(Build.SourcesDirectory)'",
        "-GrantsScriptPath 'scripts/database/Configure-AzureDemoDatabasePrincipals.sql'",
        "-ExpectedExecutorPrincipalObjectId '`$(AZDEMO_SQL_ADMIN_OBJECT_ID)'",
        '-MaximumEvidenceAgeDays 90')) {
    if (-not $sqlBootstrapInvocation.Contains($fragment)) {
        throw "The durable SQL bootstrap invocation is missing its fail-closed release/evidence contract: $fragment"
    }
}
foreach ($fragment in @(
        "'merge-base', '--is-ancestor'",
        "'rev-parse', '--is-shallow-repository'",
        "'cat-file', '-e'",
        'Get-FileHash -LiteralPath $resolvedScript -Algorithm SHA256',
        '[ValidateRange(1, 90)] [int] $MaximumEvidenceAgeDays = 90',
        '$recordedAt -gt $now.Add($clockSkewTolerance)',
        '$recordedAt -lt $now.AddDays(-$MaximumEvidenceAgeDays).Subtract($clockSkewTolerance)')) {
    if (-not $sqlBootstrapValidatorScript.Contains($fragment)) {
        throw "The durable SQL bootstrap validator is missing its fail-closed ancestry, grants-hash or age contract: $fragment"
    }
}
if ($sqlBootstrapValidatorScript -match '(?im)\bgit\s+(?:fetch|pull)\b' -or
    $sqlBootstrapValidatorScript -match "(?im)'(?:fetch|pull)'") {
    throw 'Durable SQL bootstrap evidence validation must not fetch or pull repository history.'
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
foreach ($fragment in @(
        '[Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux)',
        'dotnet restore $project --locked-mode',
        'dotnet publish $project --configuration Release --no-self-contained --no-restore',
        '$seedDirectory = Join-Path $packageRoot ''seed''',
        '$demoDataDirectory = Join-Path $packageRoot ''demo-data''',
        '$samplesDirectory = Join-Path $packageRoot ''samples''')) {
    if (-not $seedPackageScript.Contains($fragment)) {
        throw "Seed artifact generator is missing its locked Linux publish contract: $fragment"
    }
}
$seedPackageIndex = $packageStage.IndexOf('New-AzureDemoSeedArtifact.ps1', [StringComparison]::Ordinal)
$deploymentManifestIndex = $packageStage.IndexOf('New-AzureDemoDeploymentArtifactManifest.ps1', [StringComparison]::Ordinal)
$seedRegressionIndex = $packageStage.IndexOf('Test-AzureDemoImmutableSeedArtifact.ps1', [StringComparison]::Ordinal)
$packagePublishIndex = $packageStage.IndexOf('publish: $(Build.SourcesDirectory)/artifacts/azure-demo-ci/packages', [StringComparison]::Ordinal)
if ($seedPackageIndex -lt 0 -or $deploymentManifestIndex -le $seedPackageIndex -or
    $seedRegressionIndex -le $deploymentManifestIndex -or $packagePublishIndex -le $seedRegressionIndex) {
    throw 'Seed publish, complete deployment manifest, fail-closed regression and immutable publication order is invalid.'
}
if ([regex]::Matches($packageStage, '(?m)^\s*- pwsh: ./scripts/build/Test-AzureDemoImmutableSeedArtifact\.ps1').Count -ne 1) {
    throw 'The immutable seed artifact regression must run exactly once before package publication.'
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
