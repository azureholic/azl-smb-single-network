locals {
  gateway_name = var.gateway_type == "Vpn" ? "vpngw-${var.name_prefix}" : "ergw-${var.name_prefix}"
}

resource "azurerm_public_ip" "gateway" {
  name                = "pip-${local.gateway_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = local.gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  type                = var.gateway_type
  vpn_type            = var.gateway_type == "Vpn" ? "RouteBased" : null
  active_active       = false
  bgp_enabled         = false
  sku                 = var.sku_name
  generation          = var.gateway_type == "Vpn" ? "Generation2" : "None"

  ip_configuration {
    name                 = "gw-ipconfig"
    subnet_id            = var.gateway_subnet_id
    public_ip_address_id = azurerm_public_ip.gateway.id
  }
}

resource "azurerm_monitor_diagnostic_setting" "gateway" {
  name                       = "ds-${local.gateway_name}"
  target_resource_id         = azurerm_virtual_network_gateway.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "GatewayDiagnosticLog"
  }
  enabled_log {
    category = "TunnelDiagnosticLog"
  }
  enabled_log {
    category = "RouteDiagnosticLog"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}
