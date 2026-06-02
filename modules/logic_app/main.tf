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
    "AZURE_SUBSCRIPTION_ID"     = var.subscription_id
    "VM_RESOURCE_GROUP"                    = var.vm_resource_group
    "VM_NAME"                              = var.vm_name
    "UAMI_RESOURCE_ID"                     = var.uami_resource_id
    # Routes storage (WEBSITE_CONTENTSHARE) access through VNet so the Logic App
    # uses the private endpoint instead of the public storage endpoint.
    # Required when public_network_access_enabled = false on the storage account.
    "WEBSITE_CONTENTOVERVNET"              = "1"
  }

  site_config {
    vnet_route_all_enabled = true
    min_tls_version        = "1.2"


## IP 170.55.159.52/32 — allowed at priority 100 (dev machine IP address — adjust or remove in production)

    dynamic "ip_restriction" {
      for_each = { for i, ip in var.inbound_ip_addresses : i => ip }
      content {
        name       = "allow-ip-${ip_restriction.key}"
        ip_address = ip_restriction.value
        priority   = 100 + ip_restriction.key
        action     = "Allow"
      }
    }

##  VM subnet — allowed at priority 200 (so VMs in the environment can call workflows)

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

##  Everything else — denied (Azure's default when any allow rule exists)



  # Azure automatically manages AzureWebJobsStorage, WEBSITE_CONTENTSHARE, etc.
  # ignore_changes prevents Terraform from removing them on subsequent plans.
  
  lifecycle {
    ignore_changes = [app_settings]
  }

  tags = var.tags
}
