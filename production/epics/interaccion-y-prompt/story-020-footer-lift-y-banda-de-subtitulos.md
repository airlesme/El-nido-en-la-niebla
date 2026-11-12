# Story 020: `FooterLift` y puerto `SubtitleBandQuery` — el pie sube sobre los subtítulos

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S — 0,5 día (0,5–1), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Detailed Rules › D regla 24 (convivencia con 26); D24-17; AC-24-22
**Requirement**: `TR-prompt-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (D6 «Coexistence with 26», D5/`SubtitleBandQuery`, G-6)
**ADR Decision Summary**: cada fotograma `rest_y = safe_bottom − footer_h`, `top = subtitle_band.visible_top_px()` y `y = min(rest_y, top − footer_h)`; si `y < safe_top` el pie queda justo sobre los bloques y se recorta a 2 líneas (el subtítulo nunca se tapa ni se mueve); sin bloque dibujado (`INF`) el pie reposa en su ancla; anillo y etiqueta no se mueven. `NullSubtitleBand` (`visible_top = INF`, reservado 0) es el valor por defecto en `UiPorts` hasta que exista 26.
**ADR Version**: ADR-0016 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: la animación del desplazamiento usa `offset_transform` (4.7) y es de la 023; esta historia es solo la aritmética y el puerto. `sub_hueco_px` (12) es de 26: se lee del puerto, no de `prompt.json`.

**Control Manifest Rules (this layer)**:
- Required: P-R04 (rectángulo seguro de `ViewportMapper`, no 1920×1080 fijo).
- Forbidden: que 24 lea estado interno de 26 o 26 llame a 24 (ADR-0016 G-6; 26 solo ofrece `SubtitleBandQuery`).
- Guardrail: sin asignaciones por fotograma (función pura sobre floats).

**Decisiones de usuario ya cerradas que la afectan**: nº 5 (subtítulos a 720p escalan con suelo definido en 26): la altura de la banda la entrega 26 ya en px lógicos; 24 no la recalcula.

---

## Acceptance Criteria

*From GDD 24 AC-24-22 y ADR-0016 § Test Plan (`test_footer_lift.gd`), scoped to this story:*

- [ ] `y = min(rest_y, top − footer_h)`: sin bloques (`INF`) → `y = rest_y`; un bloque con `visible_top` 900 y pie de 80 → `y = 820`; la fórmula nunca da un `y` que solape el bloque (`y + footer_h ≤ top`).
- [ ] Con tamaño grande + 2 bloques, donde `y < safe_top` → el pie se coloca sobre el borde superior de los bloques y se **recorta a 2 líneas** (`max_lines = 2`); el rectángulo del subtítulo queda intacto (la prueba verifica que 24 no produce ninguna orden sobre él).
- [ ] `NullSubtitleBand` registrado por defecto: el prompt funciona sin 26 (dependencia blanda) y la elevación es 0.
- [ ] Anillo y etiqueta no dependen del puerto (la prueba comprueba que su posición no varía con `visible_top`).

---

## Implementation Notes

- Puerto `SubtitleBandQuery` (`UiPorts.subtitle_band`) con `visible_top_px() -> float` y `reserved_px() -> float`; si 26 ya lo definió, se reutiliza.
- `FooterLift.solve(rest_y, top, footer_h, safe_top) -> LiftResult {y, max_lines}` pura.

---

## Out of Scope

- Banda real de subtítulos y su F4 (26). Animación del movimiento: 023. Captura de la convivencia: 024.

---

## Files

- `src/ui/prompt/footer_lift.gd`, `src/ui/subtitles/subtitle_band_query.gd` (solo puerto + `NullSubtitleBand`)
- `tests/unit/prompt/footer_lift_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/prompt/footer_lift_test.gd` — debe existir y pasar.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 015 (`ViewportMapper.safe_rect()`), 019 (alto del pie en el modelo)
- Unlocks: 023, 024
