###############################################################################
# Role Assignments — cross-module, kept at root level
# All assignments use the single environment UAMI (uami-{project}-{env}-{seq}).
###############################################################################

# Grants the environment UAMI permission to start/deallocate the automation VM
resource "azurerm_role_assignment" "uami_vm_contributor" {
  scope                = module.virtual_machine.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = module.identity.uami_principal_id
  description          = "Allows environment UAMI to start and deallocate the automation VM via Logic App workflows"
}

# Grants the environment UAMI read/write access to blob storage
resource "azurerm_role_assignment" "uami_storage_blob" {
  scope                = module.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.identity.uami_principal_id
  description          = "Allows environment UAMI to read and write workflow state in blob storage"
}
