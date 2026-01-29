# Sample terraform.tfvars file
# Copy this to terraform.tfvars and update with your actual values

# Basic Configuration
rg_name         = "rg-test-vm"
location        = "East US"
environment     = "Test"
created_by      = "YourName"  # CHANGE THIS to your name/identifier
subscription_id = "d0b6484c-394e-4e9b-a4d7-08beb829a885"  # CHANGE THIS

# Network Configuration
vnet_name   = "vnet-test"
vnet_cidr   = ["10.0.0.0/16"]
subnet_name = "subnet-test"
subnet_cidr = ["10.0.1.0/24"]

# VM Configuration
vm_name              = "vm-test-tf"
vm_size              = "Standard_B2s"
admin_username       = "azureuser"
ssh_public_key_path  = "~/.ssh/id_rsa.pub"  # CHANGE THIS to your SSH key path

# Image Configuration (Ubuntu 22.04 LTS)
image = {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}

# Alert Configuration
custom_emails = "your-email@example.com"  # CHANGE THIS (optional)

# Event Hub Configuration - IMPORTANT: These must match your existing Event Hub
eventhub_namespace_name = "your-eventhub-namespace"  # CHANGE THIS - Get from Azure Portal
eventhub_name           = "your-eventhub-name"        # CHANGE THIS - Get from Azure Portal

# Optional Configuration
enable_memory_alert = false  # Set to true if you want memory monitoring too
webhook_uri         = ""     # Leave empty if not using webhook
