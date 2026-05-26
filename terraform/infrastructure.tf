# ==============================================================================
# CircleGuard - Terraform Root
# ==============================================================================
# ADVERTENCIA: Este directorio YA NO se usa directamente para apply.
#
# Toda la infraestructura está organizada por ambientes bajo:
#   environments/dev/    -> Ambiente de desarrollo
#   environments/stage/  -> Ambiente de pruebas / staging
#   environments/prod/   -> Ambiente de producción
#
# Módulos reutilizables:
#   modules/azure_infrastructure/  -> VM, VNet, ACR, NSG en Azure
#   modules/kubernetes_services/   -> Postgres, Kafka, Redis en K3s
#
# CÓMO USAR:
#   cd environments/dev   && terraform init && terraform apply
#   cd environments/stage && terraform init && terraform apply
#   cd environments/prod  && terraform init && terraform apply
#
# ANTES de ejecutar por primera vez, corre el script de bootstrap:
#   bash bootstrap-backend.sh
# ==============================================================================
