// Bicep for creating Queue in Service Bus

// TODO: Replace code for param name and location with the common bicep code for these kind of params, once solution is found out.
@description('Provide Naming Convention parameter for the Service Bus Queue.')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Service Bus Queue.')
param shortName string = ''

@description('Service Bus Queue name.')
param resourceName string = ''

@description('Name of the Service Bus namespace under which Queue is to be created.')
param serviceBusNamespaceName string

@description('Delete the Service Bus Queue after it remains idle for a configurable amount of time.')
param autoDeleteOnIdle string = 'P10675199DT2H48M5.4775807S'

@description('Enable dead lettering on message expiration for Service Bus Queue.')
param deadLetteringOnMessageExpiration bool = false

@description('Time to live (TTL) for a message in the Service Bus Queue.')
param defaultMessageTimeToLive string = 'P10675199DT2H48M5.4775807S'

@description('Duration of the duplicate detection history in the Service Bus Queue.')
param duplicateDetectionHistoryTimeWindow string = 'PT10M'

@description('Enable Server side batch operations.')
param enableBatchedOperations bool = true

@description('Enable express entities.')
param enableExpress bool = false

@description('Enable queue to be partitioned across multiple message brokers.')
param enablePartitioning bool = false

@description('Amount of time that the message is locked for other receivers.')
param lockDuration string = 'PT5M'

@description('Maximum delivery count where message is automatically deadlettered after this number of deliveries.')
param maxDeliveryCount int = 10

@description('Maximum size (in KB) of the message payload.')
param maxMessageSizeInKilobytes int = 1024

@description('Maximum size of the queue in megabytes.')
param maxSizeInMegabytes int = 1024

@description('Enable Duplicate Deletion for the Queue.')
param requiresDuplicateDetection bool = false

@description('Enable Queue to support the concept of sessions.')
param requiresSession bool = false

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

@description('Queue/Topic name to forward the messages.')
param forwardTo string = ''

@description('Queue/Topic name to forward the Dead Letter message.')
param forwardDeadLetteredMessagesTo string = ''

@description('Tags for the resources.')
param tags object = {}

var typeOfResource = 'sbq'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


// Refering to an already existing Service Bus namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: serviceBusNamespaceName
}


resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: finalResourceName
  parent: serviceBusNamespace
  properties: {
    autoDeleteOnIdle: autoDeleteOnIdle
    deadLetteringOnMessageExpiration: deadLetteringOnMessageExpiration
    defaultMessageTimeToLive: defaultMessageTimeToLive
    duplicateDetectionHistoryTimeWindow: duplicateDetectionHistoryTimeWindow
    enableBatchedOperations: enableBatchedOperations
    enableExpress: enableExpress
    enablePartitioning: enablePartitioning
    lockDuration: lockDuration
    maxDeliveryCount: maxDeliveryCount
    maxMessageSizeInKilobytes: maxMessageSizeInKilobytes
    maxSizeInMegabytes: maxSizeInMegabytes
    requiresDuplicateDetection: requiresDuplicateDetection
    requiresSession: requiresSession
    forwardTo: length(forwardTo) > 0 ? forwardTo : json('null')
    forwardDeadLetteredMessagesTo: length(forwardDeadLetteredMessagesTo) > 0 ? forwardDeadLetteredMessagesTo : json('null')
    status: status
  }
  tags: tags
}

output serviceBusQueue object = {
  name: serviceBusQueue.name
  id: serviceBusQueue.id
}
