# Story 001: Catálogo `items.json` + `inventory_config.json` y esquema

> **Epic**: Documentos y bolsillo
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S — 0,5 días (0,5–1), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/documentos-y-bolsillo.md` — § Detailed Rules › A (ítems y documentos), B; § Tuning Knobs
**Requirement**: `TR-pocket-001`, `TR-pocket-010`, `TR-pocket-018` (datos: `items.json` + `inventory_config.json`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 (D1, D2, D5, D6, G-1…G-7, G-9, G-16)
**ADR Decision Summary**: datos de juego solo por `DataReader`, con esquema GDScript en el `DataCatalog`; arrays de registros con `id`; textos visibles solo vía `ContentDB` (18).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: S-0005-A: claves duplicadas en un objeto → gana la última en silencio (por eso los ítems son un array y el `id` duplicado se detecta en el array); coma final aceptada en silencio salvo precomprobación de `JsonText`; BOM eliminado en silencio al decodificar → se comprueba en bytes (lo hace `DataReader`, épico contenido-y-datos).

**Control Manifest Rules (this layer)**:
- Required: ADR-0005 G-1, G-4 (`schema_version`), G-6, G-7; F-R05.
- Forbidden: crear ítems en ejecución; `tr()` para texto visible (G-9).
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/documentos-y-bolsillo.md`, scoped to this story:*

- [ ] **AC-01**: se piden los 7 IDs (`I-01`, `I-02`, `I-03`, `I-04`, `I-05`, `I-06a`, `I-07`) e `I-06b`: los siete existen con su clase y `I-06b` devuelve falso con una línea de registro.
- [ ] Cada documento declara clave de 18, fragmentos ordenados y `estilo` ∈ {`impreso`, `manuscrito_vera`, `manuscrito_guardian`, `cristal_espejo`, `pantalla`, `libro`}; estilo fuera de dominio o clave inexistente en 18 = error de datos (TR-pocket-010).
- [ ] `inventory_config.json` contiene `t_item_dentro` 0,3, `t_mostrar_item_s` 0,7, `t_item_fuera` 0,3, `lectura_min_s`, `t_tapa_s` 0,6, `repaso_orden` (`I-07, I-05, I-06a, I-04`), `repaso_cerrar_ciclo`; ningún valor duplicado en código.

---

## Implementation Notes

*Derived from ADR-0005 D2/D5/D6:*

- Ficheros `assets/data/items/items.json` e `assets/data/items/inventory_config.json` (ruta D1 `assets/data/<dominio>/<snake_case>.json`).
- La correspondencia ítem → hecho (`tarjeta_B`→`I-02`, `tarjeta_D`→`I-03`, `formulario_leido`→`I-04`, `caja_c1/c2/c4`) vive en datos y se valida contra `flags.json` de 3.
- Firma de la consulta de catálogo para 20: si ningún ADR/GDD la fija, tarea de la historia con ADR-fallback registrado.

---

## Out of Scope

- Story 002: `has_item`. Pantalla de lectura: diferida por ADR-0016.

---

## Files

- `assets/data/items/items.json`, `assets/data/items/inventory_config.json`
- `src/systems/pocket/item_catalog.gd`
- `tests/unit/pocket/catalogo_items_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/pocket/catalogo_items_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/EPIC.md` (`DataReader`, `DataCatalog`, `ContentDB`; historias aún sin crear)
- Unlocks: `production/epics/documentos-y-bolsillo/story-002-has-item-y-sesion.md`
