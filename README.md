# 🚀 FortiProxy Terraform Deployment Scripts

[![Terraform](https://img.shields.io/badge/Terraform-≥1.0-623CE4?style=flat&logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Supported-0078D4?style=flat&logo=microsoftazure)](https://azure.microsoft.com)
[![AWS](https://img.shields.io/badge/AWS-Supported-FF9900?style=flat&logo=amazonaws)](https://aws.amazon.com)
[![FortiProxy](https://img.shields.io/badge/FortiProxy-7.2%20|%207.4%20|%207.6-EE0000?style=flat&logo=fortinet)](https://www.fortinet.com/products/web-application-firewall/fortiproxy)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue?style=flat)](LICENSE)

> **Enterprise-grade Infrastructure as Code (IaC) templates for automated FortiProxy Web Application Firewall deployment across AWS and Azure cloud platforms**

## 🌟 Overview

Deploy **Fortinet FortiProxy** - the industry-leading **Web Application Firewall (WAF)** and **SSL VPN** solution - instantly across cloud environments using **Terraform Infrastructure as Code**. This repository provides production-ready, enterprise-tested deployment templates for both **single-instance** and **high-availability** configurations.

### 🎯 Why Choose This Repository?

- ✅ **Multi-Cloud Support**: Deploy on Azure and AWS with identical configurations
- ✅ **Version Flexibility**: Support for FortiProxy 7.2, 7.4, and 7.6
- ✅ **Deployment Options**: Single-instance and HA active-passive clusters
- ✅ **Production-Ready**: Enterprise-tested templates with security best practices
- ✅ **Infrastructure as Code**: Version-controlled, repeatable deployments
- ✅ **Zero-Downtime HA**: Cross-zone high availability configurations
- ✅ **Easy Customization**: Modular design with comprehensive variable support

## 🏗️ Architecture Support

### 🔧 Deployment Types

| Deployment Type | Description | Use Case | Availability Zones |
|---|---|---|---|
| **Single Instance** | Standalone FortiProxy deployment | Development, Testing, POC | Single Zone |
| **HA Active-Passive** | High-availability cluster | Production, Critical workloads | Cross-Zone |
| **HA with Management** | HA cluster with dedicated mgmt | Enterprise, Compliance | Cross-Zone |

### ☁️ Cloud Platform Support

#### Microsoft Azure
- **Regions**: All Azure regions with availability zone support
- **VM Sizes**: Standard_F4, Standard_B4ms, and larger
- **Networking**: VNet with multiple subnets, NSGs, Load Balancers
- **Storage**: Managed disks with diagnostics

#### Amazon Web Services (AWS)
- **Regions**: All AWS regions with Multi-AZ support
- **Instance Types**: M5, C5, and T3 families
- **Networking**: VPC with public/private subnets, Security Groups
- **Storage**: EBS volumes with CloudWatch integration

## 🚀 Quick Start Guide

### Prerequisites

1. **Terraform** ≥ 1.0 installed ([Download](https://terraform.io/downloads))
2. **Cloud CLI** configured:
   - Azure: `az login` ([Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
   - AWS: `aws configure` ([AWS CLI](https://aws.amazon.com/cli/))
3. **FortiProxy BYOL License** (for production deployments)

### 📦 Repository Structure

```
fortiproxy-terraform/
├── azure/
│   ├── 7.2/
│   │   ├── single/                    # Single instance deployment
│   │   └── ha-ap-port1-mgmt-crosszone/ # HA cluster deployment
│   ├── 7.4/
│   │   ├── single/                    # Single instance deployment
│   │   └── ha-ap-port1-mgmt-crosszone/ # HA cluster deployment
│   ├── 7.6/
│   │   ├── single/                    # Single instance deployment
│   │   └── ha-ap-port1-mgmt-crosszone/ # HA cluster deployment
│   └── win2019-ad/                    # Active Directory for testing
├── aws/
│   └── 7.0/
│       └── ha-active-passive/         # AWS HA deployment
└── CLAUDE.md                          # AI-assisted development guide
```

### 🎯 Deploy Your First FortiProxy

#### Azure Single Instance (Recommended for beginners)

```bash
# 1. Clone the repository
git clone https://github.com/fortinet/fortiproxy-terraform.git
cd fortiproxy-terraform/azure/7.6/single

# 2. Configure your deployment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Azure credentials and preferences

# 3. Deploy with Terraform
terraform init
terraform plan
terraform apply

# 4. Access your FortiProxy
# URL, username, and password will be displayed after deployment
```

#### Azure High Availability Cluster

```bash
# Navigate to HA deployment
cd fortiproxy-terraform/azure/7.6/ha-ap-port1-mgmt-crosszone

# Configure and deploy
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
terraform init
terraform plan
terraform apply
```

## 🔧 Configuration Options

### Essential Variables

| Variable | Description | Example | Required |
|---|---|---|---|
| `subscription_id` | Azure Subscription ID | `12345678-1234-...` | ✅ |
| `client_id` | Azure Service Principal ID | `87654321-4321-...` | ✅ |
| `location` | Azure region | `eastus2`, `westeurope` | ✅ |
| `fpxversion` | FortiProxy version | `7.6.0`, `7.4.4` | ✅ |
| `license` | License file path | `./license.lic` | ✅ |
| `size` | VM size | `Standard_F4s_v2` | ⚠️ |

### Advanced Customization

```hcl
# terraform.tfvars example
subscription_id = "your-subscription-id"
client_id       = "your-client-id"
client_secret   = "your-client-secret"
tenant_id       = "your-tenant-id"

# Deployment customization
location = "eastus2"
size     = "Standard_F4s_v2"
fpxversion = "7.6.0"

# Network configuration
vnetcidr    = "172.16.0.0/16"
publiccidr  = "172.16.0.0/24"
privatecidr = "172.16.1.0/24"

# License files
license  = "./license-active.lic"
license2 = "./license-passive.lic"
```

## 📚 Deployment Scenarios

### 🏢 Enterprise Production

**Scenario**: High-traffic web application protection
**Recommended**: Azure 7.6 HA Active-Passive
```bash
cd azure/7.6/ha-ap-port1-mgmt-crosszone
# Configure for Standard_F8s_v2 or larger
# Enable all security features
```

### 🧪 Development & Testing

**Scenario**: Application development and testing
**Recommended**: Azure 7.6 Single Instance
```bash
cd azure/7.6/single
# Configure for Standard_B4ms (cost-effective)
# Simplified configuration
```

### 🔒 Compliance & Security

**Scenario**: Regulated industries, PCI-DSS compliance
**Recommended**: Azure 7.6 HA with Active Directory
```bash
cd azure/7.6/ha-ap-port1-mgmt-crosszone
cd ../win2019-ad  # Deploy AD for authentication
# Configure LDAP/RADIUS integration
```

## 🛡️ Security Best Practices

### 🔐 Network Security
- **Default Deny**: All NSGs/Security Groups use explicit allow rules
- **Segmentation**: Separate management and data plane networks
- **Encryption**: All traffic encrypted in transit and at rest
- **Monitoring**: Built-in logging and diagnostics

### 🚨 Operational Security
- **Secrets Management**: Use Azure Key Vault or AWS Secrets Manager
- **Access Control**: Implement RBAC with least privilege
- **Monitoring**: Enable Azure Monitor or CloudWatch integration
- **Backup**: Automated configuration backups

## 🔍 Troubleshooting

### Common Issues & Solutions

#### ❌ VM Size Not Available
```
Error: SkuNotAvailable: Standard_F4 not available in westus2
```
**Solution**: Use different VM size or region:
```hcl
size = "Standard_B4ms"
location = "eastus2"
```

#### ❌ License File Not Found
```
Error: no file exists at "license.txt"
```
**Solution**: Create placeholder or provide valid license:
```bash
echo "# Placeholder license" > license.txt
```

#### ❌ Network Interface Reserved
```
Error: NicReservedForAnotherVm
```
**Solution**: Wait 3 minutes and retry `terraform destroy`

### 📞 Getting Help

1. **Documentation**: Check individual README files in deployment folders
2. **Community**: [FortiProxy Documentation](https://docs.fortinet.com/product/fortiproxy)
3. **Issues**: [GitHub Issues](https://github.com/fortinet/fortiproxy-terraform/issues)
4. **Commercial Support**: Contact [Fortinet Support](https://support.fortinet.com)

## 🧪 Testing & Validation

### Automated Testing
```bash
# Validate Terraform configuration
terraform validate

# Check security compliance
tfsec .

# Test deployment (dry-run)
terraform plan -out=plan.tfplan
```

### Manual Validation
- ✅ Web GUI accessible via HTTPS
- ✅ SSH access to management interface
- ✅ HA synchronization (for cluster deployments)
- ✅ Log forwarding to SIEM systems

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **🐛 Report Bugs**: Use GitHub Issues for bug reports
2. **💡 Feature Requests**: Suggest new deployment scenarios
3. **📝 Documentation**: Improve README files and examples
4. **🔧 Code**: Submit pull requests for enhancements

### Development Workflow
```bash
# Fork and clone the repository
git clone https://github.com/yourusername/fortiproxy-terraform.git

# Create feature branch
git checkout -b feature/new-deployment-type

# Make changes and test
terraform validate
terraform plan

# Submit pull request
git push origin feature/new-deployment-type
```

## 📈 Roadmap

### Upcoming Features
- 🎯 **FortiProxy 7.8** support
- 🎯 **Google Cloud Platform** deployments
- 🎯 **Kubernetes** integration
- 🎯 **Ansible** automation playbooks
- 🎯 **CI/CD pipeline** templates

### Version History
- **v3.0** (Current): FortiProxy 7.6 support, single deployments
- **v2.0**: FortiProxy 7.4 support, enhanced HA
- **v1.0**: Initial release with FortiProxy 7.2

## 📄 License & Support

### 📜 License
This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

### 🏢 Support Policy
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.

- **Community Support**: [GitHub Issues](https://github.com/fortinet/fortiproxy-terraform/issues)
- **Documentation**: [Fortinet Documentation Library](https://docs.fortinet.com)
- **Commercial Support**: [FortiCare Support](https://support.fortinet.com)
- **Contact**: [github@fortinet.com](mailto:github@fortinet.com)

---

<div align="center">

### 🌟 **Star this repository if it helped you!** 🌟

[![GitHub stars](https://img.shields.io/github/stars/fortinet/fortiproxy-terraform?style=social)](https://github.com/fortinet/fortiproxy-terraform/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/fortinet/fortiproxy-terraform?style=social)](https://github.com/fortinet/fortiproxy-terraform/network)

**Made with ❤️ by the Fortinet Community**

[🔗 **Fortinet.com**](https://fortinet.com) | [📚 **Documentation**](https://docs.fortinet.com) | [💬 **Community**](https://community.fortinet.com)

</div>