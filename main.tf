provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "personal" {
  name     = "personal-resources"
  location = "Central India"
}

resource "azurerm_virtual_network" "personal" {
  name                = "personal-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.personal.location
  resource_group_name = azurerm_resource_group.personal.name
}

resource "azurerm_subnet" "personal" {
  name                 = "personal-subnet"
  resource_group_name  = azurerm_resource_group.personal.name
  virtual_network_name = azurerm_virtual_network.personal.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "personal" {
  count               = var.vm_count
  name                = "personal-publicip-${count.index}"
  location            = azurerm_resource_group.personal.location
  resource_group_name = azurerm_resource_group.personal.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "personal" {
  count               = var.vm_count
  name                = "personal-nic-${count.index}"
  location            = azurerm_resource_group.personal.location
  resource_group_name = azurerm_resource_group.personal.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.personal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.personal[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "personal" {
  count                 = var.vm_count
  name                  = "personal-vm-${count.index}"
  location              = azurerm_resource_group.personal.location
  resource_group_name   = azurerm_resource_group.personal.name
  network_interface_ids = [azurerm_network_interface.personal[count.index].id]

  size           = "Standard_D2_v3"
  admin_username = "adminuser"
  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.public_key_path)
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_network_security_group" "personal" {
  name                = "personal-nsg"
  location            = azurerm_resource_group.personal.location
  resource_group_name = azurerm_resource_group.personal.name
}

resource "azurerm_network_security_rule" "personal" {
  count                       = var.vm_count
  name                        = "allow-ssh-${count.index}"
  priority                    = 100 + count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = azurerm_network_interface.personal[count.index].private_ip_address
  resource_group_name         = azurerm_resource_group.personal.name
  network_security_group_name = azurerm_network_security_group.personal.name
}
