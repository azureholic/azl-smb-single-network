targetScope = 'subscription'

metadata name = 'SMB Landing Zone - Policy Assignments Module'
metadata description = 'Assigns Azure Landing Zone and Azure Security Baseline policies at subscription scope.'

// =============================================
// Parameters
// =============================================

@description('Azure region for policy assignment managed identity.')
param location string

@description('Log Analytics Workspace resource ID for diagnostic policy parameters.')
param logAnalyticsWorkspaceId string

@description('Deploy Microsoft Cloud Security Benchmark (Azure Security Baseline).')
param deploySecurityBaseline bool

@description('Allowed Azure locations.')
param allowedLocations array

@description('Deploy Sovereignty Baseline - Global Policies.')
param deploySovereignPolicies bool

@description('Deploy Sovereignty Baseline - Confidential Policies (Azure Confidential Computing enforcement).')
param deploySovereignConfidentialPolicies bool

// =============================================
// Built-in Policy Definition IDs
// =============================================

var mcsbPolicySetId = '/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8'
var allowedLocationsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
var allowedLocationsRgPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988'
var auditVmsWithoutManagedDisksPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d'
var denyPublicIpOnNicPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114'
var requireStorageMinTlsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/fe83a0eb-a853-422d-aac2-1bffd182c5d0'
var auditResourceLocationMatchesRgPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/0a914e76-4921-4c19-b460-a2d36003525a'
var deployActivityLogPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/2465583e-4e78-4c15-b6be-a36cbc7c8b0f'
var deployDefenderForServersPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/8e86a5b6-b9bd-49d1-8e21-4bb8a0862222'
var deployDefenderForStoragePolicyId = '/providers/Microsoft.Authorization/policyDefinitions/cfdc5972-75b3-4418-8ae1-7f5c36839390'
var deployDefenderForSqlPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/b99b73e7-074b-4089-9395-b7236f094491'
var deployDefenderForKvPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/1f725891-01c0-420a-9059-4fa46cb770b7'
var deployDefenderForArmPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/b7021b2b-08fd-4dc0-9de7-3c6ece09faf9'
var deployDefenderForDnsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/bdc59948-5574-49b3-bb91-76b7c986428d'
var sovereignGlobalPolicySetId = '/providers/Microsoft.Authorization/policySetDefinitions/c1cbff38-87c0-4b9f-9f70-035c7a3b5523'
var sovereignConfidentialPolicySetId = '/providers/Microsoft.Authorization/policySetDefinitions/03de05a4-c324-4ccd-882f-a814ea8ab9ea'

// =============================================
// Microsoft Cloud Security Benchmark (Azure Security Baseline)
// =============================================

resource mcsbAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (deploySecurityBaseline) {
  name: 'mcsb-baseline'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Microsoft Cloud Security Benchmark'
    description: 'Azure Security Baseline - Microsoft Cloud Security Benchmark initiative for ALZ SMB landing zone.'
    policyDefinitionId: mcsbPolicySetId
    enforcementMode: 'Default'
  }
}

// =============================================
// ALZ Policy: Allowed Locations
// =============================================

resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-allowed-locations'
  properties: {
    displayName: 'ALZ - Allowed locations'
    description: 'Restricts the locations where resources can be deployed.'
    policyDefinitionId: allowedLocationsPolicyId
    enforcementMode: 'Default'
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

resource allowedLocationsRgAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-allowed-loc-rg'
  properties: {
    displayName: 'ALZ - Allowed locations for resource groups'
    description: 'Restricts the locations where resource groups can be created.'
    policyDefinitionId: allowedLocationsRgPolicyId
    enforcementMode: 'Default'
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

// =============================================
// ALZ Audit/Deny Policies
// =============================================

resource auditManagedDisksAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-audit-managed-disk'
  properties: {
    displayName: 'ALZ - Audit VMs without managed disks'
    description: 'Audits VMs that do not use managed disks.'
    policyDefinitionId: auditVmsWithoutManagedDisksPolicyId
    enforcementMode: 'Default'
  }
}

resource requireMinTlsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-storage-tls'
  properties: {
    displayName: 'ALZ - Storage accounts should have minimum TLS version'
    description: 'Audit minimum TLS version for storage accounts.'
    policyDefinitionId: requireStorageMinTlsPolicyId
    enforcementMode: 'Default'
    parameters: {
      minimumTlsVersion: {
        value: 'TLS1_2'
      }
    }
  }
}

resource denyPublicIpOnNicAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-deny-pip-nic'
  properties: {
    displayName: 'ALZ - Network interfaces should not have public IPs'
    description: 'Denies the creation of public IPs on network interfaces.'
    policyDefinitionId: denyPublicIpOnNicPolicyId
    enforcementMode: 'Default'
  }
}

resource auditResourceLocationAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-audit-res-location'
  properties: {
    displayName: 'ALZ - Audit resource location matches resource group location'
    description: 'Audits that resource location matches its resource group location.'
    policyDefinitionId: auditResourceLocationMatchesRgPolicyId
    enforcementMode: 'Default'
  }
}

// =============================================
// ALZ DINE Policy: Deploy Activity Log to LAW
// =============================================

resource deployActivityLogAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-deploy-actlog'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'ALZ - Deploy Activity Log diagnostic settings to Log Analytics'
    description: 'Deploys diagnostic settings for Activity Log to send to Log Analytics workspace.'
    policyDefinitionId: deployActivityLogPolicyId
    enforcementMode: 'Default'
    parameters: {
      logAnalytics: {
        value: logAnalyticsWorkspaceId
      }
    }
  }
}

resource activityLogRoleMonitoring 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'alz-deploy-actlog', 'monitoring-contributor')
  properties: {
    principalId: deployActivityLogAssignment.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '749f88d5-cbae-40b8-bcfc-e573ddc772fa')
    principalType: 'ServicePrincipal'
  }
}

resource activityLogRoleLogAnalytics 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'alz-deploy-actlog', 'log-analytics-contributor')
  properties: {
    principalId: deployActivityLogAssignment.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '92aaf0da-9dab-42b6-94a3-d43ce8d16293')
    principalType: 'ServicePrincipal'
  }
}

// =============================================
// ALZ DINE Policies: Microsoft Defender for Cloud
// =============================================

resource deployDefenderForServers 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-defender-servers'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'ALZ - Configure Microsoft Defender for Servers'
    description: 'Configures Microsoft Defender for Servers.'
    policyDefinitionId: deployDefenderForServersPolicyId
    enforcementMode: 'Default'
  }
}

resource defenderServersRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'alz-defender-servers', 'contributor')
  properties: {
    principalId: deployDefenderForServers.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType: 'ServicePrincipal'
  }
}

resource deployDefenderForStorage 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-defender-storage'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'ALZ - Configure Microsoft Defender for Storage'
    description: 'Configures Microsoft Defender for Storage.'
    policyDefinitionId: deployDefenderForStoragePolicyId
    enforcementMode: 'Default'
  }
}

resource defenderStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'alz-defender-storage', 'contributor')
  properties: {
    principalId: deployDefenderForStorage.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType: 'ServicePrincipal'
  }
}

resource deployDefenderForSql 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-defender-sql'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'ALZ - Configure Microsoft Defender for SQL'
    description: 'Configures Microsoft Defender for SQL.'
    policyDefinitionId: deployDefenderForSqlPolicyId
    enforcementMode: 'Default'
  }
}

resource defenderSqlRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'alz-defender-sql', 'contributor')
  properties: {
    principalId: deployDefenderForSql.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType: 'ServicePrincipal'
  }
}

resource deployDefenderForKeyVaults 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-defender-kv'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'ALZ - Configure Microsoft Defender for Key Vaults'
    description: 'Configures Microsoft Defender for Key Vaults.'
    policyDefinitionId: deployDefenderForKvPolicyId
    enforcementMode: 'Default'
  }
}

resource defenderKvRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'alz-defender-kv', 'contributor')
  properties: {
    principalId: deployDefenderForKeyVaults.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType: 'ServicePrincipal'
  }
}

resource deployDefenderForArm 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-defender-arm'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'ALZ - Configure Microsoft Defender for Resource Manager'
    description: 'Configures Microsoft Defender for Resource Manager.'
    policyDefinitionId: deployDefenderForArmPolicyId
    enforcementMode: 'Default'
  }
}

resource defenderArmRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'alz-defender-arm', 'contributor')
  properties: {
    principalId: deployDefenderForArm.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType: 'ServicePrincipal'
  }
}

resource deployDefenderForDns 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-defender-dns'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'ALZ - Configure Microsoft Defender for DNS'
    description: 'Configures Microsoft Defender for DNS.'
    policyDefinitionId: deployDefenderForDnsPolicyId
    enforcementMode: 'Default'
  }
}

resource defenderDnsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'alz-defender-dns', 'contributor')
  properties: {
    principalId: deployDefenderForDns.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType: 'ServicePrincipal'
  }
}

// =============================================
// Sovereignty Baseline - Global Policies
// =============================================

resource sovereignGlobalAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (deploySovereignPolicies) {
  name: 'sov-global-baseline'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Sovereignty Baseline - Global Policies'
    description: 'Microsoft Cloud for Sovereignty global policies - denies resource creation outside approved regions.'
    policyDefinitionId: sovereignGlobalPolicySetId
    enforcementMode: 'Default'
    parameters: {
      effect: {
        value: 'Deny'
      }
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

// =============================================
// Sovereignty Baseline - Confidential Policies
// =============================================

resource sovereignConfidentialAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (deploySovereignConfidentialPolicies) {
  name: 'sov-confidential'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Sovereignty Baseline - Confidential Policies'
    description: 'Microsoft Cloud for Sovereignty confidential policies - enforces Azure Confidential Computing, CMK usage, and approved regions/resource types.'
    policyDefinitionId: sovereignConfidentialPolicySetId
    enforcementMode: 'Default'
    parameters: {
      effect: {
        value: 'Deny'
      }
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}
