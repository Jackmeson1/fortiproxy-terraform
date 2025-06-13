resource "azurerm_image" "custom" {
  count               = var.custom ? 1 : 0
  name                = var.custom_image_name
  resource_group_name = var.custom_image_resource_group_name
  location            = var.location
  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.customuri
    size_gb  = 2
  }
}

resource "azurerm_linux_virtual_machine" "customfpxvm" {
  count                        = var.custom ? 1 : 0
  name                         = "fpxvm"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.myterraformgroup.name
  network_interface_ids        = [azurerm_network_interface.fpxport1.id, azurerm_network_interface.fpxport2.id]
  size                         = var.size
  zone                         = "1"
  admin_username               = var.adminusername
  admin_password               = var.adminpassword
  disable_password_authentication = false
  custom_data                     = base64encode(templatefile("${var.bootstrap-fpxvm}", {
    type         = var.license_type
    license_file = var.license
  }))

  source_image_id = var.custom ? element(azurerm_image.custom.*.id, 0) : null

  os_disk {
    name                 = "osDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  additional_capabilities {
    ultra_ssd_enabled = false
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.fpxstorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_managed_disk" "customfpxdatadisk" {
  count                = var.custom ? 1 : 0
  name                 = "customfpxvmdatadisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "customfpxdatadisk" {
  count              = var.custom ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.customfpxdatadisk[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.customfpxvm[0].id
  lun                = "0"
  caching            = "ReadWrite"
}


resource "azurerm_linux_virtual_machine" "fpxvm" {
  zone                         = "1"
  count                        = var.custom ? 0 : 1
  name                         = "fpxvm"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.myterraformgroup.name
  network_interface_ids        = [azurerm_network_interface.fpxport1.id, azurerm_network_interface.fpxport2.id]
  size                         = var.size
  admin_username               = var.adminusername
  admin_password               = var.adminpassword
  disable_password_authentication = false
  custom_data                     = base64encode(templatefile("${var.bootstrap-fpxvm}", {
    type         = var.license_type
    license_file = var.license
  }))

  source_image_reference {
    publisher = var.publisher
    offer     = var.fpxoffer
    sku       = var.fpxsku[var.license_type]
    version   = var.fpxversion
  }

  plan {
    name      = var.fpxsku[var.license_type]
    publisher = var.publisher
    product   = var.fpxoffer
  }

  os_disk {
    name                 = "osDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  additional_capabilities {
    ultra_ssd_enabled = false
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.fpxstorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_managed_disk" "fpxdatadisk" {
  count                = var.custom ? 0 : 1
  name                 = "fpxvmdatadisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30
  zone                 = "1"

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "fpxdatadisk" {
  count              = var.custom ? 0 : 1
  managed_disk_id    = azurerm_managed_disk.fpxdatadisk[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.fpxvm[0].id
  lun                = "0"
  caching            = "ReadWrite"
}