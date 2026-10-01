param location string
param privateEndpointSubnetId string
param privateDnsZoneIds object
param privateEndpointNames object
param apiSiteId string
param keyVaultId string
param storageAccountId string
param tags object

var managedTargets = [
  {
    name: privateEndpointNames.apiMain
    id: apiSiteId
    groupId: 'sites'
    zoneId: privateDnsZoneIds.appService
  }
  {
    name: privateEndpointNames.apiStaging
    id: apiSiteId
    groupId: 'sites-staging'
    zoneId: privateDnsZoneIds.appService
  }
  {
    name: privateEndpointNames.keyVault
    id: keyVaultId
    groupId: 'vault'
    zoneId: privateDnsZoneIds.keyVault
  }
  {
    name: privateEndpointNames.blob
    id: storageAccountId
    groupId: 'blob'
    zoneId: privateDnsZoneIds.blob
  }
]
resource endpoints 'Microsoft.Network/privateEndpoints@2024-05-01' = [for target in managedTargets: {
  name: target.name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
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
resource sqlEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' existing = {
  name: privateEndpointNames.sql
}
resource zoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = [for (target, index) in managedTargets: {
  parent: endpoints[index]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'zone'
        properties: {
          privateDnsZoneId: target.zoneId
        }
      }
    ]
  }
}]
resource sqlZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: sqlEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'zone'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.sql
        }
      }
    ]
  }
}
output privateEndpointIds array = concat([for endpoint in endpoints: endpoint.id], [sqlEndpoint.id])
