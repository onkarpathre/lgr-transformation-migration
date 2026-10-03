using '../main.bicep'

param environmentName = 'azdemo'
param location = 'uksouth'
param resourceGroupName = 'Onkar.Pathre'
param resourceNames = {
  resourceGroup: 'Onkar.Pathre'
  appServicePlan: 'asp-mtp-dev-uks-001'
  webApp: 'app-mtp-web-dev-uks-001'
  apiApp: 'app-mtp-api-dev-uks-001'
  sqlServer: 'sql-mtp-dev-uks-001'
  sqlDatabase: 'sqldb-mtp-dev-uks-001'
  keyVault: 'kv-mtp-dev-uks-op01'
  applicationInsights: 'appi-mtp-dev-uks-001'
  logAnalytics: 'log-mtp-dev-uks-001'
  storageAccount: 'stmtpdevuks001'
  virtualNetwork: 'vnet-mtp-dev-uks-001'
  sqlPrivateEndpoint: 'pep-sql-mtp-dev-uks-001'
  sqlPrivateDnsZone: 'privatelink.database.windows.net'
  apiMainIdentity: 'id-mtp-api-dev-uks-001'
  apiStagingIdentity: 'id-mtp-api-staging-dev-uks-001'
  actionGroup: 'ag-mtp-dev-uks-001'
  integrationSubnet: 'snet-appsvc-integration'
  privateEndpointSubnet: 'snet-private-endpoints'
  appServicePrivateDnsZone: 'privatelink.azurewebsites.net'
  keyVaultPrivateDnsZone: 'privatelink.vaultcore.azure.net'
  blobPrivateDnsZone: 'privatelink.blob.core.windows.net'
  privateDnsVirtualNetworkLink: 'link-mtp-dev-uks-001'
  sqlPrivateDnsVirtualNetworkLink: 'link-mtp-dev-vnet'
  apiPrivateEndpoint: 'pep-api-mtp-dev-uks-001'
  apiStagingPrivateEndpoint: 'pep-api-staging-mtp-dev-uks-001'
  keyVaultPrivateEndpoint: 'pep-kv-mtp-dev-uks-001'
  blobPrivateEndpoint: 'pep-blob-mtp-dev-uks-001'
  importContainer: 'discovery-imports'
  stagingSlot: 'staging'
  networkDeployment: 'network-mtp-dev-uks-001'
  identitiesDeployment: 'identities-mtp-dev-uks-001'
  monitoringDeployment: 'monitoring-mtp-dev-uks-001'
  dataDeployment: 'data-mtp-dev-uks-001'
  appsDeployment: 'apps-mtp-dev-uks-001'
  privateEndpointsDeployment: 'private-endpoints-mtp-dev-uks-001'
  alertsDeployment: 'alerts-mtp-dev-uks-001'
  alerts: {
    webHealthTest: 'webtest-mtp-web-health-dev-uks-001'
    apiReadinessTest: 'webtest-mtp-api-readiness-dev-uks-001'
    webHealth: 'alert-mtp-web-health-dev-uks-001'
    apiReadiness: 'alert-mtp-api-readiness-dev-uks-001'
    webHttp5xx: 'alert-mtp-web-http5xx-dev-uks-001'
    apiHttp5xx: 'alert-mtp-api-http5xx-dev-uks-001'
    unhandledErrors: 'alert-mtp-unhandled-errors-dev-uks-001'
    authFailuresDenials: 'alert-mtp-auth-failures-denials-dev-uks-001'
    sqlDtu: 'alert-mtp-sql-dtu-dev-uks-001'
    sqlConnectivity: 'alert-mtp-sql-connectivity-dev-uks-001'
    keyVaultDenial: 'alert-mtp-keyvault-denial-dev-uks-001'
    blobDependency: 'alert-mtp-blob-dependency-dev-uks-001'
    importFailure: 'alert-mtp-import-failure-dev-uks-001'
    storageMalware: 'alert-mtp-storage-malware-dev-uks-001'
    failedDeployment: 'alert-mtp-failed-deployment-dev-uks-001'
    webSlotHealth: 'alert-mtp-web-slot-health-dev-uks-001'
    apiSlotHealth: 'alert-mtp-api-slot-health-dev-uks-001'
    logDailyCap: 'alert-mtp-log-daily-cap-dev-uks-001'
    serviceHealth: 'alert-mtp-service-health-dev-uks-001'
  }
}
param owner = readEnvironmentVariable('AZDEMO_OWNER')
param costCentre = readEnvironmentVariable('AZDEMO_COST_CENTRE')
param expiryDate = readEnvironmentVariable('AZDEMO_EXPIRY_DATE')
param entraTenantId = readEnvironmentVariable('AZDEMO_ENTRA_TENANT_ID')
param spaClientId = readEnvironmentVariable('AZDEMO_SPA_CLIENT_ID')
param apiClientId = readEnvironmentVariable('AZDEMO_API_CLIENT_ID')
param apiAudience = 'api://${readEnvironmentVariable('AZDEMO_API_CLIENT_ID')}'
param apiScope = 'api://${readEnvironmentVariable('AZDEMO_API_CLIENT_ID')}/lgr.access'
param sqlEntraAdminObjectId = readEnvironmentVariable('AZDEMO_SQL_ADMIN_OBJECT_ID')
param sqlEntraAdminName = readEnvironmentVariable('AZDEMO_SQL_ADMIN_NAME')
param deploymentPrincipalObjectId = readEnvironmentVariable('AZDEMO_DEPLOYMENT_PRINCIPAL_OBJECT_ID')
param migrationPrincipalObjectId = readEnvironmentVariable('AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID')
param alertEmailAddress = readEnvironmentVariable('AZDEMO_ALERT_EMAIL')
