metadata name = 'SMB Landing Zone - Networking Module'
metadata description = 'Deploys the VNET with conditional subnets, NSGs, and route tables.'

// =============================================
// Parameters
// =============================================

@description('Azure region.')
param location string

@description('Naming prefix.')
param namePrefix string

@description('Tags.')
param tags object

@description('VNET address prefix.')
param vnetAddressPrefix string

@description('Workload subnet address prefix.')
param workloadSubnetPrefix string

@description('Gateway subnet address prefix.')
param gatewaySubnetPrefix string

@description('Firewall subnet address prefix.')
param firewallSubnetPrefix string

@description('Bastion subnet address prefix.')
param bastionSubnetPrefix string

@description('DNS Resolver inbound subnet prefix.')
param dnsInboundSubnetPrefix string

@description('DNS Resolver outbound subnet prefix.')
param dnsOutboundSubnetPrefix string

@description('Deploy Bastion subnet.')
param deployBastion bool

@description('Deploy Firewall subnet.')
param deployFirewall bool

@description('Deploy Gateway subnet.')
param deployGateway bool

@description('Deploy DNS Resolver.')
param deployDnsResolver bool

@description('Deploy DNS inbound endpoint.')
param deployDnsInboundEndpoint bool

@description('Deploy DNS outbound endpoint.')
param deployDnsOutboundEndpoint bool

@description('Log Analytics Workspace resource ID.')
param logAnalyticsWorkspaceId string

@description('Azure Firewall private IP for UDR. Empty string if no firewall.')
param firewallPrivateIp string

// =============================================
// Variables
// =============================================

var vnetName = 'vnet-${namePrefix}'

// Build subnet array conditionally
var gatewaySubnet = deployGateway
  ? [
      {
        name: 'GatewaySubnet'
        addressPrefix: gatewaySubnetPrefix
      }
    ]
  : []

var firewallSubnet = deployFirewall
  ? [
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: firewallSubnetPrefix
      }
    ]
  : []

var bastionSubnet = deployBastion
  ? [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: bastionSubnetPrefix
        networkSecurityGroupResourceId: nsgBastion.?outputs.?resourceId ?? ''
      }
    ]
  : []

var dnsInboundSubnet = deployDnsResolver && deployDnsInboundEndpoint
  ? [
      {
        name: 'snet-dns-inbound'
        addressPrefix: dnsInboundSubnetPrefix
        delegations: [
          {
            name: 'Microsoft.Network.dnsResolvers'
            properties: {
              serviceName: 'Microsoft.Network/dnsResolvers'
            }
          }
        ]
      }
    ]
  : []

var dnsOutboundSubnet = deployDnsResolver && deployDnsOutboundEndpoint
  ? [
      {
        name: 'snet-dns-outbound'
        addressPrefix: dnsOutboundSubnetPrefix
        delegations: [
          {
            name: 'Microsoft.Network.dnsResolvers'
            properties: {
              serviceName: 'Microsoft.Network/dnsResolvers'
            }
          }
        ]
      }
    ]
  : []

var workloadSubnet = [
  {
    name: 'snet-workload'
    addressPrefix: workloadSubnetPrefix
    networkSecurityGroupResourceId: nsgWorkload.outputs.resourceId
    routeTableResourceId: deployFirewall ? (routeTable.?outputs.?resourceId ?? '') : null
  }
]

var allSubnets = union(
  gatewaySubnet,
  firewallSubnet,
  bastionSubnet,
  dnsInboundSubnet,
  dnsOutboundSubnet,
  workloadSubnet
)

// =============================================
// NSG - Workload Subnet
// =============================================

module nsgWorkload 'br/public:avm/res/network/network-security-group:0.5.3' = {
  params: {
    name: 'nsg-${namePrefix}-workload'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
  }
}

// =============================================
// NSG - Bastion Subnet (required rules per Azure docs)
// =============================================

module nsgBastion 'br/public:avm/res/network/network-security-group:0.5.3' = if (deployBastion) {
  params: {
    name: 'nsg-${namePrefix}-bastion'
    location: location
    tags: tags
    securityRules: [
      // Inbound rules
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          priority: 130
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 140
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInbound'
        properties: {
          priority: 150
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: ['8080', '5701']
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      // Outbound rules
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['22', '3389']
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
        }
      }
      {
        name: 'AllowBastionHostCommunicationOutbound'
        properties: {
          priority: 120
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: ['8080', '5701']
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowGetSessionInformationOutbound'
        properties: {
          priority: 130
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
  }
}

// =============================================
// Route Table (for workload subnet when firewall is deployed)
// =============================================

module routeTable 'br/public:avm/res/network/route-table:0.5.0' = if (deployFirewall) {
  params: {
    name: 'rt-${namePrefix}-workload'
    location: location
    tags: tags
    routes: [
      {
        name: 'default-via-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

// =============================================
// Virtual Network
// =============================================

module vnet 'br/public:avm/res/network/virtual-network:0.7.2' = {
  params: {
    name: vnetName
    location: location
    tags: tags
    addressPrefixes: [vnetAddressPrefix]
    subnets: allSubnets
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

output vnetId string = vnet.outputs.resourceId
output vnetName string = vnet.outputs.name
output workloadSubnetId string = vnet.outputs.subnetResourceIds[length(allSubnets) - 1]
output dnsInboundSubnetId string = deployDnsResolver && deployDnsInboundEndpoint
  ? vnet.outputs.subnetResourceIds[length(gatewaySubnet) + length(firewallSubnet) + length(bastionSubnet)]
  : ''
output dnsOutboundSubnetId string = deployDnsResolver && deployDnsOutboundEndpoint
  ? vnet.outputs.subnetResourceIds[length(gatewaySubnet) + length(firewallSubnet) + length(bastionSubnet) + length(dnsInboundSubnet)]
  : ''
