# Epic: Acceso — puerta A y cajón A05

> **Layer**: Feature
> **GDD**: design/gdd/control-de-acceso.md (§ Overview l. 15, § Acceptance Criteria l. 236)
> **Architecture Module**: Capa 3 — 8 Acceso (`Access` en `planta`; manejadores `C06`, `A05`)
> **Status**: **BLOQUEADO (parcial) por ADR-0005 (Proposed)** — 15/18 TR lo citan (`access/access.json`); 3 libres
> **Desbloqueo**: aceptación de ADR-0005 (spike S-0005-A, C5, O1 de ADR-0018)
> **Stories**: Not yet created — run `/create-stories acceso-puerta-a-cajon-a05` (hoy, solo los 3 TR libres)
> **Control manifest**: v2026-11-11 — § Feature Layer Rules (vacía) + reglas transversales de Foundation
> **Engine Risk**: MEDIUM (colisión de la hoja con Jolt; `AnimationPlayer`/`Tween` en pausa)

## Overview

Estados derivados de puertas, lectores, cajón y ascensor, leídos de hechos. **Alcance M1 solo
puerta A y cajón A05**: `archivo_abierto` → `ANIM_DOOR_OPEN` 1,2 s; A05 entrega I-02 e I-03. Puertas
B y D, lectores y ascensor `C08` fuera (salas B y D fuera del hito). El guardado al abrir la puerta A
queda diferido (recorte 4).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0001: Event bus and fact contract (Accepted) | Estados derivados de hechos; aviso «puerta abierta» | MEDIUM |
| ADR-0002: Pause and game time (Accepted) | Cubre TR-access-012 | HIGH |
| ADR-0005 (**Proposed**) | `access/access.json` | MEDIUM |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-1**: cajón A05 abierto al final de la escena 3.
- **C-M1-5**: `ANIM_DOOR_OPEN` 1,2 s dentro de ±1 fotograma (con el reloj falso).
- **C-M1-3**: la puerta A abre siempre tras `archivo_abierto`, también tras fallos previos de P1.

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` access; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-access-001 | Todos los valores (tiempos, ángulos, LED, claves, IDs) viven en `assets/data/access/access.json` con esquema `doors[]`/`readers[]`/`drawers[]`/`elevator`, validado en carga y en CI | ❌ No ADR (ADR-0005 Proposed) |
| TR-access-002 | El mapa lector→hecho/tarjeta es fijo (`C06`→`tarjeta_B`/`I-02`; `C07` y `D06`→`tarjeta_D`/`I-03`) y el CI lo valida; ID repetido, ancla/hecho inexistente = dato inválido | ❌ No ADR (ADR-0005 Proposed) |
| TR-access-003 | Datos inválidos: en desarrollo error que detiene la ejecución; en build final falla abierto (puerta `ABIERTA`, lector `LISTO`, `A05` `CERRADO`, ascensor con defaults 2,0/8/20,0 s) con una línea ... | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-004 | Estados de puerta (`CERRADA`,`LEYENDO`,`ABRIÉNDOSE`,`ABIERTA`), lector, ascensor y cajón son derivados de hechos + temporizadores; 8 no persiste nada ni escribe ningún hecho | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-005 | Configuración al arrancar síncrona en el mismo fotograma, en el paso 6 del arranque de 4 (tras 7 y 9, con hechos ya definitivos), sin emitir «puerta abierta»; A nace según `archivo_abierto`, B... | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-006 | `can_interact` de lectores/ascensor/cajón es puro y barato (lectura directa de hechos en el paso de física); `interact` revalida el estado | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-007 | Aviso «puerta abierta» (A/B/D) se emite una sola vez por apertura, en el primer paso de `ABRIÉNDOSE`; es idempotente ante avisos duplicados | ADR-0001 ✅ |
| TR-access-008 | La colisión de la hoja se desactiva en el primer paso de `ABRIÉNDOSE`; las puertas nunca se cierran; hueco 1,00 × 2,10 m | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-009 | Hoja animada con `ANIM_DOOR_OPEN` 1,2 s, θ(t)=90°·(3x²−2x³), x=clamp(t/1,2) | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-010 | `interact(Usar)` de lector: `bloquear_contexto("tarjeta")` solo dentro de `interact()` (nulo → `SIN_EFECTO`); cuenta `t_lectura_s` 0,5 s; la apertura no depende del gesto ni de 20 | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-011 | Gesto de tarjeta orquestado en paralelo: `sostener_item` → `objeto_sujeto` (tope 0,6 s) → `reproducir_gesto(HAND_CARD_SWIPE)` ≤1,0 s → `gesto_terminado` → `guardar_item` → `liberar_cont... | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-012 | Todos los temporizadores (8 en total) son de tiempo de juego y se detienen con la pausa | ADR-0002 ✅ |
| TR-access-013 | Ascensor: estados evaluados por prioridad `EN_USO`>`LISTO`>`ESPERA`>`EN_APAGON`>`INACTIVO`; `LISTO` tras `t_ascensor_s` 2,0 s de `llamada_completada` (inmediato si ya verdadero) | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-014 | `EN_USO` siempre sale: «ascensor rechazado» o `t_en_uso_tope_s` 20,0 s (> traspaso de 21 de 12,0 s) | ADR-0001 ✅ |
| TR-access-015 | Enfriamiento único de `MEGA_03` de 8 s (≥ duración+2 s) con reloj de juego; «línea pedida» solo en `INACTIVO` | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-016 | Cajón `A05`: tras `gesto_terminado(HAND_DRAWER, cualquier motivo)` o `t_cajon_tope_s` 3,0 s llama una sola vez a `otorgar("A05")` (idempotente); nace `ABIERTO` solo si ambas tarjetas son verdaderas | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-017 | LED de lector con 3 presentaciones distinguibles sin color (reposo 30 %, leyendo 30–80 % a 2 Hz, abierto 100 %; ≥30 puntos de diferencia); `SIN_TARJETA` y `LISTO` comparten presentación | ADR-0001 ✅ (+ ADR-0005 Proposed) |
| TR-access-018 | Invariantes no-softlock: ninguna puerta cerrada con condición cumplida sin forma de activarla; tarjetas no se gastan; rechazo/cancelación del gesto nunca bloquea apertura ni entrega | ADR-0001 ✅ (+ ADR-0005 Proposed) |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
