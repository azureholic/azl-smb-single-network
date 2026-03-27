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

variable "virtual_network_id" {
  type = string
}

variable "deploy_inbound_endpoint" {
  type = bool
}

variable "deploy_outbound_endpoint" {
  type = bool
}

variable "inbound_subnet_name" {
  type = string
}

variable "outbound_subnet_name" {
  type = string
}
