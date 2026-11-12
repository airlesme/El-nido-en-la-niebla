# Story 014: Datos del prompt — `prompt.json`, esquema y validación

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S — 0,5 día (0,5–1), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Tuning Knobs (l. 139); § Detailed Rules › E, regla 31
**Requirement**: `TR-prompt-020` (**parte**: «datos en `assets/data/ui/prompt.json`»; el resto de TR-prompt-020 es de la 021)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 (esquema y validación de datos, carga con `DataReader`); ADR-0016 (D12 ficheros de datos de `assets/data/ui/`; § Validation Criteria «Data validation (CI)»)
**ADR Decision Summary**: los valores de la tabla de Tuning Knobs viven en `assets/data/ui/prompt.json`, validados contra un esquema en carga y en CI; campo desconocido = error de datos; `pulso_min_intervalo_ms` < 334 y cualquier tamaño de texto < 24 se rechazan **en validación**, no en ejecución.
**ADR Version**: ADR-0005 2026-11-10 · ADR-0016 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (JSON + GDScript puro)
**Engine Notes**: sigue el patrón de `interactables.json` (IP-001) y del `DataReader` del épico contenido-y-datos.

**Control Manifest Rules (this layer)**:
- Required: P-R03 (el texto sale de `ContentDB`; este fichero solo trae números y banderas, nunca cadenas visibles), F-R09 (logs por `LogSink`).
- Forbidden: valores de juego hardcodeados (coding-standards), literales «Retroceso»/«Backspace» en datos (AC-24-10).
- Guardrail: carga una vez en «escena lista»; nada por fotograma.

**Decisiones de usuario ya cerradas (2026-11-12) que la afectan**: ninguna directamente. La nº 3 (`reducir_movimiento`) fija el origen de `fade_reducido_ms` (100 ms) y la nº 5/QQ-10 afecta al suelo de texto (ver 025).

---

## Acceptance Criteria

*From GDD `design/gdd/prompt-de-interaccion.md`, scoped to this story:*

- [ ] `assets/data/ui/prompt.json` contiene todas las claves de § Tuning Knobs con sus valores iniciales (`anillo_px` 28, `anillo_grande_px` 48, `anillo_opacidad` 0,80, `fade_in_ms` 250, `fade_out_ms` 150, `fade_reducido_ms` 100, `pulso_ms` 120, `pulso_rechazo_min` 0,40, `pulso_min_intervalo_ms` 340, `etiqueta_offset_px` 12, `pie_ancho_max` 0,60, `pie_alto_texto_px` 28, `pie_alto_min_px` 24, `pie_panel_opacidad` 0,85, `pie_fade_ms` 250, `ui_escala_min/max`) y pasa el esquema; los rangos seguros de la tabla se validan como error de datos al salirse.
- [ ] **Tope de fotosensibilidad** (D24-12, AC-24-06): `pulso_min_intervalo_ms` < 334 es error de validación (CI y carga); `pie_alto_min_px` ≠ 24 y `pie_alto_texto_px` < 24 también.
- [ ] Un campo desconocido, un tipo erróneo o una cadena de texto visible en el fichero = error de datos con ruta del campo; el lector devuelve un `PromptConfig` inmutable y las claves ausentes caen al valor inicial **con log** (no silencioso).
- [ ] `etiqueta_accion_visible` e `icono_grande` **no** están en este fichero (son ajustes del jugador de 6, GDD § Tuning Knobs); el `PromptConfig` solo expone sus valores iniciales (falso/falso) para TR-prompt-019.

---

## Implementation Notes

- `PromptConfig` (`RefCounted`) con campos tipados y `static func from_dictionary(d, log) -> PromptConfig`; se inyecta en todas las historias del prompt (no hay singleton).
- `ui_escala_min/max` se cargan pero **no** se usan para calcular nada en tiempo de ejecución (ADR-0007 D7.2: son el rango de resoluciones soportado). Su uso real lo decide la 025.
- Test de CI (grep) «ningún literal Retroceso/Backspace en `src/ui/prompt/` ni en `assets/data/ui/prompt.json`» (AC-24-10) vive aquí y se amplía en 016.

---

## Out of Scope

- Claves de texto de 18 (`UI_VERBO_*`, `OBJ_*`): épico contenido-y-datos.
- `text_sizes.json` y los temas (ADR-0016 D3): UI compartida de 25/26/27, no del prompt.

---

## Files

- `assets/data/ui/prompt.json`, `assets/data/ui/prompt.schema.json`
- `src/ui/prompt/prompt_config.gd`, `src/ui/prompt/prompt_config_loader.gd`
- `tests/unit/prompt/prompt_config_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/prompt/prompt_config_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: épico contenido-y-datos (`DataReader`, esquema, `ContentDB`); `production/epics/interaccion-y-prompt/story-001-catalogo-interactuables.md` (patrón de carga)
- Unlocks: 017, 018, 019, 020, 021, 022, 023
