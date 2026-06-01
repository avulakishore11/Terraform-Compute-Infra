output "vm_id" {
  value = azurerm_windows_virtual_machine.main.id
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.main.name
}

output "private_ip" {
  value = azurerm_network_interface.main.private_ip_address
}
