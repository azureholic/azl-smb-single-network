<#
.SYNOPSIS
    Deploys the SMB Single-Network Landing Zone using Azure CLI.

.DESCRIPTION
    Deploys the Azure Landing Zone for SMB with a single VNET, logging,
    private DNS zones, optional features, and ALZ policy assignments.
    Uses the current az account subscription. Reads the location from
    the .bicepparam file.

.PARAMETER ParameterFile
    Path to the .bicepparam file. Defaults to main.bicepparam.

.PARAMETER WhatIf
    Run a what-if deployment instead of actual deployment.

.EXAMPLE
    .\deploy.ps1

.EXAMPLE
    .\deploy.ps1 -WhatIf
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ParameterFile = "main.bicepparam",

    [Parameter()]
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Extract location from bicepparam file
$locationMatch = Select-String -Path $ParameterFile -Pattern "^param location\s*=\s*'([^']+)'" | Select-Object -First 1
if (-not $locationMatch) {
    Write-Error "Could not find 'param location' in $ParameterFile"
    exit 1
}
$Location = $locationMatch.Matches[0].Groups[1].Value

# Verify az CLI is logged in and get current subscription
$account = az account show --output json 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in to Azure CLI. Running az login..." -ForegroundColor Yellow
    az login
    $account = az account show --output json
}
$accountObj = $account | ConvertFrom-Json
$subscriptionName = $accountObj.name
$subscriptionId = $accountObj.id

$deploymentName = "smb-lz-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "`nSubscription: $subscriptionName ($subscriptionId)" -ForegroundColor Cyan
Write-Host "Deployment:   $deploymentName" -ForegroundColor Cyan
Write-Host "Location:     $Location" -ForegroundColor Cyan
Write-Host "Parameters:   $ParameterFile" -ForegroundColor Cyan
Write-Host ""

if ($WhatIf) {
    Write-Host "Running What-If deployment..." -ForegroundColor Yellow
    az deployment sub what-if `
        --name $deploymentName `
        --location $Location `
        --template-file "main.bicep" `
        --parameters $ParameterFile
} else {
    Write-Host "Starting deployment..." -ForegroundColor Green
    az deployment sub create `
        --name $deploymentName `
        --location $Location `
        --template-file "main.bicep" `
        --parameters $ParameterFile

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
        az deployment sub show --name $deploymentName --query properties.outputs --output table
    } else {
        Write-Host "`nDeployment failed!" -ForegroundColor Red
        exit 1
    }
}
