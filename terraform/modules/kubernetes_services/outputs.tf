output "namespace" {
  value       = kubernetes_namespace.namespace.metadata[0].name
  description = "Nombre del namespace de Kubernetes creado para el ambiente"
}

output "postgres_release_name" {
  value       = helm_release.postgres.name
  description = "Nombre del Helm release de PostgreSQL"
}

output "redis_release_name" {
  value       = helm_release.redis.name
  description = "Nombre del Helm release de Redis"
}

output "kafka_release_name" {
  value       = var.enable_kafka ? helm_release.kafka[0].name : "kafka-disabled"
  description = "Nombre del Helm release de Kafka (o 'kafka-disabled' si no está desplegado)"
}
