location    = "eastus"
environment = "dev"
project     = "winvm" # ***this IMP, so confirm with lead before changing, as it is used in naming conventions across all resources and modules***.
instance    = "01"

tags = {
  Department  = "CorpIT"
  CreatedBy   = "Kishore Avula"
  Project     = "Infra-automation"
  Environment = "dev"
}

vnet_address_space      = ["10.1.0.0/16"]
subnet_address_prefixes = ["10.1.0.0/24"]

# always look confluence documentation before creating any NSG rules, we have a standard set of NSG rules that we use across all environments and projects. If you need to create custom NSG rules, please refer to the documentation and follow the guidelines for naming conventions, priority settings, and allowed protocols/ports.
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

vm_size        = "Standard_D4s_v3"
admin_username = "azureadmin"

os_disk_size_gb              = 128
os_disk_storage_account_type = "StandardSSD_LRS"

data_disk_size_gb              = 32
data_disk_storage_account_type = "StandardSSD_LRS"
data_disk_lun                  = 0

# Azure Update Manager — copy the full ARM ID from Azure Portal → Maintenance Configurations
maintenance_configuration_resource_id = "/subscriptions/7a6d2623-b7d9-467b-ab2f-d71d7bf6d45d.../resourceGroups/.../providers/Microsoft.Maintenance/maintenanceConfigurations/..."

# Storage Account
deploy_storage_account           = false   # set to false to skip deploying the storage account in this environment
storage_workload                 = "hr"          # drives the storage account name: st{location}{workload}{env}{instance}
storage_account_kind             = "StorageV2"
storage_account_tier             = "Standard"
storage_account_replication_type = "ZRS"    # Zone-redundant: survives a full AZ outage
storage_access_tier              = "Hot"    # Optimised for frequent reads/writes

storage_public_network_access_enabled = true   # must be true for ip_rules to take effect
storage_shared_access_key_enabled     = true   # set false to enforce Azure AD-only auth

blob_soft_delete_retention_days      = 7
container_soft_delete_retention_days = 7
storage_versioning_enabled           = false   # enable if you need point-in-time blob recovery

# Storage Firewall — allowed public IPs
# Rules: bare IPv4 only (no /31 or /32 CIDR), no RFC-1918 private ranges.
# To add a new IP: append to the list, raise a PR for review.
# To add VNet access: use storage_subnet_ids with the subnet's Service Endpoint instead.
storage_ip_rules = [
  "170.55.159.52",  #— dev workstation (added 2026-05-14)
  # "x.x.x.x",     # <Name> — <purpose> (added YYYY-MM-DD)
  # "x.x.x.x",     # <Name> — <purpose> (added YYYY-MM-DD)
]

# storage_subnet_ids   = []               # add subnet resource IDs for VNet Service Endpoint access
storage_network_bypass = ["AzureServices"] # allows Monitor, Backup, Site Recovery etc.
