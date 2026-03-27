# SMB Single-Network Azure Landing Zone — Platform (Terraform)

Terraform implementation of the platform deployment for an Azure Landing Zone for Small/Medium Business using a **single VNET** in a **single subscription** that acts as both platform and workload landing zone.

## Architecture

![Architecture](../../docs/architecture.png)

## Azure Verified Modules Used

| Module | Version | Purpose |
|--------|---------|---------|
| `Azure/avm-res-operationalinsights-workspace/azurerm` | 0.5.1 | Log Analytics Workspace |
| `Azure/avm-res-storage-storageaccount/azurerm` | 0.5.0 | Storage Account for logs |
| `Azure/avm-res-automation-automationaccount/azurerm` | 0.2.0 | Automation Account |
| `Azure/avm-res-network-virtualnetwork/azurerm` | 0.17.1 | Virtual Network |
| `Azure/avm-res-network-networksecuritygroup/azurerm` | 0.5.1 | NSGs |
| `Azure/avm-res-network-routetable/azurerm` | 0.5.0 | Route Table (firewall UDR) |
| `Azure/avm-res-network-bastionhost/azurerm` | 0.9.0 | Azure Bastion |
| `Azure/avm-res-network-azurefirewall/azurerm` | 0.4.0 | Azure Firewall |
| `Azure/avm-res-network-firewallpolicy/azurerm` | 0.3.4 | Firewall Policy |
| `Azure/avm-res-network-dnsresolver/azurerm` | 0.8.0 | Private DNS Resolver |
| `Azure/avm-ptn-network-private-link-private-dns-zones/azurerm` | 0.23.1 | All Private Link DNS Zones |
| `Azure/avm-res-keyvault-vault/azurerm` | 0.10.2 | Key Vault |

Native `azurerm` resources are used for VPN/ER Gateway, policy assignments, and policy exemptions (no AVM equivalents at subscription scope).

## File Structure

```
tf/
├── platform/                               # This directory
│   ├── main.tf                             # Main orchestration (resource groups + modules)
│   ├── variables.tf                        # Input variables
│   ├── outputs.tf                          # Outputs
│   ├── providers.tf                        # Provider versions & config
│   ├── terraform.tfvars                    # Default variable values
│   ├── modules/
│   │   ├── logging/                        # LAW, Storage, Automation Account
│   │   ├── networking/                     # VNET, NSGs, Route Tables, Subnets
│   │   ├── key-vault/                      # Key Vault (RBAC, private, purge-protected)
│   │   ├── bastion/                        # Azure Bastion (optional)
│   │   ├── firewall/                       # Azure Firewall + Policy (optional)
│   │   ├── gateway/                        # VPN / ExpressRoute Gateway (optional)
│   │   ├── dns-resolver/                   # Private DNS Resolver (optional)
│   │   ├── private-dns-zones/              # Private Link DNS Zones
│   │   ├── policy-assignments/             # ALZ + MCSB + Sovereignty policy assignments
│   │   └── subnet-policy-exemption/        # NSG policy exemptions for special subnets
│   ├── deploy.ps1                          # PowerShell deployment wrapper
│   └── README.md
└── (workload examples — planned)
```

## Prerequisites

- Terraform >= 1.9.0
- Azure CLI (for authentication)
- Subscription-level permissions (Owner or Contributor + User Access Administrator)

### Providers

| Provider | Version |
|----------|---------|
| `azurerm` | ~> 4.37 |
| `azapi` | ~> 2.4 |
| `modtm` | ~> 0.3 |
| `random` | ~> 3.5 |

## Deployment

### 1. Configure Variables

Edit `terraform.tfvars` to match your environment:

```hcl
location      = "westeurope"
environment   = "prod"
workload_name = "smb"

# Enable optional features
deploy_bastion      = true
deploy_firewall     = true
deploy_vpn_gateway  = true
deploy_dns_resolver = true

# Sovereignty policies (optional)
deploy_sovereign_policies              = true
deploy_sovereign_confidential_policies = false
```

### 2. Deploy

**Using the deployment script:**

```powershell
# Plan
.\deploy.ps1 -Action plan

# Apply
.\deploy.ps1 -Action apply

# Apply without prompt
.\deploy.ps1 -Action apply -AutoApprove
```

**Using Terraform directly:**

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Optional Features

| Feature | Variable | Default |
|---------|----------|---------|
| Azure Bastion | `deploy_bastion` | `false` |
| Azure Firewall | `deploy_firewall` | `false` |
| VPN Gateway | `deploy_vpn_gateway` | `false` |
| ExpressRoute Gateway | `deploy_er_gateway` | `false` |
| Private DNS Resolver | `deploy_dns_resolver` | `false` |
| DNS Resolver Inbound | `deploy_dns_inbound_endpoint` | `true` |
| DNS Resolver Outbound | `deploy_dns_outbound_endpoint` | `true` |
| Private DNS Zones | `deploy_private_dns_zones` | `true` |
| Policy Assignments | `deploy_policies` | `true` |
| Security Baseline (MCSB) | `deploy_security_baseline` | `true` |
| Sovereignty Baseline | `deploy_sovereign_policies` | `false` |
| Sovereignty Confidential | `deploy_sovereign_confidential_policies` | `false` |

## Subnet Addressing (defaults for 10.0.0.0/16)

| Subnet | CIDR | Purpose |
|--------|------|---------|
| GatewaySubnet | 10.0.0.0/27 | VPN / ExpressRoute Gateway |
| AzureFirewallSubnet | 10.0.0.64/26 | Azure Firewall |
| AzureBastionSubnet | 10.0.1.0/26 | Azure Bastion |
| snet-dns-inbound | 10.0.1.64/28 | DNS Resolver Inbound |
| snet-dns-outbound | 10.0.1.80/28 | DNS Resolver Outbound |
| snet-workload | 10.0.10.0/24 | Workloads |

> **Note:** When deploying Azure Firewall, the `firewall_private_ip` variable must match the 4th usable IP in `firewall_subnet_prefix` (e.g., `10.0.0.68` for `10.0.0.64/26`). This is used for the workload subnet route table.

## Policy Assignments

### Azure Security Baseline
- **Microsoft Cloud Security Benchmark (MCSB)** - Comprehensive security baseline initiative

### Sovereignty Baseline (optional)
- **Sovereignty Baseline - Global Policies** - Data residency and compliance controls
- **Sovereignty Baseline - Confidential Policies** - Azure Confidential Computing enforcement

### ALZ Audit/Deny Policies
- Allowed Locations (resources and resource groups)
- Audit VMs without managed disks
- Require secure transfer for storage
- Require minimum TLS 1.2 for storage
- Deny public IP on NICs
- Audit subnets without NSG
- Audit resource location matches resource group

### ALZ DINE Policies (Deploy If Not Exists)
- Activity Log to Log Analytics
- Microsoft Defender for Servers (P1)
- Microsoft Defender for Storage
- Microsoft Defender for SQL
- Microsoft Defender for Key Vaults
- Microsoft Defender for Resource Manager
- Microsoft Defender for DNS

### Policy Exemptions (conditional)

When policy assignments and the relevant optional features are both enabled, NSG policy exemptions are automatically created for subnets that do not support NSG attachment:

| Subnet | Condition |
|--------|-----------|
| GatewaySubnet | `deploy_policies && (deploy_vpn_gateway \|\| deploy_er_gateway)` |
| AzureFirewallSubnet | `deploy_policies && deploy_firewall` |
