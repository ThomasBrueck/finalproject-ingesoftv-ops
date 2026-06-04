# ==============================================================================
# Configuración del ambiente de STAGING (stage)
# Prioridad: fidelidad con producción a costo reducido.
# - Persistencia habilitada: simula comportamiento real de datos.
# - Almacenamiento moderado: suficiente para pruebas de integración y QA.
# - 1 réplica de Kafka: refleja la topología básica sin costo de HA.
# ==============================================================================

environment           = "stage"
persistence_enabled   = true
postgres_storage_size = "5Gi"
kafka_replica_count   = 1
enable_kafka          = true
