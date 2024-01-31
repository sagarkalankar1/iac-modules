//Bicep template to add configuration setting to app servcies

@description('Name of an existing App Service')
param appServiceName string

@description('Add Key Value pairs of new Application Settings')
param appSettings object

@description('List of the existing Key Value pairs of Application Settings')
param currentAppSettings object


resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName 
}

resource siteconfig 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: appService
  properties: union(currentAppSettings, appSettings)
}
