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
# Create Log Analytics Workspace for centralized monitoring
resource "azurerm_log_analytics_workspace" "central_workspace" {
  name                = "central-monitoring-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                  = "PerGB2018"
}
resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  name               = "vm-diagnostics-settings"
  target_resource_id = azurerm_linux_virtual_machine.vm.id
  workspace_id       = azurerm_log_analytics_workspace.central_workspace.id

  logs {
    category = "AuditLogs"
    enabled  = true
  }

  metrics {
    category = "AllMetrics"
    enabled  = true
  }
}
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "vm-cpu-high-alert"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Compute/virtualMachines"]
  description         = "Alert when CPU utilization exceeds 80% for 10 minutes"

  criteria {
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
    time_aggregation = "Average"
    metric_namespace = "Microsoft.Compute/virtualMachines"
  }

  action {
    action_group_id = azurerm_monitor_action_group.vm_alert_group.id
  }

  severity = 2  # Set severity level (2 for warning)
}
resource "azurerm_monitor_action_group" "vm_alert_group" {
  name                = "vm-alert-action-group"
  resource_group_name = var.resource_group_name
  short_name          = "vmalerts"

  email_receiver {
    name               = "EmailReceiver"
    custom_emails      = var.custom_emails
  }

  webhook_receiver {
    name        = "webhookReceiver"
    service_uri = var.webhook_uri
  }
}
# Logic App Workflow (integrated with ServiceNow or other webhook services)
resource "azurerm_logic_app_workflow" "vm_cpu_alert_logic_app" {
  name                = "vm-cpu-alert-logic-app"
  location            = var.location
  resource_group_name = var.resource_group_name

  definition          = jsonencode({
    "definition" = {
      "actions" = {
        "CreateIncident" = {
          "inputs" = {
            "serviceNow" = {
              "incident" = {
                "short_description" = "VM CPU High Alert",
                "description"       = "CPU utilization exceeded 80%",
                "priority"          = "2",
                "assignment_group"  = "VM-Team"
              }
            }
          }
        }
      }
    }
  })

  parameters = {}
}
