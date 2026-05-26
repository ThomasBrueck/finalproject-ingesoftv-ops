# ==============================================================================
# CircleGuard - Bootstrap Azure Backend (PowerShell)
# Equivalente a bootstrap-backend.sh para Windows PowerShell
# ==============================================================================

$RESOURCE_GROUP_NAME = "circleguard-tfstate-rg"
$LOCATION            = "eastus"
$RANDOM_SUFFIX       = Get-Random -Minimum 10000 -Maximum 99999
$STORAGE_ACCOUNT_NAME = "cgtfstate$RANDOM_SUFFIX"
$CONTAINER_NAME      = "tfstate"
$SUBSCRIPTION_ID     = "8cd4e2ee-fbca-46b3-a3f5-57efa772ac64"

Write-Host "=== 1. Fijando suscripcion ===" -ForegroundColor Cyan
az account set --subscription $SUBSCRIPTION_ID
Write-Host "Suscripcion activa: $(az account show --query name -o tsv)" -ForegroundColor Green

Write-Host "`n=== 2. Creando Resource Group ===" -ForegroundColor Cyan
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION --subscription $SUBSCRIPTION_ID --output table

Write-Host "`n=== 3. Creando Storage Account: $STORAGE_ACCOUNT_NAME ===" -ForegroundColor Cyan
az storage account create `
    --name $STORAGE_ACCOUNT_NAME `
    --resource-group $RESOURCE_GROUP_NAME `
    --location $LOCATION `
    --sku Standard_LRS `
    --subscription $SUBSCRIPTION_ID `
    --output table

Write-Host "`n=== 4. Obteniendo clave del Storage Account ===" -ForegroundColor Cyan
$ACCOUNT_KEY = az storage account keys list `
    --account-name $STORAGE_ACCOUNT_NAME `
    --resource-group $RESOURCE_GROUP_NAME `
    --subscription $SUBSCRIPTION_ID `
    --query "[0].value" -o tsv

Write-Host "`n=== 5. Creando Blob Container: $CONTAINER_NAME ===" -ForegroundColor Cyan
az storage container create `
    --name $CONTAINER_NAME `
    --account-name $STORAGE_ACCOUNT_NAME `
    --account-key $ACCOUNT_KEY `
    --output table

Write-Host "`n=== COMPLETADO ===" -ForegroundColor Green
Write-Host "----------------------------------------------------------------------"
Write-Host "Copia estos valores en tus archivos backend.tf:"
Write-Host ""
Write-Host "  resource_group_name  = `"$RESOURCE_GROUP_NAME`""
Write-Host "  storage_account_name = `"$STORAGE_ACCOUNT_NAME`""
Write-Host "  container_name       = `"$CONTAINER_NAME`""
Write-Host "----------------------------------------------------------------------"
