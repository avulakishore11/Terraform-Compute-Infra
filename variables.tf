# ── Core ──────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  description = "Azure Subscription ID — passed via TF_VAR_subscription_id pipeline secret"
  type        = string
}

variable "sequence" {
  description = "Two-digit sequence number appended to resource names (e.g. 01, 02)"
  type        = string
}

variable "location" {
  description = "Azure region for all resources (e.g. eastus2, eastus)"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev | uat | prod)"
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "environment must be one of: dev, uat, prod."
  }
}

variable "project" {
  description = "Short project identifier used in resource naming"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource. Must include: Department, CreatedBy, Project, Environment."
  type        = map(string)
  validation {
    condition = alltrue([
      for key in ["Department", "CreatedBy", "Project", "Environment"]
      : contains(keys(var.tags), key)
    ])
    error_message = "tags map must contain all required keys: Department, CreatedBy, Project, Environment."
  }
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vnet_address_space" {
  description = "Address space for the Virtual Network (CIDR)"
  type        = list(string)
}

variable "subnet_logicapp_prefix" {
  description = "Logic App VNet integration subnet CIDR prefix"
  type        = string
}

variable "subnet_vm_prefix" {
  description = "VM subnet CIDR prefix"
  type        = string
}

variable "subnet_private_endpoint_prefix" {
  description = "Private endpoint subnet CIDR prefix"
  type        = string
}

variable "nsg_rules" {
  description = "NSG inbound/outbound security rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
}

variable "routes" {
  description = "User-defined routes for the Route Table"
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
}

# ── Compute ───────────────────────────────────────────────────────────────────

variable "vm_size" {
  description = "Azure VM SKU size (e.g. Standard_D2s_v3)"
  type        = string
}

variable "vm_admin_username" {
  description = "VM administrator username"
  type        = string
}

variable "vm_admin_password" {
  description = "VM administrator password — passed via TF_VAR_vm_admin_password pipeline secret"
  type        = string
  sensitive   = true
  default     = null
}

variable "vm_os_disk_size" {
  description = "VM OS disk size in GB"
  type        = number
}

variable "os_disk_caching" {
  description = "OS disk caching (None | ReadOnly | ReadWrite)"
  type        = string
}

variable "os_disk_storage_account_type" {
  description = "OS disk storage tier (Standard_LRS | StandardSSD_LRS | Premium_LRS)"
  type        = string
}

variable "image_publisher" {
  description = "VM image publisher"
  type        = string
}

variable "image_offer" {
  description = "VM image offer"
  type        = string
}

variable "image_sku" {
  description = "VM image SKU"
  type        = string
}

variable "image_version" {
  description = "VM image version"
  type        = string
}

variable "data_disk_size_gb" {
  description = "Data disk size in GB"
  type        = number
}

variable "data_disk_storage_account_type" {
  description = "Data disk storage type (Standard_LRS | StandardSSD_LRS | Premium_LRS)"
  type        = string
}

variable "data_disk_lun" {
  description = "Logical Unit Number for the data disk"
  type        = number
}

variable "maintenance_configuration_resource_id" {
  description = "ARM resource ID of the Azure Update Manager maintenance configuration. Leave unset to skip Update Manager policy assignment."
  type        = string
  default     = null
}

# ── Logic App ─────────────────────────────────────────────────────────────────

variable "logic_app_sku" {
  description = "App Service Plan SKU for Logic App Standard (WS1 | WS2 | WS3)"
  type        = string
}

# ── Storage Account ───────────────────────────────────────────────────────────
# Single account — used by Logic App runtime and application data.
# public_network_access_enabled and shared_access_key_enabled are hardcoded
# as true in main.tf (required by Logic App Standard — not user-configurable).

variable "storage_account_kind" {
  description = "Storage account kind (StorageV2 recommended)"
  type        = string
}

variable "storage_account_tier" {
  description = "Performance tier (Standard | Premium)"
  type        = string
}

variable "storage_account_replication_type" {
  description = "Replication strategy (LRS | ZRS | GRS | GZRS | RA-GRS | RA-GZRS)"
  type        = string
}

variable "storage_access_tier" {
  description = "Default blob access tier (Hot | Cool)"
  type        = string
}

variable "blob_soft_delete_retention_days" {
  description = "Blob soft-delete retention in days (1-365)"
  type        = number
}

variable "container_soft_delete_retention_days" {
  description = "Container soft-delete retention in days (1-365)"
  type        = number
}

variable "storage_versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
}

variable "storage_ip_rules" {
  description = "Public IPs or CIDRs (max /30) allowed through the storage firewall"
  type        = list(string)
}

variable "storage_subnet_ids" {
  description = "VNet subnet IDs allowed via Service Endpoint"
  type        = list(string)
}

variable "storage_network_bypass" {
  description = "Azure services that bypass the storage firewall (AzureServices | Logging | Metrics | None)"
  type        = list(string)
}

# ── External Storage (optional — leave null to use Terraform-managed storage) ─

variable "storage_account_name" {
  description = "Name of an existing Storage Account. Leave null to use the Terraform-managed one."
  type        = string
  default     = null
}

variable "storage_account_access_key" {
  description = "Primary access key of the existing Storage Account"
  type        = string
  sensitive   = true
  default     = null
}

variable "storage_account_id" {
  description = "Resource ID of the existing Storage Account (for RBAC)"
  type        = string
  default     = null
}
