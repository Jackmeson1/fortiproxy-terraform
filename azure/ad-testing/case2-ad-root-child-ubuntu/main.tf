# =============================================================================
# CASE 2: AD Root-Child + Ubuntu Client - Fully Automated
# Parent-Child Domain Relationship Testing
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
    Case         = "Case2-AD-Root-Child-Ubuntu"
    Automation   = "Fully-Automated"
    Architecture = "Parent-Child-Domains"
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

# Root Domain Subnet
resource "azurerm_subnet" "root_subnet" {
  name                 = "root-domain-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Child Domain Subnet
resource "azurerm_subnet" "child_subnet" {
  name                 = "child-domain-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Client Subnet
resource "azurerm_subnet" "client_subnet" {
  name                 = "client-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# =============================================================================
# NETWORK SECURITY GROUPS
# =============================================================================

# Root Domain Controller NSG
resource "azurerm_network_security_group" "root_nsg" {
  name                = "${var.resource_group_name}-root-nsg"
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

  # AD services - Allow from entire VNet for cross-domain communication
  security_rule {
    name                       = "AD-Services"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["389", "636", "88", "53", "3268", "3269", "135", "445", "464"]
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # AD UDP services
  security_rule {
    name                       = "AD-Services-UDP"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_ranges    = ["88", "53", "464", "123"]
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Dynamic RPC ports for AD replication
  security_rule {
    name                       = "AD-RPC"
    priority                   = 1012
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "49152-65535"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.rg.tags
}

# Child Domain Controller NSG (similar rules)
resource "azurerm_network_security_group" "child_nsg" {
  name                = "${var.resource_group_name}-child-nsg"
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

  # AD services
  security_rule {
    name                       = "AD-Services"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["389", "636", "88", "53", "3268", "3269", "135", "445", "464"]
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # AD UDP services
  security_rule {
    name                       = "AD-Services-UDP"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_ranges    = ["88", "53", "464", "123"]
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Dynamic RPC ports
  security_rule {
    name                       = "AD-RPC"
    priority                   = 1012
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "49152-65535"
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

# Root Domain Controller Public IP
resource "azurerm_public_ip" "root_ip" {
  name                = "${var.resource_group_name}-root-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                = "Standard"

  tags = azurerm_resource_group.rg.tags
}

# Child Domain Controller Public IP
resource "azurerm_public_ip" "child_ip" {
  name                = "${var.resource_group_name}-child-ip"
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

# Root Domain Controller NIC
resource "azurerm_network_interface" "root_nic" {
  name                = "${var.resource_group_name}-root-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.root_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.root_ip.id
  }

  tags = azurerm_resource_group.rg.tags
}

# Child Domain Controller NIC
resource "azurerm_network_interface" "child_nic" {
  name                = "${var.resource_group_name}-child-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.child_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.4"
    public_ip_address_id          = azurerm_public_ip.child_ip.id
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
resource "azurerm_network_interface_security_group_association" "root_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.root_nic.id
  network_security_group_id = azurerm_network_security_group.root_nsg.id
}

resource "azurerm_network_interface_security_group_association" "child_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.child_nic.id
  network_security_group_id = azurerm_network_security_group.child_nsg.id
}

resource "azurerm_network_interface_security_group_association" "client_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.client_nic.id
  network_security_group_id = azurerm_network_security_group.client_nsg.id
}

# =============================================================================
# ROOT DOMAIN CONTROLLER
# =============================================================================

resource "azurerm_windows_virtual_machine" "root_dc" {
  name                = "${var.resource_group_name}-root-dc"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.root_nic.id,
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
# CHILD DOMAIN CONTROLLER
# =============================================================================

resource "azurerm_windows_virtual_machine" "child_dc" {
  name                = "${var.resource_group_name}-child-dc"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.child_nic.id,
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

  # Wait for root domain to be established
  depends_on = [azurerm_virtual_machine_extension.root_setup]

  tags = azurerm_resource_group.rg.tags
}

# =============================================================================
# ROOT DOMAIN SETUP - AUTOMATED
# =============================================================================

resource "azurerm_virtual_machine_extension" "root_setup" {
  name                 = "root-domain-setup"
  virtual_machine_id   = azurerm_windows_virtual_machine.root_dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(local.root_setup_script)}')) | Invoke-Expression\""
  })

  depends_on = [azurerm_windows_virtual_machine.root_dc]

  tags = azurerm_resource_group.rg.tags
}

# =============================================================================
# CHILD DOMAIN SETUP - AUTOMATED
# =============================================================================

resource "azurerm_virtual_machine_extension" "child_setup" {
  name                 = "child-domain-setup"
  virtual_machine_id   = azurerm_windows_virtual_machine.child_dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(local.child_setup_script)}')) | Invoke-Expression\""
  })

  depends_on = [azurerm_virtual_machine_extension.root_setup]

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

  depends_on = [azurerm_virtual_machine_extension.child_setup]

  tags = azurerm_resource_group.rg.tags
}

# =============================================================================
# SCRIPTS
# =============================================================================

locals {
  root_domain_name  = var.root_domain_name
  child_domain_name = var.child_domain_name
  root_domain_upper = upper(var.root_domain_name)
  child_domain_upper = upper(var.child_domain_name)

  # PowerShell script for root domain setup
  root_setup_script = templatefile("${path.module}/scripts/setup-root-domain.ps1", {
    domain_name    = var.root_domain_name
    admin_password = var.admin_password
  })

  # PowerShell script for child domain setup
  child_setup_script = templatefile("${path.module}/scripts/setup-child-domain.ps1", {
    root_domain_name  = var.root_domain_name
    child_domain_name = var.child_domain_name
    admin_password    = var.admin_password
    root_dc_ip        = "10.0.1.4"
  })

  # Cloud-init script for Ubuntu client setup
  client_setup_script = templatefile("${path.module}/scripts/setup-client-multidomain.sh", {
    root_domain_name  = var.root_domain_name
    child_domain_name = var.child_domain_name
    root_domain_upper = local.root_domain_upper
    child_domain_upper = local.child_domain_upper
    root_dc_ip        = "10.0.1.4"
    child_dc_ip       = "10.0.2.4"
  })
}