# ==============================================================================
# Configuración del ambiente de DESARROLLO (dev)
# Prioridad: velocidad de iteración y bajo costo.
# - Sin persistencia: los datos se pierden al reiniciar pods (aceptable en dev).
# - Recursos mínimos: reduce costo de Azure for Students.
# - 1 réplica de Kafka: suficiente para pruebas funcionales locales.
# ==============================================================================

environment           = "dev"
persistence_enabled   = false
postgres_storage_size = "1Gi"
kafka_replica_count   = 1
enable_kafka          = false
