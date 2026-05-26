module "azure_infrastructure" {
  source = "../../modules/azure_infrastructure"

  environment    = "stage"
  acr_name       = var.acr_name
  vm_size        = var.vm_size
  ssh_public_key = var.ssh_public_key
}

module "kubernetes_services" {
  source                       = "../../modules/kubernetes_services"
  namespace                    = "stage"
  postgres_password            = var.postgres_password
  postgres_persistence_enabled = true # STAGE usa persistencia para simular PROD
  kafka_persistence_enabled    = true
  redis_persistence_enabled    = true

  # Enforzar que se cree la VM y el ACR antes de aplicar recursos de Kubernetes
  depends_on = [module.azure_infrastructure]
}

output "stage_vm_public_ip" {
  value       = module.azure_infrastructure.vm_public_ip
  description = "IP pública del servidor STAGE en Azure"
}

output "stage_acr_login_server" {
  value       = module.azure_infrastructure.acr_login_server
  description = "Dirección de login del registro ACR para STAGE"
}

output "stage_postgres_dns" {
  value       = module.kubernetes_services.postgres_dns
  description = "Dirección DNS interna de Postgres"
}
