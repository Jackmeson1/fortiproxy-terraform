# 🏢 Case 2: Root-Child Domain + Ubuntu Client - Fully Automated

> **Enterprise multi-domain Active Directory environment with parent-child trust relationships**

[![Azure](https://img.shields.io/badge/Azure-Supported-0078D4?style=flat&logo=microsoftazure)](https://azure.microsoft.com)
[![Terraform](https://img.shields.io/badge/Terraform-≥1.0-623CE4?style=flat&logo=terraform)](https://terraform.io)
[![Forest Trust](https://img.shields.io/badge/Trust-Parent%20Child-28a745?style=flat&logo=windows)](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)

## 🎯 Purpose

This deployment creates a **multi-domain Active Directory forest** with automatic parent-child trust relationships for testing FortiProxy's advanced LDAP authentication scenarios. Perfect for validating enterprise authentication architectures with complex domain hierarchies.

## 🏗️ Architecture

### 📊 Forest Structure

```
Active Directory Forest: corp.local
├── Root Domain: corp.local (10.0.1.4)
│   ├── Enterprise Admins
│   ├── Corporate Groups (Universal)
│   ├── Forest-wide Service Accounts
│   └── Global Catalog (Port 3268)
└── Child Domain: dev.corp.local (10.0.2.4)
    ├── Development Teams
    ├── QA Groups (Domain Local)
    ├── Test Accounts
    └── Local Resources

Trust Relationship: ←→ Two-way Transitive Trust (Automatic)
Client: Ubuntu 20.04 (10.0.3.x) - Multi-domain authentication
```

### 🔄 Trust Architecture

| Component | Type | Direction | Purpose |
|-----------|------|-----------|---------|
| **Parent-Child Trust** | Transitive | Two-way | Automatic domain trust |
| **Forest Root** | corp.local | Authoritative | Enterprise-wide authentication |
| **Child Domain** | dev.corp.local | Subordinate | Development environment |
| **Global Catalog** | Root DC only | Forest-wide | Cross-domain searches |

### 🛡️ Security Model

- **Forest Admins**: Enterprise-wide privileges
- **Domain Admins**: Domain-specific privileges  
- **Universal Groups**: Available across entire forest
- **Domain Local Groups**: Specific to child domain resources
- **Global Groups**: Available forest-wide but managed per domain

## 🚀 Quick Deployment

### Prerequisites

```bash
# Required tools
terraform --version  # >= 1.0
az --version         # Azure CLI

# Azure authentication
az login
```

### 🎯 Deploy Multi-Domain Forest

```bash
# 1. Clone and navigate
git clone https://github.com/fortinet/fortiproxy-terraform.git
cd fortiproxy-terraform/azure/ad-testing/case2-ad-root-child-ubuntu

# 2. Configure deployment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials

# 3. Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### ⚙️ Required Configuration

Edit `terraform.tfvars` with your multi-domain settings:

```hcl
# Azure credentials
subscription_id = "your-subscription-id"
client_id       = "your-client-id"
client_secret   = "your-client-secret"  
tenant_id       = "your-tenant-id"

# Multi-domain configuration
root_domain_name  = "corp.local"      # Forest root
child_domain_name = "dev.corp.local"  # Child domain

# Security settings  
admin_source_ip = "your-public-ip/32"  # Restrict access!
admin_password  = "VeryComplexPassword123!"

# SSH key for Ubuntu client
client_ssh_public_key = "ssh-rsa AAAAB3NzaC1..."
```

### 🔑 Generate SSH Key

```bash
# Generate SSH key pair for client access
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ad_client_key

# Get public key for terraform.tfvars
cat ~/.ssh/ad_client_key.pub
```

## 🧪 Multi-Domain Testing Environment

### 👥 Forest Users (Root Domain: corp.local)

| Username | Password | Groups | Purpose |
|----------|----------|---------|---------|
| `enterprise.admin` | `TestPass123!` | Enterprise Admins, Domain Admins | Forest-wide administration |
| `corp.manager` | `TestPass123!` | Corporate-Admins, IT-Department | Corporate IT management |
| `network.engineer` | `TestPass123!` | Network-Engineers, IT-Department | Network infrastructure |
| `security.analyst` | `TestPass123!` | Security-Team, FortiProxy-Admins | Security operations |

### 👨‍💻 Development Users (Child Domain: dev.corp.local)

| Username | Password | Groups | Purpose |
|----------|----------|---------|---------|
| `dev.lead` | `TestPass123!` | Dev-Admins, Dev-Users | Development team leadership |
| `senior.dev` | `TestPass123!` | Dev-Users, Dev-Database-Access | Senior development |
| `junior.dev` | `TestPass123!` | Dev-Users | Junior development |
| `qa.engineer` | `TestPass123!` | QA-Team, Dev-Users | Quality assurance |

### 🏷️ Forest-Wide Groups (Universal Scope)

- **Corporate-Admins**: Corporate-wide administrators
- **IT-Department**: Corporate IT department
- **Network-Engineers**: Network engineering team
- **Security-Team**: Corporate security team
- **FortiProxy-Admins**: FortiProxy WAF administrators

### 🏷️ Child Domain Groups (Domain Local Scope)

- **Dev-Admins**: Development environment administrators
- **Dev-Users**: Development environment users
- **QA-Team**: Quality assurance team
- **FortiProxy-Dev-Users**: Development FortiProxy access

## 🔍 Multi-Domain Testing & Validation

### 🎯 Comprehensive Testing Suite

After deployment, connect to the Ubuntu client:

```bash
# SSH to Ubuntu client (IP from terraform output)
ssh -i ~/.ssh/ad_client_key ubuntu@<CLIENT-PUBLIC-IP>

# Run comprehensive multi-domain test suite
/opt/multidomain-tests/test-all-domains.sh
```

### 🎫 Cross-Domain Kerberos Testing

```bash
# Root domain authentication
kinit enterprise.admin@CORP.LOCAL
kinit corp.manager@CORP.LOCAL
kinit network.engineer@CORP.LOCAL

# Child domain authentication
kinit dev.lead@DEV.CORP.LOCAL
kinit senior.dev@DEV.CORP.LOCAL
kinit qa.engineer@DEV.CORP.LOCAL

# Verify tickets and trusts
klist          # List current tickets
klist -T       # List trusted realms
kdestroy       # Clear all tickets
```

### 📂 Multi-Domain LDAP Testing

```bash
# Root domain LDAP queries
ldapwhoami -H ldap://10.0.1.4 -D "enterprise.admin@corp.local" -W
ldapsearch -H ldap://10.0.1.4 -D "enterprise.admin@corp.local" -W \
  -b "DC=corp,DC=local" "(objectClass=user)" cn sAMAccountName

# Child domain LDAP queries
ldapwhoami -H ldap://10.0.2.4 -D "dev.lead@dev.corp.local" -W
ldapsearch -H ldap://10.0.2.4 -D "dev.lead@dev.corp.local" -W \
  -b "DC=dev,DC=corp,DC=local" "(objectClass=user)" cn sAMAccountName

# Global Catalog forest-wide searches
ldapsearch -H ldap://10.0.1.4:3268 -D "enterprise.admin@corp.local" -W \
  -b "DC=corp,DC=local" "(objectClass=user)" cn sAMAccountName
```

### 🔗 Cross-Domain Authentication Testing

```bash
# Test cross-domain access
/opt/multidomain-tests/test-cross-domain.sh

# Verify trust relationships
/opt/multidomain-tests/verify-trust.sh

# Domain-specific tests
/opt/multidomain-tests/test-root-domain.sh
/opt/multidomain-tests/test-child-domain.sh
```

## 🔗 FortiProxy Multi-Domain Integration

### 📋 Forest-Wide LDAP Configuration (Recommended)

Use **Global Catalog** for forest-wide authentication:

```
Server: 10.0.1.4 (Root DC)
Port: 3268 (Global Catalog) or 3269 (GC SSL)
Base DN: DC=corp,DC=local
Bind DN: enterprise.admin@corp.local
Bind Password: TestPass123!
Common Name Identifier: sAMAccountName
Purpose: Forest-wide user authentication
```

### 📋 Domain-Specific LDAP Configuration

For **root domain only**:
```
Server: 10.0.1.4
Port: 389 (LDAP) or 636 (LDAPS)
Base DN: DC=corp,DC=local
Bind DN: enterprise.admin@corp.local
```

For **child domain only**:
```
Server: 10.0.2.4
Port: 389 (LDAP) or 636 (LDAPS)  
Base DN: DC=dev,DC=corp,DC=local
Bind DN: dev.lead@dev.corp.local
```

### 🔍 Multi-Domain Search Filters

```bash
# All forest users (Global Catalog)
(objectClass=user)

# Root domain users only
(&(objectClass=user)(userPrincipalName=*@corp.local))

# Child domain users only
(&(objectClass=user)(userPrincipalName=*@dev.corp.local))

# Enterprise administrators
(memberOf=CN=Enterprise Admins,CN=Users,DC=corp,DC=local)

# Corporate administrators
(memberOf=CN=Corporate-Admins,OU=Corporate-Groups,DC=corp,DC=local)

# Development users
(memberOf=CN=Dev-Users,OU=Development-Groups,DC=dev,DC=corp,DC=local)

# FortiProxy administrators (forest-wide)
(memberOf=CN=FortiProxy-Admins,OU=Corporate-Groups,DC=corp,DC=local)

# FortiProxy development users
(memberOf=CN=FortiProxy-Dev-Users,OU=Development-Groups,DC=dev,DC=corp,DC=local)
```

### 🎯 Integration Scenarios

1. **Global Forest Authentication**: Use Global Catalog (port 3268) for all users
2. **Department-Specific**: Use child domain DC for development teams only  
3. **Hybrid Access**: Corporate users via root domain, dev users via child domain
4. **Cross-Domain Groups**: Universal groups accessible from both domains

## 📊 Deployment Outputs

After successful deployment:

```bash
# Get forest information
terraform output forest_info

# Get connection commands
terraform output connection_commands

# Get test credentials
terraform output test_credentials

# Get FortiProxy configuration
terraform output fortiproxy_config

# Get testing commands
terraform output test_commands
```

## 🛡️ Security Considerations

### 🔒 Forest Security Model

- **Enterprise Admins**: Ultimate forest authority
- **Domain Admins**: Per-domain administrative rights
- **Automatic Trusts**: Secure parent-child relationship
- **Global Catalog**: Controlled access to forest data
- **Cross-Domain Groups**: Universal groups for forest-wide access

### ⚠️ Security Best Practices

```bash
# 1. Restrict network access
admin_source_ip = "your-public-ip/32"

# 2. Use complex passwords  
admin_password = "VeryComplexPassword123!"

# 3. Monitor cross-domain activity
# Check logs on both domain controllers

# 4. Implement least privilege
# Use domain-specific groups where possible

# 5. Enable auditing
# Monitor enterprise admin activities
```

## 🔧 Troubleshooting Multi-Domain Issues

### 🚨 Common Multi-Domain Problems

#### Trust Relationship Issues
```bash
# Test trust on Ubuntu client
kinit enterprise.admin@CORP.LOCAL
klist -T  # Should show both realms

# Test cross-domain access
ldapsearch -H ldap://10.0.2.4 -Y GSSAPI -b "DC=dev,DC=corp,DC=local" "(objectClass=user)"
```

#### DNS Resolution Problems
```bash
# Fix multi-domain DNS
sudo systemctl restart systemd-resolved

# Test both domains  
nslookup rootdc.corp.local 10.0.1.4
nslookup childdc.dev.corp.local 10.0.2.4
```

#### Global Catalog Issues
```bash
# Test Global Catalog connectivity
telnet 10.0.1.4 3268

# Test GC search
ldapsearch -H ldap://10.0.1.4:3268 -x -b "DC=corp,DC=local" -s base "(objectclass=*)"
```

### 📝 Log Locations

| Component | Log Location | Purpose |
|-----------|--------------|---------|
| **Root Domain Setup** | `C:\root-domain-setup.log` | Forest creation log |
| **Child Domain Setup** | `C:\child-domain-setup.log` | Child domain join log |
| **Multi-Domain Client** | `/var/log/multidomain-client-setup.log` | Client configuration |
| **Testing Summary** | `C:\root-domain-summary.txt` | Root domain info |
| **Child Summary** | `C:\child-domain-summary.txt` | Child domain info |

## 💰 Cost Estimation

### 💵 Azure Costs (East US region)

| Resource | Size | Monthly Cost | Daily Cost |
|----------|------|--------------|------------|
| **Root DC** | Standard_B4ms | ~$120 | ~$4.00 |
| **Child DC** | Standard_B4ms | ~$120 | ~$4.00 |
| **Ubuntu Client** | Standard_B2s | ~$30 | ~$1.00 |
| **Networking** | Multi-subnet VNet | ~$10 | ~$0.33 |
| **Storage** | Premium SSD | ~$20 | ~$0.67 |
| **Total** | | **~$300** | **~$10.00** |

### 💡 Cost Optimization

```hcl
# Enable auto-shutdown for testing
enable_auto_shutdown = true
auto_shutdown_time = "1900"

# Use smaller sizes for short testing
vm_size = "Standard_B2ms"        # ~$60/month each
client_vm_size = "Standard_B1s"  # ~$15/month
```

## 🧹 Cleanup

```bash
# Destroy multi-domain infrastructure
terraform destroy -auto-approve

# Remove SSH keys (optional)
rm ~/.ssh/ad_client_key*
```

## 📈 Next Steps

1. **Test Case 3**: [AD Cross-Forest + Ubuntu](../case3-ad-cross-forest-ubuntu/)
2. **Deploy FortiProxy**: Use templates in `/azure/7.6/`
3. **Enterprise Integration**: Implement Azure AD Connect for hybrid scenarios
4. **Monitoring**: Set up Azure Monitor for domain controller health

## 🤝 Support

- **Documentation**: Individual README files in deployment folders
- **Issues**: [GitHub Issues](https://github.com/fortinet/fortiproxy-terraform/issues)  
- **Community**: [FortiProxy Documentation](https://docs.fortinet.com/product/fortiproxy)

---

**✅ Case 2 Status: Fully Automated Multi-Domain Forest - Parent-Child Trust Ready**

Made with ❤️ for enterprise FortiProxy authentication testing!