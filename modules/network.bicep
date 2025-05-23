param location string

param tiers array

var virtualNetworkName = 'myvnet'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworkName
  location: location
  properties:{
    addressSpace:{
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [for (tier,i) in tiers: {
      name:'subnet-${tier}'
      properties:{
        addressPrefix:'10.0.${i+1}.0/24'
      }
    }]
  }
}

output subnetIds array = [
  for (tier,i) in tiers: {
    subnetTier: tier
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets',virtualNetworkName,'subnet-${tier}')
  }
]
