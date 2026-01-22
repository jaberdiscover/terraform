variable "location" {
  type = string
  default = "Central US"
}

variable "rg_name" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "vnet_cidr" {
  type = list(string)
}

variable "subnet_name" {
  type = string
}

variable "subnet_cidr" {
  type = list(string)
}

variable "vm_name" {
  type = string
}

variable "vm_size" {
  type = string
  default = "Standard_B2s"
}

variable "admin_username" {
  type = string
  default = "azureuser"
}

variable "ssh_public_key_path" {
  type = string
}

variable "image" {
  type = object({
    publisher = string
    offer = string
    sku = string
    version = string
  })
}