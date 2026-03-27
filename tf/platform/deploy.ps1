#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy or plan the SMB Landing Zone using Terraform.
.DESCRIPTION
    Wrapper script for Terraform operations. Supports plan, apply, and destroy.
.PARAMETER Action
    Terraform action: plan, apply, or destroy.
.PARAMETER AutoApprove
    Skip interactive approval for apply/destroy.
.EXAMPLE
    .\deploy.ps1 -Action plan
    .\deploy.ps1 -Action apply -AutoApprove
#>

param(
    [ValidateSet('plan', 'apply', 'destroy')]
    [string]$Action = 'plan',

    [switch]$AutoApprove
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# Verify terraform is available
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error "Terraform CLI not found. Install from https://developer.hashicorp.com/terraform/downloads"
}

# Initialize if needed
if (-not (Test-Path '.terraform')) {
    Write-Host "Initializing Terraform..." -ForegroundColor Cyan
    terraform init
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

# Show current subscription
$account = az account show 2>$null | ConvertFrom-Json
if ($account) {
    Write-Host "Azure Subscription: $($account.name) ($($account.id))" -ForegroundColor Green
}

# Execute
switch ($Action) {
    'plan' {
        Write-Host "`nRunning terraform plan..." -ForegroundColor Cyan
        terraform plan -var-file="terraform.tfvars" -out="tfplan"
    }
    'apply' {
        $approveFlag = if ($AutoApprove) { '-auto-approve' } else { '' }
        if (Test-Path 'tfplan') {
            Write-Host "`nApplying saved plan..." -ForegroundColor Cyan
            terraform apply $approveFlag "tfplan"
        } else {
            Write-Host "`nRunning terraform apply..." -ForegroundColor Cyan
            terraform apply $approveFlag -var-file="terraform.tfvars"
        }
    }
    'destroy' {
        $approveFlag = if ($AutoApprove) { '-auto-approve' } else { '' }
        Write-Host "`nRunning terraform destroy..." -ForegroundColor Red
        terraform destroy $approveFlag -var-file="terraform.tfvars"
    }
}

exit $LASTEXITCODE
