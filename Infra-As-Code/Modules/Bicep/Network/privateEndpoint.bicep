//Bicep template for Private end points for any resource

@description('Name of the Private Endpoint')
param resourceName string

@description('Location for all resources.')
param location string

@description('Id of the resource that needs private endpoint')
param resourceId string // = *resource*.id

// TODO: Conditional logic to pick DNS Name based on the group ID 
@description('Group Id for the type of resource')
@allowed([
  'sites' //for app service 
  'vault' //for kv
  'blob'
  'table'
  'queue'
  'file'
  'Sql'
  'file'
  'staticSites'
  'sqlServer'
  'MongoDB'
])
param groupId string

@description('Id of the subnet for the Private Endpoint')
param subnetId string 

@description('Tags for the resource')
param tags object

@description('Metadata for Private DNS Zone ID. Required Keys: [ subscriptionId, resourceGroupName ] Optional Keys [ zoneName ]')
param pvtDnsZone object


/*
TODO: Try and seperate the conditions to make it look less clustered and more organised.
// Opiniated Pvt DNS Zone name for Azure Site = 'privatelink.azurewebsites.net'
privateDnsZoneName = (groupId == 'sites') ? 'privatelink.azurewebsites.net' : privateDnsZoneName

// Opiniated Pvt DNS Zone name for Azure Site = 'privatelink.azurewebsites.net'
privateDnsZoneName = (groupId == 'vault') ? 'privatelink.vaultcore.azure.net' : privateDnsZoneName
*/
var privateDnsZoneName = ( (groupId == 'sites') ? 'privatelink.azurewebsites.net' : ( (groupId == 'vault') ? 'privatelink.vaultcore.azure.net' : ( (groupId == 'blob') ? 'privatelink.blob.core.windows.net' :  ( (groupId == 'file')  ?  'privatelink.file.core.windows.net' : ( (groupId == 'sqlServer') ? 'privatelink.database.windows.net' : ( (groupId == 'Sql') ? 'privatelink.documents.azure.com' : ( (groupId == 'MongoDB') ? 'privatelink.mongo.cosmos.azure.com':((groupId == 'table') ? 'privatelink.table.core.windows.net': ((groupId == 'queue') ? 'privatelink.queue.core.windows.net': '' )))))))))

@description('DNS Zone Name for function dnsZoneIdPrefix')
var privDnsZoneName = ( (contains(pvtDnsZone, 'zoneName' ) ) ? ( ( empty(pvtDnsZone.zoneName) ) ? privateDnsZoneName : pvtDnsZone.zoneName ) : privateDnsZoneName )


@description('User Defined Function to generate Dns Zone Id Prefix based on Subscription ID Resource Group Name DNS Zone Name')
func generateDnsZoneIdPrefix(resourceGroup string, subscriptionId string, privDnsZoneName string) string => '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Network/privateDnsZones/${privDnsZoneName}'

//Creating private end point 
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: resourceName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: resourceName
        properties: {
          privateLinkServiceId: resourceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
  tags: tags
}


resource privateEndpointPrivDNSZone 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-11-01' = {
  name: 'privateEndpointPrivDNSZoneDeploy'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs:[
      {
        name: '${privateEndpoint.name}-priv-dns-zone'
        properties: {
          privateDnsZoneId: generateDnsZoneIdPrefix(pvtDnsZone.resourceGroupName, pvtDnsZone.subscriptionId, privDnsZoneName)
        }
      }
    ]
  }
}

output privateEndpoint object = {
  name: privateEndpoint.name
  id: privateEndpoint.id
  dnsId: privateEndpointPrivDNSZone.id
}
