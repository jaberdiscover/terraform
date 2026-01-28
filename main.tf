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

resource "azurerm_sql_server" "sqlserver" {
  name                         = var.sqlserver_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
}

# SQL Database
resource "azurerm_sql_database" "sqldb" {
  name                     = var.sqldb_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  server_name              = azurerm_sql_server.example.name
  sku_name                 = "S1"
  collation                = "SQL_Latin1_General_CP1_CI_AS"
  max_size_bytes           = 1073741824  # 1 GB
}
# Create Log Analytics Workspace for centralized monitoring
resource "azurerm_log_analytics_workspace" "central_workspace" {
  name                = "central-monitoring-logs"
  location            = var.location
  resource_group_name = var.rg_name
  sku                  = "PerGB2018"
  retention_in_days = 30
}
resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  name               = "vm-diagnostics-settings"
  target_resource_id = azurerm_linux_virtual_machine.vm.id
  log_analytics_workspace_id      = azurerm_log_analytics_workspace.central_workspace.id

  # enabled_log {
  #   category = "AuditEvent"

  # }
  metric {
    category = "AllMetrics"
    enabled = true
    }
}
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "vm-cpu-high-alert"
  resource_group_name = var.rg_name
  scopes              =["/subscriptions/d0b6484c-394e-4e9b-a4d7-08beb829a885/resourceGroups/rg-test-vm/providers/Microsoft.Compute/virtualMachines/vm-test-tf"]
  description         = "Alert when CPU utilization exceeds 80% for 10 minutes"

  criteria {
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5
    metric_namespace = "Microsoft.Compute/virtualMachines"
  }

  action {
    action_group_id = azurerm_monitor_action_group.vm_alert_group.id
  }

  severity = 2  # Set severity level (2 for warning)
}
resource "azurerm_monitor_action_group" "vm_alert_group" {
  name                = "vm-alert-action-group"
  resource_group_name = var.rg_name
  short_name          = "vmalerts"

  email_receiver {
    name               = "EmailReceiver"
    email_address =       var.custom_emails
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
  resource_group_name = var.rg_name

  workflow_schema       = jsonencode({
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
          },
          "runAfter" = {},
          "metadeta" = {},
          "type" = "Http",
          "version" ="2025-05-01-preview"
        }
      }
    }
  })

  parameters = {}
}
# Logic App (for ServiceNow Integration)
resource "azurerm_logic_app_workflow" "sql_cpu_alert_logic_app" {
  name                = "sql-cpu-alert-logic-app"
  location            = var.location
  resource_group_name = var.resource_group_name

  definition = jsonencode({
    "definition" = {
      "actions" = {
        "CreateIncident" = {
          "inputs" = {
            "serviceNow" = {
              "incident" = {
                "short_description" = "SQL DB CPU High Alert",
                "description"      = "CPU utilization exceeded 80%",
                "priority"          = "2",
                "assignment_group"  = "VM-Team"
              }
            }
          }
        }
      },
      "runAfter" = {},
      "metadata" = {},
      "type"     = "Http",
      "version"  = "2025-05-01-preview"
    }
  })
}

# Action Group (Connects Alert to Logic App)
resource "azurerm_monitor_action_group" "sql_db_alert" {
  name                = "sql-db-alert-action-group"
  resource_group_name = var.resource_group_name
  short_name          = "sqlalerts"

  logic_app_receiver {
    name            = "send-to-servicenow"
    resource_id     = azurerm_logic_app_workflow.example.id
    use_common_alert_schema = true
  }
}

# Metric Alert for CPU Percentage
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "sql-db-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_sql_database.example.id]
  description         = "Alert when CPU utilization exceeds 80%"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80

    dimension {
      name     = "DatabaseName"
      operator = "Include"
      values   = [azurerm_sql_database.example.name]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.example.id
  }

  severity = 2  # Warning
  enabled  = true
}

# Metric Alert for DTU Consumption
resource "azurerm_monitor_metric_alert" "dtu_alert" {
  name                = "sql-db-dtu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_sql_database.example.id]
  description         = "Alert when DTU consumption exceeds 80%"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80

    dimension {
      name     = "DatabaseName"
      operator = "Include"
      values   = [azurerm_sql_database.example.name]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.example.id
  }

  severity = 2  # Warning
  enabled  = true
}

# Metric Alert for Storage Used Percentage
resource "azurerm_monitor_metric_alert" "storage_alert" {
  name                = "sql-db-storage-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_sql_database.example.id]
  description         = "Alert when storage usage exceeds 80%"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80

    dimension {
      name     = "DatabaseName"
      operator = "Include"
      values   = [azurerm_sql_database.example.name]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.example.id
  }

  severity = 2  # Warning
  enabled  = true
}

# Diagnostic Settings for SQL Database (Optional)
resource "azurerm_monitor_diagnostic_setting" "sql_db_diagnostics" {
  name                      = "sql-db-diagnostics"
  target_resource_id        = azurerm_sql_database..id
  storage_account_id        = azurerm_storage_account..id  # Using the same storage account for diagnostics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id  # Optional: If you want to send logs to Log Analytics

  enabled_log {
    category = "SQLSecurityAuditEvents"  # Security-related audit logs
  }

  enabled_log {
    category = "SQLInsights"  # Performance metrics and SQL Query execution logs
  }

  enabled_metric {
    category = "AllMetrics"  # Resource utilization metrics (CPU, Memory, DTU)
  }
}
