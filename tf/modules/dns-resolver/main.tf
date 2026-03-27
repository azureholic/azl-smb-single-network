module "dns_resolver" {
  source  = "Azure/avm-res-network-dnsresolver/azurerm"
  version = "0.8.0"

  name                       = "dnspr-${var.name_prefix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tags                       = var.tags
  virtual_network_resource_id = var.virtual_network_id
  enable_telemetry           = false

  inbound_endpoints = var.deploy_inbound_endpoint ? {
    inbound = {
      name        = "inbound"
      subnet_name = var.inbound_subnet_name
    }
  } : {}

  outbound_endpoints = var.deploy_outbound_endpoint ? {
    outbound = {
      name        = "outbound"
      subnet_name = var.outbound_subnet_name
      forwarding_ruleset = {
        default = {
          name                                      = "dnsfrs-${var.name_prefix}"
          link_with_outbound_endpoint_virtual_network = true
        }
      }
    }
  } : {}
}
