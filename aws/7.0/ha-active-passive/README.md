# Deployment of FortiProxy-VM (BYOL) Cluster on the AWS
## Introduction
A Terraform script to deploy a FortiProxy-VM Cluster on AWS for Cross-AZ deployment

## Requirements
* [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) >= 1.0
* Terraform Provider AWS 5.7.0
* Terraform Provider Template 2.2.0


## Deployment overview
Terraform deploys the following components:
   - A AWS VPC with 8 subnets:  4 subnets in one AZ, 4 subnets in a second AZ.
   - Two FortiProxy-VM instances with four NICs.
   - Two Network Security Group rules: one for external, one for internal.
   - Two Route tables: one for internal subnet and one for external subnet.

![ha-architecture](./aws-topology-ha-ap-2az.png?raw=true "HA Architecture")

## Deployment
To deploy the FortiProxy-VM to AWS:
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

FPXActiveMGMTPublicIP = <Active FPX Management Public IP>
FPXClusterPublicFQDN = <Cluster Public FQDN>
FPXClusterPublicIP = <Cluster Public IP>
FPXPassiveMGMTPublicIP = <Passive FPX Management Public IP>
Password = <FPX Password>
Username = <FPX admin>

```

## Destroy the instance
To destroy the instance, use the command:
```sh
$ terraform destroy
```

# Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/fortinet/fortiproxy-terraform/issues) tab of this GitHub project.
For other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

## License
[License](https://github.com/fortinet/fortiproxy-terraform/blob/master/LICENSE) © Fortinet Technologies. All rights reserved.
