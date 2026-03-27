metadata name = 'SMB Landing Zone - Bastion Module'
metadata description = 'Deploys Azure Bastion Host.'

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

@description('Log Analytics Workspace resource ID.')
param logAnalyticsWorkspaceId string

// =============================================
// Bastion Host
// =============================================

module bastionHost 'br/public:avm/res/network/bastion-host:0.8.2' = {
  params: {
    name: 'bas-${namePrefix}'
    location: location
    tags: tags
    virtualNetworkResourceId: virtualNetworkResourceId
    skuName: 'Standard'
    enableFileCopy: true
    enableShareableLink: false
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

output bastionId string = bastionHost.outputs.resourceId
output bastionName string = bastionHost.outputs.name
