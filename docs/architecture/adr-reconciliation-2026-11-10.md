# Reconciliación de ADRs — 2026-11-10

Alcance: ADR-0001…0009 (todos `Proposed`). Autor: technical-director (modo autonomous).
Regla aplicada: cada enmienda entre ADRs se aplica en el ADR **destino** con Edit
mínimo y se marca «Resolved» en el Open Item de origen. Los cambios a GDDs y a
`architecture.md` **no** se aplican aquí: se listan en la sección final.

## 1. Enmiendas entre ADRs

| # | ADR destino | Enmienda (origen) | Estado |
|---|---|---|---|
| 1 | ADR-0003 | Tope de `sin control` de Entrada corre en `GameClock`, no `RealClock`; `M_traspaso` en tiempo real es conservador (ADR-0006 OI-1, ADR-0002) | aplicada (§ D6) |
| 2 | ADR-0003 | `open_no_control(owner, declared_s, absorbs_foreign)` + `close_no_control(owner)` en `InputContexts`; llamada y tabla de pasos con `absorbs_foreign = motivo in [PARTIDA_NUEVA, REANUDAR]` (ADR-0006 OI-1; cierra 0003 O3) | aplicada |
| 3 | ADR-0003 | Claves de carga útil de `scene_load_*`/`scene_ready` alineadas al registro de ADR-0001 (`destino`, `motivo`, `control_final`, `D_carga`, `causa`); el pseudocódigo usaba claves inglesas | aplicada |
| 4 | ADR-0003 | Paso 4: aserto G-11 (no instanciar en pausa; 25 llama `resume()` antes) y 4 llama `GameClock.reset_session()` antes de instanciar (ADR-0002 OI-3) | aplicada |
| 5 | ADR-0003 | `unbind_scene()` en paso 3 y `bind_scene()` en paso 7 sobre 21, 23 y `Shell` (ADR-0009 D6, ausente en 0003) | aplicada |
| 6 | ADR-0001 | `input_context_changed` = `{anterior, contexto}` (clave española `anterior` = «previous», como en ADR-0006) (ADR-0006 OI-2) | aplicada |
| 7 | ADR-0001 | Ejemplo `no_control_absorbed.dueno` = `&"scene_director"` (ADR-0006 OI-2) | aplicada |
| 8 | ADR-0001 | `GameState.is_draining()` y `GameState.run_after_drain(job)` como envoltorios de `NoticeChannel` (ADR-0004 OI-1) | aplicada |
| 9 | ADR-0001 | `control_final` ‡ en «iniciada» y «terminada»; `t_since_started_s` ‡ en «terminada» (ADR-0003 O1) | aplicada (‡ hasta que GDD 3/4/21 lo confirmen) |
| 10 | ADR-0001 | OI-6 cerrado para el sistema 1 (`anterior`, `contexto`, `dueno`); `dispositivo` sigue ‡ | aplicada parcial |
| 11 | ADR-0009 | `SceneServices.audio_index: AudioSceneIndex`; `AudioDirector` como `SceneBindable` (adaptador) (ADR-0008 OI-6) | aplicada |
| 12 | ADR-0009 | Fila D4 de 22: sin `request_save`; sellado por aviso; llamadores de `request_save` = 25 y `Shell` (ADR-0004 OI-2) | aplicada |
| 13 | ADR-0009 | `ServiceContext.flavor: BuildFlavor` (paso 0 y `for_scene`) (ADR-0005 O2) | aplicada |
| 14 | ADR-0009 | Paso 9 de Boot: `director/scenes.json` + `director/director_config.json` (ADR-0005 O1) | aplicada |
| 15 | ADR-0009 | `MonotonicClock` → `RealClock` | ya hecha antes de esta ronda |
| 16 | ADR-0004 | `FileStore` gana `read_text` / `write_atomic` (borrar-y-renombrar, regla D7) para Settings (ADR-0007 OI-3) | aplicada |
| 17 | ADR-0007 | Firmas de `FileStore` alineadas a ADR-0004 (`rename`/`remove`/`ensure_dir` → `Error`) y dos llamadas `!= OK` | aplicada |
| 18 | ADR-0004 | Clave `causas_activas` (registro ADR-0005) en lugar de `save_active_causes` (ADR-0004 OI-7) | aplicada |
| 19 | ADR-0005 | Pseudocódigo usa `LogSink.line(level, msg)` de ADR-0001 (ADR-0005 O4) | aplicada |
| 20 | ADR-0005 | `LineTextSource` de 23 = adaptador sobre `ContentDB.get_line()` (ADR-0008 OI-9, parte 18) | aplicada |
| 21 | ADR-0002 | OI-7 (inyección de relojes) cerrado por ADR-0009 D3 | aplicada (solo marca) |
| 22 | 0004/0006/0007/0008 | Contradicción `MonotonicClock` marcada «Resolved: `RealClock` (ADR-0002)» (0004 OI-3, 0006 OI-6, 0007 C1, 0008 OI-7) | aplicada |
| 23 | ADR-0007 | `SettingsPort` + canal de cambios que pide ADR-0008 OI-9 (0007 expone `SettingsReader`/`subscribe_change`; hay que confirmar la equivalencia) | pendiente |
| 24 | ADR-0006 | Acción de entrada de depuración para `ContentDB.dev_reload()` (ADR-0005 O6) | pendiente |
| 25 | ADR-0007 | Origen del idioma activo al arrancar (ADR-0005 O7; en el slice, `es` fijo) | pendiente |
| 26 | ADR-0001/0006 | Garantía de entrega en el mismo fotograma respecto al despacho de entrada (ADR-0003 O2; depende de NS-7, que no tiene fuente) | pendiente (spike) |
| 27 | ADR-0003 | ¿`recepcion` necesita `SceneServices` más allá de `player`, `interaction`, `atmosphere`? (ADR-0009 O5) | pendiente |
| 28 | 0004/0006/0007/0008/0010+ | Listas de campos de los ficheros del registro (ADR-0005 O5) | pendiente (ADRs futuros) |

## 2. Cambios requeridos en GDDs / architecture.md (deduplicados)

| # | Destino | Cambio | ADR origen |
|---|---|---|---|
| G1 | GDD 7 r29 / OQ 6, GDD 28 | Alinear si 28 consume «interacción ejecutada» | 0001 OI-2 |
| G2 | GDD 3 Tuning Knobs | Tope «por entrega encadenada», no «por fotograma» | 0001 OI-3 |
| G3 | GDD 3 r2 | Confirmar comprobación de dueño en `write_silent` también en release | 0001 OI-4 |
| G4 | GDD 3 Dependencias (fila 7) | 4 avisos frente a los 11 de r10 | 0001 OI-8 |
| G5 | GDD 3 r10, GDD 4, GDD 21 | `control_final` en «iniciada»/«terminada», `t_since_started_s` en «terminada» | 0003 O1/C6 |
| G6 | GDD 3, 24, 25 | Consumidores de «pausa cerrada» (5 no, 24 sí) | 0002 OI-5 |
| G7 | GDD 23 D23-25, 28 R22/OQ 12, 29 R35/OQ 11, 26 OQ 8, 25 OQ 2/D25-28 | Cerrar tras el spike de pausa | 0002 OI-2 |
| G8 | GDD 4 OQ 8 + GDD 27 | Quién levanta el telón sobre el título (fila `titulo` en `load_transitions.json`) | 0003 O4 |
| G9 | GDD 4 r15 vs r11 | Descarga total desde pausa: fundido de 0,1 s | 0003 O5/C3 |
| G10 | GDD 21 r11b | Quitar «Continuar» desde la pausa | 0003 C4 |
| G11 | GDD 5 Edge Cases vs r24 | «Nueva partida desde Sellada» = desde el título | 0004 OI-5 |
| G12 | GDD 5 | `save_recovered` solo tras `save_at_risk`; `v0` aceptado sintácticamente | 0004 OI-6 |
| G13 | GDD 16 (usuario, QQ-11) | Permanencia de la elección de P6 | 0004 OI-4 |
| G14 | GDD 5, 21, 17, 7, 4, 19, 22; TR-director-003, TR-save-021, TR-scene-022 | Rutas `assets/data/<dominio>/<snake>.json`; GDD 7 sin `*.schema.json`; claves `t_cap`, `n_gap`, `delta_max` | 0005 O1/C1/C2/C5 |
| G15 | GDD 1 r17 | «Tecla imprimible» → conjunto que consume el campo de texto | 0006 OI-5 |
| G16 | GDD 24 | Consultar periódicamente `bindings_revision()` (aviso «asignaciones cambiadas») | 0006 OI-9 |
| G17 | GDD 30 (opcional) | Ajuste manual de estilo de glifos | 0006 OI-8 |
| G18 | GDD 24, 26, 30 (usuario QQ-10) | Suelo de 24 px lógicos; quitar el factor de ventana de 30 F1, 24 F2, 26 F3; AC-26-08 recalculado | 0007 OI-1/C2/C3 |
| G19 | GDD 6 / ajustes (usuario QQ-08) | `escala_texto_ui` cerrada (18 claves) | 0007 OI-2 |
| G20 | GDD 30 Tuning Knobs | `tope_destellos_s` = constante de código | 0007 C4 |
| G21 | GDD 6 AC-13 + Edge Cases | Sin aviso si el modo aplicado no cambia; adoptar `.tmp` huérfano si falta el principal | 0007 C5/C6 |
| G22 | GDD 23 R41, R48, Tuning Knobs | Nombrar capas en pausa; `watchdog`; nuevos ajustes `t_atasco_s`, `max_pasos`, partición del pool, `muro_db` | 0008 OI-3/4/10 |
| G23 | GDD 18, GDD 26 OQ 1 | `seg_b_inicio_s` opcional por segmento de `VO_G_07` | 0008 OI-8 |
| G24 | GDD 23 OQ 3 / 27 OQ 1 (usuario) | Silencio de audio en el título | 0008 OI-11 |
| G25 | GDD 28 DT-1 / TR-atmos-001 | La atmósfera es un nodo de escena | 0009 C1 |
| G26 | GDDs 7, 20, 9, 12, 15, 17 | Llamadas hacia arriba → puertos de salida | 0009 C4 |
| A1 | `architecture.md` § API Boundaries | «Bus y estado (3)» con nombres G-13; «Guardado (5)» con D11; «Entrada» con las Key Interfaces de 0006 | 0001 OI-9, 0004 OI-8, 0006 OI-3 |
| A2 | `architecture.md` § Data Flow 4 (Boot) | Añadir `GameClock` (paso 3); que la lista del validador remita al registro D1 | 0009 C2, 0005 C3 |
| A3 | `architecture.md` § Data Flow 5 | 4 abre `sin control` en SYNC tras «iniciada» | 0003 C1 |
| A4 | `architecture.md` § Árbol | Liberar el título no es una «descarga» | 0003 C2 |
| A5 | `architecture.md` § Required ADRs / Module Ownership / Data Flow pausa | 25 `ALWAYS`; `RealClock`, `schedule`/`cancel`/`deadline`; T1–T6 | 0002 OI-1 |
| A6 | `architecture.md` QQ-14 | Validación en el nivel L (planta) y el nivel B (arranque) | 0005 C4 |
| A7 | `architecture.md` § Module Ownership «Regla de uso», § System Layer Map, mapa de capas | Solo `Boot` es raíz de composición; puertos D6; 21 = F5 alojado como autoload | 0009 C3/C4/C5 |
| A8 | `reviews/cross-review-r9-esquema-v2.md`, `engine-reference/godot/modules/ui.md` | Ruta `assets/data/state/flags.json`; nota sobre `tr()` | 0005 C6/C7 |

## 3. Contradicciones entre ADRs

Ninguna queda sin resolver. Resueltas en esta ronda: nombre del reloj, firmas
de `FileStore` (0004 frente a 0007; manda 0004), idioma de las claves de carga
útil (0003 frente a 0001; manda el registro de 0001) y `request_save` desde 22
(0009 frente a 0004).

---

# Ronda 2 (ADR 0010–0017)

Misma metodología que la ronda 1: Edit mínimo en el ADR **destino** y marca
«Resolved» en el Open Item de origen cuando existe. Sin tocar GDDs ni
`architecture.md`.

## R2.1 Enmiendas entre ADRs

| # | ADR destino | Enmienda (origen) | Estado |
|---|---|---|---|
| R1 | ADR-0009 | `SceneServices.puzzle_writer: FactWriter` (9), construido por la raíz de escena con `GameState.writer_for(9)` (0010 OI-1) | aplicada |
| R2 | ADR-0009 | D3 regla 5: excepción para restaurar en `configurar` llamando a `BoxPresenter` (0010 C4 / D12) | aplicada |
| R3 | ADR-0003 | Nota en el pseudocódigo: `configure_all` decide el fallo con la consulta `configuration_failed()` porque `configurar()` devuelve `void` (0010 C6 / D13) | aplicada |
| R4 | ADR-0006 | `PointerTargetProvider.target_at(p_px) -> StringName`; `GestureRecognizer` lo usa al pulsar (0011 A-1 / C3) | aplicada |
| R5 | ADR-0009 | Fila D4 de 7: añadir 3 (solo lectura) y 6 (lectura) (0011 A-2 / C2) | aplicada |
| R6 | ADR-0009 | Ejemplo D3 `registrar_manejador(&"A03", …)` pasa un adaptador `InteractionHandler` (0011 A-3) | aplicada |
| R7 | ADR-0006 | D9: límites de `PointerCursor` = `ViewportMapper.logical_rect()`; `zone_rect()` toma el valor por defecto del mapper; 1920×1080 es la referencia 16:9 (0016 OI-3 / C3, 0011 C1) | aplicada |
| R8 | ADR-0008 | `listener_position()` → `rayo_vision().origen` / `.direccion` (0012 OI-1 / C1) | aplicada |
| R9 | ADR-0009 | Fila D4: añadir 2 a las filas de 8, 19, 22 y 23 (0012 OI-2 / C3) | aplicada |
| R10 | ADR-0002 | OI-4 resuelto por ADR-0012 D2 (0012 OI-4) | aplicada |
| R11 | ADR-0003 | O6 y R5 resueltos por ADR-0012 D2/D4; `colocar` antes de `configurar` deja una colocación pendiente (0012 OI-5 / C2) | aplicada |
| R12 | ADR-0007 | D9: `LIGHT_FLICKER_DEPTH_FLOOR = 0.40`; quitar el alias `FLASH_MAX_HZ`; unidad del destello; 28 llama a `try_flash()` tras su limitador; cierra OI-6 (0014 OI-1, 0013 C3) | aplicada |
| R13 | ADR-0009 | `FlashGuard` inyectado por `ServiceContext` (0014 OI-5) | aplicada |
| R14 | ADR-0014 | Umbral de glow ≥ 1,0 (o pase SH5); D7 cita el tope medido `ΔL_refl` de ADR-0015 D2 (0015 OI-1) | aplicada |
| R15 | ADR-0009 | Fila D6 de `SurfaceFx`: 10 → 11 operaciones (+ `set_floor_marks`), firmas en ADR-0015; cierra O2 para `SurfaceFx` (0015 OI-3) | aplicada |
| R16 | ADR-0007 | D8.3: el hover mueve el cursor/foco de opciones (0016 OI-2 / C2) | aplicada |
| R17 | ADR-0017 | 21 no arranca líneas mientras la cortina cubre la pantalla (0016 OI-4 / C5) | aplicada |
| R18 | ADR-0007 | OI-5 cerrado: la pantalla de 19 es un overlay del lienzo raíz (0016 OI-10) | aplicada |
| R19 | ADR-0009 | `SceneDirector` recibe `settings` (`SettingsReader`, `reducir_movimiento`) (0017 A1) | aplicada |
| R20 | ADR-0003 | `SceneLoader.fade_duration_s(reason) -> float` ‡ (0017 A2) | aplicada |
| R21 | ADR-0006 | `InputContexts.no_control_margin_s() -> float` ‡ (`margen_E`) (0017 A3) | aplicada |
| R22 | ADR-0001 | Filas «‡ ADR-0017» del registro → ADR-0017 D5; esquema `SceneEffects` (0017 A4, 0014 OI-7) | aplicada |
| R23 | ADR-0005 | D2.5: `scenes.json` + `al_disparar`, `cadena`, campos de cue; `call.json` `times` sin `fallback_s`, con `t_pick_s`, `t_breath_s` (0017 A5 / C2 / C8) | aplicada |
| R24 | ADR-0008 | Forma de la petición de interrupción de voz que usa 22 para `VO_G_14_*` (0017 A6) | pendiente |
| R25 | ADR-0011 | `ViewReceiver` como puerto `RefCounted` (0010 OI-2) | ya estaba hecha (0011 D6: `@abstract … extends RefCounted`) |
| R26 | ADR-0011 | Nombres de campo de `ViewElement` / `PointerEvent` (0010 OI-5) | pendiente |
| R27 | ADR-0015 | Operación de `SurfaceFx` para el `HIGHLIGHT` en el mundo (0010 OI-4) | ya estaba hecha (0015: pulso `HIGHLIGHT` + `stop_highlight`) |
| R28 | ADR-0005 | Claves de `puzzles.json` añadidas por 0010 (`idle_hints_auto_apply`) (0010 OI-6) | pendiente |
| R29 | ADR-0012 | Tipo que devuelve `rayo_vision()`, `fov_actual()`, `reserve` (0011 OI-4); `pose_con_retardo`, `giro_acumulado` (0014 OI-4); objetos en mano en `HANDS_BIT` (0013 OI-8) | parcial: `rayo_vision`, `fov_actual`, `pose_con_retardo`, `giro_acumulado` ya existen; `reserve` y `HANDS_BIT` pendientes |
| R30 | ADR-0016 | Aviso de cambio de `ViewportMapper` (0011 OI-5); capa de `HandsComposite` (0013 OI-4); anfitrión de la tarjeta final por encima de la cortina (0017 OI-4); el texto del mundo usa F29-3 (0015 OI-9) | parcial: `logical_rect()` ya existe; aviso de cambio, capa de manos, anfitrión de la tarjeta y F29-3 pendientes |
| R31 | ADR-0011 | Números de capa de colisión `player_body` / `zone_sensor` (0012 OI-9, 0003 O7); colisión del objeto en mano (0012 OI-6) | parcial: capas 2 `player_body` y 4 `zone_sensor` ya en 0011; colisión de `V05` pendiente |
| R32 | ADR-0014 | Luz del teléfono `V02` en mano (0013 OI-3) | pendiente |
| R33 | ADR-0010 | Quién reenvía los efectos de pista a `SurfaceFx` (0015 OI-6); parada de `VO_G_07` (0017 OI-6, con 0008) | pendiente |

## R2.2 Cambios requeridos en GDDs / architecture.md (deduplicados; **[U]** = decisión del usuario)

| # | Destino | Cambio | ADR origen |
|---|---|---|---|
| H1 | GDD 9 r9 | Atracción de las referencias de P1: prevalece la anulación por zona | 0010 C1 |
| H2 | GDD 9 r9, r13; `architecture.md` | `PARTIAL(progress)` + `element`/`action` opcionales | 0010 C2 |
| H3 | GDD 17 R11.4/R13; `architecture.md` | `request_hint -> int` (`HintOutcome`, `!= REFUSED`); R13 sin aviso nuevo | 0010 C3/C7 |
| H4 | GDD 9 r7, GDD 11 Dependencias | `missing_items` es una lista; el controlador de P1 llama a `compose_i01()` en `on_open()` | 0010 C5/C10 |
| H5 | GDD 9 Tuning Knobs, r4b, r14a; TR-puzzles-008 | `idle_hints_auto_apply` = false en los datos; llamadas internas `reject`/`begin`; nota sobre los hooks | 0010 C8/C9/C11 |
| H6 | GDD 7 r31, GDD 13 | `distancia_m` (obligatoria) y `centro_m` en `vista`/`modo`; 13 deja de usar `view_distance_m` | 0011 OI-2 |
| H7 | GDD 7 r20, F2/r32 | `pos_px_inicio`; `seleccionar` = un solo `FIN`; nota sobre la pulsación larga | 0011 OI-3/C4 |
| H8 | GDD 14 OQ 1 | Tamaño del tablero `D01b` y su `distancia_m` (diseño / arte) | 0011 OI-6 |
| H9 | `architecture.md` § Interacción (7) | `ViewReceiver` = puerto `RefCounted`; `PIE_PERSISTENTE = -1.0` | 0011 A-4/C5 |
| H10 | GDD 1 F2–F3 | Convención de signos de `consume_look_delta()` | 0012 OI-3 |
| H11 | GDD 2 OQ 4, OQ 9, r22 | Rig de las manos / `HAND_CARD_SWIPE`; r22 consulta por sondeo, no por el bus | 0012 OI-8/C4 |
| H12 | `architecture.md` filas ADR-0012/0013 | TR-player-010 repartido (contrato del nodo / técnica) | 0012 C5 |
| H13 | GDD 28 traspaso fila 2; TR-atmos-010 | Capa de render `HANDS` con suelo emisivo, luces compartidas; separar técnica y mecanismo | 0013 C1/C2 |
| H14 | GDD 28 R7, R22, OQ 12; TR-atmos-008/-018 | `Tween` → envolvente sobre `GameClock` | 0014 OI-2 |
| H15 | GDD 28 F8, AC-28-02, Tuning Knobs; TR-atmos-016/-005 | ≤ 14 habilitadas por instancia (activación por sala); AC ≤ 2; nombres de `A11yConstants`; `zone_visibility`, `shadow_allowlist` | 0014 OI-3 |
| H16 | GDD 29 R7, R11, R13/AC-16, R33, R35, R41, R5; TR-shaders-004/-006/-017/-020, TR-puzzle2-007 | Película + texto; material por instancia; tope de luminancia; 11 operaciones; sin `Tween`; prioridad del texto del cristal; citar la definición de destello de ADR-0007 D9 | 0015 OI-2/OI-5 |
| H17 | GDD 30 | El texto del mundo se mide con F29-3, no con `TEXT_MIN_PX`; `a11y_tab.json` e ids del atlas de glifos por `PadFamily` | 0015 OI-9, 0016 OI-8 |
| H18 | `architecture.md` árbol del Shell, § Required ADRs | `PauseVeil`, números de capa (D1), fila 0016 | 0016 OI-1/C4 |
| H19 | GDD 26 R22 | Las líneas en `sin control` quedan bajo la cortina (las retiene 21) | 0016 C5 |
| H20 | GDD 18 | Claves `UI_ACCION_<ID>`, `UI_SUB_HABLANTE_*`, `UI_SUB_MUESTRA`, `TEL_MENSAJE_*`, `UI_TITULO_JUEGO`, `UI_CONTINUARA` (`seg_b_inicio_s` = G23) | 0016 OI-7, 0017 OI-2/OI-3 |
| H21 | GDD 19 | La pantalla del ordenador es un overlay del lienzo raíz en `SceneUi` | 0016 OI-10 |
| H22 | GDD 8, 21 | Id y estados de las puertas del ascensor de recepción (`ASCENSOR_RECEPCION` ‡) | 0017 OI-1 |
| H23 | GDD 7, 21 | Quién ejecuta `TELEFONO_PULSOS` / `TELEFONO_MENSAJE` sobre `V02` | 0017 OI-2 |
| H24 | GDD 21 r4, r7, Tuning Knobs | Estados de objeto en lugar de efectos; 23 posterga las líneas; ruta y ubicación de los ajustes (ruta = G14) | 0017 G-a/G-b/G-c |
| H25 | GDD 22 Tuning Knobs | `t_pick_s`, `t_breath_s`; `fallback_s` por línea desde 18; `t_corte_senal_s` retirado | 0017 G-d/C1 |
| H26 | GDD 27 r24 | Anfitrión de la tarjeta final en el Shell, por encima de la cortina | 0017 G-e/C7 |
| H27 | GDD 24 F2, GDD 26 F3 (TR-subs-014, TR-prompt-015/-018) | = G18 de la ronda 1 **[U]** QQ-10 | 0016 OI-5 |
| H28 | GDD 24 R14 / TR-prompt-010 | = G16 de la ronda 1 | 0016 OI-6 |
| H29 | GDD 28 OQ 8, OQ 11, OQ 1 | **[U]** Ritmo del parpadeo (1,15 s), apagón reducido de 0,8 s, lluvia durante el apagón | 0013 OI-7, 0014 OI-8 |
| H30 | GDD 29 Q1 | **[U]** Vistas de P2/P5 como superficies 3D del mundo (asumido) frente a `SubViewport` | 0015 OI-7 |
| H31 | GDD 29 Q7 | **[U]** Orientación del texto (espejo) | 0015 OI-8 |
| H32 | QQ-04 / ADR-0019 | **[U]** Hardware de referencia; los presupuestos siguen provisionales | 0014 OI-9, 0015 OI-4 |
| H33 | QQ-23 | **[U]** Herramienta de análisis de destellos (no se ha verificado que PEAT esté disponible) | 0014 OI-6 |
| H34 | ADR-0019 / arte | **[U]** Salida HDR (desactivada en el slice) y modo de AA | 0013 OI-5/OI-6, 0015 OI-10 |
| H35 | Arte (sin cambio de GDD) | `luz_minima_manos`, suelo plano, `sub_fondo_opacidad_min`, contrastes 7:1 / 4.5:1 | 0013 OI-2, 0016 OI-9 |

## R2.3 Contradicciones entre ADRs

Ninguna queda sin resolver. Resueltas en esta ronda:

- **Hover y foco:** el hover no movía el cursor (0007 D8.3) frente a que sí lo mueve (0006 D9, 0016). Manda 0016 y el hover mueve el foco; la G-9 de 0007 (el hover no es selección) sigue siendo compatible.
- **Cursor de 1920×1080 fijo frente al rectángulo lógico del mapper** (0006 frente a 0007 / 0011 / 0016). Manda el mapper; 1920×1080 queda como referencia 16:9.
- **`listener_position()` frente a la API cerrada del Jugador** (0008 frente a 0012). Manda 0012.
- **`configurar() -> void` frente a `ConfigureResult`** (0009 frente a 0003). Se resuelve con la consulta `configuration_failed()` de 0010.
- **`fallback_s` y `t_corte_senal_s` en `call.json`** (0005 frente a 0017). Manda 0017, en línea con los GDD 22 y 23.
- **Tabla D4 de 0009 incompleta** (faltaban 2, 3 y 6) frente a 0011 y 0012: filas ampliadas.

Quedan abiertas pero no son contradicciones: R24, R26, R28, R32 y R33 (decisiones que corresponden al ADR destino o a su historia), y las partes pendientes de R29, R30 y R31.

Nota de proceso: el hook `write-guard` avisa en cada Edit de un subagente sobre un fichero existente. Son avisos y no bloquean; las ediciones se hicieron según el modo por lotes de `CLAUDE.md`.
