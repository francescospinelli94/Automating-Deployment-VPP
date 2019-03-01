

provider "azurerm" {
    
}




# RESOURCE GROUP
resource "azurerm_resource_group" "vpprg" {
    name     = "vpp"
    location = "eastus"

    tags {
        environment = "vpp"
    }
}




# VIRTUAL NETWORK
resource "azurerm_virtual_network" "vppvnet" {
    name                = "vppvnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.vpprg.name}"

    tags {
        environment = "Terraform Demo"
    }
}




# SUBNET - MANAGEMENT (SSH)
resource "azurerm_subnet" "subnet-mgmt" {
    name                 = "subnet-mgmt"
    resource_group_name  = "${azurerm_resource_group.vpprg.name}"
    virtual_network_name = "${azurerm_virtual_network.vppvnet.name}"
    address_prefix       = "10.0.1.0/24"
}



# SUBNET - VPP
resource "azurerm_subnet" "subnet-vpp" {
    name                 = "subnet-vpp"
    resource_group_name  = "${azurerm_resource_group.vpprg.name}"
    virtual_network_name = "${azurerm_virtual_network.vppvnet.name}"
    address_prefix       = "10.0.2.0/24"
}



# SUBNET IPV6
resource "azurerm_subnet" "subnet-ipv6" {
    name                 = "subnet-ipv6"
    resource_group_name  = "${azurerm_resource_group.vpprg.name}"
    virtual_network_name = "${azurerm_virtual_network.vppvnet.name}"
    address_prefix       = "10.0.3.0/24"
}



# IP
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "PublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.vpprg.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "vpp"
    }
}




# IPv6
resource "azurerm_public_ip" "myterraformpublicipv6" {
    name                         = "PublicIPv6"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.vpprg.name}"
	ip_version = "IPv6"    
	public_ip_address_allocation = "dynamic"
    
    tags {
        environment = "vpp"
    }
}




# SECURITY GROUP
resource "azurerm_network_security_group" "vppsg" {
    name                = "vppsg"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.vpprg.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Terraform Demo"
    }
}




# NIC1
resource "azurerm_network_interface" "vppnic" {
    name                      = "nic-mgmt"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.vpprg.name}"
    network_security_group_id = "${azurerm_network_security_group.vppsg.id}"

    ip_configuration {
	primary = "true"       
	 name                          = "myNicConfiguration1"
        subnet_id                     = "${azurerm_subnet.subnet-mgmt.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}



# NIC2
resource "azurerm_network_interface" "vppnic2" {
    name                      = "nic-vpp"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.vpprg.name}"
    network_security_group_id = "${azurerm_network_security_group.vppsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration2"
        subnet_id                     = "${azurerm_subnet.subnet-vpp.id}"
        private_ip_address_allocation = "dynamic"
       # public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}



# NIC3
resource "azurerm_network_interface" "vppnic3" {
    name                      = "nic-ipv6"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.vpprg.name}"
    network_security_group_id = "${azurerm_network_security_group.vppsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration3"
        subnet_id                     = "${azurerm_subnet.subnet-ipv6.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicipv6.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}



# VM
resource "azurerm_virtual_machine" "vpp" {
    name                  = "vpp"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.vpprg.name}"


network_interface_ids = ["${azurerm_network_interface.vppnic.id}", "${azurerm_network_interface.vppnic2.id}",
 "${azurerm_network_interface.vppnic3.id}"   ]

primary_network_interface_id = "${azurerm_network_interface.vppnic.id}"

    vm_size               = "Standard_DS3_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "XXXX"
	admin_password = "XXXX"
    }

    os_profile_linux_config {
        disable_password_authentication = false
       # ssh_keys {
        #    path     = "/home/azureuser/.ssh/authorized_keys"
         #   key_data = "ssh-rsa AAAAB3Nz{snip}hwhqT9h"
        #}
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Terraform Demo"
    }
}




resource "azurerm_route_table" "rt" {
  name                = "route-table"
  location            = "${azurerm_resource_group.vpprg.location}"
  resource_group_name = "${azurerm_resource_group.vpprg.name}"

  route {
    name                   = "route_to_vpp"
    address_prefix         = "10.0.0.0/16"
    next_hop_type          = "None"
    
  }
}




resource "azurerm_subnet_route_table_association" "rt_association" {
  subnet_id      = "${azurerm_subnet.subnet-vpp.id}"
  route_table_id = "${azurerm_route_table.rt.id}"
}


