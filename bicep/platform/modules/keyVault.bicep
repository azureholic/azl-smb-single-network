metadata name = 'SMB Landing Zone - Key Vault Module'
metadata description = 'Deploys Azure Key Vault for the landing zone security resource group.'

// =============================================
// Parameters
// =============================================

@description('Azure region.')
param location string

@description('Naming prefix.')
param namePrefix string

@description('Tags.')
param tags object

@description('Log Analytics Workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceId string

// =============================================
// Variables
// =============================================

var keyVaultName = 'kv-${replace(namePrefix, '-', '')}'

// =============================================
// Key Vault
// =============================================

module keyVault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  params: {
    name: length(keyVaultName) > 24 ? substring(keyVaultName, 0, 24) : keyVaultName
    location: location
    tags: tags
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    sku: 'standard'
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
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

output keyVaultId string = keyVault.outputs.resourceId
output keyVaultName string = keyVault.outputs.name
output keyVaultUri string = keyVault.outputs.uri
