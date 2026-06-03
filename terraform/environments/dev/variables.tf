variable "environment" {
  type        = string
  description = "Nombre del ambiente"
}

variable "persistence_enabled" {
  type        = bool
  description = "Habilitar persistencia de datos (PVCs)"
}

variable "postgres_storage_size" {
  type        = string
  description = "Tamaño del PVC de PostgreSQL"
}

variable "kafka_replica_count" {
  type        = number
  description = "Número de réplicas del broker/controller de Kafka"
}

variable "aks_cluster_name" {
  type        = string
  description = "Nombre del clúster AKS compartido"
  default     = "circleguard-aks"
}

variable "aks_resource_group" {
  type        = string
  description = "Grupo de recursos del clúster AKS"
  default     = "circleguard-core-rg"
}
