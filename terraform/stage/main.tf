terraform {
  backend "azurerm" {
    resource_group_name  = "finalproject-tfstate"
    storage_account_name = "finalprojecttfstate"
    container_name       = "tfstate"
    key                  = "stage.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

module "aks" {
  source              = "../modules/aks"
  cluster_name        = "finalproject-aks-stage"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "finalproject-stage"
  node_count          = 3
}
