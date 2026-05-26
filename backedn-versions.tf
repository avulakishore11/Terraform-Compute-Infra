terraform {
  backend "azurerm" {
    resource_group_name  = "rgeus-tftest-01"
    storage_account_name = "terrastatesa"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
    # use_azuread_auth removed — TerraformTaskV4 retrieves the storage account
    # key automatically via the ARM API using the service connection (Contributor role).
    # To re-enable Azure AD auth later, the service principal needs:
    #   Storage Blob Data Contributor on the tfstate container (data-plane role).
  }
}
