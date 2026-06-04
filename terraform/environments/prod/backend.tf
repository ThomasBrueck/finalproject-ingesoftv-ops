terraform {
  backend "azurerm" {
    resource_group_name  = "circleguard-tfstate-rg"
    storage_account_name = "cgtfstate99901"
    container_name       = "tfstate"
    key                  = "env/prod.terraform.tfstate"
  }
}
