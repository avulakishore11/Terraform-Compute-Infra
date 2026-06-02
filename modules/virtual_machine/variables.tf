## Variables for the Windows Virtual Machine module

# string = single value, e.g., "eastus"
# number = numeric value, e.g., 128
# bool = true/false
# list(string) = multiple strings in a list, e.g., ["eastus", "westus"]
# map(string) = key-value pairs, e.g., { "env" = "dev", "project" = "winvm" }

## description = Helps humans understand purpose. Has no effect on deployment.

# fmt fix: inline comments after a value must be separated by exactly 1 space before #.
#          Previously had 2 spaces (e.g. `string  # ...`); terraform fmt normalises to 1 space.
variable "resource_group_name" {
  description = "Name of the Resource Group where the VM will be deployed"
  type        = string # Note: type must NOT be quoted — string not "string"
}

variable "location" {
  description = "Azure region where the VM will be deployed"
  type        = string
}

variable "vm_name" {
  description = "Name of the Windows Virtual Machine"
  type        = string
}

variable "vm_size" {
  description = "SKU size of the Virtual Machine (e.g. Standard_D2s_v3)"
  type        = string
}

variable "admin_username" {
  description = "Local administrator username"
  type        = string
  sensitive   = true # won't appear in plan/apply output or logs
}

variable "admin_password" {
  description = "Local administrator password (store in Key Vault for production)"
  type        = string
  sensitive   = true
}

variable "nic_id" {
  description = "Resource ID of the Network Interface to attach to this VM"
  type        = string
}

variable "os_disk_caching" {
  description = "OS disk caching mode (None | ReadOnly | ReadWrite)"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  # "storage_account_type" refers to the disk performance tier for Azure Managed Disks.
  # It does NOT create a Storage Account — it is a tier label (Standard_LRS, StandardSSD_LRS, Premium_LRS).
  description = "OS disk storage tier (Standard_LRS | StandardSSD_LRS | Premium_LRS)"
  type        = string
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB. type = number — passed to the Azure API as an integer."
  type        = number
}

# Image reference variables — specify which Windows image to use.
# These have defaults so you don't need to set them in tfvars unless overriding.

variable "image_publisher" {
  description = "VM image publisher"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "image_offer" {
  description = "VM image offer"
  type        = string
  default     = "WindowsServer"
}

variable "image_sku" {
  description = "VM image SKU"
  type        = string
  default     = "2022-Datacenter"
}

variable "image_version" {
  description = "VM image version"
  type        = string
  default     = "latest"
}

variable "uami_id" {
  description = "Resource ID of the User Assigned Managed Identity to attach to the VM"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource. Must include: CreatedBy, Owner, Department, Environment."
  type        = map(string)
  default     = {}
}
# fmt fix: file previously had no trailing newline; terraform fmt requires every .tf file
#          to end with a newline character.
