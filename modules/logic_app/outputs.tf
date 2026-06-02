output "app_service_plan_id" {
  value = azurerm_service_plan.logicappservice_plan.id
}

output "app_service_plan_name" {
  value = azurerm_service_plan.logicappservice_plan.name
}

output "logic_app_id" {
  value = azurerm_logic_app_standard.logic_app.id
}

output "logic_app_name" {
  value = azurerm_logic_app_standard.logic_app.name
}

output "default_hostname" {
  value = azurerm_logic_app_standard.logic_app.default_hostname
}
