# Define the Resource Group
resource "azurerm_resource_group" "private_rg" {
  name     = "openenv-xnzv7p"
  location = "East US"
}

# Define the Virtual Network (VNet)
resource "azurerm_virtual_network" "private_vnet" {
  name                = "ocp-private-vnet"
  location            = azurerm_resource_group.private_rg.location
  resource_group_name = azurerm_resource_group.private_rg.name
  address_space       = ["10.0.0.0/16"]
}

# Define the Subnet within the VNet
resource "azurerm_subnet" "registry_subnet" {
  name                 = "registry-subnet"
  resource_group_name  = azurerm_resource_group.private_rg.name
  virtual_network_name = azurerm_virtual_network.private_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define the Network Security Group (NSG) for Internet Access
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "private-vm-nsg"
  location            = azurerm_resource_group.private_rg.location
  resource_group_name = azurerm_resource_group.private_rg.name

  security_rule {
    name                       = "AllowInboundSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutboundInternet"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}
