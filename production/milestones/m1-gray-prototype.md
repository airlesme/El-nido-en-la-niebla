# Hito: M1 · Prototipo gris (escenas 1–3)

> Línea base creada el 2026-11-11 (PR-PHASE-GATE C12). Plantilla:
> `.claude/docs/templates/milestone-definition.md`. Equipo: una persona con agentes;
> sin fecha de demo. Fuentes: `docs/PLAN-TECNICO.md` § 4 (fila M1) y
> `design/slice/slice-v0.3.md` §§ 10.1, 11 (escenas 1–3), 23.1, Anexos A.2–A.4, B.1, C.1–C.3, D.2.

## Overview

- **Fecha objetivo**: ninguna fija. Plazo relativo: tras S0 (y en paralelo o tras S0b).
- **Tipo**: Prototype (vertical, sin texturas)
- **Duración**: 2–4 semanas (esperado 3). **Confianza: baja.**
- **Sprints**: 2 (de ~1,5 semanas; sin velocidad medida)
- **Estado**: **En curso** — S0 cerrado; ADR 0001, 0002, 0003, 0005, 0006, 0009, 0010, 0011, 0012 y 0017 `Accepted`; faltan historias y sprint.

## Objetivo del hito

**Se juega de la escena 1 a la 3 sin texturas** (PLAN-TECNICO § 4): llegada al despacho de
Vera, mensaje del Guardián, búsqueda «transición» en el ordenador, impresión, pasillo,
puzle 1 (Cronología) en el panel de la puerta A y Archivo con el formulario y las dos
tarjetas. Es la primera prueba de que la cadena *entrada → interacción → estado → puzle →
puerta* funciona sobre la arquitectura aceptada, con el invariante «ningún fallo es terminal».

## Alcance

**Espacios (geometría gris):** despacho de Vera (A.2), pasillo (A.3, el de S0b si existe), Archivo (A.4).
**Escena 1 (C.1):** fundido, ventilador, `VO_V_01`, `MEGA_01`, vibración de V02 y mensaje «¿Jugamos esta noche?» → «Ahora no» → «Este número ya no está disponible». Audio provisional.
**Escena 2 (C.2):** ordenador con búsqueda «transición» (resultados a 0,4 s, orden visual 3, 1, 4, 2 con dos distractores), `correos_leidos`, impresora V08.
**Escena 3 (C.3):** puzle 1 (4 huecos, solución `2 · 1 · 3 · 4`, fallo: vibran y vuelven a la impresión tras 1,5 s, sin penalización) → `archivo_abierto` → `ANIM_DOOR_OPEN` 1,2 s → A03, A04 (`formulario_leido`), A05 (I-02, I-03 → `tarjeta_B`, `tarjeta_D`), `VO_V_04`, lluvia que se intensifica.
**Flags de D.2 que entran:** `correos_leidos`, `archivo_abierto`, `formulario_leido`, `tarjeta_B`, `tarjeta_D` (5 de 20).
**Sistemas (n.º de GDD):** 1 entrada, 2 jugador, 3 estado/bus, 4 escena de planta, 7 interacción, 8 acceso (solo puerta A y cajón A05), 9 marco de puzles, 11 puzle 1, 18 contenido narrativo, 19 ordenador/impresora, 20 documentos y bolsillo, 21 director de escenas (escenas 1–3), 24 prompt; recortables: 5 guardado, 17 pistas, 25 pausa, 26 subtítulos, 23 audio (provisional), 6 ajustes.
**Fuera:** salas B y D, caja y puzles 2–6, apagón, llamada, Recepción, título, arte final, VO final, ADR-0015.

## Criterios de salida (todos medibles)

- [ ] **C-M1-1** Partida nueva → escena 3 completa (cajón A05 abierto, `tarjeta_B` y `tarjeta_D` en verdadero) sin consola de depuración, en un export `playtest-windows` **y** `playtest-linux`.
- [ ] **C-M1-2** Puzle 1: tests gdUnit4 en verde de solución válida, inválidas y «sin softlock»; el oráculo de secuencias con `GameClock` falso (TR-puzzle1-018) si ADR-0018 ya tiene su soporte, si no NOT ASSESSED anotado.
- [ ] **C-M1-3** Ningún estado alcanzable impide terminar la escena 3 (comprobado por test de estado y por un recorrido manual de fallo repetido ×5 en P1).
- [ ] **C-M1-4** Los 5 flags se escriben solo por su dueño (contrato de ADR-0001) y aparecen en el test de estado.
- [ ] **C-M1-5** Tiempos de C.1 y C.3 dentro de ±1 fotograma del dato (test de timeline con reloj falso, ADR-0017).
- [ ] **C-M1-6** Mando y teclado completan el recorrido (sesión manual registrada).
- [ ] **C-M1-7** Capturas retenidas en `production/qa/evidence/` de cada pantalla/vista tocada: despacho, ordenador, impresión, panel P1, Archivo, prompt de interacción.
- [ ] **C-M1-8** Tiempo del recorrido escena 1→3 cronometrado por el desarrollador (**dato informativo**, no criterio del slice; el criterio 1 se mide en M5).
- [ ] **C-M1-9** CI verde; 0 S1 abiertos; 0 errores en consola durante el recorrido.
- [ ] **C-M1-10** Rendimiento: una carrera informativa del recorrido en `REF-1` archivada (sin veredicto vinculante: B1 se juzga en P3/M4). Si S0b dejó un escalón de recorte, se aplica aquí.

## Lista de funcionalidades

### Imprescindible (el hito falla sin esto)

| Elemento | Doc | Dueño | Estado |
|---|---|---|---|
| Jugador 1P sin manos (cámara, movimiento, FOV 70°, ojos 1,62 m) | GDD 2, ADR-0012 | gameplay-programmer | Pendiente |
| Entrada con contextos (teclado + mando) | GDD 1, ADR-0006 | gameplay-programmer | Pendiente |
| Estado + bus, 5 flags | GDD 3, ADR-0001 | lead-programmer | Pendiente |
| Carga de planta (despacho, pasillo, Archivo) | GDD 4, ADR-0003 | gameplay-programmer | Pendiente |
| Interacción: foco, prompt, lectura por pulsación larga | GDD 7, 24, ADR-0011 | gameplay-programmer | Pendiente |
| Datos JSON validados (líneas, flags, puzle P1) | GDD 18, ADR-0005 | lead-programmer | Pendiente |
| Ordenador (búsqueda) + impresora | GDD 19 | ui-programmer | Pendiente |
| Marco de puzles + P1 | GDD 9, 11, ADR-0010 | gameplay-programmer | Pendiente |
| Puerta A + cajón A05 | GDD 8 | gameplay-programmer | Pendiente |
| Documentos y bolsillo (A04, I-02, I-03) | GDD 20 | gameplay-programmer | Pendiente |
| Director de escenas 1–3 (versión mínima) | GDD 21, ADR-0017 | gameplay-programmer | Pendiente |

### Recortable (en orden de recorte, ver abajo)

| Elemento | Doc | Impacto del recorte | Pasa a |
|---|---|---|---|
| Manos (rig, `ANIM_*`) | GDD 2, ADR-0013 | Inspección sin manos visibles | M2 / M4 |
| Pistas de P1 (3 niveles) | GDD 17 | Criterio 2 del slice sin probar en P1 | M2 |
| Subtítulos de las líneas de escenas 1–3 | GDD 26, ADR-0016 | Criterio 8 se prueba más tarde | M3 |
| Guardado automático al abrir la puerta A | GDD 5, ADR-0004 | Sin reanudación en M1 | M2 |
| Menú de pausa | GDD 25 | Pausa solo con atajo dev | M2 |
| Inspección con rotación en mano | GDD 7 | Solo lectura | M2 |
| Audio direccional/capas de lluvia por zona | GDD 23, ADR-0008 | Audio plano provisional | M3 |
| Ajustes persistentes | GDD 6, ADR-0007 | Valores por defecto en código de datos | M2 |

### Extra (solo si se va por delante)

| Elemento | Valor |
|---|---|
| Distractores del correo con texto final | Textura narrativa |
| Lluvia que se intensifica al leer la fecha (C.3) con la atmósfera real de S0b | Tono |

## Orden de recorte acordado para M1 (qué se corta primero)

Se aplica **antes** de mover el plazo. Un recorte cada vez; se anota en § Registro de cambios.

1. **Manos** (ADR-0013 y su spike D-28 pasan a M4).
2. **Pistas de P1** → M2.
3. **Subtítulos** → M3 (la regla «toda línea con subtítulo» se recupera antes de M4, no se abandona).
4. **Guardado** → M2 (ADR-0004 y S-0004 se mueven con él).
5. **Menú de pausa** → M2.
6. **Rotación en inspección** → M2.
7. **Ajustes persistentes y audio por zonas** → M2/M3.
8. **Escena 1 simplificada**: el mensaje del Guardián como secuencia fija sin elección (C.1 a 14 s) — último recurso, porque toca el tono.

**No se recorta nunca en M1:** P1 completo con su fallo no terminal, búsqueda «transición» + impresión (son la entrada de P1), puerta A, los 5 flags, tests de lógica de P1, recorrido con mando y teclado.

## ADR y spikes que cierra (de los 19, todos `Proposed` hoy)

| ADR | Qué exige | En M1 |
|---|---|---|
| 0003 Scene loading | Spikes S-0003-A, -B (C compartido con 0005) | Imprescindible |
| 0005 Data schema | Spike S-0005-A (parser JSON 4.7); C5; enmienda O1 de ADR-0018 (hot reload a `src/dev/`) | Imprescindible |
| 0006 Input | Spikes S-0006-A…F; C1 (si quedó diferida de S0); rec. 24 | Imprescindible |
| 0010 Puzzle framework | Sin spike; C4, C5, C6 | Imprescindible |
| 0011 Interaction | Spikes S-0011-A, -B, -C (`intersect_shape` con Jolt); C4; R31 | Imprescindible |
| 0012 Player/camera | Spikes S-0012-A…F (interpolación a 30/60/144 fps); R29 | Imprescindible |
| 0017 Scene director | Sin spike; C3 (enmienda en 0008) | Imprescindible (versión mínima) |
| 0007 Settings/a11y/UI scaling | Spikes SP-1…SP-6; rec. 23, 25 | Parcial: escalado de UI del prompt/ordenador; resto con el recorte 7 |
| 0008 Audio | `stream_paused`, limitador, arranque sin dispositivo; C2, C3 | Parcial (audio provisional) |
| 0016 Subtitles/UI text | Spike corto con 0007; R30 | Solo si no se recorta (3) |
| 0004 Save | S-0004 en Windows y Linux; AC-42 del GDD 5 | Solo si no se recorta (4) |
| 0013 Hands/blackout | Spike D-28 | Solo si no se recorta (1) |

No le conciernen: 0001, 0002, 0009, 0018 (cerrados en S0), 0014, 0019 (S0b), 0015 (M2/M4).
**Regla:** una historia que cite un ADR aún `Proposed` queda bloqueada; el spike del ADR va **delante** de su historia en el sprint.

## Cola de diseño pendiente que le afecta (contada, no resuelta)

`adr-reconciliation-2026-11-10.md`:
- **Ronda 1 (§ 2): 11** — G5 (`control_final`, 0003), G14 (rutas de datos y claves, 0005), G15, G16 (entrada, 0006), G18 **[U]** QQ-10 (suelo de 24 px), G19, G21 (ajustes, 0007), A3, A4, A6, A8 (`architecture.md` / registro).
- **Ronda 2 (R2.2): 16** — H1–H5 (marco de puzles y P1, 0010), H6, H7, H9 (interacción, 0011), H10, H11, H12 (jugador/manos, 0012), H20 (claves de texto, 0016/0017), H21 (overlay del ordenador), H23 (`TELEFONO_*` sobre V02, escena 1), H24 (director: estados de objeto), H28 (= G16).
- Total M1: **27** cambios. Estado de aplicación: NOT VERIFIED (no se abrieron los GDD).

Decisiones del usuario de `gdd-cross-review-2026-11-10-r2.md`: **2** de 6 le afectan directamente (n.º 3 `reducir_movimiento`/`escala_texto_ui`; n.º 4 filtro de «interacción ejecutada», con la opción por defecto ya aplicada) y **2 más condicionadas** a no recortar (n.º 1 espera de pistas si entran las pistas de P1; n.º 5 suelo de subtítulos a 720p si entran subtítulos).
Del slice § 20: **D-04** (nombre de Vera: megafonía y formulario) toca M1, sin bloquear porque se lee de datos.

## Puertas de calidad

| Puerta | Umbral | Método |
|---|---|---|
| Lógica | 100 % de tests de P1, estado y timeline en verde | gdUnit4 en CI |
| Softlock | 0 estados terminales | Test de estado + recorrido de fallo |
| Bugs | 0 S1 abiertos; S2 listados con dueño | registro de bugs |
| Visual/UI | Captura retenida por vista tocada | `production/qa/evidence/` |
| Rendimiento | Informativo (NOT VERIFIED hasta P3 en M4) | Carrera en `REF-1` |

## Riesgos

| Riesgo | Prob. | Impacto | Mitigación | Dueño |
|---|---|---|---|---|
| R-M1-1 **Siete spikes de motor** (0003, 0005, 0006, 0011, 0012 y parciales de 0007/0008) caen en M1 antes de poder cerrar historias | Alta | Alto (plazo) | Spikes en la semana 1, en el orden topológico de la review; recorte 1–7 | technical-director |
| R-M1-2 PLAN y slice § 23 dan **1 semana** a M1; esta línea base estima 2–4 por los spikes y la aceptación de ADR | Alta | Medio | Plazo realista aquí; ver README § Desviación | producer |
| R-M1-3 Cola de diseño (27 cambios) sin aplicar a los GDD cuando se escriban las historias | Media | Medio | Pasada de aplicación de la cola antes de `/create-stories` de M1 | game-designer |
| R-M1-4 NS-7/C1: bus y entrada desfasados un fotograma (`sin control`) | Media | Medio | Spike S-0006; aceptar 0006 solo con el resultado | engine-programmer |
| R-M1-5 Jolt + `intersect_shape` para el foco no se comporta como el ADR supone | Media | Medio | S-0011-C temprano; fallback de raycast simple (PLAN § 2.2) | gameplay-programmer |
| R-M1-6 Una sola persona: cualquier bloqueo detiene todo | Alta | Alto | Holgura en el pesimista; orden de recorte; nada en paralelo que dependa de otra cosa abierta | producer |

## Plazo

| Escenario | Semanas | Supuesto |
|---|---|---|
| Optimista | 2 | Los spikes pasan con el diseño del ADR; recortes 1–2 aplicados |
| Esperado | 3 | Uno o dos spikes obligan a enmendar un ADR; recortes 1–4 |
| Pesimista | 4 | Varios spikes con fallback; se llega al recorte 7 |

**Confianza baja:** sin historia de sprints ni velocidad; ~10 ADR con spike o enmienda pendientes; la estimación es de un juicio, no de una medida. Si a la mitad del esperado (≈ 1,5 semanas) no se juega la escena 2, se aplica el siguiente recorte y se avisa al usuario.

## Dependencias

| Depende de | Estado | Si se retrasa |
|---|---|---|
| S0 cerrado (0001/0002/0009 `Accepted`, export que funciona) | Pendiente | M1 no empieza |
| S0b (escalón de recorte, pasillo) | Pendiente | M1 sigue en gris; el pasillo se rehace sin atmósfera |
| Cola de diseño de M1 aplicada a GDDs | Pendiente | Historias con contratos viejos |
| `/create-epics` + `/create-stories` + `/sprint-plan` para M1 | No iniciado | Sin historias no hay ejecución trazable |

## Registro de cambios

| Fecha | Cambio | Motivo |
|---|---|---|
| 2026-11-11 | Línea base | PR-PHASE-GATE C12 |
| 2026-11-11 | ADR 0005, 0006, 0010 y 0017 `Accepted` (spikes de datos y entrada automatizados; mando físico diferido). Desbloquea 7 épicos | Segundo tramo de M1 |
| 2026-11-11 | ADR 0003, 0011 y 0012 `Accepted` tras sus spikes de física (suite 71/71); partes con ventana diferidas al prototipo jugable. Cola de diseño aplicada (lotes A, B, C; pendientes H3, H8, H9, H10, H12) | Primer tramo de M1 |
| 2026-11-11 | Sprint 1 planificado (`production/sprints/sprint-001.md`): 10 días nominales, capacidad desconocida; Must 7 historias / 8 d (estado + datos hasta lecturas de hechos), cola de tirada 8 historias / 9,5 d (escritor de hechos, entrada hasta `GameClock`). Riesgo R-S1-1: backlog ≈ 130 d-p frente a ≈ 15 planificados; rebaselinar tras el Sprint 1 | Medir velocidad |
| 2026-11-11 | Sprint 2 planificado (`production/sprints/sprint-002.md`), inicio 2026-11-11, fin por registrar: ruta crítica solo Logic, 18 historias (Must 13 · Should 5) en 5 olas paralelas + ola 0 de deuda; capacidad en historias verificadas (Sprint 1: 10, mediana ≈ 12 turnos). Riesgo R-S2-7: CP-001 e IP-005 (Integration) cortan la lógica de carga e interacción y abren el Sprint 3 | Decisión del usuario: Sprint 2 = ruta crítica |
