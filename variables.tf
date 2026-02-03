# Basic Configuration
variable "rg_name" {
  description = "Resource Group Name"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment tag (Test, Dev, Prod)"
  type        = string
  default     = "Test"
}

variable "created_by" {
  description = "Your name or identifier to track your alerts"
  type        = string
  # Example: "JohnDoe" or "YourName"
}

variable "subscription_id" {
  description = "Azure Subscription ID where VM will be created"
  type        = string
}

# Event Hub Configuration (for Function App integration)
# These are in a DIFFERENT subscription
# variable "eventhub_subscription_id" {
#   description = "Subscription ID where Event Hub and Function App are located (can be different from VM subscription)"
#   type        = string
# }

variable "eventhub_resource_group" {
  description = "Resource Group where Event Hub is located (in the other subscription)"
  type        = string
}

variable "eventhub_namespace_name" {
  description = "Name of the existing Event Hub Namespace (in the other subscription)"
  type        = string
  # Example: "your-eventhub-namespace"
}

variable "eventhub_name" {
  description = "Name of the existing Event Hub (in the other subscription)"
  type        = string
  # Example: "your-eventhub-name"
}
variable "vnet_name" {
  description = "Virtual Network Name"
  type        = string
}

variable "vnet_cidr" {
  description = "VNET Address Space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  description = "Subnet Name"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet Address Prefix"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

# VM Configuration
variable "vm_name" {
  description = "Virtual Machine Name"
  type        = string
}

variable "vm_size" {
  description = "VM Size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin Username"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH Public Key"
  type        = string
}

variable "image" {
  description = "VM Image Details"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Alert Configuration
variable "custom_emails" {
  description = "Email address for alert notifications (optional)"
  type        = string
  default     = ""
}


variable "enable_memory_alert" {
  description = "Enable memory alert monitoring"
  type        = bool
  default     = false
}

# Optional: Webhook (if you want to keep it as backup)
variable "webhook_uri" {
  description = "Webhook URI (optional, can be left empty)"
  type        = string
  default     = ""
}
