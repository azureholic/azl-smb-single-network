metadata name = 'SMB Landing Zone - Firewall Module'
metadata description = 'Deploys Azure Firewall with Firewall Policy.'

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

@description('Azure Firewall SKU tier.')
@allowed(['Basic', 'Standard', 'Premium'])
param skuTier string

@description('Log Analytics Workspace resource ID.')
param logAnalyticsWorkspaceId string

// =============================================
// Firewall Policy
// =============================================

module firewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.4' = {
  params: {
    name: 'afwp-${namePrefix}'
    location: location
    tags: tags
    tier: skuTier
    threatIntelMode: 'Deny'
    insightsIsEnabled: true
    defaultWorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

// =============================================
// Azure Firewall
// =============================================

module azureFirewall 'br/public:avm/res/network/azure-firewall:0.10.0' = {
  params: {
    name: 'afw-${namePrefix}'
    location: location
    tags: tags
    azureSkuTier: skuTier
    virtualNetworkResourceId: virtualNetworkResourceId
    firewallPolicyId: firewallPolicy.outputs.resourceId
    threatIntelMode: 'Deny'
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

output firewallId string = azureFirewall.outputs.resourceId
output firewallName string = azureFirewall.outputs.name
output firewallPrivateIp string = azureFirewall.outputs.privateIp
output firewallPolicyId string = firewallPolicy.outputs.resourceId
