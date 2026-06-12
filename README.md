# 🛡️ CircleGuard — Repositorio de Operaciones (Ops / GitOps)

**Absolute Privacy. High-Speed Containment. Secure Campus.**

CircleGuard es un sistema universitario de rastreo de contactos y "fencing" de salud que identifica grupos de contacto interconectados ("Círculos") y aplica cuarentenas rápidas preservando el anonimato individual.

Este repositorio (**ops**) es la **fuente de verdad de la plataforma**: contiene la Infraestructura como Código (Terraform), los manifiestos de Kubernetes de los tres ambientes, el pipeline de CI/CD reutilizable, el stack de observabilidad y la documentación operativa. El código de los microservicios vive en el repo de aplicación `finalproject-ingesoftv-dev`.

> Arquitectura GitOps de repositorios separados: este repo nunca contiene lógica de negocio; el repo dev nunca contiene manifiestos de infraestructura.

---

## 📑 Tabla de contenido

1. [Arquitectura](#-arquitectura)
2. [Estructura del repositorio](#-estructura-del-repositorio)
3. [Stack tecnológico](#-stack-tecnológico)
4. [Documentación completa del proyecto](#-documentación-completa-del-proyecto)
5. [Manual de operaciones básico](#-manual-de-operaciones-básico)
6. [Pipeline de CI/CD](#-pipeline-de-cicd)
7. [Cumplimiento del taller](#-cumplimiento-del-taller)

---

## 🏗️ Arquitectura

CircleGuard es una **arquitectura de microservicios** (8 servicios Spring Boot) sobre un **modelo de datos híbrido** (PostgreSQL, Neo4j, Redis, Kafka, LDAP), desplegada en **Azure Kubernetes Service (AKS)**.

- **Diagramas:** `docs/arquitectura-infraestructura.drawio` (ábrelo en https://app.diagrams.net). Pestaña 1 = plataforma y CI/CD; pestaña 2 = servicios, datos y eventos.
- **Un solo cluster, tres namespaces:** `dev` (integración + capa de datos compartida), `stage` (pre-producción + observabilidad), `production`.
- **Entrada pública:** `ingress-nginx` con TLS termina HTTPS hacia el gateway y Grafana.

### Microservicios y puertos

| Servicio | Puerto | Datos / dependencias |
|---|---|---|
| gateway-service | 8087 | Redis (estado de salud para validar QR) |
| auth-service | 8180 | PostgreSQL `auth` + LDAP · REST → identity (Bulkhead) |
| identity-service | 8083 | PostgreSQL `identity` · Kafka (auditoría) |
| promotion-service | 8088 | PostgreSQL `promotion` + Neo4j + Redis + Kafka |
| form-service | 8086 | PostgreSQL `form` + Kafka |
| dashboard-service | 8084 | PostgreSQL `dashboard` · REST → promotion |
| notification-service | 8082 | Kafka (consumidor) · REST → auth |
| file-service | 8085 | Almacenamiento de archivos |

**Eventos Kafka:** `survey.submitted`, `promotion.status.changed`, `certificate.validated`, `audit.identity.accessed`.

---

## 📂 Estructura del repositorio

```
.
├── terraform/                      # Infraestructura como Código
│   ├── modules/
│   │   ├── azure_infrastructure/   # AKS + ACR + RG + AcrPull
│   │   └── kubernetes_services/    # servicios de datos por ambiente
│   └── environments/               # core, dev, stage, prod (backend remoto azurerm)
├── k8s/                            # Manifiestos Kubernetes
│   ├── dev/                        # 8 servicios + postgres/redis/neo4j/kafka/ldap
│   ├── stage/                      # 8 servicios + observability/ + ingress TLS
│   └── production/                 # 8 servicios
├── .github/workflows/
│   └── _cicd-pipeline.yml          # pipeline reutilizable (CI + CD a 3 ambientes)
├── scripts/                        # compute-semver, generate-release-notes, infra start/stop
├── docs/                           # diagramas, costos, manual de operaciones
├── 01-metodologia-agil-branching.md
├── 03-patrones-diseno.md
└── ROLLBACK_PLAN.md
```

---

## 🛠️ Stack tecnológico

| Capa | Tecnología |
|---|---|
| Backend | Spring Boot 3.4 / Java 21 |
| Base relacional | PostgreSQL 17 (5 bases) |
| Base de grafos | Neo4j 5 Community (rastreo de contactos) |
| Caché | Redis 7 |
| Bus de eventos | Apache Kafka 3.7 (modo KRaft) |
| Directorio | OpenLDAP |
| Orquestación | Kubernetes (AKS Free tier, 2× Standard_D2s_v3) |
| Registro | Azure Container Registry (Basic) |
| IaC | Terraform (backend remoto azurerm) |
| CI/CD | GitHub Actions |
| Calidad / Seguridad | SonarCloud · Trivy · OWASP ZAP |
| Observabilidad | Prometheus · Grafana · ELK · Jaeger · Alertmanager |

---

## 📚 Documentación completa del proyecto

Toda la documentación está versionada en este repo:

| Documento | Contenido |
|---|---|
| `01-metodologia-agil-branching.md` | Scrum, Jira, estrategia de branching (Trunk-Based en ops / GitHub Flow en dev), Conventional Commits, reglas de protección |
| `03-patrones-diseno.md` | Patrones existentes (API Gateway, Repository, Service Layer, Pub/Sub) y añadidos (Bulkhead, Feature Toggle, Cache-Aside, External Configuration) |
| `docs/arquitectura-infraestructura.drawio` | Diagramas de infraestructura y de aplicación |
| `docs/MANUAL_OPERACIONES.md` | Manual de operaciones extendido |
| `docs/COSTOS.md` | Inventario de recursos Azure, costo mensual (~$170) y estrategias de ahorro |
| `ROLLBACK_PLAN.md` | Criterios de activación y procedimientos de rollback (app, infra, imagen, pipeline) |

### Resumen por requisito del taller

- **Metodología y branching** → `01-metodologia-agil-branching.md`
- **Terraform (IaC)** → `terraform/` (módulos + ambientes + backend remoto)
- **Patrones de diseño** → `03-patrones-diseno.md`
- **CI/CD** → `.github/workflows/_cicd-pipeline.yml`
- **Observabilidad** → `k8s/stage/observability/`
- **Change Management / Release Notes** → `ROLLBACK_PLAN.md` + `scripts/generate-release-notes.sh`
- **Costos / operación** → `docs/COSTOS.md`, `docs/MANUAL_OPERACIONES.md`

---

## 🔧 Manual de operaciones básico

### 1. Acceso al cluster
```bash
az login
az aks get-credentials -g circleguard-core-rg -n circleguard-aks
kubectl get pods -n dev    # | -n stage | -n production
```

### 2. Encendido / apagado (ahorro de costos)
```bash
./scripts/infra-stop.sh     # detiene el VMSS del cluster
./scripts/infra-start.sh    # arranca el VMSS y espera nodos Ready
```

### 3. Provisionar infraestructura (Terraform)
```bash
cd terraform/environments/core   # o dev | stage | prod
terraform init                   # backend remoto azurerm
terraform plan
terraform apply
```

### 4. Despliegue
El despliegue normal es **automático vía pipeline** (merge a master en el repo dev): CI → DEV → STAGE → E2E → aprobación manual → PROD.

Despliegue manual de emergencia de un servicio:
```bash
kubectl apply -f k8s/<ambiente>/<servicio>-deployment.yaml
kubectl rollout status deployment/<servicio> -n <ambiente>
```

### 5. Rollback (ver `ROLLBACK_PLAN.md`)
```bash
kubectl rollout undo deployment/<servicio> -n production
# o a una versión específica del ACR:
kubectl set image deployment/<servicio> \
  <servicio>=circleguardacrcore.azurecr.io/circle-guard/<servicio>:vX.Y.Z -n production
```

### 6. Observabilidad (namespace stage)
```bash
kubectl port-forward -n stage svc/grafana 3000:3000        # http://localhost:3000
kubectl port-forward -n stage svc/prometheus 9090:9090     # targets + alertas
kubectl port-forward -n stage svc/kibana 5601:5601         # logs (índice circleguard-logs-*)
kubectl port-forward -n stage svc/jaeger-query 16686:16686 # trazas
```

### 7. Bases de datos
- **PostgreSQL** (`postgres-dev-postgresql.dev`): bases `circleguard_auth|dashboard|form|identity|promotion`.
  ```bash
  kubectl exec -it -n dev deploy/postgres-dev-postgresql -- psql -U postgres -d circleguard_auth
  ```
- **Neo4j** (`neo4j-dev.dev:7687`, usuario `neo4j`) · **Redis** (`redis-dev-master.dev:6379`) · **Kafka** (`kafka-dev.dev:9092`).

### 8. Secretos
Los secretos de cada ambiente (`circleguard-stage-secrets`, `circleguard-production-secrets`) los crea el pipeline en cada deploy. Las credenciales de CI viven como **GitHub Secrets**; ninguna está hardcodeada.

### 9. Usuarios de prueba
| Usuario | Password | Rol |
|---|---|---|
| `staff_guard` | `password` | GATE_STAFF |
| `health_user` | `password` | HEALTH_CENTER |
| `super_admin` | `password` | todos |

### 10. Troubleshooting rápido
| Síntoma | Acción |
|---|---|
| Pod `CrashLoopBackOff` | `kubectl logs <pod> -n <ns> --previous` |
| Pod `Pending` ("Insufficient cpu") | revisar requests / apagar cargas no esenciales |
| `Multi-Attach error` en PVC | los manifests usan `strategy: Recreate`; borrar pod colgado |
| Crash "Unrecognized setting" / puerto `tcp://...` | service links de K8s → los manifests llevan `enableServiceLinks: false` |
| "too many clients" en Postgres | pool HikariCP limitado a 3 + `max_connections=200` |

---

## 🚀 Pipeline de CI/CD

`_cicd-pipeline.yml` es un workflow reutilizable invocado por cada servicio desde el repo dev. Etapas:

1. **CI** — build (Gradle/JDK 21), pruebas, cobertura JaCoCo, versión semántica, build de imagen, push a ACR, **Trivy** (CRITICAL/HIGH bloqueante).
2. **Deploy DEV** — automático; despliega capa de datos + servicio.
3. **Deploy STAGE** — automático; despliega servicio + stack de observabilidad + Ingress TLS.
4. **E2E** — 31 pruebas contra stage; **gate bloqueante** para producción.
5. **Deploy PROD** — **aprobación manual** (GitHub Environment con revisores); al terminar crea tag `servicio/vX.Y.Z` + GitHub Release con notas automáticas.
6. **notify-failure** — abre un GitHub Issue si cualquier etapa falla.

SonarCloud (Quality Gate ≥80%) corre en un workflow aparte del repo dev, una vez por commit.

---

## ✅ Cumplimiento del taller

| Sección | Estado | Dónde |
|---|---|---|
| 1. Ágil + Branching | ✅ | `01-metodologia-agil-branching.md`, Jira |
| 2. Terraform (IaC) | ✅ | `terraform/` |
| 3. Patrones de diseño | ✅ | `03-patrones-diseno.md` |
| 4. CI/CD avanzado | ✅ | `.github/workflows/` |
| 5. Pruebas completas | ✅ | repo dev (`e2e/`, `tests/`) |
| 6. Change Mgmt + Release Notes | ✅ | `ROLLBACK_PLAN.md`, `scripts/` |
| 7. Observabilidad | ✅ | `k8s/stage/observability/` |
| 8. Seguridad | ✅ | Trivy, Secrets, RBAC, TLS |
| 9. Documentación | ✅ | `docs/`, este README |

---

## 🔐 Privacidad y cumplimiento

- **Cumplimiento FERPA:** las identidades reales nunca se almacenan en el grafo de contactos.
- **Derecho al olvido:** purga completa de datos vía el Identity Vault.
- **Privacidad temporal:** las aristas de contacto se purgan automáticamente tras 14 días.
