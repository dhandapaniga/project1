# Creating the data block for the image created via Packer
data "azurerm_image" "my_image" {
  name                = "webServerImage"
  resource_group_name = "Azuredevops"
}
# Resource Group will be updated by importing it to maintain idempotent.
resource "azurerm_resource_group" "example" {
  name     = "Azuredevops"
  location = "southcentralus"
       tags     = {
          DeploymentId = "226460" 
          LaunchId    = "1346" 
          LaunchType   = "ON_DEMAND_LAB" 
          TemplateId   = "1181" 
          TenantId    = "none"
              env       = "Prod"
    createdby = "ganesand"
}
}

# Creating the Base Network 
resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = {
    env       = "Prod"
    createdby = "ganesand"
  }
}

# Creating subnet for the VMs to be placed in for the Webserver
resource "azurerm_subnet" "example" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network security group for he subnet with the needed rule from project
resource "azurerm_network_security_group" "example" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  # Deny all internet inbound
  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = azurerm_subnet.example.address_prefixes[0]
  }

  # Allow all inbound traffic within the subnet
  security_rule {
    name                       = "allow-subnet-inbound"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = azurerm_subnet.example.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.example.address_prefixes[0]
  }

  # Allow outbound traffic to the internet
  security_rule {
    name                       = "allow-internet-outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = azurerm_subnet.example.address_prefixes[0]
    destination_address_prefix = "Internet"
  }

  tags = {
    env       = "Prod"
    createdby = "ganesand"
  }
}
# Associating the NSG to subnet of the webserver
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

# To create a VM we need the following
# NIC with Private IP
# NIC to be associated with the subnet (secured with NSG)

# Creating the network interfaces for the VMs
resource "azurerm_network_interface" "example" {
  count               = var.vm_count
  name                = "${var.prefix}-nic-${count.index + 1}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    env       = "Prod"
    createdby = "ganesand"
  }
}

# creating publicip for the Load Balancer
resource "azurerm_public_ip" "example" {
  name                = "${var.prefix}-PublicIPForLB"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  tags = {
    env       = "Prod"
    createdby = "ganesand"
  }
}
# Creating the skeleton of the LB with frontend iP association
resource "azurerm_lb" "example" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}
# creating the backend address pool with nameing
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "${var.prefix}-lb-bepool"

}
# Backend address pool association from the NIC in the subnet
resource "azurerm_network_interface_backend_address_pool_association" "business-tier-pool" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.example.*.id[count.index]
  ip_configuration_name   = azurerm_network_interface.example.*.ip_configuration.0.name[count.index]
  backend_address_pool_id = azurerm_lb_backend_address_pool.example.id
}
# LB health probe
resource "azurerm_lb_probe" "http-inbound-probe" {
  loadbalancer_id     = azurerm_lb.example.id
  name                = "http-inbound-probe"
  port                = 80
}
# Create Loadbalancing Rules
resource "azurerm_lb_rule" "production-inbound-rules" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "http-inbound-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.http-inbound-probe.id
  backend_address_pool_ids       = ["${azurerm_lb_backend_address_pool.example.id}"]
}

resource "azurerm_availability_set" "example" {
  name                         = "${var.prefix}-aset"
  location                     = azurerm_resource_group.example.location
  resource_group_name          = azurerm_resource_group.example.name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 1
  managed                      = true

  tags = {
    env       = "Prod"
    createdby = "ganesand"
  }
}
resource "azurerm_linux_virtual_machine" "example" {
  count               = var.vm_count
  name                = "${var.prefix}-vm-${count.index + 1}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  availability_set_id = azurerm_availability_set.example.id
  network_interface_ids = [
    azurerm_network_interface.example[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # source_image_reference {
  #   publisher = "Canonical"
  #   offer     = "UbuntuServer"
  #   sku       = "16.04-LTS"
  #   version   = "latest"
  # }
  source_image_id = data.azurerm_image.my_image.id
  # storage_image_reference {
  #   id = "${data.azurerm_image.my_image.id}"
  # }

  tags = {
    env       = "Prod"
    createdby = "ganesand"
  }
}