output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = module.resource_group.name
}

# ── Networking ────────────────────────────────────────────────────────────────
# DUPLICATE NOTE: The outputs below now source from module.networking (terraform-automation).
# The old sources were module.virtual_network, module.subnet, module.network_security_group.
# After cross-check and removal of the old commented modules in main.tf, delete this note.

output "vnet_id" {
  description = "Resource ID of the Virtual Network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = module.networking.vnet_name
}

# DUPLICATE NOTE: The old single subnet_id output is replaced by two purpose-specific outputs.
# After cross-check, remove the old var.subnet_address_prefixes from tfvars.
#
# output "subnet_id" {
#   description = "Resource ID of the Subnet"
#   value       = module.subnet.id
# }

output "subnet_logicapp_id" {
  description = "Resource ID of the Logic App VNet integration subnet"
  value       = module.networking.subnet_logicapp_id
}

output "subnet_vm_id" {
  description = "Resource ID of the VM subnet"
  value       = module.networking.subnet_vm_id
}

# DUPLICATE NOTE: nsg_id and route_table_id no longer have a single output because
# the networking module manages two NSGs (logicapp + vm) internally.
# If you need the NSG IDs, add outputs to modules/networking/outputs.tf and expose them here.
#
# output "nsg_id" {
#   description = "Resource ID of the Network Security Group"
#   value       = module.network_security_group.id
# }
#
# output "route_table_id" {
#   description = "Resource ID of the Route Table"
#   value       = module.route_table.id
# }
#
# DUPLICATE NOTE: nic_id is now internal to module.vm (no separate network_interface module).
# output "nic_id" {
#   description = "Resource ID of the Network Interface"
#   value       = module.network_interface.id
# }

# ── Identity ─────────────────────────────────────────────────────────────────
# NEW from terraform-automation — Logic App User Assigned Managed Identity

output "uami_name" {
  description = "Name of the Logic App User Assigned Managed Identity"
  value       = module.identity.uami_name
}

output "uami_client_id" {
  description = "Client ID — set as MANAGED_IDENTITY_CLIENT_ID on Logic App app settings"
  value       = module.identity.uami_client_id
}

output "uami_principal_id" {
  description = "Principal (Object) ID of the Logic App UAMI — used for role assignments"
  value       = module.identity.uami_principal_id
}

# ── Virtual Machine ───────────────────────────────────────────────────────────
# DUPLICATE NOTE: vm_id, vm_name, vm_private_ip now source from module.vm
# (was module.virtual_machine / module.network_interface).

output "vm_id" {
  description = "Resource ID of the Windows VM"
  value       = module.virtual_machine.id
}

output "vm_name" {
  description = "Name of the Windows VM"
  value       = module.virtual_machine.name
}

output "vm_private_ip" {
  description = "Private IP address of the VM (no public IP — connect via Bastion or VPN)"
  value       = module.network_interface.private_ip_address
}

output "data_disk_id" {
  description = "Resource ID of the Managed Data Disk"
  value       = module.managed_disk.id
}

# ── Logic App ─────────────────────────────────────────────────────────────────

output "app_service_plan_id" {
  description = "Resource ID of the App Service Plan hosting the Logic App"
  value       = module.logic_app.app_service_plan_id
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan hosting the Logic App"
  value       = module.logic_app.app_service_plan_name
}

output "logic_app_name" {
  description = "Name of the Logic App Standard"
  value       = module.logic_app.logic_app_name
}

output "logic_app_id" {
  description = "Resource ID of the Logic App Standard"
  value       = module.logic_app.logic_app_id
}

output "logic_app_default_hostname" {
  description = "Default hostname of the Logic App Standard"
  value       = module.logic_app.default_hostname
}

# ── Monitoring ────────────────────────────────────────────────────────────────
# NEW from terraform-automation

output "app_insights_name" {
  description = "Name of the Application Insights instance"
  value       = module.monitoring.app_insights_name
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.monitoring.app_insights_instrumentation_key
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace"
  value       = module.monitoring.workspace_id
}

# ── Storage Account ───────────────────────────────────────────────────────────
output "storage_id" {
  description = "Resource ID of the Terraform-managed Storage Account (null when deploy_storage_account = false)"
  value       = one(module.storage_account[*].id)
}

# ── Logic App Storage ─────────────────────────────────────────────────────────
output "logicapp_storage_name" {
  description = "Name of the dedicated Logic App storage account"
  value       = azurerm_storage_account.logicapp.name
}

output "logicapp_storage_id" {
  description = "Resource ID of the dedicated Logic App storage account"
  value       = azurerm_storage_account.logicapp.id
}
