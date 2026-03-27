metadata name = 'SMB Landing Zone - Logging Module'
metadata description = 'Deploys Log Analytics workspace, Storage Account for logs, and Automation Account.'

// =============================================
// Parameters
// =============================================

@description('Azure region.')
param location string

@description('Naming prefix.')
param namePrefix string

@description('Tags.')
param tags object

@description('Log Analytics retention in days.')
param retentionInDays int

@description('Log Analytics SKU.')
param logAnalyticsSku string

// =============================================
// Variables
// =============================================

var logAnalyticsName = 'law-${namePrefix}'
var storageAccountName = replace('st${replace(namePrefix, '-', '')}logs', ' ', '')
var automationAccountName = 'aa-${namePrefix}'

// =============================================
// Log Analytics Workspace
// =============================================

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.15.0' = {
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
    skuName: logAnalyticsSku
    dataRetention: retentionInDays
  }
}

// =============================================
// Storage Account for Logs
// =============================================

module storageAccount 'br/public:avm/res/storage/storage-account:0.32.0' = {
  params: {
    name: length(storageAccountName) > 24 ? substring(storageAccountName, 0, 24) : storageAccountName
    location: location
    tags: tags
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
  }
}

// =============================================
// Automation Account (linked to LAW)
// =============================================

module automationAccount 'br/public:avm/res/automation/automation-account:0.18.0' = {
  params: {
    name: automationAccountName
    location: location
    tags: tags
    skuName: 'Basic'
    linkedWorkspaceResourceId: logAnalytics.outputs.resourceId
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
  }
}

// =============================================
// Outputs
// =============================================

output logAnalyticsWorkspaceId string = logAnalytics.outputs.resourceId
output logAnalyticsWorkspaceName string = logAnalytics.outputs.name
output storageAccountId string = storageAccount.outputs.resourceId
output storageAccountName string = storageAccount.outputs.name
output automationAccountId string = automationAccount.outputs.resourceId
