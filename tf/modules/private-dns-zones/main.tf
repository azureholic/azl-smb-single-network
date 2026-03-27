module "private_link_private_dns_zones" {
  source  = "Azure/avm-ptn-network-private-link-private-dns-zones/azurerm"
  version = "0.23.1"

  location         = var.location
  parent_id        = var.resource_group_id
  tags             = var.tags
  enable_telemetry = false

  virtual_network_link_default_virtual_networks = {
    primary = {
      virtual_network_resource_id = var.virtual_network_id
    }
  }
}
