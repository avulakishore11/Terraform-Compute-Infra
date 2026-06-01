###############################################################################
# Role Assignments — NEW from terraform-automation
# Cross-module assignments kept at root level (pattern from terraform-automation/rbac.tf)
###############################################################################

# Allows Logic App (via UAMI) to start/deallocate the automation VM
resource "azurerm_role_assignment" "uami_vm_contributor" {
  scope                = module.vm.vm_id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = module.identity.uami_principal_id
  description          = "Allows UAMI to start and deallocate the automation VM via Logic App workflows"
}

# Allows Logic App (via UAMI) to read/write workflow state in the external storage account.
# Only created when storage_account_id is provided.
resource "azurerm_role_assignment" "uami_storage_blob" {
  count = var.storage_account_id != null ? 1 : 0

  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.identity.uami_principal_id
  description          = "Allows UAMI to read and write Logic App workflow state in blob storage"
}
