location    = "eastus"
environment = "uat"
project     = "winvm"
instance    = "01"

tags = {
  Department  = "CorpIT"
  CreatedBy   = "Kishore Avula"
  Project     = "Infra-automation"
  Environment = "uat"
}

vnet_address_space      = ["10.2.0.0/16"]
subnet_address_prefixes = ["10.2.0.0/24"]

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
    next_hop_in_ip_address = "10.2.255.4"
  }
]

vm_size        = "Standard_D2s_v3"
admin_username = "azureadmin"

os_disk_size_gb              = 128
os_disk_storage_account_type = "Premium_LRS"

data_disk_size_gb              = 128
data_disk_storage_account_type = "Premium_LRS"
data_disk_lun                  = 0

deploy_storage_account           = false
storage_workload                 = "hr"
storage_account_kind             = "StorageV2"
storage_account_tier             = "Standard"
storage_account_replication_type = "ZRS"
storage_access_tier              = "Hot"

storage_public_network_access_enabled = false
storage_shared_access_key_enabled     = true

blob_soft_delete_retention_days      = 7
container_soft_delete_retention_days = 7
storage_versioning_enabled           = false

storage_ip_rules       = []
storage_network_bypass = ["AzureServices"]

# maintenance_configuration_resource_id = "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Maintenance/maintenanceConfigurations/<name>"
