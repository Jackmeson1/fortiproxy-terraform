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
  type      = string
  default   = "P@ssw0rd1234!"
  sensitive = true
}

variable "domain_name" {
  type    = string
  default = "example.com"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2ms"
}
