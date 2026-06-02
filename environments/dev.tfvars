# ── Core ──────────────────────────────────────────────────────────────────────
# subscription_id is a pipeline secret — passed via TF_VAR_subscription_id

location    = "eastus2"
environment = "dev"
project     = "winvm"
sequence    = "01"

tags = {
  Department  = "CorpIT"
  CreatedBy   = "Kishore Avula"
  Project     = "Infra-automation"
  Environment = "dev"
}

# ── Networking ────────────────────────────────────────────────────────────────
vnet_address_space     = ["10.1.0.0/16"]
subnet_logicapp_prefix = "10.1.1.0/24"
subnet_vm_prefix       = "10.1.3.0/29"

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
# vm_admin_password is a pipeline secret — passed via TF_VAR_vm_admin_password

vm_size                      = "Standard_D4s_v3"
vm_admin_username            = "azureadmin"
vm_os_disk_size              = 128
os_disk_caching              = "ReadWrite"
os_disk_storage_account_type = "StandardSSD_LRS"
image_publisher              = "MicrosoftWindowsServer"
image_offer                  = "WindowsServer"
image_sku                    = "2022-Datacenter"
image_version                = "latest"

# ── Managed Data Disk ─────────────────────────────────────────────────────────
data_disk_size_gb              = 32
data_disk_storage_account_type = "StandardSSD_LRS"
data_disk_lun                  = 0

# ── Logic App ─────────────────────────────────────────────────────────────────
logic_app_sku = "WS1"

# ── Azure Update Manager ──────────────────────────────────────────────────────
# Uncomment and set once a maintenance configuration exists in Azure Update Manager.
# maintenance_configuration_resource_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Maintenance/maintenanceConfigurations/..."

# ── Storage Account (optional application data storage) ──────────────────────
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

storage_ip_rules       = ["170.55.159.52"]
storage_subnet_ids     = []
storage_network_bypass = ["AzureServices"]
