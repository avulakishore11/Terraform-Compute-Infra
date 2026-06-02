resource "azurerm_storage_account" "storage_account" {
  name                             = var.storage_account_name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  account_kind                     = var.account_kind
  account_tier                     = var.account_tier
  account_replication_type         = var.account_replication_type
  access_tier                      = var.access_tier
  min_tls_version                  = var.min_tls_version
  https_traffic_only_enabled       = var.https_traffic_only_enabled
  public_network_access_enabled    = var.public_network_access_enabled
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled
  shared_access_key_enabled        = var.shared_access_key_enabled

  # Always Deny by default regardless of whether ip_rules/subnet_ids are populated.
  # Without this guard, passing empty lists would silently open the storage account to all traffic.
  network_rules {
    default_action             = "Deny"
    ip_rules                   = var.network_rules_ip_rules
    virtual_network_subnet_ids = var.network_rules_subnet_ids
    bypass                     = ["AzureServices"]
  }

  blob_properties {
    versioning_enabled = var.versioning_enabled

    delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }
  }

  tags = var.tags
}


