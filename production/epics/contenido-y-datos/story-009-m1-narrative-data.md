# Story 009: Datos narrativos de M1 (escenas 1–3, correos, `UI_`/`OBJ_`, tabla de nombres D-04)

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, reglas 2, 18 (lista de revisión) y 23 (claves provisionales); `design/slice/slice-v0.3.md` §12 (texto de las líneas) y C.1–C.3
**Requirement**: `TR-content-002` (subconjunto de M1)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D1 ficheros `narrative/*`; D9)
**ADR Decision Summary**: Datos en `assets/data/narrative/*.json` con `schema_version`, `fuente: slice_§12` en las entradas del slice y marcador de pendiente en las provisionales; nombres de Vera y del Guardián desde la tabla de nombres (D-04), nunca en el texto.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (solo datos)
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: F-R56, F-R64, F-R61
- Forbidden: texto visible en escenas o scripts
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/base-de-contenido-narrativo.md` y el hito M1, scoped to M1:*

- [ ] **C-M1-1 / C-M1-9 (datos)**: las líneas de escenas 1–3 (`VO_V_01`, `MEGA_01`, `VO_V_04` y las que cite el slice en C.1–C.3), los 6 correos, el mensaje «¿Jugamos esta noche?» / «Ahora no» / «Este número ya no está disponible», los textos `UI_…`/`OBJ_…` que piden las vistas de M1 y la tabla de nombres D-04 cargan sin issues al arrancar (smoke).
- [ ] Texto de las entradas `fuente: slice_§12` copiado literalmente del §12 (lo comprueba 011).
- [ ] **AC-20**: lista de revisión firmada con los cuatro puntos de la regla 18 para cada texto nuevo no procedente del §12 (en `production/qa/evidence/content-m1-review.md`).

---

## Implementation Notes

- Inventario exacto: el que pidan las historias de los épicos director-escenas-1-3, ordenador-e-impresora, documentos-y-bolsillo e interaccion-y-prompt. Si un ID aún no está decidido en su GDD, no se inventa: entra con marcador de pendiente (regla 23) y se lista en la evidencia.
- No se escriben claves de escenas 4–8 (fuera de M1).

---

## Out of Scope

- `puzzles.json` (9) y `flags.json` (3).

---

## Files

- `assets/data/narrative/*.json`
- `production/qa/evidence/content-m1-review.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: smoke check pass (`production/qa/smoke-*.md`) + lista de revisión AC-20.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-005-language-layer-and-markers.md`, `production/epics/contenido-y-datos/story-006-lines-documents-audio.md`, `production/epics/contenido-y-datos/story-007-mails-and-tasks.md`
- Unlocks: `production/epics/contenido-y-datos/story-011-verifier-slice-comparison.md`
