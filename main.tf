terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Used to fetch current subscription ID (no cross-subscription)
data "azurerm_client_config" "current" {}

############################
# Resource Group
############################
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

############################
# Network
############################
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_cidr
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_cidr
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

############################
# Linux VM
############################
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  tags = {
    CreatedBy   = var.created_by
    Environment = var.environment
    Purpose     = "Alert-To-EventHub-Test"
  }
}

############################
# Log Analytics + Diagnostics
############################
resource "azurerm_log_analytics_workspace" "central_workspace" {
  name                = "central-monitoring-logs"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  name                       = "vm-diagnostics-settings"
  target_resource_id         = azurerm_linux_virtual_machine.vm.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central_workspace.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

############################
# Action Group -> Event Hub (SAME SUBSCRIPTION)
############################
resource "azurerm_monitor_action_group" "vm_alert_group" {
  name                = "vm-alert-action-group-${var.created_by}"
  resource_group_name = var.rg_name
  short_name          = "vm-${substr(var.created_by, 0, 8)}"

  event_hub_receiver {
    name                    = "EventHubReceiver"
    event_hub_namespace     = var.eventhub_namespace_name
    event_hub_name          = var.eventhub_name
    subscription_id         = data.azurerm_client_config.current.subscription_id
    use_common_alert_schema = true
  }

  tags = {
    CreatedBy   = var.created_by
    Environment = var.environment
    Purpose     = "Alert-To-EventHub"
  }
}

############################
# CPU Metric Alert (TEST)
############################
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "vm-cpu-alert-${var.created_by}-${var.vm_name}"
  resource_group_name = var.rg_name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "TEST alert: CPU > 5%"
  severity            = 3
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5
  }

  window_size = "PT5M"
  frequency   = "PT1M"

  action {
    action_group_id = azurerm_monitor_action_group.vm_alert_group.id
  }

  tags = {
    CreatedBy   = var.created_by
    Environment = var.environment
    TestAlert   = "true"
  }
}

############################
# OPTIONAL: Memory Alert
############################
resource "azurerm_monitor_metric_alert" "memory_alert" {
  name                = "vm-memory-alert-${var.created_by}-${var.vm_name}"
  resource_group_name = var.rg_name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  severity            = 3
  enabled             = var.enable_memory_alert

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1073741824
  }

  window_size = "PT5M"
  frequency   = "PT1M"

  action {
    action_group_id = azurerm_monitor_action_group.vm_alert_group.id
  }
}

############################
# Outputs
############################
output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.vm_alert_group.id
}

output "cpu_alert_id" {
  value = azurerm_monitor_metric_alert.cpu_alert.id
}
