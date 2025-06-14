# Configure Windows Firewall with proper rules instead of disabling
Write-Host 'Configuring Windows Firewall rules for AD services...'

# Enable Windows Firewall but add proper rules
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Add firewall rules for AD services (VNet only)
$vnetPrefix = '10.0.0.0/16'

# Core AD Services
New-NetFirewallRule -DisplayName 'AD-LDAP' -Direction Inbound -Protocol TCP -LocalPort 389 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-LDAPS' -Direction Inbound -Protocol TCP -LocalPort 636 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-Kerberos-TCP' -Direction Inbound -Protocol TCP -LocalPort 88 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-Kerberos-UDP' -Direction Inbound -Protocol UDP -LocalPort 88 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-DNS-TCP' -Direction Inbound -Protocol TCP -LocalPort 53 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-DNS-UDP' -Direction Inbound -Protocol UDP -LocalPort 53 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-Global-Catalog' -Direction Inbound -Protocol TCP -LocalPort 3268 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-Global-Catalog-SSL' -Direction Inbound -Protocol TCP -LocalPort 3269 -RemoteAddress $vnetPrefix -Action Allow

# Additional AD Services
New-NetFirewallRule -DisplayName 'AD-SMB' -Direction Inbound -Protocol TCP -LocalPort 445 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-RPC-Endpoint' -Direction Inbound -Protocol TCP -LocalPort 135 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-NetBIOS-NS' -Direction Inbound -Protocol UDP -LocalPort 137 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-NetBIOS-DGM' -Direction Inbound -Protocol UDP -LocalPort 138 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-NetBIOS-SSN' -Direction Inbound -Protocol TCP -LocalPort 139 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-NTP' -Direction Inbound -Protocol UDP -LocalPort 123 -RemoteAddress $vnetPrefix -Action Allow
New-NetFirewallRule -DisplayName 'AD-Dynamic-RPC' -Direction Inbound -Protocol TCP -LocalPort 49152-65535 -RemoteAddress $vnetPrefix -Action Allow

# RDP for admin access only
New-NetFirewallRule -DisplayName 'RDP-Admin' -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow

# Install AD Domain Services and DNS
Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools

# Convert password to secure string
$secpasswd = ConvertTo-SecureString '${admin_password}' -AsPlainText -Force

# Install AD Forest with comprehensive settings
Install-ADDSForest -DomainName '${domain_name}' -SafeModeAdministratorPassword $secpasswd -Force -NoRebootOnCompletion -DomainNetbiosName 'CORP' -ForestMode 'WinThreshold' -DomainMode 'WinThreshold' -InstallDns

# Wait for AD DS to finish configuring
Start-Sleep -Seconds 120

# Import Active Directory module
Import-Module ActiveDirectory

# Build domain DN from domain name
$domainParts = '${domain_name}'.Split('.')
$domainDN = ($domainParts | ForEach-Object { "DC=$_" }) -join ','

try {
  # Create Organizational Units
  New-ADOrganizationalUnit -Name 'Departments' -Path $domainDN
  New-ADOrganizationalUnit -Name 'IT' -Path "OU=Departments,$domainDN"
  New-ADOrganizationalUnit -Name 'HR' -Path "OU=Departments,$domainDN"
  New-ADOrganizationalUnit -Name 'Finance' -Path "OU=Departments,$domainDN"
  New-ADOrganizationalUnit -Name 'Service Accounts' -Path $domainDN
  New-ADOrganizationalUnit -Name 'Admin Accounts' -Path $domainDN
  New-ADOrganizationalUnit -Name 'Linux Clients' -Path $domainDN
  
  # Create Security Groups
  New-ADGroup -Name 'IT-Admins' -GroupScope Global -GroupCategory Security -Path "OU=IT,OU=Departments,$domainDN"
  New-ADGroup -Name 'HR-Users' -GroupScope Global -GroupCategory Security -Path "OU=HR,OU=Departments,$domainDN"
  New-ADGroup -Name 'Finance-Users' -GroupScope Global -GroupCategory Security -Path "OU=Finance,OU=Departments,$domainDN"
  New-ADGroup -Name 'Domain-Admins-Custom' -GroupScope Global -GroupCategory Security -Path "OU=Admin Accounts,$domainDN"
  New-ADGroup -Name 'LDAP-Users' -GroupScope Global -GroupCategory Security -Path $domainDN
  New-ADGroup -Name 'VPN-Users' -GroupScope Global -GroupCategory Security -Path $domainDN
  New-ADGroup -Name 'Linux-Admins' -GroupScope Global -GroupCategory Security -Path $domainDN
  New-ADGroup -Name 'SSH-Users' -GroupScope Global -GroupCategory Security -Path $domainDN
  
  # Create Admin Users
  New-ADUser -Name 'admin.it' -UserPrincipalName 'admin.it@${domain_name}' -SamAccountName 'admin.it' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=Admin Accounts,$domainDN" -GivenName 'IT' -Surname 'Administrator' -PasswordNeverExpires $true
  New-ADUser -Name 'admin.security' -UserPrincipalName 'admin.security@${domain_name}' -SamAccountName 'admin.security' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=Admin Accounts,$domainDN" -GivenName 'Security' -Surname 'Administrator' -PasswordNeverExpires $true
  
  # Create Department Users
  New-ADUser -Name 'john.doe' -UserPrincipalName 'john.doe@${domain_name}' -SamAccountName 'john.doe' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=IT,OU=Departments,$domainDN" -GivenName 'John' -Surname 'Doe' -Department 'IT' -Title 'System Administrator'
  New-ADUser -Name 'jane.smith' -UserPrincipalName 'jane.smith@${domain_name}' -SamAccountName 'jane.smith' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=HR,OU=Departments,$domainDN" -GivenName 'Jane' -Surname 'Smith' -Department 'HR' -Title 'HR Manager'
  New-ADUser -Name 'bob.wilson' -UserPrincipalName 'bob.wilson@${domain_name}' -SamAccountName 'bob.wilson' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=Finance,OU=Departments,$domainDN" -GivenName 'Bob' -Surname 'Wilson' -Department 'Finance' -Title 'Financial Analyst'
  New-ADUser -Name 'alice.brown' -UserPrincipalName 'alice.brown@${domain_name}' -SamAccountName 'alice.brown' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=IT,OU=Departments,$domainDN" -GivenName 'Alice' -Surname 'Brown' -Department 'IT' -Title 'Network Engineer'
  
  # Create Service Accounts with proper SPNs
  New-ADUser -Name 'svc.ldap' -UserPrincipalName 'svc.ldap@${domain_name}' -SamAccountName 'svc.ldap' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=Service Accounts,$domainDN" -Description 'LDAP Service Account' -PasswordNeverExpires $true -KerberosEncryptionType AES256
  New-ADUser -Name 'svc.krb' -UserPrincipalName 'svc.krb@${domain_name}' -SamAccountName 'svc.krb' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=Service Accounts,$domainDN" -Description 'Kerberos Service Account' -PasswordNeverExpires $true -KerberosEncryptionType AES256
  New-ADUser -Name 'svc.backup' -UserPrincipalName 'svc.backup@${domain_name}' -SamAccountName 'svc.backup' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=Service Accounts,$domainDN" -Description 'Backup Service Account' -PasswordNeverExpires $true
  New-ADUser -Name 'svc.monitoring' -UserPrincipalName 'svc.monitoring@${domain_name}' -SamAccountName 'svc.monitoring' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=Service Accounts,$domainDN" -Description 'Monitoring Service Account' -PasswordNeverExpires $true
  
  # Create test users for Linux authentication
  New-ADUser -Name 'linux.admin' -UserPrincipalName 'linux.admin@${domain_name}' -SamAccountName 'linux.admin' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=Linux Clients,$domainDN" -GivenName 'Linux' -Surname 'Administrator' -uidNumber 10001 -gidNumber 10001
  New-ADUser -Name 'linux.user1' -UserPrincipalName 'linux.user1@${domain_name}' -SamAccountName 'linux.user1' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path "OU=Linux Clients,$domainDN" -GivenName 'Linux' -Surname 'User1' -uidNumber 10002 -gidNumber 10001
  
  # Create legacy test users for compatibility
  New-ADUser -Name 'test1' -UserPrincipalName 'test1@${domain_name}' -SamAccountName 'test1' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path $domainDN
  New-ADUser -Name 'test2' -UserPrincipalName 'test2@${domain_name}' -SamAccountName 'test2' -AccountPassword (ConvertTo-SecureString '${admin_password}' -AsPlainText -Force) -Enabled $true -Path $domainDN
  
  # Add users to groups
  Add-ADGroupMember -Identity 'IT-Admins' -Members 'john.doe','alice.brown','admin.it'
  Add-ADGroupMember -Identity 'HR-Users' -Members 'jane.smith'
  Add-ADGroupMember -Identity 'Finance-Users' -Members 'bob.wilson'
  Add-ADGroupMember -Identity 'Domain-Admins-Custom' -Members 'admin.it','admin.security'
  Add-ADGroupMember -Identity 'LDAP-Users' -Members 'john.doe','jane.smith','bob.wilson','alice.brown','test1','test2','linux.admin','linux.user1'
  Add-ADGroupMember -Identity 'VPN-Users' -Members 'john.doe','jane.smith','bob.wilson','alice.brown'
  Add-ADGroupMember -Identity 'Linux-Admins' -Members 'linux.admin','admin.it'
  Add-ADGroupMember -Identity 'SSH-Users' -Members 'linux.admin','linux.user1','john.doe','alice.brown'
  
  # Configure Service Principal Names for Kerberos
  setspn -A ldap/windc2019.${domain_name} svc.ldap
  setspn -A ldap/windc2019 svc.ldap
  setspn -A host/windc2019.${domain_name} svc.krb
  setspn -A host/windc2019 svc.krb
  
  # Enable AES encryption for Kerberos
  Set-ADUser -Identity 'svc.ldap' -KerberosEncryptionType AES128,AES256
  Set-ADUser -Identity 'svc.krb' -KerberosEncryptionType AES128,AES256
  
  # Configure LDAP settings
  # Create self-signed certificate for LDAPS
  $cert = New-SelfSignedCertificate -DnsName 'windc2019.${domain_name}' -CertStoreLocation 'cert:\LocalMachine\My' -KeyExportPolicy Exportable -KeySpec KeyExchange -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256
  
  # Configure LDAPS
  $certThumbprint = $cert.Thumbprint
  Import-Module ActiveDirectory
  Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters' -Name 'LDAPServerIntegrity' -Value 1
  
  # Set password policies
  Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $true -MinPasswordLength 8 -MaxPasswordAge 90.00:00:00 -MinPasswordAge 1.00:00:00 -PasswordHistoryCount 12
  
  # Create Group Policy for Linux clients
  New-GPO -Name 'Linux Client Policy' -Comment 'Policy for Linux domain members'
  
  # Configure Kerberos settings
  # Set up krb5.conf template for Linux clients
  $domainUpper = '${domain_name}'.ToUpper()
  $krb5Template = @"
[libdefaults]
    default_realm = $domainUpper
    dns_lookup_realm = false
    dns_lookup_kdc = true
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true
    rdns = false
    default_ccache_name = KEYRING:persistent:%%{uid}
    default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 des3-cbc-sha1 arcfour-hmac-md5
    default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 des3-cbc-sha1 arcfour-hmac-md5
    permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 des3-cbc-sha1 arcfour-hmac-md5

[realms]
    $domainUpper = {
        kdc = windc2019.${domain_name}
        admin_server = windc2019.${domain_name}
        default_domain = ${domain_name}
    }

[domain_realm]
    .${domain_name} = $domainUpper
    ${domain_name} = $domainUpper
"@
  
  # Save krb5.conf template
  $krb5Template | Out-File -FilePath 'C:\krb5.conf.template' -Encoding ASCII
  
  Write-Host 'Enhanced AD Authentication Server setup complete with LDAP, Kerberos, and proper security configuration'
  
} catch {
  Write-Host 'Error in AD configuration: ' + $_.Exception.Message
}

# Configure NTP server
w32tm /config /manualpeerlist:'time.windows.com' /syncfromflags:manual /reliable:YES /update

# Restart to complete AD setup
Restart-Computer -Force