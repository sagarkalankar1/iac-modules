//Bicep template for deploying Logic App

@description('Provide Naming Convention parameter for the Logic App')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Logic App')
param shortName string = ''

@description('Provide name for the Logic App')
param resourceName string = ''

@description('Provide Private Endpoint Suffix for the Logic App')
param privEndpointSuffix string = 'ep01' 

@description('Metadata for creating Private Endpoint for Logic App. Required Keys: [ sharedResourceGroup, privEndpointSubnetName, sharedVnetName, pvtDnsZone{}.resourceGroupName, pvtDnsZone{}.subscriptionId ] Optional Keys [ pvtDnsZone{}.zoneName ] ')
param logicMetadata object

@description('Logic App Storage Account name')
param logicAppStorageAccName string

@description('Name of Already Existing App Service Plan')
param appServicePlanName string

@description('Location for all resources.')
param location string

param tags object

//TODO: JIRA PLT-28423 : We will add the support for setting userassigned Service Identity in future
@description('Type of Managed Service Identity')
@allowed([
  // 'None'
  'SystemAssigned'
  // 'SystemAssigned, UserAssgined'
  // 'UserAssgined'    //==> array of user assigned identities.
])
param identityType string = 'SystemAssigned'

@description('Name of the App Insights to be linked')
param appInsightsName string

@description('Enable Always On configuration')
param alwaysOn bool

@description('State of FTP / FTPS service')
@allowed([
  'Disabled'
  'FtpsOnly'
])
param ftpsState string = 'Disabled'

@description('MinTlsVersion: configures the minimum version of TLS required for SSL requests')
@allowed([
  '1.2'
])
param tlsVersion string = '1.2'

@description('List of Allowed origins of request')
param allowedOrigins array

@description('Gets or sets whether CORS requests with credentials are allowed')
param supportCredentials bool = false

@description('Enable HTTP 2.0 configuration')
param http20Enabled bool = true

@description('Enable Remote Debugging')
param remoteDebuggingEnabled bool = false

@description('Enable diagnostics logs in app service')
param detailedErrorLoggingEnabled bool = true

@description('Enabled Logs categories for diagnostics settings')
param logAnalyticsWorkspaceName string

@description('Pass value to App Setting WEBSITE_NODE_DEFAULT_VERSION ')
param WEBSITE_NODE_DEFAULT_VERSION string = '~14'

@description('Pass value to App Setting AzureFunctionsJobHost__extensionBundle__version ')
param AzureFunctionsJobHost__extensionBundle__version string = '[1.*, 2.0.0)'

@description('Pass suffix to App Setting WEBSITE_CONTENTSHARE')
param WEBSITE_CONTENTSHAREsuffix string = '998c'

@description('Set to true to use 32-bit worker process')
param use32BitWorkerProcess bool = true

@allowed([
  'v6.0'
])
@description('.NET Framework version.')
param netFrameworkVersion string = 'v6.0'

@description('Logs to be passed from diagnostics settings')
param dsLogCategories object = {
  functionAppLogs: true
  allMetrics: false
  workflowRuntime: true
}


var typeOfResource = 'logic'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


@description('User Defined Function to generate Subnet ID based on Subscription ID Resource Group Name Vnet Name and Subnet Name')
func generateSubnetId(subscriptionId string, resourceGroup string, vnetName string, subnetName string) string => '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: appServicePlanName
}


resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}


// Referring to an already existing Storage Account for Logic App.
resource logicAppStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: logicAppStorageAccName
}


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}


resource logicAppStandard 'Microsoft.Web/sites@2021-02-01' = {
  name: finalResourceName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: identityType 
  }
  properties: {
    httpsOnly: true
    virtualNetworkSubnetId: generateSubnetId(subscription().subscriptionId,logicMetadata.sharedResourceGroup,logicMetadata.sharedVnetName,logicMetadata.vnetIntSubnetName)
    serverFarmId: appServicePlan.id
    siteConfig: {
      // The functionsRuntimeScaleMonitoringEnabled property is used in the context of an Azure Function App. The default value passed is true which fails the Logic App deployment
      functionsRuntimeScaleMonitoringEnabled: false
      minTlsVersion: tlsVersion
      ftpsState: ftpsState
      vnetRouteAllEnabled: true
      alwaysOn: alwaysOn
      detailedErrorLoggingEnabled: detailedErrorLoggingEnabled
      cors: {
        allowedOrigins: allowedOrigins
        supportCredentials: supportCredentials
      }
      http20Enabled: http20Enabled
      remoteDebuggingEnabled: remoteDebuggingEnabled
      use32BitWorkerProcess: use32BitWorkerProcess 	
      netFrameworkVersion: netFrameworkVersion
    }
  }
  dependsOn: [
    logicAppStorageAccount
  ]
  tags: tags
}


module LogicAppConfig 'Sites/config.bicep' = {
  name: '${finalResourceName}LogicAppConfig'
  params: {
    appSettings: {
      APP_KIND: 'workflowApp'
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
      ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
      AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
      AzureFunctionsJobHost__extensionBundle__version: AzureFunctionsJobHost__extensionBundle__version
      AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${logicAppStorageAccount.name};AccountKey=${logicAppStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'node'
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${logicAppStorageAccount.name};AccountKey=${logicAppStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
      WEBSITE_CONTENTOVERVNET: '1'
      WEBSITE_CONTENTSHARE: '${toLower(finalResourceName)}${WEBSITE_CONTENTSHAREsuffix}'
      WEBSITE_NODE_DEFAULT_VERSION: WEBSITE_NODE_DEFAULT_VERSION
    }
    appServiceName: finalResourceName
    currentAppSettings: list(resourceId('Microsoft.Web/sites/config', logicAppStandard.name, 'appsettings'), '2022-03-01').properties
  }
  dependsOn: [
    logicAppStandard
  ]
}

//TODO: JIRA: https://lennar.atlassian.net/browse/PLT-34215. 
//Temporary fix while Microsoft find solution to the above issue.
module logicFileShare '../Storage/StorageAccounts/fileShare.bicep' = {
  name: 'logicFileShareDeploy'
  params: {
    accessTier: 'TransactionOptimized'
    resourceName: '${toLower(finalResourceName)}${WEBSITE_CONTENTSHAREsuffix}'
    storageAccountName: logicAppStorageAccount.name
  }
  dependsOn: [
    LogicAppConfig
  ]
}

module privateEndPoint '../Network/privateEndpoint.bicep' = {
  name: '${finalResourceName}PrivEndpoint'
  params: {
    pvtDnsZone: logicMetadata.pvtDnsZone
    groupId: 'sites'
    resourceName: '${finalResourceName}-${privEndpointSuffix}'
    resourceId: logicAppStandard.id
    subnetId: generateSubnetId(subscription().subscriptionId,logicMetadata.sharedResourceGroup,logicMetadata.sharedVnetName,logicMetadata.privEndpointSubnetName)
    location: location
    tags: tags
  }
}


module diagnosticSettings '../Insights/DiagnosticSettings/logicAppDS.bicep' = {
  name: '${finalResourceName}DiagnosticSettings'
  params: {
    resourceName: '${finalResourceName}-diags'
    logicAppName: logicAppStandard.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    functionAppLogs: contains(dsLogCategories, 'functionAppLogs')? dsLogCategories.functionAppLogs : true
    workflowRuntime: contains(dsLogCategories, 'workflowRuntime')? dsLogCategories.workflowRuntime : true
    allMetrics: contains(dsLogCategories, 'allMetrics')? dsLogCategories.allMetrics : false
  }
}


output logicApp object = {
  name: logicAppStandard.name
  id: logicAppStandard.id
}


output privEndpoint object = {
  name: privateEndPoint.outputs.privateEndpoint.name
  id: privateEndPoint.outputs.privateEndpoint.id
}
