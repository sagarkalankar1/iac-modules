// Bicep for creating/ refering to Access policies 

//NOT TO BE USED: Based on discussion during Standup on 22-Apr-2023, it was decided to bake AKV Key, Secrets, Certificate and AccessPolicy Manually until further discussion. So keeping this module here, for future perspective only 
@description('Name of existing Key Vault')
param keyVaultName string

@description('Name of the Access Policy')
param resourceName string

@description('Provide Application ID for access')
param applicationId string

@description('Provide Object ID for access')
param objectId string

@description('Provide Tenant ID for access')
param tenantId string

@description('Permisions for Certificates Keys Secrets and Storage')
param certificates array = []

param keys array = []

param secrets array = []

param storage array = []


// Refer existing Key vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: keyVaultName
}


// Create access policy for KeyVault Keys, certificates, secrets, etc.
resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-11-01' = {
  name: resourceName
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        applicationId: applicationId
        objectId: objectId
        permissions: {
          certificates: certificates
          keys: keys
          secrets: secrets
          storage: storage
        }
        tenantId: tenantId
      }
    ]
  }
}


// Output Attributes for Access Policies
output accessPolicyAttributes object = {
  name: accessPolicy.name
  id: accessPolicy.id
}
