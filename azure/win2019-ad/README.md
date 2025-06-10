# Deploy Windows Server 2019 Domain Controller on Azure

This example Terraform configuration deploys a Windows Server 2019 VM and
initializes it as an Active Directory Domain Controller. Two test users
`test1` and `test2` are created automatically.

## Requirements

- [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
  1.0 or later
- AzureRM provider 2.24.0 or later

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and update the
   variable values as needed.
2. Initialize Terraform:

   ```sh
   terraform init
   ```
3. Review the plan and apply:

   ```sh
   terraform apply
   ```
4. After testing, destroy the environment:

   ```sh
   terraform destroy
   ```

## Outputs

After a successful deployment the public IP address of the domain controller and
the administrator credentials are displayed.
