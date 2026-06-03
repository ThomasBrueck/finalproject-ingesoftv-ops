#!/bin/bash
# ==============================================================================
# CircleGuard — Encender infraestructura de Azure
#
# Qué hace: arranca el clúster AKS con todo exactamente como lo dejaste.
# PostgreSQL, Redis y Kafka en los ambientes que hayas desplegado vuelven
# a estar disponibles automáticamente.
#
# Uso: ./scripts/infra-start.sh
# ==============================================================================
set -e

# ── Colores para los mensajes ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ── Configuración del clúster ──────────────────────────────────────────────────
CLUSTER_NAME="circleguard-aks"
RESOURCE_GROUP="circleguard-core-rg"
SUBSCRIPTION_ID="8cd4e2ee-fbca-46b3-a3f5-57efa772ac64"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     CircleGuard — Encender servicios     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Verificar sesión en Azure ───────────────────────────────────────────────
echo -e "${BLUE}[1/4]${NC} Verificando sesión en Azure..."

if ! az account show --subscription "$SUBSCRIPTION_ID" &>/dev/null; then
    echo -e "${YELLOW}No hay sesión activa. Iniciando login...${NC}"
    az login --use-device-code
fi

az account set --subscription "$SUBSCRIPTION_ID"
echo -e "${GREEN}✓${NC} Sesión activa."
echo ""

# ── 2. Verificar estado actual del clúster ─────────────────────────────────────
echo -e "${BLUE}[2/4]${NC} Verificando estado del clúster..."

CURRENT_STATE=$(az aks show \
    --name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "powerState.code" \
    --output tsv 2>/dev/null || echo "NotFound")

if [ "$CURRENT_STATE" = "NotFound" ]; then
    echo -e "${RED}✗ No se encontró el clúster '$CLUSTER_NAME'.${NC}"
    echo ""
    echo "  El clúster no existe todavía. Para crearlo desde cero:"
    echo "    cd terraform && make core-apply"
    echo "    cd terraform && make apply ENV=dev"
    exit 1
fi

if [ "$CURRENT_STATE" = "Running" ]; then
    echo -e "${GREEN}✓ El clúster ya está corriendo. No hay nada que hacer.${NC}"
    echo ""
    echo "  Puedes trabajar con normalidad."
    echo -e "  Recuerda apagarlo al terminar: ${BOLD}./scripts/infra-stop.sh${NC}"
    exit 0
fi

echo -e "${GREEN}✓${NC} Clúster encontrado. Estado actual: ${YELLOW}$CURRENT_STATE${NC}"
echo ""

# ── 3. Encender el clúster ─────────────────────────────────────────────────────
echo -e "${BLUE}[3/4]${NC} Encendiendo el clúster AKS (tarda ~5 minutos)..."
echo ""

az aks start \
    --name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --subscription "$SUBSCRIPTION_ID"

echo ""
echo -e "${GREEN}✓${NC} Clúster encendido."
echo ""

# ── 4. Actualizar el kubeconfig local ─────────────────────────────────────────
echo -e "${BLUE}[4/4]${NC} Actualizando credenciales locales de kubectl..."

az aks get-credentials \
    --name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --subscription "$SUBSCRIPTION_ID" \
    --overwrite-existing

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║  ✓ Infraestructura lista. Puedes empezar a trabajar.        ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Pods corriendo en el clúster:"
kubectl get pods --all-namespaces --no-headers 2>/dev/null \
    | awk '{printf "    %-12s %-40s %s\n", $1, $2, $4}' \
    || echo "    (kubectl no disponible en esta máquina)"
echo ""
echo -e "  Costo mientras esté encendido: ${YELLOW}~\$0.08 / hora (~\$60/mes)${NC}"
echo -e "  Recuerda apagarlo al terminar: ${BOLD}./scripts/infra-stop.sh${NC}"
echo ""
