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

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
   resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
