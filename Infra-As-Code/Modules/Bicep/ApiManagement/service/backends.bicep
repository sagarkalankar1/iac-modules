// Bicep template for deploying Backends to API Managment Service.

@description('Provide Name of API Managment Resource to Deploy to')
param apimName string

@description('Provide name for the Backend')
param resourceName string = ''

@allowed([
  'http'
  'soap'
])
@description('Backend communication protocol.')
param protocol string 

@description('Runtime Url of the Backend.')
param url string 

@description('Do you wish to link to an Azure App Servie/ Function App/ Logic App?')
param linkToWebApp bool = true

@description('Name of the Azure App Servie/ Function App/ Logic App?')
param webAppName string

@description('Description for Backend')
param backendDescription string 

@description('Web App resourceGroup Name')
param targetAppResourceGroup string = ''


resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' existing = {
  name: apimName
}

resource sites 'Microsoft.Web/sites@2022-09-01' existing = if(linkToWebApp) {
  name: webAppName
  scope: resourceGroup(targetAppResourceGroup)
}

resource backendDeploy 'Microsoft.ApiManagement/service/backends@2022-09-01-preview' = {
  name: resourceName 
  parent: apim
  properties: {
    protocol: protocol
    url: url
    resourceId: linkToWebApp ? 'https://management.azure.com${sites.id}': ''
    description: backendDescription
  }
}
