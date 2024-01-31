//Bicep template for deploying Cosmos DB Account 

@description('Provide Naming Convention parameter for the Cosmos DB')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Cosmos DB.')
param shortName string = ''

// TODO: https://lennar.atlassian.net/browse/PLT-28458 Replace code for param name and location with the common bicep code for these kind of params, once solution is found out.
@description('Azure Cosmos DB account name, max length 44 characters')
@maxLength(44)
param resourceName string = ''

@description('Provide Private Endpoint Suffix for the Cosmos DB')
param privEndpointSuffix string = 'ep01'

@description('Metadata for creating Private Endpoint for Cosmos DB. Required Keys: [ sharedResourceGroup, privEndpointSubnetName, sharedVnetName, pvtDnsZone{}.resourceGroupName, pvtDnsZone{}.subscriptionId ] Optional Keys [ pvtDnsZone{}.zoneName ]')
param cosmosMetadata object

@description('Location for the Azure Cosmos DB account.')
param location string

@description('The primary region for the Azure Cosmos DB account.')
param primaryRegion string = location

@description('Enable system managed failover for regions')
@allowed([
  true
  false
])
param systemManagedFailover bool = true

@description('Offer type of Database account.')
param databaseAccountOfferType string = 'Standard'

@description('Tags for resource')
param tags object 

@description('Type of Database account')
@allowed([
  'GlobalDocumentDB'
  'MongoDB'
  'Parse'
])
param dBAccoutkind string 

@description('Keep true for Serverless and false for Provisioned Throughput')
param enableServerless bool = false

@description('Azure Role-Based Access Control')
param disableKeyBasedMetadataWriteAccess bool = true

@description('Allow Public Network Access')
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Name of the Log Analytics Workspace')
param logAnalyticsWorkspaceName string

@description('Indicates the minimum allowed Tls version')
param minimalTlsVersion string = 'Tls12'

@description('Enabled Logs categories for diagnostics settings')
param dsLogCategories object = {
  cassandraRequests: false
  controlPlaneRequests: true
  dataPlaneRequests: true
  gremlinRequests: true
  mongoRequests: false
  partitionKeyRUConsumption: true
  partitionKeyStatistics: true
  queryRuntimeStatistics: true
  tableApiRequests: true
  allMetrics: false
}

@description('Type of Managed Service Identity.')
@allowed([
    'SystemAssigned'
//  'None'
//  'SystemAssigned, UserAssigned'
//  'UserAssigned'
])
param identityType string = 'SystemAssigned'


var typeOfResource = (dBAccoutkind == 'GlobalDocumentDB')? 'cosno' : (dBAccoutkind == 'MongoDB') ? 'mongo' : 'parse'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName

@description('The regions your DB is replicated in. An array of location objects')
var locations = [
  {
    locationName: primaryRegion  // location/ region 
    failoverPriority: 0          // Index of priority 
    isZoneRedundant: true       // Zone redundancy 
  }
]


@description('User Defined Function to generate Subnet ID based on Subscription ID Resource Group Name Vnet Name and Subnet Name')
func generateSubnetId(subscriptionId string, resourceGroup string, vnetName string, subnetName string) string => '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'


//Creating database account
resource account 'Microsoft.DocumentDB/databaseAccounts@2022-11-15' = {
  name: toLower(finalResourceName) // Needs to be lower case 
  location: location
  kind: dBAccoutkind
  properties: {
    publicNetworkAccess: publicNetworkAccess
    locations: locations
    databaseAccountOfferType: databaseAccountOfferType
    disableKeyBasedMetadataWriteAccess: disableKeyBasedMetadataWriteAccess
    enableAutomaticFailover: length(locations) > 1 ? systemManagedFailover : false
    minimalTlsVersion: minimalTlsVersion
    capabilities: enableServerless ? [
      {
        name: 'EnableServerless'
      }
    ] : []
  }
  identity: {
    type: identityType
  }
  tags: tags
}

module privateEndpoint '../Network/privateEndpoint.bicep' = {
  name: 'cosmosDBPrivEndpoint'
  params: {
    pvtDnsZone: cosmosMetadata.pvtDnsZone
    groupId: dBAccoutkind == 'GlobalDocumentDB' ? 'Sql' : 'MongoDB'
    resourceName: '${finalResourceName}-${privEndpointSuffix}'
    resourceId: account.id
    subnetId: generateSubnetId(subscription().subscriptionId,cosmosMetadata.sharedResourceGroup,cosmosMetadata.sharedVnetName,cosmosMetadata.privEndpointSubnetName)
    location: location
    tags: tags
  }
}


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

module diagnosticSettings '../Insights/DiagnosticSettings/cosmosDbDS.bicep' = {
  name: '${finalResourceName}diagnosticSettings'
  params: {
    cosmosDBName: account.name
    resourceName: '${resourceName}-diags'
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    cassandraRequests: contains(dsLogCategories, 'cassandraRequests')? dsLogCategories.cassandraRequests : false
    allMetrics: contains(dsLogCategories, 'allMetrics')? dsLogCategories.allMetrics : false
    controlPlaneRequests: contains(dsLogCategories, 'controlPlaneRequests')? dsLogCategories.controlPlaneRequests : true
    dataPlaneRequests: contains(dsLogCategories, 'dataPlaneRequests')? dsLogCategories.dataPlaneRequests : true
    gremlinRequests: contains(dsLogCategories, 'gremlinRequests')? dsLogCategories.gremlinRequests : true
    mongoRequests: contains(dsLogCategories, 'mongoRequests')? dsLogCategories.mongoRequests : false
    partitionKeyRUConsumption: contains(dsLogCategories, 'partitionKeyRUConsumption')? dsLogCategories.partitionKeyRUConsumption : true
    partitionKeyStatistics: contains(dsLogCategories, 'partitionKeyStatistics')? dsLogCategories.partitionKeyRUConsumption : true
    queryRuntimeStatistics: contains(dsLogCategories,'queryRuntimeStatistics')? dsLogCategories.queryRuntimeStatistics : true
    tableApiRequests: contains(dsLogCategories, 'tableApiRequests')? dsLogCategories.tableApiRequests : true
  }
}


output account object = {
  name: account.name
  id: account.id
}

output privateEndpoint object = {
  name: privateEndpoint.outputs.privateEndpoint.name
  id: privateEndpoint.outputs.privateEndpoint.id
}
