# Story 006: Líneas en segmentos, documentos en fragmentos y campo `audio`

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S (≈ 0,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, reglas 9 (segmentos y fragmentos) y 17 (audio)
**Requirement**: `TR-content-008`, `TR-content-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D6 `get_line`, `get_document`, `get_fragment`; nota ADR-0008 OI-9)
**ADR Decision Summary**: Una línea = 1..n segmentos `{text, pause_before_s}` y un campo `audio` (ruta o nulo); un documento = fragmentos ordenados unidos con espacio. `audio` nulo o fichero ausente = «sin audio», con log y sin error.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: comprobar existencia de audio con `ResourceLoader.exists()` en la carga, no al reproducir (decisión de implementación; si ADR-0008 fija otra cosa al aceptarse, prevalece).

**Control Manifest Rules (this layer)**:
- Required: F-R58, F-R62
- Forbidden: cargar el stream de audio en `ContentDB` (solo la ruta)
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/base-de-contenido-narrativo.md`:*

- [ ] **AC-09**: `VO_G_07` tiene 2 segmentos, el segundo con pausa previa; el subtítulo es la secuencia de ambos (fixture).
- [ ] **AC-10**: `DOC_01` F1–F3 existen y su concatenación con espacios es el texto del documento; F4 → «no encontrado».
- [ ] **AC-E4**: una línea con audio cuyo fichero no existe se trata como «sin audio» en release y se registra (`get_line(id).audio` vacío/nulo).

---

## Implementation Notes

- Firmas (ADR-0005): `get_line(id) -> ContentLine` (`{found, speaker, scene, segments[{text, pause_before_s}], audio}`), `get_document(id) -> ContentDocument`, `get_fragment(doc_id, fragment_id) -> String`.
- `ContentLine` es la fuente del adaptador `LineTextSource` de 23 (ADR-0008 OI-9, Proposed): no se implementa el adaptador aquí.

---

## Out of Scope

- AC-19 (subtítulo en juego): diferido por ADR-0016/ADR-0008.

---

## Files

- `src/narrative/content_db.gd`, `src/narrative/content_line.gd`, `src/narrative/content_document.gd`
- `tests/unit/content/lines_documents_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/lines_documents_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-004-content-db-load-and-lifecycle.md`
- Unlocks: `production/epics/contenido-y-datos/story-009-m1-narrative-data.md`
