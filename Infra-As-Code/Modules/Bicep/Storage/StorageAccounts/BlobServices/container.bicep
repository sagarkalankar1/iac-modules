//Bicep template for deploying Container

@description('Name of existing Storage Account')
param storageAccountName string

@description('Name of Container')
param resourceName string


resource blob 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' existing = {
  name: '${storageAccountName}/default'
}

//Creating container
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: resourceName
  parent: blob
}
