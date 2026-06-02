output "id" {
  description = "Resource ID of the Windows Virtual Machine"
  value       = azurerm_windows_virtual_machine.virtual_machine.id
}

output "name" {
  description = "Name of the Windows Virtual Machine"
  value       = azurerm_windows_virtual_machine.virtual_machine.name
}
