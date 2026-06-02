###############################################################################
# Naming Convention:
#   Resource Group   : rg-{project}-{env}-{seq}
#   VNet             : vnet{region}-{env}-{seq}
#   Subnets          : sn-{purpose}-{env}
#   NSGs             : nsg-{purpose}-{env}-{seq}
#   Logic App        : la{region}-{project}-{env}-{seq}
#   App Service Plan : asp-{region}-{project}-{env}-{seq}
#   UAMI             : uami-logicapp-storage-{env}
#   VM               : vm{region}-{project}-{env}-{seq}
#   Storage          : stla{region}{env}{seq}  (no dashes — Azure requirement)
###############################################################################

locals {
  # ── Region abbreviation map ─────────────────────────────────────────────────
  region_short = {
    "eastus"             = "eus"
    "eastus2"            = "eus2"
  }
  region = lookup(local.region_short, var.location, replace(var.location, " ", ""))

  # ── Resource names ──────────────────────────────────────────────────────────
  resource_group_name   = "rg-${var.project}-${var.environment}-${var.sequence}"
  vnet_name             = "vnet${local.region}-${var.environment}-${var.sequence}"
  subnet_logicapp_name  = "sn-logicapp-${var.environment}"
  subnet_vm_name        = "sn-vm-${var.environment}"
  nsg_logicapp_name     = "nsg-logicapp-${var.environment}-${var.sequence}"
  nsg_vm_name           = "nsg-vm-${var.environment}-${var.sequence}"
  policy_identity_name  = "id-policy-remediation-${var.project}-${var.environment}-${var.sequence}"
  uami_name             = "uami-logicapp-storage-${var.environment}"
  log_analytics_name    = "law-${var.project}-${var.environment}-${var.sequence}"
  app_insights_name     = "appi-${var.project}-${var.environment}-${var.sequence}"
  app_service_plan_name = "asp-${local.region}-${var.project}-${var.environment}-${var.sequence}"
  logic_app_name        = "la${local.region}-${var.project}-${var.environment}-${var.sequence}"
  vm_name               = "vm${local.region}-${var.project}-${var.environment}-${var.sequence}"
  vm_nic_name           = "nic-${local.vm_name}"
  vm_disk_name          = "osdisk-${local.vm_name}"
  managed_disk_name     = "disk-${local.vm_name}"
  # Single storage account — used by both Logic App runtime and application data.
  # Storage account names cannot contain dashes (Azure requirement).
  logicapp_storage_name = lower(replace("stla${local.region}${var.environment}${var.sequence}", "-", ""))

  # ── Common tags applied to every resource ───────────────────────────────────
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
      Owner       = "Kishore Avula"
      CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    },
    var.tags
  )
}
