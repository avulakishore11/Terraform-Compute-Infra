###############################################################################
# Role Assignments — cross-module, kept at root level
###############################################################################

# Allows Logic App (via UAMI) to start/deallocate the automation VM
resource "azurerm_role_assignment" "uami_vm_contributor" {
  scope                = module.virtual_machine.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = module.identity.uami_principal_id
  description          = "Allows UAMI to start and deallocate the automation VM via Logic App workflows"
}

# Allows Logic App (via UAMI) to read/write its dedicated storage account.
# Storage account is Terraform-managed (storage.tf) so no conditional needed.
resource "azurerm_role_assignment" "uami_storage_blob" {
  scope                = module.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.identity.uami_principal_id
  description          = "Allows UAMI to read and write Logic App workflow state in blob storage"
}
