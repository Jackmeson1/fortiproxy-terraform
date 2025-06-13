// Resource Group

resource "azurerm_resource_group" "myterraformgroup" {
  # name     = "Terraformdemo"
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = "Terraform Demo"
  }
}
