# =============================================================================
# AUTOMATED ROOT DOMAIN SETUP - Case 2: Root-Child Architecture
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
    Add-Content -Path "C:\root-domain-setup.log" -Value "[$timestamp] $Message"
}

Write-Log "Starting Root Domain Setup for: $DomainName"
Write-Log "This will be the forest root domain for child domain testing"

try {
    # =============================================================================
    # STEP 1: INSTALL AD DOMAIN SERVICES
    # =============================================================================
    
    Write-Log "Installing Active Directory Domain Services role..."
    
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Restart:$false
    
    Write-Log "AD Domain Services role installed successfully"
    
    # =============================================================================
    # STEP 2: PROMOTE TO FOREST ROOT DOMAIN CONTROLLER
    # =============================================================================
    
    Write-Log "Promoting server to Forest Root Domain Controller..."
    
    $securePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    
    # Install new forest with root domain
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
        
    Write-Log "Forest Root Domain Controller promotion initiated - server will reboot"
    
} catch {
    Write-Log "Error during initial forest setup: $($_.Exception.Message)"
    
    # Schedule the post-reboot script for forest root configuration
    Write-Log "Scheduling post-reboot forest root configuration..."
    
    $postRebootScript = @"
# =============================================================================
# POST-REBOOT ROOT DOMAIN CONFIGURATION
# =============================================================================

`$VerbosePreference = "Continue"
`$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]`$Message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[`$timestamp] `$Message"
    Add-Content -Path "C:\root-domain-postreboot.log" -Value "[`$timestamp] `$Message"
}

Start-Sleep -Seconds 120  # Wait for AD services to fully start

Write-Log "Starting post-reboot root domain configuration..."

try {
    Import-Module ActiveDirectory -Force
    
    # =============================================================================
    # CREATE FOREST-WIDE ORGANIZATIONAL UNITS
    # =============================================================================
    
    Write-Log "Creating forest-wide Organizational Units..."
    
    `$domainDN = "DC=" + "$DomainName".Replace(".", ",DC=")
    
    # Root domain OUs
    New-ADOrganizationalUnit -Name "Corporate-Users" -Path `$domainDN -Description "Corporate Users in Root Domain"
    New-ADOrganizationalUnit -Name "Corporate-Groups" -Path `$domainDN -Description "Corporate Security Groups"
    New-ADOrganizationalUnit -Name "Service-Accounts" -Path `$domainDN -Description "Forest Service Accounts"
    New-ADOrganizationalUnit -Name "Enterprise-Admins" -Path `$domainDN -Description "Enterprise Administrators"
    
    Write-Log "Root domain Organizational Units created successfully"
    
    # =============================================================================
    # CREATE FOREST-WIDE SECURITY GROUPS
    # =============================================================================
    
    Write-Log "Creating forest-wide Security Groups..."
    
    `$corporateGroupsOU = "OU=Corporate-Groups,`$domainDN"
    
    # Corporate-level groups
    New-ADGroup -Name "Corporate-Admins" -SamAccountName "Corporate-Admins" -GroupCategory Security -GroupScope Universal -DisplayName "Corporate Administrators" -Path `$corporateGroupsOU -Description "Corporate-wide administrators"
    New-ADGroup -Name "IT-Department" -SamAccountName "IT-Department" -GroupCategory Security -GroupScope Universal -DisplayName "IT Department" -Path `$corporateGroupsOU -Description "Corporate IT Department"
    New-ADGroup -Name "Network-Engineers" -SamAccountName "Network-Engineers" -GroupCategory Security -GroupScope Universal -DisplayName "Network Engineers" -Path `$corporateGroupsOU -Description "Network Engineering Team"
    New-ADGroup -Name "Security-Team" -SamAccountName "Security-Team" -GroupCategory Security -GroupScope Universal -DisplayName "Security Team" -Path `$corporateGroupsOU -Description "Corporate Security Team"
    New-ADGroup -Name "FortiProxy-Admins" -SamAccountName "FortiProxy-Admins" -GroupCategory Security -GroupScope Universal -DisplayName "FortiProxy Administrators" -Path `$corporateGroupsOU -Description "FortiProxy WAF Administrators"
    New-ADGroup -Name "VPN-Users" -SamAccountName "VPN-Users" -GroupCategory Security -GroupScope Universal -DisplayName "VPN Users" -Path `$corporateGroupsOU -Description "VPN Access Users"
    
    Write-Log "Forest-wide Security Groups created successfully"
    
    # =============================================================================
    # CREATE ROOT DOMAIN USERS
    # =============================================================================
    
    Write-Log "Creating root domain users..."
    
    `$corporateUsersOU = "OU=Corporate-Users,`$domainDN"
    `$serviceAccountsOU = "OU=Service-Accounts,`$domainDN"
    `$enterpriseAdminsOU = "OU=Enterprise-Admins,`$domainDN"
    
    `$userPassword = ConvertTo-SecureString "TestPass123!" -AsPlainText -Force
    
    # Enterprise Administrator (highest privilege)
    `$enterpriseAdmin = New-ADUser -Name "Enterprise Admin" -GivenName "Enterprise" -Surname "Admin" -SamAccountName "enterprise.admin" -UserPrincipalName "enterprise.admin@$DomainName" -Path `$enterpriseAdminsOU -AccountPassword `$userPassword -Enabled `$true -Description "Enterprise Administrator - Forest-wide privileges" -PassThru
    Add-ADGroupMember -Identity "Enterprise Admins" -Members `$enterpriseAdmin
    Add-ADGroupMember -Identity "Domain Admins" -Members `$enterpriseAdmin
    Add-ADGroupMember -Identity "Corporate-Admins" -Members `$enterpriseAdmin
    Add-ADGroupMember -Identity "IT-Department" -Members `$enterpriseAdmin
    
    # Corporate IT Manager
    `$corpManager = New-ADUser -Name "Corp Manager" -GivenName "Corp" -Surname "Manager" -SamAccountName "corp.manager" -UserPrincipalName "corp.manager@$DomainName" -Path `$corporateUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "Corporate IT Manager" -PassThru
    Add-ADGroupMember -Identity "Corporate-Admins" -Members `$corpManager
    Add-ADGroupMember -Identity "IT-Department" -Members `$corpManager
    Add-ADGroupMember -Identity "FortiProxy-Admins" -Members `$corpManager
    
    # Network Engineer
    `$netEngineer = New-ADUser -Name "Network Engineer" -GivenName "Network" -Surname "Engineer" -SamAccountName "network.engineer" -UserPrincipalName "network.engineer@$DomainName" -Path `$corporateUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "Corporate Network Engineer" -PassThru
    Add-ADGroupMember -Identity "Network-Engineers" -Members `$netEngineer
    Add-ADGroupMember -Identity "IT-Department" -Members `$netEngineer
    Add-ADGroupMember -Identity "VPN-Users" -Members `$netEngineer
    
    # Security Analyst
    `$secAnalyst = New-ADUser -Name "Security Analyst" -GivenName "Security" -Surname "Analyst" -SamAccountName "security.analyst" -UserPrincipalName "security.analyst@$DomainName" -Path `$corporateUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "Corporate Security Analyst" -PassThru
    Add-ADGroupMember -Identity "Security-Team" -Members `$secAnalyst
    Add-ADGroupMember -Identity "FortiProxy-Admins" -Members `$secAnalyst
    Add-ADGroupMember -Identity "VPN-Users" -Members `$secAnalyst
    
    # Corporate Service Accounts
    `$svcFortiProxy = New-ADUser -Name "FortiProxy Service" -GivenName "FortiProxy" -Surname "Service" -SamAccountName "svc.fortiproxy" -UserPrincipalName "svc.fortiproxy@$DomainName" -Path `$serviceAccountsOU -AccountPassword `$userPassword -Enabled `$true -Description "FortiProxy LDAP Service Account (Forest-wide)" -PassThru
    `$svcEnterprise = New-ADUser -Name "Enterprise Service" -GivenName "Enterprise" -Surname "Service" -SamAccountName "svc.enterprise" -UserPrincipalName "svc.enterprise@$DomainName" -Path `$serviceAccountsOU -AccountPassword `$userPassword -Enabled `$true -Description "Enterprise-wide Service Account" -PassThru
    
    Write-Log "Root domain users created successfully"
    
    # =============================================================================
    # CONFIGURE DNS FOR CHILD DOMAIN SUPPORT
    # =============================================================================
    
    Write-Log "Configuring DNS for child domain support..."
    
    # Create DNS delegation for future child domain
    # This will be completed when child domain is created
    Add-DnsServerResourceRecordA -ZoneName "$DomainName" -Name "rootdc" -IPv4Address "10.0.1.4"
    Add-DnsServerResourceRecordA -ZoneName "$DomainName" -Name "ldap" -IPv4Address "10.0.1.4"
    Add-DnsServerResourceRecordA -ZoneName "$DomainName" -Name "kerberos" -IPv4Address "10.0.1.4"
    
    Write-Log "DNS configuration completed"
    
    # =============================================================================
    # CONFIGURE FOREST TRUSTS AND PERMISSIONS
    # =============================================================================
    
    Write-Log "Configuring forest-wide permissions..."
    
    # Configure Schema Admins group (for future schema extensions)
    # Enterprise Admins already have schema admin rights by default
    
    # Set up cross-domain authentication policies
    New-ADFineGrainedPasswordPolicy -Name "Corporate-Password-Policy" -ComplexityEnabled `$true -LockoutDuration "00:30:00" -LockoutObservationWindow "00:30:00" -LockoutThreshold 5 -MaxPasswordAge "42.00:00:00" -MinPasswordAge "1.00:00:00" -MinPasswordLength 12 -PasswordHistoryCount 24
    
    Write-Log "Forest-wide permissions configured"
    
    # =============================================================================
    # CONFIGURE WINDOWS FIREWALL FOR CROSS-DOMAIN COMMUNICATION
    # =============================================================================
    
    Write-Log "Configuring Windows Firewall for cross-domain communication..."
    
    # Enable firewall rules for AD services
    Enable-NetFirewallRule -DisplayGroup "Active Directory Domain Services"
    Enable-NetFirewallRule -DisplayGroup "DNS Service"
    Enable-NetFirewallRule -DisplayGroup "Kerberos Key Distribution Center"
    
    # Create custom rules for cross-domain communication
    New-NetFirewallRule -DisplayName "AD-Cross-Domain-LDAP" -Direction Inbound -LocalPort 389 -Protocol TCP -Action Allow -Description "Cross-domain LDAP traffic"
    New-NetFirewallRule -DisplayName "AD-Cross-Domain-LDAPS" -Direction Inbound -LocalPort 636 -Protocol TCP -Action Allow -Description "Cross-domain LDAPS traffic"
    New-NetFirewallRule -DisplayName "AD-Cross-Domain-GC" -Direction Inbound -LocalPort 3268 -Protocol TCP -Action Allow -Description "Cross-domain Global Catalog"
    New-NetFirewallRule -DisplayName "AD-Cross-Domain-GC-SSL" -Direction Inbound -LocalPort 3269 -Protocol TCP -Action Allow -Description "Cross-domain Global Catalog SSL"
    New-NetFirewallRule -DisplayName "AD-Cross-Domain-RPC" -Direction Inbound -LocalPort "49152-65535" -Protocol TCP -Action Allow -Description "Cross-domain RPC endpoint mapper"
    
    Write-Log "Windows Firewall configured for cross-domain communication"
    
    # =============================================================================
    # ENABLE ADDITIONAL FOREST FEATURES
    # =============================================================================
    
    Write-Log "Enabling additional forest features..."
    
    # Enable AD Recycle Bin
    Enable-ADOptionalFeature -Identity "Recycle Bin Feature" -Scope ForestOrConfigurationSet -Target "$DomainName" -Confirm:`$false
    
    # Enable Privileged Access Management (if supported)
    try {
        Enable-ADOptionalFeature -Identity "Privileged Access Management Feature" -Scope ForestOrConfigurationSet -Target "$DomainName" -Confirm:`$false
        Write-Log "Privileged Access Management enabled"
    } catch {
        Write-Log "Privileged Access Management not available in this forest functional level"
    }
    
    Write-Log "Additional forest features configured"
    
    # =============================================================================
    # CREATE ROOT DOMAIN TESTING SUMMARY
    # =============================================================================
    
    Write-Log "Creating root domain testing summary..."
    
    `$testingSummary = @"
# =============================================================================
# ROOT DOMAIN TESTING ENVIRONMENT - CASE 2: ROOT-CHILD ARCHITECTURE
# =============================================================================

Forest Information:
- Forest Root Domain: $DomainName
- Forest Functional Level: WinThreshold
- Root Domain Controller: rootdc.$DomainName (10.0.1.4)
- Child Domain: dev.$DomainName (will be created on child DC)

Root Domain Users Created:
1. enterprise.admin@$DomainName (Password: TestPass123!)
   - Groups: Enterprise Admins, Domain Admins, Corporate-Admins, IT-Department
   - Description: Enterprise Administrator with forest-wide privileges

2. corp.manager@$DomainName (Password: TestPass123!)
   - Groups: Corporate-Admins, IT-Department, FortiProxy-Admins
   - Description: Corporate IT Manager

3. network.engineer@$DomainName (Password: TestPass123!)
   - Groups: Network-Engineers, IT-Department, VPN-Users
   - Description: Corporate Network Engineer

4. security.analyst@$DomainName (Password: TestPass123!)
   - Groups: Security-Team, FortiProxy-Admins, VPN-Users
   - Description: Corporate Security Analyst

Service Accounts:
1. svc.fortiproxy@$DomainName (Password: TestPass123!)
   - Purpose: FortiProxy LDAP Service Account (Forest-wide)

2. svc.enterprise@$DomainName (Password: TestPass123!)
   - Purpose: Enterprise-wide Service Account

Forest-Wide Security Groups:
- Corporate-Admins: Corporate-wide administrators
- IT-Department: Corporate IT Department
- Network-Engineers: Network Engineering Team
- Security-Team: Corporate Security Team
- FortiProxy-Admins: FortiProxy WAF Administrators
- VPN-Users: VPN Access Users

Cross-Domain Testing:
- Forest trusts: Implicit parent-child trust will be established
- Global Catalog: Available for cross-domain queries
- Universal Groups: Available across entire forest
- Cross-domain authentication: Enabled

FortiProxy Configuration (Root Domain):
- Server: 10.0.1.4
- Port: 389 (LDAP) or 636 (LDAPS) or 3268 (Global Catalog)
- Base DN: DC=$($DomainName.Replace(".", ",DC="))
- Bind DN: enterprise.admin@$DomainName or svc.fortiproxy@$DomainName
- Bind Password: TestPass123!
- Global Catalog Port: 3268 (for forest-wide searches)

Child Domain Integration:
- Child domain will automatically have trust relationship with root
- Users from child domain can authenticate to root domain resources
- Global groups from root domain available to child domain

Deployment Status: ✅ ROOT DOMAIN READY - Waiting for Child Domain Setup
"@

    `$testingSummary | Out-File -FilePath "C:\root-domain-summary.txt" -Encoding UTF8
    
    Write-Log "Root domain testing summary created at C:\root-domain-summary.txt"
    
    # =============================================================================
    # CLEANUP AND COMPLETION
    # =============================================================================
    
    Write-Log "Root domain setup completed successfully!"
    Write-Log "Forest root domain is ready for child domain creation"
    Write-Log "Enterprise administrators and forest-wide groups created"
    Write-Log "DNS and firewall configured for cross-domain communication"
    
    # Remove scheduled task
    Unregister-ScheduledTask -TaskName "RootDomainPostRebootSetup" -Confirm:`$false -ErrorAction SilentlyContinue
    
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
    
    Register-ScheduledTask -TaskName "RootDomainPostRebootSetup" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Complete root domain setup after reboot"
    
    Write-Log "Post-reboot root domain setup scheduled successfully"
    
    # Reboot to complete forest installation
    Write-Log "Initiating reboot to complete forest root domain setup..."
    Restart-Computer -Force
}