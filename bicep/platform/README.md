# SMB Single-Network Azure Landing Zone — Platform

Platform deployment for an Azure Landing Zone for Small/Medium Business using a **single VNET** in a **single subscription** that acts as both platform and workload landing zone.

## Architecture

![Architecture](../../docs/architecture.png)

> Edit the source: [`docs/architecture.drawio`](../../docs/architecture.drawio) — open with the [Draw.io VS Code extension](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio) or [app.diagrams.net](https://app.diagrams.net).

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
| `avm/res/key-vault/vault` | 0.13.3 | Key Vault |

## File Structure

```
bicep/
├── platform/                               # This directory
│   ├── main.bicep                          # Main orchestration (subscription scope)
│   ├── main.bicepparam                     # Parameters file
│   ├── bicepconfig.json                    # Bicep configuration
│   ├── modules/
│   │   ├── logging.bicep                   # LAW, Storage, Automation Account
│   │   ├── networking.bicep                # VNET, NSGs, Route Tables, Subnets
│   │   ├── keyVault.bicep                  # Key Vault (RBAC, private, purge-protected)
│   │   ├── bastion.bicep                   # Azure Bastion (optional)
│   │   ├── firewall.bicep                  # Azure Firewall + Policy (optional)
│   │   ├── gateway.bicep                   # VPN / ExpressRoute Gateway (optional)
│   │   ├── dnsResolver.bicep               # Private DNS Resolver (optional)
│   │   ├── privateDnsZones.bicep           # Private Link DNS Zones
│   │   ├── policyAssignments.bicep         # ALZ + MCSB + Sovereignty policy assignments
│   │   └── subnetPolicyExemption.bicep     # NSG policy exemptions for special subnets
│   ├── deploy.ps1                          # PowerShell deployment script
│   └── README.md
└── (workload examples — planned)
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

// Sovereignty policies (optional)
param deploySovereignPolicies = true
param deploySovereignConfidentialPolicies = false
```

### 2. Deploy

The deployment script reads `location` from the `.bicepparam` file and uses your current `az` account subscription.

**Deploy:**

```powershell
.\deploy.ps1
```

**Preview changes first:**

```powershell
.\deploy.ps1 -WhatIf
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
| Sovereignty Baseline | `deploySovereignPolicies` | `false` |
| Sovereignty Confidential | `deploySovereignConfidentialPolicies` | `false` |

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
| GatewaySubnet | `deployPolicies && (deployVpnGateway \|\| deployErGateway)` |
| AzureFirewallSubnet | `deployPolicies && deployFirewall` |
