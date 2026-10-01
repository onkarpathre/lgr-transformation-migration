param virtualNetworkName string
param integrationSubnetName string
param privateEndpointSubnetName string
param privateDnsZoneNames object
param virtualNetworkLinkName string
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetworkName
}
resource integrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: integrationSubnetName
}
resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: privateEndpointSubnetName
}
var zoneNames = [
  privateDnsZoneNames.appService
  privateDnsZoneNames.sql
  privateDnsZoneNames.keyVault
  privateDnsZoneNames.blob
]
resource zones 'Microsoft.Network/privateDnsZones@2024-06-01' existing = [
  for zoneName in zoneNames: {
    name: zoneName
  }
]
resource links 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [
  for (zoneName, index) in zoneNames: {
    parent: zones[index]
    name: virtualNetworkLinkName
    location: 'global'
    tags: tags
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
]
output integrationSubnetId string = integrationSubnet.id
output privateEndpointSubnetId string = privateEndpointSubnet.id
output privateDnsZoneIds object = {
  appService: zones[0].id
  sql: zones[1].id
  keyVault: zones[2].id
  blob: zones[3].id
}
