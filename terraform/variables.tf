variable "subscription_id" {
  description = "Azure subscription the lab runs in, set through TF_VAR_subscription_id."
  type        = string
}

variable "resource_group_name" {
  description = "Ressource Group"
  type        = string
  default     = "mpetitRG"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "francecentral"
}

variable "cluster_name" {
  description = "AKS cluster name."
  type        = string
  default     = "aks-azurefiles"
}

variable "node_count" {
  description = "Number of nodes in the default pool."
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size of the default pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "vnet_name" {
  description = "Virtual network hosting the nodes and the private endpoint."
  type        = string
  default     = "vnet-azurefiles"
}

variable "vnet_address_space" {
  description = "Address space of the virtual network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "Subnet carrying the AKS nodes and the private endpoint."
  type        = string
  default     = "10.0.1.0/24"
}

variable "service_cidr" {
  description = "CIDR of the Kubernetes services."
  type        = string
  default     = "10.240.0.0/16"
}

variable "dns_service_ip" {
  description = "Address of kube-dns."
  type        = string
  default     = "10.240.0.10"
}

variable "storage_account_name" {
  description = "Storage account holding the NFS share."
  type        = string
  default     = "mpazurefilesnfs"
}
