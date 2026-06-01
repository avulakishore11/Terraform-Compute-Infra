# ── Core ──────────────────────────────────────────────────────────────────────
# subscription_id is a pipeline secret — passed via TF_VAR_subscription_id, not here.

location    = "eastus2"
environment = "dev"
project     = "winvm"   # *** confirm with lead before changing — used in all resource names ***
sequence    = "01"

tags = {
  Department  = "CorpIT"
  CreatedBy   = "Kishore Avula"
  Project     = "Infra-automation"
  Environment = "dev"
}

# ── Networking ────────────────────────────────────────────────────────────────
vnet_address_space     = ["10.1.0.0/16"]
subnet_logicapp_prefix = "10.1.1.0/24"   # Logic App VNet integration — delegation required
subnet_vm_prefix       = "10.1.3.0/29"   # VM subnet — /29 gives 3 usable IPs

nsg_rules = [
  {
    name                       = "Allow-RDP-Internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
]

routes = [
  {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.255.4"
  }
]

# ── Virtual Machine ───────────────────────────────────────────────────────────
vm_size           = "Standard_D4s_v3"
vm_admin_username = "azureadmin"
vm_os_disk_size   = 128
# vm_admin_password is a pipeline secret — passed via TF_VAR_vm_admin_password, not here.

# ── Managed Data Disk ─────────────────────────────────────────────────────────
data_disk_size_gb              = 32
data_disk_storage_account_type = "StandardSSD_LRS"
data_disk_lun                  = 0

# ── Logic App ─────────────────────────────────────────────────────────────────
logic_app_sku = "WS1"

# ── Azure Update Manager ──────────────────────────────────────────────────────
# Copy the full ARM ID from: Azure Portal → Maintenance Configurations → your config → Properties → Resource ID
# Leave unset (omit) to skip Update Manager policy assignment until the config is created.
# maintenance_configuration_resource_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Maintenance/maintenanceConfigurations/..."

# ── Storage Account (Terraform-managed, conditional) ─────────────────────────
deploy_storage_account           = true
storage_workload                 = "hr"
storage_account_kind             = "StorageV2"
storage_account_tier             = "Standard"
storage_account_replication_type = "ZRS"
storage_access_tier              = "Hot"

storage_public_network_access_enabled = true
storage_shared_access_key_enabled     = true

blob_soft_delete_retention_days      = 7
container_soft_delete_retention_days = 7
storage_versioning_enabled           = false

storage_ip_rules = [
  "170.55.159.52",  # dev workstation (added 2026-05-14)
]
storage_network_bypass = ["AzureServices"]

# ── Workflow notifications ────────────────────────────────────────────────────
# key_vault_name and notification_email have defaults in variables.tf.
# Override here if needed:
# key_vault_name     = "kv-winvm-dev-01"
# notification_email = "kishore.avula@kaseya.com"
