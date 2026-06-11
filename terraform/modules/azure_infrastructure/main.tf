# ==============================================================================
# Azure Infrastructure - Core AKS Cluster
# ==============================================================================

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-core-rg"
  location = var.location
  tags = {
    Environment = "core"
    Project     = "CircleGuard"
  }
}

# 2. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "${var.acr_name}core"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
  tags = {
    Environment = "core"
  }
}

# 3. Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.project_name}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.project_name}aks"
  sku_tier            = "Free"
  oidc_issuer_enabled = true

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "core"
  }
}

# 4. Role Assignment (Permitir que AKS descargue imagenes de ACR)
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
