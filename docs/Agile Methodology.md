# Metodología Ágil: Kanban

## 1. Características Clave del Proyecto

Equipo muy pequeño (2), microservicios heterogéneos (Go, Node, Java, Python, Vue), alto mix de trabajo (features, fixes, hardening, ops, docs), despliegues frecuentes, tooling automatizado (CI/CD, Terraform, Docker, tracing con Zipkin) y necesidad de resiliencia temprana (cache-aside, circuit breakers, pub/sub). Esto favorece flujo continuo sobre ciclos cerrados.

## 2. Por qué Kanban

Minimiza ceremonias, absorbe trabajo no planificado (ops/hardening), permite liberar cada servicio cuando está listo, reduce multitarea con WIP bajo y se apoya en observabilidad para feedback rápido. Scrum introduciría overhead de sprints fijos y compromisos artificiales dada la variabilidad; Kanban mantiene foco en Lead Time real.

## 3. Flujo Kanban

Backlog → Ready → In Progress → Code Review → Staging → Verificación → Producción → Done
WIP (máx): In Progress 2 totales; Code Review 2; Verificación 1. Paso a Done tras 10–15 min de monitoreo estable en producción.

## 4. Elementos Técnicos que Refuerzan el Flujo

- Circuit Breakers: evitan cascadas → menos bloqueos.
- Cache-Aside: rapidez sin esperar DB definitiva.
- Pub/Sub Redis: desacopla logging / auditoría.
- Tracing distribuido: diagnóstico rápido → MTTR bajo.

## 5. Métricas Básicas

Lead Time (<=2 días), Throughput semanal estable, Edad de bloqueos (<24h), MTTR (<30 min). Se observan para detectar cuellos, no para micro‑gestión.

## 6. Conclusión

Kanban encaja porque el valor proviene de liberar pequeños cambios resilientes continuamente, no de planificar lotes. Las prácticas técnicas reducen el costo de cambio y garantizan visibilidad, sosteniendo entregas frecuentes con riesgo controlado. Es un marco ligero que deja espacio a la evolución futura (DB relacional, gateway, políticas) sin rehacer proceso.

_Relacionado: `Branching Strategies.md`, `Architecture Diagram.md`._
