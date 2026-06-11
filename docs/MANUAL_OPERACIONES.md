# Manual de Operaciones — CircleGuard

Guía operativa básica del sistema. Complementa `ROLLBACK_PLAN.md` (rollback) y
`01-metodologia-agil-branching.md` (flujo de trabajo).

## 1. Arquitectura operativa

- **Cluster:** AKS `circleguard-aks` (RG `circleguard-core-rg`, eastus2), 2 nodos `Standard_D2s_v3`.
- **Namespaces:** `dev` (integración + infra compartida), `stage` (pre-producción + observabilidad), `production`.
- **Registry:** ACR `circleguardacrcore.azurecr.io`, imágenes `circle-guard/<servicio>:vX.Y.Z` y `:latest`.
- **GitOps:** este repo (ops) es la fuente de verdad de manifiestos y pipeline; el repo dev contiene el código y dispara los pipelines.

## 2. Acceso al cluster

```bash
az login
az aks get-credentials -g circleguard-core-rg -n circleguard-aks
kubectl get pods -n dev|stage|production
```

## 3. Encendido / apagado de la infraestructura

```bash
./scripts/infra-stop.sh    # detiene el VMSS (ahorro fuera de horario)
./scripts/infra-start.sh   # arranca el VMSS y espera nodos Ready
```

## 4. Despliegues

El despliegue normal es **vía pipeline** (merge a master en el repo dev):
CI (build, tests, Sonar, Trivy) → Deploy DEV → Deploy STAGE → E2E → aprobación
manual → Deploy PROD (+ tag SemVer + Release Notes automáticas).

Despliegue manual de emergencia de un servicio:

```bash
kubectl apply -f k8s/<ambiente>/<servicio>-deployment.yaml
kubectl rollout status deployment/<servicio> -n <ambiente>
```

## 5. Rollback

Ver `ROLLBACK_PLAN.md`. Resumen:

```bash
# A la revisión anterior del deployment
kubectl rollout undo deployment/<servicio> -n production
# A una versión específica (tag SemVer del ACR)
kubectl set image deployment/<servicio> <servicio>=circleguardacrcore.azurecr.io/circle-guard/<servicio>:vX.Y.Z -n production
```

## 6. Observabilidad (namespace stage)

| Herramienta | Acceso (port-forward) | Uso |
|---|---|---|
| Grafana | `kubectl port-forward -n stage svc/grafana 3000:3000` → http://localhost:3000 | Dashboards (servicios, JVM, negocio) |
| Prometheus | `kubectl port-forward -n stage svc/prometheus 9090:9090` | Métricas crudas / alertas |
| Kibana | `kubectl port-forward -n stage svc/kibana 5601:5601` | Logs centralizados (índice `circleguard-logs-*`) |
| Jaeger | `kubectl port-forward -n stage svc/jaeger-query 16686:16686` | Tracing distribuido |
| Alertmanager | `kubectl port-forward -n stage svc/alertmanager 9093:9093` | Estado de alertas |

Las alertas críticas (servicio caído, error rate, latencia) están definidas en
el ConfigMap `prometheus-rules` (`k8s/stage/observability/prometheus.yaml`).

## 7. Troubleshooting común

| Síntoma | Diagnóstico | Acción |
|---|---|---|
| Pod `CrashLoopBackOff` | `kubectl logs <pod> -n <ns> --previous` | Ver causa en el log; si es imagen rota → rollback |
| Pod `Pending` | `kubectl describe pod` → "Insufficient cpu/memory" | Revisar requests; apagar cargas no esenciales |
| `Multi-Attach error` en PVC | Deployment con PVC RWO en RollingUpdate | Los manifests usan `strategy: Recreate`; borrar pod viejo si quedó colgado |
| Servicio responde 503 en `/actuator/health` | Aún inicializando (probes SCRUM-43) | Esperar; readiness gate del pipeline lo cubre |
| Crash con "Unrecognized setting" (Neo4j) o puerto `tcp://...` (logback) | Service links de K8s inyectando env vars | Los manifests llevan `enableServiceLinks: false`; verificar que no se haya quitado |
| "too many clients" en Postgres | Pool HikariCP × pods > max_connections | Manifests fijan `MAXIMUM_POOL_SIZE=3` y Postgres `max_connections=200` |
| Pipeline falla en checkout del repo ops | Ref inexistente | Los checkouts del pipeline usan `ref: master` fijo |

## 8. Bases de datos

- **Postgres** (`postgres-dev-postgresql.dev`): bases `circleguard_auth|dashboard|form|identity|promotion`.
  ```bash
  kubectl exec -it -n dev deploy/postgres-dev-postgresql -- psql -U postgres -d circleguard_auth
  ```
- **Neo4j** (`neo4j-dev.dev:7687`, usuario `neo4j`): grafo de contactos/círculos.
- **Redis** (`redis-dev-master.dev:6379`): caché de estado de salud (clave `user:status:<id>`).
- **Kafka** (`kafka-dev.dev:9092`): eventos `survey.submitted`, `promotion.status.changed`, `certificate.validated`.

## 9. Secretos

Los secretos de cada ambiente (`circleguard-stage-secrets`, `circleguard-production-secrets`)
los crea el pipeline en cada deploy (DB, LDAP, JWT, QR). Para rotarlos: editar el
step "Deploy to <AMBIENTE> namespace" en `.github/workflows/_cicd-pipeline.yml`
(idealmente migrar a GitHub Secrets → `--from-literal=$VAR`).

## 10. Usuarios de prueba

| Usuario | Password | Rol | Permisos clave |
|---|---|---|---|
| `staff_guard` | `password` | GATE_STAFF | escaneo QR |
| `health_user` | `password` | HEALTH_CENTER | `identity:lookup`, reporte de casos |
| `super_admin` | `password` | todos | todos |
