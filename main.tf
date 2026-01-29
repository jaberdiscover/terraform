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

  tags = {
    CreatedBy = var.created_by
    Environment = var.environment
    MonitoredBy = "FunctionApp"
  }
}

# Create Log Analytics Workspace for centralized monitoring
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

# Action Group that sends alerts to Event Hub (which triggers Function App)
# Event Hub is in a DIFFERENT subscription/account
resource "azurerm_monitor_action_group" "vm_alert_group" {
  name                = "vm-alert-action-group-${var.created_by}"
  resource_group_name = var.rg_name
  short_name          = "vm-${substr(var.created_by, 0, 8)}"

  # Optional: Keep email notification if you want
  email_receiver {
    name          = "EmailReceiver"
    email_address = var.custom_emails
  }

  # Event Hub receiver - connects to Event Hub in DIFFERENT subscription
  # Format: /subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.EventHub/namespaces/{namespace}/eventhubs/{eventhub}
  event_hub_receiver {
    name                    = "EventHubReceiver-CrossSub"
    event_hub_namespace     = var.eventhub_namespace_name
    event_hub_name          = var.eventhub_name
    subscription_id         = var.eventhub_subscription_id  # Different subscription!
    use_common_alert_schema = true  # Important: Use common alert schema for consistency
  }

  tags = {
    CreatedBy   = var.created_by
    Purpose     = "FunctionAppIntegration"
    Environment = var.environment
    CrossSub    = "true"
  }
}

# CPU Alert Rule - sends to Action Group (which sends to Event Hub → Function App → ServiceNow)
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "vm-cpu-alert-${var.created_by}-${var.vm_name}"
  resource_group_name = var.rg_name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "TEST ALERT - Created by ${var.created_by} - Alert when CPU exceeds 5% (easy to trigger for testing)"
  severity            = 3  # Sev3 for testing

  criteria {
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5  # Low threshold for easy testing
    metric_namespace = "Microsoft.Compute/virtualMachines"
  }

  window_size        = "PT5M"  # 5 minute window
  frequency          = "PT1M"  # Check every 1 minute

  action {
    action_group_id = azurerm_monitor_action_group.vm_alert_group.id
  }

  tags = {
    CreatedBy   = var.created_by
    TestAlert   = "true"
    Environment = var.environment
    MonitoredBy = "FunctionApp"
  }
}

# Optional: Memory Alert (if you want to monitor memory too)
resource "azurerm_monitor_metric_alert" "memory_alert" {
  name                = "vm-memory-alert-${var.created_by}-${var.vm_name}"
  resource_group_name = var.rg_name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "TEST ALERT - Created by ${var.created_by} - Alert when Available Memory is low"
  severity            = 3
  enabled             = var.enable_memory_alert  # Can be toggled

  criteria {
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1073741824  # 1 GB in bytes
    metric_namespace = "Microsoft.Compute/virtualMachines"
  }

  window_size = "PT5M"
  frequency   = "PT1M"

  action {
    action_group_id = azurerm_monitor_action_group.vm_alert_group.id
  }

  tags = {
    CreatedBy   = var.created_by
    TestAlert   = "true"
    Environment = var.environment
    MonitoredBy = "FunctionApp"
  }
}

# Output important information
output "vm_id" {
  value       = azurerm_linux_virtual_machine.vm.id
  description = "The ID of the created VM"
}

output "vm_name" {
  value       = azurerm_linux_virtual_machine.vm.name
  description = "The name of the created VM"
}

output "action_group_id" {
  value       = azurerm_monitor_action_group.vm_alert_group.id
  description = "The ID of the Action Group connected to Event Hub"
}

output "cpu_alert_id" {
  value       = azurerm_monitor_metric_alert.cpu_alert.id
  description = "The ID of the CPU alert rule"
}

output "alert_identifier" {
  value       = "vm-cpu-alert-${var.created_by}-${var.vm_name}"
  description = "Use this to search for your alerts in ServiceNow"
}

