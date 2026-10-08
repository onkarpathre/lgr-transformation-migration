targetScope = 'resourceGroup'

@allowed(['azdemo'])
param environmentName string
@allowed(['uksouth'])
param location string
@allowed(['Onkar.Pathre'])
param resourceGroupName string
@description('Exact physical Azure resource names. Required MTP resources are validated below and referenced as existing resources by their modules.')
param resourceNames object
param owner string
param costCentre string
@description('Future ISO YYYY-MM-DD expiry date. Validated by the protected pipeline before deployment.')
param expiryDate string
@allowed(['NODE|24-lts'])
param webLinuxFxVersion string = 'NODE|24-lts'
@allowed(['DOTNETCORE|10.0'])
param apiLinuxFxVersion string = 'DOTNETCORE|10.0'
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

assert resourceGroupMatches = resourceGroup().name == resourceGroupName
assert environmentNameMatches = environmentName == 'azdemo'
assert apiAudienceMatches = apiAudience == 'api://${apiClientId}'
assert apiScopeMatches = apiScope == '${apiAudience}/lgr.access'
assert exactResourceNames = resourceNames.resourceGroup == 'Onkar.Pathre' && resourceNames.appServicePlan == 'asp-mtp-dev-uks-001' && resourceNames.webApp == 'app-mtp-web-dev-uks-001' && resourceNames.apiApp == 'app-mtp-api-dev-uks-001' && resourceNames.sqlServer == 'sql-mtp-dev-uks-001' && resourceNames.sqlDatabase == 'sqldb-mtp-dev-uks-001' && resourceNames.keyVault == 'kv-mtp-dev-uks-op01' && resourceNames.applicationInsights == 'appi-mtp-dev-uks-001' && resourceNames.logAnalytics == 'log-mtp-dev-uks-001' && resourceNames.storageAccount == 'stmtpdevuks001' && resourceNames.virtualNetwork == 'vnet-mtp-dev-uks-001' && resourceNames.integrationSubnet == 'snet-appservice' && resourceNames.privateEndpointSubnet == 'snet-private-endpoints' && resourceNames.sqlPrivateEndpoint == 'pep-sql-mtp-dev-uks-001' && resourceNames.sqlPrivateDnsZone == 'privatelink${environment().suffixes.sqlServerHostname}' && resourceNames.sqlPrivateDnsVirtualNetworkLink == 'link-mtp-dev-vnet'

var tags = {
  workload: 'MTP - Transformation & Migration Platform'
  environment: 'azure-demo'
  dataClassification: 'synthetic'
  owner: owner
  costCentre: costCentre
  expiryDate: expiryDate
  managedBy: 'Bicep'
  productBoundary: 'record-plan-evidence-only'
}

module network 'modules/network.bicep' = {
  name: resourceNames.networkDeployment
  params: {
    virtualNetworkName: resourceNames.virtualNetwork
    integrationSubnetName: resourceNames.integrationSubnet
    privateEndpointSubnetName: resourceNames.privateEndpointSubnet
    privateDnsZoneNames: {
      appService: resourceNames.appServicePrivateDnsZone
      sql: resourceNames.sqlPrivateDnsZone
      keyVault: resourceNames.keyVaultPrivateDnsZone
      blob: resourceNames.blobPrivateDnsZone
    }
    virtualNetworkLinkNames: {
      appService: resourceNames.privateDnsVirtualNetworkLink
      sql: resourceNames.sqlPrivateDnsVirtualNetworkLink
      keyVault: resourceNames.privateDnsVirtualNetworkLink
      blob: resourceNames.privateDnsVirtualNetworkLink
    }
    tags: tags
  }
}
module identities 'modules/identities.bicep' = {
  name: resourceNames.identitiesDeployment
  params: {
    location: location
    apiMainIdentityName: resourceNames.apiMainIdentity
    apiStagingIdentityName: resourceNames.apiStagingIdentity
    tags: tags
  }
}
module monitoring 'modules/monitoring.bicep' = {
  name: resourceNames.monitoringDeployment
  params: {
    applicationInsightsName: resourceNames.applicationInsights
    logAnalyticsWorkspaceName: resourceNames.logAnalytics
    actionGroupName: resourceNames.actionGroup
    alertEmailAddress: alertEmailAddress
    tags: tags
  }
}
module data 'modules/data.bicep' = {
  name: resourceNames.dataDeployment
  params: {
    entraTenantId: entraTenantId
    sqlEntraAdminObjectId: sqlEntraAdminObjectId
    sqlEntraAdminName: sqlEntraAdminName
    keyVaultName: resourceNames.keyVault
    storageAccountName: resourceNames.storageAccount
    sqlServerName: resourceNames.sqlServer
    sqlDatabaseName: resourceNames.sqlDatabase
    importContainerName: resourceNames.importContainer
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
  name: resourceNames.appsDeployment
  params: {
    location: location
    appServicePlanName: resourceNames.appServicePlan
    webAppName: resourceNames.webApp
    apiAppName: resourceNames.apiApp
    stagingSlotName: resourceNames.stagingSlot
    webLinuxFxVersion: webLinuxFxVersion
    apiLinuxFxVersion: apiLinuxFxVersion
    integrationSubnetId: network.outputs.integrationSubnetId
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
  name: resourceNames.privateEndpointsDeployment
  params: {
    location: location
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    privateDnsZoneIds: network.outputs.privateDnsZoneIds
    privateEndpointNames: {
      apiMain: resourceNames.apiPrivateEndpoint
      apiStaging: resourceNames.apiStagingPrivateEndpoint
      sql: resourceNames.sqlPrivateEndpoint
      keyVault: resourceNames.keyVaultPrivateEndpoint
      blob: resourceNames.blobPrivateEndpoint
    }
    apiSiteId: apps.outputs.apiSiteId
    keyVaultId: data.outputs.keyVaultId
    storageAccountId: data.outputs.storageAccountId
    tags: tags
  }
}
module alerts 'modules/alerts.bicep' = {
  name: resourceNames.alertsDeployment
  params: {
    location: location
    resourceGroupName: resourceGroupName
    alertNames: resourceNames.alerts
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
output apiMainIdentityName string = identities.outputs.apiMainIdentityName
output apiMainIdentityPrincipalId string = identities.outputs.apiMainPrincipalId
output apiMainIdentityClientId string = identities.outputs.apiMainClientId
output apiStagingIdentityName string = identities.outputs.apiStagingIdentityName
output apiStagingIdentityPrincipalId string = identities.outputs.apiStagingPrincipalId
output apiStagingIdentityClientId string = identities.outputs.apiStagingClientId
output sqlServerName string = resourceNames.sqlServer
output sqlServerFqdn string = data.outputs.sqlServerFqdn
output sqlDatabaseName string = data.outputs.sqlDatabaseName
output keyVaultUri string = data.outputs.keyVaultUri
output storageAccountUri string = data.outputs.storageAccountUri
output applicationInsightsResourceId string = monitoring.outputs.applicationInsightsResourceId
output deploymentPrincipalPlaceholder string = deploymentPrincipalObjectId
output migrationPrincipalPlaceholder string = migrationPrincipalObjectId
