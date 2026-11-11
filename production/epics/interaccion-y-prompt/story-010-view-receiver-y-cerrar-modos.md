# Story 010: Contrato `ViewReceiver`, cancelación y `cerrar_modos()`

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Core Rules, reglas 21, 27, 30 (B-03)
**Requirement**: `TR-interact-012` (cierre total), `TR-interact-016` (fases y cancelación), `TR-interact-021` (descarga)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D8 entrega de `PointerEvent`, D10 cancelación en pausa); ADR-0009 (D5/D6 puertos `@abstract`, adaptador con `WeakRef`); ADR-0010 (adaptador del marco: `on_engage`/`on_disengage`/`cancel_gesture`)
**ADR Decision Summary**: `ViewReceiver` es un puerto de 7 (`elements`, `handle_pointer`, `on_open`, `on_close`) registrado con `registrar_receptor`; 7 entrega `CANCELACION` a un gesto en curso antes de `on_close(motivo)`; la descarga de escena cierra de forma síncrona sin avisos al bus.
**ADR Version**: ADR-0011 2026-11-10 · ADR-0009 2026-11-10 · ADR-0010 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: `@abstract` (4.5) para los puertos, como ADR-0009; overrides tipados con `return` explícito (4.7).

**Control Manifest Rules (this layer)**:
- Required: F-R33 (puertos `@abstract RefCounted`, adaptador con `WeakRef`), F-R31.
- Forbidden: FE-X05 (un controlador nunca referencia `InteractionSystem`: le llega por el adaptador).
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-27c**: un receptor de prueba recibe `on_open()` una vez al pasar a Abierta, `on_close(motivo)` una vez al cerrar y `cancelación` por `handle_pointer` antes de `on_close` si hay gesto; el adaptador del marco traduce a `on_engage`/`on_disengage`/`cancel_gesture`; los `actualización` de cursor no avanzan un contador de inactividad que cuenta solo `inicio`/`fin`/`cancelación`.
- [ ] **AC-29**: con un `agarrar` en curso, `atrás` entrega `cancelación` antes del aviso de cierre; con pausa (`MENU`), `CANCELACION` y la vista sigue abierta.
- [ ] **AC-35**: `cerrar_modos()` con `lectura` → «lectura cerrada» (`sistema`) y una vez «modos cerrados»; con `ordenador` → `devolver_camara`, `on_close(sistema)` y «modos cerrados» solo tras `camara_devuelta`; `llamada` no se cierra; descarga con vista abierta → `cancelación` y `on_close(sistema)` síncronos sin avisos al bus.

---

## Implementation Notes

*Derived from ADR-0011 D8/D10 y ADR-0009 D5:*

- `registrar_receptor(id_vista, receptor)`; sin receptor registrado `abrir_vista` → `RECHAZADA` (009).
- Inspección fuera de M1: la rama `inspección` de `cerrar_modos()` (objeto a su sitio) no se implementa ahora; dejar el caso marcado en la prueba como pendiente de recorte 6.

---

## Out of Scope

- Story 011: construcción de `PointerEvent` y picking.

---

## Files

- `src/interaction/ports/view_receiver.gd`
- `tests/unit/interaction/view_receiver_test.gd`, `tests/unit/interaction/cerrar_modos_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/interaction/view_receiver_test.gd`, `cerrar_modos_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-009-vista-cercana-ciclo.md`
- Unlocks: `production/epics/interaccion-y-prompt/story-011-view-metrics-y-picking.md`; adaptador de vista del épico `puzles-marco-y-p1`
