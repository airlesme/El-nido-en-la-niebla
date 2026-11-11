# Story 004: `SceneLoader` — precondiciones y estados

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R7, R13, § States and Transitions
**Requirement**: `TR-scene-008`, `TR-scene-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (§ Preconditions of `request_load`; § Key Interfaces; D5) · ADR-0009 (`setup(ctx)`, `ctx.require`) · ADR-0001 (lectura de `llamada_completada`)
**ADR Decision Summary**: `request_load(destination, reason, final_control) -> bool` rechaza (dev: manejador fatal; release: una línea de log; `false`) en Cargando (incluida una segunda petición en el mismo fotograma), en Error, con `GameState` no Listo o restaurando, `recepcion` con `llamada_completada` falso, `planta` con `recepcion` cargada, `recepcion` desde Sin escena.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguna en esta historia.

**Control Manifest Rules (Core)**:
- Required: C-R05; firmas de § Key Interfaces (`enum State { NO_SCENE, LOADING, READY, ERROR }`, `Destination`, `Reason`, `FinalControl`, `get_state()`)
- Forbidden: C-X05 (`SceneLoader` nunca escribe un hecho; solo lee `llamada_completada`)
- Guardrail: C-G02

---

## Acceptance Criteria

- [ ] **AC-07a**: GIVEN el estado (3) en Listo y este sistema en Sin escena, WHEN se pide `planta` con `partida_nueva` (y con `reanudar`), THEN se acepta y entra en Cargando; GIVEN el estado (3) sin cargar o en restauración, THEN se rechaza en los dos modos y no cambia de estado ni llama al cargador.
- [ ] **AC-07b**: GIVEN Lista, WHEN llegan dos peticiones válidas en el mismo fotograma, THEN se acepta la primera y se rechaza la segunda (dos modos); WHEN llega una durante Cargando, THEN se rechaza igual.
- [ ] **AC-14**: GIVEN `llamada_completada` falso, WHEN se pide `recepcion`, THEN se rechaza como en AC-07 (escrituras en el estado = 0, mismo estado, misma escena, 0 llamadas al cargador); GIVEN verdadero, THEN se acepta con `control_final` = `ninguno`.
- [ ] **AC-16a (parte de rechazo)**: WHEN se pide `planta` con `recepcion` cargada sin descarga total, THEN se rechaza como en AC-07.

---

## Implementation Notes

- **Decisión (ver `stories.md`)**: se mantiene `setup(ctx: ServiceContext)` del esqueleto y de ADR-0009 D2; `SceneSource`, `Curtain`, `InputContexts`, `RealClock` y `LoadTransitions` se obtienen por `ctx.require`. ADR-0003 § Key Interfaces lista un `setup` de 6 parámetros: pedir la enmienda a ADR-0003 al cerrar la historia.
- Modos: dev → manejador fatal inyectado (ADR-0009); release → descarta + log (`BuildFlavor`).
- `recepcion` no existe en M1: las ramas de rechazo se prueban con dobles; no se crea `recepcion.tscn`.

---

## Out of Scope

- 005: lo que pasa tras aceptar; 008: Error; 009: `request_full_unload`.

---

## Files

- `src/scene/scene_loader.gd`
- `tests/unit/scene/scene_loader_preconditions_test.gd`
- `tests/unit/scene/doubles/` (estado falso, cargador falso, bus falso)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/scene/scene_loader_preconditions_test.gd` (T-U1) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-001-shell-worldslot.md`; `GameState` con estado Listo/restaurando legible (épico Estado/bus, ADR-0001)
- Unlocks: `production/epics/carga-de-planta/story-005-load-sequence.md`, `story-010-stale-scene-warning.md`
