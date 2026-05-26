module "azure_infrastructure" {
  source = "../../modules/azure_infrastructure"

  environment    = "prod"
  acr_name       = var.acr_name
  vm_size        = var.vm_size
  ssh_public_key = var.ssh_public_key
}

module "kubernetes_services" {
  source                       = "../../modules/kubernetes_services"
  namespace                    = "prod"
  postgres_password            = var.postgres_password
  postgres_persistence_enabled = true # PROD siempre usa persistencia en disco
  kafka_persistence_enabled    = true
  redis_persistence_enabled    = true

  # Enforzar que se cree la VM y el ACR antes de aplicar recursos de Kubernetes
  depends_on = [module.azure_infrastructure]
}

output "prod_vm_public_ip" {
  value       = module.azure_infrastructure.vm_public_ip
  description = "IP pública del servidor PROD en Azure"
}

output "prod_acr_login_server" {
  value       = module.azure_infrastructure.acr_login_server
  description = "Dirección de login del registro ACR para PROD"
}

output "prod_postgres_dns" {
  value       = module.kubernetes_services.postgres_dns
  description = "Dirección DNS interna de Postgres"
}
