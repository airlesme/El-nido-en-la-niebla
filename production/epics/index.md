# Epics Index

Last Updated: 2026-11-11
Engine: Godot 4.7.2 (pin `4.7.2.stable.official.ed1daf0bf`)
Ámbito: hito **M1 · Prototipo gris (escenas 1–3)** — `production/milestones/m1-gray-prototype.md`
Control manifest: `docs/architecture/control-manifest.md` **Manifest Version 2026-11-11** (ver aviso A1)
Generado por: `/create-epics` en modo `automation: autonomous` (decisiones registradas abajo, sin preguntas)

Estado de los ADR comprobado con Grep sobre `## Status` el 2026-11-11:
**Accepted** 0001, 0002, 0003, 0009, 0011, 0012 · **Proposed** 0004–0008, 0010, 0013–0019.

## Épicos de M1 (11, uno por módulo de `architecture.md` § Module Ownership)

«Libres» = TR cuya fila no cita ningún ADR `Proposed` (se pueden escribir historias hoy).
«Cubiertos» = TR con al menos un ADR `Accepted` (criterio de la skill).

| Epic | Layer | System (GDD n.º) | GDD | Stories | Status | TR cubiertos / libres / total | Bloqueado por |
|------|-------|------------------|-----|---------|--------|------|------|
| [estado-y-bus](estado-y-bus/EPIC.md) | Foundation | 3 Estado y bus | `estado-y-bus-de-eventos.md` | Not yet created | **Ready** (5 TR esperan a 0004/0005) | 18 / 13 / 18 | — |
| [entrada-y-controles](entrada-y-controles/EPIC.md) | Foundation | 1 Entrada | `entrada-y-controles.md` | Not yet created | **BLOQUEADO** | 5 / 0 / 19 | ADR-0006 |
| [contenido-y-datos](contenido-y-datos/EPIC.md) | Foundation | 18 Contenido narrativo + esquema de datos | `base-de-contenido-narrativo.md` | Not yet created | **BLOQUEADO** | 0 / 0 / 17 | ADR-0005 |
| [jugador-primera-persona](jugador-primera-persona/EPIC.md) | Core | 2 Jugador | `jugador-en-primera-persona.md` | Not yet created | **Ready** (manos fuera; 2 TR esperan a 0005) | 21 / 15 / 21 | — |
| [carga-de-planta](carga-de-planta/EPIC.md) | Core | 4 Escena de planta | `escena-de-planta.md` | Not yet created | **Ready** (2 TR esperan a 0005/0008) | 23 / 21 / 23 | — |
| [interaccion-y-prompt](interaccion-y-prompt/EPIC.md) | Feature + Presentation | 7 Interacción, 24 Prompt | `interaccion-e-inspeccion.md`, `prompt-de-interaccion.md` | Not yet created | **Parcial**: 7 Ready · 24 BLOQUEADO | 24 / 22 / 42 | ADR-0016 (prompt) |
| [documentos-y-bolsillo](documentos-y-bolsillo/EPIC.md) | Feature | 20 Bolsillo | `documentos-y-bolsillo.md` | Not yet created | **BLOQUEADO (parcial)**: 4/18 libres | 16 / 4 / 18 | ADR-0005 |
| [ordenador-e-impresora](ordenador-e-impresora/EPIC.md) | Feature | 19 Ordenador/correo/impresora | `ordenador-correo-impresora.md` | Not yet created | **BLOQUEADO** | 2 / 2 / 22 | ADR-0006, ADR-0005 (+0007 en 2 TR) |
| [puzles-marco-y-p1](puzles-marco-y-p1/EPIC.md) | Feature | 9 Marco de puzles, 11 Puzle 1 | `marco-de-puzles.md`, `puzle-1-cronologia.md` | Not yet created | **BLOQUEADO** | 11 / 0 / 40 | ADR-0010 (+0005) |
| [acceso-puerta-a-cajon-a05](acceso-puerta-a-cajon-a05/EPIC.md) | Feature | 8 Acceso (solo puerta A y `A05`) | `control-de-acceso.md` | Not yet created | **BLOQUEADO (parcial)**: 3/18 libres | 16 / 3 / 18 | ADR-0005 |
| [director-escenas-1-3](director-escenas-1-3/EPIC.md) | Feature | 21 Director (escenas 1–3, versión mínima) | `director-de-escenas.md` | Not yet created | **BLOQUEADO** | 10 / 1 / 27 | ADR-0017 (+0005, 0008) |

**Resumen:** 4 épicos con trabajo escribible hoy (estado-y-bus, jugador, carga-de-planta, la mitad
«interacción» de interaccion-y-prompt); 7 bloqueados total o mayoritariamente por ADR `Proposed`.

## Qué desbloquea cada épico

Orden recomendado de desbloqueo (de más a menos TR liberados), para el sprint 1 de M1:

| # | ADR | Desbloquea | Acción que lo acepta (de `m1-gray-prototype.md` § ADR y spikes) |
|---|---|---|---|
| 1 | **ADR-0005** Data schema | contenido-y-datos (17), acceso (15), bolsillo (14), ordenador (14), puzles (6), estado (2), jugador (2), director (2), carga (1), prompt (1) | Spike **S-0005-A** (parser JSON 4.7); C5; enmienda O1 de ADR-0018 (hot reload a `src/dev/`) |
| 2 | **ADR-0006** Input | entrada-y-controles (19), ordenador (14) | Spikes **S-0006-A…F**; C1 / NS-7 (entrega bus↔entrada en el mismo fotograma, R-M1-4); rec. 24 |
| 3 | **ADR-0010** Puzzle framework | puzles-marco-y-p1 (33) | **Aceptación sin spike**; resolver C4, C5, C6 (y H3, H8 de la cola de diseño) |
| 4 | **ADR-0017** Scene director | director-escenas-1-3 (26) | **Aceptación sin spike**; C3 (enmienda en ADR-0008) |
| 5 | **ADR-0016** Subtitles/UI text | prompt (20 de 20) | Spike corto con ADR-0007; R30 |
| 6 | ADR-0007 Settings/UI scaling | TR-prompt-018, TR-computer-013, TR-computer-014 | Spikes SP-1…SP-6 (solo la parte de escalado de UI en M1) |
| 7 | ADR-0008 Audio | TR-director-009/026, TR-puzzles-013, TR-scene-009 (co-citado) | `stream_paused`, limitador, arranque sin dispositivo; C2, C3 |

## Diferidos a M2/M3 (recortables sin épico en M1)

Decisión registrada (ver D2): **los 8 recortables quedan sin épico en esta pasada**. No es un
recorte formal: el orden de recorte del hito («un recorte cada vez», § Registro de cambios) lo
aplica el usuario/producer en el hito. Si M1 va por delante, `/create-epics` se vuelve a ejecutar
para el que se recupere.

| Recortable (orden) | GDD | ADR | Estado del ADR | Pasa a |
|---|---|---|---|---|
| 1 Manos (rig, `ANIM_*`) | 2 `jugador-en-primera-persona.md` | ADR-0013 (spike D-28) | Proposed | M2 / M4 |
| 2 Pistas de P1 | 17 `sistema-de-pistas.md` | (depende de ADR-0010) | Proposed | M2 |
| 3 Subtítulos | 26 `subtitulos.md` | ADR-0016 | Proposed | M3 — **ver aviso A2** |
| 4 Guardado al abrir puerta A | 5 `guardado-y-carga.md` | ADR-0004 (S-0004) | Proposed | M2 |
| 5 Menú de pausa (solo atajo dev en M1) | 25 `menu-de-pausa.md` | ADR-0002 | Accepted | M2 |
| 6 Rotación en inspección | 7 `interaccion-e-inspeccion.md` | ADR-0011 | Accepted | M2 (excluida de interaccion-y-prompt) |
| 7a Ajustes persistentes | 6 `ajustes-persistentes.md` | ADR-0007 (SP-1…6) | Proposed | M2 |
| 7b Audio por zonas | 23 `director-de-audio.md` | ADR-0008 | Proposed | M3 |

## Avisos (hallazgos de esta pasada)

- **A1 — Manifiesto desfasado.** `control-manifest.md` v2026-11-11 cubre solo ADR-0001, 0002 y
  0009; 0003, 0011 y 0012 se aceptaron después ese mismo día. Core y Feature no tienen reglas
  propias. **Antes de `/create-stories`** de jugador, carga-de-planta e interacción:
  `/create-control-manifest update`, o las historias incrustarán una versión sin sus reglas.
- **A2 — ADR-0016 no se difiere con los subtítulos.** Los 20 TR del prompt (imprescindible, GDD 24)
  citan ADR-0016. Recortar subtítulos (recorte 3) no exime de aceptar ADR-0016 en M1.
- **A3 — Audio provisional sin dueño.** C.1 exige `VO_V_01`, `MEGA_01` y la vibración de V02;
  con el audio por zonas diferido, ningún épico de M1 posee la reproducción plana provisional
  (GDD 23 / ADR-0008 Proposed). Se registra en director-escenas-1-3 como dependencia abierta;
  necesita decisión (historia mínima de `AudioDirector` o reproductor provisional del director).
- **A4 — TR-puzzle1-018 sin ADR en el registro** (oráculo de secuencias con `GameClock` falso).
  El hito lo ata a ADR-0018 (Proposed). C-M1-2 queda NOT ASSESSED en esa parte hasta trazarlo.
- **A5 — Cola de diseño.** Pendientes H3, H8, H9, H10, H12 (registro de cambios del hito) tocan
  interacción y jugador, que están Ready: aplicarlos antes de sus historias (R-M1-3).
- **A6 — Texto desfasado en el hito.** § «ADR y spikes que cierra» dice «todos `Proposed` hoy»;
  0003, 0011 y 0012 ya están Accepted (lo dice el § Overview y el Registro de cambios).
- **A7 — Alcance M1 < alcance del GDD.** Las tablas de TR de cada épico listan todos los TR del
  sistema; M1 solo usa un subconjunto (p. ej. acceso: puerta A y `A05`; director: escenas 1–3).
  La selección por historia la hace `/create-stories`, citando el § Alcance del hito.

## Revisión del producer (PR-EPIC)

**PR-EPIC: CONCERNS** — revisión hecha por el agente producer en esta misma pasada (no por un
subagente aparte). Motivos: 7 de 11 épicos bloqueados por 5 ADR `Proposed` (0005, 0006, 0010,
0016, 0017) con una sola persona (R-M1-6) y un plazo de 2–4 semanas de confianza baja; sin
velocidad medida. La estructura de épicos es correcta (uno por módulo, sin solapes); el riesgo
es de secuencia, no de límites. En modo autónomo se continúa «tal como está, aceptando las
preocupaciones»; mitigación: desbloqueos 1–5 en la semana 1, en el orden de la tabla.

## Decisiones tomadas

- **D1 — Ruta de los ficheros.** Se escribe `production/epics/<slug>/EPIC.md` (la que exige la
  skill y lee `/create-stories`) en lugar de `production/epics/<slug>.md`, que rompería
  `/create-stories <slug>`. Alternativa descartada: ficheros planos (el siguiente paso no los
  encuentra).
- **D2 — Recortables sin épico.** Alternativa descartada: épicos para los 8. Motivo: 5 de ellos
  tendrían el ADR de apoyo `Proposed` (nacerían bloqueados), el escenario esperado del hito ya
  prevé los recortes 1–4, y 7 de los 11 imprescindibles están bloqueados con una sola persona.
- **D3 — Interacción y prompt en un épico** con estado parcial, como pide el encargo del hito
  (GDD 7 + 24 en una fila). Alternativa descartada: dos épicos (más limpio para el bloqueo,
  pero contradice la fila del hito).
- **D4 — Un épico Ready con TR co-citados en un ADR Proposed** sigue Ready; esas historias
  concretas quedan bloqueadas. Las historias se escriben solo sobre TR «libres».
- **D5 — Sin capacidad ni fechas inventadas.** Ningún épico lleva estimación; el plazo es el del
  hito (2–4 semanas, confianza baja).

## Trazabilidad a criterios de salida del hito

| Criterio | Épicos que lo sostienen |
|---|---|
| C-M1-1 recorrido a escena 3 en export Win+Linux | todos (integración); director-escenas-1-3, acceso, documentos-y-bolsillo cierran la escena 3 |
| C-M1-2 tests de P1 | puzles-marco-y-p1 |
| C-M1-3 sin softlock | estado-y-bus, puzles-marco-y-p1, carga-de-planta |
| C-M1-4 5 flags por su dueño | estado-y-bus (contrato), ordenador, puzles, documentos-y-bolsillo |
| C-M1-5 tiempos C.1/C.3 ±1 fotograma | director-escenas-1-3 |
| C-M1-6 mando + teclado | entrada-y-controles, jugador, interaccion-y-prompt, ordenador |
| C-M1-7 capturas retenidas | jugador (despacho), ordenador (ordenador, impresión), puzles (panel P1), carga (Archivo), interaccion-y-prompt (prompt) |
| C-M1-8 tiempo del recorrido (informativo) | director-escenas-1-3 |
| C-M1-9 CI verde, 0 S1, 0 errores | todos |
| C-M1-10 carrera en REF-1 (informativa) | carga-de-planta, jugador |
