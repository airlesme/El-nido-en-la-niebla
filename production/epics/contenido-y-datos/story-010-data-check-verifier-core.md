# Story 010: Verificador `tools/data_check` (códigos de salida, `--hito=calidad`)

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation (tooling)
> **Type**: Logic
> **Estimate**: L (≈ 1,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, reglas 15–17, 22–23
**Requirement**: `TR-content-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D8 Verifier in `tools/`; D3 nivel C)
**ADR Decision Summary**: `tools/data_check/data_check.gd` reutiliza `DataReader`/`DataValidator` y añade `ContentVerifier`: sale con 0 o ≠ 0; avisos con 0 salvo `--hito=calidad`, que los pasa a error. Comprueba IDs duplicados, referencias, líneas audibles con texto, grupos completos, marcadores y formato de claves.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: se ejecuta con `godot --headless -s res://tools/data_check/data_check.gd -- [--hito=calidad]`; el código de salida por `quit(code)` desde un `SceneTree` script (permitido en tooling, no en juego).

**Control Manifest Rules (this layer)**:
- Required: F-R65 (recoger todos los problemas con fichero y ruta)
- Forbidden: reglas de validación duplicadas fuera de `DataSchema`/`ContentRules`
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/base-de-contenido-narrativo.md`, scoped to this story (fixtures en `tests/fixtures/content/`):*

- [ ] **AC-17**: un ID duplicado, una referencia inexistente o una línea audible sin texto → código ≠ 0 en cada caso; audio ausente → aviso con código 0.
- [ ] **AC-18**: líneas audibles con `audio` nulo o fichero ausente se listan como aviso (0); `DOC_01`, `NOTA_*`, `CARTA_*` no se listan; con `--hito=calidad` pasan a error.
- [ ] **AC-03a / AC-22**: `SUB_BREATH_BROKEN` pasa el formato y `sub_llanto`/`SUB_Llanto` fallan; las entradas provisionales con marcador de pendiente son aviso (0) y error con `--hito=calidad`.
- [ ] **AC-04 (T) / AC-05 (T) / AC-E5 (T)**: referencia a un ID inexistente, grupo al que le falta un sufijo y duplicado entre ficheros → código ≠ 0.

---

## Implementation Notes

- Rutas (ADR-0005 D10): `tools/data_check/data_check.gd`, `content_verifier.gd`, listas de configuración en `tools/data_check/`.
- El cableado en CI (bloqueante) queda diferido por ADR-0018; esta historia deja el comando documentado en `tools/data_check/README` para que `/dev-story` lo ejecute a mano.

---

## Out of Scope

- Story 011 (comparación con §12), 012 (escaneo de literales).

---

## Files

- `tools/data_check/data_check.gd`, `tools/data_check/content_verifier.gd`
- `tests/unit/content/content_verifier_test.gd`, `tests/fixtures/content/*`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/content_verifier_test.gd` — must exist and pass (el GDD marca estos CA como T: además, una ejecución del verificador con salida archivada en la evidencia).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-003-data-catalog-and-validator.md`, `production/epics/contenido-y-datos/story-008-variant-groups-ids-duplicates.md`
- Unlocks: `production/epics/contenido-y-datos/story-011-verifier-slice-comparison.md`, `production/epics/contenido-y-datos/story-012-literal-scanner.md`
