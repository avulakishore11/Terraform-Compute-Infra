output "uami_id" {
  value = azurerm_user_assigned_identity.main.id
}

output "uami_name" {
  value = azurerm_user_assigned_identity.main.name
}

output "uami_client_id" {
  value = azurerm_user_assigned_identity.main.client_id
}

output "uami_principal_id" {
  value = azurerm_user_assigned_identity.main.principal_id
}
