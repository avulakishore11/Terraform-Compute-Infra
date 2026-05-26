# tflint terraform_required_version + terraform_required_providers: every module
# must declare its own terraform block so it can be linted, validated, and reused
# independently of the root module.
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0" # The root provider.tf decides the exact provider version range (~> 3.0), 
                              #while modules only declare the minimum version they need (>= 3.0).
    }
  }
}

resource "azurerm_managed_disk" "this" {
  name                 = var.disk_name
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_type = var.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  managed_disk_id    = azurerm_managed_disk.this.id
  virtual_machine_id = var.vm_id
  lun                = var.lun
  caching            = "ReadOnly"
}
