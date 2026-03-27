using 'main.bicep'

param location = 'westeurope'
param environment = 'prod'
param workloadName = 'smb'
param tags = {
  project: 'smb-landing-zone'
  owner: 'platform-team'
}

// Logging
param logRetentionInDays = 90
param logAnalyticsSku = 'PerGB2018'

// Networking
param vnetAddressPrefix = '10.0.0.0/16'
param gatewaySubnetPrefix = '10.0.0.0/27'
param firewallSubnetPrefix = '10.0.0.64/26'
param bastionSubnetPrefix = '10.0.1.0/26'
param dnsInboundSubnetPrefix = '10.0.1.64/28'
param dnsOutboundSubnetPrefix = '10.0.1.80/28'
param workloadSubnetPrefix = '10.0.10.0/24'

// Optional features - set to true to enable
param deployBastion = false
param deployFirewall = false
param firewallSkuTier = 'Standard'
param firewallPrivateIp = '10.0.0.68'
param deployVpnGateway = false
param vpnGatewaySku = 'VpnGw1AZ'
param deployErGateway = false
param erGatewaySku = 'ErGw1AZ'
param deployDnsResolver = false
param deployDnsInboundEndpoint = true
param deployDnsOutboundEndpoint = true

// Private DNS Zones
param deployPrivateDnsZones = true

// Policy
param deployPolicies = true
param deploySecurityBaseline = true
param deploySovereignPolicies = true
param deploySovereignConfidentialPolicies = false
param allowedLocations = [
  'westeurope'
  'northeurope'
  'uksouth'
  'swedencentral'
]
