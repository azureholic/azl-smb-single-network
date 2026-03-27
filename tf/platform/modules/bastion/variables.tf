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

variable "virtual_network_id" {
  type = string
}

variable "bastion_subnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}
