# ==============================================================================
# CircleGuard - Backend de Estado Remoto para STAGE
# ==============================================================================
# NOTA: Reemplaza "storage_account_name" con el nombre generado
# automáticamente por el script 'bootstrap-backend.sh'.
# ==============================================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "circleguard-tfstate-rg"
    storage_account_name = "cgtfstate99901"
    container_name       = "tfstate"
    key                  = "stage.terraform.tfstate"
  }
}
