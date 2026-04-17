resource "azurerm_resource_group" "rg" {
  name     = "tf-vm-group"
  location = "North Central US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "tf-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "tf-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  for_each = toset([ "vm1","vm2","vm3" ])
  
  name = "${each.value}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = toset([ "vm1","vm2","vm3" ])
  
  name = "${each.value}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2as_v4"

  admin_username                  = "adminuser"
  disable_password_authentication = false
  admin_password                  = "Password@123"


  network_interface_ids = [
    azurerm_network_interface.nic[each.value].id
  ]


  os_disk {
    name                 = "${each.value}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
  }
}


resource "azurerm_public_ip" "this" {
  name                = "lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_lb" "this" {
  name                = "lb_name"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend_ip"
    public_ip_address_id = azurerm_public_ip.this.id
  }
}


resource "azurerm_lb_backend_address_pool" "this" {
  name            = "backendpool"
  loadbalancer_id = azurerm_lb.this.id
}


resource "azurerm_lb_probe" "this" {
  name            = "lb_probe"
  protocol        = "Tcp"
  port            = var.probe_port
  loadbalancer_id = azurerm_lb.this.id
}


resource "azurerm_lb_rule" "this" {
  name                           = "lb_rule"
  protocol                       = "Tcp"
  frontend_port                  = var.lb_port
  backend_port                   = var.lb_port
  frontend_ip_configuration_name = "frontend_ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.this.id
  loadbalancer_id                = azurerm_lb.this.id
}

resource "azurerm_storage_account" "blob" {
  name = "storageblb01"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  account_tier = "Standard"
  account_replication_type = "LRS"
}