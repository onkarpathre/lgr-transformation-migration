[CmdletBinding()]
param(
    [string] $CandidateCommit = '3a017ccc44e3603c23d54d4c27469cacf0cda1d2',
    [string] $FinalRepairCommit = '1ae167d73bd0ae7adcac697c521177ff033563c1',
    [string] $PreviousEvidenceCommit = '0c5122c7deee7629a08625cd30b15ffd84067e6c',
    [string] $MonitoringRollbackRepairCommit = 'a5d683c7336d5938e274cb2c9460a2b6e4da6542',
    [string] $OriginalCandidate = '38add95edf8b63a552a29a6d6625336de92ea896',
    [string] $ApprovedBaseline = '4dc284b06a9d0cb2e0114c7a16d99196b545b63e'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$failures = [Collections.Generic.List[string]]::new()
$passes = [Collections.Generic.List[string]]::new()

function Assert-Contract([bool] $Condition, [string] $Id, [string] $Message) {
    if ($Condition) { $passes.Add($Id) }
    else { $failures.Add("$Id - $Message") }
}

function Read-Repo([string] $Path) {
    Get-Content -LiteralPath (Join-Path $repo $Path) -Raw
}

function Test-Ancestor([string] $Ancestor, [string] $Descendant) {
    git -C $repo merge-base --is-ancestor $Ancestor $Descendant
    return $LASTEXITCODE -eq 0
}

# Candidate identity, worktree hygiene and exact ancestry.
$head = (git -C $repo rev-parse HEAD).Trim()
$branch = (git -C $repo branch --show-current).Trim()
$remote = (git -C $repo rev-parse origin/release/azure-demo-v1).Trim()
$trackedStatus = @(git -C $repo status --short --untracked-files=no)
$staged = @(git -C $repo diff --cached --name-only)
$untracked = @(git -C $repo ls-files --others --exclude-standard | Sort-Object)
$authorisedUntracked = @(
    'docs/implementation/AZURE_DEMO_Test_Evidence_Pack.md',
    'tests/assurance/AzureDemoSqlRuntimeValidation.sql',
    'tests/assurance/Test-AzureDemoCandidate.ps1'
) | Sort-Object

Assert-Contract ($branch -eq 'release/azure-demo-v1') 'GIT-01' 'The active branch is not release/azure-demo-v1.'
Assert-Contract ($head -eq $CandidateCommit -and $remote -eq $CandidateCommit) 'GIT-02' 'HEAD or the local remote-tracking ref does not equal the exact candidate.'
Assert-Contract ($trackedStatus.Count -eq 0 -and $staged.Count -eq 0) 'GIT-03' 'Tracked or staged files changed during assurance.'
Assert-Contract (($untracked -join '|') -eq ($authorisedUntracked -join '|')) 'GIT-04' 'Untracked files are not exactly the three authorised Tester-owned files.'
Assert-Contract (
    (Test-Ancestor $ApprovedBaseline $OriginalCandidate) -and
    (Test-Ancestor $OriginalCandidate $MonitoringRollbackRepairCommit) -and
    (Test-Ancestor $MonitoringRollbackRepairCommit $PreviousEvidenceCommit) -and
    (Test-Ancestor $PreviousEvidenceCommit $FinalRepairCommit) -and
    (Test-Ancestor $FinalRepairCommit $CandidateCommit)
) 'GIT-05' 'The required baseline, original, repair and evidence-successor ancestry is invalid.'
Assert-Contract (
    ((git -C $repo rev-parse "$MonitoringRollbackRepairCommit^").Trim()) -eq $OriginalCandidate -and
    ((git -C $repo rev-parse "$PreviousEvidenceCommit^").Trim()) -eq $MonitoringRollbackRepairCommit -and
    ((git -C $repo rev-parse "$FinalRepairCommit^").Trim()) -eq $PreviousEvidenceCommit -and
    ((git -C $repo rev-parse "$CandidateCommit^").Trim()) -eq $FinalRepairCommit
) 'GIT-06' 'A required repair or evidence successor is not a direct child of its required predecessor.'

$originalDelta = @(git -C $repo diff --name-only "$ApprovedBaseline..$OriginalCandidate")
$monitoringRollbackRepairDelta = @(git -C $repo diff --name-only "$OriginalCandidate..$MonitoringRollbackRepairCommit")
$previousEvidenceDelta = @(git -C $repo diff --name-only "$MonitoringRollbackRepairCommit..$PreviousEvidenceCommit")
$finalRepairDelta = @(git -C $repo diff --name-only "$PreviousEvidenceCommit..$FinalRepairCommit")
$successorDelta = @(git -C $repo diff --name-only "$FinalRepairCommit..$CandidateCommit")
$candidateDelta = @(git -C $repo diff --name-only "$ApprovedBaseline..$CandidateCommit")
Assert-Contract (
    $originalDelta.Count -eq 60 -and
    $monitoringRollbackRepairDelta.Count -eq 9 -and
    $previousEvidenceDelta.Count -eq 1 -and
    $finalRepairDelta.Count -eq 5 -and
    $candidateDelta.Count -eq 63
) 'GIT-07' 'The original, repair, evidence-successor or cumulative candidate delta count changed.'
Assert-Contract ($successorDelta.Count -eq 1 -and $successorDelta[0] -eq 'docs/implementation/AZURE_DEMO_Implementation_Work_Package.md') 'GIT-08' 'The successor contains a change other than the evidence-document update.'

$forbiddenTracked = @(git -C $repo ls-tree -r --name-only $CandidateCommit | Where-Object {
    $_ -match '(?i)(^|/)(node_modules|\.next|bin|obj|TestResults|publish|staging|scan|artifacts)(/|$)|\.(zip|dll|pdb|exe|nupkg|snupkg|pfx|p12|publishsettings)$'
})
Assert-Contract ($forbiddenTracked.Count -eq 0) 'GIT-09' 'Generated, binary or credential output is committed.'

git -C $repo diff --check "$ApprovedBaseline..$CandidateCommit"
$candidateDiffCheck = $LASTEXITCODE
git -C $repo diff --check
$worktreeDiffCheck = $LASTEXITCODE
Assert-Contract ($candidateDiffCheck -eq 0 -and $worktreeDiffCheck -eq 0) 'GIT-10' 'Candidate or tracked-worktree whitespace validation failed.'

# Evidence traceability and repaired-file inventory.
$implementation = Read-Repo 'docs/implementation/AZURE_DEMO_Implementation_Work_Package.md'
Assert-Contract (
    $implementation.Contains($OriginalCandidate) -and
    $implementation.Contains($MonitoringRollbackRepairCommit) -and
    $implementation.Contains($PreviousEvidenceCommit) -and
    $implementation.Contains($FinalRepairCommit)
) 'EVID-01' 'One or more required implementation, repair or prior evidence commits is not recorded.'
Assert-Contract ($implementation -notmatch 'commit:\s*null|Implementation commit:\*\*\s*`null`|repair candidate[^\r\n]*(?:uncommitted|unpushed)') 'EVID-02' 'A null commit or uncommitted/unpushed repair claim remains.'
Assert-Contract ($implementation -match '343/343 tests passed: 198 unit and 145 integration' -and $implementation -match '20/20') 'EVID-03' 'Developer verification totals do not match the final repaired implementation.'
$expectedMonitoringRollbackRepairFiles = @(
    'azure-pipelines.yml',
    'infra/bicep/main.bicep',
    'infra/bicep/modules/alerts.bicep',
    'infra/bicep/modules/appservice.bicep',
    'scripts/build/Assert-AzureDemoRollbackTarget.ps1',
    'scripts/build/Test-AzureDemoMonitoringAlerts.ps1',
    'scripts/build/Test-AzureDemoRollbackSafeguards.ps1',
    'scripts/build/Test-AzurePipelineStructure.ps1',
    'tests/api.unit/AzureDemoDeploymentBoundaryTests.cs'
)
Assert-Contract ((($monitoringRollbackRepairDelta | Sort-Object) -join '|') -eq (($expectedMonitoringRollbackRepairFiles | Sort-Object) -join '|')) 'EVID-04' 'The nine-file monitoring and rollback repair inventory does not match Git.'
$expectedFinalRepairFiles = @(
    'infra/bicep/main.bicep',
    'infra/bicep/modules/alerts.bicep',
    'infra/bicep/modules/data.bicep',
    'scripts/build/Test-AzureDemoMonitoringAlerts.ps1',
    'tests/api.unit/AzureDemoDeploymentBoundaryTests.cs'
)
Assert-Contract ((($finalRepairDelta | Sort-Object) -join '|') -eq (($expectedFinalRepairFiles | Sort-Object) -join '|')) 'EVID-05' 'The five-file final Defender monitoring repair inventory does not match Git.'
Assert-Contract ($implementation -match 'commit:\s*"1ae167d73bd0ae7adcac697c521177ff033563c1"' -and $implementation -match 'state:\s*"READY_FOR_RETEST"') 'EVID-06' 'The Developer hand-off is not bound to the immutable final Defender repair commit.'
$staleEvidenceClaimPatterns = @(
    '(?i)this unstaged document change',
    '(?i)this implementation-document update[^\r\n]*remains unstaged',
    '(?i)No stage, commit, push[^\r\n]*was performed for this document update'
)
Assert-Contract (-not ($staleEvidenceClaimPatterns | Where-Object { $implementation -match $_ })) 'EVID-07' 'The committed/pushed evidence successor still describes its own document update as unstaged or not committed/pushed.'

# Monitoring: 17 alert rules, supported API shapes, scopes, probes, thresholds and routing.
$alerts = Read-Repo 'infra/bicep/modules/alerts.bicep'
$mainBicep = Read-Repo 'infra/bicep/main.bicep'
$appsBicep = Read-Repo 'infra/bicep/modules/appservice.bicep'
$dataBicep = Read-Repo 'infra/bicep/modules/data.bicep'
$monitoringBicep = Read-Repo 'infra/bicep/modules/monitoring.bicep'
$requiredAlertNames = @(
    'alert-lgrtm-web-health-azdemo', 'alert-lgrtm-api-readiness-azdemo',
    'alert-lgrtm-web-http5xx-azdemo', 'alert-lgrtm-api-http5xx-azdemo',
    'alert-lgrtm-unhandled-errors-azdemo', 'alert-lgrtm-auth-failures-denials-azdemo',
    'alert-lgrtm-sql-dtu-azdemo', 'alert-lgrtm-sql-connectivity-azdemo',
    'alert-lgrtm-keyvault-denial-azdemo', 'alert-lgrtm-blob-dependency-azdemo',
    'alert-lgrtm-import-failure-azdemo', 'alert-lgrtm-storage-malware-azdemo',
    'alert-lgrtm-failed-deployment-azdemo', 'alert-lgrtm-web-slot-health-azdemo',
    'alert-lgrtm-api-slot-health-azdemo', 'alert-lgrtm-log-daily-cap-azdemo',
    'alert-lgrtm-service-health-azdemo'
)
Assert-Contract (-not ($requiredAlertNames | Where-Object { -not $alerts.Contains($_) })) 'MON-01' 'One or more of the 17 mandatory alert resources is absent.'
Assert-Contract (
    [regex]::Matches($alerts, "'Microsoft\.Insights/webtests@2022-06-15'").Count -eq 2 -and
    [regex]::Matches($alerts, "'Microsoft\.Insights/metricAlerts@2018-03-01'").Count -eq 7 -and
    [regex]::Matches($alerts, "'Microsoft\.Insights/scheduledQueryRules@2023-12-01'").Count -eq 1 -and
    [regex]::Matches($alerts, "'Microsoft\.Insights/activityLogAlerts@2020-10-01'").Count -eq 2
) 'MON-02' 'Azure Monitor resource types or supported API versions are incomplete.'
Assert-Contract ($alerts -match "RequestUrl: 'https://`\$\{webHostname\}/'" -and $alerts -match "RequestUrl: 'https://`\$\{webHostname\}/health'" -and $alerts -match 'ExpectedHttpStatusCode:\s*200' -and $alerts -match 'SSLCertRemainingLifetimeCheck:\s*7') 'MON-03' 'Availability or readiness probe shape is incomplete.'
$requiredScopes = @(
    'scopes: [webSiteId]', 'scopes: [apiSiteId]', 'scopes: [sqlDatabaseId]',
    'scopes: [webStagingSlotId]', 'scopes: [apiStagingSlotId]',
    'scopes: [logAnalyticsWorkspaceId]', 'scopes: [resourceGroup().id]',
    'scopes: [subscription().id]'
)
Assert-Contract (-not ($requiredScopes | Where-Object { -not $alerts.Contains($_) })) 'MON-04' 'A mandatory alert scope is missing or points at the wrong resource family.'
$requiredSemantics = @(
    'AppExceptions', "ResultCode in ('401', '403')", "DependencyType has 'SQL'",
    '.vault.azure.net', '.blob.core.windows.net', '/discovery-imports',
    "ScanResultType in~ ('Malicious', 'Error', 'Not Scanned')",
    'Microsoft.Resources/deployments/write', "metricName: 'HealthCheckStatus'",
    'telemetryDailyCapGb} * 0.9', "equals: 'ServiceHealth'",
    'threshold: 5', 'threshold: 80', 'failedLocationCount: 1'
)
Assert-Contract (-not ($requiredSemantics | Where-Object { -not $alerts.Contains($_) })) 'MON-05' 'A required alert query, platform signal, probe threshold or cap threshold is absent.'
$requiredWiring = @(
    'actionGroupId: monitoring.outputs.actionGroupId',
    'applicationInsightsResourceId: monitoring.outputs.applicationInsightsResourceId',
    'logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId',
    'telemetryDailyCapGb: telemetryDailyCapGb',
    'webStagingSlotId: apps.outputs.webStagingSlotId',
    'apiStagingSlotId: apps.outputs.apiStagingSlotId'
)
Assert-Contract (-not ($requiredWiring | Where-Object { -not $mainBicep.Contains($_) }) -and $appsBicep.Contains('output webStagingSlotId string = webSlot.id') -and $appsBicep.Contains('output apiStagingSlotId string = apiSlot.id')) 'MON-06' 'Main-template parameter or staging-slot resource-ID wiring is incomplete.'
Assert-Contract ([regex]::Matches($alerts, 'actionGroupId').Count -ge 10 -and $alerts -match 'actions:\s*\{\s*actionGroups:\s*\[actionGroupId\]') 'MON-07' 'One or more alert families is not routed to the approved action group.'

# Blob diagnostics do not populate StorageMalwareScanningResults. The Defender
# settings resource must emit its ScanResults category to the workspace.
$hasDefenderSettings = $dataBicep -match "(?ms)resource\s+storageDefender\s+'Microsoft\.Security/defenderForStorageSettings@2022-12-01-preview'.*?scope:\s*storage.*?name:\s*'current'.*?isEnabled:\s*true.*?malwareScanning:\s*\{\s*onUpload:\s*\{\s*isEnabled:\s*true\s*capGBPerMonth:\s*10.*?overrideSubscriptionLevelSettings:\s*true"
$hasDefenderDiagnostic = $dataBicep -match "(?ms)resource\s+storageMalwareScanResultsDiagnostics\s+'Microsoft\.Insights/diagnosticSettings@2021-05-01-preview'.*?scope:\s*storageDefender.*?name:\s*'service'.*?workspaceId:\s*logAnalyticsWorkspaceId.*?category:\s*'ScanResults'\s*enabled:\s*true\s*retentionPolicy:\s*\{\s*enabled:\s*true\s*days:\s*logRetentionDays"
Assert-Contract ($hasDefenderSettings -and $hasDefenderDiagnostic -and $mainBicep -match '@allowed\(\[30\]\)\s*param logRetentionDays int = 30') 'MON-08' 'Defender enablement, on-upload scanning, approved 10 GB cap, override, exact nested ScanResults diagnostic route, workspace or 30-day retention is incomplete.'
$exactNestedRoute = '/providers/microsoft.security/defenderforstoragesettings/current/providers/microsoft.insights/diagnosticsettings/service'
Assert-Contract ($alerts.ToLowerInvariant().Contains($exactNestedRoute) -and $mainBicep.Contains('malwareScanResultsDiagnosticId: data.outputs.storageMalwareScanResultsDiagnosticId') -and $dataBicep.Contains('output storageMalwareScanResultsDiagnosticId string = storageMalwareScanResultsDiagnostics.id')) 'MON-09' 'The exact nested Defender diagnostic route is not carried into the malware alert module dependency contract.'
Assert-Contract ($monitoringBicep -match 'workspaceCapping:\s*\{\s*dailyQuotaGb:\s*telemetryDailyCapGb\s*\}' -and $mainBicep -match 'param telemetryDailyCapGb' -and $alerts -match 'param telemetryDailyCapGb') 'MON-10' 'The daily telemetry cap is not wired from configuration to workspace and alert threshold.'
Assert-Contract ($mainBicep.IndexOf("module monitoring", [StringComparison]::Ordinal) -lt $mainBicep.IndexOf("module data", [StringComparison]::Ordinal) -and $mainBicep.IndexOf("module data", [StringComparison]::Ordinal) -lt $mainBicep.IndexOf("module alerts", [StringComparison]::Ordinal) -and $dataBicep.IndexOf("resource storage ", [StringComparison]::Ordinal) -lt $dataBicep.IndexOf("resource storageDefender ", [StringComparison]::Ordinal) -and $dataBicep.IndexOf("resource storageDefender ", [StringComparison]::Ordinal) -lt $dataBicep.IndexOf("resource storageMalwareScanResultsDiagnostics ", [StringComparison]::Ordinal)) 'MON-11' 'Workspace, storage, Defender, ScanResults route and malware alert declaration/dependency order is invalid.'

# Rollback guard: current immutable release succeeds and ten invalid targets fail.
$pipeline = Read-Repo 'azure-pipelines.yml'
$guard = Join-Path $repo 'scripts\build\Assert-AzureDemoRollbackTarget.ps1'
$valid = @{
    SourceBranch = 'refs/heads/release/azure-demo-v1'
    SourceVersion = $CandidateCommit
    ReleaseIdentifier = $CandidateCommit
    DeploymentEnvironmentName = 'azure-demo'
    ResourceGroupName = 'Onkar.Pathre'
    WebAppName = 'app-lgrtm-web-azdemo-uks-abc123'
    ExpectedWebAppName = 'app-lgrtm-web-azdemo-uks-abc123'
    ApiAppName = 'app-lgrtm-api-azdemo-uks-abc123'
    ExpectedApiAppName = 'app-lgrtm-api-azdemo-uks-abc123'
    WebSlotName = 'staging'
    ApiSlotName = 'staging'
    TargetSlotName = 'production'
}
$validAccepted = $true
try { & $guard @valid | Out-Null } catch { $validAccepted = $false }
Assert-Contract $validAccepted 'ROLL-01' 'The exact candidate and approved target were rejected.'
$negativeCases = @(
    @{ Key = 'SourceBranch'; Value = 'refs/heads/main' },
    @{ Key = 'ReleaseIdentifier'; Value = '' },
    @{ Key = 'ReleaseIdentifier'; Value = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' },
    @{ Key = 'DeploymentEnvironmentName'; Value = 'production' },
    @{ Key = 'ResourceGroupName'; Value = 'unrelated-rg' },
    @{ Key = 'WebAppName'; Value = 'app-other-web' },
    @{ Key = 'ApiAppName'; Value = 'app-other-api' },
    @{ Key = 'WebSlotName'; Value = 'production' },
    @{ Key = 'ApiSlotName'; Value = 'production' },
    @{ Key = 'TargetSlotName'; Value = 'staging' }
)
$rejected = 0
foreach ($case in $negativeCases) {
    $arguments = @{} + $valid
    $arguments[$case.Key] = $case.Value
    try { & $guard @arguments | Out-Null } catch { $rejected++ }
}
Assert-Contract ($rejected -eq 10) 'ROLL-02' "The guard rejected $rejected of 10 invalid rollback targets."

$rollback = $pipeline.Substring($pipeline.IndexOf('- stage: Rollback', [StringComparison]::Ordinal))
$rollbackFragments = @(
    'dependsOn: SwapAndVerify',
    "in(dependencies.SwapAndVerify.result, 'Succeeded', 'SucceededWithIssues', 'Failed')",
    "eq('`${{ parameters.deployAzureDemo }}', true)",
    "eq('`${{ parameters.rollbackAzureDemo }}', true)",
    "eq(variables['Build.SourceBranch'], 'refs/heads/release/azure-demo-v1')",
    "eq('`${{ parameters.rollbackReleaseIdentifier }}', variables['Build.SourceVersion'])",
    "eq('`${{ parameters.rollbackEnvironmentName }}', 'azure-demo')",
    "eq('`${{ parameters.rollbackResourceGroupName }}', 'Onkar.Pathre')",
    "eq('`${{ parameters.rollbackWebAppName }}', variables['webAppName'])",
    "eq('`${{ parameters.rollbackApiAppName }}', variables['apiAppName'])",
    "eq('`${{ parameters.rollbackWebSlotName }}', variables['webSlotName'])",
    "eq('`${{ parameters.rollbackApiSlotName }}', variables['apiSlotName'])",
    "eq('`${{ parameters.rollbackTargetSlotName }}', 'production')"
)
Assert-Contract (-not ($rollbackFragments | Where-Object { -not $rollback.Contains($_) })) 'ROLL-03' 'Rollback stage conditions do not fail closed for the same-run release and exact target.'
Assert-Contract ($rollback.IndexOf('Assert-AzureDemoRollbackTarget.ps1', [StringComparison]::Ordinal) -lt $rollback.IndexOf('AzureCLI@2', [StringComparison]::Ordinal)) 'ROLL-04' 'An Azure rollback task can execute before the target guard.'
Assert-Contract ($rollback.IndexOf('--name $env:ROLLBACK_WEB_APP', [StringComparison]::Ordinal) -lt $rollback.IndexOf('--name $env:ROLLBACK_API_APP', [StringComparison]::Ordinal)) 'ROLL-05' 'Rollback execution order is not web before API.'

# Security and immutable product-boundary assertions.
$startup = Read-Repo 'src/api/Program.cs'
$dataTool = Read-Repo 'tools/AzureDemo.DataTool/Program.cs'
$azureGuard = Read-Repo 'src/api/Infrastructure/AzureDemoInfrastructure.cs'
$proxy = Read-Repo 'src/web/app/api/[...path]/route.ts'
$entra = Read-Repo 'src/web/components/EntraAuth.tsx'
$health = Read-Repo 'src/api/Infrastructure/HealthAndSecurity.cs'
$webHealth = Read-Repo 'src/web/app/health/route.ts'
$apiProject = Read-Repo 'src/api/LgrTransformationMigration.Api.csproj'
$azureSettings = Read-Repo 'src/api/appsettings.AzureDemo.json'
$seedManifest = Read-Repo 'demo-data/azure-demo-seed-manifest.json'
Assert-Contract ($azureSettings -match '"Mode":\s*"Entra"' -and $azureSettings -notmatch 'LocalTest' -and $azureGuard -match 'Authentication:Mode must be Entra' -and $azureGuard -match 'prohibitedConfiguration') 'SEC-01' 'Azure authentication does not prohibit LocalTest and fail closed to Entra.'
$identityHeaders = @('x-customer-id','x-user-name','x-lgr-test-principal','x-principal-id','x-roles','x-project-roles','x-permissions','cookie','x-forwarded-for','x-forwarded-host','x-forwarded-proto')
Assert-Contract (-not ($identityHeaders | Where-Object { $proxy -notmatch [regex]::Escape($_) }) -and $proxy -notmatch 'headers\.set\("x-lgr-test-principal"') 'SEC-02' 'The web proxy can emit or fails to strip a prohibited identity header.'
Assert-Contract ($entra -notmatch 'localStorage|setItem\([^\r\n]*access[_-]?token' -and $entra -match 'code_challenge_method:\s*"S256"') 'SEC-03' 'Browser authentication persists access tokens or omits PKCE S256.'
Assert-Contract ($azureGuard -match 'ActiveDirectoryManagedIdentity' -and $azureGuard -match 'TrustServerCertificate' -and $azureGuard -match 'sql\.Password' -and $azureGuard -match 'sqlIdentity != configuredIdentity') 'SEC-04' 'Managed-identity/passwordless SQL enforcement is incomplete.'
Assert-Contract ($startup -notmatch 'Database\.(?:Migrate|EnsureCreated)|MigrateAsync|SeedData\.Configure' -and $dataTool -notmatch 'Database\.(?:Migrate|EnsureCreated)|MigrateAsync|EnsureCreatedAsync') 'SEC-05' 'Migration/schema/seed execution can occur during application startup or through the data tool.'
Assert-Contract ($seedManifest -match 'synthetic' -and $seedManifest -match 'AzureDemo|azdemo' -and $seedManifest -match 'production-data' -and $seedManifest -match 'customer-data') 'SEC-06' 'The seed manifest is not constrained to synthetic AzureDemo data.'
Assert-Contract ($health -notmatch 'connectionString|SecretUri|ManagedIdentityClientId' -and $webHealth -notmatch 'connectionString|SecretUri|ManagedIdentityClientId' -and $health -match 'status = "Unavailable"') 'SEC-07' 'Health/readiness responses can disclose sensitive dependency details or do not fail safely.'
Assert-Contract ($apiProject -match 'appsettings\.LocalTest\.json" CopyToPublishDirectory="Never"' -and $apiProject -match 'appsettings\.Development\.json" CopyToPublishDirectory="Never"' -and $apiProject -match 'appsettings\.Testing\.json" CopyToPublishDirectory="Never"') 'SEC-08' 'Local/development configuration is not excluded from published artifacts.'
$allSource = $startup + $dataTool + $azureGuard + $proxy
Assert-Contract ($allSource -notmatch 'Azure\.ResourceManager|Microsoft\.Azure\.Management|api\.migrate\.azure\.com|AzureOpenAI|Anthropic') 'BOUNDARY-01' 'A prohibited provisioning, discovery API or AI capability is present in the deployment implementation.'

Write-Output "PASS=$($passes.Count) FAIL=$($failures.Count)"
$passes | ForEach-Object { Write-Output "PASS $_" }
$failures | ForEach-Object { Write-Output "FAIL $_" }
if ($failures.Count) { exit 1 }
