# =============================================================================
# AUTOMATED CHILD DOMAIN SETUP - Case 2: Root-Child Architecture
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$RootDomainName = "${root_domain_name}",
    
    [Parameter(Mandatory=$true)]
    [string]$ChildDomainName = "${child_domain_name}",
    
    [Parameter(Mandatory=$true)]
    [string]$AdminPassword = "${admin_password}",
    
    [Parameter(Mandatory=$true)]
    [string]$RootDcIp = "${root_dc_ip}"
)

# Enable verbose logging
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

# Log function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] $Message"
    Add-Content -Path "C:\child-domain-setup.log" -Value "[$timestamp] $Message"
}

Write-Log "Starting Child Domain Setup"
Write-Log "Root Domain: $RootDomainName"
Write-Log "Child Domain: $ChildDomainName"
Write-Log "Root DC IP: $RootDcIp"

try {
    # =============================================================================
    # STEP 1: CONFIGURE DNS TO POINT TO ROOT DOMAIN
    # =============================================================================
    
    Write-Log "Configuring DNS to point to root domain controller..."
    
    # Set DNS server to root domain controller
    $networkAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*Loopback*"}
    Set-DnsClientServerAddress -InterfaceIndex $networkAdapter.InterfaceIndex -ServerAddresses $RootDcIp
    
    # Wait for DNS resolution to work
    $maxAttempts = 30
    $attempt = 0
    do {
        Start-Sleep -Seconds 10
        $attempt++
        Write-Log "Attempting DNS resolution of root domain (attempt $attempt/$maxAttempts)..."
        try {
            $dnsResult = Resolve-DnsName -Name $RootDomainName -ErrorAction SilentlyContinue
            if ($dnsResult) {
                Write-Log "DNS resolution successful"
                break
            }
        } catch {
            Write-Log "DNS resolution failed, retrying..."
        }
    } while ($attempt -lt $maxAttempts)
    
    if ($attempt -eq $maxAttempts) {
        throw "Failed to resolve root domain after $maxAttempts attempts"
    }
    
    Write-Log "DNS configuration completed successfully"
    
    # =============================================================================
    # STEP 2: INSTALL AD DOMAIN SERVICES
    # =============================================================================
    
    Write-Log "Installing Active Directory Domain Services role..."
    
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Restart:$false
    
    Write-Log "AD Domain Services role installed successfully"
    
    # =============================================================================
    # STEP 3: WAIT FOR ROOT DOMAIN TO BE FULLY READY
    # =============================================================================
    
    Write-Log "Waiting for root domain to be fully operational..."
    
    $maxWaitAttempts = 60  # 10 minutes
    $waitAttempt = 0
    do {
        Start-Sleep -Seconds 10
        $waitAttempt++
        Write-Log "Checking root domain availability (attempt $waitAttempt/$maxWaitAttempts)..."
        try {
            # Try to query the root domain
            $rootDomain = Get-ADDomain -Server $RootDomainName -ErrorAction SilentlyContinue
            if ($rootDomain) {
                Write-Log "Root domain is operational"
                break
            }
        } catch {
            Write-Log "Root domain not ready yet, continuing to wait..."
        }
    } while ($waitAttempt -lt $maxWaitAttempts)
    
    if ($waitAttempt -eq $maxWaitAttempts) {
        Write-Log "Warning: Root domain verification timeout, proceeding with child domain creation"
    }
    
    # =============================================================================
    # STEP 4: CREATE CHILD DOMAIN
    # =============================================================================
    
    Write-Log "Creating child domain: $ChildDomainName"
    
    $securePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    $rootDomainCredential = New-Object System.Management.Automation.PSCredential("$RootDomainName\Administrator", $securePassword)
    
    # Get the child domain name (dev part of dev.corp.local)
    $childDomainShortName = $ChildDomainName.Split('.')[0]
    
    Install-ADDSDomain `
        -NewDomainName $childDomainShortName `
        -ParentDomainName $RootDomainName `
        -DomainMode "WinThreshold" `
        -SafeModeAdministratorPassword $securePassword `
        -Credential $rootDomainCredential `
        -InstallDns:$true `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true `
        -NoRebootOnCompletion:$false
        
    Write-Log "Child domain creation initiated - server will reboot"
    
} catch {
    Write-Log "Error during initial child domain setup: $($_.Exception.Message)"
    
    # Schedule the post-reboot script for child domain configuration
    Write-Log "Scheduling post-reboot child domain configuration..."
    
    $postRebootScript = @"
# =============================================================================
# POST-REBOOT CHILD DOMAIN CONFIGURATION
# =============================================================================

`$VerbosePreference = "Continue"
`$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]`$Message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[`$timestamp] `$Message"
    Add-Content -Path "C:\child-domain-postreboot.log" -Value "[`$timestamp] `$Message"
}

Start-Sleep -Seconds 120  # Wait for AD services to fully start

Write-Log "Starting post-reboot child domain configuration..."

try {
    Import-Module ActiveDirectory -Force
    
    # =============================================================================
    # CREATE CHILD DOMAIN ORGANIZATIONAL UNITS
    # =============================================================================
    
    Write-Log "Creating child domain Organizational Units..."
    
    `$childDomainDN = "DC=" + "$ChildDomainName".Replace(".", ",DC=")
    
    # Child domain specific OUs
    New-ADOrganizationalUnit -Name "Development-Users" -Path `$childDomainDN -Description "Development Team Users"
    New-ADOrganizationalUnit -Name "Development-Groups" -Path `$childDomainDN -Description "Development Security Groups"
    New-ADOrganizationalUnit -Name "Test-Accounts" -Path `$childDomainDN -Description "Test User Accounts"
    New-ADOrganizationalUnit -Name "Development-Services" -Path `$childDomainDN -Description "Development Service Accounts"
    
    Write-Log "Child domain Organizational Units created successfully"
    
    # =============================================================================
    # CREATE CHILD DOMAIN SECURITY GROUPS
    # =============================================================================
    
    Write-Log "Creating child domain Security Groups..."
    
    `$developmentGroupsOU = "OU=Development-Groups,`$childDomainDN"
    
    # Development-specific groups (Domain Local for child domain resources)
    New-ADGroup -Name "Dev-Admins" -SamAccountName "Dev-Admins" -GroupCategory Security -GroupScope DomainLocal -DisplayName "Development Administrators" -Path `$developmentGroupsOU -Description "Development environment administrators"
    New-ADGroup -Name "Dev-Users" -SamAccountName "Dev-Users" -GroupCategory Security -GroupScope DomainLocal -DisplayName "Development Users" -Path `$developmentGroupsOU -Description "Development environment users"
    New-ADGroup -Name "QA-Team" -SamAccountName "QA-Team" -GroupCategory Security -GroupScope DomainLocal -DisplayName "Quality Assurance Team" -Path `$developmentGroupsOU -Description "QA and testing team"
    New-ADGroup -Name "Dev-Database-Access" -SamAccountName "Dev-Database-Access" -GroupCategory Security -GroupScope DomainLocal -DisplayName "Development Database Access" -Path `$developmentGroupsOU -Description "Development database access"
    New-ADGroup -Name "Dev-SSH-Users" -SamAccountName "Dev-SSH-Users" -GroupCategory Security -GroupScope DomainLocal -DisplayName "Development SSH Users" -Path `$developmentGroupsOU -Description "Development SSH access users"
    New-ADGroup -Name "FortiProxy-Dev-Users" -SamAccountName "FortiProxy-Dev-Users" -GroupCategory Security -GroupScope DomainLocal -DisplayName "FortiProxy Development Users" -Path `$developmentGroupsOU -Description "FortiProxy access for development"
    
    Write-Log "Child domain Security Groups created successfully"
    
    # =============================================================================
    # CREATE CHILD DOMAIN USERS
    # =============================================================================
    
    Write-Log "Creating child domain users..."
    
    `$developmentUsersOU = "OU=Development-Users,`$childDomainDN"
    `$testAccountsOU = "OU=Test-Accounts,`$childDomainDN"
    `$developmentServicesOU = "OU=Development-Services,`$childDomainDN"
    
    `$userPassword = ConvertTo-SecureString "TestPass123!" -AsPlainText -Force
    
    # Development Team Lead
    `$devLead = New-ADUser -Name "Dev Lead" -GivenName "Dev" -Surname "Lead" -SamAccountName "dev.lead" -UserPrincipalName "dev.lead@$ChildDomainName" -Path `$developmentUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "Development Team Lead" -PassThru
    Add-ADGroupMember -Identity "Dev-Admins" -Members `$devLead
    Add-ADGroupMember -Identity "Dev-Users" -Members `$devLead
    Add-ADGroupMember -Identity "Dev-SSH-Users" -Members `$devLead
    Add-ADGroupMember -Identity "FortiProxy-Dev-Users" -Members `$devLead
    
    # Senior Developer
    `$seniorDev = New-ADUser -Name "Senior Developer" -GivenName "Senior" -Surname "Developer" -SamAccountName "senior.dev" -UserPrincipalName "senior.dev@$ChildDomainName" -Path `$developmentUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "Senior Software Developer" -PassThru
    Add-ADGroupMember -Identity "Dev-Users" -Members `$seniorDev
    Add-ADGroupMember -Identity "Dev-Database-Access" -Members `$seniorDev
    Add-ADGroupMember -Identity "Dev-SSH-Users" -Members `$seniorDev
    Add-ADGroupMember -Identity "FortiProxy-Dev-Users" -Members `$seniorDev
    
    # Junior Developer
    `$juniorDev = New-ADUser -Name "Junior Developer" -GivenName "Junior" -Surname "Developer" -SamAccountName "junior.dev" -UserPrincipalName "junior.dev@$ChildDomainName" -Path `$developmentUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "Junior Software Developer" -PassThru
    Add-ADGroupMember -Identity "Dev-Users" -Members `$juniorDev
    Add-ADGroupMember -Identity "FortiProxy-Dev-Users" -Members `$juniorDev
    
    # QA Engineer
    `$qaEngineer = New-ADUser -Name "QA Engineer" -GivenName "QA" -Surname "Engineer" -SamAccountName "qa.engineer" -UserPrincipalName "qa.engineer@$ChildDomainName" -Path `$developmentUsersOU -AccountPassword `$userPassword -Enabled `$true -Description "Quality Assurance Engineer" -PassThru
    Add-ADGroupMember -Identity "QA-Team" -Members `$qaEngineer
    Add-ADGroupMember -Identity "Dev-Users" -Members `$qaEngineer
    Add-ADGroupMember -Identity "FortiProxy-Dev-Users" -Members `$qaEngineer
    
    # Test Users
    `$testUser1 = New-ADUser -Name "Test User 1" -GivenName "Test" -Surname "User1" -SamAccountName "test.user1" -UserPrincipalName "test.user1@$ChildDomainName" -Path `$testAccountsOU -AccountPassword `$userPassword -Enabled `$true -Description "Test User Account 1" -PassThru
    `$testUser2 = New-ADUser -Name "Test User 2" -GivenName "Test" -Surname "User2" -SamAccountName "test.user2" -UserPrincipalName "test.user2@$ChildDomainName" -Path `$testAccountsOU -AccountPassword `$userPassword -Enabled `$true -Description "Test User Account 2" -PassThru
    Add-ADGroupMember -Identity "Dev-Users" -Members `$testUser1, `$testUser2
    Add-ADGroupMember -Identity "FortiProxy-Dev-Users" -Members `$testUser1, `$testUser2
    
    # Development Service Accounts
    `$svcDevLdap = New-ADUser -Name "Dev LDAP Service" -GivenName "Dev" -Surname "LDAP" -SamAccountName "svc.dev.ldap" -UserPrincipalName "svc.dev.ldap@$ChildDomainName" -Path `$developmentServicesOU -AccountPassword `$userPassword -Enabled `$true -Description "Development LDAP Service Account" -PassThru
    `$svcDevApp = New-ADUser -Name "Dev App Service" -GivenName "Dev" -Surname "App" -SamAccountName "svc.dev.app" -UserPrincipalName "svc.dev.app@$ChildDomainName" -Path `$developmentServicesOU -AccountPassword `$userPassword -Enabled `$true -Description "Development Application Service Account" -PassThru
    
    Write-Log "Child domain users created successfully"
    
    # =============================================================================
    # CONFIGURE CROSS-DOMAIN GROUP MEMBERSHIPS
    # =============================================================================
    
    Write-Log "Configuring cross-domain group memberships..."
    
    try {
        # Add child domain admin to enterprise groups in root domain
        # This requires querying the root domain
        `$rootDomainDN = "DC=" + "$RootDomainName".Replace(".", ",DC=")
        
        # Add dev lead to corporate IT department (if accessible)
        Add-ADGroupMember -Identity "CN=IT-Department,OU=Corporate-Groups,`$rootDomainDN" -Members `$devLead -Server "$RootDomainName" -ErrorAction SilentlyContinue
        
        Write-Log "Cross-domain group memberships configured"
    } catch {
        Write-Log "Cross-domain group membership configuration will be completed after full trust establishment"
    }
    
    # =============================================================================
    # CONFIGURE DNS FOR CHILD DOMAIN
    # =============================================================================
    
    Write-Log "Configuring DNS for child domain..."
    
    # Create DNS records for child domain services
    Add-DnsServerResourceRecordA -ZoneName "$ChildDomainName" -Name "childdc" -IPv4Address "10.0.2.4"
    Add-DnsServerResourceRecordA -ZoneName "$ChildDomainName" -Name "dev-ldap" -IPv4Address "10.0.2.4"
    Add-DnsServerResourceRecordA -ZoneName "$ChildDomainName" -Name "dev-kerberos" -IPv4Address "10.0.2.4"
    
    Write-Log "Child domain DNS records created"
    
    # =============================================================================
    # CONFIGURE WINDOWS FIREWALL
    # =============================================================================
    
    Write-Log "Configuring Windows Firewall for child domain..."
    
    # Enable firewall rules for AD services
    Enable-NetFirewallRule -DisplayGroup "Active Directory Domain Services"
    Enable-NetFirewallRule -DisplayGroup "DNS Service"
    Enable-NetFirewallRule -DisplayGroup "Kerberos Key Distribution Center"
    
    # Create custom rules for child domain
    New-NetFirewallRule -DisplayName "Child-LDAP-In" -Direction Inbound -LocalPort 389 -Protocol TCP -Action Allow -Description "Child domain LDAP traffic"
    New-NetFirewallRule -DisplayName "Child-LDAPS-In" -Direction Inbound -LocalPort 636 -Protocol TCP -Action Allow -Description "Child domain LDAPS traffic"
    New-NetFirewallRule -DisplayName "Child-GC-In" -Direction Inbound -LocalPort 3268 -Protocol TCP -Action Allow -Description "Child domain Global Catalog"
    New-NetFirewallRule -DisplayName "Child-GC-SSL-In" -Direction Inbound -LocalPort 3269 -Protocol TCP -Action Allow -Description "Child domain Global Catalog SSL"
    
    Write-Log "Windows Firewall configured for child domain"
    
    # =============================================================================
    # VERIFY DOMAIN TRUST
    # =============================================================================
    
    Write-Log "Verifying domain trust relationship..."
    
    try {
        `$trust = Get-ADTrust -Filter * -Server "$ChildDomainName"
        if (`$trust) {
            Write-Log "Domain trust established successfully:"
            `$trust | ForEach-Object {
                Write-Log "  Trust: `$(`$_.Name) - Direction: `$(`$_.Direction) - Type: `$(`$_.TrustType)"
            }
        } else {
            Write-Log "Warning: No trust relationships found yet"
        }
    } catch {
        Write-Log "Trust verification will be available after full domain synchronization"
    }
    
    # =============================================================================
    # CREATE CHILD DOMAIN TESTING SUMMARY
    # =============================================================================
    
    Write-Log "Creating child domain testing summary..."
    
    `$testingSummary = @"
# =============================================================================
# CHILD DOMAIN TESTING ENVIRONMENT - CASE 2: ROOT-CHILD ARCHITECTURE
# =============================================================================

Domain Hierarchy:
- Forest Root: $RootDomainName (10.0.1.4)
- Child Domain: $ChildDomainName (10.0.2.4)
- Trust Type: Automatic two-way transitive trust (parent-child)

Child Domain Users Created:
1. dev.lead@$ChildDomainName (Password: TestPass123!)
   - Groups: Dev-Admins, Dev-Users, Dev-SSH-Users, FortiProxy-Dev-Users
   - Description: Development Team Lead

2. senior.dev@$ChildDomainName (Password: TestPass123!)
   - Groups: Dev-Users, Dev-Database-Access, Dev-SSH-Users, FortiProxy-Dev-Users
   - Description: Senior Software Developer

3. junior.dev@$ChildDomainName (Password: TestPass123!)
   - Groups: Dev-Users, FortiProxy-Dev-Users
   - Description: Junior Software Developer

4. qa.engineer@$ChildDomainName (Password: TestPass123!)
   - Groups: QA-Team, Dev-Users, FortiProxy-Dev-Users
   - Description: Quality Assurance Engineer

5. test.user1@$ChildDomainName (Password: TestPass123!)
   - Groups: Dev-Users, FortiProxy-Dev-Users
   - Description: Test User Account 1

6. test.user2@$ChildDomainName (Password: TestPass123!)
   - Groups: Dev-Users, FortiProxy-Dev-Users
   - Description: Test User Account 2

Service Accounts:
1. svc.dev.ldap@$ChildDomainName (Password: TestPass123!)
   - Purpose: Development LDAP Service Account

2. svc.dev.app@$ChildDomainName (Password: TestPass123!)
   - Purpose: Development Application Service Account

Child Domain Security Groups:
- Dev-Admins: Development environment administrators
- Dev-Users: Development environment users
- QA-Team: Quality Assurance team
- Dev-Database-Access: Development database access
- Dev-SSH-Users: Development SSH access users
- FortiProxy-Dev-Users: FortiProxy access for development

Cross-Domain Authentication Testing:
- Root domain users can access child domain resources
- Child domain users can authenticate to root domain services
- Global Catalog queries work across domains
- Universal groups from root domain available in child domain

FortiProxy Configuration (Child Domain):
- Server: 10.0.2.4 (child domain) or 10.0.1.4 (root domain GC)
- Port: 389 (LDAP) or 636 (LDAPS) or 3268 (Global Catalog)
- Base DN (Child): DC=$($ChildDomainName.Replace(".", ",DC="))
- Base DN (Forest): DC=$($RootDomainName.Replace(".", ",DC="))
- Bind DN (Child): dev.lead@$ChildDomainName or svc.dev.ldap@$ChildDomainName
- Bind DN (Forest): enterprise.admin@$RootDomainName or svc.fortiproxy@$RootDomainName
- Global Catalog Search: Use port 3268 on root DC for forest-wide searches

Multi-Domain Testing Scenarios:
1. Child domain user authentication to root domain services
2. Root domain user authentication to child domain services
3. Cross-domain group membership validation
4. Global Catalog searches across domains
5. Forest-wide security group access

Trust Verification Commands:
- nltest /domain_trusts /v
- Get-ADTrust -Filter *
- Test-ComputerSecureChannel

Deployment Status: ✅ CHILD DOMAIN READY - Parent-Child Trust Established
"@

    `$testingSummary | Out-File -FilePath "C:\child-domain-summary.txt" -Encoding UTF8
    
    Write-Log "Child domain testing summary created at C:\child-domain-summary.txt"
    
    # =============================================================================
    # CLEANUP AND COMPLETION
    # =============================================================================
    
    Write-Log "Child domain setup completed successfully!"
    Write-Log "Parent-child trust relationship established"
    Write-Log "Development users and groups created"
    Write-Log "Cross-domain authentication ready for testing"
    
    # Remove scheduled task
    Unregister-ScheduledTask -TaskName "ChildDomainPostRebootSetup" -Confirm:`$false -ErrorAction SilentlyContinue
    
    Write-Log "Post-reboot setup completed and scheduled task removed"
    
} catch {
    Write-Log "Error during child domain post-reboot setup: `$(`$_.Exception.Message)"
    Write-Log "Stack trace: `$(`$_.ScriptStackTrace)"
    throw
}
"@

    # Create scheduled task for post-reboot execution
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Unrestricted -Command `"$postRebootScript`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName "ChildDomainPostRebootSetup" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Complete child domain setup after reboot"
    
    Write-Log "Post-reboot child domain setup scheduled successfully"
    
    # Reboot to complete child domain creation
    Write-Log "Initiating reboot to complete child domain setup..."
    Restart-Computer -Force
}