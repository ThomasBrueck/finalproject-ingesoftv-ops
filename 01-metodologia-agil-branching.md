# 1. Metodología Ágil y Estrategia de Branching

## 1. Metodología Ágil: Scrum

### 1.1 Marco de Trabajo

El proyecto CircleGuard se desarrolla con **Scrum adaptado para equipos pequeños** (2 integrantes). Scrum fue elegido sobre Kanban porque el alcance del proyecto está acotado en el tiempo (semestre académico) y se beneficia de ciclos de entrega fijos (sprints) que permiten revisar y re-priorizar entre cada iteración.


### 1.2 Herramienta: Jira

Se usa **Jira Software** con un tablero **Scrum** (no Kanban) para gestionar el backlog y los sprints.

**Jerarquía de ítems en Jira:**

```
Epic
 └── Historia de Usuario (Story)
      └── Subtarea (Sub-task)  ← opcional para tareas técnicas grandes
```

**Epics definidas para el proyecto:**

| Epic | Descripción |
|---|---|
| `EP-1` Infraestructura como Código | Terraform, módulos, ambientes dev/stage/prod |
| `EP-2` CI/CD Avanzado | Pipelines Jenkins, SonarQube, Trivy, release notes |
| `EP-3` Patrones de Diseño | Circuit Breaker, Feature Toggle, External Config |
| `EP-4` Pruebas Completas | Unitarias, integración, E2E, rendimiento, seguridad |
| `EP-5` Observabilidad | Prometheus, Grafana, ELK Stack, tracing distribuido |
| `EP-6` Seguridad | RBAC, TLS, gestión de secretos, escaneo continuo |

**Convención de etiquetas:**

- `backend`, `infra`, `ci-cd`, `testing`, `docs`, `security`
- Prioridad: `P1-critical`, `P2-high`, `P3-medium`, `P4-low`

### 1.3 Sprints

Duración: **1 semana por sprint**. Se realizan al menos 2 iteraciones completas durante el desarrollo del proyecto.


### 1.5 Ceremonias (adaptadas a equipo de 2)

| Ceremonia | Frecuencia | Duración | Artefacto |
|---|---|---|---|
| Sprint Planning | Inicio de cada sprint | 1 hora | Sprint backlog en Jira |
| Daily Standup | Diario (async vía comentarios Jira) | 15 min | Actualización de tarjetas |
| Sprint Review | Final de cada sprint | 30 min | Demo del incremento |
| Sprint Retrospective | Final de cada sprint | 30 min | Action items en Jira |

### 1.6 Definition of Done (DoD)

Un ítem del backlog se considera **Done** cuando:

- [ ] El código fue revisado mediante Pull Request (mínimo 1 aprobación)
- [ ] Los tests unitarios pasan en el pipeline de CI
- [ ] La cobertura de código no decrece respecto al sprint anterior
- [ ] SonarQube no reporta nuevos issues de nivel `BLOCKER`
- [ ] El cambio está desplegado en el entorno correspondiente (dev/stage/prod)
- [ ] La historia de Jira está en estado `Done` con comentario de evidencia

---

## 2. Estrategia de Branching: Trunk-Based Development con GitOps

### 2.1 Arquitectura GitOps — Repositorios Separados

Se adopta el patrón **GitOps con repositorios separados**, una práctica ampliamente recomendada para mantener una separación clara entre el código de la aplicación y la configuración de infraestructura/despliegue.

```
┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│   Repo: circle-guard-public     │    │   Repo: finalproject-ingesoftv  │
│   (Código de la Aplicación)     │    │   -ops  (Infraestructura/Ops)   │
│                                 │    │                                 │
│  - Microservicios Spring Boot   │    │  - Pipelines Jenkins            │
│  - Frontend Expo/React Native   │    │  - Manifiestos Kubernetes       │
│  - Tests unitarios/integración  │    │  - Terraform (IaC)              │
│  - Dockerfiles de cada servicio │    │  - docker-compose.*             │
│                                 │    │  - Scripts de operaciones       │
│  Branch principal: main         │    │  - Branch principal: master     │
└─────────────────────────────────┘    └─────────────────────────────────┘
           │                                         │
           └─────────────┬───────────────────────────┘
                         │
              Jenkins observa ambos repos
              y dispara los pipelines correspondientes
```

**Por qué repositorios separados:**

- Permite cambiar la infraestructura sin tocar el código de la app y viceversa.
- Los pipelines de CI/CD de la app no reescriben los manifiestos de K8s directamente; el ops-repo es la fuente de verdad del estado del cluster.
- Auditoría clara: se sabe si un cambio fue de negocio (app-repo) o de plataforma (ops-repo).
- Equipos con distinto ritmo: la infra puede avanzar independientemente de los sprints de features.

### 2.2 Trunk-Based Development

Se adopta **Trunk-Based Development (TBD)** en lugar de GitFlow o GitHub Flow. En TBD existe una única rama de integración continua (`main` / `master`) llamada **trunk**, y todas las ramas de trabajo son de corta duración.

#### Principios Clave

| Principio | Descripción |
|---|---|
| **Trunk único** | `main` (app-repo) y `master` (ops-repo) son las únicas ramas permanentes |
| **Ramas de corta duración** | Las feature branches duran máximo 1-2 días; se integran al trunk vía PR |
| **Integración continua real** | Cada merge al trunk dispara el pipeline de CI automáticamente |
| **Sin ramas de release** | El trunk ES la línea de release; los ambientes se controlan por pipeline, no por ramas |
| **Feature Flags** | Los features incompletos se ocultan con flags en lugar de vivir en ramas largas |

#### Por qué TBD sobre GitFlow

GitFlow introduce ramas `develop`, `release/*`, `hotfix/*` que añaden overhead de merges y conflictos frecuentes. Con un equipo de 2 personas y un semestre de tiempo, TBD simplifica el flujo:

- Sin "merge hell" entre `develop` y `release`.
- El estado de `main`/`master` siempre es desplegable.
- Los ambientes (dev, stage, prod) se diferencian por **pipeline** y **configuración**, no por rama.
- Compatible directamente con el esquema de Jenkinsfiles ya implementado (`Jenkinsfile.dev.*`, `Jenkinsfile.stage.*`, `Jenkinsfile.master.*`).

### 2.3 Estructura de Ramas

```
main / master  (trunk — rama permanente)
    │
    ├── feat/JIRA-XX-descripcion-corta     ← feature branch (max 2 días)
    ├── fix/JIRA-XX-descripcion-del-bug    ← bug fix branch
    └── chore/JIRA-XX-tarea-tecnica        ← tarea de mantenimiento/infra
```

**Convenciones de nombrado:**

| Prefijo | Cuándo usarlo | Ejemplo |
|---|---|---|
| `feat/` | Nueva funcionalidad | `feat/INGESOFTV-42-terraform-eks-module` |
| `fix/` | Corrección de bug | `fix/INGESOFTV-55-jenkins-stage-rollout` |
| `chore/` | Mantenimiento, dependencias, docs | `chore/INGESOFTV-61-update-helm-charts` |
| `test/` | Añadir/mejorar pruebas sin cambio de lógica | `test/INGESOFTV-70-e2e-gateway-flow` |

El número `INGESOFTV-XX` corresponde al ID del ticket en Jira, permitiendo trazabilidad directa entre código y backlog.

### 2.4 Flujo de Trabajo Completo

```
 Developer                  Git Remote                   Jenkins CI
     │                          │                             │
     │── git checkout -b feat/  │                             │
     │   JIRA-XX-descripcion    │                             │
     │                          │                             │
     │   (trabaja, commits)     │                             │
     │── git push origin feat/  │                             │
     │   JIRA-XX-descripcion ──►│                             │
     │                          │                             │
     │── Abre Pull Request ─────►│                             │
     │   (hacia main/master)    │── Webhook dispara ─────────►│
     │                          │                             │── Lint
     │                          │                             │── Unit Tests
     │                          │                             │── SonarQube
     │                          │◄── Estado CI (pass/fail) ───│
     │                          │                             │
     │── Review + Approve PR ──►│                             │
     │── Merge to trunk ────────►│                             │
     │                          │── Webhook post-merge ──────►│
     │                          │                             │── Build & Push Image
     │                          │                             │── Deploy to DEV
     │                          │                             │── Smoke Test DEV
     │                          │                             │
     │                          │       (aprobación manual)   │
     │                          │◄── Promote to STAGE ────────│
     │                          │                             │── Deploy to STAGE
     │                          │                             │── Integration Tests
     │                          │                             │
     │                          │       (aprobación manual)   │
     │                          │◄── Promote to PROD ─────────│
     │                          │                             │── Deploy to PROD
     │                          │                             │── Release Notes
     │                          │                             │── Git Tag vX.Y.Z
```

### 2.5 Reglas de Protección de la Rama Trunk

Configuradas en GitHub para `main` (app-repo) y `master` (ops-repo):

- [ ] **Require pull request before merging** — no se permite push directo al trunk.
- [ ] **Require status checks to pass** — el pipeline de CI debe estar en verde.
- [ ] **Require at least 1 approving review** — el compañero revisa antes de merge.
- [ ] **Dismiss stale reviews** — si hay nuevos commits, la aprobación se invalida.
- [ ] **Do not allow bypass** — ni los admins pueden saltarse las reglas.

### 2.6 Ambientes y Promoción

Los tres ambientes **no son ramas**; son **etapas en el pipeline** que se activan según el contexto del merge:

| Ambiente | Cómo se activa | Jenkinsfile | Namespace K8s |
|---|---|---|---|
| **dev** | Merge a `main`/`master` (automático) | `Jenkinsfile.dev.*` | `dev` |
| **stage** | Aprobación manual desde Jenkins después del deploy a dev | `Jenkinsfile.stage.*` | `stage` |
| **prod** | Aprobación manual + tag de versión semántica | `Jenkinsfile.master.*` | `prod` |

```
main/master
    │
    ├── merge ──► Pipeline DEV (automático)
    │                  │
    │                  └── Manual Approval ──► Pipeline STAGE
    │                                               │
    │                                               └── Manual Approval ──► Pipeline PROD
    │                                                                             │
    │                                                                             └── git tag vX.Y.Z
```

### 2.7 Versionado Semántico

Cada deploy a producción genera un tag siguiendo **Semantic Versioning (SemVer)**:

```
vMAJOR.MINOR.PATCH

MAJOR: cambio que rompe compatibilidad (nueva API, migración de DB)
MINOR: nueva funcionalidad retrocompatible
PATCH: bug fix o cambio menor
```

El script `scripts/generate-release-notes.sh` genera automáticamente las notas de release comparando el tag anterior con `HEAD`.

### 2.8 Diagrama de Flujo Resumido

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TRUNK-BASED DEVELOPMENT — CircleGuard            │
│                                                                     │
│  feat/JIRA-42  ──┐                                                  │
│  fix/JIRA-55   ──┤──► PR ──► Review ──► Merge ──► main/master      │
│  chore/JIRA-61 ──┘              │                     │            │
│                                 │ (CI pass required)  │            │
│                                 └─────────────────────┘            │
│                                                                     │
│  main/master ──► [DEV pipeline] ──► [STAGE pipeline] ──► [PROD]    │
│                      auto             manual approval   manual      │
│                                                         + tag       │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.9 Convención de Commits: Conventional Commits

Se usa el estándar **[Conventional Commits](https://www.conventionalcommits.org/)**, ya adoptado en el historial del repositorio. Cada mensaje de commit sigue la estructura:

```
<tipo>[alcance opcional]: <descripción imperativa en minúsculas>

[cuerpo opcional — explica el POR QUÉ, no el qué]

[footer opcional — referencias a tickets, breaking changes]
```

#### Tipos permitidos

| Tipo | Cuándo usarlo | Ejemplo |
|---|---|---|
| `feat` | Nueva funcionalidad visible para el usuario/operador | `feat: add terraform module for EKS node group` |
| `fix` | Corrección de un bug | `fix: stage rollout deadlock on zero maxSurge` |
| `perf` | Mejora de rendimiento sin cambio funcional | `perf: share Gradle cache via named Docker volume` |
| `chore` | Tareas de mantenimiento, dependencias, config | `chore: upgrade Spring Boot to 3.3.2` |
| `docs` | Solo documentación | `docs: add branching strategy guide` |
| `test` | Agregar o corregir pruebas | `test: add integration test for gateway auth flow` |
| `refactor` | Reestructuración de código sin cambio de comportamiento | `refactor: extract release notes logic to script` |
| `ci` | Cambios en pipelines o configuración de CI/CD | `ci: add Trivy scan stage to master pipeline` |
| `revert` | Revertir un commit anterior | `revert: feat: add prometheus scrape config` |

#### Reglas de redacción

- **Imperativo presente**: "add", "fix", "remove" — no "added", "fixes", "removing".
- **Minúsculas** en el tipo y la descripción.
- **Sin punto final** en la primera línea.
- **Máximo 72 caracteres** en la primera línea.
- El cuerpo (separado por línea en blanco) explica el *por qué*, no el *qué*.
- Para cambios que rompen compatibilidad, agregar `!` después del tipo: `feat!: rename identity endpoint`.

#### Ejemplos reales del proyecto

```
feat: add master/production pipeline with system tests, approval gate and release notes

fix: extract Release Notes shell to script, eliminating Groovy GString parse errors

perf: share Gradle dependency cache across test containers via named Docker volume

fix: stage unit tests non-fatal + clear stale deployment annotation on redeploy

ci: add SonarQube quality gate to dev pipeline
```

#### Relación con SemVer

Los tipos de commit determinan el siguiente número de versión automáticamente:

| Tipo en commits desde último tag | Bump de versión |
|---|---|
| Al menos un `feat!` o `BREAKING CHANGE` en footer | `MAJOR` (v1.0.0 → v2.0.0) |
| Al menos un `feat` | `MINOR` (v1.0.0 → v1.1.0) |
| Solo `fix`, `perf`, `chore`, etc. | `PATCH` (v1.0.0 → v1.0.1) |

### 2.10 Proceso de Pull Request

#### Apertura del PR

Al abrir un PR desde una feature branch hacia `main`/`master`, el título debe seguir la misma convención de Conventional Commits:

```
feat(auth): add JWT refresh token rotation
fix(pipeline): resolve stage rollout deadlock on zero maxSurge
chore(deps): upgrade Testcontainers to 1.20
```

El cuerpo del PR debe incluir:

```markdown
## Qué hace este PR
<!-- Una o dos oraciones. No describas los commits individualmente. -->

## Por qué
<!-- Contexto o ticket de Jira. Ej: Closes INGESOFTV-42 -->

## Cómo probarlo
<!-- Pasos para verificar el cambio. -->

## Checklist
- [ ] Los tests pasan localmente (`./gradlew test`)
- [ ] SonarQube no introduce nuevos issues BLOCKER
- [ ] El cambio está cubierto por tests (unitarios o integración)
- [ ] La documentación fue actualizada si aplica
```

#### Reglas de revisión

- Mínimo **1 aprobación** del compañero antes de merge.
- El autor del PR **no puede aprobarse a sí mismo**.
- Si se agregan commits nuevos después de la aprobación, la aprobación se invalida (**Dismiss stale reviews**).
- Los comentarios de revisión marcados como **"Request changes"** deben resolverse antes de merge.

#### Estrategia de merge: Squash and Merge

Se usa **exclusivamente Squash and Merge**. Nunca "Merge commit" ni "Rebase and merge".

**Por qué Squash:**

Las feature branches de TBD duran 1-2 días y acumulan commits de trabajo incremental (`wip:`, `fixup`, etc.) que no aportan valor al historial del trunk. Squash convierte toda la rama en **un único commit limpio** en `main`/`master` que representa una unidad completa de trabajo.

```
Antes del merge (historial de la feature branch):
  wip: half-done terraform module
  fixup: remove debug print
  wip: add variable definitions
  fix: typo in variable name

Después del Squash and Merge en trunk:
  feat(infra): add terraform module for EKS node group  ← un solo commit limpio
```

El mensaje del squash commit debe seguir Conventional Commits y referenciar el ticket:

```
feat(infra): add terraform module for EKS node group

Closes INGESOFTV-42
```

GitHub rellena este campo automáticamente con el título del PR, que ya sigue la convención.

#### Eliminación de rama tras el merge

La rama se elimina **inmediatamente y automáticamente** después del merge.

Configuración en GitHub: `Settings → General → Pull Requests → Automatically delete head branches` ✓

En TBD las ramas muertas son ruido: generan confusión sobre qué está activo, dificultan la búsqueda de ramas relevantes y contradicen el principio de trunk único.

```
Estado correcto del repo después de varios merges:

  main/master  ←──────────────────────── (único branch activo)
      │
      ├── feat/INGESOFTV-50-...   (en progreso activo, abierta)
      └── [sin otras ramas]       ← las merged ya fueron eliminadas
```

#### Flujo completo de un PR en 6 pasos

```
1. git checkout -b feat/INGESOFTV-42-terraform-eks-module

2. (trabaja, commits con Conventional Commits)
   git commit -m "feat(infra): add variable definitions for EKS node group"
   git commit -m "fix(infra): correct subnet CIDR block reference"

3. git push origin feat/INGESOFTV-42-terraform-eks-module

4. Abrir PR en GitHub:
   - Título: feat(infra): add terraform module for EKS node group
   - Body: descripción + Closes INGESOFTV-42 + checklist

5. CI pasa en verde → compañero revisa y aprueba

6. Squash and Merge
   → GitHub genera commit: "feat(infra): add terraform module for EKS node group (#12)"
   → Rama eliminada automáticamente
   → Jenkins dispara pipeline de DEV
```

---

## 3. Change Management Process

### 3.1 Propósito

Establecer un flujo formal y trazable para que todo cambio en la infraestructura y pipelines del sistema sea evaluado, autorizado y registrado antes de llegar a producción. Este documento es el counterpart del Change Management definido en el repositorio de aplicación, adaptado a la perspectiva de operaciones.

### 3.2 Tipos de Cambio

| Tipo | Categoría | Ejemplos | ¿Requiere PR? | ¿Requiere CI? |
|---|---|---|---|---|
| **Feature** | Nueva funcionalidad de infra/ops | `feat: add terraform module for EKS node group` | Sí | Sí |
| **Fix** | Corrección de bug en pipelines o manifiestos | `fix: stage rollout deadlock on zero maxSurge` | Sí | Sí |
| **Hotfix** | Corrección urgente en producción | `fix: patch ACR credentials in prod manifests` | Sí (fast-track) | Sí |
| **Chore** | Mantenimiento, dependencias, config | `chore: upgrade Terraform to 1.6` | Sí | Sí |
| **Docs** | Solo documentación | `docs: add rollback plan` | Sí | No obligatorio |
| **Revert** | Reversión de un cambio anterior | `revert: feat: add prometheus scrape config` | Sí | Sí |

### 3.3 Flujo de Aprobación de Cambios

```
┌────────────┐     ┌──────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│ 1. Ticket  │────►│ 2. Rama  │────►│ 3. Pull   │────►│ 4.        │────►│ 5. Merge  │
│ Jira:      │     │ docs/    │     │ Request   │     │ Revisión  │     │ Squash    │
│ "InProgress"│     │ feat/    │     │ (título   │     │ + CI      │     │ + Jira    │
│            │     │ fix/     │     │ Convent.  │     │ pasa      │     │ "Done"    │
└────────────┘     │ chore/   │     │ Commits)  │     │           │     │           │
                   └──────────┘     └───────────┘     └───────────┘     └───────────┘
                                                              │
                                                         ¿Aprueba?
                                                         ┌───┴───┐
                                                         │ Sí    │ No → se itera
                                                         └───┬───┘
                                                             ▼
                                                     ┌───────────────┐
                                                     │ Pipeline CI   │
                                                     │ pasa en verde │
                                                     └───────┬───────┘
                                                             ▼
                                                     ┌───────────────┐
                                                     │ Merge +       │
                                                     │ Deploy a dev  │
                                                     └───────────────┘
```

**Reglas del flujo:**

1. **Ticket en Jira**: Todo cambio debe tener un ticket Jira en estado `In Progress` antes de escribir código.
2. **Rama desde master**: `git checkout -b <tipo>/INGESOFTV-XX-descripcion`
3. **Pull Request**: Título sigue Conventional Commits. Cuerpo incluye descripción, motivación y checklist.
4. **Revisión obligatoria**: Mínimo 1 approving review del compañero. No self-approval.
5. **CI debe pasar**: Tests unitarios, SonarQube quality gate, Trivy security scan. Si falla, no se mergea.
6. **Squash & Merge**: Un solo commit limpio en master con referencia al ticket Jira.
7. **Jira a Done**: Al mergear, la historia pasa a `Done` con comentario de evidencia.

### 3.4 Promoción por Ambientes

| Etapa | Gatillo | Verificaciones |
|---|---|---|
| **DEV** | Automático al mergear a `master` | Smoke tests (health check) |
| **STAGE** | Aprobación manual tras dev | Smoke tests + integración |
| **PROD** | Aprobación manual + tag SemVer | Smoke tests + release notes |

### 3.5 Trazabilidad

Cada cambio debe ser rastreable desde el requerimiento hasta el deploy:

```
Ticket Jira ──► Rama ──► Commit ──► PR ──► Merge ──► Tag ──► Release Notes
INGESOFTV-42   feat/    feat:      feat:    v1.0.0    v1.0.0
               INGESOFTV add EKS   add EKS
```

### 3.6 Cambios de Emergencia (Hotfix)

Para bugs críticos en producción que no pueden esperar el ciclo normal:

1. Crear rama `fix/INGESOFTV-XX-descripcion` desde master
2. PR con revisión exprés (1 approve, priorizada)
3. CI pasa → merge → deploy automático a dev
4. Approval manual acelerado a stage y prod
5. Ticket de Jira se actualiza post-facto si es necesario
6. Se documenta la causa raíz y la acción preventiva en un plazo de 24h

---

## Resumen

| Dimensión | Decisión | Justificación |
|---|---|---|
| Metodología ágil | Scrum (2 semanas/sprint) | Alcance acotado, ciclos de revisión regulares, compatible con Jira |
| Herramienta de gestión | Jira Software | Trazabilidad Jira-ID → branch → PR → deploy |
| Estrategia de branching | Trunk-Based Development | Equipo pequeño, sin merge hell, trunk siempre desplegable |
| Modelo GitOps | Repos separados (app + ops) | Separación de concerns, auditoría clara, ritmos independientes |
| Diferenciación de ambientes | Por pipeline, no por rama | Compatible con TBD; dev/stage/prod son etapas, no ramas |
| Convención de commits | Conventional Commits | Trazabilidad tipo→SemVer, historial legible, ya adoptado en el repo |
| Merge strategy | Squash and Merge | Trunk limpio: un commit por unidad de trabajo, sin WIP commits |
| Eliminación de ramas | Automática post-merge | Coherencia con TBD; sin ramas muertas en el repo |
| Versionado | SemVer automático en prod | Trazabilidad de releases, release notes automáticas |
