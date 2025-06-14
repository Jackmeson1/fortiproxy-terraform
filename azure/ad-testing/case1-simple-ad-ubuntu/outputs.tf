# =============================================================================
# OUTPUTS - Case 1: Simple AD + Ubuntu
# =============================================================================

# Resource Group Information
output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "Location of the Azure Resource Group"
  value       = azurerm_resource_group.rg.location
}

# =============================================================================
# DOMAIN CONTROLLER INFORMATION
# =============================================================================

output "dc_public_ip" {
  description = "Public IP address of the Windows Domain Controller"
  value       = azurerm_public_ip.ad_ip.ip_address
}

output "dc_private_ip" {
  description = "Private IP address of the Windows Domain Controller"
  value       = azurerm_network_interface.ad_nic.private_ip_address
}

output "dc_hostname" {
  description = "Hostname of the Domain Controller"
  value       = "windc-${var.resource_group_name}"
}

output "dc_fqdn" {
  description = "Fully Qualified Domain Name of the Domain Controller"
  value       = "windc-${var.resource_group_name}.${var.domain_name}"
}

# =============================================================================
# UBUNTU CLIENT INFORMATION
# =============================================================================

output "client_public_ip" {
  description = "Public IP address of the Ubuntu client"
  value       = azurerm_public_ip.client_ip.ip_address
}

output "client_private_ip" {
  description = "Private IP address of the Ubuntu client"
  value       = azurerm_network_interface.client_nic.private_ip_address
}

# =============================================================================
# DOMAIN CONFIGURATION
# =============================================================================

output "domain_info" {
  description = "Active Directory domain information"
  value = {
    domain_name   = var.domain_name
    domain_upper  = upper(var.domain_name)
    domain_dn     = "DC=${replace(var.domain_name, ".", ",DC=")}"
    netbios_name  = upper(split(".", var.domain_name)[0])
    realm         = upper(var.domain_name)
  }
}

# =============================================================================
# CONNECTION COMMANDS
# =============================================================================

output "connection_commands" {
  description = "Commands to connect to the deployed infrastructure"
  value = {
    rdp_to_dc      = "mstsc /v:${azurerm_public_ip.ad_ip.ip_address}"
    ssh_to_client  = "ssh -i ~/.ssh/ad_client_key ${var.client_admin_username}@${azurerm_public_ip.client_ip.ip_address}"
  }
}

# =============================================================================
# TESTING INFORMATION
# =============================================================================

output "test_credentials" {
  description = "Test user credentials for authentication testing"
  sensitive   = true
  value = {
    admin_user = {
      username = var.admin_username
      password = var.admin_password
      domain   = var.domain_name
    }
    
    test_users = [
      {
        username    = "john.doe"
        password    = "TestPass123!"
        domain      = var.domain_name
        realm       = upper(var.domain_name)
        description = "IT Administrator - Full privileges"
        groups      = ["Domain Admins", "IT-Admins", "Linux-Admins"]
      },
      {
        username    = "alice.brown"
        password    = "TestPass123!"
        domain      = var.domain_name
        realm       = upper(var.domain_name)
        description = "Network Engineer - Network access"
        groups      = ["Linux-Admins", "SSH-Users"]
      },
      {
        username    = "linux.admin"
        password    = "TestPass123!"
        domain      = var.domain_name
        realm       = upper(var.domain_name)
        description = "Linux System Administrator"
        groups      = ["Linux-Admins", "SSH-Users"]
      },
      {
        username    = "linux.user1"
        password    = "TestPass123!"
        domain      = var.domain_name
        realm       = upper(var.domain_name)
        description = "Regular Linux User"
        groups      = ["SSH-Users"]
      }
    ]
    
    service_accounts = [
      {
        username    = "svc.ldap"
        password    = "TestPass123!"
        domain      = var.domain_name
        realm       = upper(var.domain_name)
        description = "LDAP Service Account for FortiProxy binding"
        purpose     = "LDAP authentication service"
      },
      {
        username    = "svc.krb"
        password    = "TestPass123!"
        domain      = var.domain_name
        realm       = upper(var.domain_name)
        description = "Kerberos Service Account"
        purpose     = "Kerberos authentication service"
      }
    ]
  }
}

# =============================================================================
# TESTING COMMANDS
# =============================================================================

output "test_commands" {
  description = "Commands for testing authentication"
  value = {
    # Kerberos commands
    kerberos_init     = "kinit john.doe@${upper(var.domain_name)}"
    kerberos_list     = "klist"
    kerberos_destroy  = "kdestroy"
    
    # LDAP commands
    ldap_whoami       = "ldapwhoami -H ldap://${azurerm_network_interface.ad_nic.private_ip_address} -D \"john.doe@${var.domain_name}\" -W"
    ldap_search_users = "ldapsearch -H ldap://${azurerm_network_interface.ad_nic.private_ip_address} -D \"john.doe@${var.domain_name}\" -W -b \"DC=${replace(var.domain_name, ".", ",DC=")}\" \"(objectClass=user)\" cn sAMAccountName"
    ldaps_search      = "ldapsearch -H ldaps://${azurerm_network_interface.ad_nic.private_ip_address}:636 -D \"john.doe@${var.domain_name}\" -W -b \"DC=${replace(var.domain_name, ".", ",DC=")}\" \"(sAMAccountName=linux.admin)\""
    
    # DNS test
    dns_test          = "nslookup windc-${var.resource_group_name}.${var.domain_name} ${azurerm_network_interface.ad_nic.private_ip_address}"
    
    # Network connectivity
    ping_dc           = "ping ${azurerm_network_interface.ad_nic.private_ip_address}"
    telnet_ldap       = "telnet ${azurerm_network_interface.ad_nic.private_ip_address} 389"
    telnet_kerberos   = "telnet ${azurerm_network_interface.ad_nic.private_ip_address} 88"
  }
}

# =============================================================================
# FORTIPROXY INTEGRATION INFO
# =============================================================================

output "fortiproxy_config" {
  description = "Configuration settings for FortiProxy LDAP integration"
  value = {
    ldap_server         = azurerm_network_interface.ad_nic.private_ip_address
    ldap_port           = "389"
    ldaps_port          = "636"
    base_dn            = "DC=${replace(var.domain_name, ".", ",DC=")}"
    bind_dn            = "john.doe@${var.domain_name}"
    bind_password      = "TestPass123!"
    cn_identifier      = "sAMAccountName"
    group_search_base  = "CN=Users,DC=${replace(var.domain_name, ".", ",DC=")}"
    user_search_filter = "(objectClass=user)"
    group_search_filter = "(objectClass=group)"
    
    # Kerberos settings
    kerberos_realm     = upper(var.domain_name)
    kdc_server         = azurerm_network_interface.ad_nic.private_ip_address
    admin_server       = azurerm_network_interface.ad_nic.private_ip_address
  }
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

output "network_config" {
  description = "Network configuration summary"
  value = {
    vnet_cidr           = "10.0.0.0/16"
    ad_subnet_cidr      = "10.0.1.0/24"
    client_subnet_cidr  = "10.0.2.0/24"
    dc_ip               = azurerm_network_interface.ad_nic.private_ip_address
    client_ip           = azurerm_network_interface.client_nic.private_ip_address
    dns_server          = azurerm_network_interface.ad_nic.private_ip_address
  }
}

# =============================================================================
# DEPLOYMENT STATUS
# =============================================================================

output "deployment_status" {
  description = "Status and next steps for the deployment"
  value = {
    status = "Deployment complete - Full automation enabled"
    case   = "Case 1: Simple AD + Ubuntu Client"
    
    next_steps = [
      "1. Wait 5-10 minutes for AD setup to complete",
      "2. SSH to Ubuntu client: ssh -i ~/.ssh/ad_client_key ${var.client_admin_username}@${azurerm_public_ip.client_ip.ip_address}",
      "3. Test Kerberos: kinit john.doe@${upper(var.domain_name)}",
      "4. Test LDAP: ldapwhoami -H ldap://${azurerm_network_interface.ad_nic.private_ip_address} -D \"john.doe@${var.domain_name}\" -W",
      "5. Deploy FortiProxy and configure LDAP authentication"
    ]
    
    automation_features = [
      "✅ Automated AD Domain Services installation",
      "✅ Automated test user creation",
      "✅ Automated Ubuntu client Kerberos/LDAP setup",
      "✅ Automated DNS configuration",
      "✅ Automated security group setup",
      "✅ Zero manual intervention required"
    ]
  }
}