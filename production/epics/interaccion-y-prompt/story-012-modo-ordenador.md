# Story 012: Modo ordenador (`V01`)

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: S — 0,5 días (0,5–1), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Core Rules, regla 24; § Formulas › F4
**Requirement**: `TR-interact-012` (modo `ordenador`), `TR-interact-013` (cesión `interaccion:ordenador`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D6, mismo ciclo que la vista); ADR-0012 (`ceder_camara`/`devolver_camara`); ADR-0006 (contexto `ordenador`)
**ADR Decision Summary**: activar `V01` pone Entrada en `ordenador` y pide `ceder_camara(&"interaccion:ordenador", …)` sin animación de sentarse; `atrás` sale con el mismo orden que una vista; el receptor es el sistema 19.
**ADR Version**: ADR-0011 2026-11-10 · ADR-0012 2026-11-10 · ADR-0006 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ver 009.

**Control Manifest Rules (this layer)**:
- Required: FE-R05; F-R32.
- Forbidden: FE-X04.
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-33**: al activar `V01`, Entrada entra en `ordenador`, se pide `ceder_camara("interaccion:ordenador", …)` sin mover el cuerpo, la cámara se acerca a la pantalla y `atrás` sale con el mismo orden que la vista.
- [ ] **AC-35 (rama ordenador)**: `cerrar_modos()` con el ordenador abierto llama `on_close(sistema)` al receptor de 19 y emite «modos cerrados» solo tras `camara_devuelta`.

---

## Implementation Notes

- Reutiliza `close_view_controller` (009) con propietario `&"interaccion:ordenador"` y contexto `ordenador`; el receptor lo registra el épico ordenador-e-impresora.

---

## Out of Scope

- La interfaz del ordenador (épico ordenador-e-impresora). Captura AC-V7: story 013.

---

## Files

- `src/interaction/close_view_controller.gd` (rama ordenador)
- `tests/integration/interaction/modo_ordenador_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/interaction/modo_ordenador_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-009-vista-cercana-ciclo.md`; épico `ordenador-e-impresora` (receptor de 19)
- Unlocks: `production/epics/interaccion-y-prompt/story-013-recorrido-m1-y-capturas.md`
