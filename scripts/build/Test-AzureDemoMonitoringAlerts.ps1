[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$alerts = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\alerts.bicep') -Raw
$main = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\main.bicep') -Raw
$apps = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\appservice.bicep') -Raw
$data = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\data.bicep') -Raw
$parameterPaths = @(
    'infra\bicep\parameters\azure-demo.bicepparam',
    'infra\bicep\parameters\dev.bicepparam'
)

function Get-BicepDeclaration([string] $Content, [string] $Symbol) {
    $pattern = "(?ms)^resource\s+$([regex]::Escape($Symbol))\s+.+?(?=^resource\s+|^module\s+|^output\s+|\z)"
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success) {
        throw "Bicep resource declaration is missing: $Symbol"
    }
    return $match.Value
}

function Assert-ExactLiteralCount([string] $Content, [string] $Literal, [int] $ExpectedCount, [string] $Context) {
    $actualCount = [regex]::Matches($Content, [regex]::Escape($Literal)).Count
    if ($actualCount -ne $ExpectedCount) {
        throw "$Context must contain '$Literal' exactly $ExpectedCount time(s); found $actualCount."
    }
}

function Get-AlertNameAssignments([string] $ParameterContent, [string] $ParameterPath) {
    $match = [regex]::Match($ParameterContent, '(?ms)^\s{2}alerts:\s*\{\r?\n(?<body>.*?)^\s{2}\}\r?$')
    if (-not $match.Success) {
        throw "$ParameterPath does not contain the exact resourceNames.alerts object."
    }

    $assignments = @{}
    foreach ($line in ($match.Groups['body'].Value -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -notmatch "^\s{4}(?<key>[A-Za-z][A-Za-z0-9]*):\s+'(?<value>[^']+)'\s*$") {
            throw "$ParameterPath contains an invalid alert-name assignment: $line"
        }
        if ($assignments.ContainsKey($Matches['key'])) {
            throw "$ParameterPath contains duplicate alert-name key $($Matches['key'])."
        }
        $assignments[$Matches['key']] = $Matches['value']
    }
    return $assignments
}

function Assert-MetricAlertDeclaration(
    [string] $Declaration,
    [string] $Symbol,
    [string] $AlertNameKey,
    [string] $Scope,
    [string] $MetricName,
    [string] $MetricNamespace,
    [string] $Aggregation,
    [string] $Description,
    [string] $EvaluationFrequency,
    [string] $WindowSize,
    [string] $Operator,
    [int] $Threshold
) {
    $required = @(
        "name: alertNames.$AlertNameKey",
        "description: '$Description'",
        'enabled: true',
        "scopes: [$Scope]",
        "evaluationFrequency: '$EvaluationFrequency'",
        "windowSize: '$WindowSize'",
        "metricName: '$MetricName'",
        "metricNamespace: '$MetricNamespace'",
        "operator: '$Operator'",
        "threshold: $Threshold",
        "timeAggregation: '$Aggregation'",
        'actionGroupId: actionGroupId'
    )
    foreach ($fragment in $required) {
        Assert-ExactLiteralCount $Declaration $fragment 1 "Metric alert $Symbol"
    }
    Assert-ExactLiteralCount $Declaration 'metricName:' 1 "Metric alert $Symbol"
    Assert-ExactLiteralCount $Declaration 'metricNamespace:' 1 "Metric alert $Symbol"
    Assert-ExactLiteralCount $Declaration 'scopes:' 1 "Metric alert $Symbol"
}

function Assert-RejectedMutation([scriptblock] $Assertion, [string] $Description) {
    $rejected = $false
    try {
        & $Assertion
    }
    catch {
        $rejected = $true
    }
    if (-not $rejected) {
        throw "Monitoring regression did not reject: $Description"
    }
    $script:rejectedMetricMutations++
}

function Replace-FirstLiteral([string] $Content, [string] $OldValue, [string] $NewValue) {
    $index = $Content.IndexOf($OldValue, [StringComparison]::Ordinal)
    if ($index -lt 0) {
        throw "Mutation source is missing: $OldValue"
    }
    return $Content.Substring(0, $index) + $NewValue + $Content.Substring($index + $OldValue.Length)
}

$expectedResourceNames = [ordered]@{
    webHealthTest = 'webtest-mtp-web-health-dev-uks-001'
    apiReadinessTest = 'webtest-mtp-api-readiness-dev-uks-001'
    webHealth = 'alert-mtp-web-health-dev-uks-001'
    apiReadiness = 'alert-mtp-api-readiness-dev-uks-001'
    webHttp5xx = 'alert-mtp-web-http5xx-dev-uks-001'
    apiHttp5xx = 'alert-mtp-api-http5xx-dev-uks-001'
    unhandledErrors = 'alert-mtp-unhandled-errors-dev-uks-001'
    authFailuresDenials = 'alert-mtp-auth-failures-denials-dev-uks-001'
    sqlCpu = 'alert-mtp-sql-cpu-dev-uks-001'
    sqlConnectivity = 'alert-mtp-sql-connectivity-dev-uks-001'
    keyVaultDenial = 'alert-mtp-keyvault-denial-dev-uks-001'
    blobDependency = 'alert-mtp-blob-dependency-dev-uks-001'
    importFailure = 'alert-mtp-import-failure-dev-uks-001'
    storageMalware = 'alert-mtp-storage-malware-dev-uks-001'
    failedDeployment = 'alert-mtp-failed-deployment-dev-uks-001'
    webSlotHealth = 'alert-mtp-web-slot-health-dev-uks-001'
    apiSlotHealth = 'alert-mtp-api-slot-health-dev-uks-001'
    logDailyCap = 'alert-mtp-log-daily-cap-dev-uks-001'
    serviceHealth = 'alert-mtp-service-health-dev-uks-001'
}

$requiredAlertNames = @(
    'alert-mtp-web-health-dev-uks-001',
    'alert-mtp-api-readiness-dev-uks-001',
    'alert-mtp-web-http5xx-dev-uks-001',
    'alert-mtp-api-http5xx-dev-uks-001',
    'alert-mtp-unhandled-errors-dev-uks-001',
    'alert-mtp-auth-failures-denials-dev-uks-001',
    'alert-mtp-sql-cpu-dev-uks-001',
    'alert-mtp-sql-connectivity-dev-uks-001',
    'alert-mtp-keyvault-denial-dev-uks-001',
    'alert-mtp-blob-dependency-dev-uks-001',
    'alert-mtp-import-failure-dev-uks-001',
    'alert-mtp-storage-malware-dev-uks-001',
    'alert-mtp-failed-deployment-dev-uks-001',
    'alert-mtp-web-slot-health-dev-uks-001',
    'alert-mtp-api-slot-health-dev-uks-001',
    'alert-mtp-log-daily-cap-dev-uks-001',
    'alert-mtp-service-health-dev-uks-001'
)

foreach ($parameterPath in $parameterPaths) {
    $parameterContent = Get-Content -LiteralPath (Join-Path $repo $parameterPath) -Raw
    $assignments = Get-AlertNameAssignments $parameterContent $parameterPath
    if ($assignments.Count -ne $expectedResourceNames.Count) {
        throw "$parameterPath must contain exactly $($expectedResourceNames.Count) monitoring resource names; found $($assignments.Count)."
    }
    foreach ($key in $expectedResourceNames.Keys) {
        if (-not $assignments.ContainsKey($key) -or $assignments[$key] -cne $expectedResourceNames[$key]) {
            throw "$parameterPath does not map $key to exact resource name $($expectedResourceNames[$key])."
        }
    }
    foreach ($name in $requiredAlertNames) {
        Assert-ExactLiteralCount $parameterContent $name 1 $parameterPath
    }
    foreach ($exactScopeInput in @(
            "webApp: 'app-mtp-web-dev-uks-001'",
            "apiApp: 'app-mtp-api-dev-uks-001'",
            "sqlServer: 'sql-mtp-dev-uks-001'",
            "sqlDatabase: 'sqldb-mtp-dev-uks-001'",
            "stagingSlot: 'staging'"
        )) {
        Assert-ExactLiteralCount $parameterContent $exactScopeInput 1 $parameterPath
    }
}

if ($requiredAlertNames.Count -ne 17) {
    throw "The mandatory monitoring alert count changed from 17 to $($requiredAlertNames.Count)."
}
if ($alerts -match '(?i)dtu_consumption_percent|app_cpu_percent|sqlDtu|sql-dtu|SQL DTU') {
    throw 'The active monitoring implementation retains prohibited SQL DTU or app-only CPU terminology.'
}

$requiredResourceTypes = @(
    'Microsoft.Insights/webtests@2022-06-15',
    'Microsoft.Insights/metricAlerts@2018-03-01',
    'Microsoft.Insights/scheduledQueryRules@2023-12-01',
    'Microsoft.Insights/activityLogAlerts@2020-10-01'
)
foreach ($resourceType in $requiredResourceTypes) {
    if (-not $alerts.Contains($resourceType)) {
        throw "Monitoring module is missing required resource type: $resourceType"
    }
}
Assert-ExactLiteralCount $alerts "'Microsoft.Insights/webtests@2022-06-15'" 2 'Monitoring module'
Assert-ExactLiteralCount $alerts "'Microsoft.Insights/metricAlerts@2018-03-01'" 7 'Monitoring module'
Assert-ExactLiteralCount $alerts "'Microsoft.Insights/scheduledQueryRules@2023-12-01'" 1 'Monitoring module'
Assert-ExactLiteralCount $alerts "'Microsoft.Insights/activityLogAlerts@2020-10-01'" 2 'Monitoring module'

$requiredSemantics = @(
    "RequestUrl: 'https://`${webHostname}/'",
    "RequestUrl: 'https://`${webHostname}/health'",
    'AppExceptions',
    "ResultCode in ('401', '403')",
    "DependencyType has 'SQL'",
    'environment().suffixes.keyvaultDns',
    'environment().suffixes.storage',
    '/discovery-imports',
    "ScanResultType in~ ('Malicious', 'Error', 'Not Scanned')",
    'Microsoft.Resources/deployments/write',
    "metricName: 'HealthCheckStatus'",
    'telemetryDailyCapGb',
    "equals: 'ServiceHealth'"
)
foreach ($fragment in $requiredSemantics) {
    if (-not $alerts.Contains($fragment)) {
        throw "Mandatory monitoring alert semantics are missing: $fragment"
    }
}

$requiredWiring = @(
    'actionGroupId: actionGroupId',
    'applicationInsightsResourceId: monitoring.outputs.applicationInsightsResourceId',
    'logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId',
    'telemetryDailyCapGb: telemetryDailyCapGb',
    'webStagingSlotId: apps.outputs.webStagingSlotId',
    'apiStagingSlotId: apps.outputs.apiStagingSlotId',
    'sqlDatabaseId: data.outputs.sqlDatabaseId'
)
foreach ($fragment in $requiredWiring) {
    if (-not ($alerts.Contains($fragment) -or $main.Contains($fragment))) {
        throw "Monitoring action-group or parameter wiring is missing: $fragment"
    }
}

foreach ($slotOutput in @('output webStagingSlotId string = webSlot.id', 'output apiStagingSlotId string = apiSlot.id')) {
    if (-not $apps.Contains($slotOutput)) {
        throw "App Service slot monitoring output is missing: $slotOutput"
    }
}
foreach ($slotContract in @(
        @{ Symbol = 'webSlot'; Parent = 'web' },
        @{ Symbol = 'apiSlot'; Parent = 'api' }
    )) {
    $slotDeclaration = Get-BicepDeclaration $apps $slotContract.Symbol
    foreach ($fragment in @(
            "resource $($slotContract.Symbol) 'Microsoft.Web/sites/slots@2023-12-01'",
            "parent: $($slotContract.Parent)",
            'name: stagingSlotName'
        )) {
        Assert-ExactLiteralCount $slotDeclaration $fragment 1 "App Service slot $($slotContract.Symbol)"
    }
}
if (-not $data.Contains('output sqlDatabaseId string = sqlDatabase.id')) {
    throw 'The SQL metric scope is not wired to the exact SQL database resource ID.'
}

$metricContracts = @(
    [pscustomobject]@{
        Symbol = 'webSlotHealth'; AlertNameKey = 'webSlotHealth'; Scope = 'webStagingSlotId'
        MetricName = 'HealthCheckStatus'; MetricNamespace = 'Microsoft.Web/sites/slots'; Aggregation = 'Average'
        Description = 'Restricted demo web staging slot health check is unhealthy.'
        EvaluationFrequency = 'PT5M'; WindowSize = 'PT5M'; Operator = 'LessThan'; Threshold = 1
    },
    [pscustomobject]@{
        Symbol = 'apiSlotHealth'; AlertNameKey = 'apiSlotHealth'; Scope = 'apiStagingSlotId'
        MetricName = 'HealthCheckStatus'; MetricNamespace = 'Microsoft.Web/sites/slots'; Aggregation = 'Average'
        Description = 'Restricted demo API staging slot readiness check is unhealthy.'
        EvaluationFrequency = 'PT5M'; WindowSize = 'PT5M'; Operator = 'LessThan'; Threshold = 1
    },
    [pscustomobject]@{
        Symbol = 'sqlCpu'; AlertNameKey = 'sqlCpu'; Scope = 'sqlDatabaseId'
        MetricName = 'cpu_percent'; MetricNamespace = 'Microsoft.Sql/servers/databases'; Aggregation = 'Average'
        Description = 'Restricted demo SQL CPU usage exceeds threshold.'
        EvaluationFrequency = 'PT5M'; WindowSize = 'PT15M'; Operator = 'GreaterThan'; Threshold = 80
    }
)

$metricDeclarations = @{}
foreach ($contract in $metricContracts) {
    $declaration = Get-BicepDeclaration $alerts $contract.Symbol
    $metricDeclarations[$contract.Symbol] = $declaration
    Assert-MetricAlertDeclaration $declaration $contract.Symbol $contract.AlertNameKey $contract.Scope $contract.MetricName `
        $contract.MetricNamespace $contract.Aggregation $contract.Description $contract.EvaluationFrequency `
        $contract.WindowSize $contract.Operator $contract.Threshold
}

foreach ($slotSymbol in @('webSlotHealth', 'apiSlotHealth')) {
    if ($metricDeclarations[$slotSymbol] -match "metricNamespace:\s*'Microsoft\.Web/sites'") {
        throw "$slotSymbol incorrectly uses the parent App Service metric namespace."
    }
}
if ($metricDeclarations['sqlCpu'] -notmatch "(?m)^\s*description:\s*'[^']*SQL CPU[^']*'\s*$" -or
    $metricDeclarations['sqlCpu'] -match '(?i)DTU') {
    throw 'The SQL metric alert name or description does not use exact CPU terminology.'
}

$script:rejectedMetricMutations = 0
$webWrongNamespace = Replace-FirstLiteral $metricDeclarations['webSlotHealth'] "metricNamespace: 'Microsoft.Web/sites/slots'" "metricNamespace: 'Microsoft.Web/sites'"
Assert-RejectedMutation { Assert-MetricAlertDeclaration $webWrongNamespace 'webSlotHealth' 'webSlotHealth' 'webStagingSlotId' 'HealthCheckStatus' 'Microsoft.Web/sites/slots' 'Average' 'Restricted demo web staging slot health check is unhealthy.' 'PT5M' 'PT5M' 'LessThan' 1 } 'web slot parent-site namespace'
$apiWrongNamespace = Replace-FirstLiteral $metricDeclarations['apiSlotHealth'] "metricNamespace: 'Microsoft.Web/sites/slots'" "metricNamespace: 'Microsoft.Web/sites'"
Assert-RejectedMutation { Assert-MetricAlertDeclaration $apiWrongNamespace 'apiSlotHealth' 'apiSlotHealth' 'apiStagingSlotId' 'HealthCheckStatus' 'Microsoft.Web/sites/slots' 'Average' 'Restricted demo API staging slot readiness check is unhealthy.' 'PT5M' 'PT5M' 'LessThan' 1 } 'API slot parent-site namespace'
$webWrongScope = Replace-FirstLiteral $metricDeclarations['webSlotHealth'] 'scopes: [webStagingSlotId]' 'scopes: [webSiteId]'
Assert-RejectedMutation { Assert-MetricAlertDeclaration $webWrongScope 'webSlotHealth' 'webSlotHealth' 'webStagingSlotId' 'HealthCheckStatus' 'Microsoft.Web/sites/slots' 'Average' 'Restricted demo web staging slot health check is unhealthy.' 'PT5M' 'PT5M' 'LessThan' 1 } 'web production-site scope'
$apiWrongScope = Replace-FirstLiteral $metricDeclarations['apiSlotHealth'] 'scopes: [apiStagingSlotId]' 'scopes: [apiSiteId]'
Assert-RejectedMutation { Assert-MetricAlertDeclaration $apiWrongScope 'apiSlotHealth' 'apiSlotHealth' 'apiStagingSlotId' 'HealthCheckStatus' 'Microsoft.Web/sites/slots' 'Average' 'Restricted demo API staging slot readiness check is unhealthy.' 'PT5M' 'PT5M' 'LessThan' 1 } 'API production-site scope'
$sqlDtuMutation = Replace-FirstLiteral $metricDeclarations['sqlCpu'] "metricName: 'cpu_percent'" "metricName: 'dtu_consumption_percent'"
Assert-RejectedMutation { Assert-MetricAlertDeclaration $sqlDtuMutation 'sqlCpu' 'sqlCpu' 'sqlDatabaseId' 'cpu_percent' 'Microsoft.Sql/servers/databases' 'Average' 'Restricted demo SQL CPU usage exceeds threshold.' 'PT5M' 'PT15M' 'GreaterThan' 80 } 'unavailable SQL DTU metric'
$sqlAppCpuMutation = Replace-FirstLiteral $metricDeclarations['sqlCpu'] "metricName: 'cpu_percent'" "metricName: 'app_cpu_percent'"
Assert-RejectedMutation { Assert-MetricAlertDeclaration $sqlAppCpuMutation 'sqlCpu' 'sqlCpu' 'sqlDatabaseId' 'cpu_percent' 'Microsoft.Sql/servers/databases' 'Average' 'Restricted demo SQL CPU usage exceeds threshold.' 'PT5M' 'PT15M' 'GreaterThan' 80 } 'unapproved app-only SQL CPU metric'

Assert-ExactLiteralCount $alerts 'actionGroupId: actionGroupId' 9 'Monitoring module action-group binding'
Assert-ExactLiteralCount $alerts 'actionGroups: [actionGroupId]' 1 'Scheduled-query action-group binding'
if ($alerts -match '(?i)Microsoft\.Authorization/roleAssignments|roleDefinitionId|principalId|\bidentity\s*:') {
    throw 'The alert module must not create identities or expand Azure permissions.'
}

$defender = Get-BicepDeclaration $data 'storageDefender'
$scanResultsDiagnostic = Get-BicepDeclaration $data 'storageMalwareScanResultsDiagnostics'
$requiredDefenderSettings = @(
    "'Microsoft.Security/defenderForStorageSettings@2022-12-01-preview'",
    'scope: storage',
    "name: 'current'",
    'isEnabled: true',
    'malwareScanning:',
    'onUpload:',
    'capGBPerMonth: 10',
    'overrideSubscriptionLevelSettings: true'
)
foreach ($fragment in $requiredDefenderSettings) {
    if (-not $defender.Contains($fragment)) {
        throw "Defender for Storage setting is incomplete: $fragment"
    }
}
if ($defender -notmatch '(?ms)properties:\s*\{\s*isEnabled:\s*true.*?malwareScanning:\s*\{\s*onUpload:\s*\{\s*isEnabled:\s*true\s*capGBPerMonth:\s*10\s*\}') {
    throw 'Defender for Storage and its on-upload malware scanner are not both explicitly enabled with the approved 10 GB monthly cap.'
}

$requiredDiagnosticSettings = @(
    "'Microsoft.Insights/diagnosticSettings@2021-05-01-preview'",
    'scope: storageDefender',
    "name: 'service'",
    'workspaceId: logAnalyticsWorkspaceId',
    "category: 'ScanResults'",
    'enabled: true',
    'retentionPolicy:',
    'days: logRetentionDays'
)
foreach ($fragment in $requiredDiagnosticSettings) {
    if (-not $scanResultsDiagnostic.Contains($fragment)) {
        throw "Defender ScanResults diagnostic route is incomplete: $fragment"
    }
}
if ($scanResultsDiagnostic -notmatch "(?ms)logs:\s*\[\s*\{\s*category:\s*'ScanResults'\s*enabled:\s*true\s*retentionPolicy:\s*\{\s*enabled:\s*true\s*days:\s*logRetentionDays") {
    throw 'The ScanResults log category and its architecture-controlled retention are not both enabled.'
}

$dependencyAndAlertCoupling = @(
    'logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId',
    'logRetentionDays: logRetentionDays',
    'malwareScanResultsDiagnosticId: data.outputs.storageMalwareScanResultsDiagnosticId',
    'output storageMalwareScanResultsDiagnosticId string = storageMalwareScanResultsDiagnostics.id'
)
foreach ($fragment in $dependencyAndAlertCoupling) {
    if (-not ($main.Contains($fragment) -or $data.Contains($fragment))) {
        throw "Workspace, storage, Defender, diagnostic and alert dependency coupling is incomplete: $fragment"
    }
}
if (-not $alerts.Contains('param malwareScanResultsDiagnosticId string') -or
    -not $alerts.Contains('/providers/microsoft.security/defenderforstoragesettings/current/providers/microsoft.insights/diagnosticsettings/service') -or
    -not $alerts.Contains('StorageMalwareScanningResults')) {
    throw 'The Defender ScanResults route is not coupled to the StorageMalwareScanningResults alert.'
}

Write-Output "Azure demo monitoring contract passed for $($requiredAlertNames.Count) mandatory alert resources; 3 exact metric contracts passed and $script:rejectedMetricMutations invalid metric mutations were rejected."
