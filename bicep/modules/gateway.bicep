metadata name = 'SMB Landing Zone - Gateway Module'
metadata description = 'Deploys a VPN or ExpressRoute Gateway.'

// =============================================
// Parameters
// =============================================

@description('Azure region.')
param location string

@description('Naming prefix.')
param namePrefix string

@description('Tags.')
param tags object

@description('Virtual Network resource ID.')
param virtualNetworkResourceId string

@description('Gateway type: Vpn or ExpressRoute.')
@allowed(['Vpn', 'ExpressRoute'])
param gatewayType string

@description('Gateway SKU name.')
param skuName string

@description('Log Analytics Workspace resource ID.')
param logAnalyticsWorkspaceId string

// =============================================
// Variables
// =============================================

var gatewayName = gatewayType == 'Vpn' ? 'vpngw-${namePrefix}' : 'ergw-${namePrefix}'

// =============================================
// Virtual Network Gateway
// =============================================

module gateway 'br/public:avm/res/network/virtual-network-gateway:0.10.1' = {
  params: {
    name: gatewayName
    location: location
    tags: tags
    gatewayType: gatewayType
    skuName: skuName
    virtualNetworkResourceId: virtualNetworkResourceId
    clusterSettings: {
      clusterMode: 'activePassiveNoBgp'
    }
    vpnType: gatewayType == 'Vpn' ? 'RouteBased' : null
    vpnGatewayGeneration: gatewayType == 'Vpn' ? 'Generation2' : null
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
  }
}

// =============================================
// Outputs
// =============================================

output gatewayId string = gateway.outputs.resourceId
output gatewayName string = gateway.outputs.name
