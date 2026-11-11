# Story 012: Escaneo de literales visibles en scripts y escenas

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation (tooling)
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, reglas 6 y 21 (únicos literales de emergencia)
**Requirement**: `TR-content-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D8 `LiteralScanner`; D7)
**ADR Decision Summary**: Un escáner en `tools/data_check/` busca literales en propiedades de texto de nodos de interfaz (scripts y `.tscn`) con una lista de excepciones cuyos únicos elementos de juego son «…» y el mensaje de fallo de carga; depuración y log quedan fuera.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: los `.tscn` se analizan como texto (formato de escena de 4.7); propiedades `text`, `placeholder_text`, `tooltip_text`.

**Control Manifest Rules (this layer)**:
- Required: F-R61 (únicos literales permitidos: lista de excepciones)
- Forbidden: añadir excepciones sin cambiar la lista versionada
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/base-de-contenido-narrativo.md`:*

- [ ] **AC-06**: el escaneo sobre `src/` no encuentra literales fuera de depuración, log y la lista de excepciones; un script de prueba con `label.text = "Hola"` hace fallar el escaneo.
- [ ] **AC-E7**: los únicos literales visibles permitidos son «…» y el mensaje de fallo de carga (`src/core/composition/fatal_messages.gd` como excepción documentada de ADR-0009 D8).

---

## Implementation Notes

- Rutas: `tools/data_check/literal_scanner.gd` y su lista de excepciones (ADR-0005 D10). El cableado en CI, diferido por ADR-0018.

---

## Out of Scope

- CI bloqueante (ADR-0018).

---

## Files

- `tools/data_check/literal_scanner.gd`, `tools/data_check/literal_exceptions.json`
- `tests/unit/content/literal_scanner_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/literal_scanner_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-010-data-check-verifier-core.md`
- Unlocks: None
