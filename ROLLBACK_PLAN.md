# Plan de Rollback — CircleGuard (Ops)

## 1. Propósito

Documentar los procedimientos para restaurar la estabilidad del sistema desde la perspectiva de operaciones. Este plan cubre rollback a nivel de Kubernetes (aplicación), infraestructura (Terraform), imágenes de contenedor (ACR) y pipelines CI/CD.

## 2. Criterios de Activación

Se debe ejecutar un rollback cuando se cumple **cualquiera** de estas condiciones después de un despliegue:

| Síntoma | Acción |
|---|---|
| Health check del servicio responde `DOWN` tras deploy | Rollback inmediato |
| Smoke tests fallan en el pipeline | El pipeline bloquea la promoción automáticamente |
| Tasa de error > 5% en producción (monitoreado por gateway) | Rollback inmediato |
| `kubectl rollout status` timeout (300s) | Rollback inmediato |
| Vulnerabilidad CRITICAL descubierta post-deploy | Rollback o hotfix, lo que sea más rápido |
| Degradación de performance > 30% en latency p99 | Rollback y evaluar |

## 3. Rollback de Aplicación (Kubernetes)

### 3.1 Procedimiento

Todos los deployments de CircleGuard usan `RollingUpdate` con `maxUnavailable: 0` y `maxSurge: 1`, lo que garantiza que siempre hay al menos el número deseado de pods disponibles durante el despliegue.

```bash
# 1. Ver historial de revisiones del deployment
kubectl rollout history deployment/<service-name> -n production

# 2. Rollback a la revisión anterior
kubectl rollout undo deployment/<service-name> -n production

# 3. Verificar el estado del rollback
kubectl rollout status deployment/<service-name> -n production --timeout=300s

# 4. Verificar que los pods estén ready
kubectl get pods -l app=<service-name> -n production

# 5. Verificar que la imagen desplegada sea la anterior
kubectl describe deployment/<service-name> -n production | grep Image
```

### 3.2 Rollback a una revisión específica

```bash
# Listar revisiones
kubectl rollout history deployment/<service-name> -n production

# Rollback a revisión específica (ej: revisión 3)
kubectl rollout undo deployment/<service-name> -n production --to-revision=3
```

### 3.3 Post-rollback verification

```bash
# Smoke test manual
POD=$(kubectl get pod -l app=<service-name> -n production -o jsonpath='{.items[0].metadata.name}')
kubectl exec "$POD" -n production -- wget -qO- http://localhost:<port>/actuator/health

# Verificar que el rollout está completo
kubectl rollout status deployment/<service-name> -n production
```

## 4. Rollback de Infraestructura (Terraform)

### 4.1 Rollback a un estado anterior de Terraform

```bash
# 1. Listar los estados disponibles en el backend (Azure Storage)
az storage blob list --container-name tfstate --account-name <storage-account> --output table

# 2. Descargar un estado anterior
az storage blob download --container-name tfstate --name <env>.tfstate --file <env>.tfstate.backup --account-name <storage-account>

# 3. Forzar el estado local a la versión anterior
terraform state push <env>.tfstate.backup

# 4. Aplicar el estado anterior (esto crea/destruye recursos para converger)
terraform apply -auto-approve
```

### 4.2 Rollback usando `terraform destroy` y `terraform apply`

Para cambios pequeños y rápidos, es más práctico destruir el recurso problemático y recrearlo:

```bash
# Destruir solo el módulo/servicio afectado (si está modularizado)
terraform destroy -target module.<module_name> -auto-approve

# Re-aplicar desde el estado estable conocido
terraform apply -auto-approve
```

### 4.3 Prevención

- Siempre revisar `terraform plan` antes de `apply`
- Usar workspaces separados por ambiente (`dev`, `stage`, `prod`)
- Mantener el estado de Terraform en Azure Storage con versionado habilitado

## 5. Rollback de Imagen de Contenedor (ACR)

### 5.1 Identificar la imagen anterior

```bash
# Listar tags disponibles en ACR
az acr repository show-tags --name circleguardacrcore --repository circle-guard/<service-name> --output table

# La imagen anterior tiene el tag numérico inmediatamente anterior
```

### 5.2 Redeploy con imagen anterior

```bash
# Desplegar la imagen anterior directamente
kubectl set image deployment/<service-name> -n production \
  <service-name>=circleguardacrcore.azurecr.io/circle-guard/<service-name>:<tag-anterior>
```

## 6. Rollback de Pipeline CI/CD

### 6.1 Revertir un cambio en el pipeline

```bash
# Revertir el commit que modificó el pipeline
git revert <commit-hash>
git push origin master
```

### 6.2 Re-ejecutar un pipeline exitoso anterior

Desde GitHub Actions:
1. Ir a `Actions` → seleccionar workflow
2. Filtrar por `master` branch
3. Seleccionar la última ejecución exitosa
4. Click en `Re-run jobs`

## 7. Rollback Multi-servicio

Si un release afectó múltiples servicios, ejecutar rollback en orden inverso al despliegue:

```bash
# Orden típico de despliegue:
# 1. identity-service
# 2. auth-service
# 3. promotion-service
# 4. notification-service
# 5. form-service
# 6. file-service
# 7. dashboard-service
# 8. gateway-service

# Rollback en orden inverso
kubectl rollout undo deployment/circleguard-gateway-service -n production
kubectl rollout undo deployment/circleguard-dashboard-service -n production
# ... continuar hasta identity-service
```

## 8. Checklist de Rollback

- [ ] Identificar el servicio(s) afectado y el alcance del fallo
- [ ] Notificar al equipo (compañero vía Jira/comentario)
- [ ] Ejecutar `kubectl rollout undo` para rollback de aplicación
- [ ] Verificar health check post-rollback con `kubectl exec`
- [ ] Confirmar que la imagen desplegada es la correcta (`kubectl describe deployment`)
- [ ] Si hay cambio de DB, notificar al equipo de desarrollo para crear migración de fix
- [ ] Revertir commits en master con `git revert` si el cambio de código fue la causa
- [ ] Documentar la incidencia en Jira con causa raíz y acción preventiva
- [ ] Actualizar este documento si el procedimiento reveló mejoras

## 9. Post-Mortem

Dentro de las 24h siguientes al rollback:

1. Documentar causa raíz del fallo
2. Evaluar por qué no fue detectado en stage
3. Definir acción preventiva (mejorar pruebas, monitoreo, thresholds, etc.)
4. Agregar ticket en Jira para la acción preventiva
5. Actualizar el `ROLLBACK_PLAN.md` si aplica
