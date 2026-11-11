# Story 009: Cursor virtual F5a/F5b y `PointerTargetProvider`

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Formulas F5a (velocidad del cursor), F5b (atracción asistida); § Detailed Design › Core Rules, regla 12
**Requirement**: `TR-input-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D9) · ADR-0011 (C1: viewport lógico; `PointerTargetProvider.target_at` = pick de 7)
**ADR Decision Summary**: En `vista cercana`, `ordenador`, `llamada` y `menú`, `PointerCursor` (puro) mantiene `p` en píxeles lógicos dentro de `ViewportMapper.logical_rect()` (1920×1080 referencia). Con ratón refleja el cursor real; con mando v_c = 900 · r² · s_c (máx. 2.400 px/s) y atracción F5b hacia el objetivo más cercano del proveedor.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0011 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: viewport lógico bajo `canvas_items`/`expand`: NEEDS_WINDOWED (ADR-0011), se comprueba en 015. El dibujo del cursor es ADR-0016 (Proposed): fuera.

**Control Manifest Rules (this layer)**:
- Required: F-R33 (proveedor como puerto `RefCounted`), F-R42
- Forbidden: mover el cursor del SO / eventos de ratón sintéticos (Alternativa 3 descartada)
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story:*

- [ ] **AC-F5**: r = 0,613 → v_c = 338 px/s (±1); r = 0,2 → 36 px/s; r = 1 con s_c 1,5 → 1.350 px/s; la posición queda dentro de la ventana. d = 40, v_c = 100, 60 fps → w = 0,375, factor 0,080, Δp sin tope 1,2 y final 0,833 px/fotograma (±0,01).
- [ ] **AC-12 (parte L)**: con mando en `vista cercana` u `ordenador`, ambos sticks mueven el cursor; en `llamada` y `menú` solo el derecho; en `exploración` no hay cursor.
- [ ] `set_cursor_visible(requester, visible)` y `get_cursor_position()` responden según el contexto (sin dibujo).

---

## Implementation Notes

- Firmas (ADR-0006): `set_pointer_provider(ctx, provider)`, `set_cursor_visible(requester, visible)`, `get_cursor_position() -> Vector2`; `PointerTargetProvider.targets()`, `on_hover()`, `zone_rect()`, `target_at(p_px)`.
- `ViewportMapper.logical_rect()`: si no existe aún (ADR-0011), *ADR-fallback*: rectángulo fijo 1920×1080 inyectado y nota en la historia de interacción que lo cree.

---

## Out of Scope

- Capa de cursor y su forma (ADR-0016); AC-E18 (V).

---

## Files

- `src/input/pointer_cursor.gd`, `src/input/pointer_target_provider.gd`, `src/input/input_router.gd`
- `tests/unit/input/virtual_cursor_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/virtual_cursor_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-008-move-and-look-formulas.md`
- Unlocks: `production/epics/entrada-y-controles/story-010-gesture-recognizer.md`
