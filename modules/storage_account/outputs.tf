output "id" {
  description = "Resource ID of the storage account"
  value       = azurerm_storage_account.storage_account.id
}

output "name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.storage_account.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint URL"
  value       = azurerm_storage_account.storage_account.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Primary storage account access key"
  value       = azurerm_storage_account.storage_account.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.storage_account.primary_connection_string
  sensitive   = true
}
