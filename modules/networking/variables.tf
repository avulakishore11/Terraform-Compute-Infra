variable "resource_group_name" {
  type = string
}

variable "location" {
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

variable "nsg_logicapp_name" {
  type = string
}

variable "nsg_vm_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
