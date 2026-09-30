param location string
param tags object
resource apiMain 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-lgrtm-api-azdemo'
  location: location
  tags: tags
}
resource apiStaging 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-lgrtm-api-staging-azdemo'
  location: location
  tags: tags
}
output apiMainIdentityId string = apiMain.id
output apiMainPrincipalId string = apiMain.properties.principalId
output apiMainClientId string = apiMain.properties.clientId
output apiStagingIdentityId string = apiStaging.id
output apiStagingPrincipalId string = apiStaging.properties.principalId
output apiStagingClientId string = apiStaging.properties.clientId
