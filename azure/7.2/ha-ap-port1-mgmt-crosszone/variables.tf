// Azure configuration
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}


//  For HA, choose instance size that support 4 nics at least
//  Check : https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes
variable "size" {
  type    = string
  default = "Standard_F4"
}

// Availability zones only support in certain regions
// Check: https://docs.microsoft.com/en-us/azure/availability-zones/az-overview
variable "zone1" {
  type    = string
  default = "1"
}

variable "zone2" {
  type    = string
  default = "2"
}

variable "location" {
  type    = string
  default = "westus2"
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
// Provide the license type for FortiProxy-VM Instances, either byol or payg.
variable "license_type" {
  default = "byol"
}

variable "publisher" {
  type    = string
  default = "fortinet"
}

variable "resource_group_name" {
  type = string
  default = "TerraformDemoFPX"
}

variable "fpxoffer" {
  type    = string
  default = "fortinet-fortiproxy"
}

// BYOL sku: fpx-vm-byol
// PAYG sku: N/A
variable "fpxsku" {
  type = map(any)
  default = {
    byol = "fpx-vm-byol"
  }
}

//FPX vm name
variable "active_name" {
  type =  string
  default = "FPX-A"
}
variable "passive_name" {
  type =  string
  default = "FPX-B"
}

// FPX version
variable "fpxversion" {
  type    = string
  default = "7.2.13"
}

variable "adminusername" {
  type    = string
  default = "fpxadmin"
}

variable "adminpassword" {
  type    = string
  default = "Fortinet123#"
}

// HTTPS Port
variable "adminsport" {
  type    = string
  default = "8443"
}

variable "vnetcidr" {
  default = "172.16.0.0/16"
}

variable "publiccidr" {
  default = "172.16.0.0/24"
}

variable "privatecidr" {
  default = "172.16.1.0/24"
}

variable "hasynccidr" {
  default = "172.16.2.0/24"
}

variable "hamgmtcidr" {
  default = "172.16.3.0/24"
}

variable "activeport1" {
  default = "172.16.3.10"
}

variable "activeport1mask" {
  default = "255.255.255.0"
}

variable "activeport2" {
  default = "172.16.0.10"
}

variable "activeport2mask" {
  default = "255.255.255.0"
}

variable "activeport3" {
  default = "172.16.1.10"
}

variable "activeport3mask" {
  default = "255.255.255.0"
}

variable "activeport4" {
  default = "172.16.2.10"
}

variable "activeport4mask" {
  default = "255.255.255.0"
}

variable "passiveport1" {
  default = "172.16.3.11"
}

variable "passiveport1mask" {
  default = "255.255.255.0"
}

variable "passiveport2" {
  default = "172.16.0.11"
}

variable "passiveport2mask" {
  default = "255.255.255.0"
}

variable "passiveport3" {
  default = "172.16.1.11"
}

variable "passiveport3mask" {
  default = "255.255.255.0"
}

variable "passiveport4" {
  default = "172.16.2.11"
}

variable "passiveport4mask" {
  default = "255.255.255.0"
}

variable "port1gateway" {
  default = "172.16.3.1"
}

variable "port2gateway" {
  default = "172.16.0.1"
}

variable "bootstrap-active" {
  // Change to your own path
  type    = string
  default = "config-active.conf"
}

variable "bootstrap-passive" {
  // Change to your own path
  type    = string
  default = "config-passive.conf"
}


// license file for the active fpx
variable "license" {
  // Change to your own byol license file, license.lic
  type    = string
  default = "license.txt"
}

// license file for the passive fpx
variable "license2" {
  // Change to your own byol license file, license2.lic
  type    = string
  default = "license2.txt"
}

