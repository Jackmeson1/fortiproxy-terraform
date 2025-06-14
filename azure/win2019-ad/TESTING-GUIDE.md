# AD 2019 Client-Server Authentication Testing Guide

## Infrastructure Deployed ✅

**Windows Server 2019 AD Controller:**
- Public IP: `52.179.0.176`
- Private IP: `10.0.1.4` 
- RDP Access: Available
- Domain: `example.com`

**Ubuntu 20.04 Client:**
- Public IP: `172.190.245.136`
- Private IP: `10.0.2.4`
- SSH Access: Available
- DNS: Configured to use AD server

## Manual Setup Steps

### 1. Configure AD Server (via RDP)

Connect to Windows Server: `52.179.0.176` (RDP)
- Username: `azureuser`
- Password: `P@ssw0rd1234!`

Run these PowerShell commands:

```powershell
# Install AD Domain Services
Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools

# Install AD Forest
$secpasswd = ConvertTo-SecureString 'P@ssw0rd1234!' -AsPlainText -Force
Install-ADDSForest -DomainName 'example.com' -SafeModeAdministratorPassword $secpasswd -Force -DomainNetbiosName 'CORP' -ForestMode 'WinThreshold' -DomainMode 'WinThreshold' -InstallDns

# Reboot will be required
```

After reboot, run:

```powershell
Import-Module ActiveDirectory

# Create test users
$securePassword = ConvertTo-SecureString "TestPass123!" -AsPlainText -Force
New-ADUser -Name "John Doe" -SamAccountName "john.doe" -UserPrincipalName "john.doe@example.com" -AccountPassword $securePassword -Enabled $true -PasswordNeverExpires $true
New-ADUser -Name "Linux Admin" -SamAccountName "linux.admin" -UserPrincipalName "linux.admin@example.com" -AccountPassword $securePassword -Enabled $true -PasswordNeverExpires $true

# Create groups
New-ADGroup -Name "Linux-Admins" -GroupScope Global -GroupCategory Security
Add-ADGroupMember -Identity "Linux-Admins" -Members "john.doe","linux.admin"
```

### 2. Test from Ubuntu Client (via SSH)

Connect to Ubuntu Client: 
```bash
ssh -i ~/.ssh/ad_client_key ubuntu@172.190.245.136
```

**Test 1: Basic Connectivity**
```bash
# Test DNS resolution
nslookup windc2019.example.com

# Test network connectivity  
ping 10.0.1.4
telnet 10.0.1.4 389  # LDAP
telnet 10.0.1.4 88   # Kerberos
```

**Test 2: Kerberos Authentication**
```bash
# Configure Kerberos
sudo tee /etc/krb5.conf > /dev/null << EOF
[libdefaults]
    default_realm = EXAMPLE.COM
    dns_lookup_realm = false
    dns_lookup_kdc = true
    ticket_lifetime = 24h
    forwardable = true

[realms]
    EXAMPLE.COM = {
        kdc = windc2019.example.com
        admin_server = windc2019.example.com
        default_domain = example.com
    }

[domain_realm]
    .example.com = EXAMPLE.COM
    example.com = EXAMPLE.COM
EOF

# Test Kerberos ticket acquisition
kinit john.doe@EXAMPLE.COM
# Password: TestPass123!

# Verify ticket
klist

# Test different users
kinit linux.admin@EXAMPLE.COM
klist
```

**Test 3: LDAP Authentication**
```bash
# Test LDAP bind with user credentials
ldapwhoami -H ldap://10.0.1.4 -D "john.doe@example.com" -W

# Search for users
ldapsearch -H ldap://10.0.1.4 -D "john.doe@example.com" -W -b "DC=example,DC=com" "(objectClass=user)" cn sAMAccountName mail

# Test with different authentication methods
ldapsearch -H ldap://windc2019.example.com -D "CN=John Doe,CN=Users,DC=example,DC=com" -W -b "DC=example,DC=com" "(sAMAccountName=linux.admin)"
```

**Test 4: LDAPS (Secure LDAP)**
```bash
# Test LDAPS connection (may require certificate trust)
ldapsearch -H ldaps://10.0.1.4:636 -D "john.doe@example.com" -W -b "DC=example,DC=com" "(objectClass=user)" cn
```

## Expected Results

✅ **Successful Kerberos Authentication:**
- `kinit` should succeed without errors
- `klist` should show valid tickets with realm EXAMPLE.COM
- Ticket lifetime should be 24h

✅ **Successful LDAP Authentication:** 
- `ldapwhoami` should return the user DN
- LDAP searches should return user objects
- Both userPrincipalName and distinguished name formats should work

✅ **Network Connectivity:**
- DNS resolution of windc2019.example.com should return 10.0.1.4
- Ports 88 (Kerberos) and 389 (LDAP) should be accessible

## Test Credentials

| Username | Password | Domain | Purpose |
|----------|----------|---------|---------|
| john.doe | TestPass123! | EXAMPLE.COM | Standard user testing |
| linux.admin | TestPass123! | EXAMPLE.COM | Admin user testing |
| azureuser | P@ssw0rd1234! | CORP | Local admin (Windows) |

## Troubleshooting

**DNS Issues:**
```bash
echo "10.0.1.4 windc2019.example.com windc2019" | sudo tee -a /etc/hosts
```

**Time Sync Issues:**
```bash
sudo timedatectl set-timezone UTC
sudo systemctl restart systemd-timesyncd
```

**Kerberos Debug:**
```bash
export KRB5_TRACE=/dev/stdout
kinit john.doe@EXAMPLE.COM
```

## Success Criteria

🎯 **Kerberos Ticket Test:** Successfully obtain and validate Kerberos tickets for multiple users
🎯 **LDAP Bind Test:** Successfully authenticate and query AD via LDAP protocol  
🎯 **Cross-Protocol Test:** Use Kerberos ticket for LDAP SASL/GSSAPI authentication
🎯 **Multiple Users:** Verify authentication works for different user accounts
🎯 **Service Accounts:** Test authentication with service accounts if configured

This validates that FortiProxy can successfully authenticate users against your Windows Server 2019 AD environment using both Kerberos and LDAP protocols.