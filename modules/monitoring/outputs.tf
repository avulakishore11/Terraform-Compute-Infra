output "workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "app_insights_name" {
  value = azurerm_application_insights.main.name
}

output "app_insights_connection_string" {
  value = azurerm_application_insights.main.connection_string
}

output "app_insights_instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}
