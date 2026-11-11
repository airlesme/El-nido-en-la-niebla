# Story 004: Tapa `A03` (DELEGAR) y habilitado de `A04`

> **Epic**: Documentos y bolsillo
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/documentos-y-bolsillo.md` — § Detailed Rules › E (cómo se leen); regla 15
**Requirement**: `TR-pocket-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D6 contrato de manejador `InteractionHandler`); ADR-0009 (adaptador de puerto, D5/D6); ADR-0002 (G-9 tweens del mundo en pausa)
**ADR Decision Summary**: `A03` es un interactuable `DELEGAR` a 20 con estados `cerrada`/`abierta` no guardados; se reconstruye `abierta` si `formulario_leido`; la tapa anima `t_tapa_s` sin bloquear; `A04` se habilita solo con `A03` abierta.
**ADR Version**: ADR-0011 2026-11-10 · ADR-0009 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (`Tween` en pausa)
**Engine Notes**: los tweens del mundo se crean con el nodo del mundo como dueño para que la pausa los detenga (ADR-0002 G-9).

**Control Manifest Rules (this layer)**:
- Required: FE-R06 (`can_interact` puro), F-R33 (adaptador con `WeakRef`).
- Forbidden: bloquear el contexto durante la animación de la tapa; `Timer` para `t_tapa_s`.
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/documentos-y-bolsillo.md`, scoped to this story:*

- [ ] **AC-09**: con `A03` cerrada, `A04` no está habilitado; al abrir `A03`, `A04` es legible; al cargar con `formulario_leido` verdadero, `A03` está abierta.
- [ ] **AC-21**: al activar `A03`, `A04` queda habilitado en el mismo paso y el jugador puede moverse y mirar durante `t_tapa_s` 0,6 s.
- [ ] La pausa congela la animación de la tapa (reloj falso / tween del mundo).

---

## Implementation Notes

- El habilitado de `A04` se expresa por el contrato de 7: el manejador de `A04` (de 20) contesta `NO` mientras `A03` esté cerrada (no hay hecho para `A03`, así que no cabe `habilitado_si`). Registrar esta elección en el GDD 20 § Decisiones tomadas si el GDD no lo fija (ADR-fallback).

---

## Out of Scope

- Pantalla de lectura de `A04`: diferida por ADR-0016. Escritura de `formulario_leido`: story 003.

---

## Files

- `src/systems/pocket/pocket_handlers.gd` (manejadores `A03`, `A04`)
- `tests/integration/pocket/tapa_a03_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/pocket/tapa_a03_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/documentos-y-bolsillo/story-003-escritor-de-hechos.md`, `production/epics/interaccion-y-prompt/story-007-orden-al-pulsar-y-aviso.md`
- Unlocks: recorrido M1 (`production/epics/interaccion-y-prompt/story-013-recorrido-m1-y-capturas.md`)
