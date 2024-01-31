/* 
Bicep to add Diagnostic Settings to Azure Key Vault
LINK FOR LOGS: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs-categories
*/

@description('The name of the Diagnostic Setting.')
param resourceName string

@description('The name of the Key Vault.')
param keyVaultName string

@description('The resource Id of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

// Default values set referring to azu-lngfxresp01.
param auditEvent bool = true

param azurePolicyEvaluationDetails bool = true

param allMetrics bool = false

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource setting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: resourceName
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId != '' ? logAnalyticsWorkspaceId : ''
    logs: [
      {
        category: 'AuditEvent'
        enabled: auditEvent
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: azurePolicyEvaluationDetails
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
