# ==============================================================================
# Kubernetes Services (Helm Deployments for Multi-Tenant AKS)
# ==============================================================================

# 1. Namespaces para cada ambiente (dev, stage, prod)
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(var.environments)

  metadata {
    name = each.key
  }
}

# 2. PostgreSQL
resource "helm_release" "postgres" {
  for_each = toset(var.environments)

  name       = "postgres-${each.key}"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "18.6.7"
  namespace  = kubernetes_namespace.namespaces[each.key].metadata[0].name
  wait       = true

  set {
    name  = "auth.postgresPassword"
    value = "supersecretpassword"
  }
  set {
    name  = "auth.database"
    value = "circleguard_auth"
  }

  # Persistencia habilitada SOLO para stage y prod
  set {
    name  = "primary.persistence.enabled"
    value = each.key == "dev" ? "false" : "true"
  }
  set {
    name  = "primary.persistence.size"
    value = "5Gi"
  }
}

# 3. Redis
resource "helm_release" "redis" {
  for_each = toset(var.environments)

  name       = "redis-${each.key}"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "redis"
  version    = "25.5.3"
  namespace  = kubernetes_namespace.namespaces[each.key].metadata[0].name
  wait       = true

  set {
    name  = "architecture"
    value = "standalone"
  }
  set {
    name  = "auth.enabled"
    value = "false"
  }

  # Persistencia habilitada SOLO para stage y prod
  set {
    name  = "master.persistence.enabled"
    value = each.key == "dev" ? "false" : "true"
  }
}

# 4. Kafka
resource "helm_release" "kafka" {
  for_each = toset(var.environments)

  name       = "kafka-${each.key}"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "kafka"
  version    = "29.3.2"
  namespace  = kubernetes_namespace.namespaces[each.key].metadata[0].name
  wait       = true
  timeout    = 900  # 15 minutos — Kafka tarda más que el default de 5 min

  # Bitnami movió sus imágenes de docker.io a ghcr.io en 2024
  set {
    name  = "image.registry"
    value = "ghcr.io"
  }
  set {
    name  = "replicaCount"
    value = "1"
  }
  set {
    name  = "controller.replicaCount"
    value = "1"
  }

  # Persistencia habilitada SOLO para stage y prod
  set {
    name  = "broker.persistence.enabled"
    value = each.key == "dev" ? "false" : "true"
  }
  set {
    name  = "controller.persistence.enabled"
    value = each.key == "dev" ? "false" : "true"
  }
}
