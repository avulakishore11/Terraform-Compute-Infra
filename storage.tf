###############################################################################
# Backend Storage Account — referenced, not created by Terraform.
# Name and resource group match the backend block in backedn-versions.tf.
# Used by Logic App Standard as its runtime storage, and hosts the
# logicapp-state container for workflow state.
###############################################################################

data "azurerm_storage_account" "backend" {
  name                = "terrastatesa"
  resource_group_name = "rgeus-tftest-01"
}

# Dedicated container for Logic App workflow state.
# The Terraform state files use the "tfstate" container (in backedn-versions.tf).
# This keeps Logic App state separate on the same storage account.
resource "azurerm_storage_container" "logicapp_state" {
  name               = "logicapp-state"
  storage_account_id = data.azurerm_storage_account.backend.id
}
