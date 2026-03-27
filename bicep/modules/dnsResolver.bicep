metadata name = 'SMB Landing Zone - DNS Resolver Module'
metadata description = 'Deploys Private DNS Resolver with optional inbound and outbound endpoints.'

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

@description('Deploy inbound endpoint.')
param deployInboundEndpoint bool

@description('Deploy outbound endpoint.')
param deployOutboundEndpoint bool

@description('Inbound endpoint subnet resource ID.')
param inboundSubnetId string

@description('Outbound endpoint subnet resource ID.')
param outboundSubnetId string

// =============================================
// Variables
// =============================================

var inboundEndpoints = deployInboundEndpoint
  ? [
      {
        name: 'inbound'
        subnetResourceId: inboundSubnetId
      }
    ]
  : []

var outboundEndpoints = deployOutboundEndpoint
  ? [
      {
        name: 'outbound'
        subnetResourceId: outboundSubnetId
      }
    ]
  : []

// =============================================
// Private DNS Resolver
// =============================================

module dnsResolver 'br/public:avm/res/network/dns-resolver:0.5.6' = {
  params: {
    name: 'dnspr-${namePrefix}'
    location: location
    tags: tags
    virtualNetworkResourceId: virtualNetworkResourceId
    inboundEndpoints: inboundEndpoints
    outboundEndpoints: outboundEndpoints
  }
}

// =============================================
// DNS Forwarding Ruleset (if outbound endpoint exists)
// =============================================

module dnsForwardingRuleset 'br/public:avm/res/network/dns-forwarding-ruleset:0.5.3' = if (deployOutboundEndpoint) {
  params: {
    name: 'dnsfrs-${namePrefix}'
    location: location
    tags: tags
    dnsForwardingRulesetOutboundEndpointResourceIds: [
      '${dnsResolver.outputs.resourceId}/outboundEndpoints/outbound'
    ]
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: virtualNetworkResourceId
      }
    ]
  }
}

// =============================================
// Outputs
// =============================================

output dnsResolverId string = dnsResolver.outputs.resourceId
output dnsResolverName string = dnsResolver.outputs.name
