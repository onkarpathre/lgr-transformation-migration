targetScope = 'resourceGroup'

@description('Short environment code such as dev, test or prod.')
param environmentName string = 'dev'

@description('Azure region approved for the programme.')
param location string = resourceGroup().location

@description('Stable product prefix used in resource names.')
param workloadName string = 'lgrtm'

@description('Phase 1 creates the observability foundation only. Enable explicitly for a future sandbox deployment.')
param deployMonitoring bool = false

var tags = {
  workload: 'LGR Transformation and Migration'
  environment: environmentName
  managedBy: 'Bicep'
  phase: 'POC'
}

module monitoring 'modules/monitoring.bicep' = if (deployMonitoring) {
  name: 'monitoring-${environmentName}'
  params: {
    location: location
    namePrefix: '${workloadName}-${environmentName}'
    tags: tags
  }
}

output monitoringEnabled bool = deployMonitoring
output logAnalyticsWorkspaceId string = deployMonitoring ? monitoring.outputs.logAnalyticsWorkspaceId : ''
output applicationInsightsConnectionString string = deployMonitoring ? monitoring.outputs.applicationInsightsConnectionString : ''
