# Story 003: `TickInterpolator` con la fracción del motor

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S — 0,5 días (0,5–1; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Core Rules R10–R11 (paso fijo + presentación interpolada)
**Requirement**: `TR-player-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D2, enmendado 2026-11-11 por S-0012-A R1; P-3)
**ADR Decision Summary**: interpolación propia del rig, interpolación física del motor apagada; α = `Engine.get_physics_interpolation_fraction()` en cada `_process`; `TickInterpolator` **no** lleva acumulador propio.
**ADR Version**: 2026-11-10 (D2 enmendado 2026-11-11, commit 7c6a031)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: **Medido en S-0012-A (Spike Results 2026-11-11)**: el acumulador espejo `acc += delta − dt·ticks` FALLÓ (desviación 13,8 % a 30 fps, 25,9 % a 60, 69,9 % a 144; 54,4 % sin tope; saltos no monótonos). `Engine.get_physics_interpolation_fraction()` con la interpolación del motor apagada: desviación ≤ 1e-13, 0 fotogramas no monótonos a 30/60/144/sin tope. NP-1 PASS: todos los ticks pendientes corren antes de `_process` (2 ticks/fotograma a 30 fps, 0–1 a 144).

**Control Manifest Rules (Core)**:
- Required: C-R15 (`prev ← curr ← new` por tick; `lerp(prev, curr, α)` por fotograma; α = fracción del motor; `reset(p)` en `colocar` y en la recolocación de seguridad)
- Forbidden: C-X09 (acumulador propio de α), C-X10 (suavizado exponencial), C-X11 (interpolación del motor o `get_global_transform_interpolated()` / `reset_physics_interpolation()`)
- Guardrail: C-G01 (≤ 0,10 ms media por fotograma en `_process`)

---

## Acceptance Criteria

*TR-player-004 no tiene AC L propio en el GDD (su AC es AC-06, integración, en 013). Criterios de la fila del registro y del Test Plan T-U2 de ADR-0012:*

- [ ] Con secuencias sintéticas de fotogramas a 30, 60 y 144 fps (α inyectado), la posición presentada es `lerp(prev, curr, α)` y nunca extrapola (α en [0, 1]).
- [ ] `reset(p)` deja `prev = curr = p`: el primer fotograma tras `colocar` no hace barrido.
- [ ] Con α congelado (pausa, variante A de ADR-0002) la salida no cambia entre fotogramas y continúa desde ahí al reanudar.
- [ ] La fase de paso `d` y la razón `r` se interpolan con el mismo α (`lerp(d_prev, d_curr, α)`, `lerp(r_prev, r_curr, α)`).

---

## Implementation Notes

- `TickInterpolator` es `RefCounted` sin motor (C-R22): **recibe** α; la lectura de `Engine.get_physics_interpolation_fraction()` vive en el `_fraction()` del `Player` (011), única llamada NP-3 permitida (C-X11).
- El texto de D2/P-3 sobre `acc`/`ticks` en `reset` queda obsoleto (contradicción X-01 del manifiesto): no implementar `acc`.
- La firma exacta de los métodos (`push(...)`, `sample(alpha)`) no la fija el ADR: se define aquí y se anota en ADR-0012 (ADR-fallback).
- La variante B de pausa (árbol sin pausar) no está medida (manifiesto P-24): fuera de esta historia.

---

## Out of Scope

- 011: aplicar la salida a `Rig`; 013: AC-06 en ventana real (NEEDS_WINDOWED).

---

## Files

- `src/player/tick_interpolator.gd`
- `tests/unit/player/tick_interpolator_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/tick_interpolator_test.gd` (T-U2) — must exist and pass. Regresión de motor ya existente: `tests/unit/engine_facts/adr0012_tick_interpolation_test.gd`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/jugador-primera-persona/story-011-player-node-api.md`
