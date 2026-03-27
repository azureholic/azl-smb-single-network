# ==============================================================================
# General
# ==============================================================================

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "environment" {
  description = "Environment identifier used in resource naming."
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "workload_name" {
  description = "Short workload name used in resource naming."
  type        = string
  default     = "smb"
  validation {
    condition     = length(var.workload_name) <= 10
    error_message = "Workload name must be 10 characters or less."
  }
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Logging
# ==============================================================================

variable "log_retention_in_days" {
  description = "Log Analytics workspace retention in days."
  type        = number
  default     = 90
  validation {
    condition     = var.log_retention_in_days >= 30 && var.log_retention_in_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "log_analytics_sku" {
  description = "Log Analytics workspace SKU."
  type        = string
  default     = "PerGB2018"
  validation {
    condition     = contains(["PerGB2018", "CapacityReservation"], var.log_analytics_sku)
    error_message = "SKU must be PerGB2018 or CapacityReservation."
  }
}

# ==============================================================================
# Networking
# ==============================================================================

variable "vnet_address_prefix" {
  description = "VNET address prefix."
  type        = string
  default     = "10.0.0.0/16"
}

variable "gateway_subnet_prefix" {
  description = "Gateway subnet address prefix."
  type        = string
  default     = "10.0.0.0/27"
}

variable "firewall_subnet_prefix" {
  description = "Azure Firewall subnet address prefix."
  type        = string
  default     = "10.0.0.64/26"
}

variable "bastion_subnet_prefix" {
  description = "Azure Bastion subnet address prefix."
  type        = string
  default     = "10.0.1.0/26"
}

variable "dns_inbound_subnet_prefix" {
  description = "DNS Resolver inbound endpoint subnet address prefix."
  type        = string
  default     = "10.0.1.64/28"
}

variable "dns_outbound_subnet_prefix" {
  description = "DNS Resolver outbound endpoint subnet address prefix."
  type        = string
  default     = "10.0.1.80/28"
}

variable "workload_subnet_prefix" {
  description = "Workload subnet address prefix."
  type        = string
  default     = "10.0.10.0/24"
}

# ==============================================================================
# Optional Features
# ==============================================================================

variable "deploy_bastion" {
  description = "Deploy Azure Bastion."
  type        = bool
  default     = false
}

variable "deploy_firewall" {
  description = "Deploy Azure Firewall."
  type        = bool
  default     = false
}

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.firewall_sku_tier)
    error_message = "Firewall SKU must be Basic, Standard, or Premium."
  }
}

variable "firewall_private_ip" {
  description = "Azure Firewall expected private IP (4th IP in AzureFirewallSubnet)."
  type        = string
  default     = "10.0.0.68"
}

variable "deploy_vpn_gateway" {
  description = "Deploy VPN Gateway."
  type        = bool
  default     = false
}

variable "vpn_gateway_sku" {
  description = "VPN Gateway SKU."
  type        = string
  default     = "VpnGw1AZ"
  validation {
    condition     = contains(["VpnGw1", "VpnGw1AZ", "VpnGw2", "VpnGw2AZ"], var.vpn_gateway_sku)
    error_message = "VPN Gateway SKU must be VpnGw1, VpnGw1AZ, VpnGw2, or VpnGw2AZ."
  }
}

variable "deploy_er_gateway" {
  description = "Deploy ExpressRoute Gateway."
  type        = bool
  default     = false
}

variable "er_gateway_sku" {
  description = "ExpressRoute Gateway SKU."
  type        = string
  default     = "ErGw1AZ"
  validation {
    condition     = contains(["Standard", "HighPerformance", "UltraPerformance", "ErGw1AZ", "ErGw2AZ", "ErGw3AZ"], var.er_gateway_sku)
    error_message = "ExpressRoute Gateway SKU must be Standard, HighPerformance, UltraPerformance, ErGw1AZ, ErGw2AZ, or ErGw3AZ."
  }
}

variable "deploy_dns_resolver" {
  description = "Deploy Private DNS Resolver."
  type        = bool
  default     = false
}

variable "deploy_dns_inbound_endpoint" {
  description = "Deploy DNS Resolver inbound endpoint."
  type        = bool
  default     = true
}

variable "deploy_dns_outbound_endpoint" {
  description = "Deploy DNS Resolver outbound endpoint."
  type        = bool
  default     = true
}

variable "deploy_private_dns_zones" {
  description = "Deploy Private Link DNS Zones."
  type        = bool
  default     = true
}

# ==============================================================================
# Policy
# ==============================================================================

variable "deploy_policies" {
  description = "Deploy Azure Landing Zone policy assignments."
  type        = bool
  default     = true
}

variable "deploy_security_baseline" {
  description = "Deploy Microsoft Cloud Security Benchmark (Azure Security Baseline) policy assignment."
  type        = bool
  default     = true
}

variable "deploy_sovereign_policies" {
  description = "Deploy Sovereignty Baseline - Global Policies."
  type        = bool
  default     = false
}

variable "deploy_sovereign_confidential_policies" {
  description = "Deploy Sovereignty Baseline - Confidential Policies (Azure Confidential Computing enforcement)."
  type        = bool
  default     = false
}

variable "allowed_locations" {
  description = "Allowed Azure locations for policy."
  type        = list(string)
  default     = ["westeurope", "northeurope"]
}
