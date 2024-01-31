//Bicep template for deploying File Share instance inside an existing Storage account 

@description('Name of existing Storage Account')
param storageAccountName string

@description('Name of File Share')
param resourceName string

@description('Access tier for specific share.')
@allowed([
  'Cool'
  'Hot' 
  'Premium'
  'TransactionOptimized'
])
param accessTier string

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource blob 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  name: 'default'
  parent: storage
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
    }
  }
  resource fileshare 'shares@2023-01-01' = {
    name: resourceName
    properties:{
      accessTier: accessTier
    }
  }
}
