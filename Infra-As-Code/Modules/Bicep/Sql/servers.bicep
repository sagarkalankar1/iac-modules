// Bicep template for SQL Server

@description('The name of the SQL logical server.')
param resourceName string = ''

@description('Provide Naming Convention parameter for the SQL server')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the SQL server.')
param shortName string = ''

@description('Location for the SQL Server.')
param location string

@description('The administrator username of the SQL logical server.')
param administratorLogin string

// We had discussed about multiple approched for maintaining the SQL Admin Password.
// You will find the details in below JIRA ticket.
// JIRA: https://lennar.atlassian.net/browse/PLT-30152
// Current approch: We are going to use the Azure DevOps variable grp to maintain Server Admin password and will pass it to bicep script at runtime.
@description('The administrator password of the SQL logical server.')
@secure()
param administratorLoginPassword string

@description('Tags for the resource')
param tags object

@description('Whether or not public endpoint access is allowed for this server. Value is optional but if passed in, must be Enabled or Disabled')
@allowed([
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Whether or not to restrict outbound network access for this server. Value is optional but if passed in, must be Enabled or Disabled')
@allowed([
  'Disabled'
])
param restrictOutboundNetworkAccess string = 'Disabled'

@description('The version of the server.')
param version string

@description('Metadata for creating Private Endpoint for Sql Server. Required Keys: [ sharedResourceGroup, privEndpointSubnetName, sharedVnetName, pvtDnsZone{}.resourceGroupName, pvtDnsZone{}.subscriptionId ] Optional Keys [ pvtDnsZone{}.zoneName ]')
param sqlMetadata object

@description('Provide Private Endpoint Suffix for the Sql Server')
param privEndpointSuffix string = 'ep01' 


var typeOfResource = 'sqlserver'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


@description('User Defined Function to generate Subnet ID based on Subscription ID Resource Group Name Vnet Name and Subnet NameD')
func generateSubnetId(subscriptionId string, resourceGroup string, vnetName string, subnetName string) string => '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'

// Creating SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-08-01-preview' = {
  name: finalResourceName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    publicNetworkAccess: publicNetworkAccess
    restrictOutboundNetworkAccess: restrictOutboundNetworkAccess
    version: version
  }
  tags: tags
}

module privateEndPoint '../Network/privateEndpoint.bicep' = {
  name: '${finalResourceName}PrivEndPoint'
  params: {
    pvtDnsZone: sqlMetadata.pvtDnsZone
    groupId: 'sqlServer'
    resourceName: '${finalResourceName}-${privEndpointSuffix}'
    resourceId: sqlServer.id
    subnetId: generateSubnetId(subscription().subscriptionId,sqlMetadata.sharedResourceGroup,sqlMetadata.sharedVnetName,sqlMetadata.privEndpointSubnetName)
    location: location
    tags: tags
  }
}

output sqlServer object = {
  name: sqlServer.name
  id: sqlServer.id
}
