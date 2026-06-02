# tflint terraform_required_version + terraform_required_providers: every module
# must declare its own terraform block so it can be linted, validated, and reused
# independently of the root module.
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0" # The root provider.tf decides the exact provider version range (~> 3.0), while modules only declare the minimum version they need (>= 3.0).
    }
  }
}

resource "azurerm_windows_virtual_machine" "virtual_machine" {
  name                  = var.vm_name
  computer_name         = trim(substr(var.vm_name, 0, 15), "-") # Windows: max 15 chars, no trailing hyphen
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [var.nic_id]

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.uami_id]
  }

  boot_diagnostics {}

  tags = var.tags
}
