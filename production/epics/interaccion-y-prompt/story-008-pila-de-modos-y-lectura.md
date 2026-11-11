# Story 008: Pila de modos y lectura (`abrir_lectura`, `lectura_min_s`, petición aplazada)

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L — 1,5 días (1–2,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Core Rules, reglas 16, 17, 18, 27, 27b; § States and Transitions
**Requirement**: `TR-interact-012`, `TR-interact-020`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D10: `lectura_min_s` y tope de 3 s de la petición aplazada como plazos de `GameClock`); ADR-0001 (avisos `reading_opened`, `reading_completed`, `reading_closed`, `reading_discarded`, `modes_closed`); ADR-0002 (G-1 `deadline`/`is_due`)
**ADR Decision Summary**: los modos se apilan (`exploración`, `lectura`, `vista cercana`, `ordenador`; `inspección` fuera de M1); `atrás` cierra solo el superior; `abrir_lectura(doc_id)` devuelve `ACEPTADA`/`APLAZADA`/`RECHAZADA(motivo)` según la tabla de estado; plazos en `GameClock`.
**ADR Version**: ADR-0011 2026-11-10 · ADR-0001 2026-11-10 · ADR-0002 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguno; la pantalla de lectura la dibuja 20 (`ReadingScreen`, bloqueada por ADR-0016: ver épico documentos-y-bolsillo).

**Control Manifest Rules (this layer)**:
- Required: FE-R05; F-R31 (`SubscriptionBag`); ADR-0002 G-1.
- Forbidden: `Timer`/`create_timer` para `lectura_min_s` o el tope de 3 s.
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-22 / AC-23**: en `A04`, mantener `interactuar` 0,5 s pide `lectura` con la clave y el estilo; `R01` (catálogo de prueba) con dos páginas: `interactuar` pasa a la 2 y otra vez no hace nada.
- [ ] **AC-24 / AC-25 / AC-38b**: `lectura_min_s` 2,0 → «lectura completada» (`A04`) una sola vez a 2,0 s de juego; cerrada a 1,9 s no; la pausa de 10 s no avanza el contador; un `LEER` sin `lectura_min_s` nunca la emite.
- [ ] **AC-27e (1)–(8)**: en `exploración` estable → `ACEPTADA` (contexto `lectura`, `HAND_READ`); con vista `Saliendo` → `APLAZADA` y se abre al volver a `exploración` con «lectura abierta»; con pausa → `APLAZADA` sin contar el tope; > 3 s de juego → «lectura descartada» y registro; con `ordenador`, otra lectura o una petición ya aplazada → `RECHAZADA(motivo)`; `atrás` vuelve a `exploración` y `reposo()`; la vía `repasar_bolsillo` recibe el mismo trato.
- [ ] **AC-35b / AC-26e**: vista abierta con lectura apilada: `atrás` cierra solo la lectura; `cerrar_modos()` cierra lectura y luego vista con motivo `sistema`; `cerrar_vista(resuelto)` con la lectura abierta espera a cerrarla; lectura programática con objeto sujeto pide `reposo()` antes de `HAND_READ`.

---

## Implementation Notes

*Derived from ADR-0011 D10 y GDD reglas 16–18, 27b:*

- Una única petición aplazada; caduca por `GameClock.deadline` (3 s), no corre en pausa.
- `cerrar_modos()` emite una vez «modos cerrados» con la lista al vaciarse la pila; `llamada` no se cierra.
- La firma de `abrir_lectura` y su enumeración de motivos: si ADR-0011 «Key Interfaces» la fija, usarla; si no, ADR-fallback registrado (tarea de la historia).

---

## Out of Scope

- Story 009/010: vistas cercanas. Épico documentos-y-bolsillo: escritura de `formulario_leido` y repaso.

---

## Files

- `src/interaction/mode_stack.gd`, `src/interaction/reading_gate.gd`
- `tests/unit/interaction/pila_de_modos_test.gd`, `tests/unit/interaction/abrir_lectura_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/interaction/pila_de_modos_test.gd`, `abrir_lectura_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-007-orden-al-pulsar-y-aviso.md`
- Unlocks: `production/epics/interaccion-y-prompt/story-009-vista-cercana-ciclo.md`, `production/epics/documentos-y-bolsillo/story-003-escritor-de-hechos.md`, `production/epics/documentos-y-bolsillo/story-006-repaso-del-bolsillo.md`
