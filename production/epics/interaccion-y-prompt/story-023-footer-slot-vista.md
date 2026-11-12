# Story 023: `FooterSlot` — pie visible (panel, márgenes seguros, fundidos y elevación)

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M — 1,5 días (1–2,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Detailed Rules › D reglas 21, 24–27; AC-24-14 (contraste y márgenes), AC-24-16, AC-24-22
**Requirement**: `TR-prompt-015` (**parte**: abajo-centro, márgenes seguros 5 %, ≤ 2 líneas a ≤ 60 % del ancho, panel 85 %, contraste ≥ 4,5:1 sobre blanco puro; la cláusula «texto ≥ max(28·s, 24) px» es de la 025, Blocked)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (D6 «Footer» y «Coexistence with 26», D3 tamaños lógicos, D4 `GlyphText`, G-4, G-5)
**ADR Decision Summary**: `FooterSlot` es la vista delgada sobre `FooterState` (019) y `FooterLift` (020): ≤ 2 líneas (3 si > `texto_max_caracteres`, con aviso de datos), cuerpo 28 px **lógicos**, panel azul noche al 85 %, texto blanco frío; la elevación sobre subtítulos anima `offset_transform` (4.7) en el tiempo del propio fundido (150 ms; 100 con `reducir_movimiento`); todo el contenido pasa por `GlyphText`.
**ADR Version**: ADR-0016 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `offset_transform` en contenedores NO se reinicia (fuente ADR-0016); medición de líneas reales con fuente Atkinson (SP-16E) y glifos ±2 px (SP-16D) son NEEDS_WINDOWED; la fuente Atkinson **no está aún en el repo** (SP-16A usó la del motor): las capturas de esta historia se anotan «fuente provisional».

**Control Manifest Rules (this layer)**:
- Required: P-R03 (texto de `ContentDB`), P-R04, F-R18, F-R07.
- Forbidden: `[font_size]` y `add_theme_font_size_override` sobre texto de lectura (ADR-0016 G-5); `Tween`/`Timer` (G-2: el movimiento se avanza por fotograma con el reloj de juego); computar factor `ventana/1080` (G-4); máquina de escribir.
- Guardrail: `FooterSlot` no reconstruye texto por fotograma, solo al cambiar `(clave, revision)`.

**Decisiones de usuario ya cerradas que la afectan**: **nº 3** (`reducir_movimiento` fija 100 ms; `escala_texto_ui` «se da por cerrada»). **Hueco para el ui-owner**: ADR-0016 D6 dice «28 px body scaled by `escala_texto_ui`» pero la decisión 3 la da por cerrada; esta historia implementa el pie a **factor 1,0 fijo** y deja `TODO(ui-owner)` para cuando se confirme si `escala_texto_ui` existe en el slice.

---

## Acceptance Criteria

*From GDD 24 § Acceptance Criteria, scoped to this story:*

- [ ] **AC-24-14 (sin la parte de píxeles físicos, ver 025)**: en 720p, 1080p y 2160p el pie queda dentro de los márgenes seguros del 5 % (rect de `ViewportMapper`), abajo-centro, ≤ 2 líneas a ≤ 60 % del ancho; contraste texto/panel ≥ 4,5:1 medido con la razón de luminancia relativa WCAG sobre fondo de prueba blanco puro `#FFFFFF` **y** negro puro, calculada sobre la captura (y por cálculo unitario con panel efectivo ≈ `#3E4A56`).
- [ ] **AC-24-16 (pie)**: con `reducir_movimiento` todos los fundidos del pie (entrada/salida `pie_fade_ms`, sustitución, elevación) duran 100 ms; sin él, 250 ms de entrada/salida y 150 ms de sustitución y elevación.
- [ ] **AC-24-22 (vista)**: con un bloque de subtítulo (doble de `SubtitleBandQuery`) visible, el pie queda sobre su borde superior + `sub_hueco_px` sin solaparlo; con tamaño grande + 2 bloques se recorta a 2 líneas y el subtítulo queda íntegro; anillo y etiqueta no se mueven.
- [ ] Texto largo (+30 %) que no cabe en 2 líneas dentro del 60 % → el ancho crece al 80 % y luego a 3 líneas con la advertencia de R25; el cambio de dispositivo con `UI_BOLSILLO_AYUDA` en pantalla re-resuelve el token con reflow (fundido 100 ms) sin reiniciar el reloj.

---

## Implementation Notes

- `FooterSlot` (`Control`) = panel + `RichTextLabel` escrito solo por `GlyphText`; todas las medidas en px lógicos de `PromptConfig`.
- La captura de evidencia del pie va en 024 (G-11: 1280×720, 1920×1080 y 3840×2160, más 2560×1080 para HUD); con `escala_texto_ui` = 1,00 únicamente hasta que se resuelva el TODO.

---

## Out of Scope

- Lógica del hueco (019), aritmética de elevación (020), suelo de texto en píxeles (025), banda real de 26.

---

## Files

- `src/ui/prompt/footer_slot.gd`, `src/ui/prompt/footer_panel_style.gd`
- `tests/unit/prompt/footer_contrast_test.gd`, `tests/integration/prompt/footer_slot_test.gd`
- Evidencia: `production/qa/evidence/prompt-pie-evidence.md` + capturas

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: captura retenida del pie (con `OBJ_C06`/`D03` y con `UI_BOLSILLO_AYUDA`) sobre fondo blanco y negro, y con un bloque de subtítulo de prueba, en `production/qa/evidence/`; más `footer_contrast_test.gd` (cálculo WCAG) y `footer_slot_test.gd`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 015, 016, 019, 020, 021
- Unlocks: 024
