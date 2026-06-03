#!/bin/bash
# ==============================================================================
# CircleGuard — Apagar infraestructura de Azure
#
# Qué hace: detiene el clúster AKS para que Azure deje de cobrar por las VMs.
# Los datos y configuración quedan guardados. Al volver a prender todo sigue
# exactamente igual.
#
# Uso: ./scripts/infra-stop.sh
# ==============================================================================
set -e

# ── Colores para los mensajes ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # sin color

# ── Configuración del clúster ──────────────────────────────────────────────────
CLUSTER_NAME="circleguard-aks"
RESOURCE_GROUP="circleguard-core-rg"
SUBSCRIPTION_ID="8cd4e2ee-fbca-46b3-a3f5-57efa772ac64"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     CircleGuard — Apagar servicios       ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── 0. Verificar que Azure CLI está instalado ─────────────────────────────────
if ! command -v az &>/dev/null; then
    echo -e "${RED}✗ Azure CLI no está instalado.${NC}"
    echo ""
    echo "  Instálalo con este comando y vuelve a ejecutar el script:"
    echo ""
    echo -e "  ${BOLD}curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash${NC}"
    echo ""
    exit 1
fi

# ── 1. Verificar sesión en Azure ───────────────────────────────────────────────
echo -e "${BLUE}[1/3]${NC} Verificando sesión en Azure..."

if ! az account show --subscription "$SUBSCRIPTION_ID" &>/dev/null; then
    echo -e "${YELLOW}No hay sesión activa. Iniciando login...${NC}"
    az login --use-device-code
fi

az account set --subscription "$SUBSCRIPTION_ID"
echo -e "${GREEN}✓${NC} Sesión activa."
echo ""

# ── 2. Verificar estado actual del clúster ─────────────────────────────────────
echo -e "${BLUE}[2/3]${NC} Verificando estado del clúster..."

CURRENT_STATE=$(az aks show \
    --name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "powerState.code" \
    --output tsv 2>/dev/null || echo "NotFound")

if [ "$CURRENT_STATE" = "NotFound" ]; then
    echo -e "${RED}✗ No se encontró el clúster '$CLUSTER_NAME'.${NC}"
    echo "  Verifica que hayas aplicado la infraestructura con: make core-apply"
    exit 1
fi

if [ "$CURRENT_STATE" = "Stopped" ]; then
    echo -e "${YELLOW}El clúster ya está detenido. No hay nada que hacer.${NC}"
    echo ""
    echo -e "  Costo actual: ${GREEN}~\$0 / hora${NC}"
    exit 0
fi

echo -e "${GREEN}✓${NC} Clúster encontrado. Estado actual: ${YELLOW}$CURRENT_STATE${NC}"
echo ""

# ── 3. Apagar el clúster ───────────────────────────────────────────────────────
echo -e "${BLUE}[3/3]${NC} Deteniendo el clúster AKS (tarda ~3 minutos)..."
echo ""

az aks stop \
    --name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --subscription "$SUBSCRIPTION_ID"

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║  ✓ Infraestructura detenida. Azure ya no cobra VMs. ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Costo mientras esté apagado: ${GREEN}~\$0 / hora${NC}"
echo -e "  Tus datos y configuración ${BOLD}están guardados${NC}."
echo ""
echo -e "  Para volver a encender: ${BOLD}./scripts/infra-start.sh${NC}"
echo ""
