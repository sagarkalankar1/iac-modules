@description('Provide Naming Convention parameter for the Azure connection')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Azure Connection.')
param shortName string = ''

@description('Provide name for the Azure Connection')
param resourceName string = ''

@description('Location for all resources.')
param location string

param tags object

@description('The display name for API')
param apiDisplayName string

@description('Resource reference id for API Connection')
param apiConnectionResourceId string

@description('Resource reference type')
param apiConnectionResourceType string = ''

@description('Dictionary of custom parameter values')
param connectionCustomParameterValues object = {}

@description('Dictionary of nonsecret parameter values')
param connectionNonSecretParameterValues object = {}

@description('Dictionary of parameter values')
param connectionParameterValues object = {}

@description('Status of the connection')
param connectionStatuses array = []

@description('Connection Access Policy resource Object ID')
param connectionAccessPolicyObjectId string

@description('Connection Access Policy resource Tenent ID')
param connectionAccessPolicyTenantId string

@description('Azure Connection API kind')
@allowed([
  'V2'
])
param azureConnectionKind string = 'V2'

var typeOfResource = 'connection'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName

resource azureConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: finalResourceName
  location: location
  tags: tags
  kind: 'V2'
  properties: {
    api: {
      displayName: apiDisplayName
      id: apiConnectionResourceId
      type: apiConnectionResourceType
    }
    customParameterValues: connectionCustomParameterValues
    nonSecretParameterValues: connectionNonSecretParameterValues
    parameterValues: connectionParameterValues
    statuses: connectionStatuses
  }
  resource accessPolices 'accessPolicies@2016-06-01' = {
    name: '${finalResourceName}-policy'
    location: location
    properties: {
      principal: {
        type: 'ActiveDirectory'
        identity: {
          objectId: connectionAccessPolicyObjectId
          tenantId: connectionAccessPolicyTenantId
        }
      }
    }
  }
}
