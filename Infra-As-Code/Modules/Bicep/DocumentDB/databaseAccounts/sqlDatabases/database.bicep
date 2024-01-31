// Bicep Template for deploying database

@description('Name of the Cosmos DB SQL database.') 
param databaseName string

@description('The resource name.') 
param cosmosDbDatabaseName string

@description('Name of the parent CosmosDB.') 
param cosmosDbName string

@description('The location of the resource group to which the resource belongs.')
param location string 

@description('Tags are a list of key-value pairs that describe the resource.')
param tags object = {}

@description('Represents maximum throughput, the resource can scale up to.')
param maxThroughput int = 1000

@description('Request Units per second. For example, "throughput": 10000.')
param throughput int = 400
 

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2023-09-15' existing = {
  name: cosmosDbName
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  name: cosmosDbDatabaseName
  location: location
  tags: tags
  parent: cosmosDb
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: maxThroughput
      }
      throughput: throughput
    }
    resource: {
      id: databaseName
    }
  }
}
