variable "exemption_name" {
  type = string
}

variable "display_name" {
  type = string
}

variable "exemption_description" {
  type = string
}

variable "policy_assignment_id" {
  type = string
}

variable "policy_definition_reference_ids" {
  description = "Policy definition reference IDs to scope the exemption within an initiative."
  type        = list(string)
  default     = []
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}
