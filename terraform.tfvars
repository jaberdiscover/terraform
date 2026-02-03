# Sample terraform.tfvars file
# Copy this to terraform.tfvars and update with your actual values

# Basic Configuration
rg_name         = "rg-test-vm"
location        = "East US"
environment     = "Test"
created_by      = "AbdulM"  # CHANGE THIS to your name/identifier

# Subscription Configuration
subscription_id = "d0b6484c-394e-4e9b-a4d7-08beb829a885"  # CHANGE THIS - VM subscription

# Event Hub Configuration 
#eventhub_subscription_id = "9202ea8a-00d5-469d-ac22-7b6bf3f5377f"  # CHANGE THIS - Event Hub subscription
eventhub_resource_group  = "CGKPI"              # CHANGE THIS - Event Hub resource group
eventhub_namespace_name  = "cegeventhub"               # CHANGE THIS - Get from other account
eventhub_name            = "eventhubtest"                    # CHANGE THIS - Get from other account

# Network Configuration
vnet_name   = "vnet-test"
vnet_cidr   = ["10.0.0.0/16"]
subnet_name = "subnet-test"
subnet_cidr = ["10.0.1.0/24"]

# VM Configuration
vm_name              = "vm-test-tf"
vm_size              = "Standard_B2s"
admin_username       = "azureuser"
ssh_public_key_path  = "C:/Users/AbdulMajeed/.ssh/id_ed25519.pub"  # CHANGE THIS to your SSH key path

# Image Configuration (Ubuntu 22.04 LTS)
image = {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}

# Alert Configuration
custom_emails = "abdul.majeed@windward.com"  # CHANGE THIS (optional)

# Optional Configuration
enable_memory_alert = false  # Set to true if you want memory monitoring too
webhook_uri         = ""     # Leave empty if not using webhook
