resource "azurerm_service_plan" "logicappservice_plan" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  sku_name            = var.logic_app_sku
  tags                = var.tags
}

resource "azurerm_logic_app_standard" "logic_app" {
  name                       = var.logic_app_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  app_service_plan_id        = azurerm_service_plan.logicappservice_plan.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  https_only                 = true
  version                    = "~4"

  virtual_network_subnet_id = var.subnet_logicapp_id

  identity {
    type         = "UserAssigned"
    identity_ids = [var.uami_id]
  }

  app_settings = {
    "MANAGED_IDENTITY_CLIENT_ID" = var.uami_client_id
    "AZURE_SUBSCRIPTION_ID"      = var.subscription_id
    "VM_RESOURCE_GROUP"          = var.vm_resource_group
    "VM_NAME"                    = var.vm_name
    "UAMI_RESOURCE_ID"           = var.uami_resource_id
    # Pre-created file share — prevents Azure from attempting to create it from
    # Microsoft-internal IPs, which fails against network-restricted storage.
    "WEBSITE_CONTENTSHARE"       = var.content_share_namett5
    # Routes file share access through the VNet private endpoint.
    "WEBSITE_CONTENTOVERVNET"    = "1"
  }

  site_config {
    vnet_route_all_enabled = true
    min_tls_version        = "1.2"

    # Allow specific IPs (e.g. dev workstation) to call Logic App triggers
    dynamic "ip_restriction" {
      for_each = { for i, ip in var.inbound_ip_addresses : i => ip }
      content {
        name       = "allow-ip-${ip_restriction.key}"
        ip_address = ip_restriction.value
        priority   = 100 + ip_restriction.key
        action     = "Allow"
      }
    }

    # Allow VNet subnets (e.g. VM subnet) to call Logic App triggers
    dynamic "ip_restriction" {
      for_each = { for i, id in var.inbound_subnet_ids : i => id }
      content {
        name                      = "allow-subnet-${ip_restriction.key}"
        virtual_network_subnet_id = ip_restriction.value
        priority                  = 200 + ip_restriction.key
        action                    = "Allow"
      }
    }
  }

  # Azure automatically injects AzureWebJobsStorage, FUNCTIONS_EXTENSION_VERSION, etc.
  # after first deploy. ignore_changes ensures subsequent plans do not remove those
  # platform-managed settings. WEBSITE_CONTENTSHARE is set explicitly above on creation
  # and will not be changed by Azure after that.
  lifecycle {
    ignore_changes = [app_settings]
  }

  tags = var.tags
}
