# Story 014: `ErrorPanel` sobre el telón

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Ready
> **Layer**: Core
> **Type**: UI
> **Estimate**: S — 0,5 días (0,5–1; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R11, R14; § UI Requirements
**Requirement**: `TR-scene-018`, `TR-scene-014` (solo el mensaje por encima del telón)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (Load sequence «Failure»: `ErrorPanel` encima del telón, acción única «Volver al título» con `ui_aceptar` o cursor; Implementation Guidelines)
**ADR Decision Summary**: en Error la cortina queda en negro y el `ErrorPanel` (`PROCESS_MODE_ALWAYS`, única capa por encima del telón) muestra el mensaje legible con una sola acción.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Captura **con el motor** (`--write-movie`, `.claude/docs/run-and-observe.md`), nunca del escritorio.

**Control Manifest Rules (Core)**:
- Required: C-R12
- Forbidden: C-X08 (otra capa por encima del telón)
- Guardrail: —

---

## Acceptance Criteria

- [ ] **AC-12b (V)**: GIVEN el fallo de carga de la build final (AC-15a), THEN una captura retenida muestra el mensaje de error legible por encima de la cortina en negro.
- [ ] La única acción es «Volver al título», aceptable con `ui_aceptar` y con el cursor; `pausa`/`atrás` no hacen nada (AC-22, lógica en 008).
- [ ] C-M1-3: ningún fallo deja la partida sin salida (el panel aparece en cada causa de AC-15a provocada a mano en un export de playtest).

---

## Implementation Notes

- **Decisión (ver `stories.md`)**: `Label` + `Button` con el tema por defecto; **no** se usa la pila de texto, escalado ni números de capa de ADR-0016 / ADR-0007 (ambos Proposed). Texto desde datos (no en código); clave a acordar con el épico de contenido (ADR-0005).
- Para provocar el fallo: fixture/dev flag que fuerce `missing_resource` en una build de playtest.

---

## Out of Scope

- Estilo final del panel (ADR-0016) y accesibilidad de tamaño de texto (ADR-0007).

---

## Files

- `src/shell/error_panel.tscn`, `src/shell/error_panel.gd`
- `production/qa/evidence/carga-014-error-panel.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: captura retenida del panel en `production/qa/evidence/` (motor, `--write-movie`).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-001-shell-worldslot.md`, `story-008-load-failure-error-state.md`, `story-009-full-unload.md`
- Unlocks: `production/epics/carga-de-planta/story-015-new-game-gray-walk-evidence.md`
