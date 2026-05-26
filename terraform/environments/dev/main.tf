module "azure_infrastructure" {
  source = "../../modules/azure_infrastructure"

  environment    = "dev"
  acr_name       = var.acr_name
  vm_size        = var.vm_size
  ssh_public_key = var.ssh_public_key
}

module "kubernetes_services" {
  source                       = "../../modules/kubernetes_services"
  namespace                    = "dev"
  postgres_password            = var.postgres_password
  postgres_persistence_enabled = false # DEV no necesita persistencia en disco de Azure

  # Enforzar que se cree la VM y el ACR antes de aplicar recursos de Kubernetes
  depends_on = [module.azure_infrastructure]
}

output "dev_vm_public_ip" {
  value       = module.azure_infrastructure.vm_public_ip
  description = "IP pública del servidor DEV en Azure"
}

output "dev_acr_login_server" {
  value       = module.azure_infrastructure.acr_login_server
  description = "Dirección de login del registro ACR para DEV"
}

output "dev_postgres_dns" {
  value       = module.kubernetes_services.postgres_dns
  description = "Dirección DNS interna de Postgres"
}
