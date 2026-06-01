output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "subnet_logicapp_id" {
  value = azurerm_subnet.logicapp.id
}

output "subnet_vm_id" {
  value = azurerm_subnet.vm.id
}
