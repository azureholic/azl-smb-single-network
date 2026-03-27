locals {
  storage_name_raw = "st${replace(var.name_prefix, "-", "")}logs"
  storage_name     = substr(local.storage_name_raw, 0, min(length(local.storage_name_raw), 24))
}

# ==============================================================================
# Log Analytics Workspace (AVM)
# ==============================================================================

module "law" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                                = "law-${var.name_prefix}"
  location                            = var.location
  resource_group_name                 = var.resource_group_name
  tags                                = var.tags
  log_analytics_workspace_sku         = var.log_analytics_sku
  log_analytics_workspace_retention_in_days = var.retention_in_days
  enable_telemetry                    = false
}

# ==============================================================================
# Storage Account (AVM)
# ==============================================================================

module "storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.5.0"

  name                     = local.storage_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  tags                     = var.tags
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled = true
  public_network_access_enabled = false
  enable_telemetry         = false

  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# ==============================================================================
# Automation Account (AVM)
# ==============================================================================

module "automation" {
  source  = "Azure/avm-res-automation-automationaccount/azurerm"
  version = "0.2.0"

  name                = "aa-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  sku                 = "Basic"
  enable_telemetry    = false

  diagnostic_settings = {
    to_law = {
      workspace_resource_id = module.law.resource_id
      log_categories        = ["JobLogs", "JobStreams", "DscNodeStatus"]
      metric_categories     = ["AllMetrics"]
    }
  }
}

# ==============================================================================
# Link Automation Account to LAW
# ==============================================================================

resource "azurerm_log_analytics_linked_service" "automation" {
  resource_group_name = var.resource_group_name
  workspace_id        = module.law.resource_id
  read_access_id      = module.automation.resource_id
}
