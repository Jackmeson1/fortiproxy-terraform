# =============================================================================
# OUTPUTS - Case 2: AD Root-Child + Ubuntu
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
# DOMAIN CONTROLLERS INFORMATION
# =============================================================================

output "root_dc_public_ip" {
  description = "Public IP address of the Root Domain Controller"
  value       = azurerm_public_ip.root_ip.ip_address
}

output "root_dc_private_ip" {
  description = "Private IP address of the Root Domain Controller"
  value       = azurerm_network_interface.root_nic.private_ip_address
}

output "child_dc_public_ip" {
  description = "Public IP address of the Child Domain Controller"
  value       = azurerm_public_ip.child_ip.ip_address
}

output "child_dc_private_ip" {
  description = "Private IP address of the Child Domain Controller"
  value       = azurerm_network_interface.child_nic.private_ip_address
}

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

output "forest_info" {
  description = "Active Directory forest information"
  value = {
    forest_root_domain = var.root_domain_name
    child_domain       = var.child_domain_name
    root_domain_upper  = upper(var.root_domain_name)
    child_domain_upper = upper(var.child_domain_name)
    root_domain_dn     = "DC=${replace(var.root_domain_name, ".", ",DC=")}"
    child_domain_dn    = "DC=${replace(var.child_domain_name, ".", ",DC=")}"
    trust_type         = "Two-way transitive trust (parent-child)"
    forest_mode        = var.forest_functional_level
    domain_mode        = var.domain_functional_level
  }
}

# =============================================================================
# CONNECTION COMMANDS
# =============================================================================

output "connection_commands" {
  description = "Commands to connect to the deployed infrastructure"
  value = {
    rdp_to_root_dc   = "mstsc /v:${azurerm_public_ip.root_ip.ip_address}"
    rdp_to_child_dc  = "mstsc /v:${azurerm_public_ip.child_ip.ip_address}"
    ssh_to_client    = "ssh -i ~/.ssh/ad_client_key ${var.client_admin_username}@${azurerm_public_ip.client_ip.ip_address}"
  }
}

# =============================================================================
# TESTING INFORMATION
# =============================================================================

output "test_credentials" {
  description = "Test user credentials for multi-domain authentication testing"
  sensitive   = true
  value = {
    admin_credentials = {
      username = var.admin_username
      password = var.admin_password
      domains  = [var.root_domain_name, var.child_domain_name]
    }
    
    root_domain_users = [
      {
        username    = "enterprise.admin"
        password    = "TestPass123!"
        domain      = var.root_domain_name
        realm       = upper(var.root_domain_name)
        description = "Enterprise Administrator - Forest-wide privileges"
        groups      = ["Enterprise Admins", "Domain Admins", "Corporate-Admins", "IT-Department"]
      },
      {
        username    = "corp.manager"
        password    = "TestPass123!"
        domain      = var.root_domain_name
        realm       = upper(var.root_domain_name)
        description = "Corporate IT Manager"
        groups      = ["Corporate-Admins", "IT-Department", "FortiProxy-Admins"]
      },
      {
        username    = "network.engineer"
        password    = "TestPass123!"
        domain      = var.root_domain_name
        realm       = upper(var.root_domain_name)
        description = "Corporate Network Engineer"
        groups      = ["Network-Engineers", "IT-Department", "VPN-Users"]
      },
      {
        username    = "security.analyst"
        password    = "TestPass123!"
        domain      = var.root_domain_name
        realm       = upper(var.root_domain_name)
        description = "Corporate Security Analyst"
        groups      = ["Security-Team", "FortiProxy-Admins", "VPN-Users"]
      }
    ]
    
    child_domain_users = [
      {
        username    = "dev.lead"
        password    = "TestPass123!"
        domain      = var.child_domain_name
        realm       = upper(var.child_domain_name)
        description = "Development Team Lead"
        groups      = ["Dev-Admins", "Dev-Users", "Dev-SSH-Users", "FortiProxy-Dev-Users"]
      },
      {
        username    = "senior.dev"
        password    = "TestPass123!"
        domain      = var.child_domain_name
        realm       = upper(var.child_domain_name)
        description = "Senior Software Developer"
        groups      = ["Dev-Users", "Dev-Database-Access", "Dev-SSH-Users", "FortiProxy-Dev-Users"]
      },
      {
        username    = "junior.dev"
        password    = "TestPass123!"
        domain      = var.child_domain_name
        realm       = upper(var.child_domain_name)
        description = "Junior Software Developer"
        groups      = ["Dev-Users", "FortiProxy-Dev-Users"]
      },
      {
        username    = "qa.engineer"
        password    = "TestPass123!"
        domain      = var.child_domain_name
        realm       = upper(var.child_domain_name)
        description = "Quality Assurance Engineer"
        groups      = ["QA-Team", "Dev-Users", "FortiProxy-Dev-Users"]
      }
    ]
    
    service_accounts = [
      {
        username    = "svc.fortiproxy"
        password    = "TestPass123!"
        domain      = var.root_domain_name
        realm       = upper(var.root_domain_name)
        description = "FortiProxy LDAP Service Account (Forest-wide)"
        purpose     = "Forest-wide LDAP authentication"
      },
      {
        username    = "svc.enterprise"
        password    = "TestPass123!"
        domain      = var.root_domain_name
        realm       = upper(var.root_domain_name)
        description = "Enterprise-wide Service Account"
        purpose     = "Enterprise service integration"
      },
      {
        username    = "svc.dev.ldap"
        password    = "TestPass123!"
        domain      = var.child_domain_name
        realm       = upper(var.child_domain_name)
        description = "Development LDAP Service Account"
        purpose     = "Development environment LDAP binding"
      },
      {
        username    = "svc.dev.app"
        password    = "TestPass123!"
        domain      = var.child_domain_name
        realm       = upper(var.child_domain_name)
        description = "Development Application Service Account"
        purpose     = "Development application integration"
      }
    ]
  }
}

# =============================================================================
# TESTING COMMANDS
# =============================================================================

output "test_commands" {
  description = "Commands for testing multi-domain authentication"
  value = {
    # Root domain Kerberos commands
    root_kerberos_init    = "kinit enterprise.admin@${upper(var.root_domain_name)}"
    root_kerberos_manager = "kinit corp.manager@${upper(var.root_domain_name)}"
    root_kerberos_network = "kinit network.engineer@${upper(var.root_domain_name)}"
    
    # Child domain Kerberos commands
    child_kerberos_lead   = "kinit dev.lead@${upper(var.child_domain_name)}"
    child_kerberos_senior = "kinit senior.dev@${upper(var.child_domain_name)}"
    child_kerberos_qa     = "kinit qa.engineer@${upper(var.child_domain_name)}"
    
    # Multi-domain utilities
    kerberos_list         = "klist"
    kerberos_trusts       = "klist -T"
    kerberos_destroy      = "kdestroy"
    
    # Root domain LDAP commands
    root_ldap_whoami      = "ldapwhoami -H ldap://${azurerm_network_interface.root_nic.private_ip_address} -D \"enterprise.admin@${var.root_domain_name}\" -W"
    root_ldap_search      = "ldapsearch -H ldap://${azurerm_network_interface.root_nic.private_ip_address} -D \"enterprise.admin@${var.root_domain_name}\" -W -b \"DC=${replace(var.root_domain_name, ".", ",DC=")}\" \"(objectClass=user)\" cn sAMAccountName"
    
    # Child domain LDAP commands
    child_ldap_whoami     = "ldapwhoami -H ldap://${azurerm_network_interface.child_nic.private_ip_address} -D \"dev.lead@${var.child_domain_name}\" -W"
    child_ldap_search     = "ldapsearch -H ldap://${azurerm_network_interface.child_nic.private_ip_address} -D \"dev.lead@${var.child_domain_name}\" -W -b \"DC=${replace(var.child_domain_name, ".", ",DC=")}\" \"(objectClass=user)\" cn sAMAccountName"
    
    # Global Catalog commands (forest-wide)
    gc_search_forest      = "ldapsearch -H ldap://${azurerm_network_interface.root_nic.private_ip_address}:3268 -D \"enterprise.admin@${var.root_domain_name}\" -W -b \"DC=${replace(var.root_domain_name, ".", ",DC=")}\" \"(objectClass=user)\" cn sAMAccountName"
    gc_cross_domain       = "ldapsearch -H ldap://${azurerm_network_interface.root_nic.private_ip_address}:3268 -Y GSSAPI -b \"DC=${replace(var.root_domain_name, ".", ",DC=")}\" \"(objectClass=user)\" cn"
    
    # DNS and network tests
    dns_test_root         = "nslookup rootdc.${var.root_domain_name} ${azurerm_network_interface.root_nic.private_ip_address}"
    dns_test_child        = "nslookup childdc.${var.child_domain_name} ${azurerm_network_interface.child_nic.private_ip_address}"
    ping_root_dc          = "ping ${azurerm_network_interface.root_nic.private_ip_address}"
    ping_child_dc         = "ping ${azurerm_network_interface.child_nic.private_ip_address}"
    
    # Port connectivity tests
    telnet_root_ldap      = "telnet ${azurerm_network_interface.root_nic.private_ip_address} 389"
    telnet_root_gc        = "telnet ${azurerm_network_interface.root_nic.private_ip_address} 3268"
    telnet_child_ldap     = "telnet ${azurerm_network_interface.child_nic.private_ip_address} 389"
    telnet_root_kerberos  = "telnet ${azurerm_network_interface.root_nic.private_ip_address} 88"
    telnet_child_kerberos = "telnet ${azurerm_network_interface.child_nic.private_ip_address} 88"
  }
}

# =============================================================================
# FORTIPROXY INTEGRATION INFO
# =============================================================================

output "fortiproxy_config" {
  description = "Configuration settings for FortiProxy multi-domain LDAP integration"
  value = {
    # Root domain configuration (recommended for forest-wide access)
    root_domain = {
      ldap_server         = azurerm_network_interface.root_nic.private_ip_address
      ldap_port           = "389"
      ldaps_port          = "636"
      global_catalog_port = "3268"
      global_catalog_ssl  = "3269"
      base_dn            = "DC=${replace(var.root_domain_name, ".", ",DC=")}"
      bind_dn            = "enterprise.admin@${var.root_domain_name}"
      bind_password      = "TestPass123!"
      cn_identifier      = "sAMAccountName"
      purpose            = "Forest-wide authentication via Global Catalog"
    }
    
    # Child domain configuration (for domain-specific access)
    child_domain = {
      ldap_server    = azurerm_network_interface.child_nic.private_ip_address
      ldap_port      = "389"
      ldaps_port     = "636"
      base_dn        = "DC=${replace(var.child_domain_name, ".", ",DC=")}"
      bind_dn        = "dev.lead@${var.child_domain_name}"
      bind_password  = "TestPass123!"
      cn_identifier  = "sAMAccountName"
      purpose        = "Child domain specific authentication"
    }
    
    # Search filters for multi-domain
    search_filters = {
      all_forest_users     = "(objectClass=user)"
      root_domain_users    = "(&(objectClass=user)(userPrincipalName=*@${var.root_domain_name}))"
      child_domain_users   = "(&(objectClass=user)(userPrincipalName=*@${var.child_domain_name}))"
      enterprise_admins    = "(memberOf=CN=Enterprise Admins,CN=Users,DC=${replace(var.root_domain_name, ".", ",DC=")})"
      corporate_admins     = "(memberOf=CN=Corporate-Admins,OU=Corporate-Groups,DC=${replace(var.root_domain_name, ".", ",DC=")})"
      dev_users            = "(memberOf=CN=Dev-Users,OU=Development-Groups,DC=${replace(var.child_domain_name, ".", ",DC=")})"
      fortiproxy_admins    = "(memberOf=CN=FortiProxy-Admins,OU=Corporate-Groups,DC=${replace(var.root_domain_name, ".", ",DC=")})"
      fortiproxy_dev_users = "(memberOf=CN=FortiProxy-Dev-Users,OU=Development-Groups,DC=${replace(var.child_domain_name, ".", ",DC=")})"
    }
    
    # Kerberos settings for multi-domain
    kerberos = {
      root_realm     = upper(var.root_domain_name)
      child_realm    = upper(var.child_domain_name)
      root_kdc       = azurerm_network_interface.root_nic.private_ip_address
      child_kdc      = azurerm_network_interface.child_nic.private_ip_address
      trust_type     = "Two-way transitive trust"
    }
  }
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

output "network_config" {
  description = "Multi-domain network configuration summary"
  value = {
    vnet_cidr             = "10.0.0.0/16"
    root_subnet_cidr      = "10.0.1.0/24"
    child_subnet_cidr     = "10.0.2.0/24"
    client_subnet_cidr    = "10.0.3.0/24"
    root_dc_ip            = azurerm_network_interface.root_nic.private_ip_address
    child_dc_ip           = azurerm_network_interface.child_nic.private_ip_address
    client_ip             = azurerm_network_interface.client_nic.private_ip_address
    primary_dns_server    = azurerm_network_interface.root_nic.private_ip_address
    secondary_dns_server  = azurerm_network_interface.child_nic.private_ip_address
  }
}

# =============================================================================
# DEPLOYMENT STATUS
# =============================================================================

output "deployment_status" {
  description = "Status and next steps for the multi-domain deployment"
  value = {
    status = "Multi-domain deployment complete - Full automation enabled"
    case   = "Case 2: Root-Child Domain Architecture"
    
    forest_structure = [
      "Root Domain: ${var.root_domain_name} (${azurerm_network_interface.root_nic.private_ip_address})",
      "Child Domain: ${var.child_domain_name} (${azurerm_network_interface.child_nic.private_ip_address})",
      "Trust Type: Automatic two-way transitive trust (parent-child)"
    ]
    
    next_steps = [
      "1. Wait 15-20 minutes for both AD domains to be fully configured",
      "2. SSH to Ubuntu client: ssh -i ~/.ssh/ad_client_key ${var.client_admin_username}@${azurerm_public_ip.client_ip.ip_address}",
      "3. Run comprehensive tests: /opt/multidomain-tests/test-all-domains.sh",
      "4. Test root domain: kinit enterprise.admin@${upper(var.root_domain_name)}",
      "5. Test child domain: kinit dev.lead@${upper(var.child_domain_name)}",
      "6. Test cross-domain: /opt/multidomain-tests/test-cross-domain.sh",
      "7. Verify trust: /opt/multidomain-tests/verify-trust.sh",
      "8. Deploy FortiProxy and configure for multi-domain LDAP"
    ]
    
    automation_features = [
      "✅ Automated root domain forest creation",
      "✅ Automated child domain and trust establishment",
      "✅ Automated enterprise and development user creation",
      "✅ Automated forest-wide and domain-specific security groups",
      "✅ Automated Ubuntu client multi-domain configuration",
      "✅ Automated Global Catalog setup for forest-wide searches",
      "✅ Automated cross-domain DNS and firewall configuration",
      "✅ Zero manual intervention required"
    ]
    
    testing_capabilities = [
      "🎫 Multi-realm Kerberos authentication",
      "📂 Domain-specific and forest-wide LDAP queries",
      "🌐 Global Catalog cross-domain searches",
      "🔗 Cross-domain trust verification",
      "🛡️ Enterprise and domain-specific group membership",
      "🔍 FortiProxy multi-domain integration testing"
    ]
  }
}