data "azurerm_client_config" "current" {}

###############################################################################
# Resource Group
###############################################################################
module "resource_group" {
  source   = "./modules/resource_group"
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

###############################################################################
# Networking
###############################################################################
module "networking" {
  source = "./modules/networking"

  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  environment                    = var.environment
  vnet_name                      = local.vnet_name
  vnet_address_space             = var.vnet_address_space
  subnet_logicapp_name           = local.subnet_logicapp_name
  subnet_logicapp_prefix         = var.subnet_logicapp_prefix
  subnet_vm_name                 = local.subnet_vm_name
  subnet_vm_prefix               = var.subnet_vm_prefix
  subnet_private_endpoint_prefix = var.subnet_private_endpoint_prefix
  nsg_logicapp_name              = local.nsg_logicapp_name
  nsg_vm_name                    = local.nsg_vm_name
  tags                           = local.common_tags
}

###############################################################################
# Storage Private Endpoint — lives at root to avoid a cycle between
# module.networking (needs storage ID) and module.storage_account (needs
# subnet ID from networking). Root level depends on both with no cycle.
###############################################################################
resource "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = module.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file" {
  name                  = "link-${local.vnet_name}"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = module.networking.vnet_id
  tags                  = local.common_tags
}

resource "azurerm_private_endpoint" "storage_account" {
  name                = "pe-${local.storage_account_name}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.networking.subnet_private_endpoint_id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-${local.storage_account_name}"
    is_manual_connection           = false
    private_connection_resource_id = module.storage_account.id
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "pdzg-${local.storage_account_name}"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_file.id]
  }
}

###############################################################################
# Identity
###############################################################################

# Policy remediation identity — used by Azure Update Manager policies (policies.tf)
module "policy_remediation_identity" {
  source              = "./modules/managed_identity"
  name                = local.policy_identity_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags
}

# Environment UAMI — single managed identity for the environment; grants access to VM and storage
module "identity" {
  source = "./modules/identity"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  uami_name           = local.uami_name
  tags                = local.common_tags
}

###############################################################################
# Monitoring
###############################################################################
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  log_analytics_name = local.log_analytics_name
  tags               = local.common_tags
}

###############################################################################
# Virtual Machine
###############################################################################
module "network_interface" {
  source = "./modules/network_interface"

  nic_name            = local.vm_nic_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.networking.subnet_vm_id
  tags                = local.common_tags
}

module "virtual_machine" {
  source = "./modules/virtual_machine"

  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  vm_name                      = local.vm_name
  vm_size                      = var.vm_size
  admin_username               = var.vm_admin_username
  admin_password               = var.vm_admin_password
  nic_id                       = module.network_interface.id
  os_disk_caching              = var.os_disk_caching
  os_disk_storage_account_type = var.os_disk_storage_account_type
  os_disk_size_gb              = var.vm_os_disk_size
  image_publisher              = var.image_publisher
  image_offer                  = var.image_offer
  image_sku                    = var.image_sku
  image_version                = var.image_version
  tags                         = local.common_tags
}

###############################################################################
# Logic App
###############################################################################
module "logic_app" {
  source = "./modules/logic_app"

  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  app_service_plan_name          = local.app_service_plan_name
  logic_app_name                 = local.logic_app_name
  logic_app_sku                  = var.logic_app_sku
  subnet_logicapp_id             = module.networking.subnet_logicapp_id
  storage_account_name           = module.storage_account.name
  storage_account_access_key     = module.storage_account.primary_access_key
  content_share_name = azurerm_storage_share.logicapp.name
  uami_id            = module.identity.uami_id
  uami_client_id     = module.identity.uami_client_id
  vm_name            = local.vm_name
  vm_resource_group = module.resource_group.name
  subscription_id   = var.subscription_id
  uami_resource_id  = module.identity.uami_id
  tags              = local.common_tags

  inbound_ip_addresses = var.logic_app_inbound_ip_addresses
  inbound_subnet_ids   = [module.networking.subnet_vm_id]

  # Wait for private endpoint + DNS zone to be ready before creating the Logic App.
  depends_on = [module.networking, azurerm_storage_share.logicapp,
                azurerm_private_dns_zone_virtual_network_link.storage_file]
}

###############################################################################
# Storage Account — single account used by Logic App runtime and app data.
# Always deployed. Key auth and public access are hardcoded because Logic App
# Standard requires both: the App Service control plane creates the file share
# from Microsoft-internal IPs and authenticates with the storage account key.
###############################################################################
module "storage_account" {
  source               = "./modules/storage_account"
  storage_account_name = local.storage_account_name
  location             = module.resource_group.location
  resource_group_name  = module.resource_group.name

  account_kind             = var.storage_account_kind
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  access_tier              = var.storage_access_tier

  public_network_access_enabled = true  # required: App Service control plane creates file share from Microsoft IPs
  shared_access_key_enabled     = true  # required: Logic App authenticates via storage account key

  blob_soft_delete_retention_days      = var.blob_soft_delete_retention_days
  container_soft_delete_retention_days = var.container_soft_delete_retention_days
  versioning_enabled                   = var.storage_versioning_enabled

  network_rules_ip_rules   = var.storage_ip_rules
  network_rules_subnet_ids = concat(var.storage_subnet_ids, [module.networking.subnet_logicapp_id])

  tags = local.common_tags
}

# Pre-create the file share so the App Service control plane finds it already
# exists during Logic App deployment and skips its own creation attempt (which causes 403).
resource "azurerm_storage_share" "logicapp" {
  name               = "logic-app-content"
  storage_account_id = module.storage_account.id
  quota              = 5120
  access_tier        = "Cool"
}

###############################################################################
# Monitoring — Diagnostic Settings and Azure Monitor Agent
###############################################################################

# Logic App → Log Analytics + storage archival
resource "azurerm_monitor_diagnostic_setting" "logic_app" {
  name                       = "diag-${local.logic_app_name}"
  target_resource_id         = module.logic_app.logic_app_id
  log_analytics_workspace_id = module.monitoring.workspace_id
  storage_account_id         = module.storage_account.id

  enabled_log { category = "AppServiceHTTPLogs" }
  enabled_log { category = "AppServiceConsoleLogs" }
  enabled_log { category = "AppServiceAppLogs" }
  enabled_log { category = "AppServicePlatformLogs" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# VM → Azure Monitor Agent extension (enables Log Analytics telemetry from the VM)
resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = module.virtual_machine.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  automatic_upgrade_enabled  = true
  tags                       = local.common_tags
}

# Link Log Analytics workspace to the storage account for custom log archival
resource "azurerm_log_analytics_linked_storage_account" "logs" {
  data_source_type      = "CustomLogs"
  resource_group_name   = module.resource_group.name
  workspace_resource_id = module.monitoring.workspace_id
  storage_account_ids   = [module.storage_account.id]
}

###############################################################################
# Resource Lock — prevents accidental deletion of the resource group
###############################################################################
resource "azurerm_management_lock" "resource_group" {
  count      = var.enable_resource_lock ? 1 : 0
  name       = "lock-${local.resource_group_name}"
  scope      = module.resource_group.id
  lock_level = "CanNotDelete"
  notes      = "Locked to prevent accidental deletion. Remove this lock before running terraform destroy."
}

###############################################################################
# VM Log Analytics — Data Collection Rule + Association
# The Azure Monitor Agent extension (installed in the monitoring section) needs
# a DCR to define what to collect and where to send it.
###############################################################################
resource "azurerm_monitor_data_collection_rule" "vm" {
  name                = "dcr-${local.vm_name}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = local.common_tags

  destinations {
    log_analytics {
      workspace_resource_id = module.monitoring.workspace_id
      name                  = "law-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Event", "Microsoft-Perf"]
    destinations = ["law-destination"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available Bytes",
        "\\LogicalDisk(_Total)\\% Free Space",
        "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",
        "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",
      ]
      name = "perf-counters"
    }

    windows_event_log {
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "System!*[System[(Level=1 or Level=2)]]",
      ]
      name = "windows-event-logs"
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "vm" {
  name                    = "dcra-${local.vm_name}"
  target_resource_id      = module.virtual_machine.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm.id
}

###############################################################################
# Recovery Services Vault + Backup Policy + Protected VM
###############################################################################
resource "azurerm_recovery_services_vault" "main" {
  name                = local.recovery_vault_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = "Standard"
  storage_mode_type   = var.recovery_vault_redundancy
  soft_delete_enabled = true
  tags                = local.common_tags
}

resource "azurerm_backup_policy_vm" "main" {
  name                = var.backup_policy_name
  resource_group_name = module.resource_group.name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  policy_type         = var.backup_policy_type
  timezone            = "UTC"

  backup {
    frequency = var.backup_frequency
    time      = var.backup_time
    weekdays  = var.backup_frequency == "Weekly" ? var.backup_weekdays : null
  }

  # Only applicable for V2 (Enhanced) policy
  instant_restore_retention_days = var.backup_policy_type == "V2" ? var.backup_instant_restore_days : null

  # Daily retention — used when backup_frequency = Daily (prod)
  dynamic "retention_daily" {
    for_each = var.backup_frequency == "Daily" ? [1] : []
    content {
      count = var.backup_retention_days
    }
  }

  # Weekly retention — used when backup_frequency = Weekly (dev/uat)
  dynamic "retention_weekly" {
    for_each = var.backup_frequency == "Weekly" ? [1] : []
    content {
      count    = var.backup_retention_weeks
      weekdays = var.backup_weekdays
    }
  }
}

resource "azurerm_backup_protected_vm" "main" {
  resource_group_name = module.resource_group.name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  source_vm_id        = module.virtual_machine.id
  backup_policy_id    = azurerm_backup_policy_vm.main.id
}

###############################################################################
# Managed Data Disk
###############################################################################
module "managed_disk" {
  source               = "./modules/managed_disk"
  disk_name            = local.managed_disk_name
  location             = module.resource_group.location
  resource_group_name  = module.resource_group.name
  storage_account_type = var.data_disk_storage_account_type
  disk_size_gb         = var.data_disk_size_gb
  vm_id                = module.virtual_machine.id
  lun                  = var.data_disk_lun
  tags                 = local.common_tags
}
