# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Terraform scripts for deploying FortiProxy-VM instances across AWS and Azure cloud providers. The configurations support various deployment patterns including high-availability (HA) active-passive clusters and Active Directory authentication server setups.

## Commands

### Terraform Operations
- `terraform init` - Initialize providers and modules (run in specific deployment directory)
- `terraform plan` - Review planned changes before deployment
- `terraform apply` - Deploy infrastructure 
- `terraform destroy` - Remove deployed infrastructure

### Setup Process
1. Navigate to desired deployment directory (e.g., `azure/7.2/ha-ap-port1-mgmt-crosszone/`)
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and customize variables
3. Run standard Terraform workflow: init → plan → apply

## Architecture

### Directory Structure
- `aws/` - AWS deployment configurations
  - Version-specific subdirectories (7.0/, etc.)
  - Deployment pattern subdirectories (ha-active-passive/, etc.)
- `azure/` - Azure deployment configurations  
  - Version-specific subdirectories (7.0/, 7.2/)
  - Deployment pattern subdirectories and utilities (win2019-ad/)

### Configuration Files
Each deployment contains these standard Terraform files:
- `main.tf` - Primary resource definitions
- `variables.tf` - Input variable declarations
- `provider.tf` - Cloud provider configuration
- `network.tf` - Network infrastructure (VPC/VNet, subnets)
- `output.tf` - Output values after deployment
- `terraform.tfvars.example` - Example variable values
- Configuration files for FortiProxy instances (`config-active.conf`, `config-passive.conf`)

### FortiProxy HA Deployments
- Deploy active-passive clusters across availability zones
- Use 4-NIC configurations: management/HA-mgmt (port1), public/untrust (port2), private/trust (port3), HA-sync (port4)
- Support cross-zone deployments for high availability
- Require VM sizes supporting 4+ NICs (e.g., Standard_F4 on Azure)

### Active Directory Component
The `azure/win2019-ad/` deployment creates a comprehensive Windows Server 2019 AD environment:
- Domain Controller with LDAP/LDAPS/Kerberos services
- Pre-configured organizational units and security groups
- Test users and service accounts for authentication testing
- Used for testing FortiProxy LDAP/AD authentication features

## Important Notes
- Each deployment directory is self-contained with its own variable definitions
- Always customize `terraform.tfvars` before deployment - contains cloud credentials and instance sizing
- FortiProxy configurations include HA sync settings and port assignments
- AD deployment includes comprehensive authentication services setup for testing scenarios