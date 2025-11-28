resource "azurerm_resource_group" "weather" {
  name     = var.resource_group
  location = var.location
}
#

resource "azurerm_virtual_network" "weather" {
  name                = var.vnet_name
  location            = azurerm_resource_group.weather.location
  resource_group_name = azurerm_resource_group.weather.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "weather" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.weather.name
  virtual_network_name = azurerm_virtual_network.weather.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "weather" {
  name                = var.nsg_name
  location            = azurerm_resource_group.weather.location
  resource_group_name = azurerm_resource_group.weather.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

data "azurerm_client_config" "current" {}

# Create Azure Key Vault
resource "azurerm_key_vault" "vault" {
  name                = var.key_vault_name
  resource_group_name = azurerm_resource_group.weather.name
  location            = azurerm_resource_group.weather.location
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  #enable_rbac_authorization   = true  
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
}

resource "azurerm_key_vault_access_policy" "sp_secret_access" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.sp_object_id
  depends_on = [azurerm_key_vault.vault]
  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Recover",
    "Backup",
    "Restore",
    "Delete",
    "Purge"
  ]
  lifecycle {
    prevent_destroy = false  # Ensures Terraform deletes the policy
  }
}
/*
resource "azurerm_key_vault_access_policy" "sp_secret_access1" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.sp_object_id1
  depends_on = [azurerm_key_vault.vault]
  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge"
  ]
  lifecycle {
    prevent_destroy = false  # Ensures Terraform deletes the policy
  }
}
*/
# Generate SSH Key Pair
resource "tls_private_key" "vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store Private Key in Azure Key Vault
resource "azurerm_key_vault_secret" "vm_ssh_key" {
  name         = var.secret_name
  value        = tls_private_key.vm_ssh_key.private_key_pem
  key_vault_id = azurerm_key_vault.vault.id
  depends_on = [azurerm_key_vault_access_policy.sp_secret_access]
}

resource "azurerm_public_ip" "weather" {
  name                = "weather-public-ip"
  location            = azurerm_resource_group.weather.location
  resource_group_name = azurerm_resource_group.weather.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "weather" {
  name                = "weather-nic"
  location            = azurerm_resource_group.weather.location
  resource_group_name = azurerm_resource_group.weather.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.weather.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.weather.id
  }
}

# Azure VM with SSH Key from Key Vault
resource "azurerm_linux_virtual_machine" "weather" {
  name                  = "weather-vm"
  location              = azurerm_resource_group.weather.location
  resource_group_name   = azurerm_resource_group.weather.name
  size                  = "Standard_B1s"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.weather.id]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.vm_ssh_key.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
