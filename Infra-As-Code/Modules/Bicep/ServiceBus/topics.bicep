// Bicep for creating Topic in Service Bus

// TODO: Replace code for param name and location with the common bicep code for these kind of params, once solution is found out.
@description('Provide Naming Convention parameter for the Service Bus Topic.')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Service Bus Topic.')
param shortName string = ''

@description('Service Bus Topic name.')
param resourceName string = ''

@description('Name of the Service Bus namespace under which Topic is to be created.')
param serviceBusNamespaceName string

@description('Delete the Service Bus Topic after it remains idle for a configurable amount of time.')
param autoDeleteOnIdle string = 'P10675199DT2H48M5.4775807S'

@description('Time to live (TTL) for a message in the Service Bus Topic.')
param defaultMessageTimeToLive string = 'P10675199DT2H48M5.4775807S'

@description('Duration of the duplicate detection history in the Service Bus Topic.')
param duplicateDetectionHistoryTimeWindow string = 'PT10M'

@description('Enable Server side batch operations.')
param enableBatchedOperations bool = true

@description('Enable express entities.')
param enableExpress bool = false

@description('Enable topic to be partitioned across multiple message brokers.')
param enablePartitioning bool = false

@description('Maximum size (in KB) of the message payload.')
param maxMessageSizeInKilobytes int = 1024

@description('Maximum size of the topic in megabytes.')
param maxSizeInMegabytes int = 1024

@description('Enable Duplicate Deletion for the Topic.')
param requiresDuplicateDetection bool = false

@description('Enable Topic support for Ordering.')
param supportOrdering bool = true

@description('Status of a messaging entity..')
@allowed([
  'Active'
  'Creating'
  'Deleting'
  'Disabled'
  'ReceiveDisabled'
  'Renaming'
  'Restoring'
  'SendDisabled'
  'Unknown'
])
param status string = 'Active'

@description('Tags for the resources.')
param tags object = {}

var typeOfResource = 'sbt'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


// Refering to an already existing Service Bus namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: serviceBusNamespaceName 
}


resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = {
  name: finalResourceName
  parent: serviceBusNamespace
  properties: {
    autoDeleteOnIdle: autoDeleteOnIdle
    defaultMessageTimeToLive: defaultMessageTimeToLive
    duplicateDetectionHistoryTimeWindow: duplicateDetectionHistoryTimeWindow
    enableBatchedOperations: enableBatchedOperations
    enableExpress: enableExpress
    enablePartitioning: enablePartitioning
    maxMessageSizeInKilobytes: maxMessageSizeInKilobytes
    maxSizeInMegabytes: maxSizeInMegabytes
    requiresDuplicateDetection: requiresDuplicateDetection
    status: status
    supportOrdering: supportOrdering
  }
  tags: tags
}

output serviceBusTopic object = {
  name: serviceBusTopic.name
  id: serviceBusTopic.id
}
