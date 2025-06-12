output "public_ip" {
  value       = azurerm_public_ip.ip.ip_address
  description = "Public IP address of the AD server"
}

output "domain_name" {
  value       = var.domain_name
  description = "Active Directory domain name"
}

output "admin_username" {
  value       = var.admin_username
  description = "Local administrator username"
}

output "admin_password" {
  value       = var.admin_password
  sensitive   = true
  description = "Administrator password"
}

output "ldap_server" {
  value       = "ldap://${azurerm_public_ip.ip.ip_address}:389"
  description = "LDAP server connection string"
}

output "ldaps_server" {
  value       = "ldaps://${azurerm_public_ip.ip.ip_address}:636"
  description = "LDAP over SSL server connection string"
}

output "kerberos_realm" {
  value       = upper(var.domain_name)
  description = "Kerberos realm (uppercase domain name)"
}

output "authentication_info" {
  sensitive = true
  value = <<-EOT
    ====== Active Directory Authentication Server ======
    Domain: ${var.domain_name}
    NetBIOS: CORP
    Public IP: ${azurerm_public_ip.ip.ip_address}
    
    LDAP Settings:
    - LDAP URL: ldap://${azurerm_public_ip.ip.ip_address}:389
    - LDAPS URL: ldaps://${azurerm_public_ip.ip.ip_address}:636
    - Base DN: DC=example,DC=com
    
    Kerberos Settings:
    - Realm: ${upper(var.domain_name)}
    - KDC: ${azurerm_public_ip.ip.ip_address}:88
    
    Sample Users Created:
    Admin Accounts:
    - admin.it@${var.domain_name}
    - admin.security@${var.domain_name}
    
    Department Users:
    - john.doe@${var.domain_name} (IT)
    - alice.brown@${var.domain_name} (IT)
    - jane.smith@${var.domain_name} (HR)
    - bob.wilson@${var.domain_name} (Finance)
    
    Service Accounts:
    - svc.ldap@${var.domain_name}
    - svc.backup@${var.domain_name}
    - svc.monitoring@${var.domain_name}
    
    Legacy Test Users:
    - test1@${var.domain_name}
    - test2@${var.domain_name}
    
    Security Groups:
    - IT-Admins, HR-Users, Finance-Users
    - LDAP-Users, VPN-Users, Domain-Admins-Custom
    
    All users have password: ${var.admin_password}
    ================================================
  EOT
  description = "Complete authentication server information"
}
