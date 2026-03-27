module "bastion" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "0.9.0"

  name             = "bas-${var.name_prefix}"
  location         = var.location
  parent_id        = var.resource_group_id
  tags             = var.tags
  sku              = "Standard"
  file_copy_enabled = true
  enable_telemetry = false

  ip_configuration = {
    name             = "bastion-ipconfig"
    subnet_id        = var.bastion_subnet_id
    create_public_ip = true
  }

  diagnostic_settings = {
    to_law = {
      workspace_resource_id = var.log_analytics_workspace_id
      log_categories        = ["BastionAuditLogs"]
      metric_categories     = ["AllMetrics"]
    }
  }
}
