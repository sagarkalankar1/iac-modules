//Bicep template for deploying Function App

//Confluence Page: https://lennar.atlassian.net/wiki/spaces/PLAT/pages/561709128/Function+App+Module

// TODO: Replace code for param name and location with the common bicep code for these kind of params, once solution is found out.

@description('Provide Naming Convention parameter for the Function App')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Function App')
param shortName string = ''

@description('Provide name for the Function App')
param resourceName string = ''

@description('Provide Private Endpoint Suffix for the Function App')
param privEndpointSuffix string = 'ep01' 

@description('Metadata for creating Private Endpoint for Function App. Required Keys: [ sharedResourceGroup, privEndpointSubnetName, sharedVnetName, pvtDnsZone{}.resourceGroupName, pvtDnsZone{}.subscriptionId ] Optional Keys [ pvtDnsZone{}.zoneName ] ')
param funcMetadata object

@description('Function App Storage Account name')
param functionAppStorageAccName string

@description('Location for Function App.')
param location string 

@description('Tags for resources')
param tags object

@description('Name of App Service Plan')
param appServicePlanName string

@description('List of Allowed origins of request')
param allowedOrigins array

@description('Gets or sets whether CORS requests with credentials are allowed')
param supportCredentials bool = false

@description('MinTlsVersion: configures the minimum version of TLS required for SSL requests')
@allowed([
  '1.2'
])
param tlsVersion string = '1.2'

@description('State of FTP / FTPS service')
@allowed([
  'Disabled'
  'FtpsOnly'
])
param ftpsState string = 'Disabled'

@description('Enabled Logs categories for diagnostics settings')
param logAnalyticsWorkspaceName string

@description('Logs to be passed from diagnostics settings')
param dsLogCategories object = {
  functionAppLogs: true
  allMetrics: false
}

//NOTE: Python and poweshell currently not supported hence commented out. 
@description('Runtime stack for the Functions Worker')
@allowed([
  'node'
  //'python'
  'dotnet'
  'java'
  //'powershell'
])
param functionsRuntimeWorker string 

//https://learn.microsoft.com/en-us/azure/azure-functions/functions-app-settings#FUNCTIONS_WORKER_RUNTIME
//To fetch the latest values for this parameter use az cli command:
// az functionapp list-runtimes
//When functionRuntimeWorker is node put linuxFxVersion as Node|18-lts
@description('The Runtime Stack versions for Linux based App Service Plan, Possible Values: [ dotnet, java, Node|18-lts ] ')
param linuxFxVersion string = ''

//To fetch the latest values for this parameter use az cli command:
// az functionapp list-runtimes
//When functionRuntimeWorker is node put windowsFxVersion as Node|18-lts
@description('The Runtime Stack of current web app for Windows based App Service Plan, Possible Values: [ dotnet, java, Node|18-lts ]')
param windowsFxVersion string = ''

//To fetch the latest values for this parameter use az cli command:
// az functionapp list-runtimes
//When functionRuntimeWorker is dotnet put netFrameworkVersion as 6
@description('The Runtime Stack versions, Possible Values: [ v4.8, 6, 7 ]')
param netFrameworkVersion string = ''

//To fetch the latest values for this parameter use az cli command:
// az functionapp list-runtimes
//When functionRuntimeWorker is java put javaVersion as 17
@description('The Runtime Stack versions, Possible Values: [ 8, 11, 17 ]')
param javaVersion string = ''

// @description('The Runtime Stack versions ie. 7.2')
// param powerShellVersion string = ''

@description('Name of the App Insights to be linked')
param appInsightsName string

@description('Enable Always On configuration')
param alwaysOn bool = true

// Currently only supports the SystemAssigned. 
// In future we will have capability to use UserAssigned Managed Service Identity.
@description('Type of Managed Service Identity.')
@allowed([
    'SystemAssigned'
//  'None'
//  'SystemAssigned, UserAssgined'
//  'UserAssgined'
])
param identityType string = 'SystemAssigned'


var typeOfResource = 'func'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


@description('User Defined Function to generate Subnet ID based on Subscription ID Resource Group Name Vnet Name and Subnet Name')
func generateSubnetId(subscriptionId string, resourceGroup string, vnetName string, subnetName string) string => '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'

// Refering to an already existing app insights.
resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName 
}

// Referring to an already existing Storage Account for Function App.
resource functionAppStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: functionAppStorageAccName
}

// Creating Function App
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: toLower(finalResourceName)
  location: location
  kind: 'functionapp'
  identity: {
    type: identityType
  }
  properties: {
    serverFarmId: appServicePlanName
    virtualNetworkSubnetId: generateSubnetId(subscription().subscriptionId,funcMetadata.sharedResourceGroup, funcMetadata.sharedVnetName, funcMetadata.vnetIntSubnetName)
    siteConfig: {
      // TODO: Testing and adding appSettings[] Jira: https://lennar.atlassian.net/browse/PLT-28306
      ftpsState: ftpsState
      minTlsVersion: tlsVersion
      linuxFxVersion: linuxFxVersion
      windowsFxVersion: windowsFxVersion
      netFrameworkVersion: netFrameworkVersion
      javaVersion: javaVersion
      //powerShellVersion: powerShellVersion
      vnetRouteAllEnabled: true
      alwaysOn: alwaysOn
      cors: {
        allowedOrigins: allowedOrigins
        supportCredentials: supportCredentials
      }
    }
    httpsOnly: true
  }
  tags: tags
  dependsOn: [
    functionAppStorageAccount
  ]
}


module functionAppConfig 'Sites/config.bicep' = {
  name: '${finalResourceName}functionAppConfig'
  params: {
    appSettings: {
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
      ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
      WEBSITE_CONTENTSHARE: '${toLower(finalResourceName)}9f32'
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${functionAppStorageAccount.name};AccountKey=${functionAppStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
      AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${functionAppStorageAccount.name};AccountKey=${functionAppStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
      FUNCTIONS_WORKER_RUNTIME: functionsRuntimeWorker
      FUNCTIONS_EXTENSION_VERSION: '~4'
    }
    appServiceName: finalResourceName
    currentAppSettings: list(resourceId('Microsoft.Web/sites/config', functionApp.name, 'appsettings'), '2022-03-01').properties
  }
  dependsOn: [
    //functionApp
  ]
}

// Creating Private endpoint for Function App
module privateEndPoint '../Network/privateEndpoint.bicep' = {
  name: 'functionAppPrivEndpoint'
  params: {
    pvtDnsZone: funcMetadata.pvtDnsZone
    groupId: 'sites'
    resourceName: '${finalResourceName}-${privEndpointSuffix}'
    resourceId: functionApp.id
    subnetId: generateSubnetId(subscription().subscriptionId, funcMetadata.sharedResourceGroup,funcMetadata.sharedVnetName,funcMetadata.privEndpointSubnetName)
    location: location
    tags: tags
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

module diagnosticSettings '../Insights/DiagnosticSettings/functionAppDS.bicep' = {
  name: '${finalResourceName}DiagnosticSettings'
  params: {
    resourceName: '${finalResourceName}-diags'
    functionAppName: functionApp.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    functionAppLogs: contains(dsLogCategories, 'functionAppLogs')? dsLogCategories.functionAppLogs : true
    allMetrics: contains(dsLogCategories, 'allMetrics')? dsLogCategories.allMetrics : false
  }
}

output functionApp object = {
  name: functionApp.name
  id: functionApp.id
}


output privEndpoint object = {
  name: privateEndPoint.outputs.privateEndpoint.name
  id: privateEndPoint.outputs.privateEndpoint.id
}
