// Bicep for adding Secrets to Key Vault

//NOT TO BE USED: Based on discussion during Standup on 22-Apr-2023, it was decided to bake AKV Key, Secrets, Certificate and AccessPolicy Manually until further discussion. So keeping this module here, for future perspective only 
@description('Name of the Key Vault')
param keyVaultName string

@description('Name of the Secret')
param resourceName string


// Refer existing Key vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: keyVaultName
}


// Check if the secret exists in Key vault
// resource existingSecret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' existing = {
//   name: resourceName
// }


// Create secret in Key Vault.
// resource secret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = if (existingSecret == null) {
resource secret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {  
  parent: keyVault
  name: resourceName
  properties: {
    // TODO: Find solution for how to ignore the change in secret value. Jira: https://lennar.atlassian.net/browse/PLT-28305
    value: 'TO_BE_FILLED_BY_RELEASE_MGMT_TEAM'
  }
}


// Output Attributes for Secrets
output secretAttributes object = {
  name: secret.name
  id: secret.id
}
