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

resource "azurerm_linux_virtual_machine" "customactivefpxvm" {
  count                        = var.custom ? 1 : 0
  name                         = "FPX-A"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.myterraformgroup.name
  network_interface_ids        = [azurerm_network_interface.activeport1.id, azurerm_network_interface.activeport2.id, azurerm_network_interface.activeport3.id, azurerm_network_interface.activeport4.id]
  size                         = var.size
  zone                         = var.zone1
  admin_username               = var.adminusername
  admin_password               = var.adminpassword
  disable_password_authentication = false
  custom_data                     = base64encode(local.activeFortiProxy)

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

resource "azurerm_managed_disk" "customactivedatadisk" {
  count                = var.custom ? 1 : 0
  name                 = "customactivedatadisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "customactivedatadisk" {
  count              = var.custom ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.customactivedatadisk[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.customactivefpxvm[0].id
  lun                = "0"
  caching            = "ReadWrite"
}



resource "azurerm_linux_virtual_machine" "activefpxvm" {
  count                        = var.custom ? 0 : 1
  name                         = var.active_name
  location                     = var.location
  resource_group_name          = azurerm_resource_group.myterraformgroup.name
  network_interface_ids        = [azurerm_network_interface.activeport1.id, azurerm_network_interface.activeport2.id, azurerm_network_interface.activeport3.id, azurerm_network_interface.activeport4.id]
  size                         = var.size
  zone                         = var.zone1
  admin_username               = var.adminusername
  admin_password               = var.adminpassword
  disable_password_authentication = false
  custom_data                     = base64encode(local.activeFortiProxy)

  source_image_reference {
    publisher = var.publisher
    offer     = var.fpxoffer
    sku       = var.license_type == "byol" ? var.fpxsku["byol"] : var.fpxsku["payg"]
    version   = var.fpxversion
  }

  plan {
    name      = var.license_type == "byol" ? var.fpxsku["byol"] : var.fpxsku["payg"]
    publisher = var.publisher
    product   = var.fpxoffer
  }

  os_disk {
    name                 = "activeosDisk"
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

resource "azurerm_managed_disk" "activedatadisk" {
  count                = var.custom ? 0 : 1
  name                 = "activedatadisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30
  zone                 = var.zone1

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "activedatadisk" {
  count              = var.custom ? 0 : 1
  managed_disk_id    = azurerm_managed_disk.activedatadisk[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.activefpxvm[0].id
  lun                = "0"
  caching            = "ReadWrite"
}

locals {
  activeFortiProxy = templatefile(var.bootstrap-active, {
    type            = var.license_type
    license_file    = var.license
    port1_ip        = var.activeport1
    port1_mask      = var.activeport1mask
    port2_ip        = var.activeport2
    port2_mask      = var.activeport2mask
    port3_ip        = var.activeport3
    port3_mask      = var.activeport3mask
    port4_ip        = var.activeport4
    port4_mask      = var.activeport4mask
    passive_peerip  = var.passiveport4
    mgmt_gateway_ip = var.port1gateway
    defaultgwy      = var.port2gateway
    tenant          = var.tenant_id
    subscription    = var.subscription_id
    clientid        = var.client_id
    clientsecret    = var.client_secret
    adminsport      = var.adminsport
    rsg             = azurerm_resource_group.myterraformgroup.name
    clusterip       = azurerm_public_ip.ClusterPublicIP.name
    routename       = azurerm_route_table.internal.name
  })
}
