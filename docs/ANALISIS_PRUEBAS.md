# Análisis de Resultados de Pruebas — CircleGuard

Entregable de la sección 9 del proyecto (Análisis de resultados de pruebas).
Consolida los resultados de las pruebas automatizadas y la evidencia de
observabilidad recogida del ambiente `stage` desplegado en AKS.

## Resumen ejecutivo

El sistema pasa todas las compuertas de calidad: **31/31** pruebas E2E,
cobertura **~92%** (Quality Gate de SonarCloud en verde), **0** vulnerabilidades
HIGH/CRITICAL en el escaneo de seguridad, y los **8** servicios reportan UP con
métricas, logs y trazas fluyendo correctamente.

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
aceptación se cumple en los 8. El patrón es consistente (1 Medium común y 2 Low
adicionales en identity), correspondiente a observaciones de nivel informativo
propias del stack. **Veredicto: PASS.**

---

## 2. Estado de servicios (Grafana)

Los 8 servicios en verde "UP" en el panel *Estado de Servicios*. Confirma que
Prometheus descubre y scrapeа correctamente los 8 endpoints `/actuator/health`
y que ninguno está caído. Evidencia directa de que los health checks y el
service discovery funcionan.

---

## 3. Pruebas de rendimiento (Locust + paneles de Grafana)

- *HTTP Requests por segundo por servicio*: picos escalonados (uno por servicio)
  hasta ~6 req/s — patrón típico de la suite de Locust ejecutando carga servicio
  por servicio.
- *JVM Heap*: diente de sierra saludable (asignación + recolección de basura
  periódica) entre 32 y 64 MiB, sin fugas de memoria.
- *JVM Threads*: estable entre 32 y 37 hilos por servicio, sin crecimiento bajo
  carga.

El sistema absorbe la carga sintética sin degradación de memoria ni de hilos.
**Veredicto: estable bajo carga.**

---

## 4. Métricas de negocio (Grafana)

- *Gateway: Escaneos QR por minuto* → pico de ~200, confirmando la instrumentación
  de negocio del gateway y que la carga ejercitó la validación de QR.
- *Auth: Inicios de sesión por minuto* → 0 en la ventana mostrada.
- *Promotion: Usuarios en Cuarentena* → 0.
- *Form: Encuestas Sintomáticas* → 0.

Las métricas de negocio están registradas y se actualizan (lo prueba el pico de
QR). Que login, cuarentena y encuestas estén en 0 es coherente con la ventana de
15 minutos: la carga se concentró en el path de QR y no se dispararon flujos de
casos positivos ni encuestas en ese intervalo. Las métricas reflejan fielmente
la actividad real.

---

## 5. Gestión de logs (Kibana)

Kibana centraliza los logs de los 8 servicios y permite buscarlos y filtrarlos
por servicio bajo índices diarios. Los logs estructurados (con `app`, `level`,
`traceId`, `spanId`) llegan correctamente desde los servicios vía Logstash hacia
Elasticsearch. Entre la actividad registrada se observa el **Circuit Breaker de
Resilience4j** de dashboard-service operando: cuando una dependencia no responde,
el breaker se abre y el servicio devuelve una respuesta de respaldo en lugar de
bloquearse, evidencia de que el patrón de resiliencia funciona en ejecución.
**Veredicto: logging centralizado operativo.**

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

## Conclusión

El conjunto de pruebas confirma un sistema **seguro** (0 vulnerabilidades HIGH/
CRITICAL en los 8 servicios), **estable bajo carga** (memoria y hilos sanos),
**observable** (métricas técnicas y de negocio, logs centralizados y tracing
distribuido operando) y **funcionalmente correcto** (31/31 E2E, cobertura ~92%
sobre el gate del 80%). Todas las compuertas de calidad del pipeline pasan en
verde.
