//Bicep template for deploying Blob Services 

@description('Name of existing Storage Account')
param storageAccountName string


resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default' //Can't be anything else 
  parent: storage
}
