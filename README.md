# microservice-app-example

### Rafaela Ruiz - Pablo Pineda
 
> Proyecto de entrenamiento para practicar DevOps, arquitectura de microservicios, patrones de resiliencia y pipelines multi‑lenguaje.

## 1. Contexto

Sistema pequeño pero heterogéneo compuesto por servicios en Go (auth), Java (usuarios), NodeJS (todos), Python (procesador de logs) y Vue (frontend), apoyado por Redis (cache + pub/sub) y Zipkin (tracing). Sirve para experimentar integración continua, despliegue continuo, observabilidad y patrones de resiliencia sin la complejidad de un entorno empresarial grande. Entorno objetivo cloud: **Azure Container Apps** 

### ¿Por qué multi‑lenguaje?

- Para exponer distintos ecosistemas de build (Go modules / Maven / npm / Python)
- Para obligar a coordinar pipelines y contenedores
- Para ver diferencias de tiempos de build y estrategias de empaquetado

## 2. Objetivo

Espacio de práctica para:

- Entregas continuas (deploys pequeños y frecuentes)
- Patrones de resiliencia (Circuit Breaker, Cache-Aside, Pub/Sub, fallback)
- Observabilidad distribuida extremo a extremo (Zipkin)
- Flujo ágil ligero (Kanban) + estrategias de branching
- Evolución incremental (sustituir storage temporal, añadir gateway, etc.)

## 3. Funcionalidades Principales

- Autenticación JWT
- Listado de usuarios (Spring Boot)
- CRUD de TODOs con cache-aside (Redis)
- Publicación de eventos create/delete a Redis (pub/sub)
- Procesamiento asíncrono de logs (Python subscriber)
- Trazas distribuidas entre servicios (Zipkin)
- Frontend consumiendo APIs unificadas

## 4. Estructura del Proyecto

```
microservice-app-example/
	auth-api/              # Go service: auth & JWT issuance (circuit breaker + tracing)
	users-api/             # Java Spring Boot service: user data (Resilience4j circuit breaker)
	todos-api/             # NodeJS service: TODO CRUD + cache-aside + event publish
	log-message-processor/ # Python subscriber consuming Redis channel
	frontend/              # Vue + Nginx frontend
	monitoring/            # (Placeholder for future monitoring assets)
	docs/                  # Project documentation (agile, architecture, branching)
	arch-img/              # Architecture / component diagrams
	docker-compose.yml     # Local orchestration baseline
```

## 5. Componentes

1. [Users API](/users-api) (Spring Boot) – perfiles de usuario (solo lectura por ahora)
2. [Auth API](/auth-api) (Go) – emite tokens [JWT](https://jwt.io/)
3. [TODOs API](/todos-api) (NodeJS) – CRUD de TODOs + eventos a [Redis](https://redis.io/)
4. [Log Message Processor](/log-message-processor) (Python) – suscriptor de canal Redis
5. [Frontend](/frontend) (Vue) – UI
6. Redis – cache + pub/sub + persistencia temporal TODOs
7. Zipkin – backend de trazas

## 6. Diagrama de Arquitectura

El diagrama muestra interacciones básicas: frontend → auth (JWT) → APIs protegidas; TODOs con cache-aside; eventos a Redis; procesador asíncrono y correlación de trazas.

![microservice-app-example](/arch-img/Microservices.png)

Puntos clave:

- Circuit Breakers para aislar fallos entre servicios
- Cache-aside reduce latencia y desacopla de persistencia futura
- Pub/Sub para logging/eventos sin bloquear requests
- Tracing para diagnósticos rápidos y menor MTTR
  Para más detalle: [Architecture Diagram & Decisions](docs/Architecture%20Diagram.md)

## 7. Documentación

| Tema                    | Archivo                                                            | Contenido                             |
| ----------------------- | ------------------------------------------------------------------ | ------------------------------------- |
| Flujo Ágil / Entrega    | [Agile Methodology](docs/Agile%20Methodology.md)                   | Kanban resumido, WIP, métricas        |
| Arquitectura / Patrones | [Architecture Diagram & Decisions](docs/Architecture%20Diagram.md) | Decisiones, riesgos, evolución        |
| Estrategia de Branching | [Branching Strategies](docs/Branching%20Strategies.md)             | GitHub Flow (app) + Trunk-Based (ops) |

## 8. Ejecución Local

Requisitos: Docker.

```
docker compose up --build
```

Luego abrir el frontend (puerto expuesto en `docker-compose.yml`), y revisar Zipkin si está publicado.

---
