# Costos de Infraestructura — CircleGuard

Análisis de costos de la infraestructura desplegada en Azure (región `eastus2`),
provisionada con Terraform (`terraform/environments/*`).

## Inventario de recursos

| Recurso | SKU / Tamaño | Cantidad | Resource Group |
|---|---|---|---|
| AKS (control plane) | Free tier | 1 | `circleguard-core-rg` |
| Nodos AKS (VMSS) | `Standard_D2s_v3` (2 vCPU, 8 GiB) | 2 | `MC_circleguard-core-rg_...` |
| Azure Container Registry | Basic | 1 | `circleguard-core-rg` |
| Discos administrados (PVCs) | Standard SSD (Postgres 5Gi, Neo4j 2Gi + SO) | ~3 | `MC_...` |
| Storage Account (tfstate) | Standard LRS | 1 | `circleguard-tfstate-rg` |
| Load Balancer + IP pública | Basic (incluido por AKS) | 1 | `MC_...` |

## Costo mensual estimado (USD, eastus2, pay-as-you-go)

| Recurso | Costo unitario | Mensual |
|---|---|---|
| AKS control plane (Free tier) | $0 | $0.00 |
| 2 × Standard_D2s_v3 (~$0.096/h c/u) | $70.08/mes c/u | $140.16 |
| ACR Basic | $5/mes (0.167/día) | $5.00 |
| Discos Standard SSD (~10 GiB datos + 2×128 GiB SO E10) | ~$21.00 | $21.00 |
| Storage tfstate (LRS, <1 GiB) | ~$0.05 | $0.05 |
| Egress / IP pública | ~$4 | $4.00 |
| **Total estimado** | | **~$170/mes** |

> Con la suscripción **Azure for Students** ($100 de crédito) el cluster se
> mantiene apagándolo fuera de horas de trabajo (ver abajo).

## Estrategias de ahorro implementadas

1. **AKS Free tier** — sin costo de control plane ($73/mes ahorrados vs Standard).
2. **Apagado fuera de horario** — `scripts/infra-stop.sh` / `scripts/infra-start.sh`
   detienen/arrancan el VMSS del cluster. Apagar 12h/día reduce el costo de
   cómputo ~50% (≈ $70/mes ahorrados).
3. **Un solo Postgres compartido** — una instancia en el namespace `dev` sirve a
   los tres ambientes con bases separadas (válido para entorno académico).
4. **Stack de observabilidad compartido** — Prometheus/Grafana/ELK/Jaeger viven
   una sola vez en `stage` y monitorean los tres namespaces.
5. **Requests ajustados** — los pods piden 50m CPU / 256Mi (con límites de burst),
   lo que permite que todo el sistema quepa en 2 nodos.
6. **ACR Basic** — suficiente para 8 imágenes con tags (10 GiB incluidos).

## Desglose por ambiente

Los tres ambientes comparten el mismo cluster físico (namespaces `dev`, `stage`,
`production`), por lo que el costo marginal de cada ambiente adicional es ~$0.
La separación de costos es lógica, no física:

| Ambiente | Pods | Memoria solicitada aprox. |
|---|---|---|
| dev | 8 servicios + Postgres + Redis + Neo4j + Kafka + LDAP | ~3.5 GiB |
| stage | 8 servicios + observabilidad (7 pods) | ~3.5 GiB |
| production | 8 servicios | ~1 GiB |
