# =============================================================================
# OPTIMIZED CASE 2: AD Root-Child + Ubuntu - Maximum Automation
# Using Azure Storage for script deployment to overcome size limits
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

# =============================================================================
# STORAGE ACCOUNT FOR AUTOMATION SCRIPTS
# =============================================================================

resource "azurerm_storage_account" "automation" {
  name                     = "${replace(var.resource_group_name, "-", "")}scripts"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = azurerm_resource_group.rg.tags
}

resource "azurerm_storage_container" "scripts" {
  name                  = "automation-scripts"
  storage_account_name  = azurerm_storage_account.automation.name
  container_access_type = "blob"
}

# Upload PowerShell scripts to storage
resource "azurerm_storage_blob" "root_setup_script" {
  name                   = "setup-root-domain.ps1"
  storage_account_name   = azurerm_storage_account.automation.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/scripts/setup-root-domain.ps1"
}

resource "azurerm_storage_blob" "child_setup_script" {
  name                   = "setup-child-domain.ps1"
  storage_account_name   = azurerm_storage_account.automation.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/scripts/setup-child-domain.ps1"
}

resource "azurerm_storage_blob" "client_setup_script" {
  name                   = "setup-client-multidomain.sh"
  storage_account_name   = azurerm_storage_account.automation.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/scripts/setup-client-multidomain.sh"
}

# =============================================================================
# RESOURCE GROUP (keeping existing structure)
# =============================================================================

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment   = "Testing"
    Purpose      = "FortiProxy-AD-Authentication"
    Case         = "Case2-AD-Root-Child-Ubuntu-Optimized"
    Automation   = "Terraform-Plus-Storage"
    Architecture = "Parent-Child-Domains"
    CreatedBy    = "Terraform"
  }
}

# =============================================================================
# NETWORKING (same as before - truncated for brevity)
# =============================================================================

# [Previous networking configuration remains the same]

# =============================================================================
# OPTIMIZED ROOT DOMAIN SETUP
# =============================================================================

resource "azurerm_virtual_machine_extension" "root_setup_optimized" {
  name                 = "root-domain-setup-optimized"
  virtual_machine_id   = azurerm_windows_virtual_machine.root_dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  # Small inline script that downloads and executes the main script
  settings = jsonencode({
    commandToExecute = join(" ", [
      "powershell -ExecutionPolicy Unrestricted -Command",
      "\"Invoke-WebRequest -Uri '${azurerm_storage_blob.root_setup_script.url}' -OutFile 'C:\\setup-root-domain.ps1';",
      "& C:\\setup-root-domain.ps1 -DomainName '${var.root_domain_name}' -AdminPassword '${var.admin_password}';\""
    ])
  })

  depends_on = [
    azurerm_windows_virtual_machine.root_dc,
    azurerm_storage_blob.root_setup_script
  ]

  tags = azurerm_resource_group.rg.tags
}

# =============================================================================
# OPTIMIZED CHILD DOMAIN SETUP
# =============================================================================

resource "azurerm_virtual_machine_extension" "child_setup_optimized" {
  name                 = "child-domain-setup-optimized"
  virtual_machine_id   = azurerm_windows_virtual_machine.child_dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = join(" ", [
      "powershell -ExecutionPolicy Unrestricted -Command",
      "\"Start-Sleep -Seconds 300;", # Wait 5 minutes for root domain
      "Invoke-WebRequest -Uri '${azurerm_storage_blob.child_setup_script.url}' -OutFile 'C:\\setup-child-domain.ps1';",
      "& C:\\setup-child-domain.ps1",
      "-RootDomainName '${var.root_domain_name}'",
      "-ChildDomainName '${var.child_domain_name}'",
      "-AdminPassword '${var.admin_password}'",
      "-RootDcIp '10.0.1.4';\""
    ])
  })

  depends_on = [
    azurerm_virtual_machine_extension.root_setup_optimized,
    azurerm_storage_blob.child_setup_script
  ]

  tags = azurerm_resource_group.rg.tags
}

# =============================================================================
# MANUAL FALLBACK SCRIPTS (if automation fails)
# =============================================================================

# Create downloadable script package for manual execution
resource "azurerm_storage_blob" "manual_setup_guide" {
  name                   = "manual-setup-guide.md"
  storage_account_name   = azurerm_storage_account.automation.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/docs/manual-setup-guide.md"
}

# =============================================================================
# OUTPUTS WITH AUTOMATION STATUS
# =============================================================================

output "automation_status" {
  description = "Automation approach and fallback options"
  value = {
    primary_method = "Terraform + Azure Storage + Custom Script Extensions"
    script_storage = azurerm_storage_account.automation.name
    
    automation_scripts = {
      root_domain_url   = azurerm_storage_blob.root_setup_script.url
      child_domain_url  = azurerm_storage_blob.child_setup_script.url
      client_setup_url  = azurerm_storage_blob.client_setup_script.url
      manual_guide_url  = azurerm_storage_blob.manual_setup_guide.url
    }
    
    fallback_options = [
      "1. Download scripts from storage URLs above",
      "2. RDP to Windows VMs and run PowerShell scripts manually",
      "3. SSH to Ubuntu client and run bash script manually",
      "4. Use Azure Run Command for script execution"
    ]
    
    verification_commands = {
      check_root_domain   = "Get-ADDomain -Server ${azurerm_network_interface.root_nic.private_ip_address}"
      check_child_domain  = "Get-ADDomain -Server ${azurerm_network_interface.child_nic.private_ip_address}"
      check_trust         = "Get-ADTrust -Filter * -Server ${var.child_domain_name}"
      test_client_auth    = "/opt/multidomain-tests/test-all-domains.sh"
    }
  }
}