# Architecture Review Report

Date: 2026-11-10
Mode: full
Workflow: standard (rigor:standard). La skill a `standard` pide «architecture doc + critical ADRs only»; el encargo pedía los 17 ADR y se revisaron todos (alcance mayor que el mínimo, nunca menor).
Engine: Godot 4.7 (pin 4.7.2.stable.official.ed1daf0bf)
GDDs Reviewed: 30 GDD de sistema, **a través de `tr-baseline-provisional.md`** (no se abrió ningún GDD; ver § No leído)
ADRs Reviewed: 17 (ADR-0001…0017, todos `Proposed`)
Automation: autonomous. Cada pregunta de la skill se sustituyó por la decisión recomendada; están en § Decisiones tomadas.

[receipt al final del documento, § Receipt]

---

## Verdict: CONCERNS

- **Por qué no PASS:** ningún ADR está `Accepted`, así que 0 de 609 TR están ✅. Además, una parte de la revisión de motor queda NOT ASSESSED (ver abajo), y eso por sí solo ya impide un PASS.
- **Por qué no FAIL:** no hay huecos en Foundation/Core: los 7 ❌ son de Tooling y de localización. Tampoco hay conflictos 🔴 que bloqueen, ni ciclos de dependencias.
- **Partidas NOT ASSESSED** (cada una impide por sí sola un PASS):
  1. **Motor, todo lo que no es pausa.** Los ADR llevan 236 marcas `NOT SOURCEABLE`. Fuera de lo que cubrió el spike de pausa, esas afirmaciones quedan NOT ASSESSED, no PASS.
  2. **Consulta al especialista del motor (`godot-specialist`).** No se hizo: este subagente no tiene la herramienta `Agent`.
  3. **Presupuestos de rendimiento entre ADR.** No hay hardware de referencia (QQ-04 → ADR-0019), así que no se puede comprobar que la suma de 0014, 0015 y 0008 quepa en 16,6 ms.
  4. **Cobertura de sistemas en el Phase 6.** No se leyó `systems-index.md`, así que el cotejo sistema por sistema no se hizo.

## Traceability Summary

| Estado | Nº | % |
|---|---|---|
| ✅ Covered (ADR `Accepted`) | 0 | 0 % |
| 🟡 Covered (Proposed): trazado en *GDD Requirements Addressed* o *Decision* | 439 | 72,1 % |
| ⚠️ Partial | 163 | 26,8 % |
| ❌ Gap | 7 | 1,1 % |
| **Total** | **609** | 100 % |

Los 163 ⚠️ se reparten así:
- **13** citados solo en secciones no normativas, como fuera de alcance, o diferidos a ADR-0018/0019/0020.
- **150** no los cita ningún ADR. Se marcaron *implícitos* porque el mecanismo lo fija el ADR del sistema (por ejemplo, la entrada `P1` de `puzzles.json` queda dentro de 0005 y 0010). El ADR asignado a cada uno es **heurístico**: el que más TR del mismo sistema cita. Ese ADR no se cotejó contra el texto del TR.
- Por dominio y por sistema: `requirements-traceability.md`. Los dominios con más ⚠️: Animation 16/22, Scene 18/36, Save/Load 19/55, Accessibility 15/41.
- Por sistema, los puzles 1–6 y `access`, `box`, `pocket` y `hints` concentran los implícitos. Son reglas de contenido y comportamiento de cada sistema que el marco (0010) y el esquema (0005) permiten, pero que ningún ADR nombra. **Decisión:** no es un hueco de arquitectura. Lo que falta es trazabilidad, y se cierra en `/create-stories`, que cita el TR y el ADR del marco.

### Coverage Gaps (❌)

| TR | GDD | Requisito (resumen) | ADR sugerido | Riesgo motor |
|---|---|---|---|---|
| TR-puzzle1-018 | puzzle-1-cronologia.md | Tests: oráculo de 1.000 secuencias con `GameClock` falso | ADR-0018 Build, export, CI and dev-only tooling | LOW |
| TR-puzzle2-017 | puzzle-2-memorando-en-el-cristal.md | Solucionador exhaustivo de 64 estados | ADR-0018 | LOW |
| TR-puzzle3-018 | puzzle-3-encaje-de-la-foto.md | Tests de umbral de radio y combinaciones | ADR-0018 | LOW |
| TR-pause-023 | menu-de-pausa.md | gdUnit4 en `tests/unit/pause/`, capturas retenidas | ADR-0018 | LOW |
| TR-title-018 | pantalla-de-titulo.md | gdUnit4 en `tests/unit/title/` con dobles | ADR-0018 | LOW |
| TR-hints-017 | sistema-de-pistas.md | Duración F2 recalculada al cambiar idioma | ADR-0020 Localization readiness | LOW |
| TR-a11y-020 | opciones-de-accesibilidad.md | Textos `UI_ACC_*`, segunda línea si no cabe | ADR-0020 (o 0016) | LOW |

### Renombrados de ID

- `TR-audio-012b (provisional)` → **`TR-audio-026`**. El sufijo `b` no cumple `TR-[system]-NNN`, y 026 era el primer número libre de `audio`. Hay que actualizar las citas en ADR-0008 y en `architecture.md`, que siguen escribiendo «012b».
- Los otros 608 conservan su ID provisional, que ahora es definitivo: el registro estaba vacío (regla 2 de la Phase 2).

## Cross-ADR Conflicts

Se tomó como punto de partida `adr-reconciliation-2026-11-10.md` (rondas 1 y 2). Según ese documento, las contradicciones que encontró están resueltas. Esta revisión **no** volvió a leer los cuerpos de los ADR para buscar contradicciones nuevas (ver § No leído). Por eso la detección de conflictos de esta ronda se limita a lo siguiente:

- **🔴 Conflictos que bloquean: ninguno detectado.**
- **🟡 Contratos de integración abiertos.** No son contradicciones, pero hoy dos ADR no pueden implementarse los dos tal como están escritos:

| # | ADR | Tipo | Qué falta | Impacto | Resolución recomendada |
|---|---|---|---|---|---|
| C1 | 0001 / 0006 / 0003 | Pattern / timing | Que la entrega del bus llegue en el mismo fotograma que el despacho de entrada (rec. 26, NS-7 sin fuente) | `sin control` y la entrada podrían separarse un fotograma | Spike en S-0006 o V-ENG; aceptar 0006 solo con el resultado |
| C2 | 0007 ↔ 0008 | Integration | Comprobar que `SettingsReader`/`subscribe_change` equivale al `SettingsPort` + canal que pide 0008 OI-9 (rec. 23) | Audio sin aviso de cambio de volumen | Enmienda de 1 línea en 0008: usar las Key Interfaces de 0007 |
| C3 | 0008 ↔ 0017 | Integration | Cómo pide 22 la interrupción de voz para `VO_G_14_*` (R24) | 0017 da por hecha una API que 0008 no define | Enmienda en 0008 antes de aceptar 0017 |
| C4 | 0010 ↔ 0011 | Integration | Nombres de campo de `ViewElement`/`PointerEvent` (R26) | Controladores de puzle sin tipo cerrado | Fijarlos en 0011 D6 |
| C5 | 0005 ↔ 0010 | Data ownership | Claves de `puzzles.json` que añade 0010 (`idle_hints_auto_apply`, R28) | El validador de 0005 rechaza datos válidos | Añadirlas a 0005 D2.5 |
| C6 | 0010 ↔ 0015 / 0008 / 0017 | Integration | Quién reenvía los efectos de pista a `SurfaceFx`; parada de `VO_G_07` (R33) | Dos posibles dueños | Lo decide 0010 (dueño del marco) |
| C7 | 0012 / 0016 / 0011 / 0014 | Integration | `reserve`, `HANDS_BIT` (R29); aviso del `ViewportMapper`, capa de manos, anfitrión de la tarjeta final, F29-3 (R30); colisión de `V05` (R31); luz de `V02` en mano (R32) | Huecos de interfaz en Presentation | Cerrarlos en el ADR destino antes de aceptarlo |
| C8 | 0014 + 0015 + 0008 | Performance | Suma de presupuestos sin hardware de referencia | **NOT ASSESSED** | ADR-0019 tras QQ-04 |
| C9 | 0003 ↔ 0009 | Integration | ¿`recepcion` necesita `SceneServices` más allá de `player`, `interaction` y `atmosphere`? (rec. 27) | Bajo | Se cierra al hacer la historia de la escena |

Pendientes de la ronda 1 sin conflicto directo: rec. 24 (acción de depuración para `ContentDB.dev_reload()` en 0006), rec. 25 (idioma activo al arrancar en 0007; en el slice, `es` fijo) y rec. 28 (listas de campos de los ficheros del registro).

No existe `docs/consistency-failures.md`, así que no hay patrones previos que mostrar ni entradas que añadir.

## ADR Dependency Order

Salida de `adr-dep-graph.sh`:
- 73 aristas, **sin `CYCLE`** y sin `NO_DEPS_SECTION`.
- `ADRS: 18`: el patrón `adr-*` también recoge `adr-reconciliation-2026-11-10.md`, que no tiene aristas. Es una observación, no un defecto de los ADR.
- Orden: 0001, 0002, 0009, 0003, 0007, 0004, 0005, 0006, 0008, 0015, 0010, 0011, 0012, 0013, 0014, 0016, 0017.

| Capa | ADR (requiere) |
|---|---|
| Foundation | 0001 Event bus and fact contract (ninguno) |
| | 0002 Pause and game time (0001) |
| | 0009 Service composition (0001, 0002) |
| Core | 0003 Scene loading (0001, 0002, 0009) |
| | 0007 Settings / a11y / UI scaling (0001, 0002, 0009) |
| | 0004 Save (0001, 0002, 0003, 0009) |
| | 0005 Data schema (0001, 0002, 0003, 0009) |
| | 0006 Input (0001, 0002, 0003, 0007, 0009) |
| | 0008 Audio (0001, 0002, 0003, 0009) |
| Feature / Presentation | 0015 Glass and mirror shaders (0002, 0007, 0009) |
| | 0010 Puzzle framework (0001–0006, 0009) |
| | 0011 Interaction (0001, 0002, 0003, 0006, 0009) |
| | 0012 Player and camera (0002, 0003, 0005, 0006, 0007, 0009) |
| | 0013 Hands and blackout (0002, 0005, 0007, 0009) |
| | 0014 Atmosphere (0001, 0002, 0003, 0005, 0007, 0009) |
| | 0016 Subtitles and UI text (0001, 0002, 0005–0009) |
| | 0017 Scene director (0001–0009) |

⚠️ Todas las aristas apuntan a ADR `Proposed`. Ningún ADR puede implementarse con seguridad hasta que se acepte su cadena de dependencias, empezando por 0001 y 0002.

## ADR por pasar a `Accepted` y su condición

**No se ha cambiado el estado de ningún ADR.** Moverlo a `Accepted` exige la confirmación explícita del usuario y cumplir la condición de la tabla. Se listan en orden topológico.

| ADR | Condición (de su § Status y de esta revisión) | Distancia |
|---|---|---|
| 0001 | Sin gate de spike en Status. Antes de aceptar: verificaciones V-ENG-1…6 (lectura en O(1), parada en dev) y decisión C1 (NS-7) | Cerca: primera candidata junto a 0002 |
| 0002 | Spike ejecutado en 4.7.2 (S1–S3, S5–S16 PASS, opción A válida). Falta el **log de S4 manual** (foco con teclado y mando, conectar y desconectar el mando); escuchar S8 y mirar el salto visual de S11 | **La más cerca**: solo falta ese log |
| 0009 | 0001 y 0002 `Accepted`; C9 | Cerca (riesgo LOW) |
| 0003 | Spikes S-0003-A y S-0003-B en 4.7.2 con sus resultados en § Spike Results (S-0003-C lo comparte con 0005) | Spike pendiente |
| 0007 | Spikes SP-1…SP-6 (geometría de stretch a 720p/1080p/2160p y 16:10, AccessKit, re-layout del Theme); rec. 23 y 25 | Spike pendiente |
| 0004 | Spike S-0004 en Windows **y** Linux y AC-42 del GDD 5 en PASS | Spike pendiente |
| 0005 | Spike S-0005-A (parser JSON de 4.7); C5 | Spike pendiente |
| 0006 | Spikes S-0006-A…F, y 0001, 0002, 0003 y 0009 `Accepted`; C1; rec. 24 | Spike pendiente |
| 0008 | Verificación de `stream_paused` (S8 ya PASS en el spike de pausa), limitador y arranque sin dispositivo; C2, C3 | Spike parcial |
| 0015 | Spike de shaders que exige TR-shaders-008. S10 confirma que la fase debe ir sobre `GameClock` (ya lo decide) | Spike pendiente |
| 0010 | Sin spike; C4, C5, C6; dependencias `Accepted` | Enmiendas |
| 0011 | Spikes S-0011-A, -B y -C (`intersect_shape` con Jolt); C4; R31 | Spike pendiente |
| 0012 | Spikes S-0012-A…F (interpolación a 30/60/144 fps); R29 | Spike pendiente |
| 0013 | Spike D-28 cuyo resultado se escriba en D1, borrando la rama perdedora | Spike pendiente |
| 0014 | Prueba S0b en hardware de referencia (QQ-04, decisión del usuario); R32 | Bloqueada por QQ-04 |
| 0016 | Spike corto junto con 0007; R30 | Spike pendiente |
| 0017 | Sin spike (LOW); C3 (enmienda en 0008); dependencias `Accepted` | Enmiendas |

Que una sección «Spike Results» exista en 0003, 0004, 0006 y 0011 no significa que el spike se haya ejecutado. No se leyeron. Según el historial, solo se ha ejecutado el spike de pausa.

## Engine Compatibility Issues

Engine: Godot 4.7 (pin 4.7.2). ADRs con `## Engine Compatibility`: **17 / 17**.

- **Versión:** los 17 declaran Godot 4.7. Ninguno está desfasado.
- **APIs obsoletas:** 0 usos. Las 7 coincidencias con `deprecated-apis.md` citan la sustitución, no la API vieja:
  - 0002:63 y 0003:70 → `Time.get_ticks_msec`
  - 0003:48 → `instantiate()`
  - 0006:52 → `event.device == 0` evitado
  - 0008:46/77 → `tap_back_pos` retirado
  - 0012:73 → `AnimationMixer.active`
- **Riesgo declarado:** HIGH en 0002, 0003, 0004, 0006, 0007, 0008, 0011, 0012, 0013, 0014, 0015 y 0016; MEDIUM en 0001, 0005 y 0010; LOW en 0009 y 0017.
- **Afirmaciones post-corte:**
  - **Pausa (ADR-0002): ASSESSED.** El spike en 4.7.2 verifica S1–S3 y S5–S16; S4 es parcial. Datos nuevos del spike:
    - `TIME` de shader avanza en pausa.
    - `create_timer` se dispara en pausa.
    - G-4 no es necesario.
  - **Resto: NOT ASSESSED.** Las 236 marcas `NOT SOURCEABLE` (0002: 26, 0005: 23, 0006: 21, 0016: 20, 0011: 19, 0004: 18, 0001 y 0008: 17, 0003, 0007 y 0012: 15, 0014: 11, 0013: 6, 0010: 4, 0009, 0015 y 0017: 3) no tienen fuente en `docs/engine-reference/godot/`. Las comprueban los spikes de la tabla anterior. Algunas de las marcas de 0002 quedaron resueltas por el spike, pero no se volvió a contar por marca.
  - **Contradicciones entre ADR sobre la misma API post-corte:** no se detectó ninguna en lo leído (Engine Compatibility y reconciliación). No se cruzaron los cuerpos de los ADR.
- **`### Engine Specialist Findings`: NOT ASSESSED.** No se pudo lanzar `godot-specialist` (sin herramienta `Agent`). Recomendación: lanzarlo con 0002, 0006, 0007, 0011, 0012, 0014 y 0015, que son los de más marcas o los de render.

### GDD Revision Flags (Phase 5b)

| GDD | Supuesto | Realidad | Acción |
|---|---|---|---|
| shaders-y-efectos.md (29) | Animación de shader con `TIME` / `Tween` (R35, H16) | El spike S10 muestra que `TIME` avanza en pausa: hace falta una fase uniforme sobre `GameClock` (ADR-0015) | Revise GDD (H16) |
| atmosfera-reactiva.md (28) | `Tween` para la energía de las luces (R7, R22, TR-atmos-008/-018) | ADR-0014: envolvente sobre `GameClock`. Con `create_timer` y `Tween` de proceso, el tiempo corre en pausa (S5, S16) | Revise GDD (H14) |
| Cualquier GDD con temporizadores de juego | `SceneTreeTimer` | S16: `create_timer` se dispara en pausa por defecto; la prohibición por grep en CI es necesaria | Se cubre en ADR-0018 |

**Decisión (autonomous):** **no** se edita `systems-index.md`. El encargo limita los entregables a tres ficheros y no se leyó el índice. Las filas de 28 y 29 deberían pasar a `Needs Revision` en el próximo lote de GDD.

## Architecture Document Coverage (Phase 6)

`architecture.md` existe, pero **está desfasado** (se leyó por cabeceras y § ADR Audit / Required ADRs, líneas 714–805):
- § ADR Audit sigue diciendo «No existe ningún ADR… Cobertura hoy: 0 de 609 TR (0 %)». Debe remitir a `requirements-traceability.md`.
- Siguen sin aplicar los cambios A1–A8 de la ronda 1 y H2, H3, H9, H12 y H18 de la ronda 2 de la reconciliación: API Boundaries, Boot con `GameClock`, solo `Boot` como raíz de composición, árbol del Shell, `PauseVeil`, `ViewReceiver`, TR-player-010 repartido.
- Las listas «TRs que cubre» de § Required ADRs son la intención de diseño. La trazabilidad real está en la matriz: por ejemplo, 0009 cita 17 TR y 0013 cita 8.
- **Sistemas que faltan / arquitectura huérfana: NOT ASSESSED.** No se leyó `systems-index.md` ni § System Layer Map. El baseline sí cubre 30 sistemas con slug, y los 30 aparecen citados en al menos un ADR.

## Required ADRs (por prioridad)

1. **ADR-0018** Build, export, CI and dev-only tooling. Cierra 5 ❌ y los ⚠️ de Tooling, y la prohibición de `create_timer` que aportó el spike.
2. **ADR-0019** Performance budgets and reference hardware. Bloqueada por QQ-04 (decisión del usuario). Cierra C8.
3. **ADR-0020** Localization readiness. Post-slice; 2 ❌.

No hace falta un ADR nuevo de Foundation o Core.

## Decisiones tomadas (modo autonomous)

| Pregunta de la skill | Decisión | Alternativa descartada y motivo |
|---|---|---|
| Freshness (Phase 1a) | `RECEIPT: NONE` → revisión completa | Ninguna: no había informe previo |
| Ambigüedad TR provisional ↔ registro (Phase 2 regla 4) | El registro estaba vacío: se conservan los 609 ID; solo se renombra 012b | Renumerar todo: rompería las citas de los ADR |
| TR sin cita | ⚠️ implícito con el ADR del sistema; ❌ solo para Tooling/Localization sin ADR | Todo ❌: inflaría huecos que son de trazabilidad, no de arquitectura |
| Campos del registro | Se añaden `provisional_id`, `adrs`, `coverage` (entre comillas); `version: 2` | Un fichero de mapeo aparte: el encargo pide el mapeo en el registro |
| Systems index (5b) | No editar | Marcar `Needs Revision`: queda fuera de los entregables y el índice no se leyó |
| Escritura (Phase 8) | [A] los tres ficheros. No existe `consistency-failures.md` y no hay 🔴, así que no se añade nada | — |
| `active.md` (Phase 8) | No se añade el extracto | El encargo dice «solo estos» entregables |
| Validación | `registry.sh validate`: duplicate 0, path_missing 0, status 0, layout 0; `yaml.safe_load`: 609 entradas, 609 ID únicos (= baseline) | — |

## No leído (declaración de lectura parcial)

- **GDDs:** ninguno abierto. Todo viene de `tr-baseline-provisional.md`, que a su vez es parcial: 10 bloques «NO LEÍDO», con Edge Cases y AC de casi todos los GDD sin extraer. El número de TR **crecerá**.
- **`systems-index.md`, `game-concept.md`, `game-pillars.md`, revisiones cruzadas:** no leídos.
- **ADR:** solo se escanearon por grep las cabeceras, § Status, las líneas de Engine Compatibility (versión, riesgo, `References Consulted`) y las citas TR de todas las secciones. Del ADR-0002 se leyó § Spike Results.
  - No se leyeron Context, Decision completa, Consequences, Alternatives, Validation Criteria, Spike Plans ni Open Items. Por eso la detección de conflictos descansa en la reconciliación.
  - Las secciones «Spike Results» de 0003, 0004, 0006 y 0011 no se leyeron.
- **`architecture.md`:** solo las cabeceras y las líneas 714–805.
- **Referencia del motor:** se leyó `VERSION.md` (del contexto) y se cruzó `deprecated-apis.md` por grep. No se leyeron `breaking-changes.md`, `current-best-practices.md` ni `modules/*.md`.
- **`project.yaml`:** solo `automation` y `workflow` vía `resolve_config`; no se leyeron `performance.*` ni `naming.*`. `technical-preferences.md` no se leyó.
- **Clasificación ⚠️ implícita:** el ADR asignado a los 150 TR sin cita es heurístico y no se cotejó con el texto del TR.
- **Clasificación 🟡:** se basa en que el ID aparezca en *GDD Requirements Addressed* o *Decision*. No se juzgó si la decisión cubre el requisito entero. Los rangos abreviados (`TR-x-008/-009`, `…`) se expandieron por regex.

## Handoff

1. **Acciones inmediatas:**
   - Ejecutar y registrar el log de S4 manual (deja 0002 lista para aceptar).
   - Aceptar 0001 y 0009 con el usuario tras V-ENG.
   - Escribir ADR-0018.
2. **Pre-gate:** no se comprobó (fuera del alcance de entregables).
3. **Rerun:** repetir `/architecture-review` tras cada ADR aceptado o nuevo, y cuando el baseline lea los bloques «NO LEÍDO».

## Receipt

```
Reviewed-Content-Hash: docs/architecture/adr-0001-event-bus-and-fact-contract.md 8cfb32e7a93b5dd3c67be51cfa2e40c79868add7
Reviewed-Content-Hash: docs/architecture/adr-0002-pause-and-game-time.md 657b2c66481a6f8708bed162799555e2f6acdf95
Reviewed-Content-Hash: docs/architecture/adr-0003-scene-loading-and-sin-control-handoff.md a02ce45deecd10af5a36ab8d7ca00f04d1fa3997
Reviewed-Content-Hash: docs/architecture/adr-0004-save-format-and-lifecycle.md 4137bb065efe1b8fb65092fc4c647e8b67f0bf07
Reviewed-Content-Hash: docs/architecture/adr-0005-data-schema-validation-and-content-catalog.md aed17c264f180469de220f656e2b6e63fdf0fc65
Reviewed-Content-Hash: docs/architecture/adr-0006-input-abstraction-contexts-and-binding-labels.md fe8a29554e6a7a6e9a76114e8cc010121ee25723
Reviewed-Content-Hash: docs/architecture/adr-0007-settings-persistence-accessibility-and-ui-scaling.md e00e8e03df9a45d235653e2f37a74f8df238a31a
Reviewed-Content-Hash: docs/architecture/adr-0008-audio-buses-voice-queue-and-process-mode.md 0e07e9b59b63b81734929ce04f9f4232cf1ea216
Reviewed-Content-Hash: docs/architecture/adr-0009-service-composition.md 4618f7e1388866b9c100c41f16b3a4fbcf6a09e2
Reviewed-Content-Hash: docs/architecture/adr-0010-puzzle-framework-and-controller-contract.md cc14d8ba4c736f2b92072df3412713f3211deef1
Reviewed-Content-Hash: docs/architecture/adr-0011-interaction-focus-query-and-view-picking.md 395ac9309b7d2a202dbe39ad93bc537b6cf62f6f
Reviewed-Content-Hash: docs/architecture/adr-0012-player-controller-physics-interpolation-and-camera.md 95111b60cc60f9d15011fa16d6b8cd47d2695b90
Reviewed-Content-Hash: docs/architecture/adr-0013-first-person-hands-rendering-and-blackout-lighting.md b51d190a6535df36a5bdd02ba7cff1309924cc1a
Reviewed-Content-Hash: docs/architecture/adr-0014-atmosphere-lighting-budget-and-rain.md 43796c1200dc0efc23451742d86f59776fbd5d51
Reviewed-Content-Hash: docs/architecture/adr-0015-glass-and-mirror-shaders-and-draw-order.md d9bd37ea5494ae9e4a8ef1a7e9f6223898374e4c
Reviewed-Content-Hash: docs/architecture/adr-0016-subtitles-and-ui-text-rendering.md a3f12696bbb0fdd71814f006c91958cd315c3f54
Reviewed-Content-Hash: docs/architecture/adr-0017-scene-director-timeline-and-call-data.md 106517b52ec77007aaf913a8b6685718f82d62d7
Reviewed-Content-Hash: docs/architecture/adr-reconciliation-2026-11-10.md bf5eb94a983d4c321cc649c0c7421c060dd2e396
Reviewed-Content-Hash: design/gdd/ajustes-persistentes.md 6fe569a57acd732771bd9105aafb050ef19a433c
Reviewed-Content-Hash: design/gdd/atmosfera-reactiva.md 7258b4a547ca5eb8a471b919495e0749303b9729
Reviewed-Content-Hash: design/gdd/base-de-contenido-narrativo.md 49727a5e2abd90c6a1bd0148e7d4aeb01c10ec0f
Reviewed-Content-Hash: design/gdd/caja-y-compartimentos.md d4a327871012a3ebb92f0e1ed938ce673c899689
Reviewed-Content-Hash: design/gdd/control-de-acceso.md 09e64b76c65863cdf2bff2d27cbf3cf38d95bbc0
Reviewed-Content-Hash: design/gdd/director-de-audio.md 0bf47b3ccc51f7739564218f039efb5e023702ba
Reviewed-Content-Hash: design/gdd/director-de-escenas.md 05b617c3b876058a25c12b62627298b41335df7a
Reviewed-Content-Hash: design/gdd/documentos-y-bolsillo.md 334e07bb4d212312d302aca180c264f3bd10f29c
Reviewed-Content-Hash: design/gdd/entrada-y-controles.md 06f53ac25bb283b22b78c064824feaa9c53c6085
Reviewed-Content-Hash: design/gdd/escena-de-planta.md 7e1730ec2feea3c37ce510ace6320ebe796f1d51
Reviewed-Content-Hash: design/gdd/estado-y-bus-de-eventos.md cf99409993ae13b3545f6249b194925d6f5a81d0
Reviewed-Content-Hash: design/gdd/game-concept.md e61855a8fa01048602b05a3996c21901df88a14a
Reviewed-Content-Hash: design/gdd/game-pillars.md aa4a6e4044da0181aebb404c6736a597b96bf9b7
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-09-r2.md a36a7e5f530747c6e0d53a52f3d496d8624996ef
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-09-r3.md 66fbc20908c23038cf0edc3b4b3e6ffff309f1ae
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-09-r4.md 62760594489d184c21d18642330175867ebd4a26
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-09-r5.md 6062e9875d37cdf9be7ebf9436ed9293457257b1
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-09-r6.md 37143ecac8b221ce6786c8268dc491e74aff3be7
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-09-r7.md c42bea8671e4640e96573a1ce831d585981d132b
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-09-r8.md 97fce2f4786d6c1c0ad2f5c89dc43ccce8a83a32
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-09.md 384064ad270da46f2dba1e3b9791b222f669075b
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-10-r2.md 96c49f64646d64fdca2187ba373f9ca98020e238
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-10.md b83b4334e433d62b1cbc20f0a2e93ea58241b8e5
Reviewed-Content-Hash: design/gdd/guardado-y-carga.md 5fda76e9b4353b235aaf76d58ca93f0b844606d1
Reviewed-Content-Hash: design/gdd/interaccion-e-inspeccion.md 6378f3cd87ac2ab971381ac25d5106e5eb065314
Reviewed-Content-Hash: design/gdd/jugador-en-primera-persona.md 02afd87f741dd373bd5f0fb0e4ff0a3a835b92f4
Reviewed-Content-Hash: design/gdd/llamada-telefonica.md 1d0a8114505f1d204238b5b988b34ce5f0616ca8
Reviewed-Content-Hash: design/gdd/marco-de-puzles.md 442ea6fc8f86197422a239f04f6994dfb8391abc
Reviewed-Content-Hash: design/gdd/menu-de-pausa.md 2d40e3c103cf6e61b64c6a348ce6b99d5bac7db8
Reviewed-Content-Hash: design/gdd/opciones-de-accesibilidad.md 41d265d4a9bde433c409940f10018052d80f7a8f
Reviewed-Content-Hash: design/gdd/ordenador-correo-impresora.md b3e64f48e7cd61048f17c2ec49e7f6c19014f34a
Reviewed-Content-Hash: design/gdd/pantalla-de-titulo.md 87d832e773847f96282d84e0ffca2fbe473a3567
Reviewed-Content-Hash: design/gdd/prompt-de-interaccion.md ce449edd4db554e2c85b40193e8e5544aa3fb1d2
Reviewed-Content-Hash: design/gdd/puzle-1-cronologia.md 9de1874cc3e4c97010b3792ea2b675567ddcfe40
Reviewed-Content-Hash: design/gdd/puzle-2-memorando-en-el-cristal.md c976c9002af30fab1e1dd67b416faa2575176440
Reviewed-Content-Hash: design/gdd/puzle-3-encaje-de-la-foto.md 7e6467de90c3fd0d01c5aaace2f49890916c9d40
Reviewed-Content-Hash: design/gdd/puzle-4-tablero-de-tareas.md 97d8688e9280efde5abfd4cc8082125c7fe9e43a
Reviewed-Content-Hash: design/gdd/puzle-5-espejo-de-la-diferencia.md d285f88691fa08dcd3c7804da1396017ed903de7
Reviewed-Content-Hash: design/gdd/puzle-6-decision.md 4e957032c5f2426ce1453b7e7ac266697771d87c
Reviewed-Content-Hash: design/gdd/shaders-y-efectos.md 59b480c6176b831783325c36d0cca01bb15963c0
Reviewed-Content-Hash: design/gdd/sistema-de-pistas.md 913cb99db5822b32513135512ffced46f9acfda3
Reviewed-Content-Hash: design/gdd/subtitulos.md 7c2585bf3266bba002b9360b0872ecae7b9be23b
Reviewed-Content-Hash: design/gdd/systems-index.md 4e5ece8bd94559b8e6893cdbf0643dd249ece1e3
Reviewed-Content-Hash: docs/architecture/tr-registry.yaml 4ab86ccc339747ca6eb9e6056416cd7d170c484e
Reviewed-Content-Hash: docs/architecture/architecture.md 3629eabc7a2a1910f04dd728b4cb2b7e6b25109c
Reviewed-Content-Hash: docs/engine-reference/godot/VERSION.md 5a606f800f696bc137cde59ef7b9deeedb0db1a8
Reviewed-Content-Hash: docs/engine-reference/godot/breaking-changes.md 4bc55e16796664ff88c7582c9f08e3530f7c94d4
Reviewed-Content-Hash: docs/engine-reference/godot/current-best-practices.md a45cd2c39a8ec53eaa3e924f39f93594e62085fd
Reviewed-Content-Hash: docs/engine-reference/godot/deprecated-apis.md 6a1353983e1db0d7bc0cc41a568b039495b5413c
Reviewed-Content-Hash: docs/engine-reference/godot/modules/animation.md ee51f50a46f8c63b771f62fe438947d4d84c59e3
Reviewed-Content-Hash: docs/engine-reference/godot/modules/audio.md c72af247505908a04f84a1dd3e765939efe700bd
Reviewed-Content-Hash: docs/engine-reference/godot/modules/input.md 3406b1b813858898696e510ea0accfcc7df98af8
Reviewed-Content-Hash: docs/engine-reference/godot/modules/navigation.md 7ae18ffbd2c3230cb19d610373225bfba187a472
Reviewed-Content-Hash: docs/engine-reference/godot/modules/networking.md 6606880462a2241014f77feb9610c5611e659ec6
Reviewed-Content-Hash: docs/engine-reference/godot/modules/physics.md 3b6ac8947f3f3e8c9ac9e6e0ff6cac06fdb8d805
Reviewed-Content-Hash: docs/engine-reference/godot/modules/rendering.md 2a303185bb57eed31dd1151a036784820747b211
Reviewed-Content-Hash: docs/engine-reference/godot/modules/ui.md 30ad166ab8c4e92c15aa37ed3464483b92b7845b
Reviewed-Content-Hash: project.yaml 9e919bea49f0c49e56a9b91813273e0414a6241a
Reviewed-Content-Hash: .claude/docs/technical-preferences.md b38101f179bfe125f17828c9b68cbf9082ff3a55
review-receipts: not stamped, no such file: docs/consistency-failures.md
Reviewed-Content-Hash: .claude/skills/architecture-review/SKILL.md 1a9d28aadbcbd26b5fc6b8ed1c64d73ae82b7b73
Reviewed-Content-Hash: .claude/skills/architecture-review/references/1-load.md 9a65759ebdbb2cb1f9744775bfed18cb25e76347
Reviewed-Content-Hash: .claude/skills/architecture-review/references/2-extract-requirements.md d08ea0b0e9ab9760b0d8bfe0cd9115f0bc40f8e2
Reviewed-Content-Hash: .claude/skills/architecture-review/references/3-traceability.md bb7b6b65c5e5e5b8869fa692413aa831615dede7
Reviewed-Content-Hash: .claude/skills/architecture-review/references/4-conflicts.md 0d30f8173b23248a32523a365b606dd1ce9642ab
Reviewed-Content-Hash: .claude/skills/architecture-review/references/5-engine.md 318ecbc1361d430badaf5dd8ce4cfc6ab0dff0ca
Reviewed-Content-Hash: .claude/skills/architecture-review/references/6-document-coverage.md dcce78482ec2ce60048989b6f9d1f797dd0a9a0e
Reviewed-Content-Hash: .claude/skills/architecture-review/references/7-report.md a007fd66bdac87812dc272e4b14cd231174e979d
Reviewed-Content-Hash: .claude/skills/architecture-review/references/8-write.md bf6d8946fc7b9e19eda7f65503a5c8f593a0d2b1
Reviewed-Content-Hash: .claude/skills/architecture-review/references/9-handoff.md fd5f681f4c3517c6a2e388c6d78075d82dded22e
```
