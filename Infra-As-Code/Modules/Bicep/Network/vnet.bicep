// Create VNet

@description('Name of the VNet')
param vnetName string 

@description('A list of address blocks reserved for this virtual network in CIDR notation.')
param vnetAddressPrefix string  = '10.0.0.0/16'

@description('location for vnet')
param location string = resourceGroup().location

@description('Tags for resource')
param tags object 

// Create VNet
// *use mention for resource ' = existing'*
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
   name: vnetName
   location: location
   properties: {
     addressSpace: {
       addressPrefixes: [
         vnetAddressPrefix
       ]
     }
   }
   tags: tags
}