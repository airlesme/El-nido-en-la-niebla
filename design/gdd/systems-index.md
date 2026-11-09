# Systems Index: El Nido en la Niebla

> **Status**: Draft
> **Created**: 2026-11-08
> **Last Updated**: 2026-11-09 (ronda de corrección 6)
> **Source Concept**: design/gdd/game-concept.md
> **Source of truth for details**: design/slice/slice-v0.3.md (versión v0.4; Anexos A–D)

---

## Overview

El Nido en la Niebla es una aventura de puzles en primera persona sin combate, enemigos ni economía. Su alcance mecánico es un **estado de juego** (banderas) que gobierna accesos, un **marco de puzles** común con seis implementaciones distintas, una **capa narrativa** de documentos, correos, escenas temporizadas y una llamada con variantes, y una **capa sensorial** (luz, audio y shaders) que sustituye al susto mecánico. El bucle (buscar información → resolver puzle → descubrir historia) exige primero el núcleo jugable en gris, y después la capa de calidad que hace el slice enseñable.

Los pilares condicionan el mapa: *Tensión sin castigo* obliga a que cada puzle y el guardado sean a prueba de softlock; *Información incompleta* mantiene los datos narrativos fuera del código (sistema 18); *El espacio expresa la emoción* justifica que atmósfera, audio y shaders sean sistemas propios y no decoración. Como el MVP y el Vertical Slice coinciden en contenido (el slice *es* el objetivo), «MVP» significa aquí «jugable de principio a fin con geometría gris» y «Vertical Slice» significa «capa de calidad para enseñarlo».

Se excluyen a propósito combate, IA de enemigos, economía, progresión, red y localización a otros idiomas (slice §3). La localización queda reducida a claves de traducción dentro del sistema 18 (decisión D-10).

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Entrada y controles | Core | MVP | Revisado (ronda 6) — sin bloqueantes | design/gdd/entrada-y-controles.md | — (blandas: 3, 4, 18) |
| 2 | Jugador en primera persona (movimiento, cámara, manos) | Core | MVP | Revisado (ronda de corrección 6) — pendiente de re-review | design/gdd/jugador-en-primera-persona.md | 1, 4 (blandas: 6, 18) · dependen de 2 (no al revés; las declaran ellos): 9 (blanda, vía 7) y 10 (indirecta), además de 7, 19, 20, 22 |
| 3 | Estado del juego y bus de eventos | Core | MVP | Revisado (ronda de corrección 3) — pendiente de re-review | design/gdd/estado-y-bus-de-eventos.md | — |
| 4 | Escena de planta y carga de Recepción | Core | MVP | Revisado (ronda 6) — sin bloqueantes | design/gdd/escena-de-planta.md | 3 (blandas: 1, 6, 18); 2 (dura) |
| 5 | Guardado y carga | Persistence | MVP | Revisado (ronda de corrección 6) — pendiente de re-review | design/gdd/guardado-y-carga.md | 3, 4 (duras) · blanda 18 |
| 6 | Ajustes persistentes (inferred) | Persistence | MVP | Revisado (ronda de corrección 4) — pendiente de re-review | design/gdd/ajustes-persistentes.md | 1 (blanda; la declaran 6 y 1; sin ciclo) · blanda 18 |
| 7 | Interacción e inspección | Gameplay | MVP | Revisado (ronda de corrección 4) — pendiente de re-review | design/gdd/interaccion-e-inspeccion.md | 1, 2, 4, 18 (blandas: 3, 6) |
| 8 | Control de acceso (puertas, tarjetas, lectores, ascensor `C08`, cajón `A05`) | Gameplay | MVP | Revisado (ronda 6) — sin bloqueantes | design/gdd/control-de-acceso.md | 3, 4, 7, 18, 20 (duras; 8 → 20 dura, 20 no depende de 8) · indirecta 22 (vía 3, por `llamada_completada`; la declara 8 y 22 la repite) · blandas 2, 5, 9, 21, 23, 28/29 |
| 9 | Marco de puzles (inferred) | Gameplay | MVP | Revisado (ronda de corrección 4) — pendiente de re-review | design/gdd/marco-de-puzles.md | 3, 4, 7, 10, 19 (duras; 9 ↔ 10 circular, ver Circular Dependencies), 18 (dura en validación) · blandas 2, 5, 6, 20, 23, 25, 26 · dependen de 9 (no al revés): 8 (blanda), 21 y 22 (indirectas; 22 la declara), 10, 11–16 y 17 (duras) |
| 10 | Caja y compartimentos | Gameplay | MVP | Revisado (ronda 6) — sin bloqueantes | design/gdd/caja-y-compartimentos.md | 3, 4, 7, 9 (duras; 9 ↔ 10 circular) · blandas 5, 20, 23 · indirectas 1, 2, 21 (las declara 10) |
| 11 | Puzle 1 · Cronología | Gameplay | MVP | Not Started | — | 9, 18, 19, 20 |
| 12 | Puzle 2 · Memorando en el cristal | Gameplay | MVP | Not Started | — | 7, 9, 18 |
| 13 | Puzle 3 · Encaje de la foto | Gameplay | MVP | Not Started | — | 6, 9, 10 |
| 14 | Puzle 4 · Tablero de tareas | Gameplay | MVP | Not Started | — | 9, 10, 18 |
| 15 | Puzle 5 · Espejo de la diferencia | Gameplay | MVP | Not Started | — | 6, 9, 10, 13 |
| 16 | Puzle 6 · Decisión | Gameplay | MVP | Not Started | — | 9, 10, 18 |
| 17 | Sistema de pistas (hasta 3 niveles; 2 en el puzle 6) | Gameplay | Vertical Slice | Not Started | — | 3, 9, 18 |
| 18 | Base de contenido narrativo (líneas, documentos, claves de traducción) | Narrative | MVP | Revisado (ronda de corrección 3) — pendiente de re-review | design/gdd/base-de-contenido-narrativo.md | — |
| 19 | Ordenador, correo e impresora | Narrative | MVP | Revisado (ronda 6) — sin bloqueantes | design/gdd/ordenador-correo-impresora.md | 1, 3, 4, 7, 18, 20 (duras; 9 depende de 19, dura) · blandas 2, 6, 17, 23, 25/30 · indirecta 21 (vía 7, sin camino en el slice) |
| 20 | Documentos y bolsillo | Narrative | MVP | Revisado (ronda 6) — sin bloqueantes | design/gdd/documentos-y-bolsillo.md | 3, 4, 7, 18 (duras) · blandas 1, 2, 10 · indirecta 5 · dependen de 20: 8 y 19 (duras), 9, 17 y 24 (blandas; 9 → 20 la declara 9: 20 no depende de 9), 21 (indirecta, la declara 21) |
| 21 | Director de escenas (escenas 1–8, disparadores, eventos temporizados) | Narrative | MVP | Revisado (ronda de corrección 6) — pendiente de re-review | design/gdd/director-de-escenas.md | 1, 3, 4, 18 (duras) · blandas 5, 6, 7, 8 · indirectas 2, 9, 10, 20, 22 (22 vía 3, por `llamada_iniciada`/`llamada_completada`; la declara 21 y 22 la repite) · sin dependencia 23, 26, 27, 28 (19 ↔ 21 indirecta vía 7, la declara 19; 21 no depende de 19) |
| 22 | Llamada telefónica | Narrative | MVP | Revisado (ronda de corrección 6) — pendiente de re-review | design/gdd/llamada-telefonica.md | 1, 3, 5, 7, 18 (duras; la dureza la declara 22, el dependiente, y los proveedores la repiten) · blanda 2 · indirectas 8, 9 y 21 (vía 3; 8 y 21 la declaran como dependientes, 9 la declara 22) · sin dependencia 4, 6 · 23 y 26 (sin GDD): contrato ‡ fuera de dependencias (D22-25) |
| 23 | Director de audio | Audio | Vertical Slice | Not Started | — | 3, 6, 18 (blanda: 2) |
| 24 | Prompt de interacción y feedback | UI | MVP | Not Started | — | 1, 7, 18 |
| 25 | Menú de pausa | UI | MVP | Not Started | — | 1, 6, 18 (blanda: 5) |
| 26 | Subtítulos | UI | Vertical Slice | Not Started | — | 6, 18, 23 |
| 27 | Pantalla de título, advertencias y cierre | UI | Vertical Slice | Not Started | — | 1, 3, 5, 6, 18 |
| 28 | Atmósfera reactiva (luces, apagón, reflejo retardado, lluvia) | Presentation | Vertical Slice | Not Started | — | 2, 3, 6, 21 |
| 29 | Shaders y efectos de superficie | Presentation | Vertical Slice | Not Started | — | 12, 15 |
| 30 | Opciones de accesibilidad | Meta | Vertical Slice | Not Started | — | 1, 6, 13, 15, 23, 26 |

Notas de dependencia:
- **Eventos, no llamadas directas:** audio (23), atmósfera (28), subtítulos (26) y el avance de la llamada (22) reaccionan al bus de eventos (3). Por eso el director de escenas (21) no depende de ellos ni de la llamada.
- **Pausa (25) y pistas (17):** el menú de pausa es MVP y no depende de las pistas; el sistema 17 se enchufa a su menú después.
- **Shaders (29)** tienen versión provisional en los puzles 12 y 15 durante el MVP (texto/mezcla sin shader final).
- **Dependientes del Jugador (2):** 7, 19, 20, 22, 23 y 28 (informe de revisión del GDD 2). **Contrato 2↔7:** el GDD 2 es la fuente de verdad.
- **Marco de puzles (9):** el dueño (10) consulta `get_view_gate(view_id)` antes de abrir la vista (API de 7/10); 20 debe ofrecer `has_item(item_id)`.
- **Sistema 17:** hasta tres niveles de pista por puzle; el puzle 6 tiene dos. Solo existen 8 claves `PISTA_*` con texto (GDD 18 regla 20); los efectos sin texto (p. ej. el resaltado `HIGHLIGHT` de P1 nivel 1) viven en los datos del puzle.
- **Fuera de este índice:** el registro de herramientas de IA para Steam (slice §18) es una tarea de documentación, no un sistema de juego.

---

## Categories

| Category | Description | Systems |
|----------|-------------|---------|
| **Core** | Fundamentos de los que todo depende | 1, 2, 3, 4 |
| **Persistence** | Estado guardado y ajustes | 5, 6 |
| **Gameplay** | Interacción, acceso y puzles | 7–17 |
| **Narrative** | Contenido, documentos, escenas y llamada | 18–22 |
| **Audio** | Capas, voces y silencios | 23 |
| **UI** | Prompt, pausa, subtítulos, título | 24–27 |
| **Presentation** | Luz reactiva y shaders | 28, 29 |
| **Meta** | Accesibilidad | 30 |

(No aplican Economy ni Progression: el slice no las contiene.)

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Necesario para jugar el slice de principio a fin con geometría gris y responder «¿funciona el bucle?». | Prototipos gris, caja y llamada (slice §23, semanas 1–3) | Design FIRST |
| **Vertical Slice** | Capa de calidad para enseñarlo: audio, subtítulos, pistas, título, atmósfera, shaders y accesibilidad. | Pase de calidad y demo | Design SECOND |
| **Alpha** | Sin sistemas asignados: el documento excluye lo que iría aquí. | — | — |
| **Full Vision** | Sin sistemas asignados todavía; se decide en el gate de preproducción (slice §23.5). | — | — |

Reparto: **23 MVP · 7 Vertical Slice · 0 Alpha · 0 Full Vision** (30 en total).

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Entrada y controles (1)** — todo lo que el jugador hace pasa por aquí; remapeo y mando desde el principio. Sin dependencias duras (blandas: 3, 4, 18).
2. **Estado y bus de eventos (3)** — única fuente de verdad de las banderas (Anexo D.2) y canal de comunicación entre sistemas.
3. **Base de contenido narrativo (18)** — líneas con ID, documentos y claves de traducción; el contenido vive en datos, no en código.

### Core Layer (depends on foundation)

1. **Ajustes persistentes (6)** — depends on: 1 (dura de contrato; blanda: 18) (guarda el bloque de asignaciones y ajustes de manejo; volúmenes y subtítulos que otros sistemas leen).
2. **Escena de planta (4)** — depends on: 3, 2 (duras; 2 ↔ 4 dura en ambos sentidos, la declaran 4 y 2) · blandas 1, 6, 18.
3. **Jugador en primera persona (2)** — depends on: 1, 4 (blandas: 6: `balanceo_camara`, `campo_vision`; 18).
4. **Guardado y carga (5)** — depends on: 3, 4 (duras) · blanda 18 (no depende de 6: ficheros independientes, GDD 5 regla 4). **Bloqueo cruzado con el 3:** necesita `snapshot_version` y los avisos «guardado en riesgo» / «guardado restablecido» (añadidos al GDD 3 el 2026-11-09; falta re-review del 3).
5. **Director de audio (23)** — depends on: 3, 6, 18 (blanda: 2). *(Capa Core, prioridad Vertical Slice.)*

### Feature Layer (depends on core)

1. **Interacción e inspección (7)** — depends on: 1, 2, 4, 18 (blandas: 3, 6).
2. **Marco de puzles (9)** — depends on: 3, 4, 7, 10, 19 (duras; 9 ↔ 10 circular, ver Circular Dependencies), 18 (dura en validación) · blandas 2, 5, 6, 20, 23, 25, 26.
3. **Control de acceso (8)** — depends on: 3, 4, 7, 18, 20 (duras; 8 → 20 dura) · blandas 2, 5, 9, 21, 22, 23, 28/29.
4. **Documentos y bolsillo (20)** — depends on: 3, 4, 7, 18 (duras) · blandas 1, 2, 10 · indirecta 5 (9 y 21 dependen de 20, no al revés).
5. **Ordenador, correo e impresora (19)** — depends on: 1, 3, 4, 7, 18, 20 (duras) · blandas 2, 6, 17, 23, 25/30 · indirecta 21 (vía 7).
6. **Caja y compartimentos (10)** — depends on: 3, 4, 7, 9 (duras; 9 ↔ 10 circular) · blandas 5, 20, 23 · indirectas 1, 2, 21.
7. **Puzles 1–6 (11–16)** — depend on: 9 (más 10 los de la caja, 18 los de texto, 19 y 20 el puzle 1, 13 el puzle 5).
8. **Director de escenas (21)** — depends on: 1, 3, 4, 18 (duras) · blandas 5, 6, 7, 8 · indirectas 2, 9, 10, 20 · sin dependencia 22, 23, 26, 27, 28.
9. **Llamada telefónica (22)** — depends on: 1, 3, 5, 7, 18 (duras, las declara 22) · blanda 2 · blandas ‡ 23, 26 · indirecta 9 (vía el bus) · sin dependencia 4, 6, 21.
10. **Sistema de pistas (17)** — depends on: 3, 9, 18.

### Presentation Layer (depends on features)

1. **Prompt de interacción (24)** — depends on: 1, 7, 18.
2. **Menú de pausa (25)** — depends on: 1, 6, 18 (blanda: 5).
3. **Subtítulos (26)** — depends on: 6, 18, 23.
4. **Pantalla de título y cierre (27)** — depends on: 1, 3, 5, 6, 18.
5. **Atmósfera reactiva (28)** — depends on: 2, 3, 21.
6. **Shaders y efectos (29)** — depends on: 12, 15.

### Polish Layer (depends on everything)

1. **Opciones de accesibilidad (30)** — depends on: 1, 6, 13, 15, 23, 26.

**Bottlenecks (riesgo alto si cambian; el 3 ya tiene GDD):** 3 Estado y eventos · 9 Marco de puzles · 7 Interacción · 18 Contenido narrativo.
**Hojas (se pueden diseñar tarde):** 24, 26, 27, 29, 30.

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Estado y bus de eventos (3) | MVP | Foundation | systems-designer | M |
| 2 | Entrada y controles (1) | MVP | Foundation | ux-designer | S |
| 3 | Base de contenido narrativo (18) | MVP | Foundation | narrative-director, writer | M |
| 4 | Ajustes persistentes (6) | MVP | Core | systems-designer | S |
| 5 | Escena de planta (4) | MVP | Core | level-designer | M |
| 6 | Jugador en primera persona (2) | MVP | Core | game-designer | M |
| 7 | Guardado y carga (5) | MVP | Core | systems-designer | M |
| 8 | Interacción e inspección (7) | MVP | Feature | game-designer | M |
| 9 | Marco de puzles (9) | MVP | Feature | game-designer | M |
| 10 | Control de acceso (8) | MVP | Feature | level-designer | S |
| 11 | Documentos y bolsillo (20) | MVP | Feature | game-designer | S |
| 12 | Ordenador, correo e impresora (19) | MVP | Feature | ux-designer | M |
| 13 | Puzle 1 · Cronología (11) | MVP | Feature | game-designer | S |
| 14 | Caja y compartimentos (10) | MVP | Feature | game-designer | M |
| 15 | Puzle 3 · Encaje de la foto (13) | MVP | Feature | game-designer | S |
| 16 | Puzle 4 · Tablero de tareas (14) | MVP | Feature | game-designer | S |
| 17 | Puzle 5 · Espejo de la diferencia (15) | MVP | Feature | game-designer | S |
| 18 | Puzle 6 · Decisión (16) | MVP | Feature | game-designer | S |
| 19 | Puzle 2 · Memorando en el cristal (12) | MVP | Feature | game-designer | S |
| 20 | Director de escenas (21) | MVP | Feature | narrative-director | L |
| 21 | Llamada telefónica (22) | MVP | Feature | narrative-director | M |
| 22 | Prompt de interacción (24) | MVP | Presentation | ux-designer | S |
| 23 | Menú de pausa (25) | MVP | Presentation | ux-designer | S |
| 24 | Director de audio (23) | Vertical Slice | Core | audio-director | M |
| 25 | Sistema de pistas (17) | Vertical Slice | Feature | game-designer | M |
| 26 | Subtítulos (26) | Vertical Slice | Presentation | ux-designer | S |
| 27 | Pantalla de título y cierre (27) | Vertical Slice | Presentation | ux-designer | S |
| 28 | Atmósfera reactiva (28) | Vertical Slice | Presentation | art-director, technical-artist | M |
| 29 | Shaders y efectos (29) | Vertical Slice | Presentation | technical-artist | M |
| 30 | Opciones de accesibilidad (30) | Vertical Slice | Polish | accessibility-specialist | M |

Esfuerzo: S = 1 sesión, M = 2–3, L = 4+. El puzle 2 va después de la caja porque comparte el marco de puzles pero no la dependencia c1→c3→c4; se puede adelantar sin riesgo.

---

## Circular Dependencies

- **Dura en ambos sentidos, aceptada: 2 ↔ 4** (4 declara al 2 como dura y 2 declara al 4 como dura «en ambos sentidos»; 4 solo invoca `colocar`). Es de ejecución, no de construcción. **9 ↔ 10** y las demás, abajo.
- Acoplamiento blando mutuo 8 ↔ 21 por el bus: 8 emite «ascensor llamado» (21 ejecuta el trayecto) y 21 emite «ascensor rechazado» (8 devuelve `C08` a `LISTO`). Son avisos sin llamadas directas ni hechos compartidos; no es un ciclo duro. 8 → 20 es dura (la declara 8, el dependiente) y la interfaz `sostener_item`/`guardar_item`/`otorgar` la ofrece 20; 20 la repite como «Dura (de 8 hacia 20)». 20 no depende de 8: no hay ciclo.
- **9 ↔ 10 (dura, circular, aceptada; W-4 de r5):** 10 lee `caja_cn` y `get_view_gate` de 9; 9 llama a `play_open`/`set_final_pose` de 10. Es una dependencia de ejecución tras «escena lista», no de construcción ni de datos, así que no impide diseñar ni implementar ninguno primero (D9-62).
- 5 ↔ 9 (cerrada en la ronda de corrección 4): 9 depende de 5 (blanda, la declara 9) y 5 no depende de 9; igual que 8 y 10 con 5. 9 ↔ 20 es blanda en un solo sentido declarado por 9 (20 la repite). 19 ↔ 21 indirecta (vía 7; la declara 19 y 21 la repite; ni 19 consume API de 21 ni 21 depende de 19).
- **Patrón de delegación, sin ciclo:** 7 delega el manejador de `V02` en 22 como lo hace con 8, 10 y 20; 7 no depende de 22 (22 depende de 7: `V02`, `ANIM_PHONE_PICKUP`), así que 22 ↔ 7 **no** es circular. **1 ↔ 6:** 6 depende de 1 (contrato); 1 no depende de 6. **10 ↔ 20** (blanda mutua) y **10 ↔ 21** (indirecta): sin ciclo duro.
- Dos casos que habrían formado ciclo se resuelven con el bus de eventos (sistema 3), sin dependencias directas: director de escenas (21) ↔ llamada (22), y director de escenas (21) ↔ audio (23) / atmósfera (28).

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Puzle 2 · Memorando (12) y Shaders (29) | Technical | El texto en espejo revelado por lámparas debe leerse bien en el cristal | Prototipo temprano en Godot; versión provisional sin shader |
| Puzle 5 · Espejo (15) | Design | La rotación de 40° debe sentirse bien y la diferencia entenderse sin pista nivel 3 (criterio 5) | Tolerancia en datos; probar en el primer playtest |
| Llamada (22) | Design / Scope | 12 combinaciones de variante y respuesta; silencio sin elección automática | Tests de la máquina de estados; datos en JSON |
| Atmósfera reactiva (28) | Technical / Art | El low poly puede no transmitir atmósfera | Prueba de 30 segundos antes de modelar el resto (slice §22) |
| Guardado y carga (5) | Technical | Reanudar en mitad de la llamada o de la revelación del puzle 5 | Tests de reanudación en cada punto de D.3 |
| Director de escenas (21) | Scope | Mayor volumen de eventos temporizados (Anexo C) | Definir primero el formato de datos de eventos (ADR) |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 30 |
| Design docs started | 15 (22 revisado en la ronda de corrección 1) |
| Design docs reviewed | 9 (1 a 7, 9 y 18: ronda 2 aplicada el 2026-11-09 tras sus re-reviews, `design/gdd/reviews/*-re-review.md`; pendientes de re-review) |
| Design docs approved | 0 |
| MVP systems designed | 14/23 |
| Vertical Slice systems designed | 0/7 |

---

## Review Notes

- TD-SYSTEM-BOUNDARY y PR-SCOPE: omitidos (modo `lean`). PR-SCOPE habría quedado además «NOT ASSESSED» por falta de tamaño de equipo y fecha de demo, que siguen sin definirse.
- CD-SYSTEMS: omitido (modo `lean`).

---

## Next Steps

- [ ] Revisar y aprobar esta enumeración
- [ ] Diseñar los sistemas MVP primero (`/design-system [sistema]`), empezando por Estado y bus de eventos
- [ ] Ejecutar `/design-review` sobre cada GDD completado
- [ ] Ejecutar `/gate-check technical-setup` cuando los sistemas MVP estén diseñados
- [ ] Validar los sistemas de mayor riesgo con prototipos antes de comprometer Producción

---

## Notas pendientes del lote 2026-11-09 (GDDs 2, 5, 7, 9)

Cambios que los informes de revisión piden a sistemas **sin GDD todavía**; cada uno debe recogerlos al redactarse:

- **20 Documentos:** operación `has_item(item_id)` (informe de 9); sostiene `A03` y las tarjetas con `sostener` (informe de 7).
- **22 Llamada:** restricción de emisión de `llamada_iniciada` («antes de cualquier elemento no reconstruible y como máximo al descolgar») y nota de reinterpretación de D.2 (informe de 5); registrar manejadores con `can_interact`/`interact`/`etiqueta` (informe de 7).
- **27 Pantalla de título:** consulta el resultado de la **última** inspección (con `con_futura`); muestra el aviso de versión más nueva con partida cargable; **no pide `planta`** (lo hace 5); tras completar el slice ofrece solo «Nueva partida» (decidido por el usuario; Open Question 10 de Guardado cerrada).
- **8, 10, 19:** registrar manejadores con `can_interact`/`interact`/`etiqueta`; 10 llama a `abrir_vista` tras animar el compartimento y responde `SIN_EFECTO` según `get_view_gate`.
- **Revisión pendiente (re-review) de los vecinos tocados:** 1, 3, 4, 6 y 18 (cambian reglas; sus estados no se han modificado).


---

## Notas pendientes de la ronda 2 (2026-11-09): qué debe recoger cada sistema sin GDD

Consolidado de `design/gdd/reviews/*-re-review.md`. No se han creado GDDs; cada uno debe recoger esto al redactarse.

- **8 Control de acceso:** emite «puerta abierta»; reconstruye las puertas B y D **cerradas** al reanudar (solo `tarjeta_B/D` se guardan; la tarjeta se vuelve a usar sin penalización); manejadores `can_interact`/`interact`/`etiqueta`; lista al 3 como dependencia.
- **10 Caja y compartimentos:** `interact()` de `D01a`-`D01d` llama a `bloquear_contexto("D01x")` (token), anima su compartimento con `BOX_C1_OPEN`…`BOX_C4_OPEN` (`BOX_Cn_OPEN` queda sustituida por esas y `BOX_OPEN_MAX`, dueño 10; tope 1,6 s) y llama a `abrir_vista(id, desde_token)`; libera el token si no se abre la vista; peor caso 2,6 s ininterrumpidos; consulta `get_view_gate(view_id)` del marco antes de abrir y responde `SIN_EFECTO` también con el puzle resuelto.
- **19 Ordenador/correo/impresora:** receptor de `V01` con `ViewReceiver` (recibe `on_close(sistema)` al cerrar el director); respeta la regla 20 de Entrada (campo enfocado consume texto, `Retroceso` no cierra, `Esc` = pausa); imprime en `V08` de forma repetible e ilimitada, e `I-01` no se conserva entre sesiones (`has_item('I-01')` falso tras cargar); 6 correos con orden de presentación 3, X1, 1, 4, X2, 2 (X1/X2 solo en datos).
- **20 Documentos y bolsillo:** `has_item(item_id)`; sostiene `A03` y las tarjetas como ítems (`sostener`); `abrir_lectura` para releer desde el bolsillo, manejando `APLAZADA`/`RECHAZADA`; `I-01` no persistente.
- **21 Director de escenas:** lee `llamada_iniciada` (reanudación `caja_completa ∧ ¬llamada_iniciada`); `cerrar_modos()` incluye `ordenador`, no `llamada`, y espera «modos cerrados» antes de `sin control`; toma el `sin control` en el mismo fotograma de «terminada» con `control_final` = `ninguno` y decide qué responde el ascensor (`door_slot_elevator`); confirma o retira la lectura de `memo_leido`; devuelve `exploración` tras una carga solo si abrió el `sin control` (Entrada acepta a quien lo abrió).
- **22 Llamada:** escribe `llamada_iniciada` inmediatamente antes de emitir «llamada iniciada» (como máximo al descolgar); la llamada se repite hasta completada y guardada (decisión del usuario; el hecho solo marca el sellado); solo emite «llamada iniciada»/«llamada completada»; el único emisor de «partida terminada» es 4 (3 regla 10, 4 regla 16, 5 regla 29); lista al 3 con los nombres de la tabla.
- **23 Director de audio:** emite «línea terminada»/«línea sin audio»/«línea fallida»; consume los volúmenes por pasos de Ajustes; lista al 3 y al 2 (blanda).
- **24 Prompt:** muestra `atrás` sin `Retroceso`.
- **25 Menú de pausa:** emite `pause_opened`; pantalla de reasignación (sin los gestos derivados `leer`/`agarrar`/`rotar`/`mantener`; aviso al asignar `atrás` a una tecla imprimible; rechazo de dejar `atrás` solo con una tecla imprimible); «Mando desconectado» con «continuar»; ofrece `reducir_movimiento`; las pistas no se colocan en ajustes; lista al 5 (blanda).
- **26, 28:** listan al 3 con los avisos que consumen.
- **27 Pantalla de título:** consulta `terminada` (con ella solo «Nueva partida», sin confirmación) y `con_futura`; `nueva_partida()` entra en «Cargando partida» y 27 no pide `planta`; muestra el fallo de carga.
- **30 Accesibilidad:** ofrece `reducir_movimiento` como conmutador (el sistema 6 ya lo tiene en su catálogo).
- **11 a 16 Puzles:** declaran `gestos_aceptados` por elemento y su tolerancia en px (P5 acepta `rotar` y funciona con «alternar en lugar de mantener»); datos de pista con las 8 claves `PISTA_*`.
- **Preguntas abiertas para el usuario** (el GDD 9 sigue la recomendación): D9-34 (icono en compartimentos bloqueados), D9-35 / D-16 (orden de la caja) y D7-32 (la carta del P6 se abre igualmente si el jugador salió antes).

---

## Notas pendientes de D-B1 (2026-11-09): puzle 4 con T4 de doble salida

Decisión del usuario: T4 «Carta a Dirección» acepta devolver o asignar; la elección queda en el hecho nuevo `t4_decision` (`returned`/`assigned`; 20 hechos). Cada sistema sin GDD debe recoger esto al redactarse:

- **22 Llamada:** lee `t4_decision` para la variación de `VO_G_14` (propuesta en el GDD 18, pendiente de narrative-director/usuario; clave provisional `VO_G_14_ASG`, `VO_G_14` queda como línea de `returned`). Si el director de escenas (21) reproduce esa línea, el lector es 21; confirmar en su GDD.
- **21 Director de escenas:** ~~lector alternativo de `t4_decision`~~ **resuelto en el GDD 21 (DT-6): no lo lee; lo lee 22.**
- **14 Puzle 4 (GDD aún sin redactar):** T4 de doble salida (regla 12c del GDD 9); sin «No corresponde» en T4; la pista de nivel 3 no la toca.
- **Slice:** B.4, §10.4 y D.2 (20 hechos) autorizados y aplicados en el slice v0.3.2.

---

## Notas de la propagación del lote Feature 1 (2026-11-09): GDDs 8, 10, 19, 20, 21

Propagados a 3, al registro y a este índice los «Cambios requeridos» de los cinco GDD. **Quedan sin propagar** (los edita otro agente o dependen de una decisión):

- **Decididas por el usuario (2026-11-09, slice v0.4):** `atrás` en `exploración` = `repasar_bolsillo` (un documento por pulsación, sin menú; 1, 7, 20, 24); `I-05`/`I-06a` releíbles desde el bolsillo sin presentación nueva (9, 10, 18, 20); B.1 literal del P1 (hoja con `Enviado: hh:mm` y pie «Ordena por hora de envío»); `MEGA_03` como línea 28 del §12 (28 entradas, 21 audibles; 8, 18, 21); zonas `T-D-OUT` y `T-OFI-IN` en el Anexo A.3 (4, 21; coordenadas † hasta el nivel).
- **Preguntas de alcance pendientes de decisión del usuario:** `escala_texto_ui` (PA-3 de 19; 6); si `reducir_movimiento` acorta las animaciones de la caja (pregunta 5 de 10; 6, 10); 4 o 6 resultados de búsqueda y correos de ruido `MAIL_X1`/`MAIL_X2` (PA-4 y PA-8 de 19); `I-01` relegible fuera de `C05` (PA-9 de 19); «Ahora no» como mensaje del teléfono (PA-9 de 21); `D01d` sin cadena (7, regla 19). Hasta decidirse, sus valores en el registro son PROPUESTA (†/‡).
- **GDD 22 (Llamada), escrito y revisado (ronda de corrección 1):** describe que 21 pone `V02` en `vibrando` y 22 en `en_llamada`, que «Descolgar» solo vale en `vibrando`, que 22 inicia la llamada y escribe `llamada_iniciada`/`respuesta_llamada`/`llamada_completada`, que 8 lee `llamada_completada` (activa `C08` a +2,0 s) y que 22 es el único lector de `t4_decision`. Lista a 8 y 21 como lectores (esta nota queda como histórico).
- **Dependencia 9 → 19 (dura):** 9 llama a `compose_i01()` de 19 (R30 de 19); la fila 9 ya la recoge (ronda de corrección 2). 9 no lee `correos_leidos`.
- **Estado de 21 en su lista de cambios:** pedía «Borrador»; el GDD ya está en ronda de corrección 1 y así figura arriba.
- **Futuros:** 23 Audio (`SFX_CARD_OK`, `SFX_DOOR_SWING`, `SFX_DRAWER_OPEN`, `SPK_D01C`, `SFX_BOX_WOOD_*`, `MEGA_03` por `C01`), 24 Prompt (pie `UI_BOLSILLO_AYUDA`), 17 Pistas (`V08` como `targets_if_missing_items`, `formulario_leido`), 28 Atmósfera.
- **UX:** pendiente `design/ux/ordenador-correo.md` (pantalla de 19, vía `/ux-design`).
- **Re-review pendiente:** 3, 8, 10, 19, 20 y 21; además de los vecinos tocados por otros agentes.

## Notas de la ronda de corrección 3 (2026-11-09): dureza de dependencias y nombres

- **Regla común (R6-1):** la dureza (dura / blanda / indirecta) la declara el GDD **dependiente** y el proveedor repite la misma; si discrepan, manda el dependiente salvo texto obsoleto. Reconstruidas con ese criterio las filas 1, 4, 5, 8, 9, 10, 19, 20 y 21 (tabla y mapa); 6 y 18 alineados con sus dependientes.
- **Nombres (R6-2):** la acción derivada es `repasar_bolsillo`; `BOX_Cn_OPEN` queda sustituida por `BOX_C1_OPEN`…`BOX_C4_OPEN` y `BOX_OPEN_MAX` (dueño 10).
- **(Resueltas en la ronda de corrección 4, ver más abajo)** Discrepancias de dureza que quedaban en GDD ajenos a esta ronda (los edita otro agente): 9 → 20 y 9 → 21 figuran como «Indirecta» en 9, pero 20 declara a 9 «Blanda» y 21 «Sin dependencia» (manda el dependiente); 10 → 1: 1 dice «Dura (indirecta)» y 10 «Indirecta»; 20 → 4: 4 dice «Dura vía contenedores e IDs», 20 «Indirecta» (se deja Indirecta); 20 → 8: ver Circular Dependencies; 19 ↔ 21 (19 la declara blanda sin camino en el slice, 21 no depende de 19); 10 → 21 (10 la declara blanda, 21 no lista a 10) y 5 ↔ 9 (9 lista a 5 como dependiente, 5 lista a 9 como dependiente: dirección sin cerrar); la fila 7 no lista a 6 (7 lo declara blanda).
- 17 y 24 pasan de «dependencias» de 20 a «dependen de 20» (20 les da `formulario_leido` y el pie `UI_BOLSILLO_AYUDA`); sus filas se completarán al redactarse.

## Notas de la ronda de corrección 4 (2026-11-09): cierre de durezas y reciprocidad

Resuelve R6-1 (`gdd-cross-review-2026-11-09-r6.md`) y D1–D11 de `reviews/cross-review-r6-2.md` con la regla común (la dureza la declara el GDD dependiente y el proveedor repite la misma; si discrepan, manda el dependiente salvo texto obsoleto). Pares resueltos: 9↔20 Blanda (declara 9, 20 repite); 9↔21 Indirecta (declara 21, 9 repite); 5↔9 Blanda con 9 como dependiente (declara 9); 5↔20 Indirecta (declara 20); 4↔20 Dura (declara 20, 4 repite); 8↔20 Dura (declara 8, 20 repite); 1↔10 Indirecta (declara 10, 1 repite); 10↔21 y 10↔2 Indirecta (declara 10); 19↔21 Indirecta vía 7 (declara 19; 21 no depende de 19); 7↔6 Blanda (declara 7); 6↔18 Blanda (declara 6, 18 repite); 9↔10 Dura circular (ambos). Filas reconstruidas: 7, 9, 10, 20, 21 y 22 (nueva: Borrador del lote Feature 2).

## Notas de la ronda de corrección 5 (2026-11-09): GDD 22 y reciprocidad de dependencias

Aplica `reviews/dependencias-r7-review.md` (A1–A12) y `reviews/feature-batch-2-resumen.md`. **Fila 22:** dependencias reales (duras 1, 3, 5, 7, 18; blanda 2; la dureza la declara 22, el dependiente; la cita anterior «duras 3, 5, 7, 18 · blandas 1, 2 (provisional)» era falsa), estado «Revisado (ronda de corrección 1) — pendiente de re-review». **Fila 21:** añade 10 (indirecta). **Fila 20:** 9 pasa a dependiente de 20 (lo declara 9; 20 no depende de 9) y 21 también (indirecta, la declara 21). **Fila 2:** dependientes 9 y 10. **Fila 6:** 6 → 1 por contrato; 1 no depende de 6. **22 ↔ 7:** patrón de delegación, no circular. 9 ↔ 10 y 2 ↔ 4 siguen declaradas como circulares. **Decisiones del usuario (2026-11-09):** la fila «+4,0» de C.7 es la línea a 4,8 s (slice v0.4.2; 9, F9 y D9-66); la respuesta de la llamada es definitiva y la llamada repetible se repite idéntica al cargar.

## Notas de la ronda de corrección 6 (2026-11-09): dureza común 8/21/22 y estados

Aplica los últimos avisos de `reviews/` (22 y dependencias). **Regla común:** la dureza la declara el GDD dependiente y el proveedor la repite. **Fila 22:** indirectas 8, 9 y 21 (vía 3); 23 y 26 no se listan (contrato ‡ sin GDD). **Fila 8:** 22 pasa a Indirecta (vía 3). **Fila 21:** 22 pasa a Indirecta (vía 3). **Fila 6:** 1 es Blanda (no «dura de contrato»). **Fila 9:** relación Indirecta de 22 añadida. Filas 2, 5, 21 y 22: estado «Revisado (ronda de corrección 6) — pendiente de re-review» (cambios: D-44 en 2, D-53 en 5, DT-29 en 21, D22-30 en 22). `repasar_bolsillo` unificado como identificador.
