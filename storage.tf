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
  shared_access_key_enabled     = true
  # Public access must remain open for this dedicated Logic App storage account.
  # The App Service control plane creates WEBSITE_CONTENTSHARE from Microsoft's
  # internal IPs at deploy time. Network restrictions (even with AzureServices bypass
  # or subnet allowlists) block this and cause a 403. Since this account is exclusively
  # used for Logic App runtime state/triggers (not application data), public access
  # is acceptable — access is still gated by the storage account key.
  public_network_access_enabled = true
  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"

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
