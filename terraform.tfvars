rg_name = "rg-test-vm"
vnet_name = "vnet-test"
subnet_name = "subnet-test"

vnet_cidr = [ "10.0.0.0/16" ]
subnet_cidr = [ "10.0.1.0/24" ]
subscription_id = "d0b6484c-394e-4e9b-a4d7-08beb829a885"
vm_name = "vm-test-tf"
vm_size = "Standard_B2s"
custom_emails = "abdul.majeed@windward.com"
ssh_public_key_path = "C:/Users/AbdulMajeed/.ssh/id_ed25519.pub"
webhook_uri = "https://cegeventhub.servicebus.windows.net:443/"
image = {
  publisher = "Canonical"
  offer = "0001-com-ubuntu-server-jammy"
  sku = "22_04-lts"
  version = "latest"
}
