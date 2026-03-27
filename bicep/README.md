# SMB Single-Network Azure Landing Zone

An Azure Landing Zone for Small/Medium Business using a **single VNET** in a **single subscription** that acts as both platform and workload landing zone.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ Subscription (Platform + Workload)                              │
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────────────────────────┐ │
│  │ rg-*-logging      │  │ rg-*-networking                      │ │
│  │                   │  │                                      │ │
│  │ • Log Analytics   │  │ • VNET (10.0.0.0/16)                │ │
│  │ • Storage Account │  │   ├ GatewaySubnet      (optional)   │ │
│  │ • Automation Acct  │  │   ├ AzureFirewallSubnet (optional)  │ │
│  │                   │  │   ├ AzureBastionSubnet  (optional)  │ │
│  └──────────────────┘  │   ├ snet-dns-inbound    (optional)  │ │
│                         │   ├ snet-dns-outbound   (optional)  │ │
│  ┌──────────────────┐  │   └ snet-workload                   │ │
│  │ rg-*-dns          │  │                                      │ │
│  │                   │  │ • Azure Bastion         (optional)  │ │
│  │ • Private DNS     │  │ • Azure Firewall        (optional)  │ │
│  │   Zones (all PL)  │  │ • VPN/ER Gateway        (optional)  │ │
│  └──────────────────┘  │ • Private DNS Resolver   (optional)  │ │
│                         └──────────────────────────────────────┘ │
│                                                                 │
│  Policy Assignments (subscription scope):                       │
│  • Microsoft Cloud Security Benchmark (MCSB)                    │
│  • ALZ Allowed Locations                                        │
│  • ALZ Deny Public IP on NIC                                    │
│  • ALZ Audit Subnets without NSG                                │
│  • ALZ Secure Transfer / TLS 1.2 for Storage                   │
│  • Microsoft Defender for Cloud (Servers, Storage, SQL, KV,     │
│    ARM, DNS)                                                    │
│  • Activity Log to Log Analytics                                │
└─────────────────────────────────────────────────────────────────┘
```

## Azure Verified Modules Used

| Module | Version | Purpose |
|--------|---------|---------|
| `avm/res/operational-insights/workspace` | 0.15.0 | Log Analytics Workspace |
| `avm/res/storage/storage-account` | 0.32.0 | Storage Account for logs |
| `avm/res/automation/automation-account` | 0.18.0 | Automation Account |
| `avm/res/insights/diagnostic-setting` | 0.1.4 | Activity Log diagnostics |
| `avm/res/network/virtual-network` | 0.7.2 | Virtual Network |
| `avm/res/network/network-security-group` | 0.5.3 | NSGs |
| `avm/res/network/route-table` | 0.5.0 | Route Table (firewall UDR) |
| `avm/res/network/bastion-host` | 0.8.2 | Azure Bastion |
| `avm/res/network/azure-firewall` | 0.10.0 | Azure Firewall |
| `avm/res/network/firewall-policy` | 0.3.4 | Firewall Policy |
| `avm/res/network/virtual-network-gateway` | 0.10.1 | VPN / ER Gateway |
| `avm/res/network/dns-resolver` | 0.5.6 | Private DNS Resolver |
| `avm/res/network/dns-forwarding-ruleset` | 0.5.3 | DNS Forwarding Ruleset |
| `avm/ptn/network/private-link-private-dns-zones` | 0.7.2 | All Private Link DNS Zones |

## File Structure

```
├── main.bicep                          # Main orchestration (subscription scope)
├── main.bicepparam                     # Parameters file
├── bicepconfig.json                    # Bicep configuration
├── modules/
│   ├── logging.bicep                   # LAW, Storage, Automation Account
│   ├── networking.bicep                # VNET, NSGs, Route Tables, Subnets
│   ├── bastion.bicep                   # Azure Bastion (optional)
│   ├── firewall.bicep                  # Azure Firewall + Policy (optional)
│   ├── gateway.bicep                   # VPN / ExpressRoute Gateway (optional)
│   ├── dnsResolver.bicep               # Private DNS Resolver (optional)
│   ├── privateDnsZones.bicep           # Private Link DNS Zones
│   └── policyAssignments.bicep         # ALZ + MCSB policy assignments
├── deploy.ps1                          # PowerShell deployment script
└── README.md
```

## Prerequisites

- Azure CLI with Bicep extension (`az bicep install`)
- Azure PowerShell module (`Az.Accounts`, `Az.Resources`)
- Subscription-level permissions (Owner or Contributor + User Access Administrator)

## Deployment

### 1. Configure Parameters

Edit `main.bicepparam` to match your environment:

```bicep
param location = 'westeurope'
param environment = 'prod'
param workloadName = 'smb'

// Enable optional features
param deployBastion = true
param deployFirewall = true
param deployVpnGateway = true
param deployDnsResolver = true
```

### 2. Deploy

**Using the deployment script:**

```powershell
.\deploy.ps1 -SubscriptionId "<subscription-id>" -Location "westeurope"
```

**Preview changes first:**

```powershell
.\deploy.ps1 -SubscriptionId "<subscription-id>" -Location "westeurope" -WhatIf
```

**Using Azure CLI directly:**

```bash
az deployment sub create \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.bicepparam
```

## Optional Features

| Feature | Parameter | Default |
|---------|-----------|---------|
| Azure Bastion | `deployBastion` | `false` |
| Azure Firewall | `deployFirewall` | `false` |
| VPN Gateway | `deployVpnGateway` | `false` |
| ExpressRoute Gateway | `deployErGateway` | `false` |
| Private DNS Resolver | `deployDnsResolver` | `false` |
| DNS Resolver Inbound | `deployDnsInboundEndpoint` | `true` |
| DNS Resolver Outbound | `deployDnsOutboundEndpoint` | `true` |
| Private DNS Zones | `deployPrivateDnsZones` | `true` |
| Policy Assignments | `deployPolicies` | `true` |
| Security Baseline (MCSB) | `deploySecurityBaseline` | `true` |

## Subnet Addressing (defaults for 10.0.0.0/16)

| Subnet | CIDR | Purpose |
|--------|------|---------|
| GatewaySubnet | 10.0.0.0/27 | VPN / ExpressRoute Gateway |
| AzureFirewallSubnet | 10.0.0.64/26 | Azure Firewall |
| AzureBastionSubnet | 10.0.1.0/26 | Azure Bastion |
| snet-dns-inbound | 10.0.1.64/28 | DNS Resolver Inbound |
| snet-dns-outbound | 10.0.1.80/28 | DNS Resolver Outbound |
| snet-workload | 10.0.10.0/24 | Workloads |

> **Note:** When deploying Azure Firewall, the `firewallPrivateIp` parameter must match the 4th usable IP in `firewallSubnetPrefix` (e.g., `10.0.0.68` for `10.0.0.64/26`). This is used for the workload subnet route table.

## Policy Assignments

### Azure Security Baseline
- **Microsoft Cloud Security Benchmark (MCSB)** - Comprehensive security baseline initiative

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
