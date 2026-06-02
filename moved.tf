# NOTE: azurerm_application_insights.main (module.monitoring) was removed.
# Terraform will plan to destroy it on next apply — this is intentional.
# No moved block needed for deletions.

# Resource renames declared here so Terraform updates state automatically
# during plan/apply — no manual "terraform state mv" commands needed.
# These blocks can be removed after the first successful apply.

# ── Networking module renames ─────────────────────────────────────────────────

moved {
  from = module.networking.azurerm_virtual_network.main
  to   = module.networking.azurerm_virtual_network.virtual_network
}

moved {
  from = module.networking.azurerm_subnet.logicapp
  to   = module.networking.azurerm_subnet.logicapp_subnet
}

moved {
  from = module.networking.azurerm_subnet.vm
  to   = module.networking.azurerm_subnet.virtual_machine_subnet
}

moved {
  from = module.networking.azurerm_network_security_group.logicapp
  to   = module.networking.azurerm_network_security_group.logicapp_nsg
}

moved {
  from = module.networking.azurerm_network_security_group.vm
  to   = module.networking.azurerm_network_security_group.virtual_machine_nsg
}

moved {
  from = module.networking.azurerm_subnet_network_security_group_association.logicapp
  to   = module.networking.azurerm_subnet_network_security_group_association.logicapp_nsg_association
}

moved {
  from = module.networking.azurerm_subnet_network_security_group_association.vm
  to   = module.networking.azurerm_subnet_network_security_group_association.virtual_machine_nsg_association
}

# ── Logic App module renames ──────────────────────────────────────────────────

moved {
  from = module.logic_app.azurerm_service_plan.main
  to   = module.logic_app.azurerm_service_plan.logicappservice_plan
}

moved {
  from = module.logic_app.azurerm_logic_app_standard.main
  to   = module.logic_app.azurerm_logic_app_standard.logic_app
}

# ── Storage account module rename ─────────────────────────────────────────────

moved {
  from = module.storage_account.azurerm_storage_account.this
  to   = module.storage_account.azurerm_storage_account.storage_account
}

# ── Resource Group module rename ─────────────────────────────────────────────

moved {
  from = module.resource_group.azurerm_resource_group.this
  to   = module.resource_group.azurerm_resource_group.resource_group
}

# ── Private endpoint moved from networking module to root ─────────────────────

moved {
  from = module.networking.azurerm_private_dns_zone.storage_file_dns_zone
  to   = azurerm_private_dns_zone.storage_file
}

moved {
  from = module.networking.azurerm_private_dns_zone_virtual_network_link.storage_file_dns_link
  to   = azurerm_private_dns_zone_virtual_network_link.storage_file
}

moved {
  from = module.networking.azurerm_private_endpoint.storage_account_private_endpoint
  to   = azurerm_private_endpoint.storage_account
}

# ── Storage account consolidation ─────────────────────────────────────────────

moved {
  from = azurerm_storage_account.logicapp
  to   = module.storage_account.azurerm_storage_account.this
}
