// Bicep template for deploying Key Vault Service.

@description('Provide Naming Convention parameter for the Key Vault')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Key Vault.')
param shortName string = ''

@description('Provide name for the Key Vault')
param resourceName string = ''

@description('Provide Private Endpoint Suffix for the Key Vault')
param privEndpointSuffix string = 'ep01' 

@description('Provide location for the Key Vault')
param location string

@description('Provide SKU for the Key Vault')
@allowed([
  'standard'
  'premium'
])
param sku string = 'standard'

@description('Provide Access Policies for the Key Vault')
param accessPolicies array = []

@description('Property to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the Key Vault.')
param enabledForDeployment bool = false

@description('Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the Key Vault.')
param enabledForTemplateDeployment bool = false

@description('Property to specify whether Azure Disk Encryption is permitted to retrieve secrets from the Key Vault and unwrap keys.	')
param enabledForDiskEncryption bool = false

@description('Property that controls how data actions are authorized.')
param enableAzureRbacAuthorization bool = false

// @description('Property to specify whether the vault will accept traffic from public internet.')
// param publicNetworkAccess string = 'Disabled'

// @description('Property to specify whether the "soft delete" functionality is enabled for this Key Vault.')
// param enableSoftDelete bool = true

@description('Soft Delete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int = 31

@description('Network permissions')
param networkAcls object = {}

@description('Provide Tenant ID for access')
param tenantId string

@description('Metadata for creating Private Endpoint for KV. Required Keys: [ sharedResourceGroup, privEndpointSubnetName, sharedVnetName, pvtDnsZone{}.resourceGroupName, pvtDnsZone{}.subscriptionId ] Optional Keys [ pvtDnsZone{}.zoneName ]')
param kvMetadata object

@description('Tags for the resources')
param tags object 

@description('Name of the Log Analytics Workspace')
param logAnalyticsWorkspaceName string

@description('Enabled Logs categories for diagnostics settings')
param dsLogCategories object = {
  auditEvent: true
  allMetrics: false
  azurePolicyEvaluationDetails: true
}


var typeOfResource = 'kv'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


@description('User Defined Function to generate Subnet ID based on Subscription ID Resource Group Name Vnet Name and Subnet Name')
func generateSubnetId(subscriptionId string, resourceGroup string, vnetName string, subnetName string) string => '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'


// Creating / refering to Key vault service 
resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' = {
  name: finalResourceName
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableRbacAuthorization: enableAzureRbacAuthorization
    accessPolicies: accessPolicies
    tenantId: tenantId
    sku: {
      name: sku
      family: 'A'
    }
    // publicNetworkAccess: publicNetworkAccess
    publicNetworkAccess: 'Disabled'
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    networkAcls: networkAcls
  }
  tags: tags
}


// Custom  module to create Private Endpoint
// module privateEndPoint '../Network/privateEndpoint.bicep' = if(enablePriveEndpoint) {
module privateEndPoint '../Network/privateEndpoint.bicep' = {
  name: '${finalResourceName}PrivEndPoint'
  params: {
    pvtDnsZone: kvMetadata.pvtDnsZone
    groupId: 'vault'
    resourceName: '${finalResourceName}-${privEndpointSuffix}'
    resourceId: keyVault.id
    subnetId: generateSubnetId(subscription().subscriptionId, kvMetadata.sharedResourceGroup, kvMetadata.sharedVnetName, kvMetadata.privEndpointSubnetName)
    location: location
    tags: tags
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

module diagnosticSettings '../Insights/DiagnosticSettings/keyVaultDS.bicep' = {
  name: '${finalResourceName}DiagnosticSettings'
  params: {
    resourceName: '${finalResourceName}-diags'
    keyVaultName: keyVault.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    allMetrics: contains(dsLogCategories, 'allMetrics')? dsLogCategories.allMetrics : false
    auditEvent: contains(dsLogCategories,'auditEvent')? dsLogCategories.auditEvent : true
    azurePolicyEvaluationDetails: contains(dsLogCategories, 'azurePolicyEvaluationDetails')? dsLogCategories.azurePolicyEvaluationDetails : true
  }
}

// Output Attributes for Key Vault
output keyVaultAttributes object = {
  name: keyVault.name
  id: keyVault.id
}


// Output Attributes for Key Vault Private Endpoint
output privateEndPointAttributes object = {
  name: privateEndPoint.outputs.privateEndpoint.name
  id: privateEndPoint.outputs.privateEndpoint.id
}
