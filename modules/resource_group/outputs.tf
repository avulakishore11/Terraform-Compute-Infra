output "name" {
  description = "Name of the Resource Group"
  value       = azurerm_resource_group.resource_group.name
}

output "id" {
  description = "Resource ID of the Resource Group"
  value       = azurerm_resource_group.resource_group.id
}

output "location" {
  description = "Location of the Resource Group"
  value       = azurerm_resource_group.resource_group.location
}
