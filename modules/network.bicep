@description('Location to deploy resources in')
param location string

@description('Tiers in the architecture')
param tiers array

@description('Resources that require public IP addresses')
param publicIpResources array

var virtualNetworkName = 'myvnet'

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

resource webTierNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name:'web-tier-nsg'
  location:location
  properties:{
    securityRules:[{
      name:'AllowAnyHTTPInbond'
      properties:{
        priority: 100
        direction:'Inbound'
        access:'Allow'
        protocol:'Tcp'
        sourcePortRange:'*'
        destinationPortRange: '80'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
      }
    }]
  }
}

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
          networkSecurityGroup: tier == 'webtier' ? {id: webTierNsg.id} : tier == 'apptier' ? {id: webTierNsg.id} : null
        }
      }
    ]
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

@description('Extracting external load balancer public ip')
var externalLoadBalancerPublicIp = publicIps[indexOf(publicIpResources,'externalLoadBalancer')]

resource externalLoadBalancer 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: 'external-load-balancer'
  location:location
  sku:{
    name:'Standard'
  }
  properties:{
    frontendIPConfigurations:[{
      name: 'external-load-balancer-frontend'
      properties:{
        publicIPAddress:{
          id: externalLoadBalancerPublicIp.id
        }
      }
    }]
    backendAddressPools:[{
      name: 'external-load-balancer-backend-address-pool'
    }]
    loadBalancingRules:[{
      name:'external-load-balancer-load-balancing-rule'
      properties:{
        frontendIPConfiguration:{
          id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations','external-load-balancer','external-load-balancer-frontend')
        }
        backendAddressPool:{
          id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools','external-load-balancer','external-load-balancer-backend-address-pool')
        }
        frontendPort: 80
        backendPort: 80
        protocol: 'Tcp'
        loadDistribution: 'Default'
        probe:{
          id: resourceId('Microsoft.Network/loadBalancers/probes','external-load-balancer','external-load-balancer-probe')
        }
      }
    }]
    probes:[{
      name: 'external-load-balancer-probe'
      properties:{
        protocol: 'Tcp'
        port: 80
        intervalInSeconds: 5
        numberOfProbes: 2
      }
    }]
    outboundRules:[

    ]
  }
}

resource internalLoadBalancer 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: 'internal-load-balancer'
  location:location
  sku:{
    name:'Standard'
  }
  properties:{
    frontendIPConfigurations:[{
      name: 'internal-load-balancer-frontend'
      properties:{
        subnet:{
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'subnet-apptier')
        }
        privateIPAllocationMethod: 'Dynamic'
      }
    }]
    backendAddressPools:[{
      name: 'internal-load-balancer-backend-address-pool'
    }]
    loadBalancingRules:[{
      name:'internal-load-balancer-load-balancing-rule'
      properties:{
        frontendIPConfiguration:{
          id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations','internal-load-balancer','internal-load-balancer-frontend')
        }
        backendAddressPool:{
          id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools','internal-load-balancer','internal-load-balancer-backend-address-pool')
        }
        frontendPort: 80
        backendPort: 80
        protocol: 'Tcp'
        loadDistribution: 'Default'
        probe:{
          id: resourceId('Microsoft.Network/loadBalancers/probes','internal-load-balancer','internal-load-balancer-probe')
        }
      }
    }]
    probes:[{
      name: 'internal-load-balancer-probe'
      properties:{
        protocol: 'Tcp'
        port: 80
        intervalInSeconds: 5
        numberOfProbes: 2
      }
    }]
    outboundRules:[

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

output externalLoadBalancerBackendPoolId string = externalLoadBalancer.properties.backendAddressPools[0].id
output internalLoadBalancerBackendPoolId string = internalLoadBalancer.properties.backendAddressPools[0].id
output externalLoadBalancerPublicIp string = externalLoadBalancerPublicIp.properties.ipAddress
