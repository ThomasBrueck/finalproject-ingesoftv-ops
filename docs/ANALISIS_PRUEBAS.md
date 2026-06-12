# Análisis de Resultados de Pruebas — CircleGuard

Entregable de la sección 9 del proyecto (Análisis de resultados de pruebas).
Consolida los resultados de las pruebas automatizadas y la evidencia de
observabilidad recogida del ambiente `stage` desplegado en AKS.

## Resumen ejecutivo

El sistema pasa todas las compuertas de calidad: **31/31** pruebas E2E,
cobertura **~92%** (Quality Gate de SonarCloud en verde), **0** vulnerabilidades
HIGH/CRITICAL en el escaneo de seguridad, y los **8** servicios reportan UP con
métricas, logs y trazas fluyendo correctamente. La observabilidad, además de
confirmar la salud del sistema, reveló dos hallazgos accionables (detallados al
final); el más relevante ya fue corregido y verificado.

---

## 1. Pruebas de seguridad (OWASP ZAP — DAST)

| Servicio | High | Medium | Low |
|---|---|---|---|
| gateway | 0 | 1 | 0 |
| auth | 0 | 1 | 0 |
| form | 0 | 1 | 0 |
| identity | 0 | 1 | 2 |
| promotion | 0 | 1 | 0 |
| notification | 0 | 1 | 0 |
| dashboard | 0 | 1 | 0 |
| file | 0 | 1 | 0 |

Ningún servicio presenta vulnerabilidades HIGH ni CRITICAL: el criterio de
aceptación se cumple en los 8. El patrón es muy consistente (1 Medium idéntica
en todos), lo que indica una característica común del stack —típicamente una
cabecera de seguridad ausente (p. ej. `Content-Security-Policy`)— y no un fallo
de un servicio concreto. Las 2 Low extra en identity corresponden a divulgación
menor de información.

**Recomendación:** añadir cabeceras de seguridad comunes (filtro de Spring
Security o en el Ingress) cerraría la Medium de los 8 de una sola vez.
**Veredicto: PASS.**

---

## 2. Estado de servicios (Grafana)

Los 8 servicios en verde "UP" en el panel *Estado de Servicios*. Confirma que
Prometheus descubre y scrapeа correctamente los 8 endpoints `/actuator/health`
y que ninguno está caído. Evidencia directa de que los health checks y el
service discovery funcionan.

---

## 3. Pruebas de rendimiento (Locust + panel HTTP de Grafana)

- *HTTP Requests por segundo por servicio*: picos escalonados (uno por servicio)
  hasta ~6 req/s — patrón típico de la suite de Locust ejecutando carga servicio
  por servicio.
- *JVM Heap*: diente de sierra saludable (asignación + GC periódico) entre 32 y
  64 MiB, sin fugas.
- *JVM Threads*: plano entre 32 y 37 hilos por servicio, sin crecimiento bajo
  carga.

El sistema absorbe la carga sintética sin degradación de memoria ni de hilos.
**Veredicto: estable bajo carga.**

> **Hallazgo 2 — panel "Latencia P95: No data".** El throughput se grafica pero
> la latencia P95 no, casi seguro porque la query del panel usa
> `histogram_quantile(...)` sobre `http_server_requests_seconds_bucket` con un
> nombre/etiqueta que no coincide con lo que exponen los servicios. Es un ajuste
> de la query de Grafana, no un problema del sistema.

---

## 4. Métricas de negocio (Grafana)

- *Gateway: Escaneos QR por minuto* → pico de ~200, confirmando la instrumentación
  de negocio del gateway y que la carga ejercitó la validación de QR.
- *Auth: Inicios de sesión por minuto* → 0 en la ventana mostrada.
- *Promotion: Usuarios en Cuarentena* → 0.
- *Form: Encuestas Sintomáticas* → 0.

Las métricas de negocio están registradas y se actualizan (lo prueba el pico de
QR). Que login/cuarentena/encuestas estén en 0 es coherente con la ventana de 15
minutos: la carga se concentró en el path de QR y no se dispararon flujos de
casos positivos ni encuestas en ese intervalo. Resultado esperado: las métricas
reflejan fielmente la actividad real.

---

## 5. Gestión de logs (Kibana) — Hallazgo principal

Kibana centraliza los logs de los 8 servicios. Aparecieron WARN repetidos de
dashboard-service:

```
Circuit breaker open for promotion-service [getHealthStats]:
  CircuitBreaker 'promotionService' is OPEN and does not permit further calls
I/O error on GET ".../stats/department/Engineering": Connection refused
```

Esto demuestra dos cosas:

**(a) Patrón de resiliencia funcionando (positivo).** dashboard-service protege
sus llamadas a promotion con un **Circuit Breaker de Resilience4j**
(`@CircuitBreaker(name="promotionService", fallbackMethod=...)`). Al fallar
promotion, el breaker se abrió y dashboard dejó de intentar, devolviendo un
fallback en lugar de colgarse. Es el Circuit Breaker actuando en vivo —complemento
del patrón Bulkhead (auth→identity).

**(b) Hallazgo 1 — mala configuración (CORREGIDO).** El manifiesto de
dashboard-service no definía `circleguard.promotion-service.url`, por lo que el
código caía al default `http://localhost:8088`, que dentro del pod apunta a sí
mismo → "Connection refused" y breaker abierto. La integración dashboard→promotion
estaba rota en el ambiente desplegado. El E2E ca33 pasaba igual porque el fallback
del breaker devuelve 200, enmascarando el problema.

**Remediación aplicada y verificada:** se añadió
`CIRCLEGUARD_PROMOTION_SERVICE_URL=http://circleguard-promotion-service:80` a los
deployments de dashboard (dev/stage/prod). Tras desplegar en stage, el endpoint
`/api/v1/analytics/health-board` devuelve datos reales de promotion
(`{"totalUsers":16,...}`) en vez del fallback vacío, y los logs ya no muestran
circuit breaker abierto ni connection refused.

---

## 6. Tracing distribuido (Jaeger)

Jaeger registra trazas de los 8 servicios. Para auth-service: 20 trazas con
operaciones como `http get /actuator/health/**` (~700 µs),
`http get /actuator/prometheus` (~2.6 ms) y `authorize request`, cada una con 5
spans y latencias < 3 ms. El tracing con OpenTelemetry/OTLP funciona de extremo a
extremo. La mayoría de trazas son de health (probes) y prometheus (scraping), el
tráfico de fondo esperado de la plataforma. **Veredicto: tracing operativo,
latencias excelentes.**

---

## 7. Pruebas unitarias, integración, E2E y cobertura

- **Unitarias:** verdes en los 8 servicios; cubren camino feliz y de error.
- **Integración (Testcontainers):** validan el flujo productor-consumidor sobre
  PostgreSQL y Kafka reales.
- **E2E:** 31/31 contra el ambiente stage real.
- **Cobertura:** ~92% (líneas + ramas), por encima del gate del 80%; SonarCloud
  reporta "Passed".

---

## 8. Hallazgos y recomendaciones consolidados

| # | Hallazgo | Severidad | Estado / acción |
|---|---|---|---|
| 1 | dashboard→promotion usaba `localhost:8088` (URL no configurada) → Connection refused, breaker abierto, analítica vacía | Media (funcional, enmascarada por fallback) | **Corregido y verificado** (variable de entorno añadida en los 3 ambientes) |
| 2 | Panel "Latencia P95" en Grafana sin datos | Baja (observabilidad) | Ajustar la query `histogram_quantile` al histograma real |
| 3 | 1 alerta Medium común en los 8 (probable cabecera de seguridad ausente) | Baja | Añadir cabeceras de seguridad comunes (Spring/Ingress) |
| 4 | ca33 (dashboard) pasaba pese a la integración rota | Baja (calidad de prueba) | Reforzar el E2E para validar contenido, no solo HTTP 200 |

**Veredicto general:** sistema sólido —seguro (0 HIGH), observable, resiliente
(Bulkhead + Circuit Breaker demostrados en vivo) y con buena cobertura—. Los
hallazgos son menores y de configuración, no de arquitectura. El hallazgo #1
ilustra por qué la resiliencia importa: un patrón bien aplicado evitó que una
mala configuración tumbara el dashboard.
