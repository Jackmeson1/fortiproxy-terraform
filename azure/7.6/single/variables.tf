// Azure configuration
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

// VM size - Standard_F4s_v2 recommended for FortiProxy
variable "size" {
  type    = string
  default = "Standard_F4s_v2"
}

// To use custom image
// by default is false
variable "custom" {
  default = false
}

//  Custom image blob uri
variable "customuri" {
  type    = string
  default = "<custom image blob uri>"
}

variable "custom_image_name" {
  type    = string
  default = "<custom image name>"
}

variable "custom_image_resource_group_name" {
  type    = string
  default = "<custom image resource group>"
}

// License Type to create FortiProxy-VM
// FortiProxy primarily uses BYOL licensing
variable "license_type" {
  default = "byol"
}

variable "publisher" {
  type    = string
  default = "fortinet"
}

variable "fpxoffer" {
  type    = string
  default = "fortinet-fortiproxy"
}

// FortiProxy SKUs
variable "fpxsku" {
  type = map(any)
  default = {
    byol = "fpx-vm-byol"
  }
}

// FortiProxy version
variable "fpxversion" {
  type    = string
  default = "7.6.0"
}

variable "adminusername" {
  type    = string
  default = "fpxadmin"
}

variable "adminpassword" {
  type    = string
  default = "Fortinet123#"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "vnetcidr" {
  default = "10.1.0.0/16"
}

variable "publiccidr" {
  default = "10.1.0.0/24"
}

variable "privatecidr" {
  default = "10.1.1.0/24"
}

variable "bootstrap-fpxvm" {
  // Change to your own path
  type    = string
  default = "fpxvm.conf"
}

// license file for the fpx
variable "license" {
  // Change to your own byol license file, license.txt
  type    = string
  default = "license.txt"
}