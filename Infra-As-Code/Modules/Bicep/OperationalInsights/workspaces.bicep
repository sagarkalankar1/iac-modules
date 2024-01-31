// Bicep to create Log Analytics Workspace.

@description('Name of the Log Analytics Workspace')
param resourceName string = ''

@description('Provide Naming Convention parameter for the Log Analytics Workspace')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Log Analytics Workspace.')
param shortName string = ''

@description('Location of the Log Analytics Workspace')
param location string

@description('Tags for the resources')
param tags object

//TODO: JIRA PLT-28423 : We will add the support for setting userassigned Service Identity in future
@description('Type of managed service identity')
@allowed([
  'SystemAssigned'
  //'UserAssigned'
])
param idType string = 'SystemAssigned'

@description('The name of the SKU')
@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param sku string

@description('Daily qouta for data collection in GB')
param dailyQuotaGb int = -1 // -1 is used to disable daily qouta in Log Analytics Workspace

@description('The workspace data retention in days')
param retentionInDays int = 30

@description('Flag that indicate which permission to use - resource or workspace or both')
param enableLogAccessUsingOnlyResourcePermissions bool = true

@description('The network access type for accessing Log Analytics ingestion')
param publicNetworkAccessForIngestion string = 'Enabled'

@description('The network access type for accessing Log Analytics query')
param publicNetworkAccessForQuery string = 'Enabled'

var typeOfResource = 'log'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: finalResourceName
  location: location
  tags: tags
  identity: { 
    type: idType
  }
  properties: {
    features: {
      enableLogAccessUsingOnlyResourcePermissions: enableLogAccessUsingOnlyResourcePermissions
    }
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion //Enabled in GFX PROD => lnos-gfx-log-prod
    publicNetworkAccessForQuery: publicNetworkAccessForQuery         //Enabled in GFX PROD => lnos-gfx-log-prod
    retentionInDays: retentionInDays
    sku: {
      name: sku
    }
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
  }
}


output logAnalyticsWorkspace object = {
  name: logAnalyticsWorkspace.name
  id: logAnalyticsWorkspace.id
}
