location        = "westeurope"
subscription_id = "" # Set your subscription ID
environment     = "dev"
workload_name   = "tf"
tags = {
  project = "smb-landing-zone"
  owner   = "platform-team"
}

# Logging
log_retention_in_days = 90
log_analytics_sku     = "PerGB2018"

# Networking
vnet_address_prefix        = "10.0.0.0/16"
gateway_subnet_prefix      = "10.0.0.0/27"
firewall_subnet_prefix     = "10.0.0.64/26"
bastion_subnet_prefix      = "10.0.1.0/26"
dns_inbound_subnet_prefix  = "10.0.1.64/28"
dns_outbound_subnet_prefix = "10.0.1.80/28"
workload_subnet_prefix     = "10.0.10.0/24"

# Optional features - set to true to enable
deploy_bastion               = false
deploy_firewall              = false
firewall_sku_tier            = "Standard"
firewall_private_ip          = "10.0.0.68"
deploy_vpn_gateway           = false
vpn_gateway_sku              = "VpnGw1AZ"
deploy_er_gateway            = false
er_gateway_sku               = "ErGw1AZ"
deploy_dns_resolver          = false
deploy_dns_inbound_endpoint  = true
deploy_dns_outbound_endpoint = true

# Private DNS Zones
deploy_private_dns_zones = true

# Policy
deploy_policies                        = true
deploy_security_baseline               = true
deploy_sovereign_policies              = false
deploy_sovereign_confidential_policies = false
allowed_locations                      = ["westeurope", "northeurope", "uksouth"]
