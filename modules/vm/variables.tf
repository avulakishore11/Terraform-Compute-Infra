variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "nic_name" {
  type = string
}

variable "disk_name" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "os_disk_size" {
  type = number
}

variable "tags" {
  type = map(string)
}
