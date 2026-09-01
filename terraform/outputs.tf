output "cluster_name" {
  description = "Name to pass to az aks get-credentials."
  value       = azurerm_kubernetes_cluster.this.name
}

output "storage_account_name" {
  description = "Storage account the StorageClass has to point at."
  value       = azurerm_storage_account.files.name
}

output "private_endpoint_ip" {
  description = "Private address the share answers on, useful when DNS misbehaves."
  value       = azurerm_private_endpoint.file.private_service_connection[0].private_ip_address
}
