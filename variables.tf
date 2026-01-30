# ===============================
# Basic Configuration
# ===============================
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
}

# ===============================
# Event Hub Configuration
# SAME SUBSCRIPTION (NO CROSS-SUB)
# ===============================
variable "eventhub_namespace_name" {
  description = "Name of the existing Event Hub Namespace (same subscription)"
  type        = string
}

variable "eventhub_name" {
  description = "Name of the existing Event Hub (same subscription)"
  type        = string
}

# ===============================
# Network Configuration
# ===============================
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

# ===============================
# VM Configuration
# ===============================
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

# ===============================
# Alert Configuration
# ===============================
variable "enable_memory_alert" {
  description = "Enable memory alert monitoring"
  type        = bool
  default     = false
}
