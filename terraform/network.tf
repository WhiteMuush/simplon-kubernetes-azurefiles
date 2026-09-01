locals {
  common_tags = {
    Project     = "simplon-kubernetes-azurefiles"
    Environment = "Lab"
  }
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = local.common_tags
}

# The nodes and the private endpoint share this subnet. Network policies for
# private endpoints have to be disabled here, otherwise Azure refuses to place
# the endpoint, with an error that does not name the policy.
resource "azurerm_subnet" "aks" {
  name                              = "snet-aks"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = [var.aks_subnet_prefix]
  private_endpoint_network_policies = "Disabled"
}

# Azure Files answers on a public name. Without this zone the cluster resolves
# the account to a public address that the account refuses, and the PVC stays
# Pending with no obvious cause.
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
