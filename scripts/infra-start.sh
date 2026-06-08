#!/bin/bash
# ==============================================================================
# CircleGuard — Encender infraestructura de Azure
#
# Qué hace: arranca el clúster AKS y la VM de Jenkins/SonarQube.
# PostgreSQL, Redis y Kafka en los ambientes que hayas desplegado vuelven
# a estar disponibles automáticamente.
#
# Uso: ./scripts/infra-start.sh
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
echo -e "${BOLD}║       CircleGuard — Encender infraestructura         ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# ── 0. Verificar Azure CLI ────────────────────────────────────────────────────
if ! command -v az &>/dev/null; then
    echo -e "${RED}✗ Azure CLI no está instalado.${NC}"
    echo -e "  Instálalo: ${BOLD}curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash${NC}"
    exit 1
fi

# ── 1. Sesión en Azure ────────────────────────────────────────────────────────
echo -e "${BLUE}[1/5]${NC} Verificando sesión en Azure..."
if ! az account show --subscription "$SUBSCRIPTION_ID" &>/dev/null; then
    echo -e "${YELLOW}No hay sesión activa. Iniciando login...${NC}"
    az login --use-device-code
fi
az account set --subscription "$SUBSCRIPTION_ID"
echo -e "${GREEN}✓${NC} Sesión activa."
echo ""

# ── Helper: estado del clúster ────────────────────────────────────────────────
get_aks_state() {
    az aks show --name "$CLUSTER_NAME" --resource-group "$AKS_RG" \
        --query "powerState.code" --output tsv 2>/dev/null || echo "NotFound"
}

# Helper: estado de la VM Jenkins
get_vm_state() {
    az vm get-instance-view --name "$JENKINS_VM" --resource-group "$JENKINS_RG" \
        --query "instanceView.statuses[1].displayStatus" --output tsv 2>/dev/null || echo "NotFound"
}

# ── 2. Encender VM de Jenkins ─────────────────────────────────────────────────
echo -e "${BLUE}[2/5]${NC} Verificando VM de Jenkins..."

VM_STATE=$(get_vm_state)

if [ "$VM_STATE" = "NotFound" ]; then
    echo -e "${YELLOW}  ⚠ VM Jenkins no encontrada. Si es la primera vez, créala con:${NC}"
    echo -e "     ${BOLD}cd terraform && make tools-apply${NC}"
    echo -e "  Continuando sin VM de Jenkins..."
    JENKINS_STARTED=false
elif echo "$VM_STATE" | grep -q "running"; then
    echo -e "${GREEN}✓ VM Jenkins ya está corriendo.${NC}"
    JENKINS_STARTED=true
else
    echo -e "  Estado actual: ${YELLOW}$VM_STATE${NC} — encendiendo..."
    az vm start --name "$JENKINS_VM" --resource-group "$JENKINS_RG" \
        --subscription "$SUBSCRIPTION_ID" --no-wait
    JENKINS_STARTED=true
fi
echo ""

# ── 3. Verificar y encender AKS ──────────────────────────────────────────────
echo -e "${BLUE}[3/5]${NC} Verificando clúster AKS..."

AKS_STATE=$(get_aks_state)

if [ "$AKS_STATE" = "NotFound" ]; then
    echo -e "${RED}✗ Clúster '$CLUSTER_NAME' no encontrado. Créalo con: make core-apply${NC}"
    exit 1
fi

if [ "$AKS_STATE" = "Stopping" ]; then
    echo -e "${YELLOW}Apagado en progreso. Esperando que termine...${NC}"
    while [ "$(get_aks_state)" != "Stopped" ]; do
        echo -ne "  Estado: $(get_aks_state)...\r"; sleep 10
    done
    echo ""; AKS_STATE="Stopped"
fi

if [ "$AKS_STATE" = "Running" ]; then
    echo -e "${GREEN}✓ AKS ya está corriendo.${NC}"
else
    echo -e "  Estado: ${YELLOW}$AKS_STATE${NC} — encendiendo AKS..."
    az aks start --name "$CLUSTER_NAME" --resource-group "$AKS_RG" \
        --subscription "$SUBSCRIPTION_ID" --no-wait
    echo -e "  Esperando que el clúster esté listo (~5 minutos)..."
    while [ "$(get_aks_state)" != "Running" ]; do
        echo -ne "  Estado: $(get_aks_state)...\r"; sleep 10
    done
    echo ""
fi
echo ""

# ── 4. Actualizar kubeconfig ──────────────────────────────────────────────────
echo -e "${BLUE}[4/5]${NC} Actualizando kubeconfig local..."
az aks get-credentials --name "$CLUSTER_NAME" --resource-group "$AKS_RG" \
    --subscription "$SUBSCRIPTION_ID" --overwrite-existing
echo ""

# ── 5. Esperar VM Jenkins y mostrar URLs ──────────────────────────────────────
echo -e "${BLUE}[5/5]${NC} Obteniendo información de Jenkins..."

if [ "$JENKINS_STARTED" = "true" ]; then
    # Esperar a que la VM esté running
    echo -ne "  Esperando VM Jenkins..."
    for i in $(seq 1 30); do
        VM_STATE=$(get_vm_state)
        echo "$VM_STATE" | grep -q "running" && break
        echo -ne "  Estado: $VM_STATE...\r"; sleep 10
    done
    echo ""
    JENKINS_IP=$(az vm list-ip-addresses --name "$JENKINS_VM" \
        --resource-group "$JENKINS_RG" \
        --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" \
        --output tsv 2>/dev/null || echo "N/A")
else
    JENKINS_IP="N/A"
fi

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║         ✓ Infraestructura lista para trabajar                ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}AKS Cluster:${NC}"
kubectl get nodes --no-headers 2>/dev/null \
    | awk '{printf "    %-30s %s\n", $1, $2}' \
    || echo "    (kubectl no disponible localmente)"
echo ""

if [ "$JENKINS_IP" != "N/A" ] && [ -n "$JENKINS_IP" ]; then
    echo -e "  ${BOLD}CI/CD Tools:${NC}"
    echo -e "    Jenkins:   ${BLUE}http://${JENKINS_IP}:8080${NC}"
    echo -e "    SonarQube: ${BLUE}http://${JENKINS_IP}:9000${NC}"
    echo -e "    SSH:       ${BOLD}ssh azureuser@${JENKINS_IP}${NC}"
    echo ""
    echo -e "  ${YELLOW}Nota:${NC} Si es la primera vez encendiendo, espera ~8 min"
    echo -e "  para que Jenkins y SonarQube terminen de inicializar."
fi

echo ""
echo -e "  Costo mientras esté encendido:"
echo -e "    AKS:     ${YELLOW}~\$0.10/h${NC} (~\$70/mes si estuviera 24/7)"
echo -e "    Jenkins: ${YELLOW}~\$0.04/h${NC} (~\$3 real si apagas al terminar)"
echo ""
echo -e "  Recuerda apagarlo al terminar: ${BOLD}./scripts/infra-stop.sh${NC}"
echo ""
