# 🔐 Windows Server 2019 Active Directory + Ubuntu Client Testing Environment

> **Complete infrastructure for testing FortiProxy LDAP/Kerberos authentication in Azure**

[![Azure](https://img.shields.io/badge/Azure-Supported-0078D4?style=flat&logo=microsoftazure)](https://azure.microsoft.com)
[![Windows Server 2019](https://img.shields.io/badge/Windows%20Server-2019-0078D4?style=flat&logo=windows)](https://www.microsoft.com/en-us/windows-server)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20LTS-E95420?style=flat&logo=ubuntu)](https://ubuntu.com)
[![Active Directory](https://img.shields.io/badge/Active%20Directory-Domain%20Services-0078D4?style=flat&logo=windows)](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)

## 🎯 Purpose

This deployment creates a **complete Active Directory testing environment** specifically designed for validating FortiProxy authentication integration. Perfect for enterprises implementing **LDAP**, **LDAPS**, and **Kerberos** authentication with FortiProxy Web Application Firewall.

## 🏗️ Architecture Overview

### 📋 Infrastructure Components

| Component | Specification | Purpose |
|-----------|---------------|---------|
| **Windows Server 2019** | Domain Controller | Active Directory Domain Services, DNS, Kerberos KDC |
| **Ubuntu 20.04 Client** | Authentication Test Client | Kerberos ticket testing, LDAP queries, SSH access |
| **Azure Virtual Network** | 10.0.0.0/16 | Isolated network with proper AD communication |
| **Network Security Groups** | Restrictive rules | Secure AD communication within VNet only |

### 🌐 Network Design

```
Azure VNet (10.0.0.0/16)
├── AD Subnet (10.0.1.0/24)
│   └── Windows DC (10.0.1.4) - Fixed IP
└── Client Subnet (10.0.2.0/24)
    └── Ubuntu Client (10.0.2.x) - Dynamic IP
```

### 🔒 Security Configuration

- **VNet Isolation**: All AD services restricted to 10.0.0.0/16
- **NSG Rules**: Explicit allow for LDAP (389), LDAPS (636), Kerberos (88), DNS (53)
- **RDP/SSH**: Admin access only (configurable source IP)
- **Windows Firewall**: Configured with proper AD service rules

## 🚀 Quick Deployment Guide

### Prerequisites

1. **Azure Subscription** with sufficient permissions
2. **Terraform** ≥ 1.0 installed
3. **Azure CLI** configured (`az login`)
4. **SSH Key Pair** for Ubuntu client access

### 📦 Deployment Steps

```bash
# 1. Clone and navigate to directory
git clone https://github.com/fortinet/fortiproxy-terraform.git
cd fortiproxy-terraform/azure/win2019-ad

# 2. Configure deployment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Azure credentials

# 3. Generate SSH key for client access
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ad_client_key

# 4. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 5. Access the environment
# Windows DC: RDP to the provided public IP
# Ubuntu Client: SSH using the generated key
```

### ⚙️ Required Configuration

```hcl
# terraform.tfvars
subscription_id = "your-azure-subscription-id"
client_id       = "your-service-principal-id"
client_secret   = "your-service-principal-secret"
tenant_id       = "your-azure-tenant-id"

# Deployment settings
location            = "eastus"
resource_group_name = "ADTestRG"
domain_name         = "example.com"

# Security settings
admin_source_ip = "your-public-ip/32"  # Restrict access to your IP

# SSH key (paste your public key)
client_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDExample..."
```

## 🧪 Authentication Testing Suite

### 🎯 Pre-Configured Test Environment

The deployment automatically creates:

#### 👥 Test Users
| Username | Password | Groups | Purpose |
|----------|----------|---------|---------|
| `john.doe` | `TestPass123!` | Domain Admins, IT-Admins | Administrative testing |
| `alice.brown` | `TestPass123!` | Linux-Admins, SSH-Users | Network engineer testing |
| `linux.admin` | `TestPass123!` | Linux-Admins, SSH-Users | Linux system admin testing |
| `linux.user1` | `TestPass123!` | SSH-Users | Regular user testing |

#### 🧪 Manual Testing Commands

**Kerberos Authentication:**
```bash
# Connect to Ubuntu client
ssh -i ~/.ssh/ad_client_key ubuntu@<CLIENT-PUBLIC-IP>

# Get Kerberos ticket
kinit john.doe@EXAMPLE.COM
# Password: TestPass123!

# Verify ticket
klist

# Test with different users
kinit linux.admin@EXAMPLE.COM
kdestroy  # Clear tickets
```

**LDAP Authentication:**
```bash
# Test LDAP bind
ldapwhoami -H ldap://10.0.1.4 -D "john.doe@example.com" -W

# Search for users
ldapsearch -H ldap://10.0.1.4 -D "john.doe@example.com" -W \
  -b "DC=example,DC=com" "(objectClass=user)" cn sAMAccountName

# Test LDAPS (secure LDAP)
ldapsearch -H ldaps://10.0.1.4:636 -D "john.doe@example.com" -W \
  -b "DC=example,DC=com" "(sAMAccountName=linux.admin)"
```

## 🔍 FortiProxy Integration Testing

### 🎯 LDAP Server Configuration

Use these settings in FortiProxy for LDAP authentication:

```
LDAP Server Configuration:
- Server: 10.0.1.4 (or windc2019.example.com)
- Port: 389 (LDAP) or 636 (LDAPS)
- Common Name Identifier: sAMAccountName
- Distinguished Name: DC=example,DC=com
- Bind Type: Regular
- Username: john.doe@example.com
- Password: TestPass123!

Search Filter Examples:
- All users: (objectClass=user)
- Specific group: (memberOf=CN=Linux-Admins,CN=Users,DC=example,DC=com)
- Active users: (&(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
```

### 🔐 Kerberos Configuration

```
Kerberos Configuration:
- Realm: EXAMPLE.COM
- KDC: windc2019.example.com
- Admin Server: windc2019.example.com
- Principal Format: username@EXAMPLE.COM
```

## 📊 Troubleshooting

### 🔍 Common Issues & Solutions

#### DNS Resolution Problems
```bash
# Fix DNS on Ubuntu client
echo "10.0.1.4 windc2019.example.com windc2019" | sudo tee -a /etc/hosts
```

#### Time Synchronization Issues
```bash
# Sync time on Ubuntu client
sudo timedatectl set-timezone UTC
sudo systemctl restart systemd-timesyncd
```

#### Kerberos Debug Mode
```bash
# Enable Kerberos debugging
export KRB5_TRACE=/dev/stdout
kinit john.doe@EXAMPLE.COM
```

## 🔧 Deployment Variables

### 🔧 Core Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `subscription_id` | Azure subscription ID | - | ✅ |
| `client_id` | Service principal ID | - | ✅ |
| `client_secret` | Service principal secret | - | ✅ |
| `tenant_id` | Azure tenant ID | - | ✅ |
| `location` | Azure region | `eastus` | ⚠️ |
| `domain_name` | AD domain name | `example.com` | ⚠️ |

### 🛡️ Security Variables

| Variable | Description | Default | Security Impact |
|----------|-------------|---------|-----------------|
| `admin_source_ip` | Source IP for RDP/SSH | `*` | 🚨 High - Restrict in production |
| `admin_password` | Windows admin password | `P@ssw0rd1234!` | 🚨 High - Change immediately |
| `client_ssh_public_key` | SSH public key for Ubuntu | - | ✅ Required |

## 🤝 Integration with FortiProxy

### 🎯 Step-by-Step Integration

1. **Deploy this environment**
2. **Deploy FortiProxy** (using other templates in this repo)
3. **Configure FortiProxy LDAP** with this AD server
4. **Test authentication flow** using the Ubuntu client
5. **Validate security policies** and access controls

### 📋 Integration Checklist

- [ ] AD environment deployed and functional
- [ ] FortiProxy deployed and accessible
- [ ] Network connectivity between FortiProxy and AD
- [ ] LDAP configuration completed in FortiProxy
- [ ] Test users can authenticate through FortiProxy
- [ ] Group-based access control working
- [ ] Logging and monitoring configured

## 📞 Support & Resources

### 🔗 Connection Information
After deployment, use `terraform output` to get:
- Windows DC public IP (RDP access)
- Ubuntu client public IP (SSH access)
- Connection instructions and test credentials

### ⚡ Quick Test Commands
```bash
# SSH to client
ssh -i ~/.ssh/ad_client_key ubuntu@<CLIENT-IP>

# Test Kerberos
kinit john.doe@EXAMPLE.COM

# Test LDAP
ldapwhoami -H ldap://10.0.1.4 -D "john.doe@example.com" -W
```

### 🧹 Cleanup
```bash
terraform destroy -auto-approve
```

**Made with ❤️ for the FortiProxy community** - Perfect for authentication testing and enterprise integration validation!