data "azurerm_client_config" "current" {}

locals {
  kv_name_raw = "kv-${replace(var.name_prefix, "-", "")}"
  kv_name     = substr(local.kv_name_raw, 0, min(length(local.kv_name_raw), 24))
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                          = local.kv_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = var.tags
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  legacy_access_policies_enabled = false
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  public_network_access_enabled = false
  enable_telemetry              = false

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  diagnostic_settings = {
    to_law = {
      workspace_resource_id = var.log_analytics_workspace_id
      log_categories        = ["AuditEvent", "AzurePolicyEvaluationDetails"]
      metric_categories     = ["AllMetrics"]
    }
  }
}
