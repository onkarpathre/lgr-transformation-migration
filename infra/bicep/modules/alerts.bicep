param location string
param actionGroupId string
param webSiteId string
param apiSiteId string
param sqlDatabaseId string
param tags object
resource webAvailability 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-lgrtm-web-http5xx-azdemo'
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
        { name: 'Http5xx'
          metricName: 'Http5xx'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion' }
      ]
    }
    actions: [{ actionGroupId: actionGroupId }]
  }
}
resource apiAvailability 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-lgrtm-api-http5xx-azdemo'
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
        { name: 'Http5xx'
          metricName: 'Http5xx'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion' }
      ]
    }
    actions: [{ actionGroupId: actionGroupId }]
  }
}
resource sqlSaturation 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-lgrtm-sql-dtu-azdemo'
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
        { name: 'Dtu'
          metricName: 'dtu_consumption_percent'
          metricNamespace: 'Microsoft.Sql/servers/databases'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion' }
      ]
    }
    actions: [{ actionGroupId: actionGroupId }]
  }
}
