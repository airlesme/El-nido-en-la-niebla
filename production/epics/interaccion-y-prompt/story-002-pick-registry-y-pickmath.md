# Story 002: `PickRegistry` y `PickMath` — contactos F1 aritméticos

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Done (2026-11-11; evidencia abajo)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L — 1,5 días (1–2,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Formulas › F1 (pasos 1–2); § Core Rules, reglas 2 y 5
**Requirement**: `TR-interact-003`, `TR-interact-002` (origen del rayo)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D2, D3, G-1, G-3, G-10)
**ADR Decision Summary**: los contactos de F1 se calculan con aritmética pura sobre un registro por escena de volúmenes `BoxShape3D` (prefiltro, slab test, distancia al eje por sección áurea de 24 iteraciones); ni `intersect_shape` ni `ShapeCast3D` en el foco.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (dominio Physics/Jolt; mitigado: la ruta crítica no usa APIs no documentadas)
**Engine Notes**: S-0011-A: `BoxShape3D.size` se lee (V02 → (0,15, 0,08, 0,02)); `monitoring`/`monitorable` = false siguen consultables. `ShapeCast3D` informa solo del contacto más cercano (1 de 8) → prohibido. `intersect_shape` solo en el camino de escalado D11 (no en el slice) y **siempre con `max_results` explícito ≥ nº de volúmenes** (por defecto 32 trunca; sin orden por distancia ni ID) — FE-R03; el oráculo de prueba puede usarlo así.

**Control Manifest Rules (this layer)**:
- Required: FE-R01 (contactos por `PickMath` sobre `PickRegistry`), FE-R04 (un `BoxShape3D` sin escalar en bit 3), FE-R10 (sin asignaciones por paso).
- Forbidden: FE-X01 (`intersect_shape`/`ShapeCast3D` para el foco), FE-X02 (abanico de 7 rayos).
- Guardrail: FE-G01 — barrido ≤ 0,25 ms media / 0,5 ms pico con 40 entradas; registro < 1 ms.

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-01**: un objeto del mundo que no está en `interactables.json` no es contacto (un pick con ID desconocido o duplicado es error de datos en `configurar()`).
- [ ] **AC-02**: el teléfono a 1,38 m con alcance 1,8 es contacto; a 1,9 m, no.
- [ ] **AC-07b**: con balanceo `completo` el origen es `rayo_vision()` del Jugador (ojos sin balanceo), no la cámara.
- [ ] `PickMath` devuelve, por contacto, `d_c`, `contains_axis` y `δ` exactos frente al cálculo analítico (±0,001 m) y es determinista (orden por `id`).

---

## Implementation Notes

*Derived from ADR-0011 D2/D3:*

- `InteractablePick` = `Area3D` + un `CollisionShape3D` con `BoxShape3D`, exporta `interactable_id: StringName` y `self_occluders: Array[NodePath]`; grupo de escena `&"interactable_pick"`.
- `PickRegistry` (denso, ordenado por `id` una vez): fila de catálogo, `prioridad`, `alcance_c`, `half_extents = size/2`, referencia `Node3D` para la transformada viva, índices de hecho de `habilitado_si` (`GameState.resolve_fact`), RIDs excluidos, radio envolvente `|h|`. Se reconstruye solo al cargar escena.
- `PickMath` (puro, sin física): 1) prefiltro `dist(centro, segmento) ≤ |h| + r`; 2) marco local `T⁻¹`; 3) slab test → `contains_axis`, `δ = 0`, `d_c = t_enter`; 4) si no, sección áurea con **24 iteraciones fijas** sobre `f(t)` convexa; `δ > radio_apuntado_m` → fuera; 5) `0 ≤ d_c ≤ alcance_c`.
- Arrays de candidatos preasignados y reutilizados (G-10). El origen llega por el puerto `EyeRaySource` (adaptador de `Player.rayo_vision()`, ADR-0012); en unitario, un doble.
- Prueba de oráculo opcional: `intersect_shape` con cápsula y `max_results = 64` contra el registro (medido 0 discrepancias en 8 posiciones).

---

## Out of Scope

- Story 003: oclusión. Story 004: agrupación, desempate, retención y `habilitado_si`/`can_interact` (D3.6).

---

## Files

- `src/interaction/interactable_pick.gd`, `src/interaction/pick_registry.gd`, `src/interaction/pick_math.gd`, `src/interaction/ports/eye_ray_source.gd`
- `tests/unit/interaction/pick_math_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/interaction/pick_math_test.gd` — must exist and pass (gdUnit4, headless, sin mundo de física).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-001-catalogo-interactuables.md`
- Unlocks: `production/epics/interaccion-y-prompt/story-003-capas-y-oclusion.md`, `production/epics/interaccion-y-prompt/story-004-focus-selector.md`

---

## Evidencia

- **Suite bloqueante** (`-a res://tests -i res://tests/timing`, Godot 4.7.2): 456 test cases | 0 errors | 0 failures | 0 orphans; 46/46 suites; salida completa sin `ObjectDB instances were leaked` ni `resources still in use`. `--import` sin errores.
- `tests/unit/interaction/pick_math_test.gd`: 19/19. AC-01 (id desconocido, vacío, duplicado, forma/escala/capa inválidas), AC-02 (1,38 m sí; 1,9 m no; 1,79/1,81 en el límite), AC-07b (origen del puerto `EyeRaySource`, no la cámara), orden por `id` y reutilización del pool, límites de radio y alcance, caja detrás, origen dentro, rayo paralelo, y oráculo de fuerza bruta con semilla 20261111 (400 rayos, 0 discrepancias).
- Notas: (1) con el rayo paralelo a una cara, `f(t)` es plana y `d_c` es cualquier profundidad dentro de la caja (ADR-0011 D3 tal cual; `delta` es exacto). (2) Ficheros: `pick_math.gd`, `pick_registry.gd`, `interactable_pick.gd`, `ports/eye_ray_source.gd` en `src/interaction/` (el ADR dice `focus/pick_math.gd`; se sigue la historia) y `ContactInfo` en `interaction_types.gd`.
- Pendiente fuera de alcance: `TODO(ADR-0012 OI-4)` adaptador de `rayo_vision()` (el puerto usa dos getters, sin asignaciones); `TODO(IP-003)` RIDs excluidos; `TODO(IP-004)` índices de `habilitado_si`. No medido FE-G01 (rendimiento real con 40 entradas).
