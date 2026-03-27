variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "vnet_address_prefix" {
  type = string
}

variable "workload_subnet_prefix" {
  type = string
}

variable "gateway_subnet_prefix" {
  type = string
}

variable "firewall_subnet_prefix" {
  type = string
}

variable "bastion_subnet_prefix" {
  type = string
}

variable "dns_inbound_subnet_prefix" {
  type = string
}

variable "dns_outbound_subnet_prefix" {
  type = string
}

variable "deploy_bastion" {
  type = bool
}

variable "deploy_firewall" {
  type = bool
}

variable "deploy_gateway" {
  type = bool
}

variable "deploy_dns_resolver" {
  type = bool
}

variable "deploy_dns_inbound_endpoint" {
  type = bool
}

variable "deploy_dns_outbound_endpoint" {
  type = bool
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "firewall_private_ip" {
  type = string
}
