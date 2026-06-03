variable "storage_account_name" {
  description = "Globally unique storage account name (3-24 chars, lowercase alphanumeric only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only (no hyphens or special characters). Azure enforces this globally."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that owns this storage account"
  type        = string
}

variable "account_kind" {
  description = "Storage account kind (StorageV2 recommended for most workloads)"
  type        = string
  default     = "StorageV2"
}

variable "account_tier" {
  description = "Performance tier — Standard is required for ZRS replication"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Replication strategy (LRS | ZRS | GRS | GZRS | RA-GRS | RA-GZRS)"
  type        = string
  default     = "ZRS"
}

variable "access_tier" {
  description = "Default blob access tier (Hot | Cool)"
  type        = string
  default     = "cool"
}

variable "min_tls_version" {
  description = "Minimum TLS version enforced on requests"
  type        = string
  default     = "TLS1_2"
}

variable "https_traffic_only_enabled" {
  description = "Reject all plain HTTP requests"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Allow public internet access to the storage account. Disable for private workloads."
  type        = bool
  default     = false
}

variable "allow_nested_items_to_be_public" {
  description = "Permit blobs/containers to have anonymous public read access. Keep false unless CDN is required."
  type        = bool
  default     = false
}


variable "cross_tenant_replication_enabled" {
  description = "Allow GRS replication to a storage account in a different AAD tenant. Disable unless needed."
  type        = bool
  default     = false
}


# if you want to enable this, you must also set up a cross-tenant identity and grant it Storage Account Key Operator permissions on the destination account
# if the destination account is in a different subscription, the identity must also have Reader access to that subscription
# if the destination account doesnt blong to any tenant or subscription then you should set up a service principal with Storage Account Key Operator permissions on the destination account and use its credentials to authenticate the replication
variable "shared_access_key_enabled" {
  description = "Enable storage account key (SAS) authentication. Set to false to enforce Azure AD only."
  type        = bool
  default     = false
}

variable "blob_soft_delete_retention_days" {
  description = "Blob soft-delete retention in days (1-365). Set to 0 to disable."
  type        = number
  default     = 7
}

variable "container_soft_delete_retention_days" {
  description = "Container soft-delete retention in days (1-365). Set to 0 to disable."
  type        = number
  default     = 7
}

variable "versioning_enabled" {
  description = "Enable blob versioning (keeps previous versions on overwrites/deletes)"
  type        = bool
  default     = false
}

variable "network_rules_ip_rules" {
  description = <<-EOT
    Public IPv4 addresses or CIDR ranges (max /30) allowed through the storage firewall.
    When this list is non-empty, default_action becomes Deny — every other IP is blocked.

    How to add a new IP:
      1. Confirm the IP with the requestor (run `curl ifconfig.me` from their machine).
      2. Add the entry here and update dev/test/prod.tfvars accordingly.
      3. Raise a PR so it gets reviewed — storage firewall changes are audited.

    Azure does NOT accept:
      - /31 or /32 CIDRs — use bare IPs (e.g. "170.55.159.52", not "170.55.159.52/32")
      - IPv6 addresses
      - Private RFC-1918 ranges (use virtual_network_subnet_ids for VNet access instead)
  EOT
  type        = list(string)
  default     = []
}

variable "network_rules_subnet_ids" {
  description = "VNet subnet resource IDs that may access the storage account via a Service Endpoint. Add subnets here instead of public IPs for private VNet traffic."
  type        = list(string)
  default     = []
}

variable "network_rules_bypass" {
  description = "Azure services that bypass the firewall regardless of ip_rules. AzureServices covers Monitor, Backup, Site Recovery, and other first-party services."
  type        = list(string)
  default     = ["AzureServices"]
}

variable "tags" {
  description = "Tags inherited from the root module"
  type        = map(string)
  default     = {}
}
