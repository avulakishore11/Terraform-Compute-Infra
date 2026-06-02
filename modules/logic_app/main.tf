resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  sku_name            = var.logic_app_sku
  tags                = var.tags
}

resource "azurerm_logic_app_standard" "main" {
  name                       = var.logic_app_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  app_service_plan_id        = azurerm_service_plan.main.id
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
    # Required: without this, the runtime throws WorkflowAppOAuthTokenFailure
    # when using a User-Assigned Managed Identity exclusively (no SystemAssigned).
    "MANAGED_IDENTITY_CLIENT_ID"           = var.uami_client_id
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    # VM automation context — reference in workflow HTTP actions with @appsetting('VM_NAME') etc.
    "AZURE_SUBSCRIPTION_ID" = var.subscription_id
    "VM_RESOURCE_GROUP"     = var.vm_resource_group
    "VM_NAME"               = var.vm_name
    "UAMI_RESOURCE_ID"      = var.uami_resource_id
    # Explicitly set the content share so the App Service control plane does not
    # attempt to create it. The share is pre-created by azurerm_storage_share in
    # storage.tf; without this the control plane creation attempt returns 403.
    # "WEBSITE_CONTENTSHARE"  = var.content_share_name  by adding this got an error like: with name WEBSITE_CONTENTSHARE already exists.","Target":null,"Details":[{"Message":"Parameter with name WEBSITE_CONTENTSHARE already exists."},{"Code":"Conflict"},{"ErrorEntity":{"ExtendedCode":"01013","MessageTemplate":"Parameter with name {0} already exists.","Parameters":["WEBSITE_CONTENTSHARE"],"Code":"Conflict","Message":"Parameter with name WEBSITE_CONTENTSHARE already exists."}}],"Innererror":null}

  }

  site_config {
    vnet_route_all_enabled = true
    min_tls_version        = "1.2"
  }

  # Azure automatically adds system app settings (AzureWebJobsStorage,
  # WEBSITE_CONTENTSHARE, etc.) after first deploy. Without this block,
  # terraform plan would show those as diffs on every subsequent run and
  # attempt to remove them, breaking the Logic App runtime.
  lifecycle {
    ignore_changes = [app_settings]
  }

  tags = var.tags
}
