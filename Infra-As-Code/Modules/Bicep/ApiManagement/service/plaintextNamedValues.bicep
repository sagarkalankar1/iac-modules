// Bicep for creating API Management (APIM) Named Values with Plaintext value

// TODO: This module is yet to be tested as there is no appropriate access to the APIM resource group in Azure portal.

@description('APIM name.')
@minLength(1)
param apimName string

@description('APIM Named Value Display Name.')
@minLength(3)
param displayName string

@description('Value of the APIM NamedValue.')
@minLength(1)
param value string

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
    secret: false
    value: value
    tags: tags
  }
}
