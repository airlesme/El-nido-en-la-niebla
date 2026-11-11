# Story 008: Escritura validada y `FactWriter` (tipo, rango, dueño en dev)

> **Epic**: Estado y bus de eventos
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/estado-y-bus-de-eventos.md` § Detailed Design › Core Rules, reglas 2 (escritor único), 3 (aplicación inmediata) y 4 (validación estricta)
**Requirement**: `TR-state-003`, `TR-state-004`, `TR-state-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Event bus and fact contract (D7; § Drain and Write Algorithms; G-1)
**ADR Decision Summary**: La identidad del escritor es una capacidad: `Boot` entrega a cada sistema un `FactWriter` atado a su número (`GameState.writer_for(9)`). Una escritura válida se aplica en el acto (aunque esté drenando) y solo el aviso se encola; el dueño se comprueba solo en builds de desarrollo, el resto de la validación siempre.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: comprobación de tipo estricta con `typeof()`: `float` en `int` y `int` en `bool` son inválidos (sin conversión implícita).

**Control Manifest Rules (this layer)**:
- Required: F-R05 (escribir solo por el `FactWriter` propio), F-R09, F-R66 (dev decidido por `BuildFlavor`)
- Forbidden: que un sistema pase su propio número de dueño
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/estado-y-bus-de-eventos.md`, scoped to this story:*

- [ ] **CA-02 (escritura)**: tras una escritura válida del dueño, la lectura devuelve el nuevo valor.
- [ ] **CA-06**: en release, escribir un hecho no declarado, `Tarjeta_B`, `pos_L = 5`, un `bool` con cadena o un `float` en un `int` conserva el valor y añade exactamente una línea de log (y la escritura en «Sin cargar» se descarta, CA-27).
- [ ] **CA-08**: en dev, la escritura de un hecho cuyo `owner` es X hecha por Y es inválida (`ErrorPolicy.fail`); en release no se comprueba el dueño.
- [ ] **CA-13**: un suscriptor que al recibir X escribe Y lee Y nuevo inmediatamente, y el aviso de Y llega después de que X alcance a todos los suscriptores. Escribir el valor actual devuelve `true` y no encola aviso (CA-10).

---

## Implementation Notes

- Firmas (ADR-0001): `writer_for(owner_id: int) -> FactWriter` (solo composición), `set_fact(fact, value, owner_id) -> bool`; `FactWriter._init(state, owner_id)`, `FactWriter.write(fact, value) -> bool`. `true` = aceptado (cambiado o idéntico).
- Seguir § Drain and Write Algorithms: validar → aplicar → `push_change` (solo si cambia). Los derivados (010) y el sentido único (009) se enganchan en los mismos puntos.

---

## Out of Scope

- Story 009 (sentido único), 010 (derivados), 012 (`write_silent`).

---

## Files

- `src/core/game_state.gd`, `src/core/fact_writer.gd`
- `tests/unit/state/validated_writes_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/state/validated_writes_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-003-notice-channel-cap-and-lifecycle.md`, `production/epics/estado-y-bus/story-007-fact-reads.md`
- Unlocks: `production/epics/estado-y-bus/story-009-one-way-and-reversible-facts.md`, `production/epics/estado-y-bus/story-010-derived-facts.md`, `production/epics/estado-y-bus/story-011-reset-new-game.md`, `production/epics/estado-y-bus/story-012-silent-write-window.md`, `production/epics/estado-y-bus/story-014-boot-wiring-state.md`

---

## Evidencia

- `src/core/fact_writer.gd` (nuevo), `src/core/game_state.gd` (`writer_for`, `set_fact`, validación tipo/rango/enum/derivado/dueño-en-dev; `_owners`, `_ranges`, `_enum_values`, `_derived`).
- `tests/unit/state/validated_writes_test.gd`: 10 casos, 0 fallos (CA-02 escritura, CA-06, CA-08, CA-13, valor idéntico sin aviso, límites de rango, UNLOADED).
- Suite completa (Godot 4.7.2 local): `Overall Summary: 349 test cases | 0 errors | 0 failures | 0 orphans`, exit 0; `--import` sin errores; sin `ObjectDB instances were leaked` ni `resources still in use`.
- Pendiente de otras historias (ganchos marcados en `set_fact`): sentido único (EB-009), derivados (EB-010), `write_silent` (EB-012). Un hecho derivado se rechaza como no escribible.
