# Story 008: Movimiento y mirada — F1, F2, F3

> **Epic**: Entrada y controles
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1 día, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Formulas F1 (zona muerta radial), F2 (mirada con ratón), F3 (mirada con stick); § Detailed Design › Core Rules, regla 9
**Requirement**: `TR-input-009`, `TR-input-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (D6 sondeo de ejes, D8 zona muerta propia)
**ADR Decision Summary**: Los ejes se sondean (`get_move_vector`, `consume_look_delta`); el ratón aporta píxeles relativos sin delta (Δθ = px · 0,10°/px · s_m · inv, tope ±45°/fotograma); el stick ω_max · r^1,5 · s_s con delta limitado a 0,1 s; F1 radial sobre ejes crudos, sin la zona muerta del motor. El router entrega solo el cambio de orientación (sin límites de pitch/yaw).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: zona muerta real del mando: NEEDS_MANUAL (S-0006). Valores de evento de eje verificados en `adr0006_input_events_test.gd`.

**Control Manifest Rules (this layer)**:
- Required: F-R42 (constantes † en datos), F-R46
- Forbidden: zona muerta del Input Map
- Guardrail: resultado idéntico a 30 y 144 fps

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md` (tolerancia ±0,001 salvo indicación):*

- [ ] **AC-F1**: v = (0,5; 0,4) → r = 0,613; |v| = 0,15 → 0; 0,14 → 0; 0,95 → 1; 1 → 1; `dz_in` < 0,05 se rechaza al cargar.
- [ ] **AC-F2**: relative (18, −6), s_m = 1, inv = +1 → yaw 1,8°, pitch −0,6°; 3.600 px = 360°; idéntico simulando 30 y 144 fps; un pico se limita a ±45°/fotograma.
- [ ] **AC-F3**: r = 0,613 → ω = 57,6 °/s (±0,1), 0,96 °/fotograma a 60 fps y 1,92 a 30; delta 0,5 s → se usa 0,1 s; ω_max 120 y s_s 2 → 240 °/s; ω_max 180 y s_s 2 → 360 °/s.
- [ ] **AC-09**: relative (1000, 0) se limita a 45°; delta 0,5 s a 0,1 s; el router no aplica límites de cámara.

---

## Implementation Notes

- Firmas (ADR-0006): `get_move_vector() -> Vector2` (normalizado, cero fuera de `EXPLORACION`), `consume_look_delta() -> Vector2` (grados, yaw/pitch).
- Fórmulas como funciones estáticas puras (`src/input/input_formulas.gd`) con los valores † inyectados desde la `BindingTable`.

---

## Out of Scope

- F4 `rotar` (recorte 6, M2); F5 cursor (009).

---

## Files

- `src/input/input_formulas.gd`, `src/input/input_router.gd`
- `tests/unit/input/move_and_look_formulas_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/move_and_look_formulas_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/entrada-y-controles/story-002-engine-input-adapter.md`, `production/epics/entrada-y-controles/story-003-context-stack-and-sinks.md`
- Unlocks: `production/epics/entrada-y-controles/story-009-virtual-cursor.md`
