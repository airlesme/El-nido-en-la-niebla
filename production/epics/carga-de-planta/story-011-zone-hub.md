# Story 011: `ZoneHub` y `ZoneTrigger`

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Done (2026-11-12)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R5 (zonas disparadoras)
**Requirement**: `TR-scene-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (D8; Key Interfaces `ZoneHub`; Implementation Guidelines) · ADR-0011 (tabla de capas: `zone_sensor` 4, `zone_trigger` 5) · ADR-0001 (aviso «zona activada»)
**ADR Decision Summary**: cada `T-…` es un `Area3D` sin lógica (`monitoring = false` en el `.tscn`, máscara solo `zone_sensor`) que reenvía su ID a un `ZoneHub` por escena; el hub sella cada entrada con el tick de física, ordena por (tick, ID) y emite «zona activada» una vez por entrada; `SceneLoader` activa `monitoring` en el fotograma de «terminada».
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 (Jolt) | **Risk**: HIGH
**Engine Notes**: **Medido en S-0003-B (2026-11-11)**: 100 entradas, 0 dobles, 0 fallos; banda **(8,95; 8,977]** (observado 8,95013–8,97653) idéntica a 30/60/144 fps; dos zonas con caras coincidentes entran en el mismo tick (frame 150) y el motor las entregó T-A, T-B aunque T-B se añadió primero → **el hub debe ordenar por ID él mismo**; con el sensor ya dentro, 0 entradas mientras `monitoring` está apagado y 1 entrada un tick después de encenderlo; `Engine.get_physics_frames()` sella en cada callback.

**Control Manifest Rules (Core)**:
- Required: C-R09, C-R10, C-R11 (sellar con `Engine.get_physics_frames()` y ordenar por (tick, ID)), C-R02 (`ZoneHub` único emisor de «zona activada»)
- Forbidden: lógica o lectura de hechos en `ZoneTrigger`
- Guardrail: C-G02 (el hub ordena unas pocas entradas por fotograma)

---

## Acceptance Criteria

- [ ] **AC-05a (I, PV)**: GIVEN un jugador de prueba, WHEN entra en `T-PAS-1`, sale y vuelve a entrar, THEN «zona activada» se emite dos veces con el ID `T-PAS-1`.
- [ ] **AC-05b (I, PV)**: WHEN cruza en el mismo tick dos volúmenes solapados (`T-PAS-1`, `T-PAS-2`), THEN dos avisos ordenados lexicográficamente por ID en ese fotograma; WHEN aparece dentro de una zona (fixture), THEN su aviso sale en un fotograma posterior a «carga de escena terminada» y ninguno antes.
- [ ] Unidad (T-U9): entradas del mismo tick ordenadas por ID; de ticks distintos, por tick; cada reentrada emite.

---

## Implementation Notes

- Firmas de § Key Interfaces: `register(zone: ZoneTrigger) -> void`, `set_enabled(enabled: bool) -> void`. La lógica de orden en una clase pura testeable sin física; la parte física en integración headless.
- Capas por nombre de ADR-0011; los nombres en `project.godot` faltan (manifiesto P-23).
- La regresión de motor ya existe: `tests/unit/engine_facts/adr0003_zone_sensor_jolt_test.gd`.

---

## Out of Scope

- 013: colocación de las zonas de M1 en la planta; consumo de «zona activada» por el Director (21).

---

## Files

- `src/scene/zone_hub.gd`, `src/scene/zone_trigger.gd`
- `tests/unit/scene/zone_hub_order_test.gd`, `tests/integration/scene/zone_jolt_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/scene/zone_jolt_test.gd` (T-I4) and `tests/unit/scene/zone_hub_order_test.gd` (T-U9) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (el jugador de prueba es un `Area3D` de sensor; el `Player` real se prueba en `production/epics/jugador-primera-persona/story-012-physics-walk-integration.md`)
- Unlocks: `production/epics/carga-de-planta/story-013-gray-planta-geometry.md`, `production/epics/jugador-primera-persona/story-012-physics-walk-integration.md`

---

## Evidencia

- `src/scene/zone_entry_queue.gd` (orden puro por (tick, ID)), `zone_trigger.gd`, `zone_hub.gd`.
- `tests/unit/scene/zone_hub_order_test.gd` (T-U9, 6 tests) y `tests/integration/scene/zone_jolt_test.gd` (T-I4, 5 tests, Jolt real, sin ventana): AC-05a, AC-05b (orden por ID, spawn dentro emite en tick posterior a `set_enabled(true)` y ninguno antes), desactivar, registro tardío.
- Suite bloqueante: `Overall Summary: 713 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`, 65/65 suites; sin `ObjectDB instances were leaked` ni `resources still in use`. `--import` sin errores.
- Pendiente anotado: `# TODO(scene-owner)` en `ZoneHub`: ADR-0003 no fija cómo recibe el bus; fallback `configure(notify: Callable)` (payload `{&"zona": id}`, `NoticeIds.ZONE_ENTERED`). SceneLoader debe llamar `set_enabled(true)` en «terminada» (CP-001/013).
