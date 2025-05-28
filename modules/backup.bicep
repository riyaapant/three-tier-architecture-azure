@description('Location to deploy resources in')
param location string

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2025-02-01'={
  name: 'recoveryservicesvault2'
  location: location
  sku:{
    name:'RS0'
    tier:'Standard'
  }
  properties:{
    publicNetworkAccess: 'Enabled'
  }
}
