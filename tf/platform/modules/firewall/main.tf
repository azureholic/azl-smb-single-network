# ==============================================================================
# Firewall Policy (AVM)
# ==============================================================================

module "firewall_policy" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.4"

  name                                     = "afwp-${var.name_prefix}"
  location                                 = var.location
  resource_group_name                      = var.resource_group_name
  tags                                     = var.tags
  firewall_policy_sku                      = var.sku_tier
  firewall_policy_threat_intelligence_mode = "Deny"
  enable_telemetry                         = false

  firewall_policy_insights = {
    enabled                            = true
    default_log_analytics_workspace_id = var.log_analytics_workspace_id
  }
}

# ==============================================================================
# Firewall Public IP (no AVM PIP module needed separately)
# ==============================================================================

resource "azurerm_public_ip" "firewall" {
  name                = "pip-afw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ==============================================================================
# Azure Firewall (AVM)
# ==============================================================================

module "firewall" {
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.4.0"

  name                = "afw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = var.sku_tier
  firewall_policy_id  = module.firewall_policy.resource_id
  enable_telemetry    = false

  ip_configurations = {
    primary = {
      name                 = "fw-ipconfig"
      subnet_id            = var.firewall_subnet_id
      public_ip_address_id = azurerm_public_ip.firewall.id
    }
  }

  diagnostic_settings = {
    to_law = {
      workspace_resource_id = var.log_analytics_workspace_id
      log_categories        = ["AZFWApplicationRule", "AZFWNetworkRule", "AZFWThreatIntel"]
      metric_categories     = ["AllMetrics"]
    }
  }
}
