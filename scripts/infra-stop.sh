#!/bin/bash
# ==============================================================================
# CircleGuard — Apagar infraestructura de Azure
#
# Qué hace: detiene el clúster AKS y deallocate la VM Jenkins para que Azure
# deje de cobrar. Los datos y configuración quedan guardados.
#
# Uso: ./scripts/infra-stop.sh
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ── Configuración ──────────────────────────────────────────────────────────────
CLUSTER_NAME="circleguard-aks"
AKS_RG="circleguard-core-rg"
JENKINS_VM="circleguard-jenkins-vm"
JENKINS_RG="circleguard-jenkins-rg"
SUBSCRIPTION_ID="8cd4e2ee-fbca-46b3-a3f5-57efa772ac64"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       CircleGuard — Apagar infraestructura           ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# ── 0. Verificar Azure CLI ────────────────────────────────────────────────────
if ! command -v az &>/dev/null; then
    echo -e "${RED}✗ Azure CLI no está instalado.${NC}"
    echo -e "  Instálalo: ${BOLD}curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash${NC}"
    exit 1
fi

# ── 1. Sesión en Azure ────────────────────────────────────────────────────────
echo -e "${BLUE}[1/4]${NC} Verificando sesión en Azure..."
if ! az account show --subscription "$SUBSCRIPTION_ID" &>/dev/null; then
    echo -e "${YELLOW}No hay sesión activa. Iniciando login...${NC}"
    az login --use-device-code
fi
az account set --subscription "$SUBSCRIPTION_ID"
echo -e "${GREEN}✓${NC} Sesión activa."
echo ""

# Helper: estado del clúster
get_aks_state() {
    az aks show --name "$CLUSTER_NAME" --resource-group "$AKS_RG" \
        --query "powerState.code" --output tsv 2>/dev/null || echo "NotFound"
}

# Helper: estado de la VM
get_vm_state() {
    az vm get-instance-view --name "$JENKINS_VM" --resource-group "$JENKINS_RG" \
        --query "instanceView.statuses[1].displayStatus" --output tsv 2>/dev/null || echo "NotFound"
}

# ── 2. Deallocate VM de Jenkins ───────────────────────────────────────────────
# 'deallocate' = sin cómputo cobrado (distinto de 'stop' que sí cobra)
echo -e "${BLUE}[2/4]${NC} Apagando VM de Jenkins..."

VM_STATE=$(get_vm_state)

if [ "$VM_STATE" = "NotFound" ]; then
    echo -e "  ${YELLOW}VM Jenkins no encontrada — omitiendo.${NC}"
elif echo "$VM_STATE" | grep -q "deallocated"; then
    echo -e "${GREEN}✓ VM Jenkins ya está desasignada (sin costo).${NC}"
else
    echo -e "  Estado: ${YELLOW}$VM_STATE${NC} — desasignando (sin costo de cómputo)..."
    az vm deallocate --name "$JENKINS_VM" --resource-group "$JENKINS_RG" \
        --subscription "$SUBSCRIPTION_ID" --no-wait
    echo -e "  Orden enviada. La VM quedará desasignada en ~2 minutos."
fi
echo ""

# ── 3. Apagar AKS ─────────────────────────────────────────────────────────────
echo -e "${BLUE}[3/4]${NC} Apagando clúster AKS..."

AKS_STATE=$(get_aks_state)

if [ "$AKS_STATE" = "NotFound" ]; then
    echo -e "${RED}✗ Clúster no encontrado. Verifica con: make core-apply${NC}"
    exit 1
fi

if [ "$AKS_STATE" = "Stopped" ]; then
    echo -e "${GREEN}✓ AKS ya está detenido.${NC}"
elif [ "$AKS_STATE" = "Stopping" ]; then
    echo -e "${YELLOW}Apagado ya en progreso...${NC}"
    while [ "$(get_aks_state)" != "Stopped" ]; do
        echo -ne "  Estado: $(get_aks_state)...\r"; sleep 10
    done
    echo ""
else
    az aks stop --name "$CLUSTER_NAME" --resource-group "$AKS_RG" \
        --subscription "$SUBSCRIPTION_ID" --no-wait
    echo -e "  Esperando confirmación de apagado (~3 minutos)..."
    while [ "$(get_aks_state)" != "Stopped" ]; do
        echo -ne "  Estado: $(get_aks_state)...\r"; sleep 10
    done
    echo ""
fi
echo ""

# ── 4. Resumen ────────────────────────────────────────────────────────────────
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║  ✓ Infraestructura detenida. Azure ya no cobra cómputo. ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  AKS:              ${GREEN}Detenido (costo ~\$0)${NC}"
echo -e "  VM Jenkins:       ${GREEN}Desasignada (costo ~\$0 por cómputo)${NC}"
echo -e "  Discos y datos:   ${BOLD}Guardados${NC} (costo de almacenamiento, centavos/mes)"
echo ""
echo -e "  Para volver a encender: ${BOLD}./scripts/infra-start.sh${NC}"
echo ""
