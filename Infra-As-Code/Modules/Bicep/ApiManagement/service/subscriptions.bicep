// Bicep for creating API Management (APIM) Subscription

// TODO: This module is yet to be tested as there is no appropriate access to the APIM resource group in Azure portal.

@description('APIM name.')
@minLength(1)
param apimName string

@description('Determines whether tracing can be enabled.')
param allowTracing bool

@description('APIM Subscription Display Name.')
@minLength(3)
param displayName string

@description('User (user id path) for whom subscription is being created in form /users/{userId}.')
param ownerId string = ''

@description('Primary subscription key. If not specified during request key will be generated automatically.')
param primaryKey string = ''

@description('Scope like /products/{productId} or /apis or /apis/{apiId}.')
@minLength(5)
param scope string

@description('Secondary subscription key. If not specified during request key will be generated automatically.')
param secondaryKey string = ''

@description('Initial subscription state. If no value is specified, subscription is created with Submitted state.')
@allowed([
  'active'
  'cancelled'
  'expired'
  'rejected'
  'submitted'
  'suspended'
])
param state string = 'submitted'


resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' existing = {
  name: apimName
}


resource subscription 'Microsoft.ApiManagement/service/subscriptions@2023-03-01-preview' = {
  name: displayName
  parent: apim
  properties: {
    allowTracing: allowTracing
    displayName: displayName
    ownerId: length(ownerId) > 0 ? ownerId : null
    primaryKey: length(primaryKey) > 0 ? primaryKey : null
    scope: scope
    secondaryKey: length(secondaryKey) > 0 ? secondaryKey : null
    state: state
  }
}
