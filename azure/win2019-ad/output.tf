output "public_ip" {
  value = azurerm_public_ip.ip.ip_address
}

output "username" {
  value = var.admin_username
}

output "password" {
  value = var.admin_password
  sensitive = true
}
