# NFS on Azure Files exists only on Premium FileStorage accounts. The Standard
# tier offers SMB and nothing else, so the tier is a constraint here, not a
# performance choice. Minimum billed share size is 100 GiB.
resource "azurerm_storage_account" "files" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "LRS"

  # NFS v3 carries no transport encryption, so the account has to accept plain
  # traffic. What keeps the share off the Internet is the private endpoint
  # below, together with public network access being closed.
  https_traffic_only_enabled    = false
  public_network_access_enabled = false

  tags = local.common_tags
}

# The CSI driver creates and resizes the share itself, through the management
# API, using the identity of the node pool. Storage Account Contributor is the
# narrowest built in role that allows it; Contributor on the whole resource
# group would also work and grant far more.
resource "azurerm_role_assignment" "csi_storage" {
  scope                = azurerm_storage_account.files.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
