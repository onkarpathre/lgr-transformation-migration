param location string
param apiMainIdentityName string
param apiStagingIdentityName string
param tags object
resource apiMain 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: apiMainIdentityName
  location: location
  tags: tags
}
resource apiStaging 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: apiStagingIdentityName
  location: location
  tags: tags
}
output apiMainIdentityId string = apiMain.id
output apiMainIdentityName string = apiMain.name
output apiMainPrincipalId string = apiMain.properties.principalId
output apiMainClientId string = apiMain.properties.clientId
output apiStagingIdentityId string = apiStaging.id
output apiStagingIdentityName string = apiStaging.name
output apiStagingPrincipalId string = apiStaging.properties.principalId
output apiStagingClientId string = apiStaging.properties.clientId
