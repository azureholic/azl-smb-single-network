locals {
  # Built-in Policy Definition IDs
  mcsb_policy_set_id     = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
  allowed_locations_id   = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  allowed_locations_rg_id = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
  audit_managed_disks_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d"
  deny_public_ip_nic_id  = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
  storage_min_tls_id     = "/providers/Microsoft.Authorization/policyDefinitions/fe83a0eb-a853-422d-aac2-1bffd182c5d0"
  audit_res_location_id  = "/providers/Microsoft.Authorization/policyDefinitions/0a914e76-4921-4c19-b460-a2d36003525a"
  deploy_activity_log_id = "/providers/Microsoft.Authorization/policyDefinitions/2465583e-4e78-4c15-b6be-a36cbc7c8b0f"

  defender_servers_id = "/providers/Microsoft.Authorization/policyDefinitions/8e86a5b6-b9bd-49d1-8e21-4bb8a0862222"
  defender_storage_id = "/providers/Microsoft.Authorization/policyDefinitions/cfdc5972-75b3-4418-8ae1-7f5c36839390"
  defender_sql_id     = "/providers/Microsoft.Authorization/policyDefinitions/b99b73e7-074b-4089-9395-b7236f094491"
  defender_kv_id      = "/providers/Microsoft.Authorization/policyDefinitions/1f725891-01c0-420a-9059-4fa46cb770b7"
  defender_arm_id     = "/providers/Microsoft.Authorization/policyDefinitions/b7021b2b-08fd-4dc0-9de7-3c6ece09faf9"
  defender_dns_id     = "/providers/Microsoft.Authorization/policyDefinitions/bdc59948-5574-49b3-bb91-76b7c986428d"

  sovereign_global_id       = "/providers/Microsoft.Authorization/policySetDefinitions/c1cbff38-87c0-4b9f-9f70-035c7a3b5523"
  sovereign_confidential_id = "/providers/Microsoft.Authorization/policySetDefinitions/03de05a4-c324-4ccd-882f-a814ea8ab9ea"

  # Contributor role for DINE assignments
  contributor_role_id = "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
  monitoring_contributor_role_id    = "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa"
  log_analytics_contributor_role_id = "/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"
}

data "azurerm_subscription" "current" {}

# ==============================================================================
# Microsoft Cloud Security Benchmark (Azure Security Baseline)
# ==============================================================================

resource "azurerm_subscription_policy_assignment" "mcsb" {
  count                = var.deploy_security_baseline ? 1 : 0
  name                 = "mcsb-baseline"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.mcsb_policy_set_id
  display_name         = "Microsoft Cloud Security Benchmark"
  description          = "Azure Security Baseline - Microsoft Cloud Security Benchmark initiative for ALZ SMB landing zone."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

# ==============================================================================
# ALZ Policy: Allowed Locations
# ==============================================================================

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "alz-allowed-locations"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.allowed_locations_id
  display_name         = "ALZ - Allowed locations"
  description          = "Restricts the locations where resources can be deployed."

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

resource "azurerm_subscription_policy_assignment" "allowed_locations_rg" {
  name                 = "alz-allowed-loc-rg"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.allowed_locations_rg_id
  display_name         = "ALZ - Allowed locations for resource groups"
  description          = "Restricts the locations where resource groups can be created."

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

# ==============================================================================
# ALZ Audit/Deny Policies
# ==============================================================================

resource "azurerm_subscription_policy_assignment" "audit_managed_disks" {
  name                 = "alz-audit-managed-disk"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.audit_managed_disks_id
  display_name         = "ALZ - Audit VMs without managed disks"
  description          = "Audits VMs that do not use managed disks."
}

resource "azurerm_subscription_policy_assignment" "storage_min_tls" {
  name                 = "alz-storage-tls"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.storage_min_tls_id
  display_name         = "ALZ - Storage accounts should have minimum TLS version"
  description          = "Audit minimum TLS version for storage accounts."

  parameters = jsonencode({
    minimumTlsVersion = { value = "TLS1_2" }
  })
}

resource "azurerm_subscription_policy_assignment" "deny_public_ip_nic" {
  name                 = "alz-deny-pip-nic"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.deny_public_ip_nic_id
  display_name         = "ALZ - Network interfaces should not have public IPs"
  description          = "Denies the creation of public IPs on network interfaces."
}

resource "azurerm_subscription_policy_assignment" "audit_res_location" {
  name                 = "alz-audit-res-location"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.audit_res_location_id
  display_name         = "ALZ - Audit resource location matches resource group location"
  description          = "Audits that resource location matches its resource group location."
}

# ==============================================================================
# ALZ DINE Policy: Deploy Activity Log to LAW
# ==============================================================================

resource "azurerm_subscription_policy_assignment" "deploy_activity_log" {
  name                 = "alz-deploy-actlog"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.deploy_activity_log_id
  display_name         = "ALZ - Deploy Activity Log diagnostic settings to Log Analytics"
  description          = "Deploys diagnostic settings for Activity Log to send to Log Analytics workspace."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    logAnalytics = { value = var.log_analytics_workspace_id }
  })
}

resource "azurerm_role_assignment" "activity_log_monitoring" {
  scope                = data.azurerm_subscription.current.id
  role_definition_id   = local.monitoring_contributor_role_id
  principal_id         = azurerm_subscription_policy_assignment.deploy_activity_log.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "activity_log_law" {
  scope                = data.azurerm_subscription.current.id
  role_definition_id   = local.log_analytics_contributor_role_id
  principal_id         = azurerm_subscription_policy_assignment.deploy_activity_log.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# ==============================================================================
# ALZ DINE Policies: Microsoft Defender for Cloud
# ==============================================================================

resource "azurerm_subscription_policy_assignment" "defender_servers" {
  name                 = "alz-defender-servers"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.defender_servers_id
  display_name         = "ALZ - Configure Microsoft Defender for Servers"
  description          = "Configures Microsoft Defender for Servers."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "defender_servers" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = local.contributor_role_id
  principal_id       = azurerm_subscription_policy_assignment.defender_servers.identity[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_subscription_policy_assignment" "defender_storage" {
  name                 = "alz-defender-storage"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.defender_storage_id
  display_name         = "ALZ - Configure Microsoft Defender for Storage"
  description          = "Configures Microsoft Defender for Storage."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "defender_storage" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = local.contributor_role_id
  principal_id       = azurerm_subscription_policy_assignment.defender_storage.identity[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_subscription_policy_assignment" "defender_sql" {
  name                 = "alz-defender-sql"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.defender_sql_id
  display_name         = "ALZ - Configure Microsoft Defender for SQL"
  description          = "Configures Microsoft Defender for SQL."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "defender_sql" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = local.contributor_role_id
  principal_id       = azurerm_subscription_policy_assignment.defender_sql.identity[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_subscription_policy_assignment" "defender_kv" {
  name                 = "alz-defender-kv"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.defender_kv_id
  display_name         = "ALZ - Configure Microsoft Defender for Key Vaults"
  description          = "Configures Microsoft Defender for Key Vaults."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "defender_kv" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = local.contributor_role_id
  principal_id       = azurerm_subscription_policy_assignment.defender_kv.identity[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_subscription_policy_assignment" "defender_arm" {
  name                 = "alz-defender-arm"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.defender_arm_id
  display_name         = "ALZ - Configure Microsoft Defender for Resource Manager"
  description          = "Configures Microsoft Defender for Resource Manager."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "defender_arm" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = local.contributor_role_id
  principal_id       = azurerm_subscription_policy_assignment.defender_arm.identity[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_subscription_policy_assignment" "defender_dns" {
  name                 = "alz-defender-dns"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.defender_dns_id
  display_name         = "ALZ - Configure Microsoft Defender for DNS"
  description          = "Configures Microsoft Defender for DNS."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "defender_dns" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = local.contributor_role_id
  principal_id       = azurerm_subscription_policy_assignment.defender_dns.identity[0].principal_id
  principal_type     = "ServicePrincipal"
}

# ==============================================================================
# Sovereignty Baseline - Global Policies
# ==============================================================================

resource "azurerm_subscription_policy_assignment" "sovereign_global" {
  count                = var.deploy_sovereign_policies ? 1 : 0
  name                 = "sov-global-baseline"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.sovereign_global_id
  display_name         = "Sovereignty Baseline - Global Policies"
  description          = "Microsoft Cloud for Sovereignty global policies - denies resource creation outside approved regions."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    effect                = { value = "Deny" }
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

# ==============================================================================
# Sovereignty Baseline - Confidential Policies
# ==============================================================================

resource "azurerm_subscription_policy_assignment" "sovereign_confidential" {
  count                = var.deploy_sovereign_confidential_policies ? 1 : 0
  name                 = "sov-confidential"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.sovereign_confidential_id
  display_name         = "Sovereignty Baseline - Confidential Policies"
  description          = "Microsoft Cloud for Sovereignty confidential policies - enforces Azure Confidential Computing, CMK usage, and approved regions/resource types."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    effect                = { value = "Deny" }
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}
