targetScope = 'subscription'

metadata name = 'SMB Single-Network Landing Zone'
metadata description = 'Deploys an SMB landing zone with a single VNET, logging, private DNS zones, optional features (Bastion, Firewall, VPN/ER Gateway, DNS Resolver), and ALZ policy assignments.'

// =============================================
// Parameters
// =============================================

@description('Azure region for all resources.')
param location string

@description('Environment identifier used in resource naming.')
@allowed(['dev', 'test', 'prod'])
param environment string = 'prod'

@description('Short workload name used in resource naming.')
@maxLength(10)
param workloadName string = 'smb'

@description('Tags to apply to all resources.')
param tags object = {}

// Logging parameters
@description('Log Analytics workspace retention in days.')
@minValue(30)
@maxValue(730)
param logRetentionInDays int = 90

@description('Log Analytics workspace SKU.')
@allowed(['PerGB2018', 'CapacityReservation'])
param logAnalyticsSku string = 'PerGB2018'

// Networking parameters
@description('VNET address prefix.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Gateway subnet address prefix.')
param gatewaySubnetPrefix string = '10.0.0.0/27'

@description('Azure Firewall subnet address prefix.')
param firewallSubnetPrefix string = '10.0.0.64/26'

@description('Azure Bastion subnet address prefix.')
param bastionSubnetPrefix string = '10.0.1.0/26'

@description('DNS Resolver inbound endpoint subnet address prefix.')
param dnsInboundSubnetPrefix string = '10.0.1.64/28'

@description('DNS Resolver outbound endpoint subnet address prefix.')
param dnsOutboundSubnetPrefix string = '10.0.1.80/28'

@description('Workload subnet address prefix.')
param workloadSubnetPrefix string = '10.0.10.0/24'

// Optional feature flags
@description('Deploy Azure Bastion.')
param deployBastion bool = false

@description('Deploy Azure Firewall.')
param deployFirewall bool = false

@description('Azure Firewall SKU tier.')
@allowed(['Basic', 'Standard', 'Premium'])
param firewallSkuTier string = 'Standard'

@description('Azure Firewall expected private IP (4th IP in AzureFirewallSubnet). Must match firewallSubnetPrefix.')
param firewallPrivateIp string = '10.0.0.68'

@description('Deploy VPN Gateway.')
param deployVpnGateway bool = false

@description('VPN Gateway SKU.')
@allowed(['VpnGw1', 'VpnGw1AZ', 'VpnGw2', 'VpnGw2AZ'])
param vpnGatewaySku string = 'VpnGw1AZ'

@description('Deploy ExpressRoute Gateway.')
param deployErGateway bool = false

@description('ExpressRoute Gateway SKU.')
@allowed(['Standard', 'HighPerformance', 'UltraPerformance', 'ErGw1AZ', 'ErGw2AZ', 'ErGw3AZ'])
param erGatewaySku string = 'ErGw1AZ'

@description('Deploy Private DNS Resolver.')
param deployDnsResolver bool = false

@description('Deploy DNS Resolver inbound endpoint.')
param deployDnsInboundEndpoint bool = true

@description('Deploy DNS Resolver outbound endpoint.')
param deployDnsOutboundEndpoint bool = true

@description('Deploy Private Link DNS Zones.')
param deployPrivateDnsZones bool = true

// Policy parameters
@description('Deploy Azure Landing Zone policy assignments.')
param deployPolicies bool = true

@description('Deploy Microsoft Cloud Security Benchmark (Azure Security Baseline) policy assignment.')
param deploySecurityBaseline bool = true

@description('Deploy Sovereignty Baseline - Global Policies.')
param deploySovereignPolicies bool = false

@description('Deploy Sovereignty Baseline - Confidential Policies (Azure Confidential Computing enforcement).')
param deploySovereignConfidentialPolicies bool = false

@description('Allowed Azure locations for policy.')
param allowedLocations array = [
  'westeurope'
  'northeurope'
]

// =============================================
// Variables
// =============================================

var namePrefix = '${workloadName}-${environment}'
var rgLoggingName = 'rg-${namePrefix}-logging'
var rgNetworkingName = 'rg-${namePrefix}-networking'
var rgDnsName = 'rg-${namePrefix}-dns'
var rgSecurityName = 'rg-${namePrefix}-security'
var deployGateway = deployVpnGateway || deployErGateway

var defaultTags = union(tags, {
  environment: environment
  workload: workloadName
  deployedBy: 'bicep'
})

// =============================================
// Resource Groups
// =============================================

resource rgLogging 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgLoggingName
  location: location
  tags: defaultTags
}

resource rgNetworking 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgNetworkingName
  location: location
  tags: defaultTags
}

resource rgDns 'Microsoft.Resources/resourceGroups@2024-03-01' = if (deployPrivateDnsZones) {
  name: rgDnsName
  location: location
  tags: defaultTags
}

resource rgSecurity 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgSecurityName
  location: location
  tags: defaultTags
}

// =============================================
// Logging
// =============================================

module logging 'modules/logging.bicep' = {
  scope: rgLogging
  params: {
    location: location
    namePrefix: namePrefix
    tags: defaultTags
    retentionInDays: logRetentionInDays
    logAnalyticsSku: logAnalyticsSku
  }
}

// =============================================
// Security - Key Vault
// =============================================

module keyVault 'modules/keyVault.bicep' = {
  scope: rgSecurity
  params: {
    location: location
    namePrefix: namePrefix
    tags: defaultTags
    logAnalyticsWorkspaceId: logging.outputs.logAnalyticsWorkspaceId
  }
}

// Activity Log diagnostic settings (subscription scope)
module activityLogDiagnostics 'br/public:avm/res/insights/diagnostic-setting:0.1.4' = {
  params: {
    name: 'ds-activitylog-${namePrefix}'
    workspaceResourceId: logging.outputs.logAnalyticsWorkspaceId
    storageAccountResourceId: logging.outputs.storageAccountId
  }
}

// =============================================
// Networking
// =============================================

module networking 'modules/networking.bicep' = {
  scope: rgNetworking
  params: {
    location: location
    namePrefix: namePrefix
    tags: defaultTags
    vnetAddressPrefix: vnetAddressPrefix
    workloadSubnetPrefix: workloadSubnetPrefix
    gatewaySubnetPrefix: gatewaySubnetPrefix
    firewallSubnetPrefix: firewallSubnetPrefix
    bastionSubnetPrefix: bastionSubnetPrefix
    dnsInboundSubnetPrefix: dnsInboundSubnetPrefix
    dnsOutboundSubnetPrefix: dnsOutboundSubnetPrefix
    deployBastion: deployBastion
    deployFirewall: deployFirewall
    deployGateway: deployGateway
    deployDnsResolver: deployDnsResolver
    deployDnsInboundEndpoint: deployDnsInboundEndpoint
    deployDnsOutboundEndpoint: deployDnsOutboundEndpoint
    logAnalyticsWorkspaceId: logging.outputs.logAnalyticsWorkspaceId
    firewallPrivateIp: firewallPrivateIp
  }
}

// =============================================
// Optional: Azure Bastion
// =============================================

module bastion 'modules/bastion.bicep' = if (deployBastion) {
  scope: rgNetworking
  params: {
    location: location
    namePrefix: namePrefix
    tags: defaultTags
    virtualNetworkResourceId: networking.outputs.vnetId
    logAnalyticsWorkspaceId: logging.outputs.logAnalyticsWorkspaceId
  }
}

// =============================================
// Optional: Azure Firewall
// =============================================

module firewall 'modules/firewall.bicep' = if (deployFirewall) {
  scope: rgNetworking
  params: {
    location: location
    namePrefix: namePrefix
    tags: defaultTags
    virtualNetworkResourceId: networking.outputs.vnetId
    skuTier: firewallSkuTier
    logAnalyticsWorkspaceId: logging.outputs.logAnalyticsWorkspaceId
  }
}

// =============================================
// Optional: VPN / ExpressRoute Gateway
// =============================================

module vpnGateway 'modules/gateway.bicep' = if (deployVpnGateway) {
  scope: rgNetworking
  params: {
    location: location
    namePrefix: namePrefix
    tags: defaultTags
    virtualNetworkResourceId: networking.outputs.vnetId
    gatewayType: 'Vpn'
    skuName: vpnGatewaySku
    logAnalyticsWorkspaceId: logging.outputs.logAnalyticsWorkspaceId
  }
}

module erGateway 'modules/gateway.bicep' = if (deployErGateway) {
  scope: rgNetworking
  params: {
    location: location
    namePrefix: namePrefix
    tags: defaultTags
    virtualNetworkResourceId: networking.outputs.vnetId
    gatewayType: 'ExpressRoute'
    skuName: erGatewaySku
    logAnalyticsWorkspaceId: logging.outputs.logAnalyticsWorkspaceId
  }
}

// =============================================
// Optional: Private DNS Resolver
// =============================================

module dnsResolver 'modules/dnsResolver.bicep' = if (deployDnsResolver) {
  scope: rgNetworking
  params: {
    location: location
    namePrefix: namePrefix
    tags: defaultTags
    virtualNetworkResourceId: networking.outputs.vnetId
    deployInboundEndpoint: deployDnsInboundEndpoint
    deployOutboundEndpoint: deployDnsOutboundEndpoint
    inboundSubnetId: networking.outputs.dnsInboundSubnetId
    outboundSubnetId: networking.outputs.dnsOutboundSubnetId
  }
}

// =============================================
// Private DNS Zones
// =============================================

module privateDnsZones 'modules/privateDnsZones.bicep' = if (deployPrivateDnsZones) {
  scope: rgDns
  params: {
    location: location
    tags: defaultTags
    virtualNetworkResourceId: networking.outputs.vnetId
  }
}

// =============================================
// Policy Assignments (subscription scope)
// =============================================

module policies 'modules/policyAssignments.bicep' = if (deployPolicies) {
  params: {
    location: location
    logAnalyticsWorkspaceId: logging.outputs.logAnalyticsWorkspaceId
    deploySecurityBaseline: deploySecurityBaseline
    deploySovereignPolicies: deploySovereignPolicies
    deploySovereignConfidentialPolicies: deploySovereignConfidentialPolicies
    allowedLocations: allowedLocations
  }
}

// =============================================
// Policy Exemptions (subnets that cannot have NSGs)
// =============================================

var nsgPolicyAssignmentId = subscriptionResourceId(
  'Microsoft.Authorization/policyAssignments',
  'mcsb-baseline'
)

module exemptGatewaySubnetNsg 'modules/subnetPolicyExemption.bicep' = if (deployPolicies && deployGateway) {
  scope: rgNetworking
  params: {
    exemptionName: 'exempt-gatewaysubnet-nsg'
    displayName: 'GatewaySubnet - NSG not supported'
    exemptionDescription: 'GatewaySubnet does not support NSG attachment. Network security is provided by the Azure platform for VPN/ExpressRoute gateway traffic.'
    policyAssignmentId: nsgPolicyAssignmentId
    policyDefinitionReferenceIds: ['networkSecurityGroupsOnSubnetsMonitoring']
    vnetName: networking.outputs.vnetName
    subnetName: 'GatewaySubnet'
  }
  dependsOn: [policies]
}

module exemptFirewallSubnetNsg 'modules/subnetPolicyExemption.bicep' = if (deployPolicies && deployFirewall) {
  scope: rgNetworking
  params: {
    exemptionName: 'exempt-firewallsubnet-nsg'
    displayName: 'AzureFirewallSubnet - NSG not supported'
    exemptionDescription: 'AzureFirewallSubnet does not support NSG attachment. Azure Firewall provides its own network filtering capabilities.'
    policyAssignmentId: nsgPolicyAssignmentId
    policyDefinitionReferenceIds: ['networkSecurityGroupsOnSubnetsMonitoring']
    vnetName: networking.outputs.vnetName
    subnetName: 'AzureFirewallSubnet'
  }
  dependsOn: [policies]
}

// =============================================
// Outputs
// =============================================

output logAnalyticsWorkspaceId string = logging.outputs.logAnalyticsWorkspaceId
output storageAccountId string = logging.outputs.storageAccountId
output vnetId string = networking.outputs.vnetId
output vnetName string = networking.outputs.vnetName
output bastionId string = deployBastion ? (bastion.?outputs.?bastionId ?? '') : ''
output firewallPrivateIp string = deployFirewall ? firewallPrivateIp : ''
output keyVaultId string = keyVault.outputs.keyVaultId
output keyVaultName string = keyVault.outputs.keyVaultName
