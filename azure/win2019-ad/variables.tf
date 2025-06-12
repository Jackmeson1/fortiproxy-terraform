variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

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
  description = "Size of the VM"
  validation {
    condition = contains([
      "Standard_B2ms", "Standard_B2s", "Standard_B4ms", 
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_DS2_v2"
    ], var.vm_size)
    error_message = "VM size must be one of the supported sizes for Windows Server."
  }
}
