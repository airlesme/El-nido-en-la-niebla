# Story 012: Oráculo de 1.000 secuencias y fallo repetido ×5

> **Epic**: Marco de puzles y puzle 1 (Cronología)
> **Status**: Blocked — BLOCKED: TR-puzzle1-018 sin ADR trazado en `docs/architecture/tr-registry.yaml` (cobertura ADR **NOT ASSESSED**); trazarlo (propuesta abajo) y desbloquear
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1,5 d (confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

Prueba de resolubilidad: un solucionador independiente demuestra que desde cualquier estado
alcanzable P1 llega a `RESUELTO`. Sostiene C-M1-2 y C-M1-3 («sin softlock»).

**GDD**: `design/gdd/puzle-1-cronologia.md` (R39, S7; AC-12) · `design/gdd/marco-de-puzles.md` (regla 30; AC-36)
**Requirement**: `TR-puzzle1-018` (sin ADR), `TR-puzzles-021` (ADR-0010)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: **NOT ASSESSED** para TR-puzzle1-018. Candidato: ADR-0010 § Validation Criteria **T-I6** (`tests/integration/puzzles/solvability_oracle_test.gd`, `N_fuzz` = 1000 secuencias deterministas con semilla por puzle a través de `handle_pointer → evaluate → framework`), que hoy cubre solo TR-puzzles-021.
**ADR Decision Summary**: — (pendiente de trazado)
**ADR Version**: unversioned (sin ADR trazado)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: semilla fija (`RandomNumberGenerator.seed`), sin aleatoriedad de ejecución (estándar de determinismo).

**Control Manifest Rules (this layer)**:
- Required: FE-R13, FE-R15
- Forbidden: FE-X06
- Guardrail: el test no depende del tiempo real

---

## Acceptance Criteria

- [ ] **GDD 11 AC-12 (sin «guardar y cargar»)**: 1.000 secuencias aleatorias de acciones válidas (R13, cancelaciones, cerrar y reabrir) reproducidas por el solucionador independiente desde cada estado por `handle_pointer` llegan siempre a `RESUELTO` y escriben `archivo_abierto`. Pistas: recortadas en M1; «guardar y cargar»: Diferido (ADR-0004).
- [ ] **C-M1-3 (recorrido manual)**: cinco fallos seguidos en P1 en la build `playtest-windows` y resolución después; documentado en `tests/playtest/p1-fallo-x5.md` con una captura del motor.
- [ ] **TR-puzzle1-018 (temporización F5, AC-6/7)**: reutiliza los casos de la story 005 dentro del arnés del oráculo, con `GameClock` falso.

---

## Implementation Notes

**Propuesta de ubicación (para trazar TR-puzzle1-018):**

1. Enmendar `docs/architecture/tr-registry.yaml`: TR-puzzle1-018 → ADR-0010 (T-I6), igual que TR-puzzles-021. Es una ampliación de la tabla de validación de ADR-0010, no una decisión nueva: no hace falta ADR propio.
2. Arnés compartido (código de test, conoce la solución por datos y `elements()`): `tests/helpers/puzzles/solvability_oracle.gd`.
3. Prueba de P1 en la ruta que fija el GDD 11: `tests/unit/puzzle_1/p1_solvability_oracle_test.gd`; T-I6 lo reutiliza para el resto de puzles.

---

## Out of Scope

- Variante con guardar/cargar (ADR-0004) y con pistas (M2).

---

## Files

- `tests/helpers/puzzles/solvability_oracle.gd`
- `tests/unit/puzzle_1/p1_solvability_oracle_test.gd`
- `tests/playtest/p1-fallo-x5.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/puzzle_1/p1_solvability_oracle_test.gd` — must exist and pass; recorrido ×5 documentado.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/puzles-marco-y-p1/story-006-rechazo-uniforme.md`, `production/epics/puzles-marco-y-p1/story-007-resolucion-immediate.md`, `production/epics/puzles-marco-y-p1/story-008-material-vista-compose-i01.md`; trazado de TR-puzzle1-018
- Unlocks: None
