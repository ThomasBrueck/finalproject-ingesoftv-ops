# ==============================================================================
# CircleGuard Terraform - Operaciones por Ambiente
# Uso: make <target> ENV=<dev|stage|prod>
#
# Ejemplos:
#   make init    ENV=dev
#   make plan    ENV=stage
#   make apply   ENV=prod
#   make destroy ENV=dev
# ==============================================================================

ENVS       := dev stage prod
ENV_DIR    = environments/$(ENV)
TFVARS     = $(ENV_DIR)/terraform.tfvars

.PHONY: help init plan apply destroy validate fmt core-init core-plan core-apply tools-init tools-plan tools-apply tools-destroy

help:
	@echo ""
	@echo "  CircleGuard Terraform - Targets disponibles"
	@echo "  ─────────────────────────────────────────────"
	@echo "  make init    ENV=<dev|stage|prod>   Inicializar backend remoto del ambiente"
	@echo "  make plan    ENV=<dev|stage|prod>   Mostrar plan de cambios sin aplicar"
	@echo "  make apply   ENV=<dev|stage|prod>   Aprovisionar/actualizar el ambiente"
	@echo "  make destroy ENV=<dev|stage|prod>   Destruir los recursos del ambiente"
	@echo "  make validate                        Validar sintaxis de todos los módulos"
	@echo "  make fmt                             Formatear todos los archivos .tf"
	@echo ""
	@echo "  Infraestructura compartida (AKS/ACR):"
	@echo "  make core-init    Inicializar el directorio core"
	@echo "  make core-plan    Plan del clúster AKS compartido"
	@echo "  make core-apply   Aprovisionar el clúster AKS compartido"
	@echo ""

_check_env:
	@[ -n "$(ENV)" ] || (echo "ERROR: especifica ENV=dev|stage|prod" && exit 1)
	@echo $(ENVS) | grep -wq "$(ENV)" || (echo "ERROR: ENV='$(ENV)' no válido. Usa: dev, stage o prod" && exit 1)

init: _check_env
	@echo "==> Inicializando backend remoto para ambiente: $(ENV)"
	terraform -chdir=$(ENV_DIR) init

plan: _check_env
	@echo "==> Plan de cambios para ambiente: $(ENV)"
	terraform -chdir=$(ENV_DIR) plan -var-file=terraform.tfvars

apply: _check_env
	@echo "==> Aplicando cambios en ambiente: $(ENV)"
	terraform -chdir=$(ENV_DIR) apply -var-file=terraform.tfvars

destroy: _check_env
	@echo "==> DESTRUYENDO ambiente: $(ENV) — confirma con 'yes' cuando se solicite"
	terraform -chdir=$(ENV_DIR) destroy -var-file=terraform.tfvars

validate:
	@echo "==> Validando módulos y environments"
	@for env in $(ENVS); do \
		echo "  Validando environments/$$env ..."; \
		terraform -chdir=environments/$$env validate; \
	done
	terraform -chdir=modules/kubernetes_services validate
	terraform -chdir=modules/azure_infrastructure validate
	@echo "  Validación completa."

fmt:
	@echo "==> Formateando archivos .tf"
	terraform fmt -recursive .

# Infraestructura compartida (AKS + ACR)
core-init:
	terraform -chdir=environments/core init

core-plan:
	terraform -chdir=environments/core plan

core-apply:
	terraform -chdir=environments/core apply

# VM de Jenkins + SonarQube (encender/apagar con infra-start/stop)
# Requiere: export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
tools-init:
	terraform -chdir=environments/tools init

tools-plan:
	terraform -chdir=environments/tools plan -var-file=terraform.tfvars

tools-apply:
	@echo "==> Creando VM de Jenkins. Tardará ~5 minutos en estar lista."
	terraform -chdir=environments/tools apply -var-file=terraform.tfvars
	@echo ""
	@echo "  La VM arranca Jenkins y SonarQube automáticamente via cloud-init."
	@echo "  Espera ~8 minutos adicionales para que los contenedores estén listos."

tools-destroy:
	@echo "==> ELIMINANDO VM de Jenkins"
	terraform -chdir=environments/tools destroy -var-file=terraform.tfvars
