variable "prefix" {
  default = "tfcloud"
}
variable "subscription_id" { default = "b5799dba-db55-4a3e-a924-447423d54891" }
variable "client_id" { default = "8e62a5c4-9d03-4a3b-a939-754f99bd2716" }
variable "secret" { default = "9-XKD-c09co]S1Ml[=B9A?]QyGiX5WRA" }
variable "tenant_id" { default = "9a7c976b-6e54-4bcc-99cb-f707fc5da05b" }

provider "azurerm" {
  version = "~> 2.0"
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "westeurope"
  tags = {
    acronimo = "HCLO0"
    referente = "federico.vibrati@intesasanpaolo.com"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}