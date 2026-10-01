[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$alerts = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\alerts.bicep') -Raw
$main = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\main.bicep') -Raw
$apps = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\appservice.bicep') -Raw
$data = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\data.bicep') -Raw
$parameters = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\parameters\azure-demo.bicepparam') -Raw

function Get-BicepDeclaration([string] $Content, [string] $Symbol) {
    $pattern = "(?ms)^resource\s+$([regex]::Escape($Symbol))\s+.+?(?=^resource\s+|^module\s+|^output\s+|\z)"
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success) {
        throw "Bicep resource declaration is missing: $Symbol"
    }
    return $match.Value
}

$requiredAlertNames = @(
    'alert-mtp-web-health-dev-uks-001',
    'alert-mtp-api-readiness-dev-uks-001',
    'alert-mtp-web-http5xx-dev-uks-001',
    'alert-mtp-api-http5xx-dev-uks-001',
    'alert-mtp-unhandled-errors-dev-uks-001',
    'alert-mtp-auth-failures-denials-dev-uks-001',
    'alert-mtp-sql-dtu-dev-uks-001',
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

foreach ($name in $requiredAlertNames) {
    if (-not $parameters.Contains($name)) {
        throw "Mandatory monitoring alert is missing: $name"
    }
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
    'apiStagingSlotId: apps.outputs.apiStagingSlotId'
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

if (($alerts.Split("`n") | Where-Object { $_ -match 'actionGroupId' }).Count -lt 10) {
    throw 'Mandatory alerts are not consistently wired to the approved action group.'
}

Write-Output "Azure demo monitoring contract passed for $($requiredAlertNames.Count) mandatory alert resources."
