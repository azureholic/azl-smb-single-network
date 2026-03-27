# ==============================================================================
# NSG - Workload Subnet (AVM)
# ==============================================================================

module "nsg_workload" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = "nsg-${var.name_prefix}-workload"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  enable_telemetry    = false

  security_rules = {
    DenyAllInbound = {
      access                     = "Deny"
      direction                  = "Inbound"
      name                       = "DenyAllInbound"
      priority                   = 4096
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  diagnostic_settings = {
    to_law = {
      workspace_resource_id = var.log_analytics_workspace_id
      log_groups            = ["allLogs"]
    }
  }
}

# ==============================================================================
# NSG - Bastion Subnet (AVM)
# ==============================================================================

module "nsg_bastion" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"
  count   = var.deploy_bastion ? 1 : 0

  name                = "nsg-${var.name_prefix}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  enable_telemetry    = false

  security_rules = {
    AllowHttpsInbound = {
      access                     = "Allow"
      direction                  = "Inbound"
      name                       = "AllowHttpsInbound"
      priority                   = 120
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    AllowGatewayManagerInbound = {
      access                     = "Allow"
      direction                  = "Inbound"
      name                       = "AllowGatewayManagerInbound"
      priority                   = 130
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    }
    AllowAzureLoadBalancerInbound = {
      access                     = "Allow"
      direction                  = "Inbound"
      name                       = "AllowAzureLoadBalancerInbound"
      priority                   = 140
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    }
    AllowBastionHostCommunicationInbound = {
      access                     = "Allow"
      direction                  = "Inbound"
      name                       = "AllowBastionHostCommunicationInbound"
      priority                   = 150
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    AllowSshRdpOutbound = {
      access                     = "Allow"
      direction                  = "Outbound"
      name                       = "AllowSshRdpOutbound"
      priority                   = 100
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
    }
    AllowAzureCloudOutbound = {
      access                     = "Allow"
      direction                  = "Outbound"
      name                       = "AllowAzureCloudOutbound"
      priority                   = 110
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
    }
    AllowBastionHostCommunicationOutbound = {
      access                     = "Allow"
      direction                  = "Outbound"
      name                       = "AllowBastionHostCommunicationOutbound"
      priority                   = 120
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    AllowGetSessionInformationOutbound = {
      access                     = "Allow"
      direction                  = "Outbound"
      name                       = "AllowGetSessionInformationOutbound"
      priority                   = 130
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    }
  }

  diagnostic_settings = {
    to_law = {
      workspace_resource_id = var.log_analytics_workspace_id
      log_groups            = ["allLogs"]
    }
  }
}

# ==============================================================================
# Route Table - Workload Subnet (AVM)
# ==============================================================================

module "rt_workload" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.5.0"
  count   = var.deploy_firewall ? 1 : 0

  name                          = "rt-${var.name_prefix}-workload"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = var.tags
  bgp_route_propagation_enabled = true
  enable_telemetry              = false

  routes = {
    default_via_firewall = {
      name                   = "default-via-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_private_ip
    }
  }
}

# ==============================================================================
# Virtual Network (AVM)
# ==============================================================================

locals {
  workload_subnet = {
    workload = {
      name             = "snet-workload"
      address_prefixes = [var.workload_subnet_prefix]
      network_security_group = {
        id = module.nsg_workload.resource_id
      }
      route_table = var.deploy_firewall ? {
        id = module.rt_workload[0].resource_id
      } : null
    }
  }

  gateway_subnet = var.deploy_gateway ? {
    gateway = {
      name             = "GatewaySubnet"
      address_prefixes = [var.gateway_subnet_prefix]
    }
  } : {}

  firewall_subnet = var.deploy_firewall ? {
    firewall = {
      name             = "AzureFirewallSubnet"
      address_prefixes = [var.firewall_subnet_prefix]
    }
  } : {}

  bastion_subnet = var.deploy_bastion ? {
    bastion = {
      name             = "AzureBastionSubnet"
      address_prefixes = [var.bastion_subnet_prefix]
      network_security_group = {
        id = module.nsg_bastion[0].resource_id
      }
    }
  } : {}

  dns_inbound_subnet = var.deploy_dns_resolver && var.deploy_dns_inbound_endpoint ? {
    dns_inbound = {
      name             = "snet-dns-inbound"
      address_prefixes = [var.dns_inbound_subnet_prefix]
      delegations = [
        {
          name = "Microsoft.Network.dnsResolvers"
          service_delegation = {
            name    = "Microsoft.Network/dnsResolvers"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
          }
        }
      ]
    }
  } : {}

  dns_outbound_subnet = var.deploy_dns_resolver && var.deploy_dns_outbound_endpoint ? {
    dns_outbound = {
      name             = "snet-dns-outbound"
      address_prefixes = [var.dns_outbound_subnet_prefix]
      delegations = [
        {
          name = "Microsoft.Network.dnsResolvers"
          service_delegation = {
            name    = "Microsoft.Network/dnsResolvers"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
          }
        }
      ]
    }
  } : {}
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  name             = "vnet-${var.name_prefix}"
  location         = var.location
  parent_id        = var.resource_group_id
  tags             = var.tags
  address_space    = [var.vnet_address_prefix]
  enable_telemetry = false

  subnets = merge(
    local.workload_subnet,
    local.gateway_subnet,
    local.firewall_subnet,
    local.bastion_subnet,
    local.dns_inbound_subnet,
    local.dns_outbound_subnet
  )

  diagnostic_settings = {
    to_law = {
      workspace_resource_id = var.log_analytics_workspace_id
      log_categories        = ["VMProtectionAlerts"]
      metric_categories     = ["AllMetrics"]
    }
  }
}
