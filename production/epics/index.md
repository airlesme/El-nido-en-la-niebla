# Epics Index

Last Updated: 2026-11-11 (2.ª pasada: re-evaluación tras aceptar ADR-0005, 0006, 0010 y 0017)
Engine: Godot 4.7.2 (pin `4.7.2.stable.official.ed1daf0bf`)
Ámbito: hito **M1 · Prototipo gris (escenas 1–3)** — `production/milestones/m1-gray-prototype.md`
Control manifest: `docs/architecture/control-manifest.md` **Manifest Version 2026-11-11** — en
regeneración en esta misma sesión (ver cuestión abierta Q2)
Generado por: `/create-epics` (1.ª pasada) y producer (2.ª pasada), modo `automation: autonomous`

Estado de los ADR comprobado con Grep `^Accepted` bajo `## Status` el 2026-11-11:
**Accepted** 0001, 0002, 0003, 0005, 0006, 0009, 0010, 0011, 0012, 0017 ·
**Proposed** 0004, 0007, 0008, 0013, 0014, 0015, 0016, 0018, 0019.

## Épicos de M1 (12: 11 por módulo de `architecture.md` § Module Ownership + audio-provisional)

«Libres» = TR cuya fila no cita ningún ADR `Proposed` (se pueden escribir historias hoy).
**Criterio de estado (2.ª pasada):** **LISTO** = todo el trabajo de M1 escribible; los TR que
aún citan un `Proposed` caen en un recorte diferido o son co-citas sueltas (D4). **PARCIAL** =
hay un bloque de TR que M1 necesita y que sigue citando un `Proposed`. **BLOQUEADO** = el
trabajo de M1 del épico no puede empezar.

| Epic | Layer | System (GDD n.º) | Stories | Status | TR libres / total | Bloqueado por | Desbloqueado hoy por |
|------|-------|------------------|---------|--------|------|------|------|
| [estado-y-bus](estado-y-bus/EPIC.md) | Foundation | 3 Estado y bus | Not yet created | **LISTO** | 14 / 18 | ADR-0004 solo en TR-state-013…016 (guardado, recorte 4) | ADR-0005 (TR-state-001) |
| [entrada-y-controles](entrada-y-controles/EPIC.md) | Foundation | 1 Entrada | Not yet created | **LISTO** | 19 / 19 | — (comprobaciones de mando físico NEEDS_MANUAL) | ADR-0006 |
| [contenido-y-datos](contenido-y-datos/EPIC.md) | Foundation | 18 Contenido + esquema | Not yet created | **LISTO** | 17 / 17 | — | ADR-0005 |
| [jugador-primera-persona](jugador-primera-persona/EPIC.md) | Core | 2 Jugador | Not yet created | **LISTO** | 17 / 21 | ADR-0013 solo en 4 TR de manos (recorte 1) | ADR-0005 (TR-player-002/021) |
| [carga-de-planta](carga-de-planta/EPIC.md) | Core | 4 Escena de planta | Not yet created | **LISTO** | 22 / 23 | ADR-0008 co-citado en TR-scene-009 | ADR-0005 (TR-scene-022) |
| [interaccion-y-prompt](interaccion-y-prompt/EPIC.md) | Feature + Presentation | 7 Interacción, 24 Prompt | Not yet created | **PARCIAL**: 7 LISTO · 24 BLOQUEADO | 22 / 42 | **ADR-0016** (20 TR del prompt; TR-prompt-018 también ADR-0007) | ADR-0005 (TR-prompt-020, sigue con 0016) |
| [documentos-y-bolsillo](documentos-y-bolsillo/EPIC.md) | Feature | 20 Bolsillo | Not yet created | **LISTO** | 18 / 18 | — | ADR-0005 |
| [ordenador-e-impresora](ordenador-e-impresora/EPIC.md) | Feature | 19 Ordenador/impresora | Not yet created | **PARCIAL** | 20 / 22 | **ADR-0007** (TR-computer-013/014, escalado de UI y tamaño de texto) | ADR-0006, ADR-0005 |
| [puzles-marco-y-p1](puzles-marco-y-p1/EPIC.md) | Feature | 9 Marco, 11 Puzle 1 | Not yet created | **LISTO** | 39 / 40 | ADR-0008 co-citado en TR-puzzles-013; TR-puzzle1-018 **sin ADR** (Q3) | ADR-0010, ADR-0005, ADR-0017 |
| [acceso-puerta-a-cajon-a05](acceso-puerta-a-cajon-a05/EPIC.md) | Feature | 8 Acceso (puerta A, `A05`) | Not yet created | **LISTO** | 18 / 18 | — | ADR-0005 |
| [director-escenas-1-3](director-escenas-1-3/EPIC.md) | Feature | 21 Director (escenas 1–3) | Not yet created | **PARCIAL** | 25 / 27 | **ADR-0008** (TR-director-009/026: canales de voz y líneas sin audio) | ADR-0017, ADR-0005 |
| [audio-provisional](audio-provisional/EPIC.md) | Feature (C3) | 23 Audio (subconjunto plano) | Not yet created | **BLOQUEADO** | 0 / 10 | **ADR-0008** (los 26 TR de 23 lo citan) | — (épico nuevo, Q1) |

**Resumen:** 8 LISTO, 3 PARCIAL, 1 BLOQUEADO. Los cuatro ADR aceptados hoy liberaron 7 épicos
(contenido, entrada, acceso, bolsillo, puzles, y los núcleos de ordenador y director). Lo que
queda bloqueado cuelga de **tres ADR**: 0016 (prompt), 0007 (escalado de UI en prompt y
ordenador) y 0008 (audio provisional + 2 TR del director).

## (a) Épicos que siguen bloqueados y por qué ADR

| Épico | Parte bloqueada | ADR | ¿Imprescindible en M1? |
|---|---|---|---|
| interaccion-y-prompt | Todo el prompt (GDD 24, 20 TR) | ADR-0016 (+ ADR-0007 en TR-prompt-018) | Sí — C-M1-7 pide su captura; A2: recortar subtítulos no exime de 0016 |
| ordenador-e-impresora | TR-computer-013 (UI lógica 1920×1080, 16:9/16:10, modo teclado ≤ 520 px) y TR-computer-014 (texto ≥ 24 px, contraste, lector de pantalla) | ADR-0007 | Sí en parte — el hito marca 0007 «Parcial: escalado de UI del prompt/ordenador» |
| director-escenas-1-3 | TR-director-009 (dos canales `VO_V_*`/`MEGA_*`) y TR-director-026 (líneas fallidas/sin audio) | ADR-0008 | Sí — C.1 lanza `VO_V_01` y `MEGA_01` |
| audio-provisional | Todo el épico | ADR-0008 | Sí — slice/hito: C.1 «Audio provisional»; hito § ADR: 0008 «Parcial (audio provisional)» |
| carga-de-planta / puzles-marco-y-p1 | TR-scene-009 / TR-puzzles-013 (co-cita de 0008) | ADR-0008 | Co-citas sueltas; el resto del épico no espera |
| estado-y-bus / jugador | TR-state-013…016 / 4 TR de manos | ADR-0004 / ADR-0013 | No — recortes 4 y 1 |

## (b) ADR `Proposed` por aceptar para M1

| # | ADR | Desbloquea en M1 | Spike o acción pendiente (hito § ADR y spikes) | Dueño |
|---|---|---|---|---|
| 1 | **ADR-0008** Audio (aceptación parcial) | audio-provisional (10 TR), TR-director-009/026, TR-puzzles-013, TR-scene-009 | Subconjunto del Spike Plan: **SA1** (árbol de buses), **SA3** (`get_length()`), **SA5** (falta vs roto, en export), **SA6** (sin dispositivo) + **S8/S9** de ADR-0002 (`stream_paused`, audio con el árbol pausado) si no se ejecutaron; C2; **C3** (enmienda que pide ADR-0017). Coste del ADR: ~0,5–1 día de los 1,5 totales. SA7 (limitador), SA8–SA10 se difieren con el audio por zonas (recorte 7b) | engine-programmer; revisa technical-director |
| 2 | **ADR-0016** Subtitles/UI text | prompt (20 TR) | Spike corto compartido con ADR-0007; R30. **Necesario aunque se recorten los subtítulos** (A2) | ui-programmer / engine-programmer; revisa technical-director |
| 3 | **ADR-0007** Settings/UI scaling (solo escalado de UI) | TR-prompt-018, TR-computer-013/014 | De SP-1…SP-6, solo los de escalado de UI y texto; rec. 23, 25; **G18 [U] QQ-10** (suelo de 24 px, decisión del usuario pendiente). Persistencia de ajustes, con el recorte 7a | engine-programmer; revisa technical-director |
| 4 | **ADR-0018** Build/export/CI | C-M1-1 (exports Win+Linux), C-M1-9 (CI), trazado de TR-puzzle1-018 (Q3) | El hito lo da por «cerrado en S0» pero sigue `Proposed`: aceptarlo o registrar por qué no. Incluye la enmienda O1 (hot reload a `src/dev/`) que exigía ADR-0005 | technical-director |
| — | ADR-0004, ADR-0013 | Solo si no se aplican los recortes 4 y 1 | S-0004 (Win+Linux, AC-42); D-28 | — |

Fuera de M1: 0014, 0019 (S0b), 0015 (M2/M4). Orden de aceptación sugerido: 0008 parcial y 0016
+ 0007 parcial en paralelo con la primera semana de historias de Foundation (no bloquean
Foundation ni Core).

## (c) Orden sugerido de historias por épico

Orden entre épicos (dependencias): **estado/bus → contenido/datos y entrada → jugador → carga de
planta → interacción → acceso/bolsillo → ordenador/impresora → puzle 1 → audio provisional →
director.** Contenido sube al lado de entrada porque el resto lee datos validados al arrancar.
Dentro de cada épico, primero lo lógico (con test), después lo integrado, al final lo visual.
Son títulos orientativos para `/create-stories`, no historias.

1. **estado-y-bus** — catálogo de hechos desde `flags.json` (TR-001) → lectura O(1) y escritura
   validada con `owner` (002–006) → derivados (007) → avisos, cola y bajas (008–011) →
   `escribir_silencioso` (017) → consola dev + script CI (018). Instantánea/restauración (013–016) no.
2. **contenido-y-datos** — validador de esquemas con los hallazgos de S-0005-A (claves
   duplicadas, BOM en bytes, comas finales) → `ContentDB` y capa de idioma → datos de escenas
   1–3, `flags.json`, entrada `P1` de `puzzles.json` (D-04 desde datos).
3. **entrada-y-controles** — pila de contextos → `sin control` (dueño, duración, tope; sin
   depender de entrega en el mismo fotograma, C1 medido) → dispositivo activo → asignaciones
   por defecto → `get_binding_label`. Sesión manual de mando físico al final (NEEDS_MANUAL).
4. **jugador-primera-persona** — `CharacterBody3D` y movimiento → mirada con interpolación (R1)
   → cámara y FOV → pausa → captura del despacho y corredor de 15 s (NEEDS_WINDOWED). Antes: H10, H12.
5. **carga-de-planta** — `SceneLoader` y estados → traspaso de `sin control` → geometría gris
   A.2–A.4 y zonas → panel de Error → S-0003-C medido sobre la `planta` gris.
6. **interaccion-y-prompt (solo 7)** — consulta de foco (ADR-0011, fallback de raycast) →
   retención de foco → pila de modos → vistas y `PointerEvent` → lectura por pulsación larga →
   aviso «interacción ejecutada». Prompt (24) cuando se acepte ADR-0016. Antes: H8, H9.
7. **acceso-puerta-a-cajon-a05** — estado derivado de la puerta A desde `archivo_abierto` →
   `ANIM_DOOR_OPEN` 1,2 s con reloj falso → cajón A05.
8. **documentos-y-bolsillo** — conjunto de sesión y `otorgar`/`has_item` → `formulario_leido`
   (A04) → tarjetas I-02/I-03 (`tarjeta_B`, `tarjeta_D`) → pantalla de lectura (captura).
9. **ordenador-e-impresora** — sesión V01 y búsqueda «transición» (0,4 s, orden 3·1·4·2) → foco
   dual con `LineEdit` → correos y `correos_leidos` → V08 y `compose_i01()`. TR-computer-013/014
   tras ADR-0007. Antes: H21.
10. **puzles-marco-y-p1** — marco y estado público (C4–C6 al tocarlos) → `PuzzleController` y
    `evaluate() -> Verdict` puro → P1 con fallo no terminal 1,5 s → escritor único de
    `archivo_abierto` → tests de C-M1-2 (el oráculo con `GameClock` falso espera a Q3). Antes: H3.
11. **audio-provisional** — tras la aceptación parcial de ADR-0008: autoload persistente →
    buses mínimos → «línea pedida» con respuesta única → dos canales → sin dispositivo → capas
    de ventilador y lluvia.
12. **director-escenas-1-3** — reloj `t_rel` y datos de escena (A1–A6 al tocarlos) → órdenes por
    el bus → C.1 → C.2 → C.3. Las líneas de C.1 dependen de audio-provisional (o corren con la
    duración de lectura de «sin audio» hasta entonces). Antes: H20, H23, H24.

## (d) Cuestiones abiertas

- **Q1 — Audio provisional de la escena 1 sin dueño (antes A3).** *Propuesta del producer:*
  épico nuevo [audio-provisional](audio-provisional/EPIC.md), dueño **audio-director**
  (implementa engine-programmer; sonidos provisionales del sound-designer). Alcance mínimo:
  `AudioDirector` autoload según ADR-0009 (slot n.º 6), reproducción **plana** de `VO_V_01`,
  `MEGA_01`, ventilador (`AMB_FAN`) y lluvia (con su intensificación de C.3), contrato de
  respuesta única a «línea pedida» y modo sin dispositivo. Sin ducking, polifonía, pasos,
  loudness ni zonas. **Verificado en el hito:** la escena 1 dice «Audio provisional» (§ Alcance)
  y ADR-0008 figura como «Parcial (audio provisional)» (§ ADR y spikes): está en alcance.
  **No encaja sin ADR-0008:** los 26 TR del sistema 23 lo citan, y la regla del hito impide
  historias sobre TR con un ADR `Proposed`. Queda **BLOQUEADO** hasta la aceptación parcial de
  ADR-0008 ((b) n.º 1). Mitigación mientras tanto: el director usa la ruta «sin audio» del GDD
  (duración de lectura, F3) y C.1 se puede recorrer en silencio; no es audio provisional, solo
  evita bloquear al director. *Decisión del usuario pendiente:* aceptar el dueño y el épico.
- **Q2 — Control manifest sin 0003/0011/0012 (antes A1).** Se está regenerando en esta sesión;
  debe incluir también 0005, 0006, 0010 y 0017. **No ejecutar `/create-stories`** de ningún
  épico hasta que exista la versión nueva, o las historias incrustarán reglas incompletas.
- **Q3 — TR-puzzle1-018 sin ADR (antes A4)** (oráculo de secuencias con `GameClock` falso). El
  hito lo ata a ADR-0018 (`Proposed`). Acción: trazarlo en `tr-registry.yaml` a ADR-0002 +
  ADR-0010 (ya aceptados: reloj inyectable y `evaluate()` puro) o aceptar ADR-0018; lo decide
  technical-director. Hasta entonces C-M1-2 queda NOT ASSESSED en esa parte.

## Avisos vigentes

- **A2 — ADR-0016 no se difiere con los subtítulos.** Los 20 TR del prompt (imprescindible, GDD 24)
  citan ADR-0016. El hito dice «0016: solo si no se recorta (3)»: contradice este aviso y hay
  que corregir el hito.
- **A5 — Cola de diseño.** Pendientes H3, H8, H9, H10, H12 tocan puzles, interacción y jugador:
  aplicarlos antes de sus historias (R-M1-3).
- **A6 — Texto desfasado en el hito.** § «ADR y spikes que cierra» dice «todos `Proposed` hoy»;
  ya hay 10 Accepted. Y § «No le conciernen» da 0018 por cerrado en S0, pero sigue `Proposed`.
- **A7 — Alcance M1 < alcance del GDD.** Las tablas de TR listan todos los TR del sistema; M1
  usa un subconjunto. La selección la hace `/create-stories`, citando el § Alcance del hito.

## Diferidos a M2/M3 (recortables sin épico en M1)

Sin cambios respecto de la 1.ª pasada (D2), salvo que el audio plano provisional ya tiene épico
propio; el audio por zonas (7b) sigue diferido.

| Recortable (orden) | GDD | ADR | Estado del ADR | Pasa a |
|---|---|---|---|---|
| 1 Manos (rig, `ANIM_*`) | 2 `jugador-en-primera-persona.md` | ADR-0013 (spike D-28) | Proposed | M2 / M4 |
| 2 Pistas de P1 | 17 `sistema-de-pistas.md` | ADR-0010 | **Accepted** (recuperable si M1 va por delante) | M2 |
| 3 Subtítulos | 26 `subtitulos.md` | ADR-0016 | Proposed | M3 — ver A2 |
| 4 Guardado al abrir puerta A | 5 `guardado-y-carga.md` | ADR-0004 (S-0004) | Proposed | M2 |
| 5 Menú de pausa (solo atajo dev en M1) | 25 `menu-de-pausa.md` | ADR-0002 | Accepted | M2 |
| 6 Rotación en inspección | 7 `interaccion-e-inspeccion.md` | ADR-0011 | Accepted | M2 |
| 7a Ajustes persistentes | 6 `ajustes-persistentes.md` | ADR-0007 (SP-1…6) | Proposed | M2 |
| 7b Audio por zonas | 23 `director-de-audio.md` | ADR-0008 | Proposed | M3 |

## Revisión del producer (PR-EPIC)

**PR-EPIC: CONCERNS** (2.ª pasada). Mejora clara: de 7 épicos bloqueados a 1 bloqueado y 3
parciales, y el bloqueo se concentra en 3 ADR (0008, 0016, 0007), los tres parciales en M1.
Motivos de la preocupación: (1) ninguno de los 3 tiene aceptación con fecha y los tres caen en
épicos imprescindibles (director, prompt, ordenador); (2) el manifiesto está en regeneración y
bloquea `/create-stories` en todos los épicos (Q2); (3) sigue sin velocidad medida (R-M1-6, una
persona, 2–4 semanas de confianza baja). Mitigación: aceptación parcial de 0008 y spike
0016+0007 durante la primera semana de historias de Foundation, que no los necesita.

## Decisiones tomadas

- **D1 — Ruta de los ficheros.** `production/epics/<slug>/EPIC.md` (la que lee `/create-stories`).
  Alternativa descartada: ficheros planos.
- **D2 — Recortables sin épico.** Alternativa descartada: épicos para los 8 (nacerían bloqueados).
- **D3 — Interacción y prompt en un épico** con estado parcial, como pide el hito.
- **D4 — Un épico con TR co-citados en un ADR Proposed** sigue LISTO; esas historias concretas
  quedan bloqueadas. Las historias se escriben solo sobre TR «libres».
- **D5 — Sin capacidad ni fechas inventadas.** El plazo es el del hito (2–4 semanas, confianza baja).
- **D6 (2.ª pasada) — Tres estados LISTO / PARCIAL / BLOQUEADO** con el criterio de arriba.
  Alternativa descartada: conservar «Ready / BLOQUEADO (parcial)», que llamaba igual a un épico
  con 4 TR libres y a otro con 18. Motivo: el estado debe decir si el trabajo de M1 puede empezar.
- **D7 (2.ª pasada) — audio-provisional como épico propio y BLOQUEADO.** Alternativas
  descartadas: (i) reproductor provisional dentro del director (mezcla los módulos 21 y 23 y
  habría que tirarlo en M3); (ii) marcarlo LISTO apoyándose solo en ADR-0009 (ADR-0009 fija el
  slot del autoload, no el contrato de voz; todos los TR del 23 citan ADR-0008).

## Trazabilidad a criterios de salida del hito

| Criterio | Épicos que lo sostienen |
|---|---|
| C-M1-1 recorrido a escena 3 en export Win+Linux | todos (integración); director-escenas-1-3, acceso, documentos-y-bolsillo cierran la escena 3 |
| C-M1-2 tests de P1 | puzles-marco-y-p1 |
| C-M1-3 sin softlock | estado-y-bus, puzles-marco-y-p1, carga-de-planta |
| C-M1-4 5 flags por su dueño | estado-y-bus (contrato), ordenador, puzles, documentos-y-bolsillo |
| C-M1-5 tiempos C.1/C.3 ±1 fotograma | director-escenas-1-3, audio-provisional (respuesta de línea) |
| C-M1-6 mando + teclado | entrada-y-controles, jugador, interaccion-y-prompt, ordenador |
| C-M1-7 capturas retenidas | jugador (despacho), ordenador (ordenador, impresión), puzles (panel P1), carga (Archivo), interaccion-y-prompt (prompt) |
| C-M1-8 tiempo del recorrido (informativo) | director-escenas-1-3 |
| C-M1-9 CI verde, 0 S1, 0 errores | todos |
| C-M1-10 carrera en REF-1 (informativa) | carga-de-planta, jugador |
