output "app_service_plan_id" {
  value = azurerm_service_plan.main.id
}

output "app_service_plan_name" {
  value = azurerm_service_plan.main.name
}

output "logic_app_id" {
  value = azurerm_logic_app_standard.main.id
}

output "logic_app_name" {
  value = azurerm_logic_app_standard.main.name
}

output "default_hostname" {
  value = azurerm_logic_app_standard.main.default_hostname
}
