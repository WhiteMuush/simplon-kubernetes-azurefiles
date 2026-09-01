## Storage configuration

resource "azurerm_storage_account" "files" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "LRS"

  # NFS v3 has no transport encryption, so the account cannot require HTTPS.
  https_traffic_only_enabled    = false
  public_network_access_enabled = false

  tags = local.common_tags
}

## Permissions for the CSI driver

# The driver calls Azure with the control plane identity, not the kubelet one.
resource "azurerm_role_assignment" "csi_storage" {
  scope                = azurerm_storage_account.files.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "csi_network" {
  scope                = azurerm_virtual_network.this.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}
