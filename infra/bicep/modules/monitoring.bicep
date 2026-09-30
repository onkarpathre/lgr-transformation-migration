param location string
param namePrefix string
param logRetentionDays int
param telemetryDailyCapGb int
param alertEmailAddress string
param tags object
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${namePrefix}-uks-01'
  location: location
  tags: tags
  properties: {
    retentionInDays: logRetentionDays
    features: { enableLogAccessUsingOnlyResourcePermissions: true }
    workspaceCapping: { dailyQuotaGb: telemetryDailyCapGb }
  }
  sku: { name: 'PerGB2018' }
}
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${namePrefix}-uks-01'
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    RetentionInDays: logRetentionDays
  }
}
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${namePrefix}-operations'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'lgrdemo'
    enabled: true
    emailReceivers: [
      {
        name: 'approved-operations-owner'
        emailAddress: alertEmailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}
output logAnalyticsWorkspaceId string = logAnalytics.id
output applicationInsightsResourceId string = applicationInsights.id
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
output actionGroupId string = actionGroup.id
