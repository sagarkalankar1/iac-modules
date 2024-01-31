// Bicep template for SQL managed instance

@description('The name of the SQL managed instance.')
param resourceName string = ''

@description('Provide Naming Convention parameter for the SQL managed instance')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the SQL managed instance.')
param shortName string = ''

@description('Location for the SQL managed instance.')
param location string

@description('Provide Private Endpoint Suffix for the App Service')
param privEndpointSuffix string = 'ep01'

@description('Tags for the resource')
param tags object

// We can find the possible values from Azure portal which you can provide for SKU Size
// Please find the possible values which you can use as per each SKU Tier
// - System: 0
// - GP_SYSTEM: 2, 4, 8
// - Free: 5
// - Basic: 5
// - Standard: 10, 20, 50, 100, 200, 400, 800, 1600, 3000
// - Premium: 125, 250, 500, 1000, 1750, 4000
// - Stretch: 750, 1500, 2250, 3000, 3750, 4500, 7500, 9000, 11250, 15000
// - DataWarehouse: 900, 1800, 2700, 3600, 4500, 9000, 13500, 18000, 22500, 27000, 45000, 54000, 67500, 90000, 135000, 270000
// - GP_S_Gen5: 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 80
// - GP_Gen5: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 80, 128
// - BC_Gen5: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 80, 128
// - HS_Gen5: 2, 4, 6, 8, 10, 12, 16, 18, 20, 24, 32, 40, 80
// - HS_S_Gen5: 2, 4, 6, 8, 10, 12, 16, 18, 20, 24, 32, 40, 80
// - HS_PRMS: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 64, 80, 128
// - HS_MOPRMS: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 64, 80
// You can also execute below commands to get the details of allowed values for Capacity based on the Sku
// Azure CLI: az sql db list-editions -l {location} -o table
// Azure PowerShell: Get-AzSqlServerServiceObjective -Location {location}
@description('Capacity of the particular SKU')
param skuCapacity int = 0

// You can also execute below commands to get the details of allowed values for Family based on the Sku
// Azure CLI: az sql db list-editions -l {location} -o table
// Azure PowerShell: Get-AzSqlServerServiceObjective -Location {location}
@allowed([
  'Gen5'
  '8IM'
  '8IH'
  ''
])
@description('If the service has different generations of hardware, for the same SKU, then that can be captured here.')
param skuFamily string = 'Gen5'

// You can also execute below commands to get the details of allowed values for Name based on the Sku
// Azure CLI: az sql db list-editions -l {location} -o table
// Azure PowerShell: Get-AzSqlServerServiceObjective -Location {location}
@allowed([
  'System'
  'GP_SYSTEM'
  'Free'
  'Basic'
  'Standard'
  'Premium'
  'DataWarehouse'
  'Stretch'
  'GP_S_Gen5'
  'GP_Gen5'
  'BC_Gen5'
  'HS_Gen5'
  'HS_S_Gen5'
  'HS_PRMS'
  'HS_MOPRMS'
])
@description('The name of the SKU, typically, a letter + Number code, e.g. P3.')
param skuName string = 'Basic'

// We can find the possible values from Azure portal which you can provide for SKU Size
// Please find the possible values which you can use as per each SKU Tier
// - GeneralPurpose: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 80, 128
// - Hyperscale: 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 80
// - BusinessCritical: 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 40, 80, 128
// - Basic: 50, 100, 200, 400, 800,, 1200, 1600
// - Standard: 50, 100, 200, 400, 800,, 1200, 1600, 2000, 2500, 3000
// - Premium: 125, 250, 500, 1000, 1500, 2000, 2500, 3000, 3500,4000
@description('Size of the particular SKU')
param skuSize string = '50'

// You can also execute below commands to get the details of allowed values for Tier based on the Sku
// Azure CLI: az sql db list-editions -l {location} -o table
// Azure PowerShell: Get-AzSqlServerServiceObjective -Location {location}
@description('The tier or edition of the particular SKU, e.g. Basic, Premium.')
@allowed([
  'System'
  'Free'
  'Basic'
  'Standard'
  'Premium'
  'DataWarehouse'
  'Stretch'
  'GeneralPurpose'
  'BusinessCritical'
  'Hyperscale'
])
param skuTier string = 'Basic'

@description('Specifies the mode of database creation.')
@allowed([
  'Default'
  'Secondary'
])
param createMode string = 'Default'

@description('Collation of the metadata catalog.')
@allowed([
  'DATABASE_DEFAULT'
  'SQL_Latin1_General_CP1_CI_AS'
])
param catalogCollation string = 'DATABASE_DEFAULT'

@description('The name of the elastic pool containing this database.')
param serverElasticPoolName string = ''

// It's only applicable when SKU Tier is 'Hyperscale'
@allowed([
  0
  1
  2
  3
  4
])
@description('The number of secondary replicas associated with the SQL Database that are used to provide high availability. Applicable only to Hyperscale SQL Databases.')
param highAvailabilityReplicaCount int = 0

@description('Whether or not this database is a ledger database, which means all tables in the database are ledger tables. Note: the value of this property cannot be changed after the database has been created.')
param isLedgerOn bool = false

@description('The license type to apply for this SQL Database.')
@allowed([
  'BasePrice'
  'LicenseIncluded'
])
param licenseType string = 'LicenseIncluded'

// We can find the possible values from Azure portal which you can provide for Max Size(Bytes)
@description('The storage limit for the database SQL Database in bytes.')
param maxSizeBytes int = 268435456000

// We can find the possible values from Azure portal which you can provide for Min Capacity
@description('Minimal capacity that serverless pool will not shrink below, if not paused')
param minCapacity int = 0

@description('The state of read-only routing. If enabled, connections that have application intent set to readonly in their connection string may be routed to a readonly secondary replica in the same region. Not applicable to a Hyperscale database within an elastic pool.')
@allowed([
  'Disabled'
  'Enabled'
])
param readScale string = 'Disabled'

@description('The storage account type to be used to store backups for this database.')
@allowed([
  'Geo'
  'GeoZone'
  'Local'
  'Zone'
])
param requestedBackupStorageRedundancy string = 'Zone'

@description('Whether or not this database is zone redundant, which means the replicas of this database will be spread across multiple availability zones.')
param zoneRedundant bool = false

@description('Time in minutes after which database is automatically paused. A value of -1 means that automatic pause is disabled')
param autoPauseDelay int = -1

@description('Metadata for creating Private Endpoint for SQL managed instance. Required Keys: [ sharedResourceGroup, privEndpointSubnetName, sharedVnetName, pvtDnsZone{}.resourceGroupName, pvtDnsZone{}.subscriptionId ] Optional Keys [ pvtDnsZone{}.zoneName ]')
param sqlDbMetadata object

@description('Type of enclave requested on the database i.e. Default or VBS enclaves.')
@allowed([
  'Default'
  'VBS'
])
param preferredEnclaveType string = 'Default'

@description('The secondary type of the database if it is a secondary. Valid values are Geo, Named and Standby.')
@allowed([
  'Geo'
  'Named'
  'Standby'
])
param secondaryType string = 'Standby'

//TODO: JIRA PLT-28423 : We will add the support for setting userassigned Service Identity in future
@description('Type of Managed Service Identity')
@allowed([
  'None'
  // 'UserAssgined'    //==> array of user assigned identities.
])
param identityType string = 'None'

@description('Parent SQL Server Name')
param sqlServerName string


var typeOfResource = 'sql-db'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


@description('User Defined Function to generate Subnet ID based on Subscription ID Resource Group Name Vnet Name and Subnet Name')
func generateSubnetId(subscriptionId string, resourceGroup string, vnetName string, subnetName string) string => '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'


// Referring to an already existing SQL server
resource sqlServer 'Microsoft.Sql/servers@2022-08-01-preview' existing = {
  name: sqlServerName 
}

resource sqlServerElasticPool 'Microsoft.Sql/servers/elasticPools@2021-02-01-preview' existing = {
  name: serverElasticPoolName
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: finalResourceName
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
  identity: {
    type: identityType
  }
  properties: {
    autoPauseDelay: autoPauseDelay
    catalogCollation: catalogCollation
    createMode: createMode
    elasticPoolId: serverElasticPoolName != '' ? resourceId('Microsoft.Sql/servers/elasticpools', sqlServer.name, sqlServerElasticPool.name) : ''
    highAvailabilityReplicaCount: highAvailabilityReplicaCount
    isLedgerOn: isLedgerOn
    licenseType: licenseType
    maxSizeBytes: maxSizeBytes
    minCapacity: minCapacity
    readScale: readScale
    requestedBackupStorageRedundancy: requestedBackupStorageRedundancy
    secondaryType: secondaryType
    zoneRedundant: zoneRedundant
  }
}

module subnetIDGenPrivEndpoint '../../Common/subnetIdGen.bicep' = {
  name: 'privEndpointIntegration'
  params: {
    resourceGroup: sqlDbMetadata.sharedResourceGroup
    subnetName: sqlDbMetadata.privEndpointSubnetName
    vnetName: sqlDbMetadata.sharedVnetName
    subscriptionId: subscription().subscriptionId
  }
}

module privateEndPoint '../../Network/privateEndpoint.bicep' = {
  name: '${finalResourceName}PrivEndPoint'
  params: {
    pvtDnsZone: sqlDbMetadata.pvtDnsZone
    groupId: 'sqlServer'
    resourceName: '${finalResourceName}-${privEndpointSuffix}'
    resourceId: sqlServer.id
    subnetId: generateSubnetId(subscription().subscriptionId,sqlDbMetadata.sharedResourceGroup,sqlDbMetadata.sharedVnetName,sqlDbMetadata.privEndpointSubnetName)
    location: location
    tags: tags
  }
}

output sqlDatabase object = {
  name: sqlDatabase.name
  id: sqlDatabase.id
}
