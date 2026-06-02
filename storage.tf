###############################################################################
# Logic App Storage Account — dedicated, always created with the Logic App.
# Logic App Standard requires a storage account for runtime state, triggers,
# and workflow artifacts. shared_access_key_enabled MUST be true — the
# azurerm_logic_app_standard resource authenticates via storage account key.
###############################################################################

resource "azurerm_storage_account" "logicapp" {
  name                     = local.logicapp_storage_name
  resource_group_name      = module.resource_group.name
  location                 = module.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"   # increase to ZRS/GRS for UAT/Prod
  account_kind             = "StorageV2"

  # Key auth required — Logic App Standard uses the storage account key internally.
  shared_access_key_enabled        = true
  public_network_access_enabled    = false
  https_traffic_only_enabled       = true
  min_tls_version                  = "TLS1_2"

  # AzureServices bypass lets the App Service control plane create the
  # WEBSITE_CONTENTSHARE file share on first deploy, even with public access off.
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}
