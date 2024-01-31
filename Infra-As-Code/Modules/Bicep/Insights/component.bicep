//Create App insights resource

@description('Provide Naming Convention parameter for the Application Insights')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Application Insights.')
param shortName string = ''

@description('Provide name for the Application Insights')
param resourceName string = ''

@description('Location for Application Insights')
param location string 

@description('The kind of application that this component refers to, used to customize UI')
@allowed([
  'web'
  'ios'
  'other'
  'store'
  'java'
  'phone'
])
param kind string 

@description('Tags for App Insights')
param tags object

@description('Type of application being monitored.')
@allowed([
  'web'
  'other'
])
param Application_Type string 

@description('Describes what tool created this Application Insights component.') //default value is 'rest'
param Request_Source string = 'IbizaAIExtensionEnablementBlade'

@description('Name of the Log Analytics Workspace')
param logAnalyticsWorkspaceName string

var typeOfResource = 'appi'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

//Creating AppInsights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: finalResourceName
  location: location
  kind: kind
  properties: {
    Application_Type: Application_Type
    Flow_Type: 'Bluefield'
    Request_Source: Request_Source
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
  tags: tags
}


output appInsights object = {
  name: appInsights.name
  id: appInsights.id
  instrumentationKey: appInsights.properties.InstrumentationKey
  connectionKey: appInsights.properties.ConnectionString
}
