# =============================================================================
# OUTPUT CONFIGURATION
# Enhanced outputs for AD + Client environment
# =============================================================================

output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.rg.name
}

# Domain Controller Information
output "dc_public_ip" {
  description = "Public IP address of the Windows Domain Controller"
  value       = azurerm_public_ip.ad_ip.ip_address
}

output "dc_private_ip" {
  description = "Private IP address of the Windows Domain Controller"
  value       = azurerm_network_interface.ad_nic.private_ip_address
}

# Ubuntu Client Information
output "client_public_ip" {
  description = "Public IP address of the Ubuntu client"
  value       = azurerm_public_ip.client_ip.ip_address
}

output "client_private_ip" {
  description = "Private IP address of the Ubuntu client"
  value       = azurerm_network_interface.client_nic.private_ip_address
}

# Domain Configuration
output "domain_info" {
  description = "Active Directory domain information"
  value = {
    domain_name = var.domain_name
    netbios_name = "CORP"
    realm = upper(var.domain_name)
    dc_hostname = "windc2019"
    dc_fqdn = "windc2019.${var.domain_name}"
  }
}

# Connection Instructions
output "connection_instructions" {
  description = "Instructions for connecting to the deployed infrastructure"
  sensitive   = true
  value = <<EOT
=== Connection Instructions ===
    
Windows DC:
- RDP: ${azurerm_public_ip.ad_ip.ip_address}
- Username: ${var.admin_username}
- Password: <as configured>
    
Ubuntu Client:
- SSH: ssh ${var.client_admin_username}@${azurerm_public_ip.client_ip.ip_address}
- Use your private key that matches the public key provided
    
Domain Users (for testing):
- john.doe@${var.domain_name} (IT Admin)
- alice.brown@${var.domain_name} (Network Engineer)  
- linux.admin@${var.domain_name} (Linux Admin)
- linux.user1@${var.domain_name} (Regular User)
    
All domain users have the same password as the admin password.
    
Test Authentication:
1. SSH to Ubuntu client
2. Run: /opt/ad-tests/test-all.sh
3. Get Kerberos ticket: kinit john.doe@${upper(var.domain_name)}
4. Test SSH with AD user: ssh john.doe@localhost
EOT
}

# Security Configuration Summary
output "security_notes" {
  description = "Important security configuration notes"
  value = <<EOT
=== Security Configuration ===
    
Network Security:
- All AD services are restricted to VNet (10.0.0.0/16) only
- RDP access limited to: ${var.admin_source_ip}
- SSH access limited to: ${var.admin_source_ip}
    
To improve security:
1. Update admin_source_ip to your specific IP address
2. Use Azure Bastion instead of public IPs
3. Implement Azure Firewall for additional protection
4. Enable Azure AD MFA for admin accounts
5. Use managed identities where possible
    
Current exposed services:
- RDP (3389/TCP) - Admin IP only
- SSH (22/TCP) - Admin IP only
- All other services - VNet internal only
EOT
}

# Authentication Testing Information
output "test_credentials" {
  description = "Test user credentials for authentication testing"
  sensitive   = true
  value = {
    test_users = [
      {
        username = "john.doe"
        password = "TestPass123!"
        domain   = upper(var.domain_name)
        groups   = ["Domain Admins", "IT-Admins", "Linux-Admins"]
      },
      {
        username = "alice.brown"
        password = "TestPass123!"
        domain   = upper(var.domain_name)
        groups   = ["Linux-Admins", "SSH-Users"]
      },
      {
        username = "linux.admin"
        password = "TestPass123!"
        domain   = upper(var.domain_name)
        groups   = ["Linux-Admins", "SSH-Users"]
      },
      {
        username = "linux.user1"
        password = "TestPass123!"
        domain   = upper(var.domain_name)
        groups   = ["SSH-Users"]
      }
    ]
    service_accounts = [
      {
        username = "svc.ldap"
        password = "TestPass123!"
        domain   = upper(var.domain_name)
        purpose  = "LDAP service binding"
      },
      {
        username = "svc.krb"
        password = "TestPass123!"
        domain   = upper(var.domain_name)
        purpose  = "Kerberos service principal"
      }
    ]
  }
}

# Quick Start Commands
output "quick_start_commands" {
  description = "Quick start commands for testing"
  value = {
    ssh_to_client = "ssh -i ~/.ssh/ad_client_key ${var.client_admin_username}@${azurerm_public_ip.client_ip.ip_address}"
    rdp_to_dc     = "mstsc /v:${azurerm_public_ip.ad_ip.ip_address}"
    test_kerberos = "kinit john.doe@${upper(var.domain_name)}"
    test_ldap     = "ldapwhoami -H ldap://${azurerm_network_interface.ad_nic.private_ip_address} -D \"john.doe@${var.domain_name}\" -W"
  }
}

# Network Configuration Summary
output "network_config" {
  description = "Network configuration summary"
  value = {
    vnet_cidr      = "10.0.0.0/16"
    ad_subnet      = "10.0.1.0/24"
    client_subnet  = "10.0.2.0/24"
    dc_ip          = azurerm_network_interface.ad_nic.private_ip_address
    client_ip      = azurerm_network_interface.client_nic.private_ip_address
  }
}