variable "environment" {
  type        = string
  description = "Nombre del ambiente (dev, stage, prod)"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "El ambiente debe ser 'dev', 'stage' o 'prod'."
  }
}

variable "persistence_enabled" {
  type        = bool
  description = "Habilitar persistencia de datos en PostgreSQL, Redis y Kafka"
}

variable "postgres_storage_size" {
  type        = string
  description = "Tamaño del PVC de PostgreSQL (ej. '1Gi', '5Gi', '20Gi')"
}

variable "kafka_replica_count" {
  type        = number
  description = "Número de réplicas del broker/controller de Kafka"
}
