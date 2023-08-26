resource "azurerm_virtual_machine" "custompassivefpxvm" {
  depends_on                   = [azurerm_virtual_machine.customactivefpxvm]
  count                        = var.custom ? 1 : 0
  name                         = "FPX-B"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.myterraformgroup.name
  network_interface_ids        = [azurerm_network_interface.passiveport1.id, azurerm_network_interface.passiveport2.id, azurerm_network_interface.passiveport3.id, azurerm_network_interface.passiveport4.id]
  primary_network_interface_id = azurerm_network_interface.passiveport1.id
  vm_size                      = var.size
  zones                        = [var.zone2]

  storage_image_reference {
    id = var.custom ? element(azurerm_image.custom.*.id, 0) : null
  }

  storage_os_disk {
    name              = "passiveosDisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  # Log data disks
  storage_data_disk {
    name              = "passivedatadisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = "custompassivefpx"
    admin_username = var.adminusername
    admin_password = var.adminpassword
    custom_data    = data.template_file.passiveFortiProxy.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.fpxstorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Demo"
  }
}


resource "azurerm_virtual_machine" "passivefpxvm" {
  depends_on                   = [azurerm_virtual_machine.activefpxvm]
  count                        = var.custom ? 0 : 1
  name                         = var.passive_name
  location                     = var.location
  resource_group_name          = azurerm_resource_group.myterraformgroup.name
  network_interface_ids        = [azurerm_network_interface.passiveport1.id, azurerm_network_interface.passiveport2.id, azurerm_network_interface.passiveport3.id, azurerm_network_interface.passiveport4.id]
  primary_network_interface_id = azurerm_network_interface.passiveport1.id
  vm_size                      = var.size
  zones                        = [var.zone2]

  storage_image_reference {
    publisher = var.custom ? null : var.publisher
    offer     = var.custom ? null : var.fpxoffer
    sku       = var.license_type == "byol" ? var.fpxsku["byol"] : var.fpxsku["payg"]
    version   = var.custom ? null : var.fpxversion
    id        = var.custom ? element(azurerm_image.custom.*.id, 0) : null
  }

  plan {
    name      = var.license_type == "byol" ? var.fpxsku["byol"] : var.fpxsku["payg"]
    publisher = var.publisher
    product   = var.fpxoffer
  }

  storage_os_disk {
    name              = "passiveosDisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  # Log data disks
  storage_data_disk {
    name              = "passivedatadisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = "passivefpx"
    admin_username = var.adminusername
    admin_password = var.adminpassword
    custom_data    = data.template_file.passiveFortiProxy.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.fpxstorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Demo"
  }
}

data "template_file" "passiveFortiProxy" {
  template = file(var.bootstrap-passive)

  vars = {
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
  }
}
