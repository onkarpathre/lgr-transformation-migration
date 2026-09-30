param location string
param uniqueSuffix string
param appServiceSku string
param appServiceCapacity int
param webLinuxFxVersion string
param apiLinuxFxVersion string
param integrationSubnetId string
param apiMainIdentityId string
param apiMainIdentityClientId string
param apiStagingIdentityId string
param apiStagingIdentityClientId string
param entraTenantId string
param spaClientId string
param apiAudience string
param apiScope string
param applicationInsightsConnectionString string
param logAnalyticsWorkspaceId string
param sqlServerFqdn string
param sqlDatabaseName string
param keyVaultUri string
param storageAccountUri string
param tags object

var webName = 'app-lgrtm-web-azdemo-uks-${uniqueSuffix}'
var apiName = 'app-lgrtm-api-azdemo-uks-${uniqueSuffix}'
var membershipSecretUri = '${trim(keyVaultUri, '/')}/secrets/entra-demo-memberships'
var sqlBase = 'Server=tcp:${sqlServerFqdn},1433;Database=${sqlDatabaseName};Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;Connect Timeout=30;MultipleActiveResultSets=False;User Id='
var commonSiteConfig = {
  alwaysOn: true
  ftpsState: 'Disabled'
  http20Enabled: true
  minTlsVersion: '1.2'
  scmMinTlsVersion: '1.2'
  remoteDebuggingEnabled: false
}
var commonWebSettings = [
  { name: 'NODE_ENV'
    value: 'production' }
  { name: 'HOSTNAME'
    value: '0.0.0.0' }
  { name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
    value: 'false' }
  { name: 'WEBSITE_HEALTHCHECK_MAXPINGFAILURES'
    value: '3' }
  { name: 'WEBSITE_SWAP_WARMUP_PING_PATH'
    value: '/health' }
  { name: 'WEBSITE_SWAP_WARMUP_PING_STATUSES'
    value: '200' }
  { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: applicationInsightsConnectionString }
  { name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~3' }
  { name: 'NEXT_PUBLIC_ENTRA_TENANT_ID'
    value: entraTenantId }
  { name: 'NEXT_PUBLIC_ENTRA_CLIENT_ID'
    value: spaClientId }
  { name: 'NEXT_PUBLIC_API_SCOPE'
    value: apiScope }
  { name: 'NEXT_PUBLIC_DEMO_LABEL'
    value: 'Restricted synthetic non-production demo' }
]
var apiCommon = [
  { name: 'ASPNETCORE_ENVIRONMENT'
    value: 'AzureDemo' }
  { name: 'ASPNETCORE_FORWARDEDHEADERS_ENABLED'
    value: 'true' }
  { name: 'Authentication__Mode'
    value: 'Entra' }
  { name: 'Authentication__Entra__TenantId'
    value: entraTenantId }
  { name: 'Authentication__Entra__Issuer'
    value: 'https://login.microsoftonline.com/${entraTenantId}/v2.0' }
  { name: 'Authentication__Entra__Audience'
    value: apiAudience }
  { name: 'Authentication__Entra__AllowedClientIds__0'
    value: spaClientId }
  { name: 'Authentication__EntraDemoMemberships__SecretUri'
    value: membershipSecretUri }
  { name: 'Authentication__EntraDemoMemberships__CacheSeconds'
    value: '300' }
  { name: 'Features__SqlDiscoveryAssessment'
    value: 'true' }
  { name: 'Features__SqlDiscoveryImport'
    value: 'true' }
  { name: 'Features__SqlAssessment'
    value: 'true' }
  { name: 'Features__SqlBrowserJourneys'
    value: 'true' }
  { name: 'Features__DependencyRegister'
    value: 'true' }
  { name: 'DiscoveryImport__MaximumFileSizeBytes'
    value: '26214400' }
  { name: 'DiscoveryImport__StorageMode'
    value: 'AzureBlob' }
  { name: 'DiscoveryImport__StorageAccountUri'
    value: storageAccountUri }
  { name: 'DiscoveryImport__ContainerName'
    value: 'discovery-imports' }
  { name: 'DiscoveryImport__FreshnessThresholdDays'
    value: '30' }
  { name: 'DemoData__Enabled'
    value: 'false' }
  { name: 'DemoData__ManifestVersion'
    value: 'azdemo-v1' }
  { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: applicationInsightsConnectionString }
  { name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~3' }
  { name: 'Logging__LogLevel__Default'
    value: 'Information' }
  { name: 'Logging__LogLevel__Microsoft.AspNetCore'
    value: 'Warning' }
  { name: 'WEBSITE_SWAP_WARMUP_PING_PATH'
    value: '/health/ready' }
  { name: 'WEBSITE_SWAP_WARMUP_PING_STATUSES'
    value: '200' }
  { name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
    value: 'false' }
]

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'asp-lgrtm-azdemo-uks-01'
  location: location
  tags: tags
  sku: {
    name: appServiceSku
    tier: 'Standard'
    capacity: appServiceCapacity
  }
  kind: 'linux'
  properties: {
    reserved: true
    perSiteScaling: false
    zoneRedundant: false
  }
}
resource web 'Microsoft.Web/sites@2023-12-01' = {
  name: webName
  location: location
  tags: tags
  kind: 'app,linux'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    virtualNetworkSubnetId: integrationSubnetId
    vnetRouteAllEnabled: true
    siteConfig: union(commonSiteConfig, {
      linuxFxVersion: webLinuxFxVersion
      appCommandLine: 'node server.js'
      healthCheckPath: '/health'
      appSettings: concat(commonWebSettings, [
        { name: 'API_ORIGIN'
          value: 'https://${apiName}.azurewebsites.net' }
        { name: 'OTEL_SERVICE_NAME'
          value: 'lgrtm-web-azdemo' }
      ])
    })
  }
}
resource webSlot 'Microsoft.Web/sites/slots@2023-12-01' = {
  parent: web
  name: 'staging'
  location: location
  tags: tags
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    virtualNetworkSubnetId: integrationSubnetId
    vnetRouteAllEnabled: true
    siteConfig: union(commonSiteConfig, {
      linuxFxVersion: webLinuxFxVersion
      appCommandLine: 'node server.js'
      healthCheckPath: '/health'
      appSettings: concat(commonWebSettings, [
        { name: 'API_ORIGIN'
          value: 'https://${apiName}-staging.azurewebsites.net' }
        { name: 'OTEL_SERVICE_NAME'
          value: 'lgrtm-web-staging-azdemo' }
      ])
    })
  }
}
resource api 'Microsoft.Web/sites@2023-12-01' = {
  name: apiName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${apiMainIdentityId}': {} }
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
    virtualNetworkSubnetId: integrationSubnetId
    vnetRouteAllEnabled: true
    siteConfig: union(commonSiteConfig, {
      linuxFxVersion: apiLinuxFxVersion
      healthCheckPath: '/health/ready'
      appSettings: concat(apiCommon, [
        { name: 'AllowedHosts'
          value: '${apiName}.azurewebsites.net' }
        { name: 'AllowedOrigins__0'
          value: 'https://${webName}.azurewebsites.net' }
        { name: 'AzureIdentity__ManagedIdentityClientId'
          value: apiMainIdentityClientId }
        { name: 'ConnectionStrings__LgrDatabase'
          value: '${sqlBase}${apiMainIdentityClientId}' }
        { name: 'OTEL_SERVICE_NAME'
          value: 'lgrtm-api-azdemo' }
      ])
    })
  }
}
resource apiSlot 'Microsoft.Web/sites/slots@2023-12-01' = {
  parent: api
  name: 'staging'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${apiStagingIdentityId}': {} }
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
    virtualNetworkSubnetId: integrationSubnetId
    vnetRouteAllEnabled: true
    siteConfig: union(commonSiteConfig, {
      linuxFxVersion: apiLinuxFxVersion
      healthCheckPath: '/health/ready'
      appSettings: concat(apiCommon, [
        { name: 'AllowedHosts'
          value: '${apiName}-staging.azurewebsites.net' }
        { name: 'AllowedOrigins__0'
          value: 'https://${webName}-staging.azurewebsites.net' }
        { name: 'AzureIdentity__ManagedIdentityClientId'
          value: apiStagingIdentityClientId }
        { name: 'ConnectionStrings__LgrDatabase'
          value: '${sqlBase}${apiStagingIdentityClientId}' }
        { name: 'OTEL_SERVICE_NAME'
          value: 'lgrtm-api-staging-azdemo' }
      ])
    })
  }
}
resource webSlots 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: web
  name: 'slotConfigNames'
  properties: {
    appSettingNames: [
      'API_ORIGIN'
      'OTEL_SERVICE_NAME'
      'WEBSITE_SWAP_WARMUP_PING_PATH'
    ]
  }
}
resource apiSlots 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: api
  name: 'slotConfigNames'
  properties: {
    appSettingNames: [
      'AllowedHosts'
      'AllowedOrigins__0'
      'AzureIdentity__ManagedIdentityClientId'
      'ConnectionStrings__LgrDatabase'
      'OTEL_SERVICE_NAME'
      'Authentication__EntraDemoMemberships__SecretUri'
    ]
  }
}
resource webFtp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: web
  name: 'ftp'
  properties: { allow: false }
}
resource webScm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: web
  name: 'scm'
  properties: { allow: false }
}
resource apiFtp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: api
  name: 'ftp'
  properties: { allow: false }
}
resource apiScm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: api
  name: 'scm'
  properties: { allow: false }
}
resource webSlotFtp 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: webSlot
  name: 'ftp'
  properties: { allow: false }
}
resource webSlotScm 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: webSlot
  name: 'scm'
  properties: { allow: false }
}
resource apiSlotFtp 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: apiSlot
  name: 'ftp'
  properties: { allow: false }
}
resource apiSlotScm 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: apiSlot
  name: 'scm'
  properties: { allow: false }
}
resource siteDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for site in [
  web
  api
]: {
  scope: site
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}]
resource slotDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for slot in [
  webSlot
  apiSlot
]: {
  scope: slot
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}]

output webSiteId string = web.id
output apiSiteId string = api.id
output apiStagingSlotId string = apiSlot.id
output webAppName string = web.name
output apiAppName string = api.name
output webHostname string = web.properties.defaultHostName
output webSlotHostname string = webSlot.properties.defaultHostName
output apiHostname string = api.properties.defaultHostName
output apiSlotHostname string = apiSlot.properties.defaultHostName
