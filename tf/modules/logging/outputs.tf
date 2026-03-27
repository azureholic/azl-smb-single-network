output "log_analytics_workspace_id" {
  value = module.law.resource_id
}

output "log_analytics_workspace_name" {
  value = module.law.resource.name
}

output "storage_account_id" {
  value = module.storage.resource_id
}

output "storage_account_name" {
  value = module.storage.name
}

output "automation_account_id" {
  value = module.automation.resource_id
}
