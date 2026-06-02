resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Logic App VNet Integration Subnet — delegation required for outbound traffic
resource "azurerm_subnet" "logicapp" {
  name                 = var.subnet_logicapp_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
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
resource "azurerm_subnet" "vm" {
  name                 = var.subnet_vm_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_vm_prefix]
}

# NSG — Logic App Subnet
resource "azurerm_network_security_group" "logicapp" {
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

resource "azurerm_subnet_network_security_group_association" "logicapp" {
  subnet_id                 = azurerm_subnet.logicapp.id
  network_security_group_id = azurerm_network_security_group.logicapp.id
}

# NSG — VM Subnet
resource "azurerm_network_security_group" "vm" {
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

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}
