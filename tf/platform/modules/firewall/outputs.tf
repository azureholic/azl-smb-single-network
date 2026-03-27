output "firewall_id" {
  value = module.firewall.resource_id
}

output "firewall_name" {
  value = module.firewall.resource.name
}

output "firewall_private_ip" {
  value = module.firewall.resource.ip_configuration[0].private_ip_address
}

output "firewall_policy_id" {
  value = module.firewall_policy.resource_id
}
