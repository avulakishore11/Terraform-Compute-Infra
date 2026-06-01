terraform {
  # MERGED: upgraded from >= 1.3.0 (root) to >= 1.5.0 (terraform-automation requirement).
  # >= 1.5.0 is required for azurerm ~> 4.0 and azuread provider.
  required_version = ">= 1.5.0"

  required_providers {
    # DUPLICATE NOTE: terraform-automation/providers.tf also declared azurerm ~> 4.0.
    # Merged here. Old version was ~> 3.0 — verify all resources are compatible with 4.x
    # before removing terraform-automation/providers.tf.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # NEW from terraform-automation — required for RBAC/AAD identity lookups.
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    # NEW from terraform-automation — used if random resource names are needed.
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# DUPLICATE NOTE: terraform-automation/providers.tf also declared provider "azurerm".
# Merged here. Key difference: terraform-automation passed subscription_id explicitly
# and set prevent_deletion_if_contains_resources = false.
provider "azurerm" {
  features {
    resource_group {
      # Allows terraform destroy to succeed even when the RG still contains resources.
      prevent_deletion_if_contains_resources = false
    }
  }
}

# NEW from terraform-automation
provider "azuread" {}
provider "random" {}
