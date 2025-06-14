# =============================================================================
# VARIABLES - Case 2: AD Root-Child + Ubuntu
# =============================================================================

# Azure Authentication
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "client_id" {
  type        = string
  description = "Azure service principal client ID"
}

variable "client_secret" {
  type        = string
  description = "Azure service principal client secret"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

# =============================================================================
# DEPLOYMENT CONFIGURATION
# =============================================================================

variable "location" {
  type        = string
  description = "Azure region for deployment"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
  default     = "case2-root-child-rg"
}

# =============================================================================
# DOMAIN CONFIGURATION
# =============================================================================

variable "root_domain_name" {
  type        = string
  description = "Root Active Directory domain name"
  default     = "corp.local"
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.root_domain_name))
    error_message = "Root domain name must be in format corp.local"
  }
}

variable "child_domain_name" {
  type        = string
  description = "Child Active Directory domain name (will be subdomain of root)"
  default     = "dev.corp.local"
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z0-9.-]+\\.[a-z]{2,}$", var.child_domain_name))
    error_message = "Child domain name must be in format dev.corp.local"
  }
}

# =============================================================================
# WINDOWS DC CONFIGURATION
# =============================================================================

variable "admin_username" {
  type        = string
  description = "Administrator username for Windows DCs"
  default     = "azureuser"
}

variable "admin_password" {
  type        = string
  description = "Administrator password for Windows DCs"
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Password must be at least 12 characters long"
  }
}

variable "vm_size" {
  type        = string
  description = "Size of the Windows DC VMs"
  default     = "Standard_B4ms"
  
  validation {
    condition = contains([
      "Standard_B2ms", "Standard_B4ms", "Standard_D2s_v3", "Standard_D4s_v3", "Standard_F2s_v2", "Standard_F4s_v2"
    ], var.vm_size)
    error_message = "VM size must be at least Standard_B2ms for domain controller operations."
  }
}

# =============================================================================
# UBUNTU CLIENT CONFIGURATION
# =============================================================================

variable "client_admin_username" {
  type        = string
  description = "Administrator username for Ubuntu client"
  default     = "ubuntu"
}

variable "client_ssh_public_key" {
  type        = string
  description = "SSH public key for Ubuntu client access"
}

variable "client_vm_size" {
  type        = string
  description = "Size of the Ubuntu client VM"
  default     = "Standard_B2s"
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

variable "admin_source_ip" {
  type        = string
  description = "Source IP address range for admin access (RDP/SSH)"
  default     = "*"
  
  validation {
    condition = can(cidrhost(var.admin_source_ip, 0)) || var.admin_source_ip == "*"
    error_message = "admin_source_ip must be a valid CIDR block (e.g., 203.0.113.45/32) or '*'"
  }
}

# =============================================================================
# ADVANCED CONFIGURATION
# =============================================================================

variable "enable_diagnostics" {
  type        = bool
  description = "Enable boot diagnostics for VMs"
  default     = true
}

variable "enable_auto_shutdown" {
  type        = bool
  description = "Enable auto-shutdown for cost management"
  default     = false
}

variable "auto_shutdown_time" {
  type        = string
  description = "Time for auto-shutdown (24h format)"
  default     = "1900"
}

variable "forest_functional_level" {
  type        = string
  description = "Active Directory Forest Functional Level"
  default     = "WinThreshold"
  
  validation {
    condition = contains([
      "Win2012R2", "WinThreshold", "Win2016", "Win2019"
    ], var.forest_functional_level)
    error_message = "Forest functional level must be Win2012R2, WinThreshold, Win2016, or Win2019."
  }
}

variable "domain_functional_level" {
  type        = string
  description = "Active Directory Domain Functional Level"
  default     = "WinThreshold"
  
  validation {
    condition = contains([
      "Win2012R2", "WinThreshold", "Win2016", "Win2019"
    ], var.domain_functional_level)
    error_message = "Domain functional level must be Win2012R2, WinThreshold, Win2016, or Win2019."
  }
}