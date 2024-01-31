//Bicep to create azure data factory.

@description('Name of the Data Factory')
param resourceName string

@description('Location of Resource')
param location string

@description('Tags for Resource')
param tags object

@description('The Identity type')
@allowed([
  'SystemAssigned'
  'SystemAssigned,UserAssigned'
  'UserAssigned'
])
param type string

@description('Name of the Storage Account')
param storageAccountName string

@description('Linked Service Name')
param dataFactoryLinkedServiceName string

@description('Name of the Data Sets Out')
param dataFactoryDatasetInName string

@description('Name of the Data Sets Input')
param dataFactoryDatasetOutName string

@description('Linked Service Name')
param linkedServiceName string

@description('Specify the container of Azure Blob')
param blobContainerName string

@description('Specify the file name of Data Set')
param fileName string

@description('Name of Data Set Input')
param pipelineName string

//Create ADF 
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: resourceName
  location: location
  tags: tags
  properties: {
  }
  identity: {
    type: type
  }
}

//Create linked service for blob storage
module linkedService 'Factories/linkedservices.bicep' = {
  name: 'LinkedServiceDeploy'
  params: {
    dataFactoryLinkedServiceName: dataFactoryLinkedServiceName
    dataFactoryName: resourceName
    storageAccountName: storageAccountName
  }
}

//Create datasetIn using blob storage
module dataSetsIn 'Factories/datasets.bicep' = {
  name: 'DatasetInDeploy'
  params: {
    blobContainerName: blobContainerName
    resourceName: dataFactoryDatasetInName
    dataFactoryName: resourceName
    fileName: fileName
    folderPath: 'input'
    linkedServiceName: linkedServiceName
  }
}

//Create datasetOut using blob storage
module dataSetsOut 'Factories/datasets.bicep' = {
  name: 'DatasetOutDeploy'
  params: {
    blobContainerName: blobContainerName
    resourceName: dataFactoryDatasetOutName
    dataFactoryName: resourceName
    fileName: ''
    folderPath: 'output'
    linkedServiceName: linkedServiceName
  }
}

//Creates simple plieline that copies one file from a location to another.
module pipeline 'Factories/pipeline.bicep' = {
  name: '${pipelineName}Deploy'
  params: {
    dataFactoryname: resourceName
    dataSetInName: dataSetsIn.name
    dataSetOutName: dataSetsOut.name
    pipelineName: pipelineName
  }
}

