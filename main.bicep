@description('Location to deploy the resources in')
param location string = 'swedencentral'

@description('Number of virtual machines to deploy in each tier')
param numberOfServers int = 2

@secure()
@description('Username for server/database admin')
param serverAdminLogin string

@secure()
@description('Password for server/database admin')
param serverAdminLoginPassword string

@description('Tiers required in the architecture')
var tiers = [
  'webtier'
  'apptier'
  'datatier'
  'bastion'
]

@description('Resources that require public IP addresses')
var publicIpResources = [
  'bastion'
  'natGateway'
  'externalLoadBalancer'
]


module vnet 'modules/network.bicep' = {
  params: {
    location: location
    tiers: tiers
    publicIpResources: publicIpResources
  }
}

module servers 'modules/servers.bicep' = {
  params: {
    location: location
    numberOfServers: numberOfServers
    tiers: tiers
    serverAdminLogin: serverAdminLogin
    serverAdminLoginPassword: serverAdminLoginPassword
    subnetIds: vnet.outputs.subnetIds
    externalLoadBalancerBackendAddressPoolId: vnet.outputs.externalLoadBalancerBackendPoolId
    internalLoadBalancerBackendAddressPoolId: vnet.outputs.internalLoadBalancerBackendPoolId
    privateDnsZoneId: vnet.outputs.privateDnsZoneId
  }
}

output publicLoadBalancerIp string = vnet.outputs.externalLoadBalancerPublicIp
