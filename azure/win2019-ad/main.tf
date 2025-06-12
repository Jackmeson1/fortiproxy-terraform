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

resource "azurerm_subnet" "subnet" {
  name                 = "ad-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "ad-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "rdp"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ldap"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ldaps"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "636"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "kerberos"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "kerberos-udp"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "dns"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "dns-udp"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "global-catalog"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3268"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "global-catalog-ssl"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3269"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "ip" {
  name                = "ad-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "ad-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }
}

resource "azurerm_windows_virtual_machine" "dc" {
  name                = "windc2019"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic.id]

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

resource "azurerm_virtual_machine_extension" "setup" {
  name                 = "adsetup"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = jsonencode({
    commandToExecute = <<-EOT
      powershell -ExecutionPolicy Unrestricted -Command "
        # Disable Windows Firewall
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False;
        
        # Install AD Domain Services and DNS
        Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools;
        
        # Convert password to secure string
        $secpasswd = ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force;
        
        # Install AD Forest with comprehensive settings
        Install-ADDSForest -DomainName '${var.domain_name}' -SafeModeAdministratorPassword $secpasswd -Force -NoRebootOnCompletion -DomainNetbiosName 'CORP' -ForestMode 'WinThreshold' -DomainMode 'WinThreshold' -InstallDns;
        
        # Wait for AD DS to finish configuring
        Start-Sleep -Seconds 120;
        
        # Import Active Directory module
        Import-Module ActiveDirectory;
        
        try {
          # Create Organizational Units
          New-ADOrganizationalUnit -Name 'Departments' -Path 'DC=example,DC=com';
          New-ADOrganizationalUnit -Name 'IT' -Path 'OU=Departments,DC=example,DC=com';
          New-ADOrganizationalUnit -Name 'HR' -Path 'OU=Departments,DC=example,DC=com';
          New-ADOrganizationalUnit -Name 'Finance' -Path 'OU=Departments,DC=example,DC=com';
          New-ADOrganizationalUnit -Name 'Service Accounts' -Path 'DC=example,DC=com';
          New-ADOrganizationalUnit -Name 'Admin Accounts' -Path 'DC=example,DC=com';
          
          # Create Security Groups
          New-ADGroup -Name 'IT-Admins' -GroupScope Global -GroupCategory Security -Path 'OU=IT,OU=Departments,DC=example,DC=com';
          New-ADGroup -Name 'HR-Users' -GroupScope Global -GroupCategory Security -Path 'OU=HR,OU=Departments,DC=example,DC=com';
          New-ADGroup -Name 'Finance-Users' -GroupScope Global -GroupCategory Security -Path 'OU=Finance,OU=Departments,DC=example,DC=com';
          New-ADGroup -Name 'Domain-Admins-Custom' -GroupScope Global -GroupCategory Security -Path 'OU=Admin Accounts,DC=example,DC=com';
          New-ADGroup -Name 'LDAP-Users' -GroupScope Global -GroupCategory Security -Path 'DC=example,DC=com';
          New-ADGroup -Name 'VPN-Users' -GroupScope Global -GroupCategory Security -Path 'DC=example,DC=com';
          
          # Create Admin Users
          New-ADUser -Name 'admin.it' -UserPrincipalName 'admin.it@${var.domain_name}' -SamAccountName 'admin.it' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'OU=Admin Accounts,DC=example,DC=com' -GivenName 'IT' -Surname 'Administrator';
          New-ADUser -Name 'admin.security' -UserPrincipalName 'admin.security@${var.domain_name}' -SamAccountName 'admin.security' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'OU=Admin Accounts,DC=example,DC=com' -GivenName 'Security' -Surname 'Administrator';
          
          # Create Department Users
          New-ADUser -Name 'john.doe' -UserPrincipalName 'john.doe@${var.domain_name}' -SamAccountName 'john.doe' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'OU=IT,OU=Departments,DC=example,DC=com' -GivenName 'John' -Surname 'Doe' -Department 'IT' -Title 'System Administrator';
          New-ADUser -Name 'jane.smith' -UserPrincipalName 'jane.smith@${var.domain_name}' -SamAccountName 'jane.smith' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'OU=HR,OU=Departments,DC=example,DC=com' -GivenName 'Jane' -Surname 'Smith' -Department 'HR' -Title 'HR Manager';
          New-ADUser -Name 'bob.wilson' -UserPrincipalName 'bob.wilson@${var.domain_name}' -SamAccountName 'bob.wilson' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'OU=Finance,OU=Departments,DC=example,DC=com' -GivenName 'Bob' -Surname 'Wilson' -Department 'Finance' -Title 'Financial Analyst';
          New-ADUser -Name 'alice.brown' -UserPrincipalName 'alice.brown@${var.domain_name}' -SamAccountName 'alice.brown' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'OU=IT,OU=Departments,DC=example,DC=com' -GivenName 'Alice' -Surname 'Brown' -Department 'IT' -Title 'Network Engineer';
          
          # Create Service Accounts
          New-ADUser -Name 'svc.ldap' -UserPrincipalName 'svc.ldap@${var.domain_name}' -SamAccountName 'svc.ldap' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'OU=Service Accounts,DC=example,DC=com' -Description 'LDAP Service Account';
          New-ADUser -Name 'svc.backup' -UserPrincipalName 'svc.backup@${var.domain_name}' -SamAccountName 'svc.backup' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'OU=Service Accounts,DC=example,DC=com' -Description 'Backup Service Account';
          New-ADUser -Name 'svc.monitoring' -UserPrincipalName 'svc.monitoring@${var.domain_name}' -SamAccountName 'svc.monitoring' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'OU=Service Accounts,DC=example,DC=com' -Description 'Monitoring Service Account';
          
          # Create legacy test users for compatibility
          New-ADUser -Name 'test1' -UserPrincipalName 'test1@${var.domain_name}' -SamAccountName 'test1' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'DC=example,DC=com';
          New-ADUser -Name 'test2' -UserPrincipalName 'test2@${var.domain_name}' -SamAccountName 'test2' -AccountPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Enabled $true -Path 'DC=example,DC=com';
          
          # Add users to groups
          Add-ADGroupMember -Identity 'IT-Admins' -Members 'john.doe','alice.brown','admin.it';
          Add-ADGroupMember -Identity 'HR-Users' -Members 'jane.smith';
          Add-ADGroupMember -Identity 'Finance-Users' -Members 'bob.wilson';
          Add-ADGroupMember -Identity 'Domain-Admins-Custom' -Members 'admin.it','admin.security';
          Add-ADGroupMember -Identity 'LDAP-Users' -Members 'john.doe','jane.smith','bob.wilson','alice.brown','test1','test2';
          Add-ADGroupMember -Identity 'VPN-Users' -Members 'john.doe','jane.smith','bob.wilson','alice.brown';
          
          # Configure Service Principal Names for Kerberos
          setspn -A ldap/windc2019.${var.domain_name} svc.ldap;
          setspn -A ldap/windc2019 svc.ldap;
          
          # Configure LDAP settings
          # Enable LDAP over SSL (requires certificate, will use self-signed for testing)
          
          # Set password policies
          Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $true -MinPasswordLength 8 -MaxPasswordAge 90.00:00:00 -MinPasswordAge 1.00:00:00 -PasswordHistoryCount 12;
          
          Write-Host 'AD Authentication Server setup complete with LDAP, Kerberos, and user accounts';
          
        } catch {
          Write-Host 'Error in AD configuration: ' + $_.Exception.Message;
        }
        
        # Restart to complete AD setup
        Restart-Computer -Force;
      "
    EOT
  })
}
