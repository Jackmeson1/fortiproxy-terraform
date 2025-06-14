# =============================================================================
# AUTOMATED ACTIVE DIRECTORY SETUP - Case 1: Simple AD
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$DomainName = "${domain_name}",
    
    [Parameter(Mandatory=$true)]
    [string]$AdminPassword = "${admin_password}"
)

# Enable verbose logging
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

# Log function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] $Message"
    Add-Content -Path "C:\ad-setup.log" -Value "[$timestamp] $Message"
}

Write-Log "Starting Automated AD Setup for domain: $DomainName"

try {
    # =============================================================================
    # STEP 1: INSTALL AD DOMAIN SERVICES
    # =============================================================================
    
    Write-Log "Installing Active Directory Domain Services role..."
    
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Restart:$false
    
    Write-Log "AD Domain Services role installed successfully"
    
    # =============================================================================
    # STEP 2: PROMOTE TO DOMAIN CONTROLLER
    # =============================================================================
    
    Write-Log "Promoting server to Domain Controller..."
    
    $securePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    
    Install-ADDSForest `
        -DomainName $DomainName `
        -DomainMode "WinThreshold" `
        -ForestMode "WinThreshold" `
        -SafeModeAdministratorPassword $securePassword `
        -InstallDns:$true `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true `
        -NoRebootOnCompletion:$false
        
    Write-Log "Domain Controller promotion initiated - server will reboot"
    
} catch {
    Write-Log "Error during initial AD setup: $($_.Exception.Message)"
    
    # Schedule the post-reboot script
    Write-Log "Scheduling post-reboot configuration..."
    
    $postRebootScript = @"
# =============================================================================
# POST-REBOOT AD CONFIGURATION
# =============================================================================

`$VerbosePreference = "Continue"
`$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]`$Message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[`$timestamp] `$Message"
    Add-Content -Path "C:\ad-setup-postreboot.log" -Value "[`$timestamp] `$Message"
}

Start-Sleep -Seconds 60  # Wait for services to start

Write-Log "Starting post-reboot AD configuration..."

try {
    Import-Module ActiveDirectory -Force
    
    # =============================================================================
    # CREATE ORGANIZATIONAL UNITS
    # =============================================================================
    
    Write-Log "Creating Organizational Units..."
    
    `$domainDN = "DC=" + "$DomainName".Replace(".", ",DC=")
    
    New-ADOrganizationalUnit -Name "IT-Users" -Path `$domainDN -Description "IT Department Users"
    New-ADOrganizationalUnit -Name "Linux-Users" -Path `$domainDN -Description "Linux System Users"
    New-ADOrganizationalUnit -Name "Service-Accounts" -Path `$domainDN -Description "Service Accounts"
    New-ADOrganizationalUnit -Name "Security-Groups" -Path `$domainDN -Description "Security Groups"
    
    Write-Log "Organizational Units created successfully"
    
    # =============================================================================
    # CREATE SECURITY GROUPS
    # =============================================================================
    
    Write-Log "Creating Security Groups..."
    
    `$securityGroupsOU = "OU=Security-Groups,`$domainDN"
    
    New-ADGroup -Name "IT-Admins" -SamAccountName "IT-Admins" -GroupCategory Security -GroupScope Global -DisplayName "IT Administrators" -Path `$securityGroupsOU -Description "IT Department Administrators"
    New-ADGroup -Name "Linux-Admins" -SamAccountName "Linux-Admins" -GroupCategory Security -GroupScope Global -DisplayName "Linux Administrators" -Path `$securityGroupsOU -Description "Linux System Administrators"
    New-ADGroup -Name "SSH-Users" -SamAccountName "SSH-Users" -GroupCategory Security -GroupScope Global -DisplayName "SSH Users" -Path `$securityGroupsOU -Description "Users allowed SSH access"
    New-ADGroup -Name "FortiProxy-Users" -SamAccountName "FortiProxy-Users" -GroupCategory Security -GroupScope Global -DisplayName "FortiProxy Users" -Path `$securityGroupsOU -Description "Users allowed FortiProxy access"
    
    Write-Log "Security Groups created successfully"
    
    # =============================================================================
    # CREATE TEST USERS
    # =============================================================================
    
    Write-Log "Creating test users..."
    
    `$itUsersOU = "OU=IT-Users,`$domainDN"
    `$linuxUsersOU = "OU=Linux-Users,`$domainDN"
    `$serviceAccountsOU = "OU=Service-Accounts,`$domainDN"
    
    `$userPassword = ConvertTo-SecureString "TestPass123!" -AsPlainText -Force
    
    # IT Administrator
    `$john = New-ADUser -Name "John Doe" -GivenName "John" -Surname "Doe" -SamAccountName "john.doe" -UserPrincipalName "john.doe@$DomainName" -Path `$itUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "IT Administrator - Full privileges" -PassThru
    Add-ADGroupMember -Identity "Domain Admins" -Members `$john
    Add-ADGroupMember -Identity "IT-Admins" -Members `$john
    Add-ADGroupMember -Identity "Linux-Admins" -Members `$john
    Add-ADGroupMember -Identity "SSH-Users" -Members `$john
    Add-ADGroupMember -Identity "FortiProxy-Users" -Members `$john
    
    # Network Engineer
    `$alice = New-ADUser -Name "Alice Brown" -GivenName "Alice" -Surname "Brown" -SamAccountName "alice.brown" -UserPrincipalName "alice.brown@$DomainName" -Path `$itUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "Network Engineer - Network access privileges" -PassThru
    Add-ADGroupMember -Identity "Linux-Admins" -Members `$alice
    Add-ADGroupMember -Identity "SSH-Users" -Members `$alice
    Add-ADGroupMember -Identity "FortiProxy-Users" -Members `$alice
    
    # Linux Administrator
    `$linuxAdmin = New-ADUser -Name "Linux Admin" -GivenName "Linux" -Surname "Admin" -SamAccountName "linux.admin" -UserPrincipalName "linux.admin@$DomainName" -Path `$linuxUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "Linux System Administrator" -PassThru
    Add-ADGroupMember -Identity "Linux-Admins" -Members `$linuxAdmin
    Add-ADGroupMember -Identity "SSH-Users" -Members `$linuxAdmin
    Add-ADGroupMember -Identity "FortiProxy-Users" -Members `$linuxAdmin
    
    # Regular User
    `$linuxUser1 = New-ADUser -Name "Linux User1" -GivenName "Linux" -Surname "User1" -SamAccountName "linux.user1" -UserPrincipalName "linux.user1@$DomainName" -Path `$linuxUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "Regular Linux User" -PassThru
    Add-ADGroupMember -Identity "SSH-Users" -Members `$linuxUser1
    Add-ADGroupMember -Identity "FortiProxy-Users" -Members `$linuxUser1
    
    # Service Accounts
    `$svcLdap = New-ADUser -Name "LDAP Service" -GivenName "LDAP" -Surname "Service" -SamAccountName "svc.ldap" -UserPrincipalName "svc.ldap@$DomainName" -Path `$serviceAccountsOU -AccountPassword `$userPassword -Enabled `$true -Description "LDAP Service Account for FortiProxy binding" -PassThru
    `$svcKrb = New-ADUser -Name "Kerberos Service" -GivenName "Kerberos" -Surname "Service" -SamAccountName "svc.krb" -UserPrincipalName "svc.krb@$DomainName" -Path `$serviceAccountsOU -AccountPassword `$userPassword -Enabled `$true -Description "Kerberos Service Account" -PassThru
    
    Write-Log "Test users created successfully"
    
    # =============================================================================
    # CONFIGURE DNS
    # =============================================================================
    
    Write-Log "Configuring DNS settings..."
    
    # Create DNS records for easier access
    Add-DnsServerResourceRecordA -ZoneName "$DomainName" -Name "windc" -IPv4Address "10.0.1.4"
    Add-DnsServerResourceRecordA -ZoneName "$DomainName" -Name "ldap" -IPv4Address "10.0.1.4"
    Add-DnsServerResourceRecordA -ZoneName "$DomainName" -Name "kerberos" -IPv4Address "10.0.1.4"
    
    Write-Log "DNS records created successfully"
    
    # =============================================================================
    # CONFIGURE WINDOWS FIREWALL
    # =============================================================================
    
    Write-Log "Configuring Windows Firewall for AD services..."
    
    # Enable firewall rules for AD services
    Enable-NetFirewallRule -DisplayGroup "Active Directory Domain Services"
    Enable-NetFirewallRule -DisplayGroup "DNS Service"
    Enable-NetFirewallRule -DisplayGroup "Kerberos Key Distribution Center"
    
    # Create custom rules for LDAP/LDAPS
    New-NetFirewallRule -DisplayName "LDAP-In" -Direction Inbound -LocalPort 389 -Protocol TCP -Action Allow -Description "Allow LDAP traffic"
    New-NetFirewallRule -DisplayName "LDAPS-In" -Direction Inbound -LocalPort 636 -Protocol TCP -Action Allow -Description "Allow LDAPS traffic"
    New-NetFirewallRule -DisplayName "Global-Catalog-In" -Direction Inbound -LocalPort 3268 -Protocol TCP -Action Allow -Description "Allow Global Catalog traffic"
    New-NetFirewallRule -DisplayName "Global-Catalog-SSL-In" -Direction Inbound -LocalPort 3269 -Protocol TCP -Action Allow -Description "Allow Global Catalog SSL traffic"
    
    Write-Log "Windows Firewall configured successfully"
    
    # =============================================================================
    # CONFIGURE LDAP OVER SSL (LDAPS)
    # =============================================================================
    
    Write-Log "Configuring LDAPS certificate..."
    
    # Create self-signed certificate for LDAPS
    `$cert = New-SelfSignedCertificate -DnsName "windc.$DomainName", "$DomainName", "localhost" -CertStoreLocation "cert:\LocalMachine\My" -KeyAlgorithm RSA -KeyLength 2048 -Provider "Microsoft RSA SChannel Cryptographic Provider" -KeyExportPolicy Exportable -KeyUsage DigitalSignature, KeyEncipherment -Type SSLServerAuthentication
    
    # Export certificate to trusted root
    `$certThumbprint = `$cert.Thumbprint
    Export-Certificate -Cert "cert:\LocalMachine\My\`$certThumbprint" -FilePath "C:\ldaps-cert.cer"
    Import-Certificate -FilePath "C:\ldaps-cert.cer" -CertStoreLocation "cert:\LocalMachine\Root"
    
    Write-Log "LDAPS certificate configured successfully"
    
    # =============================================================================
    # ENABLE ADDITIONAL AD FEATURES
    # =============================================================================
    
    Write-Log "Enabling additional AD features..."
    
    # Enable AD Recycle Bin
    Enable-ADOptionalFeature -Identity "Recycle Bin Feature" -Scope ForestOrConfigurationSet -Target "$DomainName" -Confirm:`$false
    
    Write-Log "AD Recycle Bin enabled"
    
    # =============================================================================
    # CREATE TESTING SUMMARY
    # =============================================================================
    
    Write-Log "Creating testing summary file..."
    
    `$testingSummary = @"
# =============================================================================
# ACTIVE DIRECTORY TESTING ENVIRONMENT - CASE 1: SIMPLE AD
# =============================================================================

Domain Information:
- Domain Name: $DomainName
- Domain Controller: windc.$DomainName (10.0.1.4)
- LDAP Port: 389
- LDAPS Port: 636
- Kerberos Port: 88
- DNS Port: 53

Test Users Created:
1. john.doe@$DomainName (Password: TestPass123!)
   - Groups: Domain Admins, IT-Admins, Linux-Admins, SSH-Users, FortiProxy-Users
   - Description: IT Administrator with full privileges

2. alice.brown@$DomainName (Password: TestPass123!)
   - Groups: Linux-Admins, SSH-Users, FortiProxy-Users
   - Description: Network Engineer with network access

3. linux.admin@$DomainName (Password: TestPass123!)
   - Groups: Linux-Admins, SSH-Users, FortiProxy-Users
   - Description: Linux System Administrator

4. linux.user1@$DomainName (Password: TestPass123!)
   - Groups: SSH-Users, FortiProxy-Users
   - Description: Regular Linux User

Service Accounts:
1. svc.ldap@$DomainName (Password: TestPass123!)
   - Purpose: LDAP Service Account for FortiProxy binding

2. svc.krb@$DomainName (Password: TestPass123!)
   - Purpose: Kerberos Service Account

Security Groups Created:
- IT-Admins: IT Department Administrators
- Linux-Admins: Linux System Administrators
- SSH-Users: Users allowed SSH access
- FortiProxy-Users: Users allowed FortiProxy access

FortiProxy LDAP Configuration:
- Server: 10.0.1.4
- Port: 389 (LDAP) or 636 (LDAPS)
- Base DN: DC=$($DomainName.Replace(".", ",DC="))
- Bind DN: john.doe@$DomainName
- Bind Password: TestPass123!
- Common Name Identifier: sAMAccountName

Testing Commands (run from Ubuntu client):
- kinit john.doe@$($DomainName.ToUpper())
- klist
- ldapwhoami -H ldap://10.0.1.4 -D "john.doe@$DomainName" -W
- ldapsearch -H ldap://10.0.1.4 -D "john.doe@$DomainName" -W -b "DC=$($DomainName.Replace(".", ",DC="))" "(objectClass=user)"

Deployment Status: ✅ FULLY AUTOMATED - NO MANUAL INTERVENTION REQUIRED
"@

    `$testingSummary | Out-File -FilePath "C:\ad-testing-summary.txt" -Encoding UTF8
    
    Write-Log "Testing summary created at C:\ad-testing-summary.txt"
    
    # =============================================================================
    # CLEANUP AND COMPLETION
    # =============================================================================
    
    Write-Log "AD setup completed successfully!"
    Write-Log "Domain Controller is ready for authentication testing"
    Write-Log "All test users and groups have been created"
    Write-Log "LDAP, LDAPS, and Kerberos services are configured and running"
    
    # Remove scheduled task
    Unregister-ScheduledTask -TaskName "ADPostRebootSetup" -Confirm:`$false -ErrorAction SilentlyContinue
    
    Write-Log "Post-reboot setup completed and scheduled task removed"
    
} catch {
    Write-Log "Error during post-reboot setup: `$(`$_.Exception.Message)"
    Write-Log "Stack trace: `$(`$_.ScriptStackTrace)"
    throw
}
"@

    # Create scheduled task for post-reboot execution
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Unrestricted -Command `"$postRebootScript`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName "ADPostRebootSetup" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Complete AD setup after reboot"
    
    Write-Log "Post-reboot setup scheduled successfully"
    
    # Reboot to complete domain controller promotion
    Write-Log "Initiating reboot to complete domain controller setup..."
    Restart-Computer -Force
}