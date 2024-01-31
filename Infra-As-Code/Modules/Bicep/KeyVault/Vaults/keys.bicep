// Bicep for adding Key to Key Vault

//NOT TO BE USED: Based on discussion during Standup on 22-Apr-2023, it was decided to bake AKV Key, Secrets, Certificate and AccessPolicy Manually until further discussion. So keeping this module here, for future perspective only 
@description('Name of Parent Key Vault')
param keyVaultName string

@description('Tags for Key')
param tags object

@description('Name of the Key')
param resourceName string

@description('The type of the Key.')
@allowed([
  'RSA'
  'RSA-HSM'
  'EC'
  'EC-HSM'
])
param keyType string


// Refer existing Key vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: keyVaultName
}


// Create Key in Key Vault.
resource key 'Microsoft.KeyVault/vaults/keys@2022-11-01' = {
  parent: keyVault
  tags: tags
  name: resourceName
  properties: {
    kty: keyType
  }
}


// Output Attributes for Keys
output keyAttributes object = {
  name: key.name
  id: key.id
}
