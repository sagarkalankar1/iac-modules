//Create pinpeline for datafactory for blob storage.

@description('Name of the Data Factory')
param dataFactoryname string

@description('Name of the pipeline')
param pipelineName string

@description('Name of Data Set Input')
param dataSetInName string

@description('Name of Data Set Out')
param dataSetOutName string


resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryname
}

resource dataFactoryPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactory
  name: pipelineName
  properties: {
    activities: [
      {
        name: 'MyCopyActivity'
        type: 'Copy'
        typeProperties: {
          source: {
            type: 'BinarySource'
            storeSettings: {
              type: 'AzureBlobStorageReadSettings'
              recursive: true
            }
          }
          sink: {
            type: 'BinarySink'
            storeSettings: {
              type: 'AzureBlobStorageWriteSettings'
            }
          }
          enableStaging: false
        }
        inputs: [
          {
            referenceName: dataSetInName
            type: 'DatasetReference'
          }
        ]
        outputs: [
          {
            referenceName: dataSetOutName
            type: 'DatasetReference'
          }
        ]
      }
    ]
  }
}
