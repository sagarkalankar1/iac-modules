//Bicep to create datasets for datafactory for blob storage

@description('Name of the DataFactory')
param dataFactoryName string

@description('Name of the Data Sets')
param resourceName string

@description('linked Service Name')
param linkedServiceName string

@description('Specify the container of Azure Blob')
param blobContainerName string

@description('Specify the folder path of Data Set')
param folderPath string

@description('Specify the file name of Data Set')
param fileName string


//Refering to datafactory 
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
}

//Creating Dataset
resource dataFactoryDataSetIn 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: resourceName
  properties: {
    linkedServiceName: {
      referenceName: linkedServiceName
      type: 'LinkedServiceReference'
    }
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: blobContainerName
        folderPath: folderPath
        fileName: fileName
      }
    }
  }
}
