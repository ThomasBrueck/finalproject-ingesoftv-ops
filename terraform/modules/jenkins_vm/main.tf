# ==============================================================================
# Jenkins VM — VM ligera para CI/CD (Jenkins + SonarQube vía Docker)
# Se enciende solo durante el trabajo; se apaga con infra-stop.sh
# ==============================================================================

resource "azurerm_resource_group" "jenkins_rg" {
  name     = "${var.project_name}-jenkins-rg"
  location = var.location
  tags = {
    Environment = "tools"
    Project     = var.project_name
  }
}

resource "azurerm_virtual_network" "jenkins_vnet" {
  name                = "${var.project_name}-jenkins-vnet"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.jenkins_rg.location
  resource_group_name = azurerm_resource_group.jenkins_rg.name
}

resource "azurerm_subnet" "jenkins_subnet" {
  name                 = "jenkins-subnet"
  resource_group_name  = azurerm_resource_group.jenkins_rg.name
  virtual_network_name = azurerm_virtual_network.jenkins_vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_public_ip" "jenkins_pip" {
  name                = "${var.project_name}-jenkins-pip"
  resource_group_name = azurerm_resource_group.jenkins_rg.name
  location            = azurerm_resource_group.jenkins_rg.location
  allocation_method   = "Static"
  sku                 = "Basic"
  tags = {
    Environment = "tools"
  }
}

resource "azurerm_network_security_group" "jenkins_nsg" {
  name                = "${var.project_name}-jenkins-nsg"
  location            = azurerm_resource_group.jenkins_rg.location
  resource_group_name = azurerm_resource_group.jenkins_rg.name

  security_rule {
    name                       = "Allow-Jenkins"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SonarQube"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Jenkins-Agent"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "50000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "jenkins_nic" {
  name                = "${var.project_name}-jenkins-nic"
  location            = azurerm_resource_group.jenkins_rg.location
  resource_group_name = azurerm_resource_group.jenkins_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jenkins_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "jenkins_nic_nsg" {
  network_interface_id      = azurerm_network_interface.jenkins_nic.id
  network_security_group_id = azurerm_network_security_group.jenkins_nsg.id
}

resource "azurerm_linux_virtual_machine" "jenkins_vm" {
  name                = "${var.project_name}-jenkins-vm"
  resource_group_name = azurerm_resource_group.jenkins_rg.name
  location            = azurerm_resource_group.jenkins_rg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.jenkins_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Bootstrap: instala Docker, Jenkins, SonarQube, kubectl, Azure CLI
  custom_data = base64encode(file("${path.module}/bootstrap.sh"))

  tags = {
    Environment = "tools"
    Project     = var.project_name
  }
}
