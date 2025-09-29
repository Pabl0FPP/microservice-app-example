# Branching Strategies (Resumen Ejecutivo)

## TL;DR

- Equipo ágil (2 personas) con microservicios en Azure (Container Apps), Docker y Terraform.
- Código de aplicación: **GitHub Flow** (ramas cortas + PR + CI antes de merge).
- Infra / operaciones: **Trunk-Based Development** (commits atómicos directo a `main`, muy pocas ramas).
- Patrones clave: integración rápida, prevención de drift, calidad automatizada, soporte a despliegue continuo.
- Feature flags + small batches ⇒ menor riesgo.

---

## 1. Contexto Breve

Necesitamos velocidad sin sacrificar estabilidad. El código de negocio cambia más rápido que la infraestructura. Por eso separamos estrategia de branching por dominio: **features ≠ infra**.

---

## 2. GitHub Flow (Dev)

**Usos:** features, refactors, UI, observabilidad.  
**Pasos:** crear rama (`feature/*`), commits pequeños, push temprano, PR con checks verdes, review, merge (squash / FF), eliminar rama, deploy automático a staging.  
**Beneficios:** simplicidad, feedback rápido, historial limpio, soporte a feature flags.  
**Riesgos mitigados:** ramas largas (límite informal < 3 días), cambios grandes divididos.

---

## 3. Trunk-Based (Ops / Infra)

**Usos:** Terraform, pipelines, parámetros runtime, hotfix producción.  
**Práctica:** commits atómicos directo a `main` o rama `ops/*` muy corta; `terraform fmt/validate/plan` en CI antes de apply.  
**Beneficios:** cero drift, respuesta operativa rápida, menos conflictos.  
**Mitigación de riesgo:** automation + small commits + revisión post‑merge si fue fast‑track.

---

## 4. Comparación Rápida

| Aspecto           | GitHub Flow        | Trunk-Based                   |
| ----------------- | ------------------ | ----------------------------- |
| Dominio           | Código app         | Infra / Ops                   |
| Vida rama         | Horas–días         | Casi nula                     |
| Tamaño cambio     | Pequeño / troceado | Muy pequeño / atómico         |
| Calidad           | PR + CI completo   | CI + Policy + (review ligera) |
| Riesgo conflictos | Medio si se alarga | Bajo                          |
| Velocidad hotfix  | Menor (PR)         | Máxima                        |

---

## 5. ¿Por qué ambas?

- Ritmos y riesgo diferentes: aplicar una sola estrategia penalizaría a uno de los dos dominios.
- Infra necesita convergencia continua; features necesitan colaboración y revisión.
- Reduce tiempo de ciclo sin degradar control.

---

## 6. Pipeline Integrado (Vista Resumida)

1. Commit feature → PR (tests, lint, security, build, terraform plan “no‑apply”).
2. Merge → build imágenes → push registry → deploy staging.
3. Tag / release → despliegue producción.
4. Commit infra → plan + policy → apply automático (si pasa gates).
5. Version label en imágenes → correlación en tracing / logs.
6. Escaneo dependencias y drift programado.

---

## 7. Buenas Prácticas Clave

- Convenciones: `feature/*`, `fix/*`, `ops/*`, `hotfix/*`.
- Squash merges (features); commits atómicos (ops).
- Feature flags para trabajo incremental.
- Terraform plan obligatorio antes de apply.
- Tags semánticos app vs tags infra separados.
- Automatización seguridad (dependabot / trivy) + lint + tests.
- Observabilidad: trace + version label.

---

## 8. Próxima Evolución

- Preview environments por PR.
- Progressive delivery (traffic splitting / blue‑green).
- Policy as Code (OPA / Sentinel) estricta.
- Tests de performance y seguridad en la fase de PR crítica.

---

## 9. Glosario Breve

- **Drift:** Diferencia entre infraestructura declarada y real.
- **Feature flag:** Permite desplegar código inactivo.
- **Small batch:** Cambios pequeños fáciles de revertir.
- **Fast‑track:** Cambio mínimo aprobado rápidamente (ops).

---

Mantener foco: integrar temprano, desplegar seguro, reducir inventario de trabajo en progreso.
