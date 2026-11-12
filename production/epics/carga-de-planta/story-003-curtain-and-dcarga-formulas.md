# Story 003: Fórmulas del telón (F1) y `D_carga` (F3)

> **Epic**: Carga de planta (despacho, pasillo, Archivo)
> **Status**: Done (2026-11-12; suite completa no verificable: ver Evidencia)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S — 0,5 días (0,5–1; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/escena-de-planta.md` — § Formulas F1 (opacidad), F3 (tope declarado y fotogramas de gracia)
**Requirement**: `TR-scene-014`, `TR-scene-015`, `TR-scene-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (Load sequence pasos 0, 2, 8; D5)
**ADR Decision Summary**: α_out = α_0 + (1 − α_0)·S(t/d) con `t += min(Δ_real, Δ_max)`; `d ≤ 0` o α_0 = 1 → salto sin división; `reducir_movimiento` se lee una vez por carga; `D_carga` = d_out + T_cap + N_gap·Δ_ref + d_in con valores **nominales**.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: LOW (lógica pura)
**Engine Notes**: ninguna.

**Control Manifest Rules (Core)**:
- Required: C-R05 (tiempo solo del `RealClock` inyectado)
- Forbidden: C-X05 (`_process(delta)` o `GameClock`)
- Guardrail: —

---

## Acceptance Criteria

- [ ] **AC-F1**: GIVEN d = 0,8 y α_0 = 0, THEN α = 0,5 en t = 0,4; GIVEN α_0 = 0,6, THEN α = 0,8 en t = 0,4; aclarado α = 0,84375 en t = 0,2; d = 0 → se salta sin división por cero; α_0 = 1 → se omite el oscurecido; Δ_real = 0,5 con Δ_max = 0,1 → t avanza 0,1; `reducir_movimiento` → d_out = d_in = 0,1 en todos los `motivo` (α = 0,5 en t = 0,05, sin corte).
- [ ] **AC-F3 (parte 1)**: GIVEN d_out = 0,8, T_cap = 10, N_gap = 2, Δ_ref = 1/30 y d_in = 0,8, THEN `D_carga` = 11,6667 ± 0,001 s; con `reducir_movimiento` verdadero `D_carga` sigue siendo el nominal.

---

## Implementation Notes

- Tolerancia ±0,0001 (GDD). Clases puras (`CurtainMath`, `LoadBudget` o nombres equivalentes en `src/scene/`); los nombres no los fija el ADR.
- Las partes de AC-F3 sobre `N_gap` en fotogramas reales y el fallo por T_cap están en 005 y 007.

---

## Out of Scope

- 005: aplicar α al `Curtain` por fotograma; 007: `t_espera`.

---

## Files

- `src/scene/curtain_math.gd`, `src/scene/load_budget.gd`
- `tests/unit/scene/curtain_formula_test.gd`, `tests/unit/scene/d_carga_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/scene/curtain_formula_test.gd` (T-U4) y `tests/unit/scene/d_carga_test.gd` (T-U5) — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/carga-de-planta/story-002-load-transitions-data.md`
- Unlocks: `production/epics/carga-de-planta/story-005-load-sequence.md`

---

## Evidencia

- `src/scene/curtain_math.gd` (F1 estática + máquina `CurtainMath` sin nodos; `dt_real` lo aporta quien llama desde el `RealClock`; sin Tween/Timer) y `src/scene/load_budget.gd` (`d_out`, `d_in`, `d_carga` nominal).
- `tests/unit/scene/curtain_formula_test.gd` (T-U4, 10 tests) y `d_carga_test.gd` (T-U5, 4 tests): AC-F1 y AC-F3 parte 1 cubiertos (0,5 / 0,8 / 0,84375, d = 0, α_0 = 1, recorte Δ_max, reducir_movimiento 0,1 s, D_carga = 11,6667).
- `-a res://tests/unit/scene`: Overall 38 test cases, 0 errors, 0 failures, 0 orphans; sin «leaked»/«still in use».
- La suite completa no pudo ejecutarse: parse error en `src/input/context_stack.gd` (`NO_DURATION_S`, trabajo en curso de EC-005, ajeno).
- Decisión: `cierre` con `reducir_movimiento` mantiene d_in = 0 (nunca aclara). Firmas `CurtainMath` registradas como `TODO(lead-programmer)` (enmienda a ADR-0003 § Key Interfaces).
