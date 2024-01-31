// Bicep for creating API Management (APIM) Named Values with Keyvault Secret

// TODO: This module is yet to be tested as there is no appropriate access to the APIM resource group in Azure portal.

@description('APIM name.')
@minLength(1)
param apimName string

@description('Client ID to be used to access key vault secret. Null for SystemAssignedIdentity or Client Id for UserAssignedIdentity.')
param identityClientId string = ''

@description('Key vault secret identifier for fetching secret.')
param secretIdentifier string

@description('APIM Named Value Display Name.')
@minLength(3)
param displayName string

@description('Tags for the resources.')
param tags array = []


resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' existing = {
  name: apimName
}


resource namedvalue 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = {
  name: displayName
  parent: apim
  properties: {
    displayName: displayName
    keyVault: {
      identityClientId: length(identityClientId) > 0 ? identityClientId : null
      secretIdentifier: secretIdentifier
    }
    secret: true
    tags: tags
  }
}
