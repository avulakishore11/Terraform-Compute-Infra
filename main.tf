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
  storage_account_id             = module.storage_account.id
  storage_account_name           = local.storage_account_name
  tags                           = local.common_tags

  depends_on = [module.storage_account]
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
  content_share_name             = azurerm_storage_share.logicapp.name
  uami_id                        = module.identity.uami_id
  uami_client_id                 = module.identity.uami_client_id
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  vm_name           = local.vm_name
  vm_resource_group = module.resource_group.name
  subscription_id   = var.subscription_id
  uami_resource_id  = module.identity.uami_id
  tags              = local.common_tags
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
  network_rules_subnet_ids = var.storage_subnet_ids
  network_rules_bypass     = var.storage_network_bypass

  tags = local.common_tags
}

# Pre-create the file share so the App Service control plane finds it already
# exists during Logic App deployment and skips its own creation attempt (which causes 403).
resource "azurerm_storage_share" "logicapp" {
  name               = "logic-app-content"
  storage_account_id = module.storage_account.id
  quota              = 5120
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
