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

  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  vnet_name              = local.vnet_name
  vnet_address_space     = var.vnet_address_space
  subnet_logicapp_name   = local.subnet_logicapp_name
  subnet_logicapp_prefix = var.subnet_logicapp_prefix
  subnet_vm_name         = local.subnet_vm_name
  subnet_vm_prefix       = var.subnet_vm_prefix
  nsg_logicapp_name      = local.nsg_logicapp_name
  nsg_vm_name            = local.nsg_vm_name
  tags                   = local.common_tags
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

# Logic App UAMI — grants Logic App access to VM and storage (rbac.tf)
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
  log_analytics_name  = local.log_analytics_name
  app_insights_name   = local.app_insights_name
  tags                = local.common_tags
}

###############################################################################
# Virtual Machine
###############################################################################
module "vm" {
  source = "./modules/vm"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.networking.subnet_vm_id
  vm_name             = local.vm_name
  nic_name            = local.vm_nic_name
  disk_name           = local.vm_disk_name
  vm_size             = var.vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  os_disk_size        = var.vm_os_disk_size
  tags                = local.common_tags
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
  # Uses the Terraform backend storage account (terrastatesa) for Logic App runtime storage.
  # The logicapp-state container is created in storage.tf on the same account.
  storage_account_name           = data.azurerm_storage_account.backend.name
  storage_account_access_key     = data.azurerm_storage_account.backend.primary_access_key
  uami_id                        = module.identity.uami_id
  uami_client_id                 = module.identity.uami_client_id
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  # VM context — exposed as app settings so workflows can reference the target VM
  # without hardcoding. Use these in your startup/shutdown workflow actions.
  vm_name           = local.vm_name
  vm_resource_group = module.resource_group.name
  subscription_id   = var.subscription_id
  uami_resource_id  = module.identity.uami_id
  tags              = local.common_tags
}

###############################################################################
# Storage Account (conditionally deployed — Terraform-managed)
# Set deploy_storage_account = true to create; leave false when using an
# externally managed storage account (var.storage_account_name / access_key).
###############################################################################
module "storage_account" {
  count                = var.deploy_storage_account ? 1 : 0
  source               = "./modules/storage_account"
  storage_account_name = local.managed_storage_name
  location             = module.resource_group.location
  resource_group_name  = module.resource_group.name

  account_kind                     = var.storage_account_kind
  account_tier                     = var.storage_account_tier
  account_replication_type         = var.storage_account_replication_type
  access_tier                      = var.storage_access_tier
  public_network_access_enabled    = var.storage_public_network_access_enabled
  shared_access_key_enabled        = var.storage_shared_access_key_enabled
  blob_soft_delete_retention_days      = var.blob_soft_delete_retention_days
  container_soft_delete_retention_days = var.container_soft_delete_retention_days
  versioning_enabled                   = var.storage_versioning_enabled

  network_rules_ip_rules   = var.storage_ip_rules
  network_rules_subnet_ids = var.storage_subnet_ids
  network_rules_bypass     = var.storage_network_bypass

  tags = local.common_tags
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
  vm_id                = module.vm.vm_id
  lun                  = var.data_disk_lun
  tags                 = local.common_tags
}
