//Create Subnet

@description('Name of the Vnet')
param vnetName string 

@description('List of address prefixes for the subnet.')
param subnetPrefix string

@description('Name of the subnet')
param resourceName string

@description('Enable or Disable apply network policies on private end point in the subnet.')
param privateEndpointNetworkPolicies string = 'Disabled'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

//Create Subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: resourceName
  properties: {
    addressPrefix: subnetPrefix
    privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
  }
}

output vnetId string = vnet.id
output subnetId string = subnet.id
