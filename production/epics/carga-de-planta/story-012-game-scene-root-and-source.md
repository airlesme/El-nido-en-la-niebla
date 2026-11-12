# Story 012: `GameSceneRoot` y `SceneSource` real

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Done (2026-11-12)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M — 1 día (1–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R2–R4 (contenedores y anclas obligatorios), R9 paso 6 (orden de configuración)
**Requirement**: `TR-scene-003`, `TR-scene-005`, `TR-scene-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (D4; Key Interfaces `SceneSource`, `GameSceneRoot`) · ADR-0009 (`configurar(ctx) -> void`) · ADR-0010 (D13: `PuzzleFramework.configuration_failed()`)
**ADR Decision Summary**: `SceneSource.instantiate(destination) -> Node` es la única clase que toca la carga de recursos (`load(path)` como `PackedScene` + `instantiate()`; `null` en fallo, nunca lanza); `GameSceneRoot` (raíz de `planta.tscn`) expone `get_player()`, `get_zone_hub()`, `validate_required_nodes()` y `configure_all(ctx)` (7 → 9 → grupo `scene_element` en orden de árbol; tras 9 pregunta `configuration_failed()` → `INVALID_PUZZLE_DATA`).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `SceneSource` real era «NOT SOURCEABLE until S-0003-A»; **S-0003-A PASS** (instanciar/liberar en 4.7.2 sin huérfanos) lo desbloquea. Carga síncrona (D4); nunca `ResourceLoader.load_threaded_*` (C-X03).

**Control Manifest Rules (Core)**:
- Required: C-R03, C-R06 (grupo `scene_element`, `configurar` síncrono o hold)
- Forbidden: C-X03
- Guardrail: C-G02

---

## Acceptance Criteria

- [ ] **AC-23 (con la raíz real)**: GIVEN elementos espía de 7, 9 y otro bajo un `GameSceneRoot`, WHEN `configure_all(ctx)`, THEN el orden es 7 → validación de 9 → configuración de 9 → resto, todos síncronos; GIVEN `configuration_failed()` verdadero, THEN devuelve `INVALID_PUZZLE_DATA` y no configura el resto.
- [ ] `validate_required_nodes()` devuelve vacío con todos los contenedores y anclas obligatorios de M1 y la lista de faltantes cuando falta `spawn_office`, `office`, `corridor` o `archive` (alimenta las causas de AC-15a en 008).
- [ ] `SceneSource.instantiate(&"planta")` devuelve la instancia; con una ruta ausente o un recurso no instanciable devuelve `null` sin excepción.

---

## Implementation Notes

- Firmas exactas de § Key Interfaces (`@export var spawn_anchor: NodePath`, `@export var configure_first: Array[NodePath]`, `const ELEMENT_GROUP := &"scene_element"`, `enum ConfigureResult { OK, INVALID_PUZZLE_DATA }`).
- En M1 7 (Interacción) y 9 (Marco de puzles) pueden no existir aún: `configure_first` admite vacío; los espías del test los sustituyen.
- **Anclas obligatorias de M1**: `spawn_office`, `door_slot_a`, `drawer_slot_a05`; `door_slot_b`, `door_slot_d`, `door_slot_elevator` son de salas fuera de M1 → decisión: se exigen solo las de M1 mediante una lista en datos, anotada en ADR-0003 O-items (no se inventan anclas).

---

## Out of Scope

- 013: el contenido de `planta.tscn`.

---

## Files

- `src/scene/scene_source.gd`, `src/scene/game_scene_root.gd`
- `tests/integration/scene/game_scene_root_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/scene/game_scene_root_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-005-load-sequence.md`
- Unlocks: `production/epics/carga-de-planta/story-013-gray-planta-geometry.md`

---

## Evidencia

- `tests/integration/scene/game_scene_root_test.gd`: 12/12 PASSED, 0 orphans (AC-23 con la raíz real: 7 → validación 9 → 9 → resto, sin doble configuración, `INVALID_PUZZLE_DATA` sin configurar el resto; `validate_required_nodes` vacío y por cada faltante `spawn_office`/`office`/`corridor`/`archive`; `SceneSource` con ruta ausente, recurso no-escena y destino desconocido → `null`; instancia correcta con fixture `tests/integration/scene/fixtures/minimal_world.tscn`).
- Suite bloqueante completa: 859 casos, 0 errores, 0 fallos, 0 huérfanos; 0 apariciones de `ObjectDB instances were leaked` / `resources still in use`. `--import` y `--boot-report` sin errores.
- Decisiones/TODO: lista de nodos obligatorios M1 como datos (`required_nodes`), pendiente anotarla en ADR-0003 O-items (`TODO(adr-0003-o-item)`); rutas de `planta.tscn`/`recepcion.tscn` en `SceneSource.DEFAULT_PATHS` (`TODO(carga-013)`); `configuration_failed()` por duck-typing hasta que exista `PuzzleFramework`; `get_player()` devuelve `Node` hasta que exista `Player` (`TODO(pj-011)`).
- Pendiente fuera de alcance: `tests/unit/scene/doubles/scene_root_double.gd` sigue siendo un doble (no se ha sustituido). SceneSource real con `planta.tscn` real depende de 013.
