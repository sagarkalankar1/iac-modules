/* 
Bicep to add Diagnostic Settings to App Service
LINK FOR LOGS: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs-categories
*/

@description('The name of the Diagnostic Setting.')
param resourceName string

@description('The name of the App Service.')
param appServiceName string

@description('The resource Id of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

// Default values set referring to azu-lngfxresp01.
param reportAntivirusAuditLogs bool = false

param appServiceApplicationLogs bool = true

param accessAuditLogs bool = true

param appServiceConsoleLogs bool = true

param siteContentChangeAuditLogs bool = false

param httplogs bool = true

param ipSecurityAuditlogs bool = true

param appServicePlatformlogs bool = true

param allMetrics bool = false

resource appService 'Microsoft.Web/sites@2020-06-01' existing = {
  name: appServiceName
}

// TODO: Add support for other sinks/ Destinations for sending logs.
resource setting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: resourceName
  scope: appService
  properties: {
    workspaceId: logAnalyticsWorkspaceId != '' ? logAnalyticsWorkspaceId : '' 
    logs: [
      {
        category: 'AppServiceAntivirusScanAuditLogs'
        enabled: reportAntivirusAuditLogs
      }
      {
        category: 'AppServiceAppLogs'
        enabled: appServiceApplicationLogs
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: accessAuditLogs
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: appServiceConsoleLogs
      }
      {
        category: 'AppServiceFileAuditLogs'
        enabled: siteContentChangeAuditLogs
      }
      {
        category: 'AppServiceHTTPLogs'
        enabled: httplogs
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: ipSecurityAuditlogs
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: appServicePlatformlogs
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
