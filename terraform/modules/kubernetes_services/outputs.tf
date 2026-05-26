output "postgres_service_name" {
  value       = "postgres-${var.namespace}-postgresql"
  description = "Nombre del servicio de PostgreSQL dentro del clúster"
}

output "postgres_dns" {
  value       = "postgres-${var.namespace}-postgresql.${var.namespace}.svc.cluster.local"
  description = "Dirección DNS interna de PostgreSQL"
}

output "kafka_service_name" {
  value       = "kafka-${var.namespace}"
  description = "Nombre del servicio de Kafka dentro del clúster"
}

output "kafka_dns" {
  value       = "kafka-${var.namespace}.${var.namespace}.svc.cluster.local"
  description = "Dirección DNS interna de Kafka"
}

output "redis_service_name" {
  value       = "redis-${var.namespace}-master"
  description = "Nombre del servicio de Redis Master dentro del clúster"
}

output "redis_dns" {
  value       = "redis-${var.namespace}-master.${var.namespace}.svc.cluster.local"
  description = "Dirección DNS interna de Redis"
}
