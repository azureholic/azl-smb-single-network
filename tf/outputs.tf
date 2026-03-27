output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID."
  value       = module.logging.log_analytics_workspace_id
}

output "storage_account_id" {
  description = "Logging storage account resource ID."
  value       = module.logging.storage_account_id
}

output "vnet_id" {
  description = "Virtual Network resource ID."
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Virtual Network name."
  value       = module.networking.vnet_name
}

output "bastion_id" {
  description = "Azure Bastion resource ID."
  value       = var.deploy_bastion ? module.bastion[0].bastion_id : ""
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP address."
  value       = var.deploy_firewall ? var.firewall_private_ip : ""
}

output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = module.key_vault.key_vault_id
}

output "key_vault_name" {
  description = "Key Vault name."
  value       = module.key_vault.key_vault_name
}
