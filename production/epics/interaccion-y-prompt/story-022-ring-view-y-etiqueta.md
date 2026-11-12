# Story 022: `RingView` y etiqueta de acción (dibujo procedural, glifo + texto)

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M — 1,5 días (1–2,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Detailed Rules › A reglas 3–6, B reglas 10–16, E regla 32; AC-24-08, 17
**Requirement**: `TR-prompt-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (D6 «Ring and label»: `_draw()` procedural, G-3 `draw_arc` solo en `RingView._draw`, D3: el anillo es un icono y **no** se escala con `escala_texto_ui`); ADR-0007 (D7.4: iconos del prompt no escalados)
**ADR Decision Summary**: anillo en el centro exacto (28 px, trazo 2, punto 4, opacidad 80 %, filo 1 px `#1C2A38`, blanco `#DCE6E8`; versión grande 48/3/8/100 %/contorno 2 con `icono_grande`) dibujado en `_draw()` para que quede nítido a cualquier escala; etiqueta = `GlyphText` de `interactuar` + texto de 18, separación `etiqueta_offset_px` (12), apagada por defecto, en línea con el glifo (nunca flotando junto al anillo).
**ADR Version**: ADR-0016 2026-11-10 · ADR-0007 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `draw_arc` está NOT SOURCEABLE y se captura en SP-16A (NEEDS_WINDOWED, sin cerrar para la fuente Atkinson real ni para el anillo 28/48): el resultado visual se observa en 024. Si no se puede dibujar el arco, el respaldo es un `Polygon` aproximado **solo** con aprobación del lead (no es decisión de esta historia).

**Control Manifest Rules (this layer)**:
- Required: P-R03 (texto de `ContentDB`), P-R04 (centro del `ViewportMapper`, no 1920×1080 fijo), F-R07.
- Forbidden: P-X01; color rojo o cualquier color como señal de estado (R32, art bible §4.5); sombra o halo; barra de progreso; punto de mira permanente.
- Guardrail: `_draw` sin asignaciones por fotograma (reutiliza `PackedVector2Array`); `queue_redraw` solo cuando `RingState` cambia.

**Decisiones de usuario ya cerradas que la afectan**: **nº 3**: `reducir_movimiento` no altera la silueta (el pulso es opacidad); **nº 5/QQ-10**: el suelo de texto y la escala de la etiqueta se resuelven en 025 (ver su pregunta abierta).

---

## Acceptance Criteria

*From GDD 24 § Acceptance Criteria, scoped to this story:*

- [ ] **AC-24-17**: con `icono_grande` el anillo mide 48 px (a 1080 lógico), trazo 3 px, punto 8 px, opacidad 100 % y contorno 2 px; por defecto 28/2/4/80 %/filo 1 px azul noche; ambos en el centro exacto de `ViewportMapper.logical_rect()` (también en 21:9 y 16:10) y sin punto de mira cuando no hay objetivo.
- [ ] **AC-24-08**: con `etiqueta_accion_visible` verdadero, la etiqueta muestra `[glifo] + texto` de `get_target().etiqueta` con el glifo de la asignación vigente de `interactuar` en el dispositivo activo, glifo del alto de la línea, en línea con el texto; con falso (valor inicial) no se dibuja etiqueta; con la clave de 18 ausente no se dibuja etiqueta, se registra el error y **nunca** se muestra la clave (R16).
- [ ] **AC-24-04 (dibujo)**: el relleno es del propio anillo (no una barra), horario desde las 12 h, igual a `RingState.fill_degrees`; a `p = 0,6` ocupa 216° (se verifica con la geometría generada y, en 024, en captura).
- [ ] Ningún elemento usa un color distinto para comunicar estado: anillo = presencia, relleno = progreso, pulso = rechazo, texto = contenido (R32); la prueba comprueba que solo se usan los dos colores del art bible.

---

## Implementation Notes

- `RingView` (`Control` con `_draw()`): único fichero que nombra `draw_arc` (G-3). `LabelView` usa `GlyphText` (016) y `LabelPolicy` pura (visible ⇔ `etiqueta_accion_visible` ∧ clave presente ∧ objetivo ≠ nulo ∧ `RingState` visible).
- El tamaño del anillo no se multiplica por `escala_texto_ui` ni por ningún factor de ventana (G-4, ADR-0016 D3).
- **TODO(ui-owner)**: tipografía, panel y atlas de glifos sin definir en el art bible (GDD OQ 3); esta historia usa los mínimos funcionales †.

---

## Out of Scope

- Cálculo de estado (018), disparo del pulso (021), pie (023), escala F2 (025).

---

## Files

- `src/ui/prompt/ring_view.gd`, `src/ui/prompt/label_view.gd`, `src/ui/prompt/label_policy.gd`
- `tests/unit/prompt/label_policy_test.gd`, `tests/integration/prompt/ring_view_geometry_test.gd`
- Evidencia: `production/qa/evidence/prompt-anillo-etiqueta-evidence.md` + capturas

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: captura retenida (motor, `--write-movie`, procedimiento `.claude/docs/run-and-observe.md`) del anillo en reposo, con relleno `p ≈ 0,6`, con `icono_grande` y con etiqueta activa, en `production/qa/evidence/`; más `label_policy_test.gd` y `ring_view_geometry_test.gd`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 015, 016, 018, 021
- Unlocks: 024
