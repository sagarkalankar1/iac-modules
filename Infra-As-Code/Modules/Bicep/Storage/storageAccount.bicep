//Bicep template for deploying storage account 

@description('Azure region of the deployment')
param location string

@description('Provide Naming Convention parameter for the Storage Account')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Storage Account.')
param shortName string = ''

// TODO: https://lennar.atlassian.net/browse/PLT-28458 Replace code for param name and location with the common bicep code for these kind of params, once solution is found out.
@description('Storage Account name, max length 44 characters')
@maxLength(44)
param resourceName string = ''

// @description('Provide Private Endpoint Suffix for the Storage Account')
// param privEndpointSuffix string = 'ep01'

@description('Metadata for creating Private Endpoint for Storage Account. Required Keys: [ sharedResourceGroup, blobPrivEndpointSubnetName, tablePrivEndpointSubnetName, queuePrivEndpointSubnetName, filePrivEndpointSubnetName, sharedVnetName, pvtDnsZone{}.resourceGroupName, pvtDnsZone{}.subscriptionId ] Optional Keys [ pvtDnsZone{}.zoneName] ')
param saMetadata object

@description('Tagging resources')
param tags object 

//REF: https://learn.microsoft.com/en-us/rest/api/storagerp/srp_sku_types
@description('Storage SKU')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param storageSkuName string 

@description('Type of Storage Account')
@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param kind string

@description('Required if kind== BlobStorage. Used for billing')
@allowed([
  'Cool'
  'Hot'
  'Premium'
  ''
])
param accessTier string = 'Hot'

@description('Allow Public Access to Blob')
param allowBlobPublicAccess bool = false

// @description('Enable Private Endpoint for resource')
// param enablePrivateEndpoint bool = true

// @description('Resource group ID')
// @allowed([
//   'blob'
//   'file'
// ])
// param groupId string 

@allowed([
  'Disabled'
  'Enabled'
])
@description('Allow or disallow public network access to Storage Account')
param publicNetworkAccess string


var typeOfResource = 'stblob'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


@description('User Defined Function to generate Subnet ID based on Subscription ID Resource Group Name Vnet Name and Subnet Name')
func generateSubnetId(subscriptionId string, resourceGroup string, vnetName string, subnetName string) string => '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'

//Creating storage account 
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: replace(finalResourceName, '-', '')
  location: location
  sku: {
    name: storageSkuName
  }
  kind: kind
  properties: (kind == 'BlobStorage') ? {
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    publicNetworkAccess: publicNetworkAccess
  } : {
    allowBlobPublicAccess: allowBlobPublicAccess
    publicNetworkAccess: publicNetworkAccess
  }
  
  tags: tags
}

//Creating private endpoints
module saBlobPrivateEndPoint '../Network/privateEndpoint.bicep' = if(contains(saMetadata, 'blobPrivEndpointSubnetName' )) {
  name: 'deploySaBlobPrivEndPoint'
  params: {
    pvtDnsZone: saMetadata.pvtDnsZone
    groupId: 'file'
    resourceName: '${finalResourceName}-ep01'
    resourceId: storage.id
    subnetId: contains(saMetadata, 'blobPrivEndpointSubnetName')?generateSubnetId(subscription().subscriptionId,saMetadata.sharedResourceGroup,saMetadata.sharedVnetName,saMetadata.blobPrivEndpointSubnetName):''
    location: location
    tags: tags
  }
}

module saTablePrivateEndPoint '../Network/privateEndpoint.bicep' = if(contains(saMetadata, 'tablePrivEndpointSubnetName' )) {
  name: 'deploySaTablePrivEndPoint'
  params: {
    pvtDnsZone: saMetadata.pvtDnsZone
    groupId: 'file'   //'table'
    resourceName: '${finalResourceName}-ep02'
    resourceId: storage.id
    subnetId: contains(saMetadata, 'tablePrivEndpointSubnetName' )?generateSubnetId(subscription().subscriptionId,saMetadata.sharedResourceGroup,saMetadata.sharedVnetName,saMetadata.tablePrivEndpointSubnetName):''
    location: location
    tags: tags
  }
  dependsOn: [
    saBlobPrivateEndPoint
  ]
}

module saQueuePrivateEndPoint '../Network/privateEndpoint.bicep' = if(contains(saMetadata, 'queuePrivEndpointSubnetName' )) {
  name: 'deploySaQueuePrivEndPoint'
  params: {
    pvtDnsZone: saMetadata.pvtDnsZone
    groupId: 'file'   //'queue'
    resourceName: '${finalResourceName}-ep03'
    resourceId: storage.id
    subnetId: contains(saMetadata, 'queuePrivEndpointSubnetName' )?generateSubnetId(subscription().subscriptionId,saMetadata.sharedResourceGroup,saMetadata.sharedVnetName,saMetadata.queuePrivEndpointSubnetName):''
    location: location
    tags: tags
  }
  dependsOn: [
    saTablePrivateEndPoint
  ]
}

module saFilePrivateEndPoint '../Network/privateEndpoint.bicep' = if(contains(saMetadata, 'filePrivEndpointSubnetName' )) {
  name: 'deploySaFilePrivEndPoint'
  params: {
    pvtDnsZone: saMetadata.pvtDnsZone
    groupId: 'file'
    resourceName: '${finalResourceName}-ep04'
    resourceId: storage.id
    subnetId: contains(saMetadata, 'filePrivEndpointSubnetName' )?generateSubnetId(subscription().subscriptionId,saMetadata.sharedResourceGroup,saMetadata.sharedVnetName,saMetadata.queuePrivEndpointSubnetName):''
    location: location
    tags: tags
  }
  dependsOn: [
    saQueuePrivateEndPoint
  ]
}


output storage object = {
  name: storage.name
  id: storage.id
}

//output keys object = {
//primary: storage.listKeys().keys[0].value
//  secondary: storage.listKeys().keys[1].value
//}

output blobPrivateEndPoint object = contains(saMetadata, 'blobPrivEndpointSubnetName' ) ? {
  name: saBlobPrivateEndPoint.outputs.privateEndpoint.name
  id: saBlobPrivateEndPoint.outputs.privateEndpoint.id
} : {}

output tablePrivateEndPoint object = contains(saMetadata, 'tablePrivEndpointSubnetName' ) ? {
  name: saTablePrivateEndPoint.outputs.privateEndpoint.name
  id: saTablePrivateEndPoint.outputs.privateEndpoint.id
} : {}

output queuePrivateEndPoint object = contains(saMetadata, 'queuePrivEndpointSubnetName' ) ? {
  name: saQueuePrivateEndPoint.outputs.privateEndpoint.name
  id: saQueuePrivateEndPoint.outputs.privateEndpoint.id
} : {}

output filePrivateEndPoint object = contains(saMetadata, 'filePrivEndpointSubnetName' ) ? {
  name: saFilePrivateEndPoint.outputs.privateEndpoint.name
  id: saFilePrivateEndPoint.outputs.privateEndpoint.id
} : {}
