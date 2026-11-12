# Story 001: `Shell`, `WorldSlot`, telón y capas

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: In Progress — falta la parte de AC-01 «cargar `planta` dos veces» con el `SceneLoader` real (stories 004/005); el resto cumplido
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R1 (una escena de juego, nodos persistentes), R11 (cortina por encima del mundo y la interfaz)
**Requirement**: `TR-scene-001`, `TR-scene-002`, `TR-scene-014` (parte de capa)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (D1, D2; § Architecture Diagram; Implementation Guidelines) · ADR-0009 (autoloads y `setup(ctx)`) · ADR-0002 (process modes)
**ADR Decision Summary**: la escena principal es `Shell` (`res://src/shell/shell.tscn`), nunca descargada, con un `Node3D` `WorldSlot` (como mucho un hijo: `title`, `planta` o `recepcion`) y los `CanvasLayer` HUD, Subtitles, PauseMenu y Curtain (+ `ErrorPanel` encima); nunca `change_scene_to_*`.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `SceneLoader` ya existe como autoload esqueleto (`src/scene/scene_loader.gd`, `PROCESS_MODE_ALWAYS` en `_init`). **Medido en S-0003-A**: `get_instance_id()`/nodos estables tras 10 ciclos instanciar/liberar.

**Control Manifest Rules (Core)**:
- Required: C-R01 (`WorldSlot` con como mucho un hijo; solo `SceneLoader` lo toca), C-R12 (`SceneLoader`, `Curtain`, `ErrorPanel` en `ALWAYS`; telón con el `layer` más alto salvo `ErrorPanel`)
- Forbidden: C-X01 (`change_scene_to_file`/`_packed`/`reload_current_scene`; grep CI sobre `src/`), C-X02, C-X08 (capa por encima del telón salvo `ErrorPanel`)
- Guardrail: C-G02 (una sola escena de juego residente)

---

## Acceptance Criteria

- [ ] **AC-01 (alcance M1, I, PV)**: GIVEN el juego arrancado, WHEN se carga `planta` dos veces seguidas, THEN `get_instance_id()` de los autoloads persistentes existentes hoy (Estado/`GameState`, `InputRouter`, `Settings`, `AudioDirector`) es idéntico antes y después, y en cada fotograma muestreado hay exactamente una escena de juego bajo `WorldSlot`. *(La versión con `recepcion` y los sistemas 1, 6 y 23 completos se cierra cuando existan; ver `stories.md`.)*
- [ ] El `CanvasLayer` `Curtain` tiene el `layer` más alto salvo `ErrorPanel`; `Curtain` y `ErrorPanel` corren en `PROCESS_MODE_ALWAYS`; `WorldSlot` hereda (`PAUSABLE` vía ADR-0002).
- [ ] El grep de CI de C-X01 existe y falla si aparece `change_scene_to_file`, `change_scene_to_packed` o `reload_current_scene` en `src/` (vérselo fallar una vez).

---

## Implementation Notes

- `project.godot`: escena principal = `shell.tscn`. `Boot` sigue siendo el primer autoload (ADR-0009).
- La cortina es un `ColorRect` negro a pantalla completa en `Curtain`; su α la escribe solo `SceneLoader` (005).
- Los números exactos de capa (p. ej. 60/70) los propone ADR-0016, **Proposed**: aquí basta el orden relativo de C-R12; no adoptar la tabla de ADR-0016.

---

## Out of Scope

- 005: escritura de α; 014: contenido del `ErrorPanel`.

---

## Files

- `src/shell/shell.tscn`, `src/shell/shell.gd`, `src/shell/curtain.gd`
- `project.godot` (escena principal)
- `tools/ci/` script de grep de C-X01
- `tests/integration/scene/persistent_nodes_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/scene/persistent_nodes_test.gd` (T-I1 de ADR-0003, alcance M1) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/carga-de-planta/story-004-loader-preconditions-states.md`, `story-014-error-panel-ui.md`

---

## Evidencia

- **Discrepancia con la historia (decisión del lead, sprint-003 R-S3-6):** `Boot` NO es un autoload; es el PRIMER hijo de `Shell` (`shell.tscn` es `run/main_scene`). `# TODO(lead-programmer)` en `src/shell/shell.gd` para la enmienda de ADR-0009 («primer autoload» -> «primer hijo de `Shell`»). `src/core/boot/main.tscn` eliminado (ningún test lo usa; `autoload_registration_test.gd` ahora espera `shell.tscn`).
- Ficheros: `src/shell/shell.tscn|shell.gd|curtain.gd`, `tools/ci/forbid_scene_change.sh`, `tests/integration/scene/persistent_nodes_test.gd` (5 tests, sin ventana, sin `Boot` en la instancia para no repetir `compose()`).
- Capas relativas: HUD 10 < Subtitles 20 < PauseMenu 30 < Curtain 100 < ErrorPanel 110 (solo orden relativo; no es la tabla de ADR-0016). `Curtain` y `ErrorPanel` en `PROCESS_MODE_ALWAYS`; `WorldSlot` hereda.
- `--import`: sin errores. Arranque `--quit-after 5 -- --boot-report`: `[boot] flavor=debug dev_tools=absent version=dev commit=dev`, rc=0, sin errores.
- Suite bloqueante: `Overall Summary: 713 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`; 0 coincidencias de `ObjectDB instances were leaked` / `resources still in use`.
- Grep C-X01: `forbid_scene_change.sh` limpio sobre el repo; con un `.gd` falso con `change_scene_to_file` imprime el hallazgo y sale con rc=1 (visto fallar).
- **Pendiente:** AC-01 con `planta` cargada por el `SceneLoader` real: el test hace el intercambio a mano bajo `WorldSlot` (ids de autoloads estables, un solo hijo por muestra). Cerrar cuando existan 004/005. El grep no está aún enganchado a un workflow de CI.
