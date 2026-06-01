output "logic_app_id" {
  value = azurerm_logic_app_standard.main.id
}

output "logic_app_name" {
  value = azurerm_logic_app_standard.main.name
}

output "default_hostname" {
  value = azurerm_logic_app_standard.main.default_hostname
}
