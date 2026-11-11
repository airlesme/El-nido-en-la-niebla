# Story 001: Búsqueda — normalización y coincidencia exacta

> **Epic**: Ordenador (búsqueda) e impresora
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S — 0,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

La búsqueda «transición» es la entrada del puzle 1. Coincidencia exacta tras normalizar, contra las
etiquetas de 18; sin prefijos ni búsqueda al teclear.

**GDD**: `design/gdd/ordenador-correo-impresora.md` (R11, R15, F1)
**Requirement**: `TR-computer-007`, `TR-computer-021`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 D6 (`ContentDB`: instantánea inmutable), D1 (registro de ficheros)
**ADR Decision Summary**: 18 carga una vez y expone consultas de solo lectura; todo valor de ajuste de 19 vive en `assets/data/`.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: la eliminación de tildes debe hacerse con una tabla propia o con API verificada en `docs/engine-reference/godot/`; si `String` no tiene una función documentada para ello, **NOT SOURCEABLE** → tabla de sustitución en código de 19 con test.

**Control Manifest Rules (this layer)**:
- Required: valores de 19 desde datos (TR-computer-021)
- Forbidden: constantes de ajuste en código
- Guardrail: búsqueda solo al pulsar `Buscar`/`Intro`

---

## Acceptance Criteria

- [ ] **GDD 19 AC-01**: «transición», «Transicion», «TRANSICIÓN » → `hay_resultados` verdadero; «trans», «tr», «» o «mantenimiento» → falso.
- [ ] **GDD 19 AC-05**: sin coincidencia no se escribe ningún hecho y se muestra «Sin resultados» sin sonido de error.
- [ ] **TR-computer-007**: longitud fuera de 3 ≤ n ≤ 32 no lanza búsqueda.

---

## Implementation Notes

- Firma de la consulta de etiquetas: la de `ContentDB` en ADR-0005 § Key Interfaces. Si no existe la consulta por etiqueta, **tarea con ADR-fallback**: añadirla en el épico `contenido-y-datos` siguiendo ADR-0005 D6, no en 19.
- Ruta propuesta (fallback, ver `stories.md` decisión 3): `src/world/computer/mail_search.gd`.

---

## Out of Scope

- Story 002: la espera de 0,4 s y la lista.

---

## Files

- `src/world/computer/mail_search.gd`
- `tests/unit/computer/mail_search_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/computer/mail_search_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `ContentDB` (`production/epics/contenido-y-datos/`)
- Unlocks: `production/epics/ordenador-e-impresora/story-002-latencia-lista-correos-leidos.md`
