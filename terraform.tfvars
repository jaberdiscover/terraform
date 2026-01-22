rg_name = "rg-test-vm"
vnet_name = "vnet-test"
subnet_name = "subnet-test"

vnet_cidr = [ "10.0.0.0/16" ]
subnet_cidr = [ "10.0.1.0/24" ]

vm_name = "vm-test-tf"
vm_size = "Standard_B2s"

ssh_public_key_path = "~/.ssh/id_rsa.pub"

image = {
  publisher = "Canonical"
  offer = "0001-com-ubuntu-server-jammy"
  sku = "22_04-lts"
  version = "latest"
}