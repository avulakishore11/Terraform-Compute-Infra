locals {
  location_abbr = {
    "eastus"             = "eus"
    "eastus2"            = "eus2"
    "westus"             = "wus"
    "westus2"            = "wus2"
    "centralus"          = "cus"
    "northcentralus"     = "ncus"
    "southcentralus"     = "scus"
    "northeurope"        = "neu"
    "westeurope"         = "weu"
    "uksouth"            = "uks"
    "ukwest"             = "ukw"
    "australiaeast"      = "aue"
    "australiasoutheast" = "ause"
    "southeastasia"      = "sea"
    "eastasia"           = "ea"
  }                           # the below naming convention is referenced in dev.tfvars
  # suffix = {location_abbr}-{project}{environment}-{instance}

  # fmt fix: blank line above had 2 trailing spaces; terraform fmt -check fails on trailing whitespace.
  # full name = {resource_type}{suffix}  e.g. vmeus-winvmdev-01
  suffix = "${local.location_abbr[var.location]}-${var.project}${var.environment}-${var.instance}"
}

module "resource_group" {
  source   = "./modules/resource_group"
  name     = "rg${local.suffix}"
  location = var.location
  tags     = var.tags
}

module "virtual_network" {
  source              = "./modules/virtual_network"
  vnet_name           = "vnet${local.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

module "subnet" {
  source               = "./modules/subnet"
  subnet_name          = "snet${local.suffix}"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.virtual_network.name
  address_prefixes     = var.subnet_address_prefixes
}

module "network_security_group" {
  source              = "./modules/network_security_group"
  nsg_name            = "nsg${local.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.subnet.id
  nsg_rules           = var.nsg_rules
  tags                = var.tags
}

module "route_table" {
  source              = "./modules/route_table"
  route_table_name    = "rt${local.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.subnet.id
  routes              = var.routes
  tags                = var.tags
}

module "network_interface" {
  source              = "./modules/network_interface"
  nic_name            = "nic${local.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.subnet.id
  tags                = var.tags
}

module "virtual_machine" {
  source              = "./modules/virtual_machine"
  vm_name             = "vm${local.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  nic_id              = module.network_interface.id

  os_disk_caching              = var.os_disk_caching
  os_disk_storage_account_type = var.os_disk_storage_account_type
  os_disk_size_gb              = var.os_disk_size_gb

  image_publisher = var.image_publisher
  image_offer     = var.image_offer
  image_sku       = var.image_sku
  image_version   = var.image_version

  tags = var.tags
}

module "policy_remediation_identity" {
  source              = "./modules/managed_identity"
  name                = "id-policy-remediation-${local.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

module "storage_account" {
  count               = var.deploy_storage_account ? 1 : 0   # conditional deployment based on variable
  source              = "./modules/storage_account"
  storage_account_name = lower(replace("st${local.location_abbr[var.location]}-${var.storage_workload}${var.environment}-${var.instance}", "-", ""))
  location            = var.location
  resource_group_name = module.resource_group.name

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

  tags = var.tags
}

module "managed_disk" {
  source               = "./modules/managed_disk"
  disk_name            = "disk${local.suffix}"
  location             = var.location
  resource_group_name  = module.resource_group.name
  storage_account_type = var.data_disk_storage_account_type
  disk_size_gb         = var.data_disk_size_gb
  vm_id                = module.virtual_machine.id
  lun                  = var.data_disk_lun
  tags                 = var.tags
}
