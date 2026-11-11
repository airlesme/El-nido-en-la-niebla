# Story 008: Fallo de carga y estado Error

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M — 1 día (1–1,5; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R4 (anclas duplicadas), R14 (fallo), § States and Transitions (Error)
**Requirement**: `TR-scene-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (Load sequence «Failure»; D5) · ADR-0009 (manejador fatal en debug)
**ADR Decision Summary**: ante cualquier fallo (pasos 4 a espera) la cortina queda en α = 1, log con la causa, «carga de escena fallida» {destino, motivo, causa}, `restore_menu()`, estado Error y `ErrorPanel` con la única acción «Volver al título» que llama a `request_full_unload()`; nunca «escena lista», «terminada», «partida terminada» ni «descarga total completada» hasta terminar esa descarga. En debug, primero el manejador fatal.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguna.

**Control Manifest Rules (Core)**:
- Required: C-R02 (emisores únicos), C-R07 (`restore_menu` en fallo)
- Forbidden: cerrar la aplicación desde Error
- Guardrail: —

---

## Acceptance Criteria

- [ ] **AC-15a**: GIVEN la build final, WHEN falla el cargador por cada causa por separado (recurso ausente, escena no instanciable, contenedor obligatorio ausente, ancla de aparición ausente, `T_cap` alcanzado, datos de puzle inválidos), THEN la cortina doble queda en α = 1, hay log con la causa, se emite «carga de escena fallida», Entrada recibe `restore_menu` (pila [`menú`]), se pide el mensaje con «Volver al título» y al aceptarlo el estado es Sin escena; «descarga total completada» no se emite al fallar, sino una vez al terminar la descarga posterior; nunca «escena lista», «terminada» ni «partida terminada»; no se aclara.
- [ ] **AC-15b**: GIVEN build de desarrollo, WHEN ocurre cualquiera de esas causas, THEN el manejador de errores inyectado recibe un error visible.
- [ ] **AC-15c**: GIVEN dos anclas con el mismo nombre, THEN en desarrollo error visible; en la build final se usa la primera en orden de árbol con una línea de log.
- [ ] **AC-22**: GIVEN Error en build final, WHEN llega `pausa` o `atrás`, THEN no ocurre nada; WHEN `ui_aceptar` sobre «Volver al título», THEN pasa a Sin escena, entrega el título y al terminar la descarga se emite «descarga total completada» una vez; nunca se cierra la aplicación.

---

## Implementation Notes

- Causas como `StringName` (`missing_resource`, `instantiate_failed`, `missing_anchor`, `t_cap`, `invalid_puzzle_data`; añadir la de contenedor ausente). Las claves de los avisos son de ADR-0001.
- El panel se pide por un puerto/doble aquí; su vista es 014.

---

## Out of Scope

- 009: la descarga total; 014: el panel visible.

---

## Files

- `src/scene/scene_loader.gd`
- `tests/unit/scene/scene_loader_failure_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/scene/scene_loader_failure_test.gd` (T-U7) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-005-load-sequence.md`, `story-007-holds-and-tcap.md`
- Unlocks: `production/epics/carga-de-planta/story-009-full-unload.md`, `story-014-error-panel-ui.md`
