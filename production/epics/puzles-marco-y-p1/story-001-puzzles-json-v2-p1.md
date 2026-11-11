# Story 001: Carga y validación de `puzzles.json` v2 (entrada P1)

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

El marco solo arranca si `assets/data/puzzles/puzzles.json` pasa la validación de la regla 29 del
GDD 9. En M1 el fichero contiene solo la entrada `P1`; el validador debe aceptar el esquema v2
completo para no reescribirse cuando entren P2–P6.

**GDD**: `design/gdd/marco-de-puzles.md` (reglas 4b, 5, 29) · `design/gdd/puzle-1-cronologia.md` (§ Datos del puzle, R19)
**Requirement**: `TR-puzzles-001`, `TR-puzzles-002`, `TR-puzzles-004`, `TR-puzzles-005`, `TR-puzzles-006`, `TR-puzzle1-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 D13 (`PuzzleDataRules`, ruta de fallo); ADR-0005 D2–D5 (esquema, niveles L/B/C, conversión a `int`, lectura)
**ADR Decision Summary**: los esquemas son declaraciones GDScript validadas por un único `DataValidator`; `puzzles.json` es el único fichero con `schema_version` 2; `PuzzleDataRules` añade las comprobaciones semánticas de la regla 29.
**ADR Version**: ADR-0010 2026-11-10 · ADR-0005 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: el comportamiento del parser JSON es NOT SOURCEABLE hasta S-0005-A (ADR-0005 D5); usar solo el envoltorio `DataReader`.

**Control Manifest Rules (this layer)**:
- Required: FE-R18 (enteros ya convertidos a `int` antes de llegar a los controladores)
- Forbidden: `JSON.parse_string` fuera del envoltorio de ADR-0005 (Foundation, l. 332); FE-X05 (el controlador no re-parsea JSON)
- Guardrail: validación solo al arrancar (nivel L), nunca por fotograma

---

## Acceptance Criteria

*From GDD `design/gdd/marco-de-puzles.md` y `design/gdd/puzle-1-cronologia.md`, scoped to this story:*

- [ ] **GDD 9 AC-35**: sin `schema_version` 2 → falla; ciclo de `requires.all` → falla (resto del AC según el GDD).
- [ ] **GDD 9 AC-48**: `sequence` leído como `2.0` se convierte a `int`; `2.5` falla la validación.
- [ ] **GDD 9 AC-10 / AC-62 (parte P1)**: `reset_after_s` > `lock_max_s` falla; `on_reject: null` en P1 falla.
- [ ] **GDD 11 AC-19**: la entrada `P1` pasa la validación de 9 (`needs_items` existe en el catálogo, `reset_after_s` ≤ 2,0, `solution` no satisfecha por el estado inicial, `solved_flag` declarado en `flags.json`, enteros como `int`). Los tres niveles de pista se validan como datos aunque las pistas estén recortadas en M1.

---

## Implementation Notes

*Derived from ADR-0010 D13 and ADR-0005 D2–D4:*

- `PuzzleDataRules` vive en `src/puzzles/data/puzzle_data_rules.gd` (ruta fijada en ADR-0010 l. 688) y se registra como `FileRules` del esquema de `puzzles.json` (ADR-0005 D2 «Base of every per-file schema»).
- Cada hallazgo es un issue con `json_path` (ADR-0010 T-U14); nunca se lanza excepción.
- `solution.sequence = [2,1,3,4]` es dato (TR-puzzle1-002); no aparece como constante en código.
- La validación que cruza con `flags.json` y el catálogo de ítems corre tras cargar los catálogos (TR-puzzles-005); si el orden de carga no está aún en el esqueleto, tarea: seguir ADR-0005 D3 y ADR-0003 (`INVALID_PUZZLE_DATA`).

---

## Out of Scope

- Story 004: qué hace el marco con datos inválidos al configurar la escena (`INVALID_PUZZLE_DATA`, T-I1).
- Story 009: `p1_view.json` (geometría).

---

## Files

- `assets/data/puzzles/puzzles.json` (entrada P1)
- `src/puzzles/data/puzzle_data_rules.gd`
- `tests/unit/puzzles/data/puzzle_data_rules_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/puzzles/data/puzzle_data_rules_test.gd` (gdUnit4) — must exist and pass. Fixtures en ficheros constantes de test, no JSON en línea.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `DataReader`/`DataValidator` de ADR-0005 (épico `production/epics/contenido-y-datos/`) y el catálogo de hechos (`production/epics/estado-y-bus/`)
- Unlocks: `production/epics/puzles-marco-y-p1/story-004-estados-configuracion-y-vista.md`, `production/epics/puzles-marco-y-p1/story-009-geometria-p1-view.md`
