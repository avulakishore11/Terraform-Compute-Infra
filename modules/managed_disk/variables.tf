variable "disk_name" {
  description = "Name of the Managed Disk"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "storage_account_type" {
  description = "Storage type for the Managed Disk"
  type        = string
  default     = "Premium_LRS"
}

variable "disk_size_gb" {
  description = "Size of the Managed Disk in GB"
  type        = number
  default     = 128
}


# attaching the this disk to VM requires the VM's resource ID and a LUN (Logical Unit Number) for the attachment. 
variable "vm_id" {
  description = "Resource ID of the VM to attach the disk to"
  type        = string
}

variable "lun" {
  description = "Logical Unit Number for the disk attachment"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Tags applied to the Managed Disk"
  type        = map(string)
  default     = {}
}
