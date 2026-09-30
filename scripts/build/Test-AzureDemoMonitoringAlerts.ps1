[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$alerts = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\alerts.bicep') -Raw
$main = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\main.bicep') -Raw
$apps = Get-Content -LiteralPath (Join-Path $repo 'infra\bicep\modules\appservice.bicep') -Raw

$requiredAlertNames = @(
    'alert-lgrtm-web-health-azdemo',
    'alert-lgrtm-api-readiness-azdemo',
    'alert-lgrtm-web-http5xx-azdemo',
    'alert-lgrtm-api-http5xx-azdemo',
    'alert-lgrtm-unhandled-errors-azdemo',
    'alert-lgrtm-auth-failures-denials-azdemo',
    'alert-lgrtm-sql-dtu-azdemo',
    'alert-lgrtm-sql-connectivity-azdemo',
    'alert-lgrtm-keyvault-denial-azdemo',
    'alert-lgrtm-blob-dependency-azdemo',
    'alert-lgrtm-import-failure-azdemo',
    'alert-lgrtm-storage-malware-azdemo',
    'alert-lgrtm-failed-deployment-azdemo',
    'alert-lgrtm-web-slot-health-azdemo',
    'alert-lgrtm-api-slot-health-azdemo',
    'alert-lgrtm-log-daily-cap-azdemo',
    'alert-lgrtm-service-health-azdemo'
)

foreach ($name in $requiredAlertNames) {
    if (-not $alerts.Contains($name)) {
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
    ".vault.azure.net",
    '.blob.core.windows.net',
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

if (($alerts.Split("`n") | Where-Object { $_ -match 'actionGroupId' }).Count -lt 10) {
    throw 'Mandatory alerts are not consistently wired to the approved action group.'
}

Write-Output "Azure demo monitoring contract passed for $($requiredAlertNames.Count) mandatory alert resources."
