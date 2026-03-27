# ==============================================================================
# SMB Single-Network Landing Zone - Terraform
# ==============================================================================

locals {
  name_prefix = "${var.workload_name}-${var.environment}"

  rg_logging_name    = "rg-${local.name_prefix}-logging"
  rg_networking_name = "rg-${local.name_prefix}-networking"
  rg_dns_name        = "rg-${local.name_prefix}-dns"
  rg_security_name   = "rg-${local.name_prefix}-security"

  deploy_gateway = var.deploy_vpn_gateway || var.deploy_er_gateway

  default_tags = merge(var.tags, {
    environment = var.environment
    workload    = var.workload_name
    deployedBy  = "terraform"
  })
}

# ==============================================================================
# Resource Groups
# ==============================================================================

resource "azurerm_resource_group" "logging" {
  name     = local.rg_logging_name
  location = var.location
  tags     = local.default_tags
}

resource "azurerm_resource_group" "networking" {
  name     = local.rg_networking_name
  location = var.location
  tags     = local.default_tags
}

resource "azurerm_resource_group" "dns" {
  count    = var.deploy_private_dns_zones ? 1 : 0
  name     = local.rg_dns_name
  location = var.location
  tags     = local.default_tags
}

resource "azurerm_resource_group" "security" {
  name     = local.rg_security_name
  location = var.location
  tags     = local.default_tags
}

# ==============================================================================
# Logging
# ==============================================================================

module "logging" {
  source = "./modules/logging"

  location           = var.location
  name_prefix        = local.name_prefix
  tags               = local.default_tags
  retention_in_days  = var.log_retention_in_days
  log_analytics_sku  = var.log_analytics_sku
  resource_group_name = azurerm_resource_group.logging.name
}

# ==============================================================================
# Security - Key Vault
# ==============================================================================

module "key_vault" {
  source = "./modules/key-vault"

  location                  = var.location
  name_prefix               = local.name_prefix
  tags                      = local.default_tags
  resource_group_name       = azurerm_resource_group.security.name
  log_analytics_workspace_id = module.logging.log_analytics_workspace_id
}

# ==============================================================================
# Activity Log Diagnostic Settings (subscription scope)
# ==============================================================================

data "azurerm_subscription" "current" {}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "ds-activitylog-${local.name_prefix}"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = module.logging.log_analytics_workspace_id
  storage_account_id         = module.logging.storage_account_id

  enabled_log {
    category = "Administrative"
  }
  enabled_log {
    category = "Security"
  }
  enabled_log {
    category = "ServiceHealth"
  }
  enabled_log {
    category = "Alert"
  }
  enabled_log {
    category = "Recommendation"
  }
  enabled_log {
    category = "Policy"
  }
  enabled_log {
    category = "Autoscale"
  }
  enabled_log {
    category = "ResourceHealth"
  }
}

# ==============================================================================
# Networking
# ==============================================================================

module "networking" {
  source = "./modules/networking"

  location                    = var.location
  name_prefix                 = local.name_prefix
  tags                        = local.default_tags
  resource_group_name         = azurerm_resource_group.networking.name
  resource_group_id           = azurerm_resource_group.networking.id
  vnet_address_prefix         = var.vnet_address_prefix
  workload_subnet_prefix      = var.workload_subnet_prefix
  gateway_subnet_prefix       = var.gateway_subnet_prefix
  firewall_subnet_prefix      = var.firewall_subnet_prefix
  bastion_subnet_prefix       = var.bastion_subnet_prefix
  dns_inbound_subnet_prefix   = var.dns_inbound_subnet_prefix
  dns_outbound_subnet_prefix  = var.dns_outbound_subnet_prefix
  deploy_bastion              = var.deploy_bastion
  deploy_firewall             = var.deploy_firewall
  deploy_gateway              = local.deploy_gateway
  deploy_dns_resolver         = var.deploy_dns_resolver
  deploy_dns_inbound_endpoint = var.deploy_dns_inbound_endpoint
  deploy_dns_outbound_endpoint = var.deploy_dns_outbound_endpoint
  log_analytics_workspace_id  = module.logging.log_analytics_workspace_id
  firewall_private_ip         = var.firewall_private_ip
}

# ==============================================================================
# Optional: Azure Bastion
# ==============================================================================

module "bastion" {
  source = "./modules/bastion"
  count  = var.deploy_bastion ? 1 : 0

  location                   = var.location
  name_prefix                = local.name_prefix
  tags                       = local.default_tags
  resource_group_name        = azurerm_resource_group.networking.name
  resource_group_id          = azurerm_resource_group.networking.id
  virtual_network_id         = module.networking.vnet_id
  bastion_subnet_id          = module.networking.bastion_subnet_id
  log_analytics_workspace_id = module.logging.log_analytics_workspace_id
}

# ==============================================================================
# Optional: Azure Firewall
# ==============================================================================

module "firewall" {
  source = "./modules/firewall"
  count  = var.deploy_firewall ? 1 : 0

  location                   = var.location
  name_prefix                = local.name_prefix
  tags                       = local.default_tags
  resource_group_name        = azurerm_resource_group.networking.name
  firewall_subnet_id         = module.networking.firewall_subnet_id
  sku_tier                   = var.firewall_sku_tier
  log_analytics_workspace_id = module.logging.log_analytics_workspace_id
}

# ==============================================================================
# Optional: VPN Gateway
# ==============================================================================

module "vpn_gateway" {
  source = "./modules/gateway"
  count  = var.deploy_vpn_gateway ? 1 : 0

  location                   = var.location
  name_prefix                = local.name_prefix
  tags                       = local.default_tags
  resource_group_name        = azurerm_resource_group.networking.name
  gateway_subnet_id          = module.networking.gateway_subnet_id
  gateway_type               = "Vpn"
  sku_name                   = var.vpn_gateway_sku
  log_analytics_workspace_id = module.logging.log_analytics_workspace_id
}

# ==============================================================================
# Optional: ExpressRoute Gateway
# ==============================================================================

module "er_gateway" {
  source = "./modules/gateway"
  count  = var.deploy_er_gateway ? 1 : 0

  location                   = var.location
  name_prefix                = local.name_prefix
  tags                       = local.default_tags
  resource_group_name        = azurerm_resource_group.networking.name
  gateway_subnet_id          = module.networking.gateway_subnet_id
  gateway_type               = "ExpressRoute"
  sku_name                   = var.er_gateway_sku
  log_analytics_workspace_id = module.logging.log_analytics_workspace_id
}

# ==============================================================================
# Optional: Private DNS Resolver
# ==============================================================================

module "dns_resolver" {
  source = "./modules/dns-resolver"
  count  = var.deploy_dns_resolver ? 1 : 0

  location                    = var.location
  name_prefix                 = local.name_prefix
  tags                        = local.default_tags
  resource_group_name         = azurerm_resource_group.networking.name
  virtual_network_id          = module.networking.vnet_id
  deploy_inbound_endpoint     = var.deploy_dns_inbound_endpoint
  deploy_outbound_endpoint    = var.deploy_dns_outbound_endpoint
  inbound_subnet_name         = "snet-dns-inbound"
  outbound_subnet_name        = "snet-dns-outbound"
}

# ==============================================================================
# Private DNS Zones
# ==============================================================================

module "private_dns_zones" {
  source = "./modules/private-dns-zones"
  count  = var.deploy_private_dns_zones ? 1 : 0

  location            = var.location
  resource_group_id   = azurerm_resource_group.dns[0].id
  tags                = local.default_tags
  virtual_network_id  = module.networking.vnet_id
}

# ==============================================================================
# Policy Assignments (subscription scope)
# ==============================================================================

module "policy_assignments" {
  source = "./modules/policy-assignments"
  count  = var.deploy_policies ? 1 : 0

  location                              = var.location
  log_analytics_workspace_id            = module.logging.log_analytics_workspace_id
  deploy_security_baseline              = var.deploy_security_baseline
  deploy_sovereign_policies             = var.deploy_sovereign_policies
  deploy_sovereign_confidential_policies = var.deploy_sovereign_confidential_policies
  allowed_locations                     = var.allowed_locations
}

# ==============================================================================
# Policy Exemptions (subnets that cannot have NSGs)
# ==============================================================================

module "exempt_gateway_subnet_nsg" {
  source = "./modules/subnet-policy-exemption"
  count  = var.deploy_policies && local.deploy_gateway ? 1 : 0

  exemption_name                   = "exempt-gatewaysubnet-nsg"
  display_name                     = "GatewaySubnet - NSG not supported"
  exemption_description            = "GatewaySubnet does not support NSG attachment. Network security is provided by the Azure platform for VPN/ExpressRoute gateway traffic."
  policy_assignment_id             = module.policy_assignments[0].mcsb_assignment_id
  policy_definition_reference_ids  = ["networkSecurityGroupsOnSubnetsMonitoring"]
  resource_group_name              = azurerm_resource_group.networking.name
  subnet_id                        = module.networking.gateway_subnet_id

  depends_on = [module.policy_assignments]
}

module "exempt_firewall_subnet_nsg" {
  source = "./modules/subnet-policy-exemption"
  count  = var.deploy_policies && var.deploy_firewall ? 1 : 0

  exemption_name                   = "exempt-firewallsubnet-nsg"
  display_name                     = "AzureFirewallSubnet - NSG not supported"
  exemption_description            = "AzureFirewallSubnet does not support NSG attachment. Azure Firewall provides its own network filtering capabilities."
  policy_assignment_id             = module.policy_assignments[0].mcsb_assignment_id
  policy_definition_reference_ids  = ["networkSecurityGroupsOnSubnetsMonitoring"]
  resource_group_name              = azurerm_resource_group.networking.name
  subnet_id                        = module.networking.firewall_subnet_id

  depends_on = [module.policy_assignments]
}
