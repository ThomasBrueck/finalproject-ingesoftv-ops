variable "namespace" {
  type        = string
  description = "El namespace de Kubernetes donde se desplegarán estos servicios (dev, stage, production)"
}

variable "postgres_password" {
  type        = string
  default     = "supersecretpassword"
  description = "Contraseña para el usuario administrador de PostgreSQL"
}

variable "postgres_db_name" {
  type        = string
  default     = "circleguard_auth"
  description = "Base de datos inicial a crear en PostgreSQL"
}

variable "postgres_persistence_enabled" {
  type        = bool
  default     = false
  description = "Habilitar persistencia de almacenamiento para PostgreSQL"
}

variable "postgres_storage_size" {
  type        = string
  default     = "5Gi"
  description = "Tamaño del disco de persistencia para PostgreSQL"
}

variable "kafka_replicas" {
  type        = number
  default     = 1
  description = "Número de réplicas para el broker de Kafka"
}

variable "kafka_persistence_enabled" {
  type        = bool
  default     = false
  description = "Habilitar persistencia para Kafka y Zookeeper"
}

variable "redis_persistence_enabled" {
  type        = bool
  default     = false
  description = "Habilitar persistencia para Redis"
}
