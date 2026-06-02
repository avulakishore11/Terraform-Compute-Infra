variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "subnet_logicapp_name" {
  type = string
}

variable "subnet_logicapp_prefix" {
  type = string
}

variable "subnet_vm_name" {
  type = string
}

variable "subnet_vm_prefix" {
  type = string
}

variable "subnet_private_endpoint_prefix" {
  description = "CIDR prefix for the private endpoint subnet (e.g. 10.1.4.0/24)"
  type        = string
}

variable "nsg_logicapp_name" {
  type = string
}

variable "nsg_vm_name" {
  type = string
}

variable "storage_account_id" {
  description = "Resource ID of the storage account to attach the private endpoint to"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account — used to name the private endpoint resources"
  type        = string
}

variable "tags" {
  type = map(string)
}
