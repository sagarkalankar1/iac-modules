// Bicep for creating API Management (APIM) Product

// TODO: Replace code for param name and location with the common bicep code for these kind of params, once solution is found out.
@description('Provide Naming Convention parameter for the APIM Product.')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the APIM Product.')
param shortName string = ''

@description('APIM Product name.')
param resourceName string = ''

@description('APIM name.')
param apimName string

@description('Whether subscription is required for accessing APIs included in this product.')
param subscriptionRequired bool = false

@description('Enable developers to call the product’s APIs immediately after subscribing with/without approval based on true/false.')
param approvalRequired bool = false

@description('APIM Product description.')
@minLength(10)
param productDescription string

@description('APIM Product Display Name.')
param displayName string

@description('State of APIM Product.')
@allowed([
  'notPublished'
  'published'
])
param state string = 'notPublished'

@description('APIM Product terms of use to be by developers trying to subscribe to the product.')
param terms string = ''

@description('Tags for the resources.')
param tags object = {}

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.projectCode}-${namingConventionProperties.environment}' : '${namingConventionProperties.projectCode}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' existing = {
  name: apimName
}


resource product 'Microsoft.ApiManagement/service/products@2022-09-01-preview' = {
  name: finalResourceName
  parent: apim
  properties: {
    subscriptionRequired: subscriptionRequired
    approvalRequired: subscriptionRequired == false ? approvalRequired : null
    description: productDescription
    displayName: displayName
    state: state
    terms: terms
  }
  tags: tags
}
