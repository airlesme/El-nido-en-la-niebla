# El Nido en la Niebla — Master Architecture

## Document Status

| Campo | Valor |
|---|---|
| Version | 2 |
| Fecha | 2026-11-10 |
| Engine | Godot 4.7 (pin 4.7.2.stable; editor local del desarrollador sin registrar, ver `docs/engine-reference/godot/VERSION.md`) |
| Lenguaje / render / física | GDScript tipado · Forward+ (D3D12 por defecto en Windows desde 4.6) · Jolt |
| GDDs cubiertos | 30/30 (vía `docs/architecture/tr-baseline-provisional.md`, lectura parcial por bloque: ver «NO LEÍDO» de cada bloque) |
| Requisitos técnicos | 609 TR, ya registrados en `docs/architecture/tr-registry.yaml` (único renombrado: `TR-audio-012b` → `TR-audio-026`) |
| ADRs referenciados | ADR-0001…ADR-0017, todos `Proposed` (ADR-0002 con resultados de spike: ver su § Spike Results) |
| Revisión de arquitectura | `docs/architecture/architecture-review-2026-11-10.md`: **CONCERNS** |
| Modo | `workflow: standard`, `automation: autonomous`, densidad `balanced` |
| Fuente de verdad del slice | `design/slice/slice-v0.3.md` (prevalece sobre GDDs y sobre este documento) |

TD-ARCHITECTURE: skipped — lean mode
LP-FEASIBILITY: skipped — lean mode

> Este documento es el **maestro**: fija capas, propiedad, flujos y fronteras.
> Las decisiones concretas (formatos, firmas definitivas, mecanismos de motor)
> se cierran en los ADR listados al final. Todo lo marcado **‡ firma propuesta**
> no lo firma ningún GDD; todo lo marcado **NOT SOURCEABLE** no está cubierto por
> `docs/engine-reference/godot/` y no debe implementarse sin spike.

## Engine Knowledge Gap Summary

El modelo conoce Godot hasta ~4.3; 4.5, 4.6 y 4.7 son post-cutoff (**HIGH**).
La única fuente admitida para APIs de motor es `docs/engine-reference/godot/`
(`VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`,
`current-best-practices.md`, `modules/*.md`). Lo que no está ahí es
**NOT SOURCEABLE** y se resuelve con spike (columna «PV/NS que citan los TR»).
Riesgo: **HIGH** = el área cambió en 4.5–4.7 o el slice depende de un
comportamiento no documentado; **MED** = cambio de valores por defecto o
dependencia parcial; **LOW** = API estable y patrón citado en la referencia.

| Dominio | Riesgo | Qué cambia 4.5–4.7 según la referencia | NOT SOURCEABLE / PV citados por los TR (deduplicados, TR de origen) |
|---|---|---|---|
| **Rendering** | HIGH | 4.5 Shader Baker, SMAA 1x, stencil, bent normals, specular occlusion; 4.6 D3D12 por defecto en Windows, glow **antes** del tonemap, SSR rehecho, AgX; 4.7 `AreaLight3D`, salida HDR, líneas de `CanvasItem` sin feather, `LinearToSRGB` sin clamp, `get_format()` en `Texture2D`, `roughness_layers` 7→8 (`modules/rendering.md`, `breaking-changes.md`) | `render_priority` y orden de dibujo de transparentes (TR-shaders-004, -005); `instance uniform` en 4.7.2 (TR-shaders-006); `#include` de `.gdshaderinc` y Shader Baker con `instance uniform` (TR-shaders-007, -008); coste de `hint_screen_texture`/`hint_depth_texture` (TR-shaders-003, TR-atmos-015); glow/HDR sobre materiales `unshaded` (TR-shaders-010); `fwidth(UV)` (TR-shaders-018); técnica de manos encima del mundo y luz mínima en apagón (TR-player-010, TR-atmos-010); `Camera3D` `keep_aspect` = altura (TR-player-008); `Camera3D.is_position_in_frustum` (TR-box-010); `ReflectionProbe` y determinante negativo (TR-atmos-009, -013); monitor «Objects in frame» (TR-atmos, notas G10); presupuestos sin medir (TR-atmos-016, TR-shaders-009); filtro de daltonismo para verificación (AC-24-07, bloque G8) |
| **Physics / Jolt** | HIGH | 4.5 interpolación física 3D movida de RenderingServer a SceneTree (API igual, internos distintos); 4.6 Jolt por defecto; 4.7 signo de `WorldBoundaryShape3D.plane.d` invertido, masa de `SoftBody3D`, `Area3D` informa solapes con `SoftBody3D` (`modules/physics.md`). Patrón `CharacterBody3D` + `move_and_slide()` e `intersect_ray` citados como estables | `Area3D` como sensor de zona bajo Jolt (radio 0,02–0,05 m) y orden de entradas simultáneas (TR-scene-006, TR-player-003, TR-scene-023); consulta de forma esférica que recoja **todos** los contactos (`ShapeCast3D`/consulta de forma) (TR-interact-003; el respaldo de 7 rayos no cumple F1); comportamiento de la interpolación física 3D en 4.7 (TR-player-004); desactivación de colisión de hoja de puerta en el mismo paso (TR-access-008, sin cita de motor) |
| **Input** | HIGH | 4.5 driver de mando SDL3; 4.6 foco dual (ratón/táctil separado de teclado/mando; `grab_focus()` solo afecta al segundo); 4.7 `InputEvent.DEVICE_ID_MOUSE`/`DEVICE_ID_KEYBOARD` en lugar de `device == 0`, `VirtualJoystick`, giroscopio (`modules/input.md`) | Detección de familia de mando (`A`/`✕`) para `get_binding_label` (TR-input-018); señales de conexión/desconexión de mando (TR-title-016, TR-pause-021, TR-input-008); lectura de ejes crudos sin la zona muerta del motor (TR-input-010); pérdida de foco de ventana (TR-input-008, TR-pause-004); modo de estiramiento para el cursor virtual en 1920×1080 lógico (TR-input-011) |
| **UI / AccessKit** | HIGH | 4.5 lector de pantalla vía AccessKit en `Control`, `FoldableContainer`, desactivación recursiva; 4.6 foco dual; 4.7 `Control.accessibility_live` tipado `AccessibilityServer.AccessibilityLiveMode`, `offset_transform_*`, imágenes de `RichTextLabel` (`width_unit`), **estiramiento por defecto `canvas_items`/`expand` solo en proyectos nuevos** (`modules/ui.md`) | Interacción de la escala de UI F1 de 30 con `content_scale_mode`/`stretch` (TR-a11y-006, TR-prompt-018, TR-subs-014, TR-computer-013); propiedad de nombre accesible y orden de foco (TR-a11y-015, AC-30-16 PV; TR-computer-014); anuncio por lector de pantalla en título (OQ 10 de 27) |
| **Audio** | MED | Sin cambios de API en 4.5–4.6; 4.7 quita `AudioEffectSpectrumAnalyzer.tap_back_pos` y `area_mask` de `AudioStreamPlayer2D/3D` pasa a `0` (rompe `audio_bus_override` de `Area3D` hasta poner la capa 1) (`modules/audio.md`). Buses, `set_bus_volume_db`, `set_bus_mute`, pool de reproductores citados | `process_mode` del nodo de audio con el árbol pausado (TR-audio-001, TR-pause-002); `stream_paused` por reproductor (TR-audio-015); limitador de techo y filtros en ejecución por fuente/paso bajo (TR-audio-022, -023); detección de «sin dispositivo» en ejecución (TR-audio-019; solo `--headless` con driver ficticio está citado); memoria de streaming frente a precarga (TR-audio-021). Aviso: los volúmenes `audio_room` de TR-audio-026 (antes 012b), si se implementan con `Area3D`, chocan con el cambio de `area_mask` |
| **Animation / Tween** | HIGH | 4.5 `BoneConstraint3D`; 4.6 IK restaurado (`SkeletonModifier3D`); 4.7 `Tween.tween_await()`, `LookAtModifier3D.relative` = `false` (`modules/animation.md`). `AnimationPlayer.play` + `await animation_finished` citado | `AnimationPlayer` con `SceneTree.paused` (TR-box-015, bloquea AC-21 de 10); `Tween` en pausa / `TWEEN_PAUSE_STOP` / `PROCESS_MODE_PAUSABLE` (TR-puzzles-014, TR-atmos-018, TR-shaders-017); pausa de `GPUParticles3D` (TR-atmos-018) |
| **Core / Scene / pausa** | HIGH | 4.4 `FileAccess.store_*` devuelven `bool`; 4.5 `duplicate_deep()`; 4.6 `Quaternion` inicia en identidad; 4.7 `Object.is_class()` con `StringName`; `Time.get_ticks_msec()` sustituye a `OS.get_ticks_msec()` (`deprecated-apis.md`) | **`SceneTree.paused` y `process_mode`** (TR-pause-001/-002/-003, TR-audio-001); `SceneTree.quit()` (TR-title-009); instanciación/liberación de escenas y conteo de huérfanos `OBJECT_NODE_COUNT`/`print_orphan_nodes()` (TR-scene-009, -023); renombrado atómico y borrado de ficheros en `user://` (TR-save-004/-005, TR-settings-012/-015); SHA-256 (TR-save-002); comportamiento del parser JSON (enteros devueltos como `float`) (TR-state-015, TR-save-003, TR-puzzles-006); reloj monotónico más allá de `Time.get_ticks_msec()` (TR-save-010, TR-settings-014); `TIME` de shader con el árbol pausado (TR-shaders-017); aplicación de `modo_ventana` sin reinicio (TR-settings-018) |
| **GDScript** | MED | 4.5 argumentos variádicos (`...args: Array`), `@abstract` (clases y métodos sin cuerpo), backtrace en release; 4.7 **override de un método con retorno tipado hereda el tipo y exige `return` explícito**, escribir un elemento de un array empaquetado ya no llama al setter de la propiedad; lambdas capturan locales por valor (`current-best-practices.md`) | Ninguno NS en los TR: `@abstract` de `PuzzleController` (TR-puzzles-008) está citado. Riesgo práctico: los `PuzzleController` hijos con `evaluate() -> Verdict` deben devolver siempre (regla 4.7) |

**Consecuencia arquitectónica.** Los NOT SOURCEABLE se agrupan en cinco spikes
(pausa; Jolt sensores y consulta de forma; render de manos y orden de dibujo;
E/S atómica, hash y JSON; escala de UI y AccessKit). Ninguno se resuelve
leyendo más documentación del proyecto: se resuelven en el editor 4.7.2 y su
resultado entra en el ADR correspondiente (ver § Required ADRs, columna Spike).

## System Layer Map

Capas del índice (`design/gdd/systems-index.md`) tal cual, más una capa 0.
**Regla de dependencias:** un sistema solo depende de capas inferiores; entre
sistemas de la misma capa, la comunicación va por el bus de avisos de 3
(ver la matización por subcapas más abajo, exigida por los contratos).

```text
 CAPA 5  POLISH        ┌──────────────────────────────────────────────────────────┐
 (normas, sin módulo   │ 30 Accesibilidad  (catálogo de normas + verificación;     │
  de ejecución)        │    claves en 6, filas en 25; sin nodo propio)            │
                       └───────▲──────────────────────────────────────────────────┘
                               │ (27 → 30: dependencia documental, no de código)
 CAPA 4  PRESENTATION  ┌───────┴──────────────────────────────────────────────────┐
                       │ 27 Título ──► 25, 21, 5, 4, 3, 1, 18     28 Atmósfera ─► 2│
                       │ 25 Pausa ──► 1, 6    24 Prompt ──► 1, 7, 18               │
                       │ 26 Subtítulos ──► 3, 6, 18    29 Shaders ──► 12, 15       │
                       └───────▲──────────────────────────────────────────────────┘
                               │
 CAPA 3  FEATURE       ┌───────┴──────────────────────────────────────────────────┐
  F5 (consumidores)    │ 11 P1─►9,18,19,20  12 P2─►7,9,18  13 P3─►9,10,7          │
                       │ 14 P4─►9,10,18     15 P5─►9,10    16 P6─►9,10,18         │
                       │ 8 Acceso─►3,4,7,18,20   17 Pistas─►3,9,18                │
                       │ 21 Director─►1,3,4,18   22 Llamada─►1,3,5,7,18           │
  F4 (núcleo puzle)    │ 9 Marco ─►3,4,7,19,18  ◄══ ciclo 9⇄10 por interfaz ══►  │
                       │ 10 Caja ─►3,4,7,9                                         │
  F3                   │ 19 Ordenador ─►1,3,4,7,18,20                              │
  F2                   │ 20 Bolsillo ─►3,4,7,18                                    │
  F1 (servicio base)   │ 7 Interacción ─►1,2,4,18                                  │
                       └───────▲──────────────────────────────────────────────────┘
                               │
 CAPA 2  CORE          ┌───────┴──────────────────────────────────────────────────┐
  C3                   │ 5 Guardado ─►3,4        23 Audio ─►3,6,18                 │
  C2                   │ 4 Escena ─►3,2   ◄══ 2⇄4: 4 llama a 2; 2→4 es de datos ══►│
                       │ 2 Jugador ─►1,(4: geometría y anclas, contrato de datos)  │
  C1                   │ 6 Ajustes ─►1 (bloque `controles` opaco)                  │
                       └───────▲──────────────────────────────────────────────────┘
                               │
 CAPA 1  FOUNDATION    ┌───────┴──────────────────────────────────────────────────┐
                       │ 3 Estado + bus de avisos   1 Entrada   18 Contenido       │
                       │ (+ GameClock / pausa: módulo de la capa, ADR de pausa)   │
                       └───────▲──────────────────────────────────────────────────┘
                               │
 CAPA 0  PLATFORM      ┌───────┴──────────────────────────────────────────────────┐
                       │ Godot 4.7.2 (SceneTree, Input Map, AudioServer, Forward+)│
                       │ Jolt (física 3D) · gdUnit4 (tests) · utilidades propias  │
                       │ sin dominio: NoticeChannel, Log, validador JSON, FakeClock│
                       └──────────────────────────────────────────────────────────┘
```

**Subcapas (decisión de este documento).** Los contratos firmados en los GDDs
incluyen llamadas directas entre sistemas de la misma capa (7↔9, 9→10, 10→7,
8→20, 19→20, 9→19, 9→20, 20→7, 21→7, 17→9 en Feature; 4→2, 5→4, 23→6 en
Core). Prohibirlas contradiría 15 GDDs revisados. Se ordenan en subcapas
(C1–C3, F1–F5) y se permite la llamada **directa hacia una subcapa inferior a
través de una interfaz inyectada**; los avisos (lo que «ha pasado») siguen
yendo siempre por el bus. Ninguna llamada directa sube de subcapa.

**Ciclos aceptados y cómo se rompen en código:**

| Ciclo | Origen | Ruptura |
|---|---|---|
| 2 ⇄ 4 (ambas duras, índice) | 4 llama `colocar()` de 2; 2 necesita anclas, etiquetas de superficie y geometría de 4 | Dependencia de código solo 4 → 2. Lo que 2 toma de 4 es contrato de datos (convención espacial TR-scene-004, `player_min_passage_width_m`), sin llamada |
| 9 ⇄ 10 (circular aceptada, índice) | 10 consulta `get_view_gate()` de 9; 9 pide `play_open(n)`/`set_final_pose(n)` a 10 | Dos interfaces pequeñas: `ViewGateProvider` (implementa 9) y `BoxPresenter` (implementa 10), inyectadas por la escena de planta al configurar. Ninguno referencia la clase del otro |

**Dependencias duras frente a blandas.** Regla del índice, que este documento
adopta: **la dureza la declara el dependiente** (el proveedor solo la repite).

- **Dura:** sin el proveedor el dependiente no puede cumplir sus AC; en código
  es una referencia inyectada obligatoria o una suscripción sin la cual el
  sistema no arranca (`configurar()` falla ruidosamente en debug).
- **Blanda:** el dependiente funciona degradado (valores por defecto, aviso que
  nunca llega, fallback de texto); en código es una suscripción al bus o una
  referencia opcional con comprobación `null`.
- **Indirecta:** se acopla solo por un hecho de 3 (p. ej. 22 → 14 por
  `t4_decision`); no genera referencia de código.

Duras declaradas (resumen del índice): 2→1,4 · 4→3,2 · 5→3,4 · 6→1 ·
23→3,6,18 · 7→1,2,4,18 · 8→3,4,7,18,20 · 9→3,4,7,10,19,18 · 10→3,4,7,9 ·
11→9,18,19,20 · 12→7,9,18 · 13→9,10,7 · 14→9,10,18 · 15→9,10 · 16→9,10,18 ·
17→3,9,18 · 19→1,3,4,7,18,20 · 20→3,4,7,18 · 21→1,3,4,18 · 22→1,3,5,7,18 ·
24→1,7,18 · 25→1,6 · 26→3,6,18 · 27→1,3,4,5,18,21,25,30 · 28→2 · 29→12,15 ·
30→1,6,26 (23 solo para AC-30-11).
Blandas relevantes para la arquitectura: 1→3,4,18 (avisos de carga) ·
23→2 (señal `paso`) y a casi todo Feature por avisos · 28→3,6,25 · 26→23 ·
24→6,26 · 25→3,4,5,18.

**Incoherencias detectadas en el índice** (no bloquean; se anotan para
`/architecture-review`): la fila 6 dice «1 (blanda)» y la capa Core dice
«1 (dura de contrato)»; 27 → 30 apunta hacia una capa superior (se resuelve
tratando 30 como capa de normas sin módulo de ejecución).

**Contratos que contradicen las decisiones de partida** (y cómo se resuelven aquí):

| Decisión de partida | Contrato que la contradice | Resolución |
|---|---|---|
| Bus como único canal horizontal en Feature | 15 llamadas directas firmadas (7↔9, 9→10, 10→7, 8→20, 19→20, 9→19/20, 20→7, 21→7, 17→9) | Subcapas F1–F5 con llamadas solo hacia abajo por interfaz; avisos siempre por el bus |
| Señales de Godot solo dentro de un sistema | Señales de 2 (`gesto_terminado`, `camara_cedida`…) consumidas por 7, 8, 20; `paso` directo 2→23; `elements_changed` controlador→7 | «Señales de contrato»: permitidas de proveedor a consumidor directo cuando el GDD las firma; nunca entre iguales |
| Un mecanismo de avisos (TR-state-012) | 6 tiene aviso propio independiente del bus (TR-settings-005) | Clase compartida `NoticeChannel`, dos instancias |
| Autoloads 3, 1, 6, 5, 23, 4 | 21 persistente (TR-scene-002, TR-director-001); 28 pide autoload (TR-atmos-001) | Se añaden 21, 18 y `GameClock`; 28 queda como nodo de escena |
| `SceneTree.paused` | 23 D23-25 / TR-audio-015 y 26 OQ 8 no pausan el árbol | Compatible si 23 y 26 corren `ALWAYS` con pausa propia (QQ-06) |
| Datos validados al arrancar | 9 valida en la carga de `planta` (TR-puzzles-005) | Ambos (debug/CI al arrancar; build final según el GDD) |

## Module Ownership

Leyenda de APIs de motor: ⚠ = API o comportamiento post-cutoff (4.5–4.7) o
NOT SOURCEABLE; riesgo entre paréntesis. «Hechos» = los 20 de
`assets/data/state/flags.json`. Rutas de datos bajo `assets/data/`.

### Autoloads (lista final, decisión de este documento)

Partida: 3, 1, 6, 5, 23, 4. Lista final, en orden de registro (= orden de
construcción; la **inicialización** la hace la escena `Boot` en el orden de
§ Data Flow 4):

Lista confirmada por ADR-0009 D1. Nombre registrado = `class_name` +
`Autoload` (`ContentDBAutoload`, `GameStateAutoload`, …); solo `Boot` lo usa,
el código usa el `class_name`. `process_mode` de los nueve: `ALWAYS`
(ADR-0002, incluido `SceneDirector`).

| # | Autoload (`class_name`) | Sistema | Motivo |
|---|---|---|---|
| 1 | `ContentDB` | 18 | **Añadido.** Catálogo de solo lectura que valida 9 al arrancar y consultan 25, 26, 27 y el panel de error; debe existir antes que cualquier escena y no depender de ninguna |
| 2 | `GameState` | 3 | Hechos + bus de avisos; único canal horizontal; sobrevive a cargas (TR-scene-002) |
| 3 | `GameClock` | Pausa (ADR-0002) | **Añadido.** Único dueño de «pausa activa» y de Δ_juego; lo exigen 9 (TR-puzzles-014), 17, 19, 21, 22, 26, 28, 29 y el tope de 1. Sin él, cada sistema reinventa la pausa |
| 4 | `InputRouter` | 1 | Persistente por TR-scene-002; pila de contextos que vive entre escenas |
| 5 | `Settings` | 6 | Persistente por TR-settings-007; lo leen todos |
| 6 | `AudioDirector` | 23 | Persistente por TR-audio-001 (capas de lluvia y drone cruzan `planta`→`recepcion`) |
| 7 | `SaveService` | 5 | Inspección al arrancar y tras «descarga total completada»; el título lo consulta sin escena de juego |
| 8 | `SceneLoader` | 4 | Carga/descarga de `planta`/`recepcion`/título; posee la cortina |
| 9 | `SceneDirector` | 21 | **Añadido.** TR-scene-002 y TR-director-001 lo exigen persistente (traspasa `sin control` en el fotograma de «carga terminada», que una escena recién instanciada no garantiza) |

**Rechazados como autoload:** `Atmosphere` de 28 (TR-atmos-001 lo propone;
contradice la lista mínima: su estado es volátil y derivable de hechos, así
que vive como nodo en cada escena de juego y se reconstruye en «escena
lista»); `HintService` 17, `PauseMenu` 25, `SurfaceFx` 29, `CallController`
22 (todos los GDDs piden inyección, no singleton).

**Regla de uso (ADR-0009 D3):** `Boot` es la **única** raíz de composición y
el único que nombra autoloads; `Shell` y el `configurar(ctx)` de cada escena
reciben el `ServiceContext` ya construido. Las llamadas hacia arriba se hacen
por puertos de salida (ADR-0009 D6). 21 es un sistema F5 alojado como
autoload, que alcanza servicios de escena solo mientras está ligado (D6). El
código de sistema recibe sus dependencias por inyección, de modo que todos
los tests de `tests/unit/` sustituyen cualquier autoload por un doble.

### Árbol en ejecución

```text
root (Window)
├── ContentDB · GameState · GameClock · InputRouter · Settings      (autoloads, sin visual)
├── AudioDirector · SaveService · SceneLoader · SceneDirector       (autoloads)
└── Shell (escena principal, nunca se descarga)
    ├── WorldSlot ............ instancia única: title.tscn | planta.tscn | recepcion.tscn
    │     └── (planta) office, corridor, archive, meeting_room, guardian_office
    │           ├── Player (2) · InteractionSystem (7) · PuzzleFramework (9) + controladores 11–16
    │           ├── Access (8) · Box D01 (10) · Pocket (20) · Computer V01/V08 (19) · CallController (22)
    │           └── AtmosphereZone/Atmosphere (28) · SurfaceFx + FxTarget (29) · HintService (17)
    │     └── SceneUi (CanvasLayer 5, PAUSABLE) ... pantallas de 27 · overlay de 19 · opciones de 22
    ├── HUD (CanvasLayer 10, PAUSABLE) .... InteractionPrompt (24) · HintNote (17) · ReadingScreen (20)
    ├── PauseVeil (CanvasLayer 20, ALWAYS) .. velo + desaturación (25, fundido F3 con RealClock)
    ├── Subtitles (CanvasLayer 30, ALWAYS, sobre el velo) (26)
    ├── MenuLayer (CanvasLayer 40, ALWAYS) .. PauseMenu + OptionsComponent (25; reutilizado por 27)
    ├── CursorLayer (CanvasLayer 50, ALWAYS) .. cursor virtual (1)
    ├── Curtain (CanvasLayer 60, ALWAYS, propiedad de 4)
    └── ErrorPanel (CanvasLayer 70, ALWAYS, propiedad de 4)
```

Números de capa y `process_mode`: ADR-0016 D1 (constantes en
`src/ui/ui_layers.gd`). Liberar `title.tscn` al cargar `planta` **no** es una
«descarga» (no reinicia la pila de entrada; ADR-0003 D2).

`Shell` resuelve sin autoloads extra la persistencia de la UI (24, 25, 26) y
de la cortina entre escenas. 4 instancia en `WorldSlot` (nunca reutiliza la
instancia, TR-scene-009) en lugar de cambiar la escena raíz.

### Capa 1 — Foundation

| Sistema | Owns | Exposes | Consumes | Engine APIs (riesgo) |
|---|---|---|---|---|
| **3 Estado y bus** | 20 hechos, catálogo `state/flags.json`, cola de avisos, `max_chained_notices`, estados Sin cargar/Listo/Restaurando, `snapshot_version` | Lectura O(1), escritura validada, `write_silent` (GDD: `escribir_silencioso`), instantánea/restaurar/restablecer, `is_queue_empty()` (GDD: `cola_vacía()`), suscripción por hecho/todos/nombre; avisos «estado restablecido/restaurado», «avisos descartados», cambio de hecho | «carga de escena iniciada/lista/fallida» (4) para la ventana silenciosa | Señales tipadas o `Callable` (LOW); parser JSON enteros→`float` ⚠ (MED, TR-state-015) |
| **1 Entrada** | Pila de contextos, dueño/duración/tope de `sin control`, dispositivo activo, `carga_en_curso`, asignaciones; `input/default_bindings.json` | Acciones lógicas y gestos derivados, «dispositivo/contexto de entrada cambiado», «`sin control` absorbido», `get_binding_label`, API de reasignación ‡, exportar/importar bloque | Avisos de carga (4), «ajustes aplicados» (6), descriptores de 7 (`gestos_aceptados`, `verbo_largo`) | Input Map (LOW); `DEVICE_ID_MOUSE/KEYBOARD` ⚠ (HIGH 4.7); SDL3 ⚠; foco dual ⚠; familia de mando y señales de conexión ⚠ NS |
| **18 Contenido** | Catálogo de solo lectura (8 tipos), tabla de nombres, listas de presentación, estado Sin cargar/Cargando/Listo/Error; `narrative/*` | Texto por (id, idioma) y por fragmento/segmento, grupos de variantes, recarga atómica solo dev | Nada en ejecución; verificador lee `slice-v0.3.md` §12 | `FileAccess`/JSON (LOW–MED); sin `tr()` del motor obligatorio: capa propia de idioma (decisión ADR-0005) |
| **GameClock (módulo de pausa)** | Flag «pausa activa», Δ_juego; el tiempo real es un `RealClock` inyectable aparte (ADR-0002) | `now()`, `delta()`, `is_paused()`, `pause()/resume()`, `deadline()/is_due()`, `schedule()/cancel()` (ADR-0002) | Petición de 25 y de 1 (foco/mando) | `SceneTree.paused`, `process_mode` ⚠ NS (HIGH) |

### Capa 2 — Core

| Sistema | Owns | Exposes | Consumes | Engine APIs (riesgo) |
|---|---|---|---|---|
| **6 Ajustes** | 20 claves + bloque `controles` opaco, `settings/defaults.json`, fichero de usuario versionado, `pendiente` | Leer/escribir/restablecer; aviso de cambio propio (clave, anterior, nuevo); «ajustes aplicados»; vaciar pendientes | Bloque de 1; escrituras de 25, 27, 30; cierre del juego | `user://`, escritura atómica ⚠ NS; `DisplayServer` modo ventana ⚠ NS (MED) |
| **2 Jugador** | Cuerpo, cabeza, cámara, manos (2 ranuras), memoria de 62 poses, objeto sostenido, propietario de cámara; `player/player.json` | API cerrada de 14 operaciones (TR-player-020); señales de contrato `paso`, `gesto_terminado`, `camara_cedida/devuelta`, `objeto_sujeto/soltado` | `mover`/`mirar`, contexto (1); `balanceo_camara`, `campo_vision` (6); `colocar` (4) | `CharacterBody3D` + Jolt (MED); interpolación física 3D ⚠ (HIGH); `Camera3D` `keep_aspect` ⚠ NS; dibujo de manos ⚠ NS |
| **4 Escena** | Instancia activa, estados Sin escena/Cargando/Lista/Error, `n_ret`, `T_cap`, cortina; `scene/load_transitions.json` | Petición de carga (`destino`, `motivo`, `control_final`), descarga total, fundido `cierre`, retenciones; avisos de carga, «escena lista», «zona activada», «partida terminada», «descarga total solicitada/completada» | Peticiones de 5, 21, 25, 27; «ascensor llamado» vía 21; `reducir_movimiento` | `PackedScene.instantiate()`, `queue_free` ⚠ NS (MED); `Area3D` bajo Jolt ⚠ NS (HIGH); `CanvasLayer` (LOW) |
| **5 Guardado** | `user://saves/autosave.json` + `.prev`, `.tmp`, `.corrupt`, `.incompatible`; `seq`, base `dif`, Sellando/Sellada; `save/save-config.json` | `continuar()`, `nueva_partida()`, resultado de inspección, guardado `quit`/`dev`; «guardado en riesgo/restablecido» | 11 causas por avisos (3, 4, 9, 22, 25), instantánea/restaurar de 3 | `FileAccess` (`store_*` → `bool`, 4.4) (MED); renombrado/borrado ⚠ NS; SHA-256 ⚠ NS; reloj monotónico (LOW–MED) |
| **23 Audio** | Árbol de buses, colas de voz por canal, polifonía 24, ducking, capas persistentes, índice de marcadores; `audio/audio_catalog.json`, `audio_settings.json` | «línea iniciada/terminada/sin audio/fallida»; nada por método | «línea pedida», «sonido pedido», «feedback de puzle», «efecto de escena pedido», carga/pausa/ajustes; señal `paso` de 2 | `AudioServer` buses (LOW); `AudioStreamPlayer3D` `area_mask` ⚠ (MED 4.7); `stream_paused`, `process_mode`, limitador ⚠ NS (HIGH) |

### Capa 3 — Feature

| Sistema | Owns | Exposes | Consumes | Engine APIs (riesgo) |
|---|---|---|---|---|
| **7 Interacción** (F1) | Objetivo, retención de foco, pila de modos, lectura aplazada, tokens; `interaction/interactables.json` + schema | `registrar_manejador`, `registrar_receptor`, `abrir_vista`, `bloquear/liberar_contexto`, `abrir/cerrar_lectura`, `cerrar_modos`, `get_target`, `duracion_pie`, `modo_actual`; `ViewReceiver`, `PointerEvent`; avisos de vista/lectura, «interacción ejecutada» | Acciones de 1, señales de 2, «escena lista», hechos (`habilitado_si`), ajustes de pie | Consulta de forma esférica / `ShapeCast3D` ⚠ NS (HIGH); `intersect_ray` (LOW); máscaras de colisión (LOW) |
| **20 Bolsillo** (F2) | Conjunto de sesión (`I-01`), cursor de repaso, presentación, `A03`; `items/items.json`, `inventory_config.json` | `has_item`, `otorgar`, `otorgar_sesion`, `sostener_item`, `guardar_item`, `repasar_bolsillo`; pantalla de lectura | Avisos de lectura (7), señales de 2, `repasar_bolsillo` (1) | `Control`/`RichTextLabel` ⚠ (MED, cambios 4.7 de imágenes) |
| **19 Ordenador** (F3) | Sesión de `V01`, consulta, lista, máquina de `V08`, `hoja_en_bandeja` | `compose_i01() -> SheetI01`; receptor `ViewReceiver`; manejador de `V08`; escribe `correos_leidos` | Puntero (7), dispositivo (1), contenido (18), `has_item` (20) | `LineEdit` y teclado en pantalla con foco dual ⚠ (HIGH 4.6) |
| **9 Marco de puzles** (F4) | Estado público por puzle, fases, acumulador, `hint_level_reached`, 12 hechos con `owner = 9`; `puzzles/puzzles.json` v2 | `PuzzleFramework` (`get_view_gate`, `list_puzzles`, `get_hints`, `request_hint`), `PuzzleController` abstracto; avisos `EV_PUZZLE_SOLVED_P1..P6`, «compartimento completado», «puzle activado/inactivo», «feedback de puzle», «línea pedida», «pista aplicada», «resolución de puzle interrumpida», «puzles configurados» | Puntero y vistas (7), hechos (3), configuración (4), señales de línea (23), ajustes de asistencia (6), `has_item` (20), `compose_i01` (19) | `@abstract` ⚠ (LOW, citado 4.5); retorno tipado heredado ⚠ (MED 4.7); `Tween` en pausa ⚠ NS |
| **10 Caja** (F4) | Pose por compartimento (en memoria), cierres pendientes; anclas `ANC_D01A..D`, `SPK_D01C`; `box/box.json` | `play_open(n)`, `set_final_pose(n)`; manejadores `D01a..d` | `get_view_gate` (9), avisos de 9 y 7 | `AnimationPlayer` en pausa ⚠ NS (HIGH); `is_position_in_frustum` ⚠ NS |
| **11–16 Puzles P1–P6** (F5) | Estado interno en memoria del controlador (colocación, θ, fichas, botones) | Subclases de `PuzzleController` (`evaluate() -> Verdict` puro) | `PointerEvent`, `GameClock`, ajustes, `compose_i01` (P1) | P2/P5 dependen de 29 (shaders ⚠); P5 audio 3D desde `SPK_D01C` (MED) |
| **8 Acceso** (F5) | Estados derivados de puertas A/B/D, lectores, cajón `A05`, ascensor `C08`; `access/access.json` | Manejadores `C06`, `C07`, `D06`, `C08`, `A05`; avisos «puerta abierta», «ascensor llamado», «línea pedida» `MEGA_03` | Hechos, «ascensor rechazado», señales de 2 | Colisión de hoja ⚠ (MED, Jolt); `AnimationPlayer`/`Tween` en pausa ⚠ NS |
| **17 Pistas** (F5) | `HintLedger` por puzle (en memoria); `hints_policy.json` | `HintPanel` (alojado por 25), `HintNote`; registro de proveedor de panel ‡ | Avisos de 9 y 7, `correos_leidos` | `Control` (MED, foco dual) |
| **21 Director** (F5, autoload) | Escenas armadas, relojes `t_rel`, estado volátil (`apagon_activo`…); `scenes/scenes.json`, `scene-config.json` | Solo bus: «línea pedida», «efecto de escena pedido» ‡, «estado de objeto pedido» ‡, «tarjeta final pedida» ‡, «ascensor rechazado» | Avisos de 4, 7, 8, 9, 22, 23, 1; hechos | Ninguna específica salvo `process_mode` ⚠ NS |
| **22 Llamada** (F5) | Máquina de 10 estados, cuenta de espera, foco de opciones, estado de `V02`; `call.json` ‡ | Manejador `V02`/`Descolgar`; avisos «llamada iniciada/completada»; escribe `llamada_iniciada`, `respuesta_llamada`, `llamada_completada` | «estado de objeto pedido», señales de línea, pausa, hechos | Cursor oculto (1) ⚠ foco dual (MED) |

### Capa 4 — Presentation y capa 5 — Polish

| Sistema | Owns | Exposes | Consumes | Engine APIs (riesgo) |
|---|---|---|---|---|
| **24 Prompt** | Pie actual/retenido, último pulso; `ui/prompt.json` | `mostrar_pie`, `ocultar_pie` | `get_target()` por fotograma, «interacción ejecutada», glifos de 1, ajustes, banda de 26 | Escala de UI ⚠ NS (HIGH); líneas de `CanvasItem` 4.7 ⚠ (anillo) |
| **25 Pausa** | Máquina de 7 estados, `guardado_en_riesgo`; `ui/pause.json` | «pausa abierta» `pause_opened`, «pausa cerrada» `pause_closed`; `OptionsComponent.mostrar()` + `cerrado` | Entrada (`menú`), ajustes, avisos de 5, panel de 17 | `process_mode` ⚠ NS; foco dual ⚠; AccessKit ⚠ |
| **26 Subtítulos** | Bloques visibles, cola de 1, relojes por bloque | Solo `alto_reservado_px` | Avisos de línea/sonido de 23 y 9/21/22, pausa, carga, ajustes, 18 | Relojes propios (LOW); escala de texto ⚠ NS |
| **27 Título** | Lista de filas, aviso de sesión | Ninguna | Resultado de inspección (5), «tarjeta final pedida» (21), carga (4), ajustes | `SceneTree.quit()` ⚠ NS; señales de mando ⚠ NS |
| **28 Atmósfera** | `LightState` por zona, lluvia, reflejo retardado, limitador de destellos; `atmosphere/atmosphere.json` | Ninguna con firma (hueco) | «efecto de escena pedido», `EV_PUZZLE_SOLVED_*`, hechos, pausa, ajustes; `pose_con_retardo`, `giro_acumulado` (2) | `Light3D`, `GPUParticles3D` (MED), `Tween`/partículas en pausa ⚠ NS, `ReflectionProbe` ⚠ NS, glow 4.6 ⚠ |
| **29 Shaders** | `frag_alpha`, envolventes, θ; `assets/shaders/*.gdshader`, `fx_config.tres` | `SurfaceFx` ‡ (10 operaciones), `FxTarget`; constante `reflection_strength_max` | Órdenes de 9, 12, 15; ajustes | `render_priority`, `instance uniform`, `#include`, Shader Baker ⚠ NS (HIGH) |
| **30 Accesibilidad** (Polish) | Nada en ejecución: normas, catálogo de claves (en 6), verificación (`tools/`) | Ninguna | Claves de 6, `controles` de 1 | AccessKit ⚠ (HIGH, 4.5/4.7) |

### Propiedad de hechos (escritor único)

| Escritor | Hechos |
|---|---|
| 9 Marco | `archivo_abierto`, `memo_leido`, `pos_L`, `pos_C`, `pos_R`, `caja_c1`–`caja_c4`, `pendiente_revelacion`, `carta_variante`, `t4_decision` |
| 20 Bolsillo | `formulario_leido`, `tarjeta_B`, `tarjeta_D` |
| 19 Ordenador | `correos_leidos` |
| 22 Llamada | `llamada_iniciada`, `respuesta_llamada`, `llamada_completada` |
| 3 Estado (derivado) | `caja_completa` |

Ningún otro sistema escribe hechos (comprobación de `owner` en builds de
desarrollo, TR-state-005).

## Data Flow

Tipos de acoplamiento: **SYNC** = llamada directa a una interfaz inyectada
(devuelve en el acto); **AVISO** = bus de 3 (encolado, sin reentrada);
**SEÑAL** = señal de contrato de un proveedor inferior a su consumidor directo;
**ESTADO** = lectura de un hecho o ajuste compartido (sin aviso);
**SONDEO** = lectura por fotograma.

> El orden interno del bucle principal de Godot (`_input`, `_physics_process`,
> `_process`, render) es **NOT SOURCEABLE — no cubierto por
> `docs/engine-reference/godot/`**. Por eso los «mismo fotograma» de los GDDs se
> garantizan con orden explícito (cola del bus, secuencias síncronas de 4 y 9),
> nunca confiando en el orden de callbacks entre nodos.

### 1. Ruta de fotograma: entrada → jugador → interacción → estado → render

```text
 evento de SO ─► InputRouter (1) ── acciones lógicas a la CIMA de la pila ─────────────┐
                    │  SYNC/SEÑAL: mover, mirar → Player (2)                          │
                    │  SYNC: interactuar/leer/seleccionar/rotar → Interaction (7)      │
                    ▼                                                                 │
 paso de física 60 Hz:  Player (2): v = move_toward(...); move_and_slide() [Jolt]     │
                        Interaction (7): barrido esférico desde rayo_vision()         │
                                         ESTADO: habilitado_si (lee hechos de 3, O(1)) │
                                         SYNC: handler.can_interact(verbo) (puro)     │
 al pulsar:             7 reserva gesto en 2 (SYNC) ─► handler.interact(verbo, ctx)    │
                        handler (8, 9, 10, 19, 20, 22) escribe SU hecho en 3 (SYNC)    │
                        3 aplica en el acto, recalcula derivados, encola aviso         │
                        bus entrega (AVISO) ─► 5, 8, 21, 23, 28, 26 …                  │
 por fotograma (render): 24 SONDEO get_target() de 7; cámara/manos con pose           │
                        interpolada de 2; 26 dibuja bloques; 28/29 Tweens/shaders      │
 render Forward+  ◄────────────────────────────────────────────────────────────────────┘
```

| Dato | Productor | Consumidor | Tipo |
|---|---|---|---|
| `mover` (Vector2), `mirar` (Δyaw, Δpitch) | 1 | 2 | SYNC por fotograma (mirada) / paso de física (movimiento) |
| `rayo_vision()` (estado de física, sin balanceo) | 2 | 7 | SYNC en paso de física |
| `habilitado_si` | 3 | 7 | ESTADO (~35 objetos por paso, TR-state-002) |
| Objetivo `{id, etiqueta, largo, p, anillo_visible}` | 7 | 24 | SONDEO (TR-prompt-001; el objetivo no viaja por el bus) |
| `paso(superficie, intensidad)` | 2 | 23 | SEÑAL directa (alta frecuencia, TR-player-017) |
| «interacción ejecutada» (id, verbo, `resultado`) | 7 | 24, 21, 23, 28 | AVISO |

### 2. Ruta de avisos y hechos

```text
 escritor (dueño) ──escribir(hecho, v)──► GameState (3)
                                           │ valida tipo/rango/owner/sentido
                                           │ aplica YA (lectura siguiente = v)
                                           │ recalcula derivados (caja_completa)
                                           ▼
                                  cola FIFO de avisos ──► entrega en orden de
                                  (tope 64; si se         ocurrencia y de suscripción
                                   supera: «avisos        (sin reentrada: lo emitido
                                   descartados» → 5)       durante una entrega se encola)
 emisor de aviso con nombre ──notify(nombre, carga)──┘
```

- **Hechos:** el cambio genera un aviso automático (nombre, anterior, nuevo)
  solo si el valor cambia. `caja_completa` se avisa **después** de `caja_c4`.
- **Avisos con nombre:** el contrato es la tabla de la regla 10 del GDD 3
  (`EV_PUZZLE_SOLVED_<ID>`, «puerta abierta», «línea pedida», «sonido pedido»,
  `pause_opened`/`pause_closed`, «línea iniciada», …). No son persistentes:
  quien no esté suscrito los pierde.
- **Ajustes (6)** tienen un canal propio con la **misma semántica** (TR-settings-005/-006),
  no el bus de 3, porque 6 no depende de 3. Se cumple TR-state-012 («un único
  mecanismo») con **una clase compartida** `NoticeChannel` (capa 0)
  instanciada dos veces: una en 3 y otra en 6.
- **Escritura silenciosa:** solo 9, solo hechos reversibles, solo entre «carga
  de escena iniciada» y «escena lista»; no emite.
- **Orden de resolución de puzle** (TR-puzzles-011): `on_solved.write` en orden
  → `solved_flag` → `RESUELTO` → `EV_PUZZLE_SOLVED_<ID>` → «compartimento
  completado» (n) → presentación no bloqueante → `cerrar_vista(resuelto)`.

### 3. Guardado y carga

**Qué se serializa:** solo el mapa de los 20 hechos + `snapshot_version`
(TR-save-015, TR-state-013). Nada de posición, temporizadores, pistas,
estado interno de puzles, ítems de sesión ni ajustes (6 tiene fichero propio).
**Quién:** 5 pide la instantánea a 3 y escribe; 3 no toca disco.

```text
 causa (aviso) ─► SaveService (5): ¿estado En partida? ¿causa activa? ──► agrupar t_agrupar 0,1 s
                                                                  (urgentes: sin agrupar)
              ─► ¿3.cola_vacía()? no → reintenta el fotograma siguiente   (nunca estado a medias)
              ─► instantánea (SYNC) ─► ¿dif con base_dif? no → nada
              ─► fichero v<N> + checksum + cuerpo JSON (seq, saved_at_utc, build, cause, snapshot)
              ─► tmp → releer/validar → validar principal → borrar prev → json→prev → tmp→json
              ─► fallo: backoff 2 s…30 s; 3 fallos → «guardado en riesgo»; éxito → «restablecido»
```

| Estado de 5 | Entra por | Comportamiento |
|---|---|---|
| Sin inspeccionar → Sin partida | Arranque | Inspección de solo lectura (hasta 3 candidatos, mayor `seq` válido) |
| Cargando partida | `continuar()` / `nueva_partida()` | Ignora causas (no las encola) |
| En partida | «carga de escena terminada» | Guarda por causas |
| **Sellando** (subestado) | `call_started` («llamada iniciada») | Captura en el primer instante con cola vacía; los reintentos escriben ese contenido capturado |
| **Sellada** | Escritura sellada correcta | Solo admite `slice_completed` (reescribe con `completed = true`); el resto se ignora |

- **`continuar()`**: instantánea migrada → 3 restaura (síncrono, atómico) →
  «estado restaurado» → base `dif` y `seq` → 4 carga `planta` (`reanudar`,
  `control_final = exploracion`) → En partida al «carga terminada».
- **`nueva_partida()`**: 3 restablece → «estado restablecido» → base `dif` =
  estado restablecido → 4 carga `planta` (`partida_nueva`,
  `control_final = ninguno`); no borra el fichero; rechazada en carga, Sellando y Sellada.
- **Reconstrucción al cargar:** cada dueño reconstruye su presentación desde
  hechos en la secuencia de configuración de 4 (7 → 9 → 8, 10, 20 …), sin avisos.

### 4. Arranque: autoloads y escena inicial

```text
 1 construcción de autoloads (sin E/S): ContentDB, GameState, GameClock, InputRouter,
   Settings, AudioDirector, SaveService, SceneLoader, SceneDirector
 2 escena principal Shell → nodo Boot ejecuta, en este orden y de forma síncrona:
   a ContentDB.load(narrative/*)            Error → mensaje de fallo de carga, no entra
   b GameState.load(state/flags.json)       ausente/corrupto → error y cierre (CA-26)
   b' GameClock.setup(ctx)                  no lee nada; now() = 0 (ADR-0009 D2, paso 3)
   c DataValidator (debug y CI): los ficheros del registro canónico de ADR-0005 D1
     → fallo ruidoso en debug
   d InputRouter.load(input/default_bindings.json)  (se suscribe a «ajustes aplicados»)
   e Settings.load(defaults.json + fichero de usuario) → Listo → «ajustes aplicados»
       → 1 importa `controles`; 23 fija buses sin rampa
   f AudioDirector.start()  (tras 3 y 6)
   g SceneLoader.validate(load_transitions.json)   inválido → DATOS_ESCENA_INVALIDOS
   h SceneDirector.load(scenes.json, scene-config.json)  (escenas inválidas se descartan)
   i SaveService.inspect()  → resultado para 27
 3 SceneLoader instancia title.tscn en WorldSlot → 27: advertencias o menú
```

Fallos fatales de catálogo (`CATALOGO_INVALIDO`, `DATOS_ESCENA_INVALIDOS`,
parámetros de 2) van a un **manejador de error fatal inyectado** (TR-settings-019),
que en debug detiene y en build final muestra el panel de 4/27 sin cerrar la app.

> **Choque con los GDDs:** 9 valida `puzzles.json` en la configuración de
> `planta` y su fallo es un fallo de carga de 4 (TR-puzzles-005, TR-scene-011),
> no un fallo de arranque. Se mantienen ambos: el paso 2c es una comprobación
> adicional de esquema solo en debug/CI; el comportamiento de build final sigue
> siendo el del GDD 9.

### 5. Secuencias

**Carga de escena (4)**, base de todo lo demás:

```text
 petición(destino, motivo, control_final) ─► «carga de escena iniciada»(destino, motivo, D_carga)
   ─► 4 abre `sin control`(4, D_carga) en 1 (SYNC, justo tras emitir «iniciada»; ADR-0003 D6) ─► cortina a α=1 ─► descarga (1 reinicia pila a [sin control])
   ─► instanciar en WorldSlot ─► 2.colocar(ancla) ─► configurar 7 → 9 → 8, 10, 20 … (SYNC, mismo fotograma)
   ─► n_ret = 0 ─► «escena lista» ─► N_gap fotogramas ─► aclarado ─► «carga de escena terminada»
       control_final = exploracion → 4 pide `exploración`
       control_final = ninguno     → 4 traspasa `sin control` a 21 en ese mismo fotograma
 fallo (T_cap 10 s, validación) ─► «carga de escena fallida» ─► cortina negra + «Volver al título»
```

**Escena dirigida (21)**: disparador (aviso de zona, hecho o «escena lista»)
→ comprueba `condiciones` (ESTADO) → si es dirigida, recibe el traspaso de
`sin control` (duración `t_fin + h_decl_s`) → reloj `t_rel` en tiempo de juego
→ órdenes vencidas por el bus (AVISO): «línea pedida», «efecto de escena
pedido» ‡, «estado de objeto pedido» ‡ → en `t_fin` pide `exploración`. Si el
traspaso se rechaza, degrada a «momento» sin reintentar. `ESC8_CIERRE`:
`cerrar_modos()` (SYNC a 7, tope 2 s) → líneas → fundido → «tarjeta final
pedida» → descarga total (SYNC a 4).

**Llamada (22)**:

```text
 21: V02 «vibrando» (estado de objeto pedido) ─► jugador: Descolgar ─► 22.interact (mismo fotograma):
   a escribe llamada_iniciada + «llamada iniciada»  ──► 5 Sellando (call_started)
   b pide contexto `llamada` a 1   c V02 = en_llamada   d DESCOLGANDO
 ─► SILENCIO ─► RESPIRACION ─► LINEA («línea pedida» VO_G_12<carta_variante>)
 ─► ANTES_OPCIONES ─► OPCIONES (guarda 0,6 s; espera 20 s → SENAL una vez)
 ─► elección: escribe respuesta_llamada ─► RESPUESTA (VO_G_13<A-D>)
 ─► CIERRE: SFX_PHONE_END, llamada_completada + «llamada completada», HAND_PHONE_PUTDOWN
 ─► libera `llamada` ─► COMPLETADA     (todo en GameClock; la pausa congela máquina y audio)
```

**Pausa** (ADR-0002, opción A validada por spike salvo S4 manual; 25 corre `ALWAYS` con `RealClock`):

```text
 apertura: `pausa` | pérdida de foco | desconexión del mando activo   (1 decide; nunca con carga_en_curso)
   ─► 25 pide contexto `menú` a 1 ─► GameClock.pause()  [SceneTree.paused = true + process_mode explícito]
   ─► 25 llama a 6 «vaciar pendientes» (SYNC, no bus) ─► «pausa abierta» (pause_opened)
        → 5 guarda (pause_opened) · 23 pausa voces/puntuales, lazos a −6 dB · 26 congela relojes
 cierre: 25 restaura contexto ─► GameClock.resume() ─► «pausa cerrada» (pause_closed) → 24 re-resuelve glifos
 «Volver al título» desde la pausa (orden «solicitada → completada → pausa cerrada»):
   5 guardado `quit` (SYNC, urgente) ─► 4 «descarga total solicitada» ─► descarga ─► 1 repone `menú`
   ─► «descarga total completada» (5 re-inspecciona, 21 borra volátil) ─► «pausa cerrada» (normaliza el reloj)
```

### 6. Hilos

Todo el código de juego corre en el **hilo principal**. El único TR que habla
de hilos es **TR-save-006**: la E/S de guardado es síncrona en el hilo
principal en el slice, y moverla a un hilo obliga a revisar `quit` y la regla
16 de 5. Ningún TR pide carga de escena en hilo; si 4 la necesitara por
`T_cap`, la carga en segundo plano de recursos es **NOT SOURCEABLE — no
cubierta por `docs/engine-reference/godot/`** y requiere ADR. Los hilos
internos del motor (mezcla de audio, render, física de Jolt) no son código del
proyecto y su comportamiento interno es igualmente NOT SOURCEABLE.

## API Boundaries

Pseudocódigo GDScript tipado. Los nombres que firma un GDD se escriben tal
cual (aunque estén en español: son IDs de contrato). **‡ firma propuesta** =
ningún GDD la firma; la fija el ADR indicado y puede cambiar. Los tipos
`Dictionary`/`Variant` marcan cargas útiles cuyo esquema está en el GDD citado.

### Bus y estado (3) — ADR-0001

```gdscript
# ‡ Todos los nombres de método: el GDD 3 deja el formato técnico a un ADR (TR-state-012).
class_name GameState extends Node
enum Status { SIN_CARGAR, LISTO, RESTAURANDO }
var snapshot_version: int                                        # solo lectura, inicial 1

func get_fact(name: StringName) -> Variant                       # ‡ «lectura de hecho», O(1), sin asignaciones
func set_fact(name: StringName, value: Variant, writer: StringName) -> bool   # ‡ «escritura validada»
func write_silent(name: StringName, value: Variant) -> bool      # GDD: escribir_silencioso (ADR-0001 G-13)
func is_queue_empty() -> bool                                    # GDD: cola_vacía() (ADR-0001 G-13)
func request_snapshot() -> Dictionary                            # ‡ {} = «no disponible» si hay cola
func restore(snapshot: Dictionary) -> void                       # ‡ síncrona y atómica
func reset_new_game() -> void                                    # ‡ «partida nueva (restablecer)»
func notify(notice: StringName, payload: Dictionary = {}) -> void            # ‡ aviso con nombre
func subscribe_fact(name: StringName, cb: Callable) -> int       # ‡ cb(name, old, new)
func subscribe_all(cb: Callable) -> int                          # ‡
func subscribe_notice(notice: StringName, cb: Callable) -> int   # ‡ cb(payload)
func unsubscribe(handle: int) -> void                            # ‡ efectiva al terminar la entrega en curso
```

Invariantes: escritura aplicada en el acto aunque se esté entregando; aviso
solo si el valor cambia; FIFO sin reentrada; tope `max_chained_notices`
(64; 8–256, en datos) → descarta cola + «avisos descartados»; suscriptor
liberado con su escena no produce error (CA-17: el canal comprueba
`is_instance_valid` del objeto del `Callable`); `owner` comprobado solo en
debug; en build final una escritura inválida se ignora con una línea de log.
Garantía: tras «estado restaurado» todo lector ve ya el estado nuevo.

### Entrada (1) — ADR-0006

> Boceto v1. Las firmas vigentes son las de ADR-0006 § Key Interfaces
> (operaciones de `sin control` D4, reasignación D11; QQ-16 cerrada).

```gdscript
class_name InputRouter extends Node
enum Context { EXPLORACION, INSPECCION, LECTURA, VISTA_CERCANA, ORDENADOR, LLAMADA, MENU, SIN_CONTROL }  # ‡ identificadores
signal dispositivo_de_entrada_cambiado(device: int)              # ‡ nombre de señal; aviso del GDD
signal contexto_de_entrada_cambiado(prev: Context, next: Context)

func entrar_en(ctx: Context, requester: StringName) -> bool      # «entrar en» contexto (‡ firma)
func salir_de(ctx: Context, requester: StringName) -> bool       # rechaza si no es la cima (log)
# Pila `sin control` (operaciones del GDD 1; firmas ‡)
func sin_control_abrir(owner: StringName, duration_s: float) -> bool
func sin_control_cerrar(owner: StringName) -> bool              # solo el dueño
func sin_control_traspasar(new_owner: StringName, new_duration_s: float) -> bool  # sin salir ni avisar; renueva tope
func pedir_exploracion(owner: StringName) -> bool
func reponer_menu() -> void
func get_binding_label(accion: StringName, dispositivo: int) -> Dictionary  # nombre del GDD; {tipo, texto, glifo_id} | {} = nulo
func export_bindings() -> Dictionary                             # ‡ bloque opaco para 6
func import_bindings(block: Dictionary) -> void                  # ‡ tolerante
func es_imprimible(entrada: InputEvent) -> bool                  # ‡ pedido por 25 (TR-pause-017)
func rebind(accion: StringName, dispositivo: int, slot: int, ev: InputEvent) -> Dictionary  # ‡ API de reasignación
```

Invariantes: solo la cima recibe acciones; `sin control` tiene siempre dueño
y duración (sin duración: 3 s con log); tope = duración + 2 s y se detiene con
la pausa; al vencer: log + liberar (pila vacía → `exploración`); descartar
la pila al aceptar carga `partida_nueva`/`reanudar` emite «`sin control`
absorbido»; `carga_en_curso` bloquea la pausa; `get_binding_label` es pura y
determinista (primera asignación por orden de alta), sin aviso.

### Interacción (7) — ADR-0011

```gdscript
enum InteractResult { SI, NO, SIN_EFECTO }                       # retorno de can_interact (GDD 7)
enum InteractOutcome { HECHO, SIN_EFECTO }                       # retorno de interact
enum Resultado { HECHO, SIN_EFECTO, GESTO_RECHAZADO, TOQUE_CORTO }  # carga de «interacción ejecutada»

# Manejador por ID (registrado antes de «escena lista»)
func can_interact(verbo: StringName) -> InteractResult           # pura y barata (por paso de física)
func etiqueta(verbo: StringName) -> StringName                   # clave de 18 | &"" = nulo
func interact(verbo: StringName, contexto: Dictionary) -> InteractOutcome

# InteractionSystem
func registrar_manejador(id: StringName, manejador: Object) -> void
func registrar_receptor(vista_id: StringName, receptor: ViewReceiver) -> void
func abrir_vista(vista_id: StringName, desde_token: int = -1) -> Dictionary   # {ACEPTADA} | {RECHAZADA, motivo}
func bloquear_contexto(razon: StringName) -> int                 # token | -1 = nulo; solo dentro de interact()
func liberar_contexto(token: int) -> void                        # idempotente
func cerrar_vista(vista_id: StringName, motivo: StringName) -> void
func abrir_lectura(doc_id: StringName) -> Dictionary             # {ACEPTADA | APLAZADA | RECHAZADA, motivo}
func cerrar_lectura(motivo: StringName) -> void
func cerrar_modos() -> void                                      # emite una vez «modos cerrados»
func get_target() -> Dictionary                                  # {id, etiqueta, largo, p, anillo_visible} | {}
func duracion_pie(clave: StringName) -> float                    # PIE_PERSISTENTE = -1.0 (ADR-0011; no INF)
func modo_actual() -> int                                        # NINGUNO, INSPECCION, LECTURA, VISTA, ORDENADOR

@abstract class_name ViewReceiver extends RefCounted              # puerto (ADR-0011)
@abstract func elements() -> Array[ViewElement]                 # {id, forma, z_orden, atraccion}
@abstract func handle_pointer(ev: PointerEvent) -> void
@abstract func on_open() -> void
@abstract func on_close(motivo: StringName) -> void
# PointerEvent = {gesto, fase, elemento, elemento_bajo, pos_px, pos_vista, delta_px, delta_grados}
```

Invariantes: 7 reserva el gesto de 2 **antes** de `interact()` (si 2 rechaza,
no se llama); tope único de bloqueo 3 s de tiempo de juego; `T_cadena ≤ 2,8 s`;
respuesta a toda pulsación ≤ `latencia_feedback_ms` 100 ms; un gesto = un
aviso «interacción ejecutada»; 7 no persiste nada. `elemento_bajo` en
`seleccionar`: lo fija ADR-0011 (un solo `FIN`; `elemento_bajo` = pick al soltar).

### Marco de puzles (9) y `puzzles.json` v2 — ADR-0010

```gdscript
enum PublicState { BLOQUEADO, ACTIVO, RESUELTO }
class Verdict:                                                   # NONE | HOLDING | PARTIAL(progress) | REJECT | SOLVED(carga)
    var kind: int
    var payload: Dictionary   # PARTIAL {progress, element?, action?} (ADR-0010 D3) · SOLVED {choice | t4_action}

@abstract class_name PuzzleController extends Node
@abstract func configure(def: Dictionary, flags: Dictionary) -> void
@abstract func on_open() -> void
@abstract func on_close(motivo: StringName) -> void
@abstract func elements() -> Array[ViewElement]
@abstract func handle_pointer(ev: PointerEvent) -> void
@abstract func handle_activation(element_id: StringName, verb: StringName) -> int
@abstract func cancel_gesture() -> void
@abstract func evaluate() -> Verdict                             # PURA: sin tiempo ni acumulador
@abstract func reset_attempt(scope: StringName, element: StringName) -> void
@abstract func play_resolution(step: Dictionary) -> void
@abstract func restore_solved_presentation() -> void
@abstract func apply_hint_effect(effect: Dictionary) -> bool
signal elements_changed(tag: StringName)

# PuzzleFramework (implementa ViewGateProvider)
func get_view_gate(view_id: StringName) -> Dictionary  # {state: OPEN|BLOCKED|SOLVED, missing_items, feedback_sfx, feedback_text_key}
func list_puzzles() -> Array[Dictionary]               # + estado, mode, vista, último compromiso, hint_level_reached, first_action ‡
func get_hints(id: StringName) -> Array[Dictionary]
func request_hint(id: StringName, level: int) -> int   # HintOutcome; aplicado = `!= REFUSED` (ADR-0010)
```

```json
{ "schema_version": 2,
  "puzzles": [ { "id": "P1", "solved_flag": "archivo_abierto", "mode": "VIEW", "view": "C05",
                 "requires": { "all": [] }, "needs_items": ["I-01"], "validation": { "policy": "DELAYED_AFTER_CHANGE" },
                 "solution": { "sequence": [2,1,3,4] }, "on_reject": {}, "on_solved": { "write": [], "close_view_after_s": 1.5 },
                 "persist": [], "hints": [] } ] }
```

Invariantes: otra `schema_version` = fallo de validación; enteros convertidos
explícitamente a `int`; el controlador **nunca** escribe hechos ni emite
avisos (no recibe referencia de escritura); estados públicos monótonos;
`SOLVED` idempotente por fotograma; todo temporizador en `GameClock`
(prohibido `SceneTreeTimer`/`create_timer`); `on_reject ≤ lock_max_s` 2,0 s;
fallo de validación en build final = fallo de carga de 4, nunca puzle inactivo.
`has_item`, `compose_i01` y `get_view_gate`: firmas fijadas en ADR-0010
(`missing_items` es una lista).

### Guardado (5) — ADR-0004

> API vigente: ADR-0004 D11 (cierra QQ-17 para 5). El boceto se mantiene como resumen.

```gdscript
enum Inspection { NINGUNA, VALIDA, IRRECUPERABLE, VERSION_FUTURA }
func continuar() -> bool                                         # nombre del GDD
func nueva_partida() -> bool                                     # rechazada en carga, Sellando y Sellada
func get_last_inspection() -> Dictionary                         # ‡ {result: Inspection, con_futura: bool, terminada: bool}
func request_save(cause: StringName) -> void                     # ‡ para `quit` (síncrono, urgente) y `dev`
```

Invariantes: una ranura; nunca renombra sobre un fichero existente; checksum
sobre los bytes exactos del cuerpo; `seq` decide el más reciente (nunca el
reloj); solo escribe si `dif`; nunca captura con la cola de 3 llena; garantía
total ante cierre de proceso, mejor esfuerzo ante corte de energía.

### Ajustes (6) — ADR-0007

```gdscript
func get_setting(key: StringName) -> Variant                     # ‡ siempre un valor válido
func set_setting(key: StringName, value: Variant) -> bool        # ‡ float cuantizado a rejilla, clamp + log
func reset_setting(key: StringName) -> void                      # ‡ «restablecer un ajuste»
func reset_all() -> void                                         # ‡ 18 claves; excluye modo_ventana, advertencias_vistas, controles
func flush_pending() -> void                                     # ‡ «vaciar pendientes» (25, llamada directa)
func subscribe_change(cb: Callable) -> int                       # ‡ cb(key, old, new); `controles` solo clave
func subscribe_applied(cb: Callable) -> int                      # ‡ «ajustes aplicados»
```

Invariantes: entra en Listo **antes** de emitir «ajustes aplicados»; sin
avisos en Cargando; guardado diferido 0,5 s / 5,0 s con reloj monotónico real;
escritura atómica; ilegible → valores iniciales + copia `.corrupt` única.

### Audio (23) — ADR-0008

Interfaz = bus de 3 (el GDD 23 no declara métodos). Cargas útiles:

```gdscript
# consumidos
# «línea pedida»   {line_id: StringName, fuente: StringName?, fallback_s: float?, puzzle: StringName?}   solo IDs de 18
# «sonido pedido»  {sound_id: StringName, fuente: StringName?, accion: play|stop|set|interrupt, valor: float?}  solo SFX_*
# emitidos (exactamente uno por «línea pedida» aceptada, como aviso encolado ≤ 1 fotograma)
# «línea iniciada»  {line_id, duracion_s, canal}            (opcional; 26 degrada sin ella)
# «línea terminada» {line_id, motivo: fin|corte|watchdog|interrumpida}
# «línea sin audio» {line_id, t_lectura_s} · «línea fallida» {line_id, t_lectura_s}
func on_paso(superficie: StringName, intensidad: float) -> void  # ‡ receptor de la señal directa de 2
```

Invariantes: 3 canales de voz por prefijo con cola de 1 y tope
`t_cola_canal_s` 8 s; techo `fallback_s + line_grace_s`; nunca se queda sin
responder (watchdog); `sound_id` desconocido se ignora con log.

### Escena (4) — ADR-0003

```gdscript
enum Destino { PLANTA, RECEPCION }  ; enum Motivo { PARTIDA_NUEVA, REANUDAR, RECEPCION }
enum ControlFinal { EXPLORACION, NINGUNO }
func request_load(destino: Destino, motivo: Motivo, control_final: ControlFinal) -> bool   # ‡ «petición de carga»
func request_full_unload() -> bool                              # ‡ «descarga total»
func request_fade_out(motivo: StringName = &"cierre") -> void    # ‡ fundido propio
func take_hold(holder_id: StringName) -> void                    # ‡ retención idempotente
func release_hold(holder_id: StringName) -> void                 # ‡ doble liberación no baja de 0
# elementos de escena: func configurar(ctx: ServiceContext) -> void   (`configurar()` del GDD; parámetro ‡)
# Jugador: colocar(posición: Vector3, yaw: float, pitch: float) -> void   (firma del GDD 2)
```

Invariantes: una sola escena de juego; precondición 3 Listo y sin otra carga;
cada `planta` es una instancia nueva; «escena lista» ⇔ `n_ret = 0`; `T_cap`
en tiempo real sin escalar; nunca aclara una escena a medias ni cierra la
aplicación; 4 es el único emisor de «partida terminada» y «descarga total
completada»; no escribe hechos (solo lee `llamada_completada`).

### Pausa — ADR-0002

```gdscript
class_name GameClock extends Node                                # autoload #3, ALWAYS (ADR-0002)
signal paused_changed(is_paused: bool)                           # solo infraestructura; juego usa el bus
func configure(backend: PauseBackend, max_frame_delta_s: float) -> void   # solo Boot
func now() -> float                  # segundos de juego acumulados (no avanza en pausa)
func delta() -> float                # Δ_juego del fotograma (0 en pausa)
func is_paused() -> bool
func pause(requester: StringName) -> void
func resume(requester: StringName) -> void
func deadline(after_s: float) -> float
func is_due(deadline_s: float) -> bool
func schedule(after_s: float, callback: Callable) -> int        # NO_HANDLE = -1
func cancel(handle: int) -> void

class_name RealClock extends RefCounted                          # tiempo real inyectable (UI de pausa, T_cap, reintentos)
func now_ms() -> int
# Contrato de 25 (GDD): emite «pausa abierta» (`pause_opened`) tras entrar en `menú` y marcar pausa;
# «pausa cerrada» (`pause_closed`) después de restaurar contexto y reanudar el tiempo.
```

Invariantes: Δ_juego = 0 desde el fotograma de apertura; siguen en tiempo
real UI de pausa, guardado diferido de 6, reintentos de 5, captura de 8 s,
muestra de volumen de 23 y `T_cap` de 4; ningún sistema de juego usa
`SceneTreeTimer`. Todo lo que corre en pausa lee `RealClock`, nunca
`GameClock`. Spike 2026-11-10 (ADR-0002 § Spike Results): opción A se
mantiene; S4 (foco con teclado/mando en pausa, desconexión del mando) queda
pendiente de registro manual.

## ADR Audit

Existen ADR-0001…0017, todos `Proposed`. Cobertura de los 609 TR según
`docs/architecture/requirements-traceability.md` y
`architecture-review-2026-11-10.md` (veredicto CONCERNS): **0 % por ADR
`Accepted`; 72,1 % (439) trazado por ADR `Proposed`; 26,8 % (163) parcial;
1,1 % (7) hueco** (5 → ADR-0018, 2 → ADR-0020). Renombrado:
`TR-audio-012b` → `TR-audio-026`. Recuento por dominio:

| Dominio TR | Nº TR | Sistemas con más TR del dominio | ADR que lo cubrirá | Cobertura (Proposed · parcial · hueco) |
|---|---|---|---|---|
| Core | 131 | hints 8, player 8, computer 7, director 7, puzzles 7, puzzle3 7, settings 7, interact 6, scene 6, puzzle1 6 | Repartido: 0001 (3), 0002 (pausa), 0003 (4, 21), 0004 (5), 0007 (6), 0009 (composición), 0010 (9, 11–17), 0011 (7), 0012 (2), 0017 (21, 22) | 🟡 99 · ⚠️ 32 · ❌ 0 |
| Input | 63 | input 14, pause 6, interact 5, computer 4, director 4 | 0006 (+ 0011 para puntero/picking, 0003 para `sin control`) | 🟡 48 · ⚠️ 15 · ❌ 0 |
| Data | 60 | content 8, puzzles 5, computer 4, hints 4 | 0005 (+ 0010 para `puzzles.json` v2) | 🟡 46 · ⚠️ 14 · ❌ 0 |
| Events | 57 | director 6, state 5, call 5, hints 4 | 0001 | 🟡 55 · ⚠️ 2 · ❌ 0 |
| Save/Load | 55 | save 13, settings 7, state 4 | 0004 (+ 0007 para el fichero de ajustes, 0001 para la instantánea) | 🟡 36 · ⚠️ 19 · ❌ 0 |
| UI | 41 | subs 9, prompt 6, a11y 5, pause 4, title 4 | 0016 (+ 0007 para escala) | 🟡 28 · ⚠️ 13 · ❌ 0 |
| Accessibility | 41 | a11y 9, shaders 5, atmos 3, prompt 3, subs 3 | 0007 (+ 0014/0015 para el limitador de destellos) | 🟡 26 · ⚠️ 15 · ❌ 0 |
| Scene | 36 | scene 7, box 4, title 3 | 0003 | 🟡 18 · ⚠️ 18 · ❌ 0 |
| Rendering | 35 | shaders 10, atmos 9 | 0013, 0014, 0015 (+ 0012 cámara/FOV) | 🟡 30 · ⚠️ 5 · ❌ 0 |
| Audio | 34 | audio 17, call 3 | 0008 | 🟡 27 · ⚠️ 7 · ❌ 0 |
| Animation | 22 | player 3, box 3 | 0012 (gestos de manos), 0002 (animación en pausa) | 🟡 6 · ⚠️ 16 · ❌ 0 |
| Tooling | 17 | content 3, puzzles 2 | 0005 (verificadores), 0018 (CI, exclusión de herramientas dev) | 🟡 8 · ⚠️ 4 · ❌ 5 |
| Physics | 10 | interact 4, player 3, scene 2 | 0011 (consulta de foco), 0012 (cuerpo e interpolación), 0003 (sensores de zona) | 🟡 9 · ⚠️ 1 · ❌ 0 |
| Localization | 7 | content 2 | 0005 (capa de idioma), 0020 | 🟡 3 · ⚠️ 2 · ❌ 2 |
| **Total** | **609** | | 17 ADR escritos (`Proposed`) | **🟡 439 · ⚠️ 163 · ❌ 7** |

**TR sin dominio claro:** 0 filas sin dominio. Pero **Core (131, 21 %)** es un
cajón de sastre que mezcla máquinas de estado de sistema, contratos de
temporizador y reglas de propiedad; `/architecture-review` debería reasignar
cada TR Core a su ADR concreto al consolidar `tr-registry.yaml`. Los 10
bloques «NO LEÍDO» del baseline implican además que el número de TR crecerá
(Edge Cases y Acceptance Criteria de casi todos los GDDs no se leyeron).

## Required ADRs

Numerados en el **orden de escritura propuesto**. Riesgo de motor: HIGH /
MED / LOW según § Engine Knowledge Gap Summary. «Spike» = prototipo en Godot
4.7.2 cuyo resultado entra en el ADR antes de pasar a `Accepted`. Todos
nacen `Proposed`; solo el technical-director los pasa a `Accepted`, con
confirmación del usuario.

### Must have before coding (Foundation y Core; hito S0)

| ADR | Título | Qué decide | Qué desbloquea | TRs que cubre | Riesgo motor | Spike |
|---|---|---|---|---|---|---|
| **ADR-0001** — escrito (`Proposed`) | Event bus and fact contract | Mecanismo del bus (`Callable` frente a señales Godot), `NoticeChannel` compartido con 6, formato de nombres de aviso (regla 10 de 3 → `StringName`), cargas útiles, cola sin reentrada y tope, formato de instantánea, ventana de escritura silenciosa, uso permitido de señales de contrato (2, `elements_changed`) | Todo sistema de Feature; 5; tests de integración | TR-state-001…018; TR-settings-005, -006; TR-puzzles-011, -020; Events de 8, 9, 21, 22, 23 | MED | No (sí test de rendimiento de lectura O(1)) |
| **ADR-0002** — escrito (`Proposed`); spike: opción A validada salvo S4 manual | Pause and game time | **Máxima prioridad.** `GameClock` como única fuente de Δ_juego; opción recomendada a spike: `SceneTree.paused = true` + `process_mode` explícito por sistema (`ALWAYS`: los 9 autoloads incluido 21, 26 y la UI de 25 y Opciones —no `WHEN_PAUSED`: Opciones también se muestra en el título con el árbol en marcha—; `PAUSABLE`: mundo, 2, 28, 29). Tiempo real por `RealClock`; `GameClock` con `deadline`/`schedule`/`cancel`; transiciones T1–T6 en ADR-0002. Resuelve 23 D23-25 frente a 28 R22 / 29 R35 | 9, 10, 17, 19, 21, 22, 26, 28, 29; AC-21 de 10, AC-28-16, AC-21 de 29 | TR-pause-001…003; TR-audio-001, -015; TR-puzzles-014; TR-box-015; TR-atmos-018; TR-shaders-017; TR-subs-008; TR-input-005, -008; TR-player-015; TR-access-012; TR-computer-009 | HIGH (todo NS) | **Sí**: `SceneTree.paused` con `Tween`, `AnimationPlayer`, `GPUParticles3D`, `AudioStreamPlayer` (`stream_paused`), `TIME` de shader, interpolación física |
| **ADR-0003** — escrito (`Proposed`) | Scene loading, Shell and `sin control` handoff | `Shell` + `WorldSlot` frente a `change_scene_to_*`, secuencia de 9 pasos, retenciones, `T_cap`, cortina, traspaso a 21, descarga total, persistencia de 2 (por escena, recomendado) | 7, 9, 21, 27, toda escena de planta | TR-scene-001…023; TR-input-003, -004, -006; TR-director-001, -002, -010, -025; TR-player-018; TR-save-019, -020 | HIGH | **Sí**: instanciar/liberar 10 veces y contar huérfanos; `Area3D` con Jolt (sensor 0,05 m) |
| **ADR-0004** — escrito (`Proposed`) | Save format and lifecycle | Ruta `user://saves/`, formato `v<N>` + checksum + JSON, algoritmo de hash, secuencia de renombrado seguro, canonicalización para `dif`, migraciones, Sellando/Sellada | 22 (sellado), 25, 27 | TR-save-001…022; TR-state-013…016; TR-call-003, -004 | HIGH | **Sí**: renombrado/borrado en Windows y Linux, SHA-256, enteros en el parser JSON |
| **ADR-0005** — escrito (`Proposed`) | Data schema, validation pipeline and content catalog | Convención de ficheros `assets/data/<sistema>/*.json`, esquemas, validación al arranque (debug ruidoso) y en CI, conversión explícita a `int`, capa de idioma de 18 (propia frente a `tr()`), verificador `tools/` | Todos los sistemas data-driven; contenido | TR-content-001…017; TR-puzzles-001…006; Data de 2, 8, 10, 17, 19, 20, 21, 22, 24, 28; TR-scene-022; TR-save-021 | MED | Sí (corto): parser JSON 4.7 |
| **ADR-0006** — escrito (`Proposed`) | Input abstraction, contexts and binding labels | Capa sobre Input Map, pila de contextos y `sin control`, histéresis de dispositivo, zona muerta propia, cursor virtual, reconocedor de gestos, `get_binding_label`, reasignación y validador de conflictos, foco del campo de texto | 2, 7, 19, 22, 24, 25 | TR-input-001…019; TR-pause-004, -008, -013, -016, -017, -021; TR-computer-003, -004, -011, -012; TR-title-007, -008, -016 | HIGH | **Sí**: familia de mando, conexión/desconexión, ejes crudos, `DEVICE_ID_*` |
| **ADR-0007** — escrito (`Proposed`) | Settings persistence, accessibility and UI scaling | Fichero de ajustes (formato, NaN), cuantización, guardado diferido; **escala de UI**: `content_scale_mode`/`stretch` frente a la F1 de 30 (evitar factor doble); preparación AccessKit (nombre accesible, orden de foco) | 24, 25, 26, 27, 30 | TR-settings-001…021; TR-a11y-001…020; TR-prompt-018; TR-subs-014; TR-computer-013, -014; TR-title-015 | HIGH | **Sí**: stretch `canvas_items` a 720p/1080p/2160p y 16:10; AccessKit |
| **ADR-0008** — escrito (`Proposed`) | Audio buses, voice queue and `process_mode` | Árbol de buses, pool de reproductores y polifonía, cola de voz por canal, watchdog, ducking, pausa por reproductor, filtros/limitador (horneado frente a ejecución), streaming frente a precarga, volúmenes por estancia sin `Area3D` (o con `area_mask` = 1) | 9, 21, 22, 26 (señales de línea) | TR-audio-001…026; TR-call-011, -015, -016; TR-director-009, -026; TR-puzzles-013; TR-settings-017 | HIGH | **Sí**: `stream_paused`, limitador, detección sin dispositivo |
| **ADR-0009** — escrito (`Proposed`) | Service composition: autoloads, Shell and dependency injection | Lista final de 9 autoloads (§ Module Ownership), `ServiceContext` ‡ e inyección en `configurar()`, subcapas F1–F5 y llamadas permitidas, interfaces `ViewGateProvider`/`BoxPresenter`, manejador de error fatal inyectado, dobles para tests | Todos los tests unitarios; regla de capas en el control manifest | Transversal: TR-hints-001; TR-settings-007, -019, -021; TR-scene-002; TR-atmos-001 (rechazado); TR-pocket (nodo de servicio); TR-shaders-015 | LOW | No |

### Before the relevant system (hitos M1–M4)

| ADR | Título | Qué decide | Qué desbloquea | TRs que cubre | Riesgo motor | Spike |
|---|---|---|---|---|---|---|
| **ADR-0010** — escrito (`Proposed`) | Puzzle framework and controller contract | `PuzzleFramework`/`PuzzleController` (`@abstract`), `Verdict`, 5 políticas, `GameClock` inyectado, esquema `puzzles.json` v2, cambios requeridos por 14 (`PARTIAL{element, action}`) y 17 (`first_action`, reaplicación, re-emisión de «puzle inactivo») | 10, 11–16, 17 (M1 P1, M2) | TR-puzzles-007…022; TR-puzzle1…6 (todas las Core/Events); TR-box-001; TR-hints-006, -007, -013, -014 | MED (retorno tipado 4.7) | No |
| **ADR-0011** — escrito (`Proposed`) | Interaction focus query under Jolt and view picking | Consulta de forma esférica que recoja todos los contactos frente a `ShapeCast3D`; máscaras; picking 2D aritmético; F6 `ppm` y eje de FOV en 16:10 | 7, 8, 19, 20, 22, vistas de puzle (M1) | TR-interact-001…022; TR-puzzle3-008, -009; TR-puzzle4-002 | HIGH | **Sí**: `intersect_shape`/`ShapeCast3D` con Jolt, coste por paso |
| **ADR-0012** — escrito (`Proposed`) | Player controller, physics interpolation and camera | Cinemático con Jolt, paso fijo 60 Hz + interpolación (o seguimiento suavizado), FOV vertical, cesión de cámara, memoria de poses, red de seguridad, máquina de gestos de manos | 7, 28 (reflejo), M1 | TR-player-001…021 (TR-player-010 parcial: contrato del nodo; técnica en 0013); TR-scene-007 | HIGH | **Sí**: interpolación 3D en 4.7 a 30/60/144 fps; `keep_aspect` |
| **ADR-0013** — escrito (`Proposed`) | First-person hands rendering and blackout lighting | Técnica de manos encima del mundo (shader, sub-viewport, segunda cámara) con `fov_manos` 60° y luz mínima en el apagón (razón ≥ 1,5:1) | 2 (manos visibles), 28 (apagón), M3 | TR-player-010; TR-atmos-010 | HIGH | **Sí** (spike A/B, D-28) |
| **ADR-0014** — escrito (`Proposed`) | Atmosphere lighting budget and rain | Presupuesto de luces (≤ 8 visibles, ≤ 2 sombras, ≤ 14 por escena), `Tween` de energía, lluvia `GPUParticles3D`, reflejo retardado por proxy, limitador de destellos, sin `LightmapGI`; 28 como nodo de escena | S0b (prueba de atmósfera), M3–M4 | TR-atmos-001…020; TR-a11y-010, -011 | HIGH | **Sí** (S0b, 30 s de pasillo, hardware de referencia) |
| **ADR-0015** — escrito (`Proposed`) | Glass and mirror shaders and transparent draw order | 3 shaders `spatial`, `render_priority`, `instance uniform` frente a material por instancia, `#include`, Shader Baker/precalentado, fallback `StandardMaterial3D`, presupuesto 0,5 ms GPU | 12 (P2), 15 (P5), M4 | TR-shaders-001…020; TR-puzzle2-007, -015; TR-puzzle5-008, -012 | HIGH | **Sí** (TR-shaders-008 lo exige) |
| **ADR-0016** — escrito (`Proposed`) | Subtitles and UI text rendering | Ocho capas `CanvasLayer` numeradas (D1: `SceneUi` 5, HUD 10, `PauseVeil` 20, subtítulos 30, menú 40, cursor 50, cortina 60, error 70; el velo es capa propia), paginación, banda reservada, convivencia 24↔26, fuentes y tamaño mínimo 24 px, tokens `{accion:<id>}` | 24, 25, 26, 27, 22 (opciones) | TR-subs-001…021; TR-prompt-001…020; TR-pause-009…011, -022; TR-title-002, -005, -011 | MED | Sí (corto, con ADR-0007) |
| **ADR-0017** — escrito (`Proposed`) | Scene director timeline and call data | Formato de `scenes.json`/`scene-config.json` y `call.json` ‡, ejecutor de línea de tiempo con `GameClock`, cargas útiles ‡ de «efecto de escena pedido», «estado de objeto pedido», «tarjeta final pedida» | 21, 22, 28, 27 (M3) | TR-director-003…027; TR-call-001…024 | LOW | No |

### Can defer

| ADR | Título | Qué decide | Qué desbloquea | TRs que cubre | Riesgo motor | Spike |
|---|---|---|---|---|---|---|
| **ADR-0018** — escrito (Proposed) | Build, export, CI and dev-only tooling | Presets Windows/Linux, ejecución de gdUnit4 en CI, exclusión verificada de consola de 3, herramientas de 5, recarga de 18 y registro de playtest de la demo | Primera build de entrega (antes de M5; el runner de tests ya está en `project.yaml`) | TR-state-018; TR-save-022; TR-content-012, -013; TR-puzzles-021, -022; Tooling restantes | MED (crash en `--import` 4.7.x documentado) | No |
| **ADR-0019** — escrito (Proposed) | Performance budgets and reference hardware | Fija equipo de referencia y presupuestos medidos (fotograma, GPU por sistema, memoria, audio) | M4 (perfilado) | TR-atmos-016; TR-shaders-009; TR-audio-021 | MED | Sí (perfilado) |
| **ADR-0020** — pendiente | Localization readiness beyond `es` | Idiomas, longitud de texto, recálculo de duraciones al cambiar idioma, texto del cristal pregenerado | Post-slice | TR-content-005, -007; TR-hints-017; TR-shaders-019; Localization restantes | LOW | No |

**Recuento: 20 ADRs** (9 antes de programar, 8 antes de su sistema, 3
diferibles); v2: 0001–0017 escritos (`Proposed`), 0018 en redacción, 0019–0020 pendientes. Orden crítico: 0001 → 0002 → 0009 → 0003 pueden redactarse en
paralelo con el spike de pausa; 0004 a 0008 dependen de 0001 y 0002.

### Presupuestos de rendimiento provisionales

| Presupuesto | Valor | Fuente | Estado |
|---|---|---|---|
| Fotogramas | 60 fps (16,6 ms) en el 99 % de fotogramas | `technical-preferences.md`, TR-atmos-016 | Provisional |
| Draw calls | ~1500 | `technical-preferences.md` | Provisional, revisar tras S0b |
| GPU atmósfera (28) | ≤ 1,0 ms; CPU ≤ 0,15 ms media / 0,5 ms pico | TR-atmos-016 | PV |
| GPU shaders (29) | ≤ 0,5 ms a 1080p; ≤ 6 draw calls por vista | TR-shaders-009 | **Sin medir** (†) |
| Audio | ≤ 24 voces; ≤ 24 MB en ejecución; ≤ 40 MB en disco | TR-audio-021 | Provisional |
| Memoria total | Sin fijar | `technical-preferences.md` | Bloqueado por hardware de referencia |
| Hardware de referencia | **Sin fijar** | PLAN-TECNICO §7 punto 4 | Abierto (QQ-04) |

## Architecture Principles

Derivados de los cinco pilares (`design/gdd/game-pillars.md`: Ambivalencia sin
moral binaria · El espacio expresa la emoción · Autonomía como progresión ·
Tensión sin castigo · Información incompleta) y del slice «Turno de noche».

1. **El hecho primero, la presentación después.** Toda consecuencia jugable
   se escribe como hecho en 3 antes de animar, sonar o mostrar nada; toda
   presentación se puede reconstruir desde hechos (`colocar`,
   `restore_solved_presentation`, `set_final_pose`). Por eso el guardado
   persiste solo 20 hechos y cancelar una presentación nunca bloquea el avance.
   *Sirve a Tensión sin castigo:* no hay estado de fallo terminal ni softlock
   por animación interrumpida.
2. **Un escritor por hecho, un canal horizontal.** Cada hecho tiene un único
   dueño; los sistemas de la misma capa se enteran de lo ocurrido solo por el
   bus de 3 y se piden servicios solo hacia una subcapa inferior por interfaz
   inyectada. *Sirve a Autonomía como progresión:* los sistemas reaccionan al
   estado, no a un guion, así que el orden en que el jugador resuelve no está
   cableado en código.
3. **Datos, no código, para todo lo que se ajusta o se lee.** Valores de
   tuning, soluciones, textos, variantes y escenas viven en `assets/data/`,
   validados al arrancar y en CI; los IDs del slice son las claves. Ningún
   controlador sabe qué variante es «buena». *Sirve a Ambivalencia sin moral
   binaria e Información incompleta:* variantes (`carta_variante`,
   `respuesta_llamada`, `t4_decision`) y lo que se revela se cambian sin tocar
   lógica y sin codificar juicio moral.
4. **Un solo tiempo de juego, y se detiene.** Todo temporizador de juego lee
   `GameClock`; ningún sistema crea su propio reloj ni usa `SceneTreeTimer`.
   La pausa es posible en cualquier momento salvo la carga. *Sirve a Tensión
   sin castigo:* ninguna tensión depende de un reloj que el jugador no pueda
   detener (la espera de 20 s de la llamada no elige por él).
5. **La atmósfera es un sistema con presupuesto y topes duros.** Luz, lluvia,
   audio y shaders son módulos de primera clase con presupuesto medido
   (§ Required ADRs) y con límites de accesibilidad en constantes de código que
   ningún dato puede violar (`FLASH_MAX_HZ`, suelo de ambiente, suelo de texto
   24 px). *Sirve a El espacio expresa la emoción* sin sacrificar el slice a un
   espectador fotosensible.

## Open Questions

| ID | Resumen | Prioridad | Vía de resolución |
|---|---|---|---|
| QQ-01 | D-16: orden de la caja (cadena c1→c3→c4 con c2 libre, o libre del todo). Afecta a `requires.all` de P5/P6 en `puzzles.json`, no a la arquitectura del marco | Media | **Resuelta 2026-11-10** (usuario): cadena c1→c3→c4 con c2 libre (diseño actual, Anexo B); se refleja en datos. Antes: Decisión del usuario (PLAN-TECNICO §7.1) |
| QQ-02 | Lenguaje: GDScript (propuesto y fijado en `project.yaml`) o C# | Baja (de facto cerrada) | Confirmación del usuario; este documento asume GDScript |
| QQ-03 | Tamaño y perfiles del equipo | Media | **Resuelta 2026-11-10** (usuario): equipo individual, una persona con agentes de Claude. Antes: Usuario (PLAN-TECNICO §7.3); condiciona `team.size` y el paralelismo de ADRs |
| QQ-04 | **Equipo de referencia** (CPU/GPU/RAM). Sin él, 60 fps, 1500 draw calls, 1,0 ms de 28 y 0,5 ms de 29 no se pueden medir | **Alta** | **Resuelta 2026-11-10 por ADR-0019** (`Proposed`): portátil de desarrollo (Core Ultra 7 265H, iGPU Intel, 15,4 GB, 1920×1200 a 60 Hz); presupuestos como objetivos, 60 fps en iGPU sin verificar. Antes: Usuario (PLAN-TECNICO §7.4) → ADR-0019; bloquea el criterio de S0b |
| QQ-05 | Fecha objetivo de la demo | Media | **Resuelta 2026-11-10** (usuario): sin fecha fija; planificación por hitos con plazos relativos y orden de recorte. Antes: Usuario (PLAN-TECNICO §7.5); decide qué ADR diferibles se adelantan |
| QQ-06 | **ADR de pausa**: `SceneTree.paused` + `process_mode` (recomendado) frente a reloj propio sin pausar el árbol; contradicción 23 D23-25 / TR-audio-015 («25 no pausa el árbol», pausa por reproductor) frente a 28 R22 y 29 R35 (árbol pausable) | **Crítica** | **Resuelta por ADR-0002** (opción A, spike 2026-11-10; S4 manual pendiente de registro). Antes: Spike en 4.7.2 → ADR-0002. Propuesta de conciliación: el árbol se pausa, 23 y 26 corren `ALWAYS` y mantienen su pausa propia guiada por `pause_opened`; 23 solo cambia el texto de D23-25 |
| QQ-07 | Espera de pistas 20/40 s (17 OQ3, 30 OQ1) frente a «Tensión sin castigo»; recorte de pips/cuaderno/«Repetir» | Baja (arquitectura) | Usuario; solo cambia `hints_policy.json` y quizá la reaplicación ‡ de `request_hint` |
| QQ-08 | Alcance de `reducir_movimiento` más allá del slice §14 y cierre de `escala_texto_ui` («restablecer todos» 18 o 17 claves) | Media | Usuario → ADR-0007 |
| QQ-09 | «interacción ejecutada»: filtrar por `HECHO` (aplicado) o aviso aparte solo para 24 (7 OQ 6) | Baja | **Resuelta por ADR-0001** D11 (un aviso, filtrado por `HECHO`). Antes: Usuario; ADR-0001 registra el contrato elegido |
| QQ-10 | Suelo de subtítulos a 720p (D26-22: `pequeno` = `medio` = 24 px) | Media | Usuario + ADR-0007/0016; depende del equipo de referencia (QQ-04) |
| QQ-11 | D13-4: `tray_drop_verdict` `REJECT` o `NONE`; permanencia de la elección de P6 ante cierre antes de guardar (16 OQ 12) | Baja | Usuario; el primero es dato, el segundo afecta a la causa de guardado `puzzle_solved:P6` (ADR-0004) |
| QQ-12 | Jugador (2) persistente o por escena (OQ de 4) | Media | **Resuelta por ADR-0003** D3 (por escena, reconstruido con `colocar`). Antes: ADR-0003 (recomendado: por escena, reconstruido con `colocar`) |
| QQ-13 | Atmósfera (28) como autoload (TR-atmos-001) o nodo de escena (este documento) | Media | **Resuelta por ADR-0009** D11 (nodo de escena). Antes: ADR-0009 / ADR-0014 |
| QQ-14 | Cuándo se valida `puzzles.json`: en la configuración de `planta` (GDD 9, TR-scene-011) o también al arrancar (decisión de partida) | Baja | **Resuelta por ADR-0005** D3.2 (nivel L en `planta` y nivel B en arranque). Antes: ADR-0005: ambos, el de arranque solo en debug/CI |
| QQ-15 | Firmas ‡ de 3 (lectura/escritura/suscripción) y de 6 (leer/escribir/restablecer/vaciar): los GDDs las dejan a ADR | Alta | **Resuelta por ADR-0001 y ADR-0007**. Antes: ADR-0001, ADR-0007 |
| QQ-16 | Firmas ‡ de 1: API de reasignación, `es_imprimible(entrada)`, lista exportada de ajustes de manejo; operaciones de `sin control` | Alta | **Resuelta por ADR-0006** D4, D11. Antes: ADR-0006 |
| QQ-17 | Firmas ‡ de 4 (petición de carga, retenciones), de 5 (`request_save`, consulta de inspección) y `GameClock` completo | Alta | **Resuelta por ADR-0002, ADR-0003 y ADR-0004** D11. Antes: ADR-0003, ADR-0004, ADR-0002 |
| QQ-18 | Firmas ‡ confirmadas solo por un lado: `has_item` (20), `compose_i01` (19), `get_view_gate` (9/10); `elemento_bajo` en `seleccionar` (7, lo pide 16); `PARTIAL{element, action}` (14 → 9); `first_action` y reaplicación (17 → 9) | Alta | **Resuelta por ADR-0010 y ADR-0011** (quedan cambios en GDDs 7, 9, 17: reconciliación H2–H4, H7). Antes: `/architecture-review` + ADR-0010/0011; cambios requeridos en GDDs 7 y 9 |
| QQ-19 | Contratos sin firma de Presentación: proveedor de panel de pistas (17 → 25), `OptionsComponent.mostrar(pantalla, pestaña_inicial?)`, API propia de 28, `SurfaceFx` (29, propuesta del GDD) | Media | **Resuelta por ADR-0016** D7/D8, **ADR-0014** (`Atmosphere`) y **ADR-0015** (puerto `SurfaceFx`). Antes: ADR-0016, ADR-0014, ADR-0015 |
| QQ-20 | Cargas útiles ‡ de «efecto de escena pedido», «estado de objeto pedido», «tarjeta final pedida»; fichero `call.json` ‡ | Media | **Resuelta por ADR-0017** D5. Antes: ADR-0017 |
| QQ-21 | Nombres de fichero sin fijar o fuera de convención: ficheros de 18 bajo `assets/data/narrative/` (el plan dice `lines.json`), `save-config.json` y `scene-config.json` (kebab-case frente a `snake_case`), `hints_policy.json` en la raíz de `assets/data/` | Baja | **Resuelta por ADR-0005** D1. Antes: ADR-0005 |
| QQ-22 | «línea iniciada» y `seg_b_inicio_s` pendientes de confirmar entre 18/23/26; audio del título (27 OQ 1 / 23 OQ 3) | Baja | **Parcial:** «línea iniciada»/`seg_b_inicio_s` resuelta por ADR-0008 D11; audio del título sigue abierto (usuario). Antes: ADR-0008 |
| QQ-23 | Herramienta de verificación de destellos (PEAT u otra, TR-a11y-011) y filtro de daltonismo para AC-24-07 | Baja | ADR-0014 / QA |

Estado (v2): las QQ no marcadas siguen abiertas; QQ-01, 03, 04, 05, 07, 08, 10, 11 esperan decisión del usuario; QQ-23, a QA (ADR-0014 OI-6). Todas las «Resuelta» lo están por ADR `Proposed`.

**Pendiente de verificar:** QQ-12 por ADR-0012 (solo verificado en ADR-0003); cierre de QQ-17 por ADR-0003 (inferido, sin frase explícita de cierre); § Entrada (1) solo remite a ADR-0006 § Key Interfaces, el boceto no se sustituyó; S4 manual de ADR-0002 sin log.
