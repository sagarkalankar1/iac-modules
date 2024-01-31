//Subnet ID Generator

@description('Input array of Subnets from same Vnet')
param subnetName string

@description('Input name of Vnet')
param vnetName string

@description('Input name of Resource Group')
param resourceGroup string

@description('Input Subscription ID')
param subscriptionId string

@description('Prefix for Subnets ID')
var subnetIDPrefix = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/'
 
@description('Outputs Subnet IDs based on the input parameters')
output subnetID string = '${subnetIDPrefix}${subnetName}'
