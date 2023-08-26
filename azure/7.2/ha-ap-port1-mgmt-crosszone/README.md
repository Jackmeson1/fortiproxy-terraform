# Deployment of a FortiProxy-VM (BYOL) Cluster on the Azure in different zones
## Introduction
## This topology is only recommended for using with FPX 7.0.12/7.2.6 and later.
## port1 - hamgmt
## port2 - public/untrust
## port3 - private/trust
## port4 - hasync
A Terraform script to deploy a FortiProxy-VM Cluster on Azure

## Requirements
* [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) >= 1.0
* Terraform Provider AzureRM >= 2.24.0
* Terraform Provider Template >= 2.2.0
* Terraform Provider Random >= 3.1.0


## Deployment overview
Terraform deploys the following components:
   - Azure Virtual Network with 4 subnets
   - Two FortiProxy-VM (BYOL) instances with four NICs.  Each FortiProxy-VM reside in different zones.
   - Two firewall rules.

## Deployment
To deploy the FortiProxy-VM to Azure:
1. Clone the repository.
2. Customize variables in the `terraform.tfvars.example` and `variables.tf` file as needed.  And rename `terraform.tfvars.example` to `terraform.tfvars`.
3. Initialize the providers and modules:
   ```sh
   $ cd XXXXX
   $ terraform init
    ```
4. Submit the Terraform plan:
   ```sh
   $ terraform plan
   ```
5. Verify output.
6. Confirm and apply the plan:
   ```sh
   $ terraform apply
   ```
7. If output is satisfactory, type `yes`.

Output will include the information necessary to log in to the FortiProxy-VM instances:
```sh
Outputs:

ActiveMGMTPublicIP = <Active FPX Management Public IP>
ClusterPublicIP = <Cluster Public IP>
PassiveMGMTPublicIP = <Passive FPX Management Public IP>
Password = <FPX Password>
ResourceGroup = <Resource Group>
Username = <FPX admin>
```

## Destroy the instance
To destroy the instance, use the command:
```sh
$ terraform destroy
```

# Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/fortinet/fortiproxy-terraform-deploy/issues) tab of this GitHub project.
For other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

## License
[License](https://github.com/fortinet/fortiproxy-terraform-deploy/blob/master/LICENSE) © Fortinet Technologies. All rights reserved.

