# Epic: Audio provisional (escenas 1–3, reproducción plana)

> **Layer**: Feature (sistema C3 alojado como autoload)
> **GDD**: design/gdd/director-de-audio.md (§ Overview l. 16, § Acceptance Criteria l. 351) — solo el subconjunto plano
> **Architecture Module**: Capa 3 — 23 Audio (`AudioDirector`, autoload n.º 6, `AudioDirectorAutoload`); `architecture.md` § API Boundaries «Audio (23) — ADR-0008»
> **Status**: **BLOQUEADO por ADR-0008 (Proposed)** — los 10 TR del alcance M1 (y los 26 del sistema 23) citan ADR-0008; 0 libres
> **Actualizado 2026-11-11**: épico nuevo (índice Q1); ningún ADR aceptado hoy lo desbloquea. ADR-0009 (Accepted) fija el slot del autoload y su `setup(ctx)`, no el contrato de voz
> **Desbloqueo pendiente**: aceptación parcial de ADR-0008 — Spike Plan SA1 (árbol de buses), SA3 (`get_length()`), SA5 (falta vs roto, en export), SA6 (sin dispositivo) + S8/S9 de ADR-0002 (`stream_paused`, audio con el árbol pausado) si no se ejecutaron; C2; C3 (enmienda que pide ADR-0017). SA7–SA10 se difieren con el audio por zonas
> **Dueño propuesto**: audio-director (implementa engine-programmer; sonidos provisionales: sound-designer) — **pendiente de aceptar por el usuario**
> **Stories**: Not yet created — run `/create-stories audio-provisional` tras la aceptación parcial de ADR-0008 y la regeneración del manifiesto (índice Q2)
> **Control manifest**: v2026-11-11 — § Feature Layer Rules (vacía) + reglas transversales de Foundation
> **Engine Risk**: HIGH (`process_mode` del nodo de audio con el árbol pausado, `stream_paused` sin verificar en 4.7; `area_mask` 0 en 4.7 si se usan fuentes 3D)

## Overview

Reproducción **plana** (sin espacialización por estancia, sin ducking, sin polifonía con robo)
de lo que el hito pide en las escenas 1–3: `VO_V_01` y `MEGA_01` en C.1, `VO_V_04` en C.3, el
ventilador del despacho (`AMB_FAN`) y la lluvia, incluida su intensificación al leer la fecha
(C.3). El `AudioDirector` es el definitivo de ADR-0009 (autoload persistente, `setup(ctx)` tras
3 y 6, `FakeAudioDirector` para tests), recortado a lo mínimo: responde a «línea pedida» con
exactamente una señal de respuesta para que el director (21) avance sin depender de duraciones
fijas. **Fuera:** ducking, prioridades P1–P5 y robo, pasos, sobresaltos, muestra de volumen,
loudness, marcadores de escena y volúmenes `audio_room`, presupuesto de memoria (todo con el
recorte 7b, audio por zonas, a M3) y el bloque de volúmenes de ajustes (recorte 7a).

**Alcance verificado en el hito:** § Alcance, escena 1 «Audio provisional»; § ADR y spikes,
0008 «Parcial (audio provisional)»; § Recortable, audio por zonas sustituido por «Audio plano
provisional». **Por qué no encaja sin ADR-0008:** los 26 TR del sistema 23 citan ADR-0008, y la
regla del hito impide escribir historias sobre TR con un ADR `Proposed`. Mientras siga
bloqueado, el director usa la ruta «sin audio» (duración de lectura, F3 del GDD 23) y C.1 se
recorre en silencio: evita bloquear al director, no cumple el «audio provisional» del hito.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0008: Audio buses, voice queue and process mode (**Proposed**) | Árbol de buses (D1), canales de voz con cola de 1 y respuesta única (D3/D4), sin dispositivo (D10), ciclo de vida (D12) | HIGH |
| ADR-0009: Service composition (Accepted) | `AudioDirector` autoload n.º 6; `setup(ctx)` tras 3 y 6; `FakeAudioDirector` | LOW |
| ADR-0002: Pause and game time (Accepted) | `PROCESS_MODE_ALWAYS` con pausa propia (QQ-06); plazos en `GameClock` | HIGH |
| ADR-0001: Event bus and fact contract (Accepted) | «línea pedida» / «línea terminada» / «sin audio» / «fallida» por el bus | MEDIUM |
| ADR-0017: Scene director timeline and call data (Accepted) | Consumidor de las respuestas; su enmienda C3 vive en ADR-0008 | MEDIUM |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-1**: `VO_V_01`, `MEGA_01`, `VO_V_04`, ventilador y lluvia suenan en `playtest-windows` y
  `playtest-linux`; sin dispositivo de audio el recorrido sigue hasta la escena 3.
- **C-M1-5**: cada «línea pedida» de C.1 y C.3 recibe exactamente una respuesta; los tiempos de
  la línea de tiempo siguen dentro de ±1 fotograma (test con `GameClock` falso y `FakeAudioDirector`).
- **C-M1-9**: 0 errores en consola; un recurso de audio ausente o roto da «fallida»/«sin audio», nunca un cuelgue.

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system: audio`; todas
`active`. **Solo el subconjunto de M1** (10 de 26); el texto es un resumen: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-audio-001 | Nodo persistente bajo la raíz que sobrevive a las cargas, `process_mode` siempre activo; arranca tras 3 y 6 | ADR-0002, ADR-0009 ✅ (+ ADR-0008 Proposed) |
| TR-audio-002 | Árbol de buses fijo creado al arrancar (`Voice` con `Voice_Vera`/`Voice_Mega`/`Voice_Guardian`, `Effects`, `Ambience`, `Music`) — en M1 basta con `Voice_Vera`, `Voice_Mega` y `Ambience` poblados | ❌ Bloqueado (ADR-0008 Proposed) |
| TR-audio-005 | Catálogo `audio_catalog.json` y `audio_settings.json`; valores † desde datos | ❌ Bloqueado (ADR-0008 Proposed) |
| TR-audio-006 | Contrato de respuesta: cada «línea pedida» aceptada recibe exactamente una señal («terminada», «sin audio» o «fallida») | ADR-0001 ✅ (+ ADR-0008 Proposed) |
| TR-audio-007 | «Línea pedida» solo acepta `line_id` del catálogo de 18; los SFX van por «sonido pedido» | ADR-0001 ✅ (+ ADR-0008 Proposed) |
| TR-audio-008 | Canales de voz por prefijo con cola de 1 y tope `t_cola_canal_s` — en M1 `VO_V_*` y `MEGA_*` | ❌ Bloqueado (ADR-0008 Proposed) |
| TR-audio-009 | Techo y corte `techo_s = fallback_s + line_grace_s` | ❌ Bloqueado (ADR-0008 Proposed) |
| TR-audio-016 | «Carga iniciada»: cancela voces en curso y encoladas sin señal | ❌ Bloqueado (ADR-0008 Proposed) |
| TR-audio-017 | Capas persistentes: lluvia y drone sobreviven a la carga; `AMB_FAN` se detiene — en M1, ventilador y lluvia planos con su intensificación de C.3 | ❌ Bloqueado (ADR-0008 Proposed) |
| TR-audio-019 | Sin dispositivo: modo `sin_dispositivo`, toda línea → «sin audio» en ≤ 1 fotograma | ❌ Bloqueado (ADR-0008 Proposed) |

Fuera de M1 (con el recorte 7b, a M3): TR-audio-003, 004, 010–015, 018, 020–026.

## Requisitos bloqueados (al 2026-11-11)

| TR-ID | Bloqueado por | Motivo / salida |
|-------|---------------|-----------------|
| TR-audio-001, 002, 005, 006, 007, 008, 009, 016, 017, 019 | ADR-0008 (Proposed) | audio; aceptación parcial de ADR-0008 (índice (b) n.º 1) |

## Orden sugerido de historias (tras el desbloqueo)

1. Autoload persistente y `setup(ctx)` con `FakeAudioDirector` (TR-001).
2. Buses mínimos y catálogo provisional (TR-002, 005).
3. «Línea pedida» con respuesta única y dos canales `VO_V_*` / `MEGA_*` (TR-006, 007, 008, 009).
4. Sin dispositivo y recurso ausente o roto (TR-019).
5. Capas de ventilador y lluvia, intensificación de C.3, cancelación en carga (TR-016, 017).

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance (subconjunto plano de este épico)
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Audio is checked by a recorded listening session in both exports (no screenshot applies)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
