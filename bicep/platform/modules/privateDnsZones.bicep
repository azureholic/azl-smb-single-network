metadata name = 'SMB Landing Zone - Private DNS Zones Module'
metadata description = 'Deploys all standard Azure Private Link Private DNS Zones using the AVM pattern module.'

// =============================================
// Parameters
// =============================================

@description('Azure region.')
param location string

@description('Tags.')
param tags object

@description('Virtual Network resource ID to link DNS zones to.')
param virtualNetworkResourceId string

// =============================================
// Private Link Private DNS Zones (all standard zones)
// =============================================

module privateLinkDnsZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.7.2' = {
  params: {
    location: location
    tags: tags
    virtualNetworkResourceIdsToLinkTo: [virtualNetworkResourceId]
  }
}

// =============================================
// Outputs
// =============================================

output resourceGroupName string = privateLinkDnsZones.outputs.resourceGroupName
