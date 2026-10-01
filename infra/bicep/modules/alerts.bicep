param location string
param resourceGroupName string
param alertNames object
param actionGroupId string
param applicationInsightsResourceId string
param logAnalyticsWorkspaceId string
param telemetryDailyCapGb int
param webHostname string
param webSiteId string
param apiSiteId string
param webStagingSlotId string
param apiStagingSlotId string
param sqlDatabaseId string
param malwareScanResultsDiagnosticId string
param tags object

assert malwareScanResultsDiagnosticScope = endsWith(
  toLower(malwareScanResultsDiagnosticId),
  '/providers/microsoft.security/defenderforstoragesettings/current/providers/microsoft.insights/diagnosticsettings/service'
)

var availabilityTestLocations = [
  {
    Id: 'emea-gb-db3-azr'
  }
]

var logAlertDefinitions = [
  {
    name: alertNames.unhandledErrors
    displayName: 'Azure demo unhandled errors'
    description: 'Unhandled application exceptions were recorded by the restricted demo.'
    severity: 1
    query: '''
AppExceptions
| where TimeGenerated >= ago(10m)
| where SeverityLevel >= 3
'''
  }
  {
    name: alertNames.authFailuresDenials
    displayName: 'Azure demo authentication failures and authorization denials'
    description: 'Repeated 401 or 403 responses were recorded by the restricted demo.'
    severity: 1
    query: '''
AppRequests
| where TimeGenerated >= ago(10m)
| where ResultCode in ('401', '403')
'''
  }
  {
    name: alertNames.sqlConnectivity
    displayName: 'Azure demo SQL dependency failure'
    description: 'The restricted demo recorded a failed Azure SQL dependency call.'
    severity: 1
    query: '''
AppDependencies
| where TimeGenerated >= ago(10m)
| where DependencyType has 'SQL'
| where Success == false
'''
  }
  {
    name: alertNames.keyVaultDenial
    displayName: 'Azure demo Key Vault dependency denial'
    description: 'The restricted demo recorded a failed or denied Key Vault dependency call.'
    severity: 1
    query: '''
AppDependencies
| where TimeGenerated >= ago(10m)
| where Target endswith '.vault.azure.net'
| where Success == false or ResultCode in ('401', '403')
'''
  }
  {
    name: alertNames.blobDependency
    displayName: 'Azure demo Blob dependency failure'
    description: 'The restricted demo recorded a failed Blob Storage dependency call.'
    severity: 1
    query: '''
AppDependencies
| where TimeGenerated >= ago(10m)
| where Target has '.blob.core.windows.net'
| where Success == false
'''
  }
  {
    name: alertNames.importFailure
    displayName: 'Azure demo discovery import failure'
    description: 'The restricted demo recorded a failed discovery import request.'
    severity: 1
    query: '''
AppRequests
| where TimeGenerated >= ago(10m)
| where Name has 'discovery-imports' or Url has '/discovery-imports'
| where Success == false
'''
  }
  {
    name: alertNames.storageMalware
    displayName: 'Azure demo storage malware or scan failure'
    description: 'Defender for Storage did not report a clean malware scan result for an uploaded demo file.'
    severity: 0
    query: '''
StorageMalwareScanningResults
| where TimeGenerated >= ago(10m)
| where ScanResultType in~ ('Malicious', 'Error', 'Not Scanned')
'''
  }
  {
    name: alertNames.logDailyCap
    displayName: 'Azure demo log daily cap approaching'
    description: 'Daily Log Analytics ingestion has reached 90 percent of the approved cap.'
    severity: 2
    query: '''
Usage
| where TimeGenerated >= startofday(now())
| summarize IngestionGb = sum(Quantity) / 1000.0
| where IngestionGb >= (${telemetryDailyCapGb} * 0.9)
'''
  }
]

resource webHealthTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: alertNames.webHealthTest
  location: location
  tags: union(tags, {
    'hidden-link:${applicationInsightsResourceId}': 'Resource'
  })
  kind: 'standard'
  properties: {
    SyntheticMonitorId: alertNames.webHealthTest
    Name: 'Azure demo web health'
    Description: 'Public web availability for the restricted demo.'
    Enabled: true
    Frequency: 300
    Timeout: 30
    Kind: 'standard'
    RetryEnabled: true
    Locations: availabilityTestLocations
    Request: {
      RequestUrl: 'https://${webHostname}/'
      HttpVerb: 'GET'
      ParseDependentRequests: false
      FollowRedirects: true
    }
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      IgnoreHttpStatusCode: false
      SSLCheck: true
      SSLCertRemainingLifetimeCheck: 7
    }
  }
}

resource apiReadinessTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: alertNames.apiReadinessTest
  location: location
  tags: union(tags, {
    'hidden-link:${applicationInsightsResourceId}': 'Resource'
  })
  kind: 'standard'
  properties: {
    SyntheticMonitorId: alertNames.apiReadinessTest
    Name: 'Azure demo API readiness through web'
    Description: 'The public web health route checks private API readiness and its bounded dependencies.'
    Enabled: true
    Frequency: 300
    Timeout: 30
    Kind: 'standard'
    RetryEnabled: true
    Locations: availabilityTestLocations
    Request: {
      RequestUrl: 'https://${webHostname}/health'
      HttpVerb: 'GET'
      ParseDependentRequests: false
      FollowRedirects: true
    }
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      IgnoreHttpStatusCode: false
      SSLCheck: true
      SSLCertRemainingLifetimeCheck: 7
    }
  }
}

resource webHealthAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertNames.webHealth
  location: 'global'
  tags: tags
  properties: {
    description: 'The restricted demo public web availability probe failed.'
    severity: 1
    enabled: true
    scopes: [
      webHealthTest.id
      applicationInsightsResourceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
      webTestId: webHealthTest.id
      componentId: applicationInsightsResourceId
      failedLocationCount: 1
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

resource apiReadinessAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertNames.apiReadiness
  location: 'global'
  tags: tags
  properties: {
    description: 'API readiness failed through the restricted demo public web probe.'
    severity: 1
    enabled: true
    scopes: [
      apiReadinessTest.id
      applicationInsightsResourceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
      webTestId: apiReadinessTest.id
      componentId: applicationInsightsResourceId
      failedLocationCount: 1
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

resource webHttpFailures 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertNames.webHttp5xx
  location: 'global'
  tags: tags
  properties: {
    description: 'Restricted demo web 5xx rate exceeds threshold.'
    severity: 2
    enabled: true
    scopes: [webSiteId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Http5xx'
          metricName: 'Http5xx'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [{ actionGroupId: actionGroupId }]
  }
}

resource apiHttpFailures 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertNames.apiHttp5xx
  location: 'global'
  tags: tags
  properties: {
    description: 'Restricted demo API 5xx rate exceeds threshold.'
    severity: 2
    enabled: true
    scopes: [apiSiteId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Http5xx'
          metricName: 'Http5xx'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [{ actionGroupId: actionGroupId }]
  }
}

resource sqlSaturation 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertNames.sqlDtu
  location: 'global'
  tags: tags
  properties: {
    description: 'Restricted demo SQL DTU usage exceeds threshold.'
    severity: 2
    enabled: true
    scopes: [sqlDatabaseId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Dtu'
          metricName: 'dtu_consumption_percent'
          metricNamespace: 'Microsoft.Sql/servers/databases'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [{ actionGroupId: actionGroupId }]
  }
}

resource webSlotHealth 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertNames.webSlotHealth
  location: 'global'
  tags: tags
  properties: {
    description: 'Restricted demo web staging slot health check is unhealthy.'
    severity: 1
    enabled: true
    scopes: [webStagingSlotId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'WebSlotHealth'
          metricName: 'HealthCheckStatus'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'LessThan'
          threshold: 1
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [{ actionGroupId: actionGroupId }]
  }
}

resource apiSlotHealth 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertNames.apiSlotHealth
  location: 'global'
  tags: tags
  properties: {
    description: 'Restricted demo API staging slot readiness check is unhealthy.'
    severity: 1
    enabled: true
    scopes: [apiStagingSlotId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ApiSlotHealth'
          metricName: 'HealthCheckStatus'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'LessThan'
          threshold: 1
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [{ actionGroupId: actionGroupId }]
  }
}

resource logAlerts 'Microsoft.Insights/scheduledQueryRules@2023-12-01' = [for alert in logAlertDefinitions: {
  name: alert.name
  location: location
  tags: tags
  properties: {
    displayName: alert.displayName
    description: alert.description
    severity: alert.severity
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [logAnalyticsWorkspaceId]
    windowSize: 'PT10M'
    criteria: {
      allOf: [
        {
          query: alert.query
          timeAggregation: 'Count'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [actionGroupId]
    }
    skipQueryValidation: true
  }
}]

resource failedDeployment 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: alertNames.failedDeployment
  location: 'global'
  tags: tags
  properties: {
    description: 'A resource-group deployment failed in the restricted Azure demo resource group.'
    enabled: true
    scopes: [resourceGroup().id]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'Administrative'
        }
        {
          field: 'resourceGroup'
          equals: resourceGroupName
        }
        {
          field: 'operationName'
          equals: 'Microsoft.Resources/deployments/write'
        }
        {
          field: 'status'
          equals: 'Failed'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroupId
          webhookProperties: {}
        }
      ]
    }
  }
}

resource serviceHealth 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: alertNames.serviceHealth
  location: 'global'
  tags: tags
  properties: {
    description: 'Azure service-health incident affecting UK South.'
    enabled: true
    scopes: [subscription().id]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ServiceHealth'
        }
        {
          field: 'properties.incidentType'
          equals: 'Incident'
        }
        {
          field: 'properties.impactedServices[*].ImpactedRegions[*].RegionName'
          containsAny: ['UK South']
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroupId
          webhookProperties: {}
        }
      ]
    }
  }
}
