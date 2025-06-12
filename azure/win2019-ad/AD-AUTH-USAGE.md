# Active Directory Authentication Server Usage Guide

This Terraform deployment creates a comprehensive Windows Server 2019 Active Directory Domain Controller with LDAP, LDAPS, and Kerberos authentication services.

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Services Configured

### 1. Active Directory Domain Services (AD DS)
- **Domain**: example.com  
- **NetBIOS**: CORP
- **Forest/Domain Functional Level**: Windows Server 2016 (WinThreshold)

### 2. LDAP Services
- **LDAP Port**: 389 (standard)
- **LDAPS Port**: 636 (SSL encrypted)
- **Base DN**: `DC=example,DC=com`
- **Global Catalog**: 3268 (standard), 3269 (SSL)

### 3. Kerberos Authentication
- **Realm**: EXAMPLE.COM (uppercase domain)
- **KDC Port**: 88 (TCP/UDP)
- **Service Principal Names**: Configured for LDAP service

### 4. DNS Services
- **DNS Port**: 53 (TCP/UDP)
- **Domain DNS**: Integrated with AD

## Organizational Structure

```
DC=example,DC=com
├── OU=Departments
│   ├── OU=IT
│   ├── OU=HR
│   └── OU=Finance
├── OU=Service Accounts
└── OU=Admin Accounts
```

## User Accounts Created

### Administrative Users
| Username | UPN | Location | Group Membership |
|----------|-----|----------|------------------|
| admin.it | admin.it@example.com | OU=Admin Accounts | IT-Admins, Domain-Admins-Custom |
| admin.security | admin.security@example.com | OU=Admin Accounts | Domain-Admins-Custom |

### Department Users
| Username | UPN | Department | Location | Groups |
|----------|-----|------------|----------|---------|
| john.doe | john.doe@example.com | IT | OU=IT,OU=Departments | IT-Admins, LDAP-Users, VPN-Users |
| alice.brown | alice.brown@example.com | IT | OU=IT,OU=Departments | IT-Admins, LDAP-Users, VPN-Users |
| jane.smith | jane.smith@example.com | HR | OU=HR,OU=Departments | HR-Users, LDAP-Users, VPN-Users |
| bob.wilson | bob.wilson@example.com | Finance | OU=Finance,OU=Departments | Finance-Users, LDAP-Users, VPN-Users |

### Service Accounts
| Username | UPN | Purpose | Location |
|----------|-----|---------|----------|
| svc.ldap | svc.ldap@example.com | LDAP Service | OU=Service Accounts |
| svc.backup | svc.backup@example.com | Backup Service | OU=Service Accounts |
| svc.monitoring | svc.monitoring@example.com | Monitoring Service | OU=Service Accounts |

### Legacy Test Users
| Username | UPN | Location |
|----------|-----|----------|
| test1 | test1@example.com | DC=example,DC=com |
| test2 | test2@example.com | DC=example,DC=com |

## Security Groups

- **IT-Admins**: IT department administrators
- **HR-Users**: HR department users
- **Finance-Users**: Finance department users
- **Domain-Admins-Custom**: Custom domain administrators
- **LDAP-Users**: Users allowed LDAP access
- **VPN-Users**: Users allowed VPN access

## Connection Examples

### LDAP Authentication

```python
# Python with ldap3
from ldap3 import Server, Connection, ALL

server = Server('ldap://YOUR_SERVER_IP:389', get_info=ALL)
conn = Connection(server, 'john.doe@example.com', 'P@ssw0rd1234!', auto_bind=True)
conn.search('DC=example,DC=com', '(objectclass=person)')
```

```bash
# Command line with ldapsearch
ldapsearch -H ldap://YOUR_SERVER_IP:389 \
  -D "john.doe@example.com" \
  -w "P@ssw0rd1234!" \
  -b "DC=example,DC=com" \
  "(objectclass=person)"
```

### LDAPS (LDAP over SSL)

```python
# Python with ldap3 (SSL)
from ldap3 import Server, Connection, ALL, Tls
import ssl

tls_configuration = Tls(validate=ssl.CERT_NONE)
server = Server('ldaps://YOUR_SERVER_IP:636', tls=tls_configuration, get_info=ALL)
conn = Connection(server, 'john.doe@example.com', 'P@ssw0rd1234!', auto_bind=True)
```

### Kerberos Authentication

```bash
# Configure krb5.conf
[realms]
EXAMPLE.COM = {
    kdc = YOUR_SERVER_IP:88
    admin_server = YOUR_SERVER_IP:88
}

[domain_realm]
.example.com = EXAMPLE.COM
example.com = EXAMPLE.COM

# Get Kerberos ticket
kinit john.doe@EXAMPLE.COM
```

### Windows Domain Join

```cmd
# Join Windows machine to domain
netdom join %COMPUTERNAME% /domain:example.com /userd:admin.it /passwordd:P@ssw0rd1234!
```

## Troubleshooting

### Test LDAP Connectivity
```bash
telnet YOUR_SERVER_IP 389
telnet YOUR_SERVER_IP 636
```

### Test Kerberos
```bash
telnet YOUR_SERVER_IP 88
```

### Test DNS
```bash
nslookup example.com YOUR_SERVER_IP
```

### Check Service Status (on Windows server)
```powershell
Get-Service ADWS, DNS, KDC, Netlogon
Get-ADDomain
Get-ADForest
```

## Security Considerations

1. **Firewall**: Windows Firewall is disabled for testing. In production, configure appropriate rules.
2. **SSL Certificates**: Self-signed certificates are used for LDAPS. Use proper CA certificates in production.
3. **Password Policy**: 8-character minimum, complexity enabled, 90-day expiration.
4. **Network Security**: Restrict source IPs in NSG rules for production use.

## Production Recommendations

1. Use proper SSL certificates from a trusted CA
2. Implement backup and disaster recovery procedures
3. Configure monitoring and alerting
4. Implement proper network segmentation
5. Use strong, unique passwords for all accounts
6. Regular security updates and patching
7. Implement Group Policy for security hardening

## Clean Up

```bash
terraform destroy
``` 