# Historias — Épico «Jugador en primera persona (sin manos)»

> **Épico**: `production/epics/jugador-primera-persona/EPIC.md` · **GDD**: `design/gdd/jugador-en-primera-persona.md`
> **Generado**: 2026-11-11 por `/create-stories` (modo `autonomous`, `workflow: standard`, `story_granularity: balanced`, `docs.density: balanced`, `qa.level: standard`)
> **Manifest Version**: 2026-11-11b · **ADR Version** (todas): 2026-11-10
> **Review**: QL-STORY-READY skipped — Lean mode
> **Estimaciones**: días de una persona, **confianza BAJA** (sin historial de sprints ni velocidad; no calibradas).

## Estado de los ADR (comprobado con `## Status` y `.claude/scripts/adr-status.sh`, 2026-11-11)

ADR-0012 Accepted · ADR-0002 Accepted · ADR-0005 Accepted · ADR-0006 Accepted · ADR-0009 Accepted · ADR-0003 Accepted · **ADR-0013 Proposed** · **ADR-0007 Proposed** (ADR-0012 lo lista en `depends_on` solo para el lector de Ajustes `balanceo_camara`/`campo_vision`)

## Historias

| ID | Título | Tipo | Est. (días, BAJA) | Depende de | Estado |
|----|--------|------|-------------------|------------|--------|
| 001 | [`PlayerConfig` y validación de `player.json`](story-001-player-config.md) | Logic | 1 (0,5–1,5) | — (cargador de ADR-0005) | Ready |
| 002 | [Locomoción F1/F2 en el marco del cuerpo](story-002-locomotion.md) | Logic | 1 (0,5–1,5) | 001 | Ready |
| 003 | [`TickInterpolator` con la fracción del motor](story-003-tick-interpolator.md) | Logic | 0,5 (0,5–1) | — | Ready |
| 004 | [Mirada 1:1: yaw/pitch, límites y roll 0](story-004-look.md) | Logic | 1 (0,5–1,5) | 001 | Ready |
| 005 | [`BobMath`: balanceo de cámara ligado a la distancia](story-005-bob-math.md) | Logic | 1 (0,5–1,5) | 001 | Ready |
| 006 | [`StepTracker` y señal `paso`](story-006-step-tracker.md) | Logic | 0,5 (0,5–1) | 001 | Ready |
| 007 | [`PoseHistory` y `YawWindow` (servicios)](story-007-pose-history-yaw-window.md) | Logic | 1 (0,5–1,5) | 001 | Ready |
| 008 | [`StuckGuard`: red de seguridad](story-008-stuck-guard.md) | Logic | 0,5 (0,5–1) | 001 | Ready |
| 009 | [Máquina de estados del Jugador y `colocar`](story-009-state-machine-colocar.md) | Logic | 1 (1–2) | 002, 004, 007 | Ready |
| 010 | [`CameraLease`: cesión y devolución de cámara](story-010-camera-lease.md) | Logic | 1,5 (1–2) | 004, 009 | Ready |
| 011 | [`Player.tscn`, rig y API pública cerrada](story-011-player-node-api.md) | Logic | 1,5 (1–2) | 002–010 | Ready |
| 012 | [Integración física headless: muros, objetos y zona](story-012-physics-walk-integration.md) | Integration | 1 (1–2) | 011; carga-de-planta 011 | Ready |
| 013 | [Recorrido en la planta gris: corredor 30/60/144 fps y captura del despacho](story-013-gray-walk-evidence.md) | Visual/Feel | 1,5 (1–2) | 012; carga-de-planta 013, 015 | Ready |

**13 historias: 11 Logic, 1 Integration, 1 Visual/Feel, 0 UI, 0 Config/Data; 0 Blocked.** Total ≈ 13 días (rango 9–20).

Orden recomendado: 001 → 003 → 002 → 004 → 005/006/007/008 → 009 → 010 → 011 → 012 → 013.

## Diferido / bloqueado por ADR (no se escriben historias)

| Qué | TR | ACs del GDD | Bloqueado por | Nota |
|-----|----|-------------|---------------|------|
| Manos: plano propio, `fov_manos`, no atravesar muros, luz del apagón | TR-player-010 | AC-31, -32, -33, -34 | **ADR-0013** (Proposed) | Recorte 1 de M1 (→ M4) |
| Transformada que lee cada servicio | TR-player-005 | AC-22 (se *verifica* en 011 vía TR-player-020; la fila sigue diferida) | **ADR-0013** (Proposed) | La fila co-cita manos |
| FOV por F5 (aspecto, tope 120° h, `campo_vision` en el acto) | TR-player-008 | AC-18, AC-19, AC-44 (parte 32:9) | **ADR-0013** (Proposed) + **ADR-0007** (Proposed, lector de Ajustes) | En M1 la cámara usa `campo_vision` por defecto 70° con `KEEP_HEIGHT` (011): igual a F5 en 16:9, 16:10, 4:3 y 21:9 (AC-18). **Recomendación**: separar la parte F5 de TR-player-008 en `/architecture-review` para desbloquear `CameraFov` |
| Pausa: congelar todo y reanudar | TR-player-015 | AC-27 | **ADR-0013** (Proposed) | La guarda G-4 de ADR-0002 sí entra en 002/011 (C-R14); el test de 600 pasos queda diferido. Pausa es recortable (recorte 5) |
| Enlace en vivo con Ajustes (`balanceo_camara`, `campo_vision`) | TR-player-009 (parte), TR-player-008 | AC-17 (cambio disparado por Ajustes), AC-19 | **ADR-0007** (Proposed) | La rampa `t_cambio_balanceo` se prueba en 005 con nivel inyectado |

### Fuera de alcance M1 (ADR Accepted, pero recorte 1 «manos» o escena fuera de M1)

| Qué | TR | ACs | Motivo |
|-----|----|-----|--------|
| `HandSlots` (gestos, ranuras) y objeto sostenido F10 | TR-player-011, TR-player-012 | AC-28, -29, -30, -46, -47, -48, -49, -50, -51 | Recorte 1 (manos → M4). En 011 las operaciones de manos existen (API cerrada, AC-04) y rechazan con log |
| Reflejo del patio de luces | — | AC-43 | Escena 4, fuera de M1 |
| Playtest de mareo/hielo (5 jugadores) | — | AC-42 | Plan técnico M5 |

## Riesgos y notas del productor

- **Alcance vs. plazo (escalado)**: este épico (~13 d) más carga-de-planta (~15,5 d) ≈ 28 días-persona de una sola persona, contra un M1 cuyo esperado es 3 (semanas, tabla del hito) para **11** sistemas imprescindibles. Ver resumen al usuario.
- El épico pide aplicar **H10 y H12** de la cola de diseño (jugador/manos) antes de las historias: no se ha comprobado su estado; `/story-readiness` debe hacerlo.
- **OI-3** de ADR-0012 (signo de `consume_look_delta()`) se resuelve en 004.
- `EPIC.md` no es UTF-8 válido: su tabla «Stories» no se actualizó desde esta ejecución (Edit lo rechaza). Este índice la sustituye hasta convertirlo.
