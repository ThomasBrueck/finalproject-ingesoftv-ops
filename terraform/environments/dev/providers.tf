terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Proveedor de Kubernetes apuntando al archivo local kubeconfig de DEV
provider "kubernetes" {
  config_path = "${path.module}/kubeconfig-dev"
}

# Proveedor de Helm apuntando al archivo local kubeconfig de DEV
provider "helm" {
  kubernetes {
    config_path = "${path.module}/kubeconfig-dev"
  }
}
