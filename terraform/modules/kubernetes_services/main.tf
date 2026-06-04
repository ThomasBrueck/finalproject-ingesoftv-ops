# ==============================================================================
# Kubernetes Services - Servicios de infraestructura para UN ambiente
# ==============================================================================

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.environment
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# PostgreSQL
resource "helm_release" "postgres" {
  name       = "postgres-${var.environment}"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "18.6.7"
  namespace  = kubernetes_namespace.namespace.metadata[0].name
  wait       = true

  set {
    name  = "auth.postgresPassword"
    value = "supersecretpassword"
  }
  set {
    name  = "auth.database"
    value = "circleguard_auth"
  }
  set {
    name  = "primary.persistence.enabled"
    value = tostring(var.persistence_enabled)
  }
  set {
    name  = "primary.persistence.size"
    value = var.postgres_storage_size
  }
}

# Redis
resource "helm_release" "redis" {
  name       = "redis-${var.environment}"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "redis"
  version    = "25.5.3"
  namespace  = kubernetes_namespace.namespace.metadata[0].name
  wait       = true

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
    value = tostring(var.persistence_enabled)
  }
}

# Kafka — deshabilitado en dev (imágenes Bitnami requieren auth en ghcr.io/docker.io)
resource "helm_release" "kafka" {
  count = var.enable_kafka ? 1 : 0

  name       = "kafka-${var.environment}"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "kafka"
  namespace  = kubernetes_namespace.namespace.metadata[0].name
  wait       = true
  timeout    = 900

  # Bitnami dejó de publicar imágenes nuevas en Docker Hub — ghcr.io es el
  # mirror oficial. allowInsecureImages omite la verificación de registro.
  set {
    name  = "image.registry"
    value = "ghcr.io"
  }
  set {
    name  = "image.repository"
    value = "bitnami/kafka"
  }
  set {
    name  = "global.security.allowInsecureImages"
    value = "true"
  }

  set {
    name  = "replicaCount"
    value = tostring(var.kafka_replica_count)
  }
  set {
    name  = "controller.replicaCount"
    value = tostring(var.kafka_replica_count)
  }
  set {
    name  = "broker.persistence.enabled"
    value = tostring(var.persistence_enabled)
  }
  set {
    name  = "controller.persistence.enabled"
    value = tostring(var.persistence_enabled)
  }
}
