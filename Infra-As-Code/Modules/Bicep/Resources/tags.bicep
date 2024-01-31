param defaultTags object

@allowed([
  'dev'
  'qa'
  'uat'
  'prod'
])
param environment string

param deploymentDate string = utcNow('yyyy-MM-dd')

// targetScope = 'resourceGroup'

var tagsObject = {
  'Application Owner': defaultTags.applicationOwner
  'Application Name' : defaultTags.applicationName
  'Business Unit': defaultTags.businessUnit
  'Cost Center': defaultTags.costCenter
  'Environment': environment
  'Deployment Date': deploymentDate
}

resource applyDefaultTags 'Microsoft.Resources/tags@2021-04-01' = {
  name: 'default'
  properties: {
    tags: tagsObject
  }
}

// output Tags object = tagsObject
