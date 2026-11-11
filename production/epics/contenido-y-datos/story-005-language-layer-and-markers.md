# Story 005: Capa de idioma y marcadores `{vera}`/`{guardian}`

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, reglas 7 (idioma) y 8 (marcadores)
**Requirement**: `TR-content-005`, `TR-content-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D7 capa de idioma propia, no `tr()`; D6)
**ADR Decision Summary**: Todo texto se resuelve por (identificador, idioma) en una capa propia; si falta en el idioma, fallback a `es` con log; si falta también en `es`, «no encontrado» («…»). Los cuatro marcadores se sustituyen en la lectura desde una tabla de nombres en datos (D-04).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: no se usa `TranslationServer`/`tr()` (D7).

**Control Manifest Rules (this layer)**:
- Required: F-R61, F-R58
- Forbidden: `tr()` para texto de juego; nombres de personaje en código
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/base-de-contenido-narrativo.md`:*

- [ ] **AC-07**: con un idioma de prueba `xx` sin un identificador, se devuelve el texto en `es` y se registra; si falta en `es`, «no encontrado».
- [ ] **AC-08 (parte L)**: con la tabla de nombres, `{vera}`, `{guardian}`, `{vera_inicial}` y `{guardian_inicial}` se sustituyen (p. ej. `VO_V_12E` → «La V no me convence» con fixture); un marcador desconocido es inválido en la carga.
- [ ] **AC-E2**: «», —, á y ñ se conservan carácter a carácter.

---

## Implementation Notes

- Firma (ADR-0005): `get_text(id: StringName) -> String` («…» si no se encuentra). El idioma es fijo durante la sesión (`es` en el slice).
- La tabla de nombres es un fichero de `narrative/` registrado en D1; sus valores reales (D-04) los pone 009.

---

## Out of Scope

- Story 009: valores reales de la tabla de nombres.
- Token `{accion:<id>}`: diferido (ADR-0016, consumidor 24).

---

## Files

- `src/narrative/content_db.gd`, `src/narrative/content_snapshot.gd`
- `tests/unit/content/language_and_markers_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/language_and_markers_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-004-content-db-load-and-lifecycle.md`
- Unlocks: `production/epics/contenido-y-datos/story-009-m1-narrative-data.md`
