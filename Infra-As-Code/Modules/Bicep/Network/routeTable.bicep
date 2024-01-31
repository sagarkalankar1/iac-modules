//Bicep template for Routetables + routes deploy
// We have kept this module as a placeholder and have not tested the implementation and reviewed for how exact it should be designed.

@description('Name of the Route Table')
param resourceName string

@description('Location for the Route Table')
param location string

@description('Tags for the Resource')
param tags object

@description('Whether to disable the routes learned by BGP on that route table. True means disable.')
param disableBgpRoutePropagation bool

@description('Name of the Route')
param routeName string

@description('The destination CIDR to which the Route applies.')
param addressPrefix string

@description('The IP address packets should be forwarded to.')
param nextHopIpAddress string

@description('The type of Azure hop the packet should be sent to.')
param nextHopType string

//Create route table 
resource routeTable 'Microsoft.Network/routeTables@2022-09-01' = {
  name: resourceName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: [ //Create routes
      {
        name: routeName
        properties: {
          addressPrefix: addressPrefix
          nextHopIpAddress: nextHopIpAddress
          nextHopType: nextHopType
        }
      }
    ]
  }
}

output UDR object = {
  name: routeTable.name
  id: routeTable.id
  routes: routeTable.properties.routes
}
