param location string
param namePrefix string
param vnetAddressPrefix string
param integrationSubnetPrefix string
param privateEndpointSubnetPrefix string
param tags object
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${namePrefix}-uks-01'
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [vnetAddressPrefix] }
    subnets: [
      {
        name: 'snet-appsvc-integration'
        properties: {
          addressPrefix: integrationSubnetPrefix
          delegations: [
            {
              name: 'appservice'
              properties: { serviceName: 'Microsoft.Web/serverFarms' }
            }
          ]
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}
var zoneNames = [
  'privatelink.azurewebsites.net'
  'privatelink.database.windows.net'
  'privatelink.vaultcore.azure.net'
  'privatelink.blob.core.windows.net'
]
resource zones 'Microsoft.Network/privateDnsZones@2024-06-01' = [for zoneName in zoneNames: {
  name: zoneName
  location: 'global'
  tags: tags
}]
resource links 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [for (zoneName, index) in zoneNames: {
  parent: zones[index]
  name: 'link-${namePrefix}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: { id: vnet.id }
  }
}]
output integrationSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-appsvc-integration')
output privateEndpointSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-private-endpoints')
output privateDnsZoneIds object = {
  appService: zones[0].id
  sql: zones[1].id
  keyVault: zones[2].id
  blob: zones[3].id
}
