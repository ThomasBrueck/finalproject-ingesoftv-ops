module "kubernetes_services" {
  source = "../../modules/kubernetes_services"

  environment           = var.environment
  persistence_enabled   = var.persistence_enabled
  postgres_storage_size = var.postgres_storage_size
  kafka_replica_count   = var.kafka_replica_count
}

output "namespace" {
  value = module.kubernetes_services.namespace
}
