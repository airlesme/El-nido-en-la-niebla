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
