# Story 016: `BindingLabelSource`, `TokenResolver` y `GlyphText` (glifo + texto, `{accion:atrás}`)

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M — 1,5 días (1–2,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Detailed Rules › B reglas 12–15 y D regla 27; AC-24-08…AC-24-11
**Requirement**: `TR-prompt-009`, `TR-prompt-010`, `TR-prompt-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (D4 tokens, `TokenResolver`, `GlyphText`, `BindingLabelSource`; C6/OI-6 `bindings_revision`); ADR-0006 (D13 `get_binding_label`, `bindings_revision()`)
**ADR Decision Summary**: `TokenResolver.resolve(text) -> Array[TextRun]` pura, con `BindingLabelSource`, `ContentDB` y `LogSink` inyectados: cada `{accion:<id>}` se vuelve un run `GLYPH {glifo_id, texto}` de `get_binding_label(id, -1)`; `{}` → run `TEXT` con `UI_ACCION_<ID>` ‡ y warning; token desconocido se elimina con error en dev; **nunca** se muestra un token crudo. Caché por `(clave, revision)`: se re-resuelve solo si `bindings_revision()` cambia o llega «dispositivo de entrada cambiado» / «pausa cerrada»; recomponer no reinicia ningún reloj. `GlyphText` es el único sitio que escribe contenido en `RichTextLabel` (glifo inline a la altura de línea, **seguido siempre de texto**).
**ADR Version**: ADR-0016 2026-11-10 · ADR-0006 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `RichTextLabel.add_image` (args y `ImageUnit` confirmados en SP-16D); alineación ±2 px de línea base y glifos reales NEEDS_WINDOWED. `{}` de `get_binding_label` = sin asignación (ADR-0006). Atlas de glifos por `PadFamily` pendiente (OI-8: dueño 30/ux); sin textura → run `TEXT` enmarcado con log, nunca vacío.

**Control Manifest Rules (this layer)**:
- Required: P-R03 (texto de `ContentDB`), F-R47 (`get_binding_label` sin efectos laterales; ya cubierto por entrada-y-controles 013), F-R07 (sin `await` en callbacks del bus).
- Forbidden: teclas hardcodeadas («Retroceso», «Backspace», nombres de tecla) en código y datos (AC-24-10); `[font_size]` BBCode (ADR-0016 G-5); `Tween`/`Timer`/`create_timer` en `src/ui/prompt/` (G-2).
- Guardrail: una consulta a Entrada por cambio, ninguna por fotograma (AC-24-09).

**Decisiones de usuario ya cerradas que la afectan**: ninguna.

---

## Acceptance Criteria

*From GDD `design/gdd/prompt-de-interaccion.md` y ADR-0016 § Test Plan (`test_token_resolver.gd`), scoped to this story:*

- [ ] **AC-24-10**: `UI_BOLSILLO_AYUDA` con token `{accion:atrás}` y la asignación por defecto de teclado y ratón → run `GLYPH` + texto «Clic der.» leído de `get_binding_label`; con `atrás` reasignada a otra tecla o a mando → muestra la vigente; grep en el repo: ningún «Retroceso»/«Backspace» en `src/ui/` ni en datos de 24.
- [ ] **AC-24-11**: `get_binding_label` devuelve `{}` o falla → `TEXT` «Atrás» (`UI_ACCION_ATRAS`) + warning por `LogSink`; clave de 18 sin token → texto tal cual + warning; token desconocido o `{` sin cerrar → eliminado + error de desarrollo; **ninguna** salida contiene un token ni una clave en bruto.
- [ ] **AC-24-09 / TR-prompt-010**: con la etiqueta visible, «dispositivo de entrada cambiado» (teclado → mando) re-resuelve en el fotograma siguiente con **una sola** consulta por cambio; «pausa cerrada» re-consulta una vez; `bindings_revision()` sin cambio → cero consultas (comparación de entero); recomponer no toca ningún reloj de pie.
- [ ] Un glifo nunca va solo (R12): todo run `GLYPH` lleva su `texto`; con dos asignaciones se usa la primera que devuelve Entrada (orden determinista, R13); `count_for_footer()` cuenta cada token como **un** carácter (R23 de 24, coherente con `duracion_pie` de 007).

---

## Implementation Notes

- Puerto `BindingLabelSource` (adaptador sobre `InputRouter`, doble en pruebas) con `get_binding_label(accion, dispositivo) -> Dictionary` y `bindings_revision() -> int`.
- `GlyphText.render(rtl, runs, line_h_px)` queda cubierto por prueba de integración mínima con un `RichTextLabel` real (nodo) y el resto puro; la alineación de glifos reales se observa en 024.
- **Pregunta abierta (no bloquea)**: las claves `UI_ACCION_<ID>` ‡ y el token `{accion:atrás}` en `UI_BOLSILLO_AYUDA` son de 18 (OI-7 de ADR-0016, pendiente en «GDD 18 próxima ronda»). Mientras no existan en `ContentDB`, las pruebas usan un `ContentDB` de prueba; si faltan en datos reales, esta historia **no** crea el texto narrativo.

---

## Out of Scope

- Etiqueta visible en pantalla: 022. Pie visible: 023. Ajustes y pantalla de controles (25/30).

---

## Files

- `src/ui/text/text_run.gd`, `src/ui/text/binding_label_source.gd`, `src/ui/text/token_resolver.gd`, `src/ui/text/glyph_text.gd`
- `tests/unit/ui/token_resolver_test.gd`, `tests/integration/ui/glyph_text_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ui/token_resolver_test.gd` — debe existir y pasar; `tests/integration/ui/glyph_text_test.gd` (nodo real).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: épico entrada-y-controles `story-013-binding-labels.md` (`get_binding_label`, `bindings_revision`); épico contenido-y-datos (`ContentDB`); 014 (config)
- Unlocks: 021, 022, 023
