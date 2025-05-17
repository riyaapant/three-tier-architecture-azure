targetScope = 'resourceGroup'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Prefix for resource names')
param prefix string = 'webapp'

@description('Admin username for VMs')
param adminUsername string = 'azureuser'

@secure()
@description('Admin password for VMs')
param adminPassword string

// VNet
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'web'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'app'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'db'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

// Public IP for Load Balancer
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${prefix}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Load Balancer
resource lb 'Microsoft.Network/loadBalancers@2023-05-01' = {
  name: '${prefix}-lb'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

// Web VM
resource webVM 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: '${prefix}-web-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: '${prefix}-web-vm'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicWeb.id
        }
      ]
    }
  }
  dependsOn: [nicWeb]
}

resource nicWeb 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${prefix}-nic-web'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/web'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// App VM
resource appVM 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: '${prefix}-app-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: '${prefix}-app-vm'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicApp.id
        }
      ]
    }
  }
  dependsOn: [nicApp]
}

resource nicApp 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${prefix}-nic-app'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/app'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// MySQL Flexible Server
resource mysql 'Microsoft.DBforMySQL/flexibleServers@2023-06-30' = {
  name: '${prefix}-mysql'
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: 'mysqladmin'
    administratorLoginPassword: adminPassword
    version: '8.0'
    storage: {
      storageSizeGB: 32
    }
    network: {
      delegatedSubnetResourceId: '${vnet.id}/subnets/db'
    }
  }
}

// Recovery Services Vault
resource rsv 'Microsoft.RecoveryServices/vaults@2023-01-01' = {
  name: '${prefix}-rsv'
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
  }
}

// Backup Protection for VMs
resource backupWeb 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-08-01' = {
  name: '${rsv.name}/Azure/protectioncontainer-${webVM.name}/vm-${webVM.name}'
  location: location
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    sourceResourceId: webVM.id
    policyId: '${rsv.id}/backupPolicies/DefaultPolicy'
  }
  dependsOn: [webVM, rsv]
}

resource backupApp 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-08-01' = {
  name: '${rsv.name}/Azure/protectioncontainer-${appVM.name}/vm-${appVM.name}'
  location: location
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    sourceResourceId: appVM.id
    policyId: '${rsv.id}/backupPolicies/DefaultPolicy'
  }
  dependsOn: [appVM, rsv]
}
