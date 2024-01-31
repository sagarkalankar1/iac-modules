// Bicep template for SQL Server

@description('The name of the SQL logical server.')
param resourceName string = ''

@description('Provide Naming Convention parameter for the SQL server')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the SQL server.')
param shortName string = ''

@description('Location for the SQL Server.')
param location string

@description('Tags for the resource')
param tags object

// Raised the support case for getting possible allowed parameters for SKU Capacity. Please find support case number below:
// Support number: 2306140030005067
@description('Capacity of the particular SKU')
param skuCapacity int

// Raised the support case for getting possible allowed parameters for SKU Family. Please find support case number below:
// Support number: 2306140030005067
// Note: You only need to mention the family when you are using the SKU Tier GeneralPurpose, BusinessCritical and Hyperscale. 
@allowed([
  'Gen5'
  'DC'
  'M'
  'Fsv2'
])
@description('If the service has different generations of hardware, for the same SKU, then that can be captured here.')
param skuFamily string = 'Gen5'

@allowed([
  'BasicPool'
  'PremiumPool'
  'StandardPool'
  'HS_Gen5'
  'BC_Gen5'
  'BC_DC'
  'BC_M'
  'GP_Gen5'
  'GP_Fsv2'
  'GP_DC'
])
@description('The name of the SKU, typically, a letter + Number code, e.g. P3.')
param skuName string = 'BasicPool'

// We can find the possible values from Azure portal which you can provide for SKU Size
// Please find the possible values which you can use as per each SKU Tier
// - GeneralPurpose: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 80, 128
// - Hyperscale: 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 80
// - BusinessCritical: 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 80, 128
// - Basic: 50, 100, 200, 400, 800,, 1200, 1600
// - Standard: 50, 100, 200, 400, 800,, 1200, 1600, 2000, 2500, 3000
// - Premium: 125, 250, 500, 1000, 1500, 2000, 2500, 3000, 3500,4000
@description('Size of the particular SKU')
param skuSize string

@description('The tier or edition of the particular SKU, e.g. Basic, Premium.')
@allowed([
  'GeneralPurpose'
  'BusinessCritical'
  'Hyperscale'
  'Basic'
  'Premium'
  'Standard'
])
param skuTier string = 'Basic'

// It's only applicable when SKU Tier is 'Hyperscale'
@allowed([
  0
  1
  2
  3
  4
])
@description('The number of secondary replicas associated with the elastic pool that are used to provide high availability. Applicable only to Hyperscale elastic pools.')
param elasticPoolHighAvailabilityReplicaCount int

@description('The license type to apply for this elastic pool.')
@allowed([
  'BasePrice'
  'LicenseIncluded'
])
param elasticPoolLicenseType string

// We can find the possible values from Azure portal which you can provide for Max Size(Bytes)
@description('The storage limit for the database elastic pool in bytes.')
param elasticPoolMaxSizeBytes int

// We can find the possible values from Azure portal which you can provide for Min Capacity
@description('Minimal capacity that serverless pool will not shrink below, if not paused')
param elasticPoolMinCapacity int

@description('Whether or not this elastic pool is zone redundant, which means the replicas of this elastic pool will be spread across multiple availability zones.')
param elasticPoolZoneRedundant bool

// We can find the possible values from Azure portal which you can provide for Per Database Max Capacity
@description('The maximum capacity any one database can consume.')
param elasticPoolPerDatabaseMaxCapacity int

// We can find the possible values from Azure portal which you can provide for Per Database Min Capacity
@description('The minimum capacity all databases are guaranteed.')
param elasticPoolPerDatabaseMinCapacity int

@description('Parent SQL Server Name')
param sqlServerName string

var typeOfResource = 'ep'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName

// Referring to an already existing SQL server
resource sqlServer 'Microsoft.Sql/servers@2022-08-01-preview' existing = {
  name: sqlServerName 
}

resource sqlServerElasticPool 'Microsoft.Sql/servers/elasticPools@2022-05-01-preview' = {
  name: '${finalResourceName}'
  location: location
  tags: tags
  sku: {
    capacity: skuCapacity
    family: skuFamily
    name: skuName
    size: skuSize
    tier: skuTier
  }
  parent: sqlServer
  properties: {
    highAvailabilityReplicaCount: elasticPoolHighAvailabilityReplicaCount
    licenseType: elasticPoolLicenseType
    maxSizeBytes: elasticPoolMaxSizeBytes
    minCapacity: elasticPoolMinCapacity
    perDatabaseSettings: {
      maxCapacity: elasticPoolPerDatabaseMaxCapacity
      minCapacity: elasticPoolPerDatabaseMinCapacity
    }
    zoneRedundant: elasticPoolZoneRedundant
  }
}

output sqlServerElasticPool object = {
  name: sqlServerElasticPool.name
  id: sqlServerElasticPool.id
}
