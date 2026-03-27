variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "retention_in_days" {
  type = number
}

variable "log_analytics_sku" {
  type = string
}

variable "resource_group_name" {
  type = string
}
