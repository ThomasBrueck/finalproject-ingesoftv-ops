# ==============================================================================
# Configuración del ambiente de PRODUCCIÓN (prod)
# Prioridad: disponibilidad, durabilidad y rendimiento.
# - Persistencia habilitada: los datos deben sobrevivir cualquier evento.
# - Almacenamiento generoso: capacidad para datos reales de usuarios.
# - 3 réplicas de Kafka: alta disponibilidad con tolerancia a fallos de broker.
# ==============================================================================

environment           = "prod"
persistence_enabled   = true
postgres_storage_size = "20Gi"
kafka_replica_count   = 3
