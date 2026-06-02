output "app_service_plan_id" {
  value = azurerm_service_plan.plan.id
}

output "app_service_plan_name" {
  value = azurerm_service_plan.plan.name
}

output "logic_app_id" {
  value = azurerm_logic_app_standard.plan.id
}

output "logic_app_name" {
  value = azurerm_logic_app_standard.plan.name
}

output "default_hostname" {
  value = azurerm_logic_app_standard.plan.default_hostname
}
