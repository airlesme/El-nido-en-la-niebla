# Story 009: Descarga total

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Complete — 4/4 criterios cumplidos (AC-16b, AC-16d parte de 4, rechazos/Lista/Error/t_unload, T-I5); el título es un marcador; la voz de 23 y el bloque de 26 quedan para esos sistemas
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R15 (descarga total)
**Requirement**: `TR-scene-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (D7; tabla «Full unload»; Key Interfaces `request_full_unload`) · ADR-0002 (`PROCESS_MODE_ALWAYS` con el árbol en pausa)
**ADR Decision Summary**: `request_full_unload()` solo desde Lista y Error: «descarga total solicitada» (sin datos) → Sin escena → oscurecer con 0,1 s si α < 1 → en α = 1 `queue_free` del hijo (sin reset de pila) → en U+1 `restore_menu()` y «descarga total completada»; aviso si `t_unload > t_descarga_total_max_s` (3,0 s); instanciar `title.tscn` cuando la cola de `GameState` esté vacía.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: **S-0003-A (árbol en pausa)**: liberación válida e instancia inválida en U+1 en 10/10 con `SceneTree.paused = true`.

**Control Manifest Rules (Core)**:
- Required: C-R02 (`request_full_unload()` único camino a «completada»), C-R04, C-R05, C-R12
- Forbidden: C-X05
- Guardrail: C-G02

---

## Acceptance Criteria

- [ ] **AC-16b (I, PV)**: GIVEN una escena cargada, WHEN se pide la descarga total, THEN el sistema queda en Sin escena, la cortina en α = 1 y sin escena de juego en el árbol.
- [ ] **AC-16d (parte de 4)**: GIVEN una escena cargada, WHEN se acepta la descarga total, THEN 4 emite «descarga total solicitada» una sola vez, antes de descargar y antes de «completada»; «completada» se emite una sola vez al terminar; GIVEN un fallo de carga sin aceptar el mensaje, THEN ninguno de los dos se emite. *(La voz de 23 y el bloque de 26: al existir esos sistemas; 23 bloqueado por ADR-0008.)*
- [ ] Se rechaza en Cargando y en Sin escena; funciona desde Lista y desde Error; `t_unload` > 3,0 s → advertencia en el log.
- [ ] Con el árbol en pausa la descarga completa termina y el orden «solicitada → completada» se mantiene (T-I5, parte de 4).

---

## Implementation Notes

- **Decisión (ver `stories.md`)**: no hay título en M1 (GDD 27 fuera); el paso 5 instancia un `src/shell/title.tscn` **marcador** (vacío o un `Label`) para cerrar «Volver al título». La transición del telón sobre el título es O4 de ADR-0003 (abierta): no se decide aquí.
- Fases `UNLOAD_FADING, UNLOAD_FREEING, TITLE_PENDING` de § Key Interfaces.

---

## Out of Scope

- Pantalla de título real (GDD 27), menú de pausa (recorte 5).

---

## Files

- `src/scene/scene_loader.gd`, `src/shell/title.tscn` (marcador)
- `tests/unit/scene/full_unload_test.gd`, `tests/integration/scene/pause_full_unload_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/scene/full_unload_test.gd` (T-U8) — must exist and pass; `tests/integration/scene/pause_full_unload_test.gd` (T-I5, parte de 4).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-008-load-failure-error-state.md`
- Unlocks: `production/epics/carga-de-planta/story-014-error-panel-ui.md`

## Evidencia

- `src/scene/scene_loader.gd`: `request_full_unload()` y fases `UNLOAD_FADING/UNLOAD_FREEING/TITLE_PENDING`; `src/scene/scene_source.gd` (`TITLE`); `src/shell/title.tscn` (marcador).
- `tests/unit/scene/full_unload_test.gd` (12 tests, T-U8) y `tests/integration/scene/pause_full_unload_test.gd` (1 test, T-I5, árbol pausado, nodos reales): pasan.
- Suite bloqueante: 934/934, 0 fallos, 0 orphans; sin `ObjectDB instances were leaked` ni `resources still in use`. `--import` y `--boot-report` sin errores.
- Pendiente fuera de esta historia: `unbind_scene()` (ADR-0009 D6, `# TODO(adr-0009-d6)`); la vista del panel y su acción «Volver al título» (014 llama a `request_full_unload()`); transición del telón sobre el título (O4, abierta).
