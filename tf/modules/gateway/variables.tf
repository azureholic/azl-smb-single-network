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

variable "gateway_subnet_id" {
  type = string
}

variable "gateway_type" {
  description = "Vpn or ExpressRoute"
  type        = string
}

variable "sku_name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}
