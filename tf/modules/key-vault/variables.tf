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

variable "log_analytics_workspace_id" {
  type = string
}
