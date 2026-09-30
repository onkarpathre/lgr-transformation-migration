param location string
param privateEndpointSubnetId string
param privateDnsZoneIds object
param apiSiteId string
param sqlServerId string
param keyVaultId string
param storageAccountId string
param tags object

var targets = [
  { name: 'api-main'
    id: apiSiteId
    groupId: 'sites'
    zoneId: privateDnsZoneIds.appService }
  { name: 'api-staging'
    id: apiSiteId
    groupId: 'sites-staging'
    zoneId: privateDnsZoneIds.appService }
  { name: 'sql'
    id: sqlServerId
    groupId: 'sqlServer'
    zoneId: privateDnsZoneIds.sql }
  { name: 'keyvault'
    id: keyVaultId
    groupId: 'vault'
    zoneId: privateDnsZoneIds.keyVault }
  { name: 'blob'
    id: storageAccountId
    groupId: 'blob'
    zoneId: privateDnsZoneIds.blob }
]
resource endpoints 'Microsoft.Network/privateEndpoints@2024-05-01' = [for target in targets: {
  name: 'pep-lgrtm-${target.name}-azdemo'
  location: location
  tags: tags
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [
      {
        name: '${target.name}-connection'
        properties: {
          privateLinkServiceId: target.id
          groupIds: [target.groupId]
          requestMessage: 'Approved restricted synthetic Azure demo private connection.'
        }
      }
    ]
  }
}]
resource zoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = [for (target, index) in targets: {
  parent: endpoints[index]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'zone'
        properties: { privateDnsZoneId: target.zoneId }
      }
    ]
  }
}]
output privateEndpointIds array = [for endpoint in endpoints: endpoint.id]
