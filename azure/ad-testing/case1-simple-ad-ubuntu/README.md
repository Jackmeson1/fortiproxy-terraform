# 🔐 Case 1: Simple AD + Ubuntu Client - Fully Automated

> **Complete Active Directory testing environment with zero manual intervention**

[![Azure](https://img.shields.io/badge/Azure-Supported-0078D4?style=flat&logo=microsoftazure)](https://azure.microsoft.com)
[![Terraform](https://img.shields.io/badge/Terraform-≥1.0-623CE4?style=flat&logo=terraform)](https://terraform.io)
[![Automation](https://img.shields.io/badge/Automation-100%25-00C851?style=flat&logo=ansible)](https://github.com/ansible/ansible)

## 🎯 Purpose

This deployment creates a **simple Active Directory environment** with complete automation for testing FortiProxy LDAP/Kerberos authentication. Perfect for validating basic authentication scenarios without complex domain structures.

## 🏗️ Architecture

### 📊 Infrastructure Overview

```
Azure Resource Group: case1-simple-ad-rg
├── Virtual Network (10.0.0.0/16)
│   ├── AD Subnet (10.0.1.0/24)
│   │   └── Windows Server 2019 DC (10.0.1.4)
│   │       ├── Active Directory Domain Services
│   │       ├── DNS Server
│   │       ├── LDAP/LDAPS (389/636)
│   │       ├── Kerberos KDC (88)
│   │       └── Global Catalog (3268/3269)
│   └── Client Subnet (10.0.2.0/24)
│       └── Ubuntu 20.04 Client (Dynamic IP)
│           ├── Kerberos client tools
│           ├── LDAP utilities
│           ├── Automated test scripts
│           └── SSH access
└── Network Security Groups
    ├── AD NSG (LDAP, Kerberos, DNS, RDP)
    └── Client NSG (SSH access)
```

### 🔄 Automation Features

| Component | Automation Level | Description |
|-----------|------------------|-------------|
| **Windows DC Setup** | 100% Automated | PowerShell DSC with scheduled tasks |
| **AD Domain Services** | 100% Automated | Domain installation, user creation, group setup |
| **Ubuntu Client** | 100% Automated | Cloud-init with Kerberos/LDAP configuration |
| **DNS Configuration** | 100% Automated | Automatic domain resolution setup |
| **Security Groups** | 100% Automated | Pre-configured AD security groups |
| **Test Users** | 100% Automated | Domain users with proper group membership |
| **Testing Scripts** | 100% Automated | Complete testing suite deployment |

## 🚀 Quick Deployment

### Prerequisites

```bash
# Required tools
terraform --version  # >= 1.0
az --version         # Azure CLI

# Azure authentication
az login
```

### 🎯 Deploy in 3 Steps

```bash
# 1. Clone and navigate
git clone https://github.com/fortinet/fortiproxy-terraform.git
cd fortiproxy-terraform/azure/ad-testing/case1-simple-ad-ubuntu

# 2. Configure deployment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials

# 3. Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### ⚙️ Required Configuration

Edit `terraform.tfvars` with your settings:

```hcl
# Azure credentials
subscription_id = "your-subscription-id"
client_id       = "your-client-id"
client_secret   = "your-client-secret"
tenant_id       = "your-tenant-id"

# Security settings
admin_source_ip = "your-public-ip/32"  # Restrict access!
admin_password  = "ComplexPassword123!"

# SSH key (generate first)
client_ssh_public_key = "ssh-rsa AAAAB3NzaC1..."
```

### 🔑 Generate SSH Key

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ad_client_key

# Get public key for terraform.tfvars
cat ~/.ssh/ad_client_key.pub
```

## 🧪 Testing Environment

### 👥 Pre-Created Test Users

| Username | Password | Groups | Purpose |
|----------|----------|---------|---------|
| `john.doe` | `TestPass123!` | Domain Admins, IT-Admins, Linux-Admins | Full administrative access |
| `alice.brown` | `TestPass123!` | Linux-Admins, SSH-Users | Network engineer testing |
| `linux.admin` | `TestPass123!` | Linux-Admins, SSH-Users | Linux system administration |
| `linux.user1` | `TestPass123!` | SSH-Users | Regular user access |

### 🏷️ Security Groups

- **IT-Admins**: IT Department Administrators
- **Linux-Admins**: Linux System Administrators  
- **SSH-Users**: Users allowed SSH access
- **FortiProxy-Users**: Users allowed FortiProxy access

### 🔧 Service Accounts

- **svc.ldap@simple.local**: LDAP binding service account
- **svc.krb@simple.local**: Kerberos service account

## 🔍 Testing & Validation

### 🎯 Automated Testing Suite

After deployment, connect to the Ubuntu client and run:

```bash
# SSH to Ubuntu client (IP from terraform output)
ssh -i ~/.ssh/ad_client_key ubuntu@<CLIENT-PUBLIC-IP>

# Run comprehensive test suite
/opt/ad-tests/test-all.sh
```

### 🎫 Kerberos Authentication Tests

```bash
# Get Kerberos ticket
kinit john.doe@SIMPLE.LOCAL
# Password: TestPass123!

# Verify ticket
klist

# Test different users
kinit alice.brown@SIMPLE.LOCAL
kinit linux.admin@SIMPLE.LOCAL

# Destroy tickets
kdestroy
```

### 📂 LDAP Authentication Tests

```bash
# Test LDAP bind
ldapwhoami -H ldap://10.0.1.4 -D "john.doe@simple.local" -W

# Search for users
ldapsearch -H ldap://10.0.1.4 -D "john.doe@simple.local" -W \
  -b "DC=simple,DC=local" "(objectClass=user)" cn sAMAccountName

# Test LDAPS (secure)
ldapsearch -H ldaps://10.0.1.4:636 -D "john.doe@simple.local" -W \
  -b "DC=simple,DC=local" "(sAMAccountName=linux.admin)"

# Test group membership
ldapsearch -H ldap://10.0.1.4 -D "john.doe@simple.local" -W \
  -b "DC=simple,DC=local" "(memberOf=CN=Linux-Admins,OU=Security-Groups,DC=simple,DC=local)"
```

## 🔗 FortiProxy Integration

### 📋 LDAP Server Configuration

Use these settings in FortiProxy:

```
Server: 10.0.1.4
Port: 389 (LDAP) or 636 (LDAPS)
Base DN: DC=simple,DC=local
Bind DN: john.doe@simple.local
Bind Password: TestPass123!
Common Name Identifier: sAMAccountName
```

### 🔍 Search Filters

```bash
# All users
(objectClass=user)

# Active users only
(&(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))

# IT Admins group
(memberOf=CN=IT-Admins,OU=Security-Groups,DC=simple,DC=local)

# Linux Admins group  
(memberOf=CN=Linux-Admins,OU=Security-Groups,DC=simple,DC=local)

# FortiProxy Users group
(memberOf=CN=FortiProxy-Users,OU=Security-Groups,DC=simple,DC=local)
```

### 🎯 Integration Workflow

1. **Deploy this environment**
2. **Wait 10 minutes** for full AD setup completion
3. **Test authentication** using provided scripts
4. **Deploy FortiProxy** using other templates
5. **Configure LDAP** with the settings above
6. **Validate integration** end-to-end

## 📊 Deployment Outputs

After successful deployment, Terraform provides:

```bash
# Get connection information
terraform output connection_commands

# Get test credentials
terraform output test_credentials

# Get FortiProxy configuration
terraform output fortiproxy_config

# Get network configuration  
terraform output network_config
```

## 🛡️ Security Considerations

### 🔒 Network Security

- All AD services restricted to VNet (10.0.0.0/16) only
- RDP access limited to configured source IP
- SSH access limited to configured source IP
- Windows Firewall rules for AD services
- NSG rules for LDAP, LDAPS, Kerberos, DNS

### ⚠️ Security Best Practices

```bash
# 1. Restrict admin access to your IP
admin_source_ip = "your-public-ip/32"

# 2. Use strong passwords
admin_password = "VeryComplexPassword123!"

# 3. Monitor access logs
# Check /var/log/auth.log on Ubuntu client
# Check Windows Event Logs on Domain Controller

# 4. Enable auto-shutdown for cost control
enable_auto_shutdown = true
auto_shutdown_time = "1900"
```

## 🔧 Troubleshooting

### 🚨 Common Issues

#### DNS Resolution Problems
```bash
# Fix DNS on Ubuntu client
sudo systemctl restart systemd-resolved
nslookup windc.simple.local 10.0.1.4
```

#### Time Synchronization Issues
```bash
# Sync time on Ubuntu client
sudo ntpdate -s 10.0.1.4
sudo systemctl restart ntp
```

#### Kerberos Ticket Issues
```bash
# Enable debug mode
export KRB5_TRACE=/dev/stdout
kinit john.doe@SIMPLE.LOCAL

# Check time difference
date  # Should match DC time
```

#### LDAP Connection Issues
```bash
# Test port connectivity
telnet 10.0.1.4 389
telnet 10.0.1.4 636

# Check LDAP server status
ldapsearch -x -h 10.0.1.4 -b "" -s base "(objectclass=*)"
```

### 📝 Log Locations

| Component | Log Location | Purpose |
|-----------|--------------|---------|
| **Ubuntu Setup** | `/var/log/ad-client-setup.log` | Client configuration log |
| **Windows AD Setup** | `C:\ad-setup.log` | AD installation log |
| **Post-reboot Setup** | `C:\ad-setup-postreboot.log` | Domain controller configuration |
| **Testing Summary** | `C:\ad-testing-summary.txt` | AD environment summary |

## 💰 Cost Estimation

### 💵 Azure Costs (East US region)

| Resource | Size | Monthly Cost | Daily Cost |
|----------|------|--------------|------------|
| **Windows DC** | Standard_B2ms | ~$60 | ~$2.00 |
| **Ubuntu Client** | Standard_B2s | ~$30 | ~$1.00 |
| **Networking** | VNet + NSGs | ~$5 | ~$0.17 |
| **Storage** | Premium SSD | ~$10 | ~$0.33 |
| **Total** | | **~$105** | **~$3.50** |

### 💡 Cost Optimization

```hcl
# Enable auto-shutdown
enable_auto_shutdown = true
auto_shutdown_time = "1900"  # 7 PM

# Use smaller VM sizes for testing
vm_size = "Standard_B1ms"        # DC: ~$30/month
client_vm_size = "Standard_B1s"  # Client: ~$15/month
```

## 🧹 Cleanup

```bash
# Destroy infrastructure
terraform destroy -auto-approve

# Remove SSH keys (optional)
rm ~/.ssh/ad_client_key*
```

## 📈 Next Steps

1. **Test Case 2**: [AD Root-Child + Ubuntu](../case2-ad-root-child-ubuntu/)
2. **Test Case 3**: [AD Cross-Forest + Ubuntu](../case3-ad-cross-forest-ubuntu/)
3. **Deploy FortiProxy**: Use templates in `/azure/7.6/`
4. **Production Setup**: Implement Azure AD Connect for hybrid scenarios

## 🤝 Support

- **Documentation**: See individual README files in deployment folders
- **Issues**: [GitHub Issues](https://github.com/fortinet/fortiproxy-terraform/issues)
- **Community**: [FortiProxy Documentation](https://docs.fortinet.com/product/fortiproxy)

---

**✅ Case 1 Status: Fully Automated - Zero Manual Intervention Required**

Made with ❤️ for the FortiProxy community - Perfect for simple AD authentication testing!