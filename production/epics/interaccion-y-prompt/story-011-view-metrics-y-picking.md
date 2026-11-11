# Story 011: `ViewMetrics` (F6), `ViewPicker` y `PointerEvent`

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L — 1,5 días (1–2), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Core Rules, reglas 20, 22; § Formulas › F6
**Requirement**: `TR-interact-015`, `TR-interact-016`, `TR-interact-017`, `TR-interact-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D7 `ViewMetrics`, D8 `ViewPicker`/`PointerEvent`, G-7, G-8, G-9); ADR-0006 (D9/D10 `PointerTargetProvider`, `target_at` — enmienda A-1 aplicada)
**ADR Decision Summary**: el picking de vistas es aritmética 2D sobre `ViewReceiver.elements()` (rect/círculo/polígono en metros) con un `ViewMetrics` inmutable que implementa F6 con eje de FOV explícito; `seleccionar` llega como un único `FIN` con `elemento` (al pulsar) y `elemento_bajo` (al soltar).
**ADR Version**: ADR-0011 2026-11-10 · ADR-0006 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH (eje de FOV; viewport lógico)
**Engine Notes**: S-0011-C: `keep_aspect` por defecto = `KEEP_HEIGHT` (FOV vertical); un quad de 0,10 m a 0,35 m con FOV 70° mide 220,34 px a 1080 y 244,83 px a 1200 en `SubViewport` (= analítico a 3e-5 px). El alto lógico bajo `canvas_items`/`expand` es **NEEDS_WINDOWED**: `ViewMetrics` recibe `W, H` **inyectados**; la fuente viva (`ViewportMapper`, ADR-0016 Proposed) queda diferida — hasta entonces el compositor pasa el tamaño por un puerto con un adaptador provisional registrado como ADR-fallback.

**Control Manifest Rules (this layer)**:
- Required: FE-R08 (`ViewMetrics` único sitio px ↔ m, eje como dato), FE-R09.
- Forbidden: FE-X02 (picking por rayo físico), FE-X03 (codificar 1080/1920/70°/1 200 ppm).
- Guardrail: picking ≤ 0,05 ms por fotograma con ≤ 40 elementos (FE-G01).

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-32**: H = 1080, d = 0,35, FOV_v 70° → ppm 2 203 (±1), 0,04 m = 88 px, 0,10 m = 220 px (±0,5); H = 1200 → 2 448 (±1); FOV horizontal 70° en 16:9 → 3 917 (±2) (con W, H inyectados; la verificación en ventana del 16:10 es NEEDS_WINDOWED).
- [ ] **AC-28**: el cursor sobre una forma da `actualización` con `elemento_bajo` y `pos_vista` en metros; `agarrar` + 12 px da `inicio` con `pos_px` al pulsar, `actualización`… y `fin` con el mismo `elemento` aunque el cursor salga; un clic da un único `FIN` con `elemento` y `elemento_bajo` (ADR-0011 D8/G-9, OI-3); `rotar` 40 px → 10,0°.
- [ ] **AC-30a / AC-30b**: hit-test ≥ 44 px para un elemento de 20 px; umbrales de separación 128/176/256/216 px; severidades excluyentes (fallo de arranque / advertencia / ninguno) y `atraccion_desactivada` lo anula.
- [ ] `gestos_aceptados` se relee en el fotograma siguiente a `elements_changed` y un gesto en curso no cambia de elegibilidad (TR-interact-017); `target_at(p_px)` coincide con el pick de 7.

---

## Implementation Notes

*Derived from ADR-0011 D7/D8:*

- `FOV_v = eje == VERTICAL ? fov : 2·atan(tan(fov/2)·H/W)`; `ppm = (H/2)/(d·tan(FOV_v/2))`; `m = c_m + Vector2(px.x − W/2, H/2 − px.y)/ppm`.
- Orden entre aciertos: `z_orden` mayor, distancia en px menor al centro de la caja, `id` menor. Polígono con test par-impar propio (sin `Geometry2D`).
- `targets()` del proveedor cacheado; se reconstruye solo si cambian `elements()` o `ViewMetrics`. `desplazar`/`actualización` solo cuando cambian posición o `elemento_bajo`.

---

## Out of Scope

- Fit check de la caja (`D01a`, TR-puzzle3-009): sala D fuera de M1. `ViewportMapper` real: ADR-0016.

---

## Files

- `src/interaction/view_metrics.gd`, `src/interaction/view_picker.gd`, `src/interaction/pointer_event.gd`
- `tests/unit/interaction/view_metrics_test.gd`, `tests/unit/interaction/view_picker_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/interaction/view_metrics_test.gd`, `view_picker_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interaccion-y-prompt/story-010-view-receiver-y-cerrar-modos.md`; épico `entrada-y-controles` (cursor y `PointerTargetProvider`)
- Unlocks: `production/epics/interaccion-y-prompt/story-013-recorrido-m1-y-capturas.md`; panel de P1 (`production/epics/puzles-marco-y-p1/`)
