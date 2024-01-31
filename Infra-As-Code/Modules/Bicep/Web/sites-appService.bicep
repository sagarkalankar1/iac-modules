//Bicep template for deploying App service using bicep.

//Confluence Page: https://lennar.atlassian.net/wiki/spaces/PLAT/pages/500466841/App+Service+Module

@description('Provide Naming Convention parameter for the App Service')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the App Service.')
param shortName string = ''

@description('Provide name for the App Service')
param resourceName string = ''

@description('Provide Private Endpoint Suffix for the App Service')
param privEndpointSuffix string = 'ep01' 

@description('Metadata for creating Private Endpoint and Vnet Integration for App Service. Required Keys: [ sharedResourceGroup, privEndpointSubnetName, sharedVnetName, pvtDnsZone{}.resourceGroupName, pvtDnsZone{}.subscriptionId ] Optional Keys [ pvtDnsZone{}.zoneName ] ')
param appMetadata object

@description('Name of Already Existing App Service Plan')
param appServicePlanName string

@description('Location for all resources.')
param location string

//To fetch the latest values for this parameter use az cli command:
//  az webapp list-runtimes --linux
@description('The Runtime Stack of current web app for Linux based App Service Plan, Possible Values: [ dotnet, java, Node|18-lts ]')
param linuxFxVersion string = ''

//To fetch the latest values for this parameter use az cli command:
//  az webapp list-runtimes
@description('The Runtime Stack of current web app for Windows based App Service Plan, Possible Values: [ dotnet, java, Node|18-lts ]')
param windowsFxVersion string = ''

//To fetch the latest values for this parameter use az cli command:
//  az webapp list-runtimes
@description('Pass value to enable for DOTNET Stack, Possible Values: [ v3.5, v4.8, 6, 7 ]')
param netFrameworkVersion string = ''

// @description('Pass value to enable for PHP Stack')
// param phpVersion string = ''

//To fetch the latest values for this parameter use az cli command:
//  az webapp list-runtimes
@description('Pass value to enable for JAVA Stack, Possible Values: [ 8, 11, 17 ]')
param javaVersion string = ''

// @description('Pass value to enable for PowerShell Stack')
// param powerShellVersion string = ''

@description('Optional Git Repo URL + branch')
param repoUrl string = ''

@description('Branch name')
param branch string = ''

@description('Resource tags')
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

@description('Name of the App Insights to be linked')
param appInsightName string

@description('Enable Always On configuration')
param alwaysOn bool = true

@description('List of Allowed origins of request')
param allowedOrigins array

@description('Gets or sets whether CORS requests with credentials are allowed')
param supportCredentials bool = false

@description('Enable HTTP 2.0 configuration')
param http20Enabled bool = true

@description('Enable Remote Debugging')
param remoteDebuggingEnabled bool = false

@description('Name of the Log Analytics Workspace')
param logAnalyticsWorkspaceName string

@description('Enabled Logs categories for diagnostics settings')
param dsLogCategories object = {
  accessAuditLogs: true
  allMetrics: false
  appServiceApplicationLogs: true
  appServiceConsoleLogs: true
  appServicePlatformlogs: true
  httplogs: true
  ipSecurityAuditlogs: true
  reportAntivirusAuditLogs: false
  siteContentChangeAuditLogs: false
}

@description('Enable diagnostics logs in app service')
param detailedErrorLoggingEnabled bool = true


var typeOfResource = 'app'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


@description('User Defined Function to generate Subnet ID based on Subscription ID Resource Group Name Vnet Name and Subnet Name')
func generateSubnetId(subscriptionId string, resourceGroup string, vnetName string, subnetName string) string => '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'

// Referring to an already existing app service plan.
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: appServicePlanName 
}

// Referring to an already existing app insights.
resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightName 
}

// Creating a new App Service.
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: finalResourceName
  location: location
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: generateSubnetId(subscription().subscriptionId,appMetadata.sharedResourceGroup,appMetadata.sharedVnetName,appMetadata.vnetIntSubnetName)
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      windowsFxVersion: windowsFxVersion
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
    }
  }
  resource config 'config@2022-09-01' = {
    name: 'web'
    properties: {
      netFrameworkVersion: netFrameworkVersion
      //phpVersion: phpVersion
      javaVersion: javaVersion
      //powerShellVersion: powerShellVersion
    }
  }
  tags: tags
  identity: {
    type: identityType
  }
}

//TODO: JIRA PLT-28515 : deployment should fail if condition 'if(startsWith(repoUrl,'https')' is not met.
// Linking of repo hosting the code for the App Service.
resource webAppSourceControl 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = if(startsWith(repoUrl,'https')){ // checking if repoURL has HTTP, or wont attach any repo.
  name: 'web'
  parent: appService
  properties: {
    repoUrl: repoUrl
    branch: branch
    isManualIntegration: true
  }
}

// module privateEndPoint '../Network/privateEndpoint.bicep' = if(enablePriveEndpoint) {
module privateEndPoint '../Network/privateEndpoint.bicep' = {
  name: '${finalResourceName}PrivEndPoint'
  params: {
    pvtDnsZone: appMetadata.pvtDnsZone
    groupId: 'sites'
    resourceName: '${finalResourceName}-${privEndpointSuffix}'
    resourceId: appService.id
    subnetId: generateSubnetId(subscription().subscriptionId, appMetadata.sharedResourceGroup, appMetadata.sharedVnetName,  appMetadata.privEndpointSubnetName)
    location: location
    tags: tags
  }
}

module appServiceConfig 'Sites/config.bicep' = {
  name: '${finalResourceName}appServiceConfig'
  params: {
    appSettings: {
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    }
    appServiceName: finalResourceName
    currentAppSettings: list(resourceId('Microsoft.Web/sites/config', appService.name, 'appsettings'), '2022-03-01').properties
  }
  dependsOn: [
    appService
  ]
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

module diagnosticSettings '../Insights/DiagnosticSettings/appServiceDS.bicep' = {
  name: '${finalResourceName}DiagnosticSettings'
  params: {
    resourceName: '${finalResourceName}-diags'
    appServiceName: appService.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    accessAuditLogs: contains(dsLogCategories, 'accessAuditLogs')? dsLogCategories.accessAuditLogs : true
    allMetrics: contains(dsLogCategories, 'allMetrics')? dsLogCategories.allMetrics : false
    appServiceApplicationLogs: contains(dsLogCategories, 'appServiceApplicationLogs')? dsLogCategories.appServiceApplicationLogs : true
    appServiceConsoleLogs: contains(dsLogCategories, 'appServiceConsoleLogs')? dsLogCategories.appServiceConsoleLogs : true
    appServicePlatformlogs: contains(dsLogCategories, 'appServicePlatformlogs')? dsLogCategories.appServicePlatformlogs : true
    httplogs: contains(dsLogCategories, 'httplogs')? dsLogCategories.httplogs : true
    ipSecurityAuditlogs: contains(dsLogCategories, 'ipSecurityAuditlogs')? dsLogCategories.ipSecurityAuditlogs : true
    reportAntivirusAuditLogs: contains(dsLogCategories,'reportAntivirusAuditLogs')? dsLogCategories.reportAntivirusAuditLogs : false
    siteContentChangeAuditLogs: contains(dsLogCategories, 'siteContentChangeAuditLogs')? dsLogCategories.siteContentChangeAuditLogs : false
  }
}


output appService object = {
  name: appService.name
  id: appService.id
}


output privEndpoint object = {
  name: privateEndPoint.outputs.privateEndpoint.name
  id: privateEndPoint.outputs.privateEndpoint.id
}
