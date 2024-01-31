/* 
Bicep to add Diagnostic Settings to Static Web App
LINK FOR LOGS: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs-categories
*/

@description('The name of the Diagnostic Setting.')
param resourceName string

@description('The name of the Static Web App.')
param functionAppName string

@description('The resource Id of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

param functionAppLogs bool = true

param allMetrics bool = false

resource functionApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: functionAppName
}

resource setting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: resourceName
  scope: functionApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId != '' ? logAnalyticsWorkspaceId : ''
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: functionAppLogs
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: allMetrics
      }
    ]
  }
}
