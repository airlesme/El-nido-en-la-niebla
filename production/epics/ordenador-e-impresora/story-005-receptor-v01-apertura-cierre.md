# Story 005: Receptor de vista `V01` — apertura, cierre, `atrás` y sesión en memoria

> **Epic**: Ordenador (búsqueda) e impresora
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1,0 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

El ordenador es una vista de 7: no recibe puntero hasta `on_open()`, y `atrás` lo cierra siempre.
Su estado de sesión vive solo en memoria.

**GDD**: `design/gdd/ordenador-correo-impresora.md` (R3, R7, R8, R9)
**Requirement**: `TR-computer-001`, `TR-computer-002`, `TR-computer-003`, `TR-computer-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (`ViewReceiver` `@abstract … extends RefCounted`, `registrar_receptor`); ADR-0006 (contexto de vista, `atrás`)
**ADR Decision Summary**: 19 implementa `ViewReceiver`; `on_close(motivo ∈ {jugador, sistema})` corre antes de devolver la cámara, igual en ambos motivos (saca foco, oculta teclado, `reposo()`, conserva consulta y lista).
**ADR Version**: ADR-0011 2026-11-10 · ADR-0006 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0006)
**Engine Notes**: `@abstract` en dos líneas (4.5); overrides tipados con `return` explícito (4.7).

**Control Manifest Rules (this layer)**:
- Required: FE-R09 (`seleccionar` como un único `FIN`)
- Forbidden: 19 no bloquea `atrás` (TR-computer-003)
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 19 AC-07**: en exploración, activar `V01` hace que 7 abra `ordenador` y 19 reciba `on_open()` solo tras `camara_cedida`; con `atrás`, `on_close(jugador)` llega antes de devolver la cámara.
- [ ] **GDD 19 AC-09 (parte `atrás`)**: con el teclado en pantalla abierto y texto escrito, `atrás` cierra el ordenador.
- [ ] **TR-computer-005**: `V01` pasa de `apagado` a `sesión abierta` solo en memoria; reiniciar el estado lo devuelve a `apagado` (la variante «tras cargar» → Diferido, ADR-0004).

---

## Implementation Notes

- Firmas de `ViewReceiver` exactamente como ADR-0011 l. 577 y siguientes.

---

## Out of Scope

- Story 006: `Retroceso`/`Esc` con foco en el campo y teclado en pantalla.
- Story 008: fundido de encendido.

---

## Files

- `src/world/computer/computer_view_receiver.gd` (fallback de ruta)
- `tests/integration/computer/computer_view_lifecycle_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/computer/computer_view_lifecycle_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `ViewReceiver`/`registrar_receptor` (`production/epics/interaccion-y-prompt/`)
- Unlocks: `production/epics/ordenador-e-impresora/story-006-foco-dual-teclado-pantalla.md`, `production/epics/ordenador-e-impresora/story-008-fundido-encendido.md`
