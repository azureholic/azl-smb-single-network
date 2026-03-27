output "vnet_id" {
  value = module.vnet.resource_id
}

output "vnet_name" {
  value = module.vnet.name
}

output "workload_subnet_id" {
  value = module.vnet.subnets["workload"].resource_id
}

output "gateway_subnet_id" {
  value = var.deploy_gateway ? module.vnet.subnets["gateway"].resource_id : ""
}

output "firewall_subnet_id" {
  value = var.deploy_firewall ? module.vnet.subnets["firewall"].resource_id : ""
}

output "bastion_subnet_id" {
  value = var.deploy_bastion ? module.vnet.subnets["bastion"].resource_id : ""
}

output "dns_inbound_subnet_id" {
  value = var.deploy_dns_resolver && var.deploy_dns_inbound_endpoint ? module.vnet.subnets["dns_inbound"].resource_id : ""
}

output "dns_outbound_subnet_id" {
  value = var.deploy_dns_resolver && var.deploy_dns_outbound_endpoint ? module.vnet.subnets["dns_outbound"].resource_id : ""
}
