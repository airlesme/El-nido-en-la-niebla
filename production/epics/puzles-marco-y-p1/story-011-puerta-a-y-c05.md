# Story 011: Puerta A tras resolver y `C05` fuera de objetivo

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1,0 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Al escribirse `archivo_abierto`, la puerta A (sistema 8) se abre en el mismo paso y `C05` deja de
ofrecerse. Integración real 8 + 9 sobre el bus.

**GDD**: `design/gdd/puzle-1-cronologia.md` (R36, R5, R6) · `design/gdd/marco-de-puzles.md` (R7, R35)
**Requirement**: `TR-puzzle1-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D15 (view gate y red de seguridad); ADR-0001 (aviso de cambio de hecho); ADR-0011 (`habilitado_si` en 7)
**ADR Decision Summary**: tras resolver, el marco cierra de inmediato una apertura por vía no normal (`cerrar_vista('C05','sistema')`); `C05` deja de ser objetivo con `archivo_abierto` verdadero.
**ADR Version**: ADR-0010 2026-11-10 · ADR-0001 2026-11-10 · ADR-0011 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: FE-R16
- Forbidden: FE-X05
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 11 AC-15 (primera parte)**: con 8 y 9 reales, al escribirse `archivo_abierto` la puerta A inicia `ANIM_DOOR_OPEN` en ese mismo paso, 8 no reproduce `SFX_UNLOCK` y al volver la cámara (t = 2,0 s) la puerta está abierta.
- [ ] **GDD 11 AC-1 (segunda parte)**: con `archivo_abierto` verdadero, `C05` no es objetivo en 7 (sin icono ni vista).
- [ ] **GDD 9 AC-42 (parte P1)**: `get_view_gate('C05')` con P1 `RESUELTO` → `SOLVED` y la vista no se abre.

---

## Implementation Notes

- La segunda mitad de AC-15 («`archivo_abierto` ya verdadero al cargar») depende de cargar partida → **Diferida** (ADR-0004); con estado inicial inyectado sí se prueba en la story 004.

---

## Out of Scope

- `ANIM_DOOR_OPEN` en sí: épico `production/epics/acceso-puerta-a-cajon-a05/`.

---

## Files

- `tests/integration/puzzle_1/p1_door_a_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/puzzle_1/p1_door_a_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/puzles-marco-y-p1/story-007-resolucion-immediate.md`; puerta A del épico `production/epics/acceso-puerta-a-cajon-a05/`; `habilitado_si` del épico `production/epics/interaccion-y-prompt/`
- Unlocks: None
