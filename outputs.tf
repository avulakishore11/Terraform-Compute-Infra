output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = module.resource_group.name
}

output "vnet_id" {
  description = "Resource ID of the Virtual Network"
  value       = module.virtual_network.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = module.virtual_network.name
}

output "subnet_id" {
  description = "Resource ID of the Subnet"
  value       = module.subnet.id
}

output "nsg_id" {
  description = "Resource ID of the Network Security Group"
  value       = module.network_security_group.id
}

output "route_table_id" {
  description = "Resource ID of the Route Table"
  value       = module.route_table.id
}

output "nic_id" {
  description = "Resource ID of the Network Interface"
  value       = module.network_interface.id
}

output "vm_id" {
  description = "Resource ID of the Windows VM"
  value       = module.virtual_machine.id
}

output "vm_name" {
  description = "Name of the Windows VM"
  value       = module.virtual_machine.name
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = module.network_interface.private_ip_address
}

output "data_disk_id" {
  description = "Resource ID of the Managed Data Disk"
  value       = module.managed_disk.id
}

# Wrong — will error
# output "storage_id" {
 # value = module.storage_account.id
# }

# Correct
output "storage_id" {
  value = module.storage_account[0].id
}