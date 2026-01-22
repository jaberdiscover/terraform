terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "=4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name = var.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name = var.vnet_name
  address_space = var.vnet_cidr
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name = var.subnet_name
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = var.subnet_cidr
}

resource "azurerm_network_interface" "nic" {
  name = "${var.vm_name}-nic"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "ipconfig1"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location = var.location
  size = var.vm_size
  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image.publisher
    offer = var.image.offer
    sku = var.image.sku
    version = var.image.version
  }
}
resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  name               = "vm-diagnostics-settings"
  target_resource_id = azurerm_linux_virtual_machine.vm.id
  logs {
    category = "AuditLogs"
    enabled  = true
    retention_policy {
      days     = 30
      enabled  = false
    }
  }
  metrics {
    category = "AllMetrics"
    enabled  = true
  }
  workspace_id = azurerm_log_analytics_workspace.central_workspace.id
}

