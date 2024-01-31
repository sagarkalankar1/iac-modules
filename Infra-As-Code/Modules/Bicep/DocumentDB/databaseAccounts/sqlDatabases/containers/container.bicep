// This bicep file makes Cosmos DB containers

@description('The resource name.')
param dbContainerName string  

@description('Name of the Cosmos DB SQL container.')
param containerName string 

@description('Name of the parent CosmosDB.')
param cosmosDbName string

@description('Name of the Cosmos DB SQL database.')
param databaseName string

@description('The location of the resource group to which the resource belongs.')
param location string 

@description('Tags are a list of key-value pairs that describe the resource.')
param tags object = {}

@description('Represents maximum throughput, the resource can scale up to.')
param maxThroughput int = 1000

@description('Request Units per second. For example, "throughput": 10000.')
param throughput int = 400

@description('Analytical TTL.')
param analyticalStorageTtl int = -1

@description('Paths of the item that need encryption along with path-specific settings. Allowed Keys: [ clientEncryptionKeyId, encryptionAlgorithm, encryptionType, path ]')
param clientEncryptionPolicyincludedPaths array = []

@description('Version of the client encryption policy definition. Supported versions are 1 and 2. Version 2 supports id and partition key path encryption.')
param clientEncryptionPolicypolicyFormatVersion int = 2

@description('The conflict resolution path in the case of LastWriterWins mode.')
param conflictResolutionPath string = '/_ts'

@description('The procedure to resolve conflicts in the case of custom mode.')
param conflictResolutionProcedure string = ''

@description('Indicates the conflict resolution mode. Allowed values: "Custom", "LastWriterWins".')
param mode string = 'LastWriterWins'

@description('Default time to live.')
param defaultTtl int = -1

@description('Indicates if the indexing policy is automatic.')
param automatic bool = true

@description('List of composite path list. Allowed Keys: [ order, path ] Allowed Values [ order: ascending, descending ]')
param compositeIndexes array = []

@description('List of paths to exclude from indexing.  Allowed Keys: [ path ]')
param indexingPolicyexcludedPaths array = []

@description('List of paths to include in the indexing.  Allowed Keys: [ indexes[ Array of Objects ], path ] Allowed keys in an object of indexes are: [ [ dataType: LineString, MultiPolygon, Number, Point, Polygon, String ], [ kind : Hash, Range, Spatial], [ precision: int ] ] ')
param indexingPolicyincludedPaths array = []

@description('Indicates the indexing mode. Allowed Values [ consistent, lazy, none ] ')
param indexingMode string = 'consistent'

@description('List of spatial specifics. spatialIndexes[ Array of Object ] Allowed keys in an object of spatialIndexes are: [ path: string , types: [ String array containing any of: LineString, MultiPolygon, Point, Polygon ] ]')
param spatialIndexes array = []

@description('Indicates the kind of algorithm used for partitioning. For MultiHash, multiple partition keys (up to three maximum) are supported for container create "Hash","MultiHash","Range".')
param partitionKeykind string = 'Hash'

@description('The configuration of the partition key to be used for partitioning data into multiple partitions.')
param partitionKeyPath array = ['/myPartitionKey']

@description('Describes the version.')
param partitionKeyVersion int = 2

@description('List of unique keys on that enforces uniqueness constraint on documents in the collection in the Azure Cosmos DB service. Allowed Keys: [ paths ]')
param uniqueKeys array = []


resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2023-09-15' existing = {
  name: cosmosDbName
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' existing = {
  parent: cosmosDb
  name: databaseName
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  name: dbContainerName
  location: location
  tags: tags
  parent: cosmosDbDatabase
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: maxThroughput
      }
      throughput: throughput
    }
    resource: {
      analyticalStorageTtl: analyticalStorageTtl
      clientEncryptionPolicy: {
        includedPaths: clientEncryptionPolicyincludedPaths
        policyFormatVersion: clientEncryptionPolicypolicyFormatVersion
      }
      conflictResolutionPolicy: {
        conflictResolutionPath: conflictResolutionPath
        conflictResolutionProcedure: conflictResolutionProcedure
        mode: mode
      }
      defaultTtl: defaultTtl
      id: containerName
      indexingPolicy: {
        automatic: automatic
        compositeIndexes: compositeIndexes
        excludedPaths: indexingPolicyexcludedPaths
        includedPaths: indexingPolicyincludedPaths
        indexingMode: indexingMode
        spatialIndexes: spatialIndexes
      }
      partitionKey: {
        kind: partitionKeykind
        paths: partitionKeyPath
        version: partitionKeyVersion
      }
      uniqueKeyPolicy: {
        uniqueKeys: uniqueKeys
      }
    }
  }
}
