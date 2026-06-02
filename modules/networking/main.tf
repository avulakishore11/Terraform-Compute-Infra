resource "azurerm_virtual_network" "virtual_network" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Logic App VNet Integration Subnet — delegation + Storage service endpoint required
resource "azurerm_subnet" "logicapp_subnet" {
  name                 = var.subnet_logicapp_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = [var.subnet_logicapp_prefix]

  service_endpoints = ["Microsoft.Storage"]

  delegation {
    name = "logic-app-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# VM Subnet
resource "azurerm_subnet" "virtual_machine_subnet" {
  name                 = var.subnet_vm_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = [var.subnet_vm_prefix]
}

# Private Endpoint Subnet 
resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = "sn-private-endpoint-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = [var.subnet_private_endpoint_prefix]
}

# ── NSG — Logic App Subnet ────────────────────────────────────────────────────
resource "azurerm_network_security_group" "logicapp_nsg" {
  name                = var.nsg_logicapp_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTPS-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureMonitor-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureMonitor"
  }
}

resource "azurerm_subnet_network_security_group_association" "logicapp_nsg_association" {
  subnet_id                 = azurerm_subnet.logicapp_subnet.id
  network_security_group_id = azurerm_network_security_group.logicapp_nsg.id
}

# ── NSG — VM Subnet ───────────────────────────────────────────────────────────
resource "azurerm_network_security_group" "virtual_machine_nsg" {
  name                = var.nsg_vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # No inbound RDP from internet — use Azure Bastion or VPN
  security_rule {
    name                       = "Deny-RDP-Internet-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "virtual_machine_nsg_association" {
  subnet_id                 = azurerm_subnet.virtual_machine_subnet.id
  network_security_group_id = azurerm_network_security_group.virtual_machine_nsg.id
}
