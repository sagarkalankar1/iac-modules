/* 
Bicep to add Diagnostic Settings to Cosmos DB
LINK FOR LOGS: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs-categories
*/

@description('The name of the Diagnostic Setting.')
param resourceName string

@description('The name of the Cosmos DB.')
param cosmosDBName string

@description('The resource Id of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

// Default values set referring to azu-lngfxresp01.
param cassandraRequests bool = false

param controlPlaneRequests bool = true

param dataPlaneRequests bool = true

param gremlinRequests bool = true

param mongoRequests bool = false

param partitionKeyRUConsumption bool = true

param partitionKeyStatistics bool = true

param queryRuntimeStatistics bool = true

param tableApiRequests bool = true

param allMetrics bool = false

resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts@2023-03-01-preview' existing = {
  name: cosmosDBName
}

// TODO: Add support for other sinks/ Destinations for sending logs.
resource setting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: resourceName
  scope: cosmosDB
  properties: {
    workspaceId: logAnalyticsWorkspaceId != '' ? logAnalyticsWorkspaceId : ''
    logs: [
      {
        category: 'cassandraRequests'
        enabled: cassandraRequests
      }
      {
        category: 'dataPlaneRequests'
        enabled: dataPlaneRequests
      }
      {
        category: 'controlPlaneRequests'
        enabled: controlPlaneRequests
      }
      {
        category: 'gremlinRequests'
        enabled: gremlinRequests
      }
      {
        category: 'mongoRequests'
        enabled: mongoRequests
      }
      {
        category: 'partitionKeyRUConsumption'
        enabled: partitionKeyRUConsumption
      }
      {
        category: 'partitionKeyStatistics'
        enabled: partitionKeyStatistics
      }
      {
        category: 'queryRuntimeStatistics'
        enabled: 	queryRuntimeStatistics
      }
      {
        category: 'tableApiRequests'
        enabled: 	tableApiRequests
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
