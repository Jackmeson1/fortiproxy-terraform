# Enhanced Windows Server 2019 AD with Ubuntu Client

This enhanced deployment creates a secure Active Directory environment with full Kerberos KDC and LDAP authentication capabilities, along with an Ubuntu client for testing.

## Architecture Overview

### Components
1. **Windows Server 2019 Domain Controller**
   - Active Directory Domain Services
   - DNS Server
   - Kerberos KDC
   - LDAP/LDAPS Server
   - Certificate Services (self-signed)

2. **Ubuntu 20.04 LTS Client**
   - Domain-joined via realmd/SSSD
   - Kerberos client configuration
   - LDAP tools
   - Test scripts for validation

3. **Network Security**
   - All AD services restricted to VNet only
   - Public access limited to admin IPs
   - Proper firewall rules instead of disabled firewall

### Network Design
```
VNet: 10.0.0.0/16
├── AD Subnet: 10.0.1.0/24
│   └── Windows DC: 10.0.1.4
└── Client Subnet: 10.0.2.0/24
    └── Ubuntu Client: Dynamic IP
```

## Security Improvements

### Network Security Groups
- **AD NSG**: All services restricted to VNet (10.0.0.0/16)
- **Client NSG**: SSH restricted to admin IPs
- **RDP/SSH**: Limited to specified admin source IPs

### Windows Firewall
- Enabled with proper rules (not disabled)
- Rules restricted to VNet traffic only
- RDP allowed for administration

## Deployment Instructions

### 1. Prerequisites
- Azure subscription with appropriate permissions
- Azure CLI or Terraform installed
- SSH key pair for Ubuntu client access

### 2. Generate SSH Keys
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ad_client_key
```

### 3. Configure Variables
```bash
cp terraform.tfvars.example-enhanced terraform.tfvars
# Edit terraform.tfvars with your values
```

**Important**: Set `admin_source_ip` to your actual IP address for security.

### 4. Deploy Infrastructure
```bash
# Use the enhanced configuration
terraform init
terraform plan -var-file=terraform.tfvars -out=tfplan -state=main-enhanced.tfstate
terraform apply tfplan

# Or specify the enhanced main.tf directly
terraform plan -var-file=terraform.tfvars -var-file=variables-enhanced.tf main-enhanced.tf
```

### 5. Wait for Deployment
The deployment takes approximately 15-20 minutes:
- VM provisioning: 5 minutes
- AD installation: 10 minutes
- Ubuntu client setup: 5 minutes

## Testing Authentication

### 1. Connect to Ubuntu Client
```bash
ssh -i ~/.ssh/ad_client_key ubuntu@<client-public-ip>
```

### 2. Run Comprehensive Test
```bash
sudo /opt/ad-tests/test-all.sh
```

### 3. Test Kerberos Authentication
```bash
# Get ticket
kinit john.doe@EXAMPLE.COM
# Password: <admin-password>

# List tickets
klist

# Destroy tickets
kdestroy
```

### 4. Test LDAP Authentication
```bash
# Simple bind test
ldapwhoami -H ldap://10.0.1.4 -D "john.doe@example.com" -W

# Search test
ldapsearch -H ldap://10.0.1.4 -D "john.doe@example.com" -W \
  -b "DC=example,DC=com" "(sAMAccountName=john.doe)"
```

### 5. Test SSH with AD Credentials
```bash
# From Ubuntu client
ssh john.doe@localhost
# Enter AD password
```

## Available Test Users

| Username | Type | Groups | Purpose |
|----------|------|--------|---------|
| john.doe | User | IT-Admins, SSH-Users | IT Administrator |
| alice.brown | User | IT-Admins, SSH-Users | Network Engineer |
| jane.smith | User | HR-Users | HR Manager |
| bob.wilson | User | Finance-Users | Financial Analyst |
| linux.admin | User | Linux-Admins, SSH-Users | Linux Administrator |
| linux.user1 | User | SSH-Users | Regular Linux User |
| svc.ldap | Service | - | LDAP Service Account |
| svc.krb | Service | - | Kerberos Service Account |

## Service Accounts and SPNs

### Service Principal Names
- `ldap/windc2019.example.com` - LDAP service
- `ldap/windc2019` - LDAP service (short name)
- `host/windc2019.example.com` - Host service
- `host/windc2019` - Host service (short name)

### Keytab Generation
```bash
# On Ubuntu client
sudo /opt/ad-tests/create-keytab.sh
```

## Kerberos Configuration

### Realm Information
- Realm: EXAMPLE.COM
- KDC: windc2019.example.com
- Admin Server: windc2019.example.com

### Encryption Types
- AES256-CTS-HMAC-SHA1-96
- AES128-CTS-HMAC-SHA1-96

### Client Configuration
Located at `/etc/krb5.conf` on Ubuntu client.

## SSSD Configuration

The Ubuntu client uses SSSD for AD integration:
- ID Provider: AD
- Auth Provider: AD
- Access Provider: AD
- Home Directory: /home/%u
- Shell: /bin/bash

## Troubleshooting

### Check Services
```bash
# On Ubuntu
systemctl status sssd
systemctl status ssh

# Check realm status
realm list
```

### Debug Kerberos
```bash
# Enable debug
KRB5_TRACE=/dev/stdout kinit john.doe@EXAMPLE.COM
```

### Debug SSSD
```bash
# Check SSSD logs
sudo journalctl -u sssd -f

# Clear SSSD cache
sudo sss_cache -E
sudo systemctl restart sssd
```

### DNS Issues
```bash
# Verify DNS
nslookup windc2019.example.com
nslookup _kerberos._tcp.example.com
```

## Security Best Practices

1. **Change Default Passwords**: Update all passwords from defaults
2. **Restrict Admin IPs**: Set specific IPs in `admin_source_ip`
3. **Use Azure Bastion**: Consider Azure Bastion instead of public IPs
4. **Enable MFA**: Add multi-factor authentication for admin accounts
5. **Regular Updates**: Keep both Windows and Ubuntu systems updated
6. **Monitor Access**: Enable Azure AD audit logs and monitoring

## Integration with FortiProxy

This AD setup is designed to test FortiProxy authentication:

1. **LDAP Authentication**
   - Server: 10.0.1.4
   - Port: 389 (LDAP) or 636 (LDAPS)
   - Base DN: DC=example,DC=com

2. **Kerberos Authentication**
   - Realm: EXAMPLE.COM
   - KDC: 10.0.1.4:88

3. **Test Groups**
   - VPN-Users: For VPN access testing
   - LDAP-Users: For general LDAP auth
   - IT-Admins: For admin access testing

## Clean Up

To destroy the infrastructure:
```bash
terraform destroy -var-file=terraform.tfvars
```

## Additional Resources

- [Azure AD DS Documentation](https://docs.microsoft.com/en-us/azure/active-directory-domain-services/)
- [SSSD AD Integration](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/windows_integration_guide/sssd-ad)
- [Kerberos Documentation](https://web.mit.edu/kerberos/krb5-latest/doc/)