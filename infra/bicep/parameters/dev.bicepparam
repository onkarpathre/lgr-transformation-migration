// Compatibility entry point retained for existing developer workflows.
// The approved main template is now AzureDemo-only, so this file deliberately
// consumes the same non-secret environment inputs as azure-demo.bicepparam.
using '../main.bicep'

param environmentName = 'azdemo'
param location = 'uksouth'
param resourceGroupName = 'Onkar.Pathre'
param workloadName = 'lgrtm'
param uniqueSuffix = readEnvironmentVariable('AZDEMO_UNIQUE_SUFFIX')
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
param vnetAddressPrefix = readEnvironmentVariable('AZDEMO_VNET_PREFIX')
param integrationSubnetPrefix = readEnvironmentVariable('AZDEMO_INTEGRATION_SUBNET_PREFIX')
param privateEndpointSubnetPrefix = readEnvironmentVariable('AZDEMO_PRIVATE_ENDPOINT_SUBNET_PREFIX')
