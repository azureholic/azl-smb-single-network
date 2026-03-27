resource "azurerm_resource_policy_exemption" "this" {
  name                            = var.exemption_name
  resource_id                     = var.subnet_id
  policy_assignment_id            = var.policy_assignment_id
  exemption_category              = "Mitigated"
  display_name                    = var.display_name
  description                     = var.exemption_description
  policy_definition_reference_ids = length(var.policy_definition_reference_ids) > 0 ? var.policy_definition_reference_ids : null
}
