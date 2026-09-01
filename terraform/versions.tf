terraform {
  required_version = ">= 1.9"

  # Project 85968137 is WhiteMuush/simplon-kubernetes-azurefiles. Credentials
  # come from .env, so nothing secret is committed here.
  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/85968137/terraform/state/aks-azurefiles"
    lock_address   = "https://gitlab.com/api/v4/projects/85968137/terraform/state/aks-azurefiles/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/85968137/terraform/state/aks-azurefiles/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
