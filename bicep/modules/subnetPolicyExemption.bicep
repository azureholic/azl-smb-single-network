metadata name = 'SMB Landing Zone - Subnet Policy Exemption'
metadata description = 'Creates a policy exemption scoped to a specific subnet that cannot have an NSG.'

// =============================================
// Parameters
// =============================================

@description('Name of the exemption resource.')
param exemptionName string

@description('Display name for the exemption.')
param displayName string

@description('Description of why the exemption is needed.')
param exemptionDescription string

@description('Resource ID of the policy assignment to exempt from.')
param policyAssignmentId string

@description('Policy definition reference IDs to scope the exemption within an initiative. Leave empty to exempt from all policies in the assignment.')
param policyDefinitionReferenceIds array = []

@description('Name of the existing VNET.')
param vnetName string

@description('Name of the subnet to exempt.')
param subnetName string

// =============================================
// Existing References
// =============================================

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: subnetName
}

// =============================================
// Policy Exemption (scoped to the specific subnet)
// =============================================

resource exemption 'Microsoft.Authorization/policyExemptions@2022-07-01-preview' = {
  name: exemptionName
  scope: subnet
  properties: {
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceIds: !empty(policyDefinitionReferenceIds) ? policyDefinitionReferenceIds : null
    exemptionCategory: 'Mitigated'
    displayName: displayName
    description: exemptionDescription
  }
}
