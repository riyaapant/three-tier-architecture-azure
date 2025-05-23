@description('Location to deploy resources in')
param location string

@description('Tiers in the architecture')
param tiers array

@description('Resources that require public IP addresses')
param publicIpResources array

var virtualNetworkName = 'myvnet'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      for (tier, i) in tiers: {
        name: tier == 'bastion' ? 'AzureBastionSubnet' : 'subnet-${tier}'
        properties: {
          addressPrefix: '10.0.${i+1}.0/24'
          natGateway:{
            id: natGateway.id
          }
        }
      }
    ]
  }
}

resource publicIps 'Microsoft.Network/publicIPAddresses@2024-05-01' = [
  for resource in publicIpResources: {
    name: '${resource}-public-ip'
    location: location
    sku: {
      name: 'Standard'
    }
    properties: {
      publicIPAllocationMethod: 'Static'
    }
  }
]

@description('Extraction NAT Gateway public IP')
var natGatewayPublicIp = publicIps[indexOf(publicIpResources,'natGateway')]

resource natGateway 'Microsoft.Network/natGateways@2024-05-01'={
  name:'nat-gateway'
  location:location
  properties:{
    publicIpAddresses:[{
      id: natGatewayPublicIp.id
    }]
  }
  sku:{
    name:'Standard'
  }
}

@description('Extracting bastion public IP')
var bastionPublicIp = publicIps[indexOf(publicIpResources,'bastion')]

resource bastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: 'bastion-host'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

output subnetIds array = [
  for (tier, i) in tiers: {
    subnetTier: tier
    subnetId: tier == 'bastion'
      ? resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AzureBastionSubnet')
      : resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'subnet-${tier}')
  }
]
