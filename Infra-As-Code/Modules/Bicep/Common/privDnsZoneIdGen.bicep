//Private DNS Zone ID Generator

@description('Input array of Private DNS Zone from same Vnet')
param privDnsZoneName string

@description('Input name of Resource Group')
param resourceGroup string

@description('Input Subscription ID')
param subscriptionId string 

@description('Prefix for Private DNS Zone ID')
var dnsZoneIDPrefix = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/privateDnsZones/'
 
@description('Outputs DNS ID based on the input parameters')
output dnsZoneId string = '${dnsZoneIDPrefix}${privDnsZoneName}'
