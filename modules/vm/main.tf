resource "azurerm_network_interface" "main" {
  name                = var.nic_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig-${var.vm_name}"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "main" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  zone                = "1"

  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    name                 = var.disk_name
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  patch_assessment_mode = "ImageDefault"
  patch_mode            = "AutomaticByOS"

  boot_diagnostics {}

  tags = var.tags
}

# Auto-Shutdown at 6:00 PM Eastern Time
resource "azurerm_dev_test_global_vm_shutdown_schedule" "main" {
  virtual_machine_id = azurerm_windows_virtual_machine.main.id
  location           = var.location
  enabled            = true

  daily_recurrence_time = "1800"
  timezone              = "Eastern Standard Time"

  notification_settings {
    enabled = false
  }

  tags = var.tags
}
