param location string

param tiers array

param numberOfServers int

param subnetIds array

param externalLoadBalancerBackendAddressPoolId string

param internalLoadBalancerBackendAddressPoolId string

param privateDnsZoneId string

@secure()
param serverAdminLogin string

@secure()
param serverAdminLoginPassword string

resource webTierNics 'Microsoft.Network/networkInterfaces@2024-05-01' = [
  for i in range(0, numberOfServers): {
    name: 'nic-webtier-${i+1}'
    location: location
    properties: {
      ipConfigurations: [
        {
          name: 'nic-webtier-ipconfig-${i+1}'
          properties: {
            subnet: {
              id: subnetIds[0].subnetId
            }
            loadBalancerBackendAddressPools: [
              {
                id: externalLoadBalancerBackendAddressPoolId
              }
            ]
          }
        }
      ]
    }
  }
]

resource appTierNics 'Microsoft.Network/networkInterfaces@2024-05-01' = [
  for i in range(0, numberOfServers): {
    name: 'nic-apptier-${i+1}'
    location: location
    properties: {
      ipConfigurations: [
        {
          name: 'nic-apptier-ipconfig-${i+1}'
          properties: {
            subnet: {
              id: subnetIds[1].subnetId
            }
            loadBalancerBackendAddressPools: [
              {
                id: internalLoadBalancerBackendAddressPoolId
              }
            ]
          }
        }
      ]
    }
  }
]

resource webTierServers 'Microsoft.Compute/virtualMachines@2024-11-01' = [
  for i in range(0, numberOfServers): {
    name: 'vm-webtier-${i+1}'
    location: location
    properties: {
      hardwareProfile: {
        vmSize: 'Standard_B1s'
      }
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
        }
      }
      osProfile: {
        computerName: 'vm-webtier-${i+1}'
        adminUsername: serverAdminLogin
        adminPassword: serverAdminLoginPassword
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: webTierNics[i].id
          }
        ]
      }
    }
  }
]

resource appTierServers 'Microsoft.Compute/virtualMachines@2024-11-01' = [
  for i in range(0, numberOfServers): {
    name: 'vm-apptier-${i+1}'
    location: location
    properties: {
      hardwareProfile: {
        vmSize: 'Standard_B1s'
      }
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
        }
      }
      osProfile: {
        computerName: 'vm-apptier-${i+1}'
        adminUsername: serverAdminLogin
        adminPassword: serverAdminLoginPassword
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: appTierNics[i].id
          }
        ]
      }
    }
  }
]

resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2024-10-01-preview' = {
  name: 'mysqlserver${uniqueString(resourceGroup().name)}'
  location: 'Sweden Central'
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: serverAdminLogin
    administratorLoginPassword: serverAdminLoginPassword
    network: {
      delegatedSubnetResourceId: subnetIds[indexOf(tiers, 'datatier')].subnetId
      privateDnsZoneResourceId: privateDnsZoneId
      publicNetworkAccess: 'Disabled'
    }
    storage:{
      storageSizeGB:32
    }
  }
}

resource mysqlDatabase 'Microsoft.DBforMySQL/flexibleServers/databases@2023-12-30' = {
  parent:mysqlServer
  name:'mysqldatabase${uniqueString(location)}'
}
