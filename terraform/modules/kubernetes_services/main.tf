resource "kubernetes_namespace" "ns" {
  metadata {
    name = var.namespace
  }
}

# Desplegar PostgreSQL
resource "helm_release" "postgres" {
  name       = "postgres-${var.namespace}"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.ns.metadata[0].name
  timeout    = 300 

  set {
    name  = "auth.postgresPassword"
    value = var.postgres_password
  }
  set {
    name  = "auth.database"
    value = var.postgres_db_name
  }
  set {
    name  = "primary.persistence.enabled"
    value = var.postgres_persistence_enabled ? "true" : "false"
  }
  set {
    name  = "primary.persistence.size"
    value = var.postgres_storage_size
  }
}

# Desplegar Kafka (para mensajería de notificaciones)
resource "helm_release" "kafka" {
  name       = "kafka-${var.namespace}"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "kafka"
  namespace  = kubernetes_namespace.ns.metadata[0].name
  version    = "29.3.2"
  timeout    = 300

  set {
    name  = "replicaCount"
    value = var.kafka_replicas
  }
  set {
    name  = "controller.persistence.enabled"
    value = var.kafka_persistence_enabled ? "true" : "false"
  }
  set {
    name  = "broker.persistence.enabled"
    value = var.kafka_persistence_enabled ? "true" : "false"
  }
  set {
    name  = "image.repository"
    value = "bitnamilegacy/kafka"
  }
}

# Desplegar Redis (para caché de sesión)
resource "helm_release" "redis" {
  name       = "redis-${var.namespace}"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "redis"
  namespace  = kubernetes_namespace.ns.metadata[0].name
  timeout    = 300

  set {
    name  = "architecture"
    value = "standalone"
  }
  set {
    name  = "auth.enabled"
    value = "false"
  }
  set {
    name  = "master.persistence.enabled"
    value = var.redis_persistence_enabled ? "true" : "false"
  }
}
