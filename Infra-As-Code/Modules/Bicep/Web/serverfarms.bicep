//Bicep template for deploying App service Plan

@description('Name of App Service Plan')
param resourceName string = ''

@description('Provide Naming Convention parameter for the App Service Plan')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the App Service Plan.')
param shortName string = ''

@description('Location of App Service Plan')
param location string

@description('SKU type for scalability')
@allowed([
  'WS1'
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1V3'
  'P2V3'
  'P3V3'
])
param sku string

@description('Tags of resource')
param tags object 

@description('OS of App Service Plan')
@allowed([
  'linux'
  'windows'
  'elastic'
])
param appServicePlanKind string

var typeOfResource = 'asp'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName

//Creating a new app service plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: finalResourceName
  location: location
  sku: {
    name: sku
  }
  kind: appServicePlanKind
  properties: {
    reserved: appServicePlanKind == 'linux' ? true : false
    zoneRedundant: (contains(sku,'P')) ? true : false //add support to disable zone redundnacy even while using Premium???
  }
  tags: tags
}

output appServicePlan object = {
  name: appServicePlan.name
  id: appServicePlan.id
}
