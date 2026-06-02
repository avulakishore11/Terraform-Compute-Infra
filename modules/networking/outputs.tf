output "vnet_id" {
  value = azurerm_virtual_network.virtual_network.id
}

output "vnet_name" {
  value = azurerm_virtual_network.virtual_network.name
}

output "subnet_logicapp_id" {
  value = azurerm_subnet.logicapp_subnet.id
}

output "subnet_vm_id" {
  value = azurerm_subnet.virtual_machine_subnet.id
}

output "subnet_private_endpoint_id" {
  value = azurerm_subnet.private_endpoint_subnet.id
}
