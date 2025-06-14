# =============================================================================
# VARIABLES - Case 1: Simple AD + Ubuntu
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
  default     = "case1-simple-ad-rg"
}

# =============================================================================
# DOMAIN CONFIGURATION
# =============================================================================

variable "domain_name" {
  type        = string
  description = "Active Directory domain name"
  default     = "simple.local"
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be in format example.com"
  }
}

# =============================================================================
# WINDOWS DC CONFIGURATION
# =============================================================================

variable "admin_username" {
  type        = string
  description = "Administrator username for Windows DC"
  default     = "azureuser"
}

variable "admin_password" {
  type        = string
  description = "Administrator password for Windows DC"
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Password must be at least 12 characters long"
  }
}

variable "vm_size" {
  type        = string
  description = "Size of the Windows DC VM"
  default     = "Standard_B2ms"
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
# OPTIONAL TESTING CONFIGURATION
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
  description = "Time for auto-shutdown (24h format, e.g., 1900)"
  default     = "1900"
}