// Resource Group

resource "azurerm_resource_group" "myterraformgroup" {
  name     = "terraform-single-fpx"
  location = var.location

  tags = {
    environment = "Terraform Single FortiProxy"
  }
}