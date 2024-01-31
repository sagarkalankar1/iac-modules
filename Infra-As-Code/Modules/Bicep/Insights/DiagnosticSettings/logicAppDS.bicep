/* 
Bicep to add Diagnostic Settings to Static Web App
LINK FOR LOGS: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs-categories
*/

@description('The name of the Diagnostic Setting.')
param resourceName string

@description('The name of the Static Web App.')
param logicAppName string

@description('The resource Id of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

param functionAppLogs bool = true

param workflowRuntime bool = true

param allMetrics bool = false

resource logicApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: logicAppName
}

resource setting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: resourceName
  scope: logicApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: functionAppLogs
      }
      {
        category: 'WorkflowRuntime'
        enabled: workflowRuntime
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
