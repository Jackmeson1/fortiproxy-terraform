# Part 2 - Run after reboot
# Creates test users and groups for authentication testing

Import-Module ActiveDirectory

# Create OUs
Write-Host "Creating Organizational Units..."
New-ADOrganizationalUnit -Name "TestUsers" -Path "DC=example,DC=com"
New-ADOrganizationalUnit -Name "ServiceAccounts" -Path "DC=example,DC=com"
New-ADOrganizationalUnit -Name "LinuxSystems" -Path "DC=example,DC=com"

# Create Groups
Write-Host "Creating Groups..."
New-ADGroup -Name "Linux-Admins" -GroupScope Global -GroupCategory Security -Path "OU=TestUsers,DC=example,DC=com"
New-ADGroup -Name "SSH-Users" -GroupScope Global -GroupCategory Security -Path "OU=TestUsers,DC=example,DC=com"
New-ADGroup -Name "IT-Admins" -GroupScope Global -GroupCategory Security -Path "OU=TestUsers,DC=example,DC=com"

# Create Test Users
Write-Host "Creating Test Users..."
$securePassword = ConvertTo-SecureString "TestPass123!" -AsPlainText -Force

New-ADUser -Name "John Doe" -SamAccountName "john.doe" -UserPrincipalName "john.doe@example.com" -AccountPassword $securePassword -Enabled $true -Path "OU=TestUsers,DC=example,DC=com" -PasswordNeverExpires $true
New-ADUser -Name "Alice Brown" -SamAccountName "alice.brown" -UserPrincipalName "alice.brown@example.com" -AccountPassword $securePassword -Enabled $true -Path "OU=TestUsers,DC=example,DC=com" -PasswordNeverExpires $true
New-ADUser -Name "Linux Admin" -SamAccountName "linux.admin" -UserPrincipalName "linux.admin@example.com" -AccountPassword $securePassword -Enabled $true -Path "OU=TestUsers,DC=example,DC=com" -PasswordNeverExpires $true
New-ADUser -Name "Linux User1" -SamAccountName "linux.user1" -UserPrincipalName "linux.user1@example.com" -AccountPassword $securePassword -Enabled $true -Path "OU=TestUsers,DC=example,DC=com" -PasswordNeverExpires $true

# Create Service Accounts
New-ADUser -Name "LDAP Service" -SamAccountName "svc.ldap" -UserPrincipalName "svc.ldap@example.com" -AccountPassword $securePassword -Enabled $true -Path "OU=ServiceAccounts,DC=example,DC=com" -PasswordNeverExpires $true
New-ADUser -Name "Kerberos Service" -SamAccountName "svc.krb" -UserPrincipalName "svc.krb@example.com" -AccountPassword $securePassword -Enabled $true -Path "OU=ServiceAccounts,DC=example,DC=com" -PasswordNeverExpires $true

# Add users to groups
Write-Host "Adding users to groups..."
Add-ADGroupMember -Identity "Linux-Admins" -Members "john.doe","alice.brown","linux.admin"
Add-ADGroupMember -Identity "SSH-Users" -Members "john.doe","alice.brown","linux.admin","linux.user1"
Add-ADGroupMember -Identity "IT-Admins" -Members "john.doe","alice.brown"
Add-ADGroupMember -Identity "Domain Admins" -Members "john.doe"

# Configure Kerberos encryption types
Write-Host "Configuring Kerberos encryption..."
Get-ADUser -Filter * | Set-ADUser -KerberosEncryptionType AES128,AES256

Write-Host "AD configuration complete!"
Write-Host "Test credentials:"
Write-Host "  Username: john.doe"
Write-Host "  Password: TestPass123!"
Write-Host "  Domain: EXAMPLE.COM"