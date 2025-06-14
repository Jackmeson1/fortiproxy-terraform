resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "ad-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "ad_subnet" {
  name                 = "ad-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "client_subnet" {
  name                 = "client-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group for AD Server - Restricted to VNet only
resource "azurerm_network_security_group" "ad_nsg" {
  name                = "ad-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  # RDP access - restricted to admin IPs only
  security_rule {
    name                       = "rdp-admin"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.admin_source_ip  # Variable for admin IP
    destination_address_prefix = "*"
  }

  # LDAP - VNet only
  security_rule {
    name                       = "ldap-vnet"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "389"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # LDAPS - VNet only
  security_rule {
    name                       = "ldaps-vnet"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "636"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Kerberos TCP - VNet only
  security_rule {
    name                       = "kerberos-tcp-vnet"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Kerberos UDP - VNet only
  security_rule {
    name                       = "kerberos-udp-vnet"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # DNS TCP - VNet only
  security_rule {
    name                       = "dns-tcp-vnet"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # DNS UDP - VNet only
  security_rule {
    name                       = "dns-udp-vnet"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Global Catalog - VNet only
  security_rule {
    name                       = "global-catalog-vnet"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3268"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Global Catalog SSL - VNet only
  security_rule {
    name                       = "global-catalog-ssl-vnet"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3269"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # SMB/CIFS - VNet only
  security_rule {
    name                       = "smb-vnet"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # RPC Endpoint Mapper - VNet only
  security_rule {
    name                       = "rpc-endpoint-vnet"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "135"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # NetBIOS Name Service - VNet only
  security_rule {
    name                       = "netbios-ns-vnet"
    priority                   = 1012
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "137"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # NetBIOS Datagram Service - VNet only
  security_rule {
    name                       = "netbios-dgm-vnet"
    priority                   = 1013
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "138"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # NetBIOS Session Service - VNet only
  security_rule {
    name                       = "netbios-ssn-vnet"
    priority                   = 1014
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "139"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # NTP - VNet only
  security_rule {
    name                       = "ntp-vnet"
    priority                   = 1015
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "123"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Dynamic RPC - VNet only
  security_rule {
    name                       = "dynamic-rpc-vnet"
    priority                   = 1016
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "49152-65535"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }
}

# Network Security Group for Client Subnet
resource "azurerm_network_security_group" "client_nsg" {
  name                = "client-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  # SSH access - restricted to admin IPs
  security_rule {
    name                       = "ssh-admin"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_ip
    destination_address_prefix = "*"
  }

  # Allow all outbound to VNet for AD communication
  security_rule {
    name                       = "outbound-vnet"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/16"
  }
}

resource "azurerm_subnet_network_security_group_association" "ad_subnet" {
  subnet_id                 = azurerm_subnet.ad_subnet.id
  network_security_group_id = azurerm_network_security_group.ad_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "client_subnet" {
  subnet_id                 = azurerm_subnet.client_subnet.id
  network_security_group_id = azurerm_network_security_group.client_nsg.id
}

# Public IP for AD server (RDP access only)
resource "azurerm_public_ip" "ad_ip" {
  name                = "ad-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP for Ubuntu client (SSH access only)
resource "azurerm_public_ip" "client_ip" {
  name                = "client-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network interface for AD server
resource "azurerm_network_interface" "ad_nic" {
  name                = "ad-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ad_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.ad_ip.id
  }
}

# Network interface for Ubuntu client
resource "azurerm_network_interface" "client_nic" {
  name                = "client-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.client_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.client_ip.id
  }

  dns_servers = ["10.0.1.4"]  # Point to AD server for DNS
}

# Windows Server 2019 Domain Controller
resource "azurerm_windows_virtual_machine" "dc" {
  name                = "windc2019"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.ad_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  provision_vm_agent = true
}

# Ubuntu 20.04 Client
resource "azurerm_linux_virtual_machine" "client" {
  name                = "ubuntu-client"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.client_vm_size
  admin_username      = var.client_admin_username
  
  admin_ssh_key {
    username   = var.client_admin_username
    public_key = var.client_ssh_public_key
  }

  network_interface_ids = [azurerm_network_interface.client_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

# AD Setup Script
resource "azurerm_virtual_machine_extension" "ad_setup" {
  name                 = "adsetup"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = jsonencode({
    commandToExecute = templatefile("${path.module}/setup-ad-enhanced-fixed.ps1", {
      admin_password = var.admin_password
      domain_name    = var.domain_name
    })
  })

  depends_on = [azurerm_windows_virtual_machine.dc]
}

# Ubuntu Client Configuration
resource "azurerm_virtual_machine_extension" "client_setup" {
  name                 = "clientsetup"
  virtual_machine_id   = azurerm_linux_virtual_machine.client.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = jsonencode({
    script = base64encode(templatefile("${path.module}/setup-ubuntu-client.sh", {
      domain_name        = var.domain_name
      domain_upper       = upper(var.domain_name)
      netbios_name       = "CORP"
      dc_ip              = azurerm_network_interface.ad_nic.private_ip_address
      admin_username     = var.admin_username
      admin_password     = var.admin_password
    }))
  })

  depends_on = [
    azurerm_linux_virtual_machine.client,
    azurerm_virtual_machine_extension.ad_setup
  ]
}