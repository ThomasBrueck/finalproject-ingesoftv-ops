#!/bin/bash
# ==============================================================================
# CircleGuard - Azure Bootstrap Script for Terraform Remote Backend State
# ==============================================================================
set -e

# Configuración de nombres de recursos (modificables)
RESOURCE_GROUP_NAME="circleguard-tfstate-rg"
LOCATION="eastus"
STORAGE_ACCOUNT_NAME="circleguardtfstate$RANDOM" # El nombre debe ser único globalmente
CONTAINER_NAME="tfstate"

echo "=== 1. Iniciando sesión en Azure (si no está autenticado) ==="
if ! az account show &>/dev/null; then
    echo "Por favor, inicia sesión en la ventana del navegador que se abrirá..."
    az login
fi

echo "=== 2. Creando el Grupo de Recursos para el Estado Remoto ==="
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" --output table

echo "=== 3. Creando la Cuenta de Almacenamiento (Storage Account) ==="
echo "Nombre generado: $STORAGE_ACCOUNT_NAME"
az storage account create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$STORAGE_ACCOUNT_NAME" \
    --sku Standard_LRS \
    --encryption-services blob \
    --output table

echo "=== 4. Obteniendo la clave de la cuenta de almacenamiento ==="
ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query "[0].value" \
    --output tsv)

echo "=== 5. Creando el contenedor de almacenamiento (Blob Container) ==="
az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$ACCOUNT_KEY" \
    --output table

echo "=== Configuración Completada Exitosamente ==="
echo "Guarda los siguientes valores para configurar tus archivos 'backend.tf' de Terraform:"
echo "----------------------------------------------------------------------"
echo "resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "container_name       = \"$CONTAINER_NAME\""
echo "----------------------------------------------------------------------"
echo "Nota: El script genera un sufijo aleatorio en el nombre del storage account para evitar colisiones globales."
