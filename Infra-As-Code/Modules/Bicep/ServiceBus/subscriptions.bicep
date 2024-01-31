// Bicep for creating Subscription in Service Bus Topic

// TODO: Replace code for param name and location with the common bicep code for these kind of params, once solution is found out.
@description('Provide Naming Convention parameter for the Service Bus Queue.')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Service Bus Queue.')
param shortName string = ''

@description('Service Bus Queue name.')
param resourceName string = ''

@description(' Client ID of the application that created the client-affine subscription.')
param clientAffineClientId string = ''

@description('Indicates whether the client-affine subscription is durable.')
param clientAffineIsDurable bool = false

@description('Indicates whether the client-affine subscription is shared.')
param clientAffineIsShared bool = false

@description('Indicates whether a subscription has dead letter support on filter evaluation exceptions.')
param deadLetteringOnFilterEvaluationExceptions bool = false

@description('Indicates whether the subscription has an affinity to the client id.')
param isClientAffine bool = false

@description('Name of the Service Bus Topic under which Subscription is to be created.')
param serviceBusTopicName string

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

@description('Amount of time that the message is locked for other receivers.')
param lockDuration string = 'PT5M'

@description('Maximum delivery count where message is automatically deadlettered after this number of deliveries.')
param maxDeliveryCount int = 10

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

@description('Tags for the resources.')
param tags object = {}

@description('Queue/Topic name to forward the messages.')
param forwardTo string = ''

@description('Queue/Topic name to forward the Dead Letter message.')
param forwardDeadLetteredMessagesTo string = ''

var typeOfResource = 'sbs'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


// Refering to an already existing Service Bus Topic
resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' existing = {
  name: serviceBusTopicName 
}


resource serviceBusSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = {
  name: finalResourceName
  parent: serviceBusTopic
  properties: {
    autoDeleteOnIdle: autoDeleteOnIdle
    clientAffineProperties: isClientAffine == false ? {} : {
      clientId: clientAffineClientId
      isDurable: clientAffineIsDurable
      isShared: clientAffineIsShared
    }
    deadLetteringOnFilterEvaluationExceptions: deadLetteringOnFilterEvaluationExceptions
    deadLetteringOnMessageExpiration: deadLetteringOnMessageExpiration
    defaultMessageTimeToLive: defaultMessageTimeToLive
    duplicateDetectionHistoryTimeWindow: duplicateDetectionHistoryTimeWindow
    enableBatchedOperations: enableBatchedOperations
    isClientAffine: isClientAffine
    lockDuration: lockDuration
    maxDeliveryCount: maxDeliveryCount
    requiresSession: requiresSession
    forwardTo: length(forwardTo) > 0 ? forwardTo : json('null')
    forwardDeadLetteredMessagesTo: length(forwardDeadLetteredMessagesTo) > 0 ? forwardDeadLetteredMessagesTo : json('null')
    status: status
  }
  tags: tags
}

output serviceBusSubscription object = {
  name: serviceBusSubscription.name
  id: serviceBusSubscription.id
}
