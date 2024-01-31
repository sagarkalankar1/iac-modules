/* 
Bicep to add Diagnostic Settings to App Service Plan
LINK FOR LOGS: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs-categories
*/

@description('The name of the Diagnostic Setting.')
param resourceName string

@description('The name of the App Service Plan.')
param appServicePlanName string

@description('The resource Id of the Workspace.')
param workspaceId string

// Default values set referring to azu-lngfxresp01.
param AllMetrics bool = false

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: appServicePlanName
}

resource setting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: resourceName
  scope: appServicePlan
  properties: {
    workspaceId: workspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: AllMetrics
      }
    ]
  }
}
