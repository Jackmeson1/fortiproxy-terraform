# =============================================================================
# CASE 1: Simple AD + Ubuntu Client - Fully Automated
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
# RESOURCE GROUP
# =============================================================================

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment   = "Testing"
    Purpose      = "FortiProxy-AD-Authentication"
    Case         = "Case1-Simple-AD-Ubuntu"
    Automation   = "Fully-Automated"
    CreatedBy    = "Terraform"
  }
}

# =============================================================================
# NETWORKING
# =============================================================================

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  tags = azurerm_resource_group.rg.tags
}

# AD Subnet
resource "azurerm_subnet" "ad_subnet" {
  name                 = "ad-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Client Subnet
resource "azurerm_subnet" "client_subnet" {
  name                 = "client-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# =============================================================================
# NETWORK SECURITY GROUPS
# =============================================================================

# AD Server NSG
resource "azurerm_network_security_group" "ad_nsg" {
  name                = "${var.resource_group_name}-ad-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # RDP access for admin
  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.admin_source_ip
    destination_address_prefix = "*"
  }

  # LDAP
  security_rule {
    name                       = "LDAP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "389"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # LDAPS
  security_rule {
    name                       = "LDAPS"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "636"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Kerberos
  security_rule {
    name                       = "Kerberos"
    priority                   = 1012
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # DNS
  security_rule {
    name                       = "DNS"
    priority                   = 1013
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Global Catalog
  security_rule {
    name                       = "GlobalCatalog"
    priority                   = 1014
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3268"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.rg.tags
}

# Client NSG
resource "azurerm_network_security_group" "client_nsg" {
  name                = "${var.resource_group_name}-client-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # SSH access for admin
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_ip
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.rg.tags
}

# =============================================================================
# PUBLIC IPs
# =============================================================================

# AD Server Public IP
resource "azurerm_public_ip" "ad_ip" {
  name                = "${var.resource_group_name}-ad-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                = "Standard"

  tags = azurerm_resource_group.rg.tags
}

# Client Public IP
resource "azurerm_public_ip" "client_ip" {
  name                = "${var.resource_group_name}-client-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                = "Standard"

  tags = azurerm_resource_group.rg.tags
}

# =============================================================================
# NETWORK INTERFACES
# =============================================================================

# AD Server NIC
resource "azurerm_network_interface" "ad_nic" {
  name                = "${var.resource_group_name}-ad-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ad_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.ad_ip.id
  }

  tags = azurerm_resource_group.rg.tags
}

# Client NIC
resource "azurerm_network_interface" "client_nic" {
  name                = "${var.resource_group_name}-client-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.client_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.client_ip.id
  }

  tags = azurerm_resource_group.rg.tags
}

# Associate NSGs with NICs
resource "azurerm_network_interface_security_group_association" "ad_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.ad_nic.id
  network_security_group_id = azurerm_network_security_group.ad_nsg.id
}

resource "azurerm_network_interface_security_group_association" "client_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.client_nic.id
  network_security_group_id = azurerm_network_security_group.client_nsg.id
}

# =============================================================================
# WINDOWS DOMAIN CONTROLLER
# =============================================================================

resource "azurerm_windows_virtual_machine" "ad_vm" {
  name                = "${var.resource_group_name}-windc"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.ad_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = azurerm_resource_group.rg.tags
}

# =============================================================================
# ACTIVE DIRECTORY SETUP - AUTOMATED
# =============================================================================

resource "azurerm_virtual_machine_extension" "ad_setup" {
  name                 = "ad-setup"
  virtual_machine_id   = azurerm_windows_virtual_machine.ad_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"& { ${base64encode(local.ad_setup_script)} }\""
  })

  depends_on = [azurerm_windows_virtual_machine.ad_vm]

  tags = azurerm_resource_group.rg.tags
}

# =============================================================================
# UBUNTU CLIENT
# =============================================================================

resource "azurerm_linux_virtual_machine" "client_vm" {
  name                = "${var.resource_group_name}-client"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.client_vm_size
  admin_username      = var.client_admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.client_nic.id,
  ]

  admin_ssh_key {
    username   = var.client_admin_username
    public_key = var.client_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(local.client_setup_script)

  depends_on = [azurerm_virtual_machine_extension.ad_setup]

  tags = azurerm_resource_group.rg.tags
}

# =============================================================================
# SCRIPTS
# =============================================================================

locals {
  domain_name_upper = upper(var.domain_name)
  domain_dn = "DC=${replace(var.domain_name, ".", ",DC=")}"

  # PowerShell script for AD setup - Base64 encoded to avoid length limits
  ad_setup_script = templatefile("${path.module}/scripts/setup-ad.ps1", {
    domain_name = var.domain_name
    admin_password = var.admin_password
  })

  # Cloud-init script for Ubuntu client setup
  client_setup_script = templatefile("${path.module}/scripts/setup-client.sh", {
    domain_name = var.domain_name
    domain_upper = local.domain_name_upper
    ad_server_ip = "10.0.1.4"
  })
}