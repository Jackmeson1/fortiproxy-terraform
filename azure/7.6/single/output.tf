output "ResourceGroup" {
  value = azurerm_resource_group.myterraformgroup.name
}

output "FPXPublicIP" {
  value = format("https://%s", azurerm_public_ip.FPXPublicIp.ip_address)
}

output "Username" {
  value = var.adminusername
}

output "Password" {
  value = var.adminpassword
}