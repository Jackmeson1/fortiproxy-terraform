variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "client_id" {
  type      = string
  sensitive = true
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type      = string
  sensitive = true
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "ADTestRG"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "admin_password" {
  type        = string
  default     = "P@ssw0rd1234!"
  sensitive   = true
  description = "Admin password for the VM. Must be at least 12 characters long and contain uppercase, lowercase, numbers, and special characters."
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Password must be at least 12 characters long."
  }
}

variable "domain_name" {
  type    = string
  default = "example.com"
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2ms"
  description = "Size of the Windows DC VM"
  validation {
    condition = contains([
      "Standard_B2ms", "Standard_B2s", "Standard_B4ms", 
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_DS2_v2"
    ], var.vm_size)
    error_message = "VM size must be one of the supported sizes for Windows Server."
  }
}

# New variables for enhanced deployment
variable "admin_source_ip" {
  type        = string
  description = "Source IP address for admin access (RDP/SSH). Use 'your-public-ip/32' format."
  default     = "*"  # Change this to your actual IP for security
}

variable "client_vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "Size of the Ubuntu client VM"
}

variable "client_admin_username" {
  type        = string
  default     = "ubuntu"
  description = "Admin username for Ubuntu client"
}

variable "client_ssh_public_key" {
  type        = string
  description = "SSH public key for Ubuntu client access"
  validation {
    condition     = length(var.client_ssh_public_key) > 50
    error_message = "SSH public key must be provided and appear to be valid."
  }
}