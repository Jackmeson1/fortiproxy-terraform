//AWS Configuration
variable access_key {}
variable secret_key {}

variable "region" {
  default = "us-east-2"
}

// Availability zone 1 for the region
variable "az1" {
  default = "us-east-2a"
}

// Availability zone 2 for the region
variable "az2" {
  default = "us-east-2b"
}

// IAM role that has proper permission for HA
// minimum requirement:
// "ec2:Describe*"
// "ec2:AssociateAddress"
// "ec2:AssignPrivateIpAddresses"
// "ec2:UnassignPrivateIpAddresses"
// "ec2:ReplaceRoute"
variable "iam" {
  default = "<AWS IAM ROLE>"
}

variable "vpccidr" {
  default = "10.1.0.0/16"
}

variable "publiccidraz1" {
  default = "10.1.0.0/24"
}

variable "privatecidraz1" {
  default = "10.1.1.0/24"
}

variable "hasynccidraz1" {
  default = "10.1.2.0/24"
}

variable "hamgmtcidraz1" {
  default = "10.1.3.0/24"
}

variable "publiccidraz2" {
  default = "10.1.10.0/24"
}

variable "privatecidraz2" {
  default = "10.1.11.0/24"
}

variable "hasynccidraz2" {
  default = "10.1.12.0/24"
}

variable "hamgmtcidraz2" {
  default = "10.1.13.0/24"
}

// License Type to create FortiProxy-VM
// Provide the license type for FortiProxy-VM Instances, either byol or payg (Currently only BYOL is supported).
variable "license_type" {
  default = "byol"
}

// AMIs are for FPXVM-AWS(PAYG)
variable "fpxvmpaygami" {
  type = map(any)
  default = {
  }
}


// AMIs are for FPXVM AWS(BYOL) - 7.0.11
variable "fpxvmbyolami" {
  type = map(any)
  default = {
    us-east-1      = "ami-054b0a7750de7d6f2"
    us-east-2      = "ami-0838c172e5385583c"
    us-west-1      = "ami-0d43319dfe6ec001c"
    us-west-2      = "ami-0194a5985bf06be7a"
    ca-central-1   = "ami-0e65dbadfd0e7f1e3"
    eu-central-1   = "ami-0bdd465c8c12fd2a9"
    eu-central-2   = "ami-0e72423c770ffa677"
    eu-west-1      = "ami-0d87b97765bea5688"
    eu-west-2      = "ami-013377f4754accbf1"
    eu-west-3      = "ami-0197e3d2dff181f10"
    eu-north-1     = "ami-0318b0c267650aaf7"
    eu-south-1     = "ami-090316215186b38ee"
    eu-south-2     = "ami-07b4f6d619dd9ef62"
    ap-east-1      = "ami-0be108f248509d88c"
    ap-southeast-1 = "ami-0c1358e4e51a85d93"
    ap-southeast-2 = "ami-0c89177c7a2797787"
    ap-southeast-3 = "ami-03d6391bfbc0bdbd8"
    ap-southeast-4 = "ami-0c93c8317ca07a8d9"
    ap-northeast-2 = "ami-0225a1eb421f121e7"
    ap-northeast-1 = "ami-088f9c8ea3e9e176d"
    ap-northeast-3 = "ami-029144eb5c7a42e84"
    ap-south-1     = "ami-080890555a8779f3b"
    ap-south-2     = "ami-069e6e0d9923dda54"
    sa-east-1      = "ami-08e8edf8f54f2b5f8"
    me-central-1   = "ami-0237c9536cc59fc0e"
    me-south-1     = "ami-0f8f854a624353be9"
    af-south-1     = "ami-013375d268e05d2e9"
  }
}

variable "size" {
  default = "m5.xlarge"
}

//  Existing SSH Key on the AWS
variable "keyname" {
  default = "<AWS SSH KEY>"
}

// HTTPS access port
variable "adminsport" {
  default = "8443"
}

variable "activeport1" {
  default = "10.1.0.10"
}

variable "activeport1mask" {
  default = "255.255.255.0"
}

variable "activeport2" {
  default = "10.1.1.10"
}

variable "activeport2mask" {
  default = "255.255.255.0"
}

variable "activeport3" {
  default = "10.1.2.10"
}

variable "activeport3mask" {
  default = "255.255.255.0"
}

variable "activeport4" {
  default = "10.1.3.10"
}

variable "activeport4mask" {
  default = "255.255.255.0"
}

variable "passiveport1" {
  default = "10.1.10.10"
}

variable "passiveport1mask" {
  default = "255.255.255.0"
}

variable "passiveport2" {
  default = "10.1.11.10"
}

variable "passiveport2mask" {
  default = "255.255.255.0"
}

variable "passiveport3" {
  default = "10.1.12.10"
}

variable "passiveport3mask" {
  default = "255.255.255.0"
}

variable "passiveport4" {
  default = "10.1.13.10"
}

variable "passiveport4mask" {
  default = "255.255.255.0"
}

variable "activeport1gateway" {
  default = "10.1.0.1"
}

variable "activeport2gateway" {
  default = "10.1.1.1"
}

variable "activeport4gateway" {
  default = "10.1.3.1"
}

variable "passiveport1gateway" {
  default = "10.1.10.1"
}

variable "passiveport2gateway" {
  default = "10.1.11.1"
}

variable "passiveport4gateway" {
  default = "10.1.13.1"
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
  default = "license.lic"
}

// license file for the passive fpx
variable "license2" {
  // Change to your own byol license file, license2.lic
  type    = string
  default = "license2.lic"
}

