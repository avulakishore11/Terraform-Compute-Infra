# ── Core ──────────────────────────────────────────────────────────────────────
# subscription_id is a pipeline secret — passed via TF_VAR_subscription_id

location    = "eastus"
environment = "prod"
project     = "winvm"
sequence    = "01"

tags = {
  Department  = "CorpIT"
  CreatedBy   = "Kishore Avula"
  Project     = "Infra-automation"
  Environment = "prod"
}

# ── Networking ────────────────────────────────────────────────────────────────
vnet_address_space     = ["10.3.0.0/16"]
subnet_logicapp_prefix         = "10.3.1.0/24"
subnet_vm_prefix               = "10.3.3.0/29"
subnet_private_endpoint_prefix = "10.3.4.0/24"

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
    next_hop_in_ip_address = "10.3.255.4"
  }
]

# ── Virtual Machine ───────────────────────────────────────────────────────────
# vm_admin_password is a pipeline secret — passed via TF_VAR_vm_admin_password

vm_size                      = "Standard_D4s_v3"
vm_admin_username            = "azureadmin"
vm_os_disk_size              = 350
os_disk_caching              = "ReadWrite"
os_disk_storage_account_type = "Premium_LRS"
image_publisher              = "MicrosoftWindowsServer"
image_offer                  = "WindowsServer"
image_sku                    = "2022-Datacenter"
image_version                = "latest"

# ── Managed Data Disk ─────────────────────────────────────────────────────────
data_disk_size_gb              = 256
data_disk_storage_account_type = "Premium_LRS"
data_disk_lun                  = 0

# ── Logic App ─────────────────────────────────────────────────────────────────
logic_app_sku                  = "WS2"
logic_app_inbound_ip_addresses = []

# ── Resource Lock ─────────────────────────────────────────────────────────────
enable_resource_lock = true

# ── Recovery Services Vault + Backup ─────────────────────────────────────────
recovery_vault_redundancy   = "GeoRedundant"
backup_policy_name          = "ka-standard-policy"
backup_policy_type          = "V2"
backup_frequency            = "Daily"
backup_time                 = "07:30"
backup_weekdays             = []
backup_retention_days       = 30
backup_retention_weeks      = 5
backup_instant_restore_days = 3

# ── Azure Update Manager ──────────────────────────────────────────────────────
# Uncomment and set once a maintenance configuration exists in Azure Update Manager.
# maintenance_configuration_resource_id = "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Maintenance/maintenanceConfigurations/<name>"

# ── Storage Account ──────────────────────────────────────────────────────────
storage_account_kind             = "StorageV2"
storage_account_tier             = "Standard"
storage_account_replication_type = "GZRS"
storage_access_tier              = "Hot"

blob_soft_delete_retention_days      = 30
container_soft_delete_retention_days = 30
storage_versioning_enabled           = true

storage_ip_rules   = []
storage_subnet_ids = []
