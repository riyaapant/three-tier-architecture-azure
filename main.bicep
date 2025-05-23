@description('Location to deploy the resources in')
param location string = 'westeurope'

@description('Tiers required in the architecture')
param tiers array = [
  'webtier'
  'apptier'
  'datatier'
  'bastion'
]

@description('Number of virtual machines to deploy in each tier')
param numberOfServers int = 2

@secure()
@description('Username for server/database admin')
param serverAdminLogin string

@secure()
@description('Password for server/database admin')
param serverAdminLoginPassword string

module vnet 'modules/network.bicep' = {
  params: {
    location: location
    tiers: tiers
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
  }
}
