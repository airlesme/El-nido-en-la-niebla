# Story 013: Recorrido en la planta gris — corredor a 30/60/144 fps y captura del despacho

> **Epic**: Jugador en primera persona (sin manos)
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: L — 1,5 días (1–2; confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/jugador-en-primera-persona.md` — § Core Rules R1, R3, R10–R11, § Game Feel
**Requirement**: `TR-player-004`, `TR-player-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (D2; § Spike Results S-0012-A «corridor» NEEDS_WINDOWED; Test Plan «Player-observable checks») · ADR-0003 (geometría de `planta`)
**ADR Decision Summary**: el corredor de 15 s a cada tope de fps es la parte NEEDS_WINDOWED de S-0012-A, diferida al prototipo jugable (manifiesto P-20); se cierra aquí.
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: headless solo alcanzó paseos de 2 s (x ≈ 3,0 m a todo tope); el paseo real de 15 s por tope no se midió. Capturas **con el propio motor**: `--write-movie` (ver `.claude/docs/run-and-observe.md`), nunca captura del escritorio.

**Control Manifest Rules (Core)**:
- Required: C-R15 (α del motor), C-R16
- Forbidden: C-X10 (suavizado exponencial para «arreglar» el feel)
- Guardrail: C-G01; P-20 del manifiesto (pendiente que esta historia cierra)

---

## Acceptance Criteria

- [ ] **AC-06 (I)**: GIVEN el pasillo (X 0 a 24, A.1) y teclado, WHEN avanza en línea recta con `W` sostenido, THEN tarda 15,1 ± 0,3 s, igual con la ventana a 30, 60 y 144 fps (`Engine.max_fps`). Cierra el NEEDS_WINDOWED de ADR-0012 y C-M1-10 (informativo).
- [ ] **AC-07 (I, alcance M1)**: GIVEN la planta gris de M1, WHEN el jugador cruza la puerta A y el umbral de Vera (1,00 m) y recorre el pasillo a su ancho completo, THEN nunca queda atascado ni roza el marco; GIVEN un hueco de mobiliario < 0,50 m, THEN no se puede entrar. *(Puertas B y D: fuera de M1.)*
- [ ] **C-M1-6**: sesión manual registrada: mando y teclado mueven y miran en el despacho, pasillo y Archivo.
- [ ] **C-M1-7 (despacho)**: captura retenida del despacho desde `spawn_office`, hecha con `--write-movie`, más visto bueno del lead.

---

## Implementation Notes

- Medición AC-06: script de dev que fija `W` y registra el tiempo en el log (`src/dev/` o `tests/`), una carrera por tope; archivar resultados en el informe de evidencia.
- Feel a 144 fps: comprobar a ojo que no hay saltos de cámara (el fallo del acumulador propio aparecía justo a 144 fps).
- No añadir manos ni FOV F5.

---

## Out of Scope

- Captura del Archivo y S-0003-C: `production/epics/carga-de-planta/story-015-new-game-gray-walk-evidence.md`.

---

## Files

- `production/qa/evidence/jugador-013-despacho.png` (o el formato que produzca `--write-movie`)
- `production/qa/evidence/story-013-gray-walk-evidence-evidence.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: captura retenida en `production/qa/evidence/` (motor, `--write-movie`) + sign-off en `production/qa/evidence/story-013-gray-walk-evidence-evidence.md` con los tiempos de AC-06 a 30/60/144 fps y la sesión de C-M1-6.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/jugador-primera-persona/story-012-physics-walk-integration.md`, `production/epics/carga-de-planta/story-013-gray-planta-geometry.md`, `production/epics/carga-de-planta/story-015-new-game-gray-walk-evidence.md` (se pueden ejecutar en la misma sesión)
- Unlocks: None
