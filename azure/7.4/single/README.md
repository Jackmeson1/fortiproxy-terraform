# Deployment of a FortiProxy-VM (BYOL) on Azure

## Introduction

A Terraform script to deploy a FortiProxy-VM (BYOL) on Azure

## Requirements

* [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) >= 1.0
* Terraform Provider AzureRM >= 3.0
* Terraform Provider Template >= 2.2.0
* Terraform Provider Random >= 3.1.0

## Deployment overview

Terraform deploys the following components:

* Azure Virtual Network with 2 subnets
* One FortiProxy-VM instance with 2 NICs
* Two firewall rules: one for external, one for internal.

## Deployment

To deploy the FortiProxy-VM to Azure:

1. Clone the repository.
2. Customize variables in the `terraform.tfvars.example` and `variables.tf` file as needed. And rename `terraform.tfvars.example` to `terraform.tfvars`.
3. Initialize the providers and modules:

   ```sh
   cd XXXXX
   terraform init
    ```

4. Submit the Terraform plan:

   ```sh
   terraform plan
   ```

5. Verify output.
6. Confirm and apply the plan:

   ```sh
   terraform apply
   ```

7. If output is satisfactory, type `yes`.

Output will include the information necessary to log in to the FortiProxy-VM instance:

```sh
FPXPublicIP = <FPX Public IP>
Password = <FPX Password>
ResourceGroup = <Resource Group>
Username = <FPX Username>
```

## Destroy the instance

To destroy the instance, use the command:

```sh
terraform destroy
```

## Requirements and limitations

FortiProxy-VM primarily uses BYOL licensing. Ensure you have appropriate licenses before deployment.

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/fortinet/fortiproxy-terraform/issues) tab of this GitHub project.
For other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

## License

[License](https://github.com/fortinet/fortiproxy-terraform/blob/master/LICENSE) © Fortinet Technologies. All rights reserved.