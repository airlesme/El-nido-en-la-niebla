# Story 015: Partida nueva hasta la planta gris — capturas y S-0003-C

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: L — 1,5 días (1–2; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Core Rules R9–R11, § Game Feel, § Visual/Audio Requirements
**Requirement**: `TR-scene-010`, `TR-scene-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (D4 y S-0003-C; Load sequence; «We will know this was right if»)
**ADR Decision Summary**: carga síncrona detrás del negro; S-0003-C (tirón de carga de la `planta` gris) diferido hasta que exista la `planta`: se mide aquí y se registra; si supera ~1 s en el hardware de referencia, ADR nuevo sobre D4.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: S-0003-C NOT RUN en el spike (faltaba `SceneSource` real y `planta` gris). Capturas **con el motor** (`--write-movie`), nunca del escritorio.

**Control Manifest Rules (Core)**:
- Required: C-R03, C-R04
- Forbidden: C-X03 (pasar a carga en hilo sin ADR)
- Guardrail: C-G02; P-21 del manifiesto (pendiente que esta historia cierra)

---

## Acceptance Criteria

- [ ] **AC-11a (alcance M1: `partida_nueva`)**: GIVEN la planta cargada con motivo `partida_nueva`, THEN el jugador está en `spawn_office` (±0,01 m) con velocidad 0 y la orientación del ancla (±0,5°).
- [ ] **AC-12a (V, variante planta)**: GIVEN la carga de `planta` con reloj forzado, WHEN α = 0,5 del fundido, THEN una captura retenida tiene luminancia media del 50 % ± 5 % de la de la escena sin cortina; WHEN α = 1, THEN otra tiene RGB = (0, 0, 0) en el centro y las cuatro esquinas y ningún elemento de interfaz visible.
- [ ] **C-M1-1 (parte de este épico)**: partida nueva carga `planta` y llega a exploración en `playtest-windows` y `playtest-linux` sin consola de depuración; **C-M1-7**: captura retenida del Archivo.
- [ ] **AC-X2 (parcial)**: playtest documentado en gris: la cortina solo cambia de α en el aclarado de la partida nueva y no aparece interfaz de carga. **S-0003-C**: tirón de la carga síncrona medido y anotado en ADR-0003 § Spike Results (informativo, C-M1-10).

---

## Implementation Notes

- En M1 no hay título: el arranque de playtest pide `request_load(PLANTA, PARTIDA_NUEVA, …)` desde `Boot`/dev; `control_final` según el Director (21): con `ninguno`, el traspaso lo hace 21 (si su épico aún no está, usar `exploracion` y anotarlo).
- Medir S-0003-C con `RealClock` entre los pasos 3 y 4 en el export; repetir 5 veces y anotar mediana y peor caso.

---

## Out of Scope

- Captura del despacho y corredor a 30/60/144 fps: `production/epics/jugador-primera-persona/story-013-gray-walk-evidence.md`.

---

## Files

- `production/qa/evidence/carga-015-archivo.png`, `production/qa/evidence/carga-015-curtain-*.png`
- `production/qa/evidence/story-015-new-game-gray-walk-evidence-evidence.md`
- `docs/architecture/adr-0003-scene-loading-and-sin-control-handoff.md` (fila S-0003-C)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas retenidas en `production/qa/evidence/` (motor, `--write-movie`) + sign-off en `production/qa/evidence/story-015-new-game-gray-walk-evidence-evidence.md` con la medida de S-0003-C.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-006-no-control-input-contract.md`, `story-013-gray-planta-geometry.md`, `story-014-error-panel-ui.md`
- Unlocks: `production/epics/jugador-primera-persona/story-013-gray-walk-evidence.md`
