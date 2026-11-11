# Historias — Épico: Contenido narrativo y datos validados

> **Épico**: `production/epics/contenido-y-datos/EPIC.md` · **GDD**: `design/gdd/base-de-contenido-narrativo.md` (18)
> **Generado**: 2026-11-11 por `/create-stories` (modo autonomous, `review_mode: lean` → QL-STORY-READY omitido)
> **Manifest Version**: 2026-11-11b · **Granularidad**: balanced (2–4 CA por historia)
> **ADRs**: ADR-0005 Accepted · ADR-0009 Accepted · ADR-0001 Accepted · ADR-0018 **Proposed** · ADR-0016 **Proposed** · ADR-0008 **Proposed**
> **Estimaciones**: días-persona, **confianza BAJA** (no hay velocidad medida). S ≈ 0,5 d · M ≈ 1 d · L ≈ 2 d.

| ID | Título | Tipo | Est. | Días | Depende de | Estado |
|----|--------|------|------|------|------------|--------|
| [001](story-001-file-store-and-json-text.md) | `FileStore` y `JsonText` (BOM en bytes, comas finales, claves duplicadas) | Logic | M | 1 | estado-y-bus 001 | Ready |
| [002](story-002-schema-and-data-reader.md) | `DataSchema`/`FieldSpec`, `DataReader.normalise` y `to_int` | Logic | L | 1,5 | 001 | Ready |
| [003](story-003-data-catalog-and-validator.md) | `DataCatalog`, `RefIndex` y `DataValidator` (paso 4 de arranque) | Logic | M | 1 | 002 | Ready |
| [004](story-004-content-db-load-and-lifecycle.md) | Esquemas narrativos y carga de `ContentDB` (Sin cargar → Listo / Error) | Logic | L | 1,5 | 003 | Ready |
| [005](story-005-language-layer-and-markers.md) | Capa de idioma y marcadores `{vera}`/`{guardian}` | Logic | M | 1 | 004 | Ready |
| [006](story-006-lines-documents-audio.md) | Líneas en segmentos, documentos en fragmentos y campo `audio` | Logic | S | 0,5 | 004 | Ready |
| [007](story-007-mails-and-tasks.md) | Correos (registro único, orden explícito, etiquetas) y fichas | Logic | S | 0,5 | 004 | Ready |
| [008](story-008-variant-groups-ids-duplicates.md) | Grupos de variantes, IDs retirados y duplicados entre ficheros | Logic | M | 1 | 004 | Ready |
| [009](story-009-m1-narrative-data.md) | Datos narrativos de M1 (escenas 1–3, correos, `UI_`/`OBJ_`, tabla de nombres D-04) | Config/Data | M | 1 | 005, 006, 007 | Ready |
| [010](story-010-data-check-verifier-core.md) | Verificador `tools/data_check` (códigos de salida, `--hito=calidad`) | Logic | L | 1,5 | 003, 008 | Ready |
| [011](story-011-verifier-slice-comparison.md) | Verificación contra la tabla §12 del slice | Logic | M | 1 | 009, 010 | Ready |
| [012](story-012-literal-scanner.md) | Escaneo de literales visibles en scripts y escenas | Logic | M | 1 | 010 | Ready |

**Total**: 12 historias (11 Logic, 1 Config/Data) · ≈ 12,5 días-persona · 12 Ready, 0 Blocked.
**Camino crítico**: (estado 001) → 001 → 002 → 003 → 004 → 005 → 009. **001–003 desbloquean también estado-y-bus 005 y entrada-y-controles 001**: es el arranque de mayor alcance de M1 (el EPIC.md ya lo señala).

## Diferido / bloqueado por ADR

| Requisito / CA | Bloqueado por | Motivo |
|---|---|---|
| TR-content-012 (recarga en caliente en dev), AC-21 segunda mitad, AC-E3, AC-E6 | ADR-0018 (Proposed) | La enmienda O1 de ADR-0018 mueve `dev_reload` a `src/dev/` (hito § ADR, fila 4); ADR-0005 D6.7 depende de ella |
| TR-content-013 «bloqueante en CI» (cableado del verificador en el pipeline) | ADR-0018 (Proposed) | CI y exports son de ADR-0018; el verificador en sí entra en 010 |
| AC-19 (línea sin audio muestra su subtítulo en juego) | ADR-0016 y ADR-0008 (Proposed) | Subtítulos (26, recorte 3) y voz (23); el lado de datos (`audio` nulo → «sin audio») entra en 006 |
| TR-content-017 (token `{accion:<id>}` sustituido por 24) | ADR-0016 (Proposed) | El consumidor (prompt, 24) está bloqueado; la gramática se añadirá al verificador cuando 24 se desbloquee |

**Fuera de este épico por alcance (no por ADR):** TR-content-016 (contrato `TEXT` de pista ↔ `PISTA_P<n>_N<k>`) lo valida el cargador de `puzzles.json` (9, épico puzles-marco-y-p1) y las pistas de P1 son el recorte 2; C-M1-2 «la entrada `P1` valida» es del esquema de `puzzles.json` (ADR-0010, puzles-marco-y-p1); C-M1-4 «los 5 flags en `flags.json`» lo cubre estado-y-bus 006 (dueño del fichero: 3).

## Decisiones tomadas (modo autonomous)

- **El pipeline de datos («S0 data pipeline» de ADR-0005 D10) entra aquí (001–003).** No existe en `src/core/data/` salvo `build_flavor.gd`, ningún épico de M1 lo posee y lo necesitan estado y entrada. *Descartado:* un épico S0 nuevo — mismo trabajo, más papeleo.
- **AC-02/AC-03 (recuento de 28 entradas del §12) en M1:** el verificador compara lo que hay; el recuento completo exige datos de escenas 4–8 (fuera de M1) y se registra NOT ASSESSED hasta M2. *Descartado:* rellenar con texto provisional las 28 — viola la regla 18 (lista de revisión) y adelanta alcance.
