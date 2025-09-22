resource "azurerm_network_interface" "this" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    public_ip_address_id          = var.public_ip_id
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.network_security_group_id
}

resource "tls_private_key" "this" {
  count     = var.authentication_type == "SSH" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.authentication_type == "Password" ? var.admin_password : null
  disable_password_authentication = var.authentication_type == "SSH"

  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  dynamic "admin_ssh_key" {
    for_each = var.authentication_type == "SSH" ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key != null ? var.ssh_public_key : tls_private_key.this[0].public_key_openssh
    }
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  os_disk {
    storage_account_type = var.os_disk.storage_account_type
    caching              = var.os_disk.caching
    disk_size_gb         = var.os_disk.disk_size_gb
  }

  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  tags = var.tags
}