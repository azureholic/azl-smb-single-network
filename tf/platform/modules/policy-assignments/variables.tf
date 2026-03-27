variable "location" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "deploy_security_baseline" {
  type = bool
}

variable "deploy_sovereign_policies" {
  type = bool
}

variable "deploy_sovereign_confidential_policies" {
  type = bool
}

variable "allowed_locations" {
  type = list(string)
}
