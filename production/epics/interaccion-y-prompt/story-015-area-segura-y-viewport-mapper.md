# Story 015: Capa `HUD`, área segura 16:9 y `ViewportMapper`

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Detailed Rules › E, regla 30 (márgenes 5 %, ultraancho anclado al área 16:9 central)
**Requirement**: `TR-prompt-018` (**parte**: márgenes del 5 % y anclaje a 16:9; la parte de escala F2 y redondeo es de la 025, Blocked)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (D1 capas, D2 `SafeAreaMath`/`ViewportMapper`/`ViewportProbe`, G-1, G-3, G-4); ADR-0007 (D7.5: `canvas_items` + `expand`)
**ADR Decision Summary**: `SafeAreaMath.safe_rect(logical, margin_pct)` pura: columna 16:9 centrada si `x/y > 16/9`, y recorte del 5 % por lado; `ViewportMapper` la sirve desde un `ViewportProbe` inyectado, y `EngineViewportProbe` es el **único** sitio que lee el viewport; `HUD` = `CanvasLayer` 10, `PAUSABLE`, configurada solo con `UiLayers.configure()`.
**ADR Version**: ADR-0016 2026-11-10 · ADR-0007 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `CanvasLayer.layer` y la lectura del viewport lógico están NOT SOURCEABLE (SP-16B: parte headless PASS; orden dibujado y mapper-vs-cursor NEEDS_WINDOWED). Un solo archivo nombra cada API (G-3). **Compartido con 25/26/27**: no hay épico de UI base; esta historia crea solo lo mínimo que el prompt necesita (ver «Decisiones tomadas» en `stories.md`).

**Control Manifest Rules (this layer)**:
- Required: P-R04 (tamaño lógico de `ViewportMapper`, no 1920×1080 fijo), F-R18 (HUD `PAUSABLE`), P-R01 no aplica (el prompt no tiene foco).
- Forbidden: P-X01 (nada sobre el telón), computar `alto_ventana/1080` o escribir `content_scale_factor` (ADR-0016 G-4).
- Guardrail: `safe_rect()` cacheado; se recalcula solo al cambiar el tamaño del viewport.

**Decisiones de usuario ya cerradas que la afectan**: la nº 5 (texto a 720p escala con la ventana) se resuelve por el stretch del motor y no se calcula aquí.

---

## Acceptance Criteria

*From ADR-0016 § Test Plan (`test_safe_area_math.gd`) y GDD 24 regla 30, scoped to this story:*

- [ ] `SafeAreaMath.safe_rect` en 1920×1080 → inset 5 % por eje (96×54 px); en 2560×1080 → columna 1920 centrada con el mismo inset (anclada al área 16:9 central); en 1920×1200 → viewport completo con inset 5 % (16:10 no encoge texto).
- [ ] `ViewportMapper` devuelve `logical_rect()`, `safe_rect()` y `window_to_logical()` desde un `ViewportProbe` falso; cambia de resultado solo cuando el probe cambia de tamaño (una consulta por cambio).
- [ ] `UiLayers.configure(cl, UiLayers.HUD, PROCESS_MODE_PAUSABLE)` fija `layer` 10 y modo explícito; un test de CI (grep) falla si `layer =` aparece fuera de `ui_layers.gd` (G-1).
- [ ] `EngineViewportProbe` es el único fichero que nombra la API de viewport; en 16:10 el alto lógico se **anota** como valor leído (NEEDS_WINDOWED: la medición real queda para 024/prototipo, no se afirma 1200 sin medir).

---

## Implementation Notes

- `margen_seguro_pct` (0,05) no es de `PromptConfig`: es de 30/art bible y lo comparten 24–27. Entra como parámetro inyectado, leído de `assets/data/ui/layout.json` (crearlo solo si 25/26/27 no lo han creado; si existe, reutilizarlo).
- `SafeArea169` (`Control`) aplica `safe_rect()` al redimensionar; el prompt se ancla a él. No se escribe ninguna fórmula de escala (G-4).

---

## Out of Scope

- Fórmula F2 y suelo de texto: historia 025 (Blocked).
- `SubtitleBandQuery`: historia 020. Mapeo de ratón (`PointerCursor`): épico entrada-y-controles (story 009).

---

## Files

- `src/ui/ui_layers.gd`, `src/ui/layout/safe_area_math.gd`, `src/ui/layout/viewport_mapper.gd`, `src/ui/layout/engine_viewport_probe.gd`, `src/ui/layout/safe_area_169.gd`
- `tests/unit/ui/safe_area_math_test.gd`, `tests/unit/ui/viewport_mapper_test.gd`, `tests/unit/ui/ui_layers_grep_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ui/safe_area_math_test.gd` y `viewport_mapper_test.gd` — deben existir y pasar.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: épico estado-y-bus (`LogSink`, `ErrorPolicy`); ADR-0009 `Shell` (padre de `HUD`; si aún no existe el nodo real, se prueba con un doble)
- Unlocks: 020, 021, 022, 023, 024
