## Common tags

locals {
  common_tags = {
    Project     = "simplon-kubernetes-azurefiles"
    Environment = "Lab"
  }
}

## Network configuration

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = local.common_tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_prefix]

  # Required before a private endpoint can be placed here.
  private_endpoint_network_policies = "Disabled"
}

## Private DNS for the file service

resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  name                 = "link-${var.vnet_name}"
  private_dns_zone_id  = azurerm_private_dns_zone.file.id
  virtual_network_id   = azurerm_virtual_network.this.id
  registration_enabled = false
  tags                 = local.common_tags
}

## Private endpoint to the storage account

resource "azurerm_private_endpoint" "file" {
  name                = "pe-${var.storage_account_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.aks.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-file"
    private_connection_resource_id = azurerm_storage_account.files.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "file"
    private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
  }
}
