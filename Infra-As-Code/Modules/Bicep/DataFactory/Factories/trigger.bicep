//Bicep for blobTrigger
@description('Data Factory name ')
param datafactoryName string

@description('Data Factory Trigger name')
param dataFactoryTriggerName string

@description('Pipeline name')
param pipelineName string

@description('Reference pipeline name.')
param pipelineReferenceName string

@description('The path of the container/folder that will trigger the pipeline.')
param folderPath string

@description('Reference LinkedService name.')
param linkedServiceReferenceName string

@description('The max number of parallel files to handle when it is triggered.')
param maxConcurrency int

resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactoryName
}

resource trigger 'Microsoft.DataFactory/factories/triggers@2018-06-01' = {
  name: dataFactoryTriggerName
  parent: datafactory
  properties: {
    annotations: []
    type: 'BlobTrigger'
  pipelines: [
    {
      parameters: {}
      pipelineReference: {
        name: pipelineName
        referenceName: pipelineReferenceName
        type: 'PipelineReference'
      }
    }
  ]
  typeProperties: {
    folderPath: folderPath
    linkedService: {
      parameters: {}
      referenceName: linkedServiceReferenceName
      type: 'LinkedServiceReference'
    }
    maxConcurrency: maxConcurrency
  }
  }
}
