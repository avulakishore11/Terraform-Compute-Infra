variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_service_plan_name" {
  type = string
}

variable "logic_app_name" {
  type = string
}

variable "logic_app_sku" {
  type    = string
  default = "WS1"
}

variable "subnet_logicapp_id" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_account_access_key" {
  type      = string
  sensitive = true
}

variable "uami_id" {
  type = string
}

variable "uami_client_id" {
  type = string
}

variable "app_insights_connection_string" {
  type = string
}

variable "tags" {
  type = map(string)
}

# VM context — used as app settings so workflows can target the automation VM
# without hardcoding. Read them in your workflow actions as @appsetting('VM_NAME') etc.
variable "vm_name" {
  description = "Name of the automation VM targeted by startup/shutdown workflows"
  type        = string
}

variable "vm_resource_group" {
  description = "Resource group containing the automation VM"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID — used by workflow HTTP actions targeting Azure REST API"
  type        = string
}
