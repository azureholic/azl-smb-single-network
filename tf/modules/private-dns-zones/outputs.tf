output "dns_zone_ids" {
  value = module.private_link_private_dns_zones.private_dns_zone_resource_ids
}

output "resource_group_resource_id" {
  value = module.private_link_private_dns_zones.resource_group_resource_id
}
