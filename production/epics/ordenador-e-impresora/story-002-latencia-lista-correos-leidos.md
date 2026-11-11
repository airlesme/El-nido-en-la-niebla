# Story 002: Latencia 0,4 s, lista en orden fijo 3, 1, 4, 2 y `correos_leidos`

> **Epic**: Ordenador (búsqueda) e impresora
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Anexo C.2 del slice: «Al escribir “transición”, los resultados aparecen tras 0,4 s. Al mostrarse el
primer resultado, se activa `correos_leidos`. Resultados en orden visual: 3, 1, 4 y 2, con los dos
distractores entre ellos.» 19 es el escritor único de `correos_leidos` (C-M1-4).

**GDD**: `design/gdd/ordenador-correo-impresora.md` (R12, R13, R14, R15, R21, F2)
**Requirement**: `TR-computer-006`, `TR-computer-008`, `TR-computer-009`, `TR-computer-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 D1, D6 (`GameClock`, sin temporizadores del árbol); ADR-0001 (`FactWriter` de 19, escritura → aviso); ADR-0005 (orden fijo de 18)
**ADR Decision Summary**: `t_busqueda` 0,4 s en tiempo de juego (se para en pausa); `correos_leidos` se escribe una vez, en el fotograma del primer resultado; la lista no se reordena.
**ADR Version**: ADR-0002 2026-11-10 · ADR-0001 2026-11-10 · ADR-0005 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0002: pausa del árbol; aquí solo `GameClock`)
**Engine Notes**: tests con `GameClock` real avanzado con `advance()` y `NullPauseBackend` (reloj falso).

**Control Manifest Rules (this layer)**:
- Required: tiempo solo por `GameClock`
- Forbidden: F-X10 (`create_timer`, `Timer`)
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 19 AC-02**: con coincidencia, la lista aparece a los 0,4 s de tiempo de juego; con la pausa abierta durante la espera, el contador se detiene.
- [ ] **GDD 19 AC-03**: la lista tiene exactamente 6 filas en el orden `MAIL_3, MAIL_X1, MAIL_1, MAIL_4, MAIL_X2, MAIL_2` (4 si `resultados_incluyen_ruido` = falso).
- [ ] **GDD 19 AC-04**: con `correos_leidos` falso, al mostrarse el primer resultado pasa a verdadero en ese mismo fotograma y «Imprimir» se habilita.
- [ ] **GDD 19 AC-24 / AC-26**: cierre (`sistema` o `atrás` a 0,3 s) antes de la lista → sin lista ni `correos_leidos`; al reabrir el campo conserva el texto.

---

## Implementation Notes

- `GameClock` del esqueleto no tiene aún `deadline`/`is_due`: **tarea con ADR-fallback** en `estado-y-bus` con las firmas de ADR-0002 § Key Interfaces (l. 527–530).
- `FactWriter(19)`: según ADR-0001 / ADR-0009 D3 (composición).

---

## Out of Scope

- Story 004: la impresora.
- Story 009: aspecto de la lista.

---

## Files

- `src/world/computer/computer_session.gd` (fallback de ruta)
- `tests/unit/computer/search_latency_and_order_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/computer/search_latency_and_order_test.gd` con `GameClock` falso y `RecordingFactWriter` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ordenador-e-impresora/story-001-busqueda-normalizacion.md`; `GameClock`/`FactWriter` (`production/epics/estado-y-bus/`)
- Unlocks: `production/epics/ordenador-e-impresora/story-004-impresora-v08-entrega-i01.md`, `production/epics/ordenador-e-impresora/story-009-overlay-gris-capturas.md`
