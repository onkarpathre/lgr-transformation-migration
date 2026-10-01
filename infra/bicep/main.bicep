targetScope = 'resourceGroup'

@allowed(['azdemo'])
param environmentName string
@allowed(['uksouth'])
param location string
@allowed(['Onkar.Pathre'])
param resourceGroupName string
@allowed(['lgrtm'])
param workloadName string
@minLength(3)
@maxLength(8)
param uniqueSuffix string
param owner string
param costCentre string
@description('Future ISO YYYY-MM-DD expiry date. Validated by the protected pipeline before deployment.')
param expiryDate string
@allowed(['S1'])
param appServiceSku string = 'S1'
@allowed([1])
param appServiceCapacity int = 1
@allowed(['NODE|24-lts'])
param webLinuxFxVersion string = 'NODE|24-lts'
@allowed(['DOTNETCORE|10.0'])
param apiLinuxFxVersion string = 'DOTNETCORE|10.0'
@allowed(['S0'])
param sqlSkuName string = 'S0'
@allowed([10737418240])
param sqlMaxSizeBytes int = 10737418240
@allowed([30])
param logRetentionDays int = 30
@minValue(1)
@maxValue(1)
param telemetryDailyCapGb int = 1
param entraTenantId string
param spaClientId string
param apiClientId string
param apiAudience string
param apiScope string
param sqlEntraAdminObjectId string
param sqlEntraAdminName string
@description('Credential-free object ID of the approved workload-identity-federated deployment principal.')
param deploymentPrincipalObjectId string
@description('Credential-free object ID of the separately governed private migration-agent identity.')
param migrationPrincipalObjectId string
param alertEmailAddress string
param integrationSubnetPrefix string
param privateEndpointSubnetPrefix string
param vnetAddressPrefix string

assert resourceGroupMatches = resourceGroup().name == resourceGroupName
assert apiAudienceMatches = apiAudience == 'api://${apiClientId}'
assert apiScopeMatches = apiScope == '${apiAudience}/lgr.access'

var prefix = '${workloadName}-${environmentName}'
var tags = {
  workload: 'LGR Transformation and Migration'
  environment: 'azure-demo'
  dataClassification: 'synthetic'
  owner: owner
  costCentre: costCentre
  expiryDate: expiryDate
  managedBy: 'Bicep'
  productBoundary: 'record-plan-evidence-only'
}

module network 'modules/network.bicep' = {
  name: 'network-${environmentName}'
  params: {
    location: location
    namePrefix: prefix
    vnetAddressPrefix: vnetAddressPrefix
    integrationSubnetPrefix: integrationSubnetPrefix
    privateEndpointSubnetPrefix: privateEndpointSubnetPrefix
    tags: tags
  }
}
module identities 'modules/identities.bicep' = {
  name: 'identities-${environmentName}'
  params: {
    location: location
    tags: tags
  }
}
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-${environmentName}'
  params: {
    location: location
    namePrefix: prefix
    logRetentionDays: logRetentionDays
    telemetryDailyCapGb: telemetryDailyCapGb
    alertEmailAddress: alertEmailAddress
    tags: tags
  }
}
module data 'modules/data.bicep' = {
  name: 'data-${environmentName}'
  params: {
    location: location
    uniqueSuffix: uniqueSuffix
    entraTenantId: entraTenantId
    sqlEntraAdminObjectId: sqlEntraAdminObjectId
    sqlEntraAdminName: sqlEntraAdminName
    sqlSkuName: sqlSkuName
    sqlMaxSizeBytes: sqlMaxSizeBytes
    logRetentionDays: logRetentionDays
    apiIdentityPrincipalIds: [
      identities.outputs.apiMainPrincipalId
      identities.outputs.apiStagingPrincipalId
    ]
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: tags
  }
}
module apps 'modules/appservice.bicep' = {
  name: 'apps-${environmentName}'
  params: {
    location: location
    uniqueSuffix: uniqueSuffix
    appServiceSku: appServiceSku
    appServiceCapacity: appServiceCapacity
    webLinuxFxVersion: webLinuxFxVersion
    apiLinuxFxVersion: apiLinuxFxVersion
    integrationSubnetId: network.outputs.integrationSubnetId
    apiMainIdentityId: identities.outputs.apiMainIdentityId
    apiMainIdentityClientId: identities.outputs.apiMainClientId
    apiStagingIdentityId: identities.outputs.apiStagingIdentityId
    apiStagingIdentityClientId: identities.outputs.apiStagingClientId
    entraTenantId: entraTenantId
    spaClientId: spaClientId
    apiAudience: apiAudience
    apiScope: apiScope
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    sqlServerFqdn: data.outputs.sqlServerFqdn
    sqlDatabaseName: data.outputs.sqlDatabaseName
    keyVaultUri: data.outputs.keyVaultUri
    storageAccountUri: data.outputs.storageAccountUri
    tags: tags
  }
}
module privateEndpoints 'modules/private-endpoints.bicep' = {
  name: 'private-endpoints-${environmentName}'
  params: {
    location: location
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    privateDnsZoneIds: network.outputs.privateDnsZoneIds
    apiSiteId: apps.outputs.apiSiteId
    sqlServerId: data.outputs.sqlServerId
    keyVaultId: data.outputs.keyVaultId
    storageAccountId: data.outputs.storageAccountId
    tags: tags
  }
}
module alerts 'modules/alerts.bicep' = {
  name: 'alerts-${environmentName}'
  params: {
    location: location
    resourceGroupName: resourceGroupName
    actionGroupId: monitoring.outputs.actionGroupId
    applicationInsightsResourceId: monitoring.outputs.applicationInsightsResourceId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    telemetryDailyCapGb: telemetryDailyCapGb
    webHostname: apps.outputs.webHostname
    webSiteId: apps.outputs.webSiteId
    apiSiteId: apps.outputs.apiSiteId
    webStagingSlotId: apps.outputs.webStagingSlotId
    apiStagingSlotId: apps.outputs.apiStagingSlotId
    sqlDatabaseId: data.outputs.sqlDatabaseId
    malwareScanResultsDiagnosticId: data.outputs.storageMalwareScanResultsDiagnosticId
    tags: tags
  }
}

output webAppName string = apps.outputs.webAppName
output apiAppName string = apps.outputs.apiAppName
output webHostname string = apps.outputs.webHostname
output webSlotHostname string = apps.outputs.webSlotHostname
output apiHostname string = apps.outputs.apiHostname
output apiSlotHostname string = apps.outputs.apiSlotHostname
output apiMainIdentityPrincipalId string = identities.outputs.apiMainPrincipalId
output apiMainIdentityClientId string = identities.outputs.apiMainClientId
output apiStagingIdentityPrincipalId string = identities.outputs.apiStagingPrincipalId
output apiStagingIdentityClientId string = identities.outputs.apiStagingClientId
output sqlServerFqdn string = data.outputs.sqlServerFqdn
output sqlDatabaseName string = data.outputs.sqlDatabaseName
output keyVaultUri string = data.outputs.keyVaultUri
output storageAccountUri string = data.outputs.storageAccountUri
output applicationInsightsResourceId string = monitoring.outputs.applicationInsightsResourceId
output deploymentPrincipalPlaceholder string = deploymentPrincipalObjectId
output migrationPrincipalPlaceholder string = migrationPrincipalObjectId
