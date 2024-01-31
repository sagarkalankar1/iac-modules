// Bicep template for deploying Static Web App

@description('Provide Naming Convention parameter for the Static Web App')
param namingConventionProperties object = {}

@description('Provide application/resource short name for the Static Web App')
param shortName string = ''

@description('Provide name for the Static Web App')
param resourceName string = ''

@description('Provide Private Endpoint Suffix for the Static Web App')
param privEndpointSuffix string = 'ep01' 

@description('Metadata for creating Private Endpoint for Static Web App. Required Keys: [ sharedResourceGroup, privEndpointSubnetName, sharedVnetName, pvtDnsZone{}.resourceGroupName, pvtDnsZone{}.subscriptionId ] Optional Keys [ pvtDnsZone{}.zoneName ] ')
param stappMetadata object

@description('Location for deployment')
param location string 

@description('URL + Branch for Git hub repo storing code of Static Web App')
param repoURL string = ''

param branch string = ''

@description('GIT Personal Access Token')
param GitPAT string = ''

@description('Tags for the resource')
param tags object

@description('SKU Name + Tier')
@allowed([
  'Free'
  'Standard'
  'Premium'
])
param skuName string

@description('SKU Tier for Static Web App')
@allowed([
  'Free'
  'Standard'
  'Premium'
])
param skuTier string = skuName

// TODO: JIRA PLT-28516 : Check with Security team to host some static website over public. If not, this param will be removed and simply make it with Pvt Endpoint only.
@description('Control Public Network Access')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetAccess string = 'Disabled'

@description('Location for Private Endpoint (Should be same as the Vnet)')
param privEndpointLocation string

@description('Instrumentaion Key to link App Insight')
param appInsightsName string

// Currently only supports the SystemAssigned. 
// In future we will have capability to use UserAssigned Managed Service Identity.
@description('Type of Managed Service Identity.')
@allowed([
    'SystemAssigned'
//  'None'
//  'SystemAssigned, UserAssgined'
//  'UserAssgined'
])
param identityType string = 'SystemAssigned'


var typeOfResource = 'stapp'

var finalResourceName = (resourceName == '') ? ((shortName == '') ? '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${namingConventionProperties.environment}' : '${namingConventionProperties.subscriptionName}-${namingConventionProperties.projectCode}-${typeOfResource}-${shortName}-${namingConventionProperties.environment}' ) : resourceName


@description('User Defined Function to generate Subnet ID based on Subscription ID Resource Group Name Vnet Name and Subnet Name')
func generateSubnetId(subscriptionId string, resourceGroup string, vnetName string, subnetName string) string => '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName 
}


// Creating Static Web App
resource staticWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: finalResourceName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties:{
    repositoryUrl: repoURL
    branch: branch
    repositoryToken: GitPAT
    publicNetworkAccess: publicNetAccess
  }
  identity: {
    type: identityType
  }
  tags: tags
}

//JIRA => PLT-34711: Managing Private DNS Zone Name for static web app based on Microsoft assigned URL.
var hostName = staticWebApp.properties.defaultHostname

var domainParts = split(hostName, '.')

var l = length(domainParts)

var overridenDNSZoneMetadata = {
      subscriptionId: stappMetadata.pvtDnsZone.subscriptionId
      resourceGroupName: stappMetadata.pvtDnsZone.resourceGroupName
      zoneName:  'privateLink.${domainParts[l-3]}.${domainParts[l-2]}.${domainParts[l-1]}'
    } 

// Creating Static Web App Private Endpoint
module privateEndPoint '../Network/privateEndpoint.bicep' = {
  name: '${finalResourceName}PrivEndPoint'
  params: {
    pvtDnsZone:( ( contains(stappMetadata.pvtDnsZone, 'zoneName' ) ) ? ( ( empty(stappMetadata.pvtDnsZone.zoneName) ) ? overridenDNSZoneMetadata : stappMetadata.pvtDnsZone ) : overridenDNSZoneMetadata )
    groupId: 'staticSites'
    resourceName: '${finalResourceName}-${privEndpointSuffix}'
    resourceId: staticWebApp.id
    subnetId: generateSubnetId(subscription().subscriptionId,stappMetadata.sharedResourceGroup,stappMetadata.sharedVnetName,stappMetadata.privEndpointSubnetName)
    location: privEndpointLocation
    tags: tags
  }
}


resource appServiceConfig 'Microsoft.Web/staticSites/config@2022-03-01' = {
  name: 'appsettings'
  parent: staticWebApp
  kind: 'app'
  properties: {
    APPINSIGHT_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
  }
}


output staticWebApp object = {
  name: staticWebApp.name
  id: staticWebApp.id
}


output privateEndPoint object = {
  name: privateEndPoint.outputs.privateEndpoint.name
  id: privateEndPoint.outputs.privateEndpoint.id
  dnsId: privateEndPoint.outputs.privateEndpoint.dnsId
}
