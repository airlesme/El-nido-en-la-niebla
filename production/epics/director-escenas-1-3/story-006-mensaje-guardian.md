# Story 006: Mensaje del Guardián — «Responder» → «Ahora no» → +1,0 s

> **Epic**: Director de escenas 1–3 (versión mínima)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M — 1,0 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Final de C.1: al pulsar «Responder», sale «Ahora no» y, 1,0 s después, «Este número ya no está
disponible». Si el jugador nunca responde, nada queda bloqueado.

**GDD**: `design/gdd/director-de-escenas.md` (reglas 15, 16)
**Requirement**: `TR-director-008`, `TR-director-019` (vuelta de `V02` a `reposo` con «interacción ejecutada» `HECHO`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017 D5 (`object_state_requested`), D2; ADR-0001 (aviso «interacción ejecutada»)
**ADR Decision Summary**: 21 es el único emisor de «estado de objeto pedido»; reacciona al aviso, no al valor.
**ADR Version**: ADR-0017 2026-11-10 · ADR-0001 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: FE-R21, FE-R23
- Forbidden: FE-X10 (el objeto `V02` no responde a `object_state_requested`)
- Guardrail: —

---

## Acceptance Criteria

- [ ] **GDD 21 AC-21-06**: con el mensaje pendiente, al pulsar «Responder» aparece «Ahora no» y 1,0 s después «Este número ya no está disponible» (±1 fotograma, `GameClock` falso); si nunca se pulsa, ningún puzle ni acceso queda bloqueado.
- [ ] **TR-director-019 (parte escena 1)**: el primer «interacción ejecutada» sobre `V02` con `resultado` = `HECHO` devuelve `V02` a `reposo`.

---

## Implementation Notes

- Los textos son claves `TELEFONO_*` de 18 (H23 en la cola de diseño): el director solo emite IDs del catálogo, nunca texto propio. Si H23 no ha fijado las claves al empezar, el test usa las del Anexo C.1 como IDs provisionales y se anota.
- El objeto `V02` y su pantalla pertenecen a otro sistema: aquí, doble de `V02`.

---

## Out of Scope

- Presentación del mensaje en `V02`.

---

## Files

- `assets/data/director/scenes.json` (respuesta de `ESC1_LLEGADA`)
- `tests/integration/director_de_escenas/guardian_message_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/director_de_escenas/guardian_message_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/director-escenas-1-3/story-005-esc1-tiempos-c1.md`; claves `TELEFONO_*` (H23)
- Unlocks: `production/epics/director-escenas-1-3/story-008-encadenado-escenas-1-3.md`
