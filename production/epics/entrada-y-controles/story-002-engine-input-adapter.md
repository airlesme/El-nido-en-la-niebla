# Story 002: `EngineInputAdapter` → `RawInput` y `feed()`

> **Epic**: Entrada y controles
> **Status**: Done (2026-11-11)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, reglas 1–2 (acciones lógicas; teclado y mando a la vez)
**Requirement**: `TR-input-001`, `TR-input-002` (ambos dispositivos activos)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input abstraction, contexts and binding labels (D2; § Spike Results S-0006)
**ADR Decision Summary**: `EngineInputAdapter` (`Node`, hijo de `InputRouter`, `ALWAYS`) es el único fichero que lee campos de `InputEvent`, nombres de mando, señales de conexión, modo del ratón y foco; convierte cada evento en `RawInput`. Todo lo demás es puro y se prueba con `feed(raw)`.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: la clase de dispositivo sale del **tipo** del evento, no de `device` (`DEVICE_ID_MOUSE/KEYBOARD` en 4.7; F-R41). Verificado en `tests/unit/engine_facts/adr0006_input_events_test.gd` y `adr0006_loop_order_test.gd`. Nombres de mando y hot-plug: NEEDS_MANUAL (S-0006-B).

**Control Manifest Rules (this layer)**:
- Required: F-R40 (el adaptador es el único que lee `InputEvent`), F-R41, F-R46 (como mucho una acción por evento crudo)
- Forbidden: `Input.` fuera del adaptador
- Guardrail: sin asignaciones por evento en la ruta caliente cuando sea posible

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story:*

- [ ] **AC-02**: con teclado y mando, `interactuar` desde cada uno llega al juego sin elegir dispositivo (eventos sintéticos → `RawInput` → acción).
- [ ] Un `InputEventKey`, `InputEventMouseButton`, `InputEventMouseMotion`, `InputEventJoypadButton` y `InputEventJoypadMotion` producen el `RawInput` esperado (`kind`, `code`, `device`); un evento crudo produce como mucho una acción.
- [ ] El adaptador cachea el último valor de eje por (mando, eje) para D8 (008).

---

## Implementation Notes

- Firmas (ADR-0006): `InputRouter.feed(raw: InputTypes.RawInput) -> void`; adaptador `pad_name(pad_id) -> String`, `set_mouse_mode(mode: StringName)`, `to_binding(ev) -> InputBinding`, `is_printable_key(code) -> bool` (este último se usa en 012).
- Sustituir el esqueleto de `src/input/input_router.gd` por la API de ADR-0006; `process_mode = ALWAYS` explícito.

---

## Out of Scope

- Stories 007 (dispositivo activo), 008 (zona muerta), 014 (foco/desconexión).

---

## Files

- `src/input/engine_input_adapter.gd`, `src/input/input_router.gd`
- `tests/unit/input/engine_input_adapter_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/engine_input_adapter_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-001-input-types-and-binding-table.md`
- Unlocks: `production/epics/entrada-y-controles/story-003-context-stack-and-sinks.md`, `production/epics/entrada-y-controles/story-007-device-tracker-hysteresis.md`, `production/epics/entrada-y-controles/story-008-move-and-look-formulas.md`

---

## Evidencia

- `tests/unit/input/engine_input_adapter_test.gd`: 22 tests, 0 fallos, 0 orphans (AC-02, los cinco tipos de evento, una accion como maximo, cache de ejes, `to_binding`, `is_printable_key`, camino real `parse_input_event` + `flush_buffered_events`).
- `--import` sin errores. Suite bloqueante (`-a res://tests -i res://tests/timing`): 373 casos, 0 errores, 0 fallos, 0 orphans; 0 apariciones de `ObjectDB instances were leaked` y de `resources still in use`.
- Provisional, con `TODO(ADR-0006)`: `InputRouter.use_table` y la senal `action_fed` (la entrega por contexto llega en 003); la deny-list de `is_printable_key` se inyecta (`set_non_printable_keys`) hasta que el JSON la lleve (012). `pad_connection_changed` y `window_focus_changed` quedan para 014.
