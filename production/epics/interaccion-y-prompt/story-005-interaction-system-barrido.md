# Story 005: `InteractionSystem` en planta — barrido por paso, pausa y `get_target()`

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1 día (1–2), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Core Rules, reglas 4, 5, 27, 28; § States and Transitions
**Requirement**: `TR-interact-002`, `TR-interact-021`, `TR-interact-022` (solo `get_target()` sondeado; el pie es 007)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D2 `configurar()`, D9 costuras y presupuesto, D10 pausa, G-4, G-10, G-11); ADR-0009 (D3 `configurar(ctx)`, `SubscriptionBag`); ADR-0002 (G-4, G-6)
**ADR Decision Summary**: 7 vive bajo `WorldSlot` (`PAUSABLE`); en cada paso de física, solo en `EXPLORACION` estable y sin pausa, ejecuta PickMath → oclusión → FocusSelector y publica un `get_target()` cacheado; al reanudar recalcula en el primer paso sin retener el objetivo viejo.
**ADR Version**: ADR-0011 2026-11-10 · ADR-0009 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (orden de física Player → 7)
**Engine Notes**: S-0011-C: el orden entre `_physics_process` se fija con `process_physics_priority` (prioridad 0 antes que 10 en 30/30 pasos aunque se añadió segundo) — FE-R11: el Player con prioridad menor que 7. `GameClock.paused_changed` prohibido: se sondea `is_paused()` (G-11).

**Control Manifest Rules (this layer)**:
- Required: FE-R05 (guarda de pausa y retorno fuera de `EXPLORACION`), FE-R10, FE-R11, F-R28 (`configurar(ctx)` con `ctx.require`), F-R29, F-R31.
- Forbidden: FE-X04 (7 nunca abre `sin control` ni conecta `paused_changed`).
- Guardrail: FE-G01 — ≤ 0,25 ms media / 0,5 ms pico por paso con 40 entradas; 0 fuera de exploración y en pausa.

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-07**: en un contexto distinto de `exploración` el barrido no se ejecuta y no hay objetivo.
- [ ] **AC-34**: en cualquier partida 7 no escribe ningún hecho ni guarda nada; al cargar escena, objetivo vacío y ningún modo abierto (TR-interact-021).
- [ ] **AC-38b (pausa)**: tras pausa y reanudación con el rayo sobre otro objeto, el objetivo se recalcula en el primer paso tras reanudar.
- [ ] Prueba de rendimiento (T-P1): 40 entradas, 600 pasos, media ≤ 0,25 ms y pico ≤ 0,5 ms; `get_target()` devuelve el mismo `Dictionary` mientras no cambie (sin asignación por paso).

---

## Implementation Notes

*Derived from ADR-0011 D2/D9/D10:*

- `configurar(ctx)`: `ctx.require(&"interaction", [...])`; recoge `get_tree().get_nodes_in_group(&"interactable_pick")`, valida IDs contra el catálogo y construye `PickRegistry`; lint de escena (T-S3): pick en bit 3 solamente, un `BoxShape3D` sin escalar, `monitoring`/`monitorable` apagados, envolviendo su cuerpo sólido.
- Costuras inyectadas: `EyeRaySource` (adaptador de `Player.rayo_vision()`, ADR-0012), `OcclusionProbe`, `GameClock`, sinks de `InputRouter`, `PromptSink` (doble hasta ADR-0016), bus.
- Pausa: `_physics_process` empieza con `if _clock.is_paused(): return`; flanco detectado con `_was_paused`; al reanudar `steps_since_lost > N_gracia` y barrido completo.
- `get_target()`: `{id, etiqueta, largo, p, anillo_visible}` o vacío; documentar que el llamador no lo muta. Cada cambio → `InputRouter.set_target_long_verb(has_largo)`.
- Las firmas exactas de `ServiceContext.require` y del adaptador del Jugador: tomarlas de ADR-0009 D3 y ADR-0012 «Key Interfaces»; si el retorno de `rayo_vision()` no está fijado (ADR-0011 OI-4), **tarea de esta historia** con ADR-fallback registrado.

---

## Out of Scope

- Story 006/007: pulsación. Story 008–011: modos y vistas.

---

## Files

- `src/interaction/interaction_system.gd` (+ escena `planta` con el nodo, `process_physics_priority`)
- `tests/integration/interaction/barrido_en_planta_test.gd`, `tests/unit/interaction/barrido_rendimiento_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/interaction/barrido_en_planta_test.gd` (Jugador real o doble + escena de prueba con picks) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-004-focus-selector.md`; épicos `jugador-primera-persona` (`rayo_vision()`), `entrada-y-controles` (contextos, `set_target_long_verb`), `carga-de-planta` (`WorldSlot`, «escena lista»)
- Unlocks: `production/epics/interaccion-y-prompt/story-006-press-interpreter.md`
