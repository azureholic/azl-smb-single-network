output "mcsb_assignment_id" {
  description = "MCSB policy assignment ID, used for exemptions."
  value       = var.deploy_security_baseline ? azurerm_subscription_policy_assignment.mcsb[0].id : ""
}
