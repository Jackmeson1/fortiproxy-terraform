resource "azurerm_linux_virtual_machine" "custompassivefpxvm" {
  depends_on                      = [azurerm_linux_virtual_machine.customactivefpxvm]
  count                           = var.custom ? 1 : 0
  name                            = "FPX-B"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.myterraformgroup.name
  network_interface_ids           = [azurerm_network_interface.passiveport1.id, azurerm_network_interface.passiveport2.id, azurerm_network_interface.passiveport3.id, azurerm_network_interface.passiveport4.id]
  size                            = var.size
  zone                            = var.zone2
  admin_username                  = var.adminusername
  admin_password                  = var.adminpassword
  disable_password_authentication = false
  custom_data                     = base64encode(local.passiveFortiProxy)

  source_image_id = var.custom ? element(azurerm_image.custom.*.id, 0) : null

  os_disk {
    name                 = "passiveosDisk"
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

resource "azurerm_managed_disk" "custompassivedatadisk" {
  count                = var.custom ? 1 : 0
  name                 = "custompassivedatadisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "custompassivedatadisk" {
  count              = var.custom ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.custompassivedatadisk[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.custompassivefpxvm[0].id
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_linux_virtual_machine" "passivefpxvm" {
  depends_on                      = [azurerm_linux_virtual_machine.activefpxvm]
  count                           = var.custom ? 0 : 1
  name                            = var.passive_name
  location                        = var.location
  resource_group_name             = azurerm_resource_group.myterraformgroup.name
  network_interface_ids           = [azurerm_network_interface.passiveport1.id, azurerm_network_interface.passiveport2.id, azurerm_network_interface.passiveport3.id, azurerm_network_interface.passiveport4.id]
  size                            = var.size
  zone                            = var.zone2
  admin_username                  = var.adminusername
  admin_password                  = var.adminpassword
  disable_password_authentication = false
  custom_data                     = base64encode(local.passiveFortiProxy)

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
    name                 = "passiveosDisk2"
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

resource "azurerm_managed_disk" "passivedatadisk" {
  count                = var.custom ? 0 : 1
  name                 = "passivedatadisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30
  zone                 = var.zone2

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "passivedatadisk" {
  count              = var.custom ? 0 : 1
  managed_disk_id    = azurerm_managed_disk.passivedatadisk[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.passivefpxvm[0].id
  lun                = "0"
  caching            = "ReadWrite"
}

locals {
  passiveFortiProxy = templatefile(var.bootstrap-passive, {
    type            = var.license_type
    license_file    = var.license2
    port1_ip        = var.passiveport1
    port1_mask      = var.passiveport1mask
    port2_ip        = var.passiveport2
    port2_mask      = var.passiveport2mask
    port3_ip        = var.passiveport3
    port3_mask      = var.passiveport3mask
    port4_ip        = var.passiveport4
    port4_mask      = var.passiveport4mask
    active_peerip   = var.activeport4
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
