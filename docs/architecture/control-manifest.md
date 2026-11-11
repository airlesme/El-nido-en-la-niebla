# Control Manifest

> **Engine**: Godot 4.7 (pin 4.7.2.stable.official.ed1daf0bf), GDScript, 3D, Forward+, Jolt
> **Last Updated**: 2026-11-11
> **Manifest Version**: 2026-11-11b
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0005, ADR-0006, ADR-0009, ADR-0010, ADR-0011, ADR-0012, ADR-0017 (los 10 `Accepted` de 19)
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

`Manifest Version` es la fecha en que se generó este manifiesto. Las historias la
incrustan al escribirse y `/story-readiness` la compara con esta para encontrar
historias escritas contra reglas viejas. `Last Updated` es la fecha (2026-11-11);
el sufijo `b` distingue esta segunda generación del mismo día (la versión
`2026-11-11` cubría solo ADR-0001/0002/0009). **Toda historia que incruste
`2026-11-11` está desfasada** respecto a las capas Core/Feature y a las reglas
nuevas de Foundation (F-R40 en adelante).

Hoja de referencia rápida para programación, extraída **solo** de los ADR
`Accepted`, de `project.yaml`, de `.claude/docs/technical-preferences.md`, de
`.claude/docs/coding-standards.md` y de `docs/engine-reference/godot/`. El *porqué*
de cada regla está en su ADR y sección. Ninguna regla procede de un ADR `Proposed`
ni de memoria del modelo.

---

## Cobertura

**10 de 19 ADR `Accepted`** (comprobado con Grep `^Accepted` bajo `## Status` en
`docs/architecture/adr-0*.md`, 2026-11-11).

| ADR | Título | Estado (línea `## Status`) | Capa |
|---|---|---|---|
| ADR-0001 | Event bus and fact contract | Accepted 2026-11-11 (C1 medida después en S-0006) | Foundation |
| ADR-0002 | Pause and game time | Accepted 2026-11-11 (variante **A**) | Foundation |
| ADR-0005 | Data schema validation and content catalog | Accepted 2026-11-11 (S-0005-A; A7/A9/A10 en export release) | Foundation (18 Contenido) |
| ADR-0006 | Input abstraction, contexts and binding labels | Accepted 2026-11-11 (partes automáticas de S-0006; mando físico NEEDS_MANUAL) | Foundation (1 Entrada) |
| ADR-0009 | Service composition | Accepted 2026-11-11 | Foundation |
| ADR-0003 | Scene loading and sin-control handoff | Accepted 2026-11-11 (S-0003-A/B; S-0003-C diferido) | Core (C2: 4 Escena) |
| ADR-0012 | Player controller, physics interpolation and camera | Accepted 2026-11-11 (S-0012-A…F con R1; pasillo 15 s NEEDS_WINDOWED) | Core (C2: 2 Jugador) |
| ADR-0010 | Puzzle framework and controller contract | Accepted 2026-11-11 (sin spike; enmiendas C4–C6 pendientes) | Feature (F4: 9; F5: 11–16) |
| ADR-0011 | Interaction focus query and view picking | Accepted 2026-11-11 (S-0011-A/B/C; alto lógico NEEDS_WINDOWED) | Feature (F1: 7) |
| ADR-0017 | Scene director timeline and call data | Accepted 2026-11-11 (sin spike; enmiendas A1–A6) | Feature (F5: 21, 22) |

**Cobertura por capa** (sistemas según `architecture.md` § System Layer Map):

- **Foundation — completa**: 3 Estado y bus (0001), `GameClock`/pausa (0002), 1
  Entrada (0006), 18 Contenido y validación de datos (0005), composición (0009).
- **Core — parcial**: cubiertos **4 Escena** (0003) y **2 Jugador** (0012). Sin
  reglas propias: **6 Ajustes** (ADR-0007), **5 Guardado** (ADR-0004), **23 Audio**
  (ADR-0008).
- **Feature — parcial**: cubiertos **7 Interacción** (0011), **9 Marco y 11–16
  controladores** (0010), **21 Director y 22 Llamada** (0017). Sin ADR propio
  `Accepted`: 8 Acceso, 10 Caja, 17 Pistas, 19 Ordenador, 20 Bolsillo (les obligan
  solo las reglas transversales y los contratos de 0010/0011 que les tocan).
- **Presentation — sin ADR propio `Accepted`** (0013–0016 `Proposed`). Solo
  reglas que ADR aceptados de otras capas imponen a sistemas de presentación
  (telón y capas de 0003, texto visible de 0005, foco dual de 0006, `ViewMetrics`
  de 0011, `TIME`/tweens de 0002).

**ADR excluidos (9, todos `Proposed`; ninguna regla extraída de ellos):**

| ADR | Título | Estado | Qué lo desbloquea |
|---|---|---|---|
| ADR-0004 | Save format and lifecycle | Proposed | Revisión + aceptación del desarrollador; consume `DataReader.to_int` (0005 D4.5) y el sellado por `call_started` (0017) |
| ADR-0007 | Settings persistence, accessibility and UI scaling | Proposed | Spike de estirado (`canvas_items`/`expand`, compartido con S-0011-C NEEDS_WINDOWED); fuente del idioma activo (0005 O7) |
| ADR-0008 | Audio buses, voice queue and process mode | Proposed | Aplicar enmiendas pedidas por 0012 OI-1 (`rayo_vision()` en vez de `listener_position()`) y 0017 A6 (forma del interrupt de voz) |
| ADR-0013 | First-person hands rendering and blackout lighting | Proposed | Huesos/IK de manos (0012 OI-8); presupuesto de render (ADR-0019) |
| ADR-0014 | Atmosphere lighting budget and rain | Proposed | Hardware de referencia (ADR-0019, QQ-04) |
| ADR-0015 | Glass and mirror shaders and draw order | Proposed | Operación `SurfaceFx` HIGHLIGHT (0010 OI-4); hardware de referencia |
| ADR-0016 | Subtitles and UI text rendering | Proposed | `ViewportMapper` y alto lógico (0006 OI-7, 0011 OI-5, NEEDS_WINDOWED); orden de capas sobre el telón (0003, 0017 OI-4) |
| ADR-0018 | Build, export, CI and dev tooling | Proposed | Imagen del runner con `git` (0005 O8); `tools/godot/.gdignore` (0005 O9) |
| ADR-0019 | Performance budgets and reference hardware | Proposed | Decisión de hardware de referencia (QQ-04); hasta entonces todos los presupuestos por sistema son provisionales |

Consecuencias concretas de la exclusión: los presupuestos de rendimiento globales
vienen de `project.yaml`, no de ADR-0019, y los presupuestos por sistema de este
manifiesto son los **provisionales** de cada ADR aceptado; el CI
`tools/ci/forbid_timers.sh` cita también ADR-0018 D6, pero aquí se traza solo a
ADR-0002 D6.

**Leyenda de verificación** (columna «Verif.»): **CI** = script existente que falla
el build · **CI‡** = chequeo decidido en el ADR pero el script **aún no existe** ·
**Test** = suite gdUnit4 nombrada en el ADR · **Rev** = solo revisión de código.

---

## Foundation Layer Rules

*Aplica a: bus de avisos y hechos (3 `GameState`, `NoticeChannel`), tiempo de juego
y pausa (`GameClock`, `RealClock`, `PauseBackend`), entrada (1 `InputRouter`,
`EngineInputAdapter`), datos y contenido (18 `ContentDB`, `DataReader`,
`DataCatalog`, `JsonText`), composición de servicios (`Boot`, `ServiceContext`,
autoloads). Por su naturaleza transversal, estas reglas
obligan a **todo** el código que usa esos mecanismos, en cualquier capa.*

### Required Patterns

**Bus y hechos (ADR-0001)**

- **F-R01** Todo aviso («algo pasó») y todo cambio de hecho se entrega por un
  `NoticeChannel` (`RefCounted`, cola FIFO única, drenaje síncrono, no reentrante).
  `GameState` (3) y `Settings` (6) tienen cada uno su instancia; las colas son
  independientes. — source: ADR-0001 § Decision D1, D2, D5; ADR-0009 § D4 · Rev
- **F-R02** Los nombres de aviso se referencian como constantes `NoticeIds.X`
  (`src/core/notice_ids.gd`, `class_name NoticeIds`). Emitir un nombre fuera del
  registro es una llamada inválida (dev: halt vía `ErrorPolicy`; release:
  descartado + una línea de log). — source: ADR-0001 § D3, § Implementation
  Guidelines G-2, § Invariants I-11 · Rev
- **F-R03** Los nombres de hecho en código son literales `StringName` (`&"caja_c1"`)
  o constantes, sensibles a mayúsculas. En caminos calientes se cachean los índices
  de `resolve_fact()` en `configurar()` y se lee con `get_fact_at()`. — source:
  ADR-0001 § D3, G-3 · Rev
- **F-R04** Payloads = `Dictionary` con claves `StringName` iguales a los nombres de
  datos del GDD, validados en debug contra `NoticeIds.SCHEMA`. Se construyen
  **nuevos en cada `notify`** y los consumidores **no los mutan** (la misma
  instancia llega a todos). Los cambios de hecho no llevan payload:
  `cb(fact: StringName, old: Variant, new: Variant)`. — source: ADR-0001 § D4, G-7 · Rev
- **F-R05** Los sistemas leen y escriben hechos solo a través de la referencia
  inyectada a `GameState` y de su `FactWriter` (entregado por la raíz de
  composición con `GameState.writer_for(n)`); un sistema nunca pasa su propio
  número de propietario. — source: ADR-0001 § D7, G-1 · Rev
- **F-R06** Ningún sistema deriva estado de un aviso que pudo perderse; al recibir
  `state_restored` / `state_reset` vuelve a leer los hechos. — source: ADR-0001 G-4 · Rev
- **F-R07** Los callbacks del bus son baratos y **no hacen `await`**; lo que necesite
  tiempo arranca su propio proceso (Tween, temporizador de `GameClock`). — source:
  ADR-0001 G-6 · Rev
- **F-R08** Todo consumidor de `interaction_executed` salvo 24 condiciona su
  reacción a `InteractionNotice.is_done(payload)` (`resultado == &"HECHO"`). —
  source: ADR-0001 § D11, G-12 · Test (V-INT-3, uno por consumidor) + Rev
- **F-R09** Todo log pasa por `LogSink`; todo «dev halt» por `ErrorPolicy`. Solo
  `src/core/error_policy_default.gd` nombra las llamadas de motor de NS-4. Su
  implementación de producción es: `push_error` + (solo dev, tras
  `OS.is_debug_build()`) parada explícita con `get_tree().quit(1)`. — source:
  ADR-0001 G-8; § Spike Results V-ENG-4 · Rev
- **F-R10** `flags.json` declara `max_chained_notices` (int, 8–256, por defecto 64);
  fuera de rango → catálogo inválido. — source: ADR-0001 § D5, G-9 · Test
- **F-R11** La consola de desarrollo (`dev_force`) vive en un script aparte excluido
  del export de la demo; `GameState` solo expone el gancho. — source: ADR-0001 G-11 · Rev
- **F-R12** Identificadores de código en inglés ASCII; mapeo GDD→código:
  `escribir_silencioso` → `write_silent`, `cola_vacía()` → `is_queue_empty()`,
  `snapshot_version` → `get_snapshot_version()`. — source: ADR-0001 G-13, NS-6 · Rev
- **F-R13** `restore` acepta un número entero como `int` **o** como `float`
  integral: en 4.7.2 todo número JSON se parsea como `float` (`2` → `2.0`). Regla
  obligatoria, no defensiva. — source: ADR-0001 § Spike Results V-ENG-3 · Test
- **F-R14** Snapshot = `{"snapshot_version": 1, "facts": {...}}` con exactamente los
  20 hechos declarados (derivados incluidos), claves `String`, `bool` como bool
  JSON, enum como `String` o `null`. — source: ADR-0001 § D8 · Test

**Tiempo de juego y pausa (ADR-0002, variante A aceptada)**

- **F-R15** Toda lógica de tiempo de juego lee el `GameClock` **inyectado**
  (`now()`, `delta()`, `deadline()`/`is_due()`, `schedule()`/`cancel()`). Excepción:
  presentación movida por el motor (Tween, AnimationPlayer, partículas, paso de
  física), que congela el árbol. — source: ADR-0002 § D1, G-1 · Rev
- **F-R16** El código que debe correr durante la pausa usa un `RealClock` **inyectado**
  (producción: `Time.get_ticks_msec()`) y vive en un nodo `ALWAYS`; nunca lee
  `GameClock` para eso. `GameClock` = tiempo que se congela; `RealClock` = tiempo
  que no. — source: ADR-0002 § D1, § D5, G-2 · Rev
- **F-R17** Esperas de tiempo de juego: `GameClock.schedule()` o deadlines. Esperas
  de tiempo real: deadlines de `RealClock` sondeadas en `_process` de un nodo
  `ALWAYS`. — source: ADR-0002 § D6 · Rev
- **F-R18** Todo `process_mode` de la tabla D2 se fija **explícitamente** en el
  `.tscn` propietario (o en `_init()` para autoloads), nunca heredado de `Shell` ni
  de la raíz. `ALWAYS`: los 9 autoloads, `Shell`, capa `Subtitles` (26), `PauseMenu`
  + `OptionsComponent` (25/27), panel de error (4). `PAUSABLE`: `WorldSlot`
  (explícito; descendientes `INHERIT`) y la capa HUD (24, 17, 20). — source:
  ADR-0002 § D2, G-7; ADR-0009 § D2, Implementation Guidelines 2 · Test (T-U6:
  `process_mode` de autoload ≠ `INHERIT`) + Rev
- **F-R19** Todo `_physics_process` que mueve un cuerpo empieza con
  `if clock.is_paused(): return`. (S12 mostró que en la variante A no es
  imprescindible; la regla sigue vigente en el ADR y protege el fallback B.) —
  source: ADR-0002 G-4, § D7; § Spike Results S12 · Rev
- **F-R20** Los tweens del mundo se crean con `create_tween()` del nodo de mundo
  propietario, a través del único helper `FxTween.make(node)` ‡; los tweens de UI
  en nodos `ALWAYS` usan el mismo helper con `ui = true`. — source: ADR-0002 G-9 · Rev
- **F-R21** Las fases temporales con significado de juego en shaders son uniforms
  alimentados desde `GameClock.now()`. `TIME` sigue avanzando en pausa (S10), así que
  solo se permite para uso decorativo donde no haga falta congelarlo. — source:
  ADR-0002 G-10; § Spike Results S10 · Rev
- **F-R22** Apertura de pausa en un mismo frame y en este orden: O1 25 pide contexto
  `menú` a 1 (si 1 rechaza, no hay pausa) → O2 `GameClock.pause(&"pause_menu")` →
  O3 6 «vaciar pendientes» (llamada síncrona) → O4 emitir `pause_opened` → O5 velo.
  Cierre: C1 salir de `menú` → C2 `GameClock.resume(&"pause_menu")` → C3 emitir
  `pause_closed` (último). `pause_opened`/`pause_closed`: sin payload, sin alias,
  una emisión por apertura/cierre efectiva, emisor solo 25. «Volver al título»:
  orden T1–T6 de § D4. — source: ADR-0002 § D4 · Rev
- **F-R23** `GameClock.process_priority` es el valor más bajo usado en el proyecto
  (`GameClock.PROCESS_PRIORITY := -1000` ‡), para que Δ_juego se calcule antes que
  cualquier consumidor. — source: ADR-0009 § D2; ADR-0002 § Spike Results S15 ·
  Test (T-U7)

**Composición de servicios (ADR-0009)**

- **F-R24** Hay exactamente 9 autoloads (tabla D1). El nombre registrado termina en
  `Autoload` y nunca coincide con un `class_name`; en el código se usa el
  `class_name` (`GameState`, `GameClock`, …). Un décimo autoload exige enmendar
  ADR-0009 con su fila P/B/G. — source: ADR-0009 § D1, Implementation Guidelines 1 · Rev
- **F-R25** Solo `src/core/boot/boot.gd` nombra un autoload (`*Autoload`). `Shell` y
  toda raíz de escena reciben el contexto de `Boot`/`SceneLoader`. — source:
  ADR-0009 § D3, Implementation Guidelines 1 · CI‡ (`tools/ci/list_autoload_refs.sh`
  no existe aún) + Rev
- **F-R26** `_init()`, `_enter_tree()` y `_ready()` de un autoload no hacen I/O, no
  leen otro autoload y no se suscriben; toda inicialización real ocurre en
  `setup(ctx: ServiceContext)`, llamado por `Boot`. Un autoload copia en `setup()`
  los pares que necesita y nunca lee otro autoload por nombre global. — source:
  ADR-0009 § D2, § D3, Implementation Guidelines 2 · Test (T-U6)
- **F-R27** `Boot` (hijo de `Shell`, en `_ready()`, síncrono) sigue el orden 0–13 de
  § D2; un paso que llama al manejador fatal **detiene** la secuencia. `ctx.freeze()`
  en el paso 12: después, el contexto global es de solo lectura. — source: ADR-0009
  § D2, § D3 · Test (T-I3)
- **F-R28** Todo sistema de escena expone exactamente un punto de entrada
  `configurar(ctx: ServiceContext) -> void`, que empieza con
  `ctx.require(&"<sistema>", [...])` para las dependencias duras, trata las blandas
  como anulables (`if x != null` u objeto nulo), copia las referencias a miembros
  tipados y **no retiene `ctx`** después de la llamada. — source: ADR-0009 § D3
  reglas 3–4, Implementation Guidelines 3 · Rev
- **F-R29** `_ready()` solo hace trabajo local; `@onready` solo para el propio subárbol
  (`%Unique`). Las referencias entre sistemas vienen de `ctx`. — source: ADR-0009
  § D3 reglas 1–2, Implementation Guidelines 4 · Rev
- **F-R30** Dentro de `configurar()` solo se llama a autoloads y a sistemas ya
  configurados antes en el orden D4/D5; las llamadas a servicios F2–F4 esperan a
  «escena lista» (exención: restauración de 9 → `BoxPresenter.set_final_pose(n)`).
  El orden de configuración de `planta` es dato (`CONFIG_ORDER: Array[StringName]`
  en la raíz de escena). — source: ADR-0009 § D3 regla 5, § D5 · Test (T-I1)
- **F-R31** Toda suscripción al bus y todo `connect()` a un nodo fuera del propio
  subárbol se registra en un `SubscriptionBag` ‡ liberado en `_exit_tree()`. —
  source: ADR-0009 § D3 regla 6, Implementation Guidelines 7 · Test (T-U2, T-I2)
- **F-R32** Dos canales que no se mezclan: avisos siempre por el bus de 3, en
  cualquier dirección; llamadas directas solo a una subcapa **estrictamente
  inferior** (o capa inferior) mediante referencia de `ctx`, y solo las de la tabla
  «Allowed direct calls» de § D4. Única excepción en la misma subcapa: el par de
  puertos 9⇄10. Hacia arriba, solo por **puertos de salida** definidos en la capa
  del llamante, implementados arriba e inyectados, tratados como blandos (objeto
  nulo). — source: ADR-0009 § D4, § D6, Implementation Guidelines 5–6 · Test (T-U8;
  mecanismo pendiente, O3) + Rev
- **F-R33** Los puertos son clases `@abstract` `RefCounted`; el proveedor entrega un
  adaptador que guarda un `WeakRef` a su dueño y devuelve un valor seguro si ya no
  existe. `ViewGateProvider`/`BoxPresenter` viven en `src/puzzles/ports/`. —
  source: ADR-0009 § D5 · Test (T-U3)
- **F-R34** Los servicios persistentes (`SceneDirector`, `AudioDirector`, `Shell`)
  acceden a servicios de escena solo entre `bind_scene()` y `unbind_scene()`;
  `SceneLoader` llama a `unbind_scene()` en todos los consumidores antes de
  `queue_free()` del mundo. — source: ADR-0009 § D6, Implementation Guidelines 8 ·
  Test (T-I2)
- **F-R35** Los controladores de puzle 11–16 reciben solo su `PuzzleServices` (campos
  de la tabla D7) y cada uno vive en `src/puzzles/p<N>_<slug>/`; los datos de otros
  puzles les llegan solo como argumento `flags` de `configure(def, flags)`. —
  source: ADR-0009 § D7, Implementation Guidelines 9 · Test (T-U4)
- **F-R36** Los errores de datos irrecuperables se notifican solo por `ctx.fatal`
  (`raise_fatal(code, detail)`, con el parámetro culpable en `detail`); un fatal en
  tiempo de escena se notifica además a 4 como fallo de carga. — source: ADR-0009
  § D8, Implementation Guidelines 10 · Test (T-U5)
- **F-R37** Las suites unitarias construyen el sistema con `TestContexts` (dobles
  escritos a mano en `tests/doubles/`); los dobles que son `Node` se liberan con
  `auto_free()`. — source: ADR-0009 § D9, Implementation Guidelines 11 · Test
  (exit 101 por huérfanos)
- **F-R38** `Atmosphere` (28) es un nodo en la raíz de cada escena de juego con un
  `AtmosphereZone` por sala, no un autoload. — source: ADR-0009 § D11 · Rev
- **F-R39** Todos los `AudioStreamPlayer*` pertenecen a 23 (`AudioDirector`,
  `ALWAYS`); las escenas solo aportan nodos marcador. — source: ADR-0002 G-8, § D2 · Rev

**Entrada (ADR-0006)**

- **F-R40** `EngineInputAdapter` (`src/input/engine_input_adapter.gd`) es el
  **único** fichero de `src/` que lee campos de subclases de `InputEvent`, llama a
  `Input.*`, lee nombres de mando, fija el modo del ratón o escucha el foco de
  ventana (excepción: firmas de `binding_from_event`/`es_imprimible` que solo
  reenvían). — source: ADR-0006 § Implementation Guidelines · CI‡ (grep `Input\.` /
  `InputEvent` fuera del adaptador; script no comprobado) + Rev
- **F-R41** La clase de dispositivo sale del **tipo** del evento (`event is
  InputEventKey` / `InputEventMouse*` / `InputEventJoypad*`) o de la comparación con
  las constantes `InputEvent.DEVICE_ID_KEYBOARD` (= **16**) y `DEVICE_ID_MOUSE`
  (= **32**); un evento de mando nuevo trae `device` 0 y `DEVICE_ID_EMULATION` = −1.
  — source: ADR-0006 § Implementation Guidelines; § Spike Results S-0006-D;
  `deprecated-apis.md` (4.7) · Rev
- **F-R42** Todo nombre de acción, asignación, umbral y etiqueta sale de
  `default_bindings.json`; ningún literal de tecla o botón fuera del adaptador y de
  ese JSON. — source: ADR-0006 § Implementation Guidelines · Rev
- **F-R43** `InputRouter` usa `GameClock` para los topes de `sin control` y de
  bloqueo, y `RealClock` para histéresis, gestos, `t_hold`, cursor y magnetismo;
  nunca `_process(delta)` para ninguno. — source: ADR-0006 § Implementation
  Guidelines; OI-1 (tope en `GameClock`) · Rev
- **F-R44** Exactamente un sink por (contexto, acción); los sistemas de escena lo
  enlazan en `configurar(ctx)` y los de `Shell`/autoload en `setup(ctx)`; el router
  comprueba `Callable.is_valid()` antes de llamar y descarta (con log) los sinks
  inválidos, así que un sistema puede liberarse sin desenlazar. — source: ADR-0006
  § Implementation Guidelines · Test
- **F-R45** Solo 4 (`&"scene_loader"`) y 21 (`&"scene_director"`) llaman a las
  operaciones de `sin control`, y solo por el puerto `InputContexts`
  (`open_no_control(owner, declared_s, absorbs_foreign)`, `close_no_control(owner)`);
  `SceneLoader.request_load` pasa `absorbs_foreign = true` si y solo si la razón es
  `partida_nueva` o `reanudar`; 7 usa `begin_blocking`. — source: ADR-0006
  § Implementation Guidelines; ADR-0003 O3 · Rev
- **F-R46** El router emite como mucho una acción por evento crudo y ejecuta el
  gancho de cambio (cancelar, latch, restaurar cursor, modo de ratón, aviso) en cada
  cambio **efectivo** de la pila, y solo en esos. — source: ADR-0006 § Implementation
  Guidelines · Test
- **F-R47** `get_binding_label` no tiene efectos laterales (los tests lo llaman dos
  veces y comparan); quien muestra etiquetas sondea `bindings_revision()`. — source:
  ADR-0006 § Implementation Guidelines; Alternative 4; OI-9 · Test
- **F-R48** Ningún consumidor del bus puede depender de que un aviso emitido en
  `_input` llegue a un suscriptor de `_physics_process` en el mismo fotograma, ni
  del orden de `_input` entre nodos. Medido en 4.7.2: `_input` corre en orden de
  árbol **inverso**, `_physics_process`/`_process` en orden de alta; a 60 Hz con
  fotogramas rápidos el suscriptor de física lo recibió una iteración después (el de
  `_process`, en el mismo). Una cola drenada una vez por tick o por fotograma es
  segura en ambos casos. — source: ADR-0006 § Spike Results «C1 / NS-7» (cierra el
  diferimiento de ADR-0001 § Spike Results «Acceptance») · Rev

**Datos y contenido (ADR-0005)**

- **F-R49** Los datos de juego se leen solo con `DataReader.read_file(entry)` (texto
  vía `FileStore` inyectado, parseo vía `JsonText.parse()`). `FileAccess` y `JSON`
  solo aparecen en `JsonText`, `RealFileStore` y los escritores de
  guardado/ajustes. — source: ADR-0005 § D5.1, G-1 · Rev
- **F-R50** Todo fichero de datos tiene entrada en `DataCatalog` y esquema antes de
  que se fusione su cargador; ruta `assets/data/<domain>/<snake_case>.json` (un
  nivel, sin ficheros en la raíz); fixtures de CI en `tests/fixtures/<domain>/`. —
  source: ADR-0005 § D1, G-2, G-3 · Test
- **F-R51** Todo fichero empieza con `schema_version` entero; un cargador rechaza
  toda versión que no implementa. — source: ADR-0005 G-4 · Test
- **F-R52** Los enteros se convierten solo con `DataReader.to_int()`: acepta `int`
  o `float` de parte fraccionaria 0 y magnitud ≤ 2^53; rechaza `2.5`, `true`, `"2"`,
  `null` con ERROR y ruta. Restauración de snapshot y ficheros de ajustes usan la
  misma función. Rechaza también no finitos (`stringify(NAN)` escribe `null`,
  `stringify(INF)` escribe `1e99999`). — source: ADR-0005 § D4; G-5; § Spike Results
  A1 (= ADR-0001 V-ENG-3), A4 · Test
- **F-R53** Colecciones con conjunto abierto de IDs = arrays de registros con `id`,
  nunca objetos indexados por ID: en 4.7.2 una clave duplicada en un objeto se
  fusiona **en silencio (gana la última)** y es indetectable tras el parseo.
  Excepción: mapas de conjunto cerrado que el esquema enumera. — source: ADR-0005
  § D5.3, G-6; § Spike Results A3 · Test
- **F-R54** `JsonText.parse()` envuelve `JSON.new().parse(text)` (error con línea y
  mensaje), no `JSON.parse_string` (devuelve `null` e imprime un error del motor). —
  source: ADR-0005 § D5.2; § Spike Results A2 · Test
- **F-R55** La comprobación de BOM se hace sobre los **bytes**
  (`FileAccess.get_file_as_bytes`) **antes** de decodificar: `get_string_from_utf8`
  y `FileAccess.get_file_as_string` quitan el BOM sin aviso y un chequeo sobre el
  `String` nunca dispara. — source: ADR-0005 § D5.4, G-16; § Spike Results A5 · Test
- **F-R56** Ficheros UTF-8 sin BOM, LF, JSON estricto (sin comentarios ni comas
  finales). El parser de 4.7.2 **acepta en silencio** coma final en array y objeto y
  ceros a la izquierda (`01` → 1.0): no se detectan tras el parseo; solo un
  pre-chequeo del texto en `JsonText` o el verificador los atrapa. — source:
  ADR-0005 § D5.2, G-16; § Spike Results A4 · Rev (pre-chequeo sin decidir, P-17)
- **F-R57** Tras `get_file_as_string` se lee `get_open_error()` en el acto: un
  fichero ausente devuelve `""`, indistinguible de uno vacío. — source: ADR-0005
  § Spike Results A6 · Test
- **F-R58** Los datos normalizados son inmutables; `ContentDB` y demás dueños de
  catálogo llaman a `make_read_only()` en los contenedores que guardan. — source:
  ADR-0005 § D5.6; § Spike Results A11 (parcial) · Rev
- **F-R59** Claves desconocidas = error salvo objeto declarado `open_with_warning`;
  añadir un campo exige tocar el esquema en el mismo commit. — source: ADR-0005 G-7 · Test
- **F-R60** Un cargador aplica la política de release de su fila del registro y
  nada más; una política más blanda exige cambiar la fila en ADR-0005. — source:
  ADR-0005 G-8 · Rev
- **F-R61** Todo texto visible por el jugador sale de `ContentDB`; los únicos
  literales permitidos son los de la lista de excepciones. — source: ADR-0005 § D7,
  G-9 · Rev
- **F-R62** `ContentDB` lee ficheros solo en `setup()` y `dev_reload()`; una lectura
  tras `READY` es un defecto. — source: ADR-0005 G-10 · Test (AC-21)
- **F-R63** Los IDs de variante se construyen con `ContentDB.variant_id(prefix,
  suffix)`. — source: ADR-0005 G-11 · Rev
- **F-R64** Un ID en `main` nunca se borra ni se reutiliza; se retira con `"status":
  "retired"`. — source: ADR-0005 § D9, G-12 · CI‡ (`--against=<ref>`, pendiente de O8)
- **F-R65** Los validadores recogen **todos** los problemas con fichero y
  `json_path`; la única llamada fatal lleva el parámetro del primer error. — source:
  ADR-0005 § D3, G-13 · Test
- **F-R66** El modo debug se decide por un `BuildFlavor` inyectado (`Boot`:
  `BuildFlavor.new(OS.is_debug_build())`; tests: `BuildFlavor.new(false)` para
  caminos de release). — source: ADR-0005 § Key Interfaces; ADR-0009 D3 paso 0 · Test
- **F-R67** Los presets de exportación incluyen `assets/data/*` y excluyen `tests/`,
  `tools/` y `prototypes/`; `tools/data_check/data_check.gd` no nombra ningún
  autoload y sale por `quit(code)` con 0/1/2. — source: ADR-0005 G-14, G-15, § D8 · Rev

### Forbidden Approaches

- **F-X01 Nunca señales de Godot para un aviso de la regla 10 del GDD 3 ni para un
  cambio de hecho** — orden entre receptores y reentrancia de `emit()` no
  documentados (NS-5); exigirían el mismo envoltorio. — source: ADR-0001 § D1, § D10,
  G-5, Alternative 1 · Rev
- **F-X02 Nunca `CONNECT_DEFERRED` como sustituto del bus** — rompe la entrega en el
  mismo frame y no ofrece `is_queue_empty()` para el guardado. — source: ADR-0001
  Alternative 2 · Rev
- **F-X03 Nunca una señal de contrato fuera de la lista de D10, entre pares o entre
  sistemas de la misma subcapa** — permitidas solo: Player (2) `paso`,
  `gesto_terminado`, `camara_cedida` → 7, 8, 20, 23; `elements_changed(tag)` del
  controlador → 9; `GameClock.paused_changed` (solo infraestructura). Una señal de
  contrato no lleva un cambio de hecho ni supone orden entre receptores; las
  señales de nodo del motor (`body_entered`, `finished`, `timeout`) no salen del
  sistema dueño. Añadir una exige firma del GDD y enmienda de ADR-0001. — source:
  ADR-0001 § D10, G-5; ADR-0009 § D4 «Contract signals» · Rev
- **F-X04 Nunca literales de cadena para nombres de aviso fuera de `notice_ids.gd` y
  tests.** — source: ADR-0001 G-2 · Rev
- **F-X05 Nunca una implementación de bus aparte para Settings** — dos
  implementaciones de la misma semántica. — source: ADR-0001 Alternative 4 · Rev
- **F-X06 Nunca un aviso separado «interacción rechazada»** — contradice GDD 7 D7-74
  y GDD 24 D24-9; se filtra `interaction_executed`. — source: ADR-0001 Alternative 5 · Rev
- **F-X07 Nunca una clase de payload tipada por aviso** (`RefCounted` por aviso) —
  coste desproporcionado; revisar solo si OI-5 lo reabre. — source: ADR-0001
  Alternative 3 · Rev
- **F-X08 Nunca depender de la entrega del bus en el mismo frame respecto a los
  callbacks de entrada, ni del orden del bucle principal entre `_input`,
  `_physics_process` y `_process` de nodos distintos** — C1/NS-7 ya **medida** en
  S-0006 (ver F-R48); las garantías de mismo frame vienen solo del drenaje
  síncrono. — source: ADR-0001 § Spike Results «Acceptance», NS-7; ADR-0006
  § Spike Results «C1 / NS-7» · Rev
- **F-X09 Nunca `assert` (ni `assert(false, …)`) como forma de detener la
  ejecución** — en 4.7.2 se elimina en release y, en debug, solo aborta la función
  actual. La parada dev es `push_error` + `get_tree().quit(1)` tras
  `OS.is_debug_build()` (F-R09), también en `DebugFatalHandler`. — source: ADR-0001
  § Spike Results V-ENG-4; ADR-0009 § D8 (enmienda 2026-11-11) · Rev
- **F-X10 Nunca `get_tree().create_timer()` (`SceneTreeTimer`), nodos `Timer` ni
  `Engine.time_scale` en `src/`** — ni para tiempo de juego ni para tiempo real en
  sistemas de juego/presentación; `create_timer` dispara en pausa por defecto (S16).
  — source: ADR-0002 § D6, G-3, Alternative 2; § Spike Results S16 · **CI**
  `tools/ci/forbid_timers.sh` (falla con `create_timer(` o `Timer.new(` en `.gd`
  fuera de `tests/`, `prototypes/`, `addons/`, …). **No cubre** nodos `Timer`
  declarados en `.tscn` ni `Engine.time_scale`: esos dos casos son Rev.
- **F-X11 Nunca escribir `SceneTree.paused` fuera de `TreePauseBackend`**; solo
  `GameClock` llama al backend; solo 25 llama a `GameClock.pause()`/`resume()`
  (solicitante `&"pause_menu"`; una consola dev puede usar el suyo). — source:
  ADR-0002 G-5 · Rev
- **F-X12 Ningún sistema de juego o presentación se conecta a
  `GameClock.paused_changed`** — consumen `pause_opened`/`pause_closed` del bus u
  observan que `GameClock` se paró. 21 y 22 no consumen los avisos de pausa. —
  source: ADR-0002 § D4, G-6 · Rev
- **F-X13 Nunca `get_tree().create_tween()` para tweens del mundo.** — source:
  ADR-0002 G-9 · Rev
- **F-X14 Nunca integrar el `delta` del motor en un acumulador propio de tiempo de
  juego.** — source: ADR-0002 § D1, G-1 · Rev
- **F-X15 Nunca añadir una instancia de mundo a `WorldSlot` mientras
  `GameClock.is_paused()`** (liberar el mundo en pausa sí está permitido). —
  source: ADR-0002 § D4, G-11 · Rev
- **F-X16 Nunca abrir la pausa con `carga_en_curso`**; `GameClock.pause()` lo
  comprueba vía `ErrorPolicy` en debug. — source: ADR-0002 G-12 · Rev
- **F-X17 Nunca `PROCESS_MODE_WHEN_PAUSED` en el slice** — `OptionsComponent` se
  reutiliza en el título con el árbol en marcha. — source: ADR-0002 § D2 nota,
  Alternative 4 · Rev
- **F-X18 Nunca pausa por avisos sin reloj central** (cada sistema parando sus
  propios temporizadores). — source: ADR-0002 Alternative 3 · Rev
- **F-X19 Nunca nombrar un autoload fuera de `boot.gd`, ni `get_node("/root/…")`, ni
  `Engine.get_singleton()` para servicios del proyecto.** — source: ADR-0009 § D3,
  Alternative 1 · CI‡ (`list_autoload_refs.sh` no existe aún) + Rev
- **F-X20 Nunca un service locator** (`Services.get(&"x")`) — sin tipos y
  dependencias resueltas en cualquier momento. — source: ADR-0009 Alternative 2 · Rev
- **F-X21 Nunca `NodePath` exportados / `@export var x: Node` para referencias entre
  sistemas** (permitido solo para el propio subárbol vía `%Unique` + `@onready`). —
  source: ADR-0009 Alternative 3, § D3 regla 2 · Rev
- **F-X22 Nunca dejar que un autoload herede `process_mode` de `root`.** — source:
  ADR-0009 § D2 · Test (T-U6)
- **F-X23 Un controlador de puzle nunca referencia `PuzzleFramework`, otro
  `PuzzleController`, `GameState` ni el lado escritor de `InteractionSystem`; un
  script de `p<N>_*` nunca hace `preload`/`load` ni nombra un `class_name` de otra
  carpeta `p<N>_*`; ningún campo de `PuzzleServices` expone controladores ni estado
  público de un puzle.** — source: ADR-0009 § D7 · CI‡
  (`list_puzzle_cross_refs.sh` no existe aún) + Test (T-U4)
- **F-X24 Ningún sistema llama a `get_tree().quit()`, hace `assert` sobre datos ni
  muestra UI de error por su cuenta.** — source: ADR-0009 § D8 · Rev (excepciones:
  la implementación de `ErrorPolicy`/`DebugFatalHandler`, F-R09, y la herramienta
  `tools/data_check/`, F-R67)
- **F-X25 Un servicio persistente nunca cachea un servicio de escena fuera de la
  ventana bind/unbind.** — source: ADR-0009 § D6 · Test (T-I2)
- **F-X26 17 (Pistas) nunca llama a 25**: publica `HintPanelProvider` en
  `SceneServices.hint_panel` y 25 lo consulta. — source: ADR-0009 § D6 · Rev
- **F-X27 Una suite unitaria nunca toca un autoload registrado ni depende de
  `mock()`/`spy()` de gdUnit4 para construir un sistema.** — source: ADR-0009 § D9 · Rev
- **F-X28 Nunca `Atmosphere` como autoload.** — source: ADR-0009 Alternative 4, § D11 · Rev
- **F-X29 Nunca comparar `InputEvent.device` con `0` ni deducir «no es mando» de un
  id negativo** — teclado y ratón son 16 y 32 (positivos). — source: ADR-0006
  § Implementation Guidelines; § Spike Results S-0006-D · Rev
- **F-X30 Nunca `Input.is_action_*`, `Input.get_vector` ni `InputMap.*` en código de
  juego, ni modificar el Input Map del motor en tiempo de ejecución** — las acciones
  llegan por sinks y por sondeo de `InputRouter`; el Input Map como almacén de
  asignaciones se rechazó (sin orden de ranuras, API de mutación NOT SOURCEABLE,
  sin filtro por contexto). — source: ADR-0006 § Implementation Guidelines,
  Alternative 1 · CI‡ + Rev
- **F-X31 Nunca un `Node` por contexto con su propio `_unhandled_input`** — depende
  del orden de propagación y de `set_input_as_handled`, y duplica gestos/topes. —
  source: ADR-0006 Alternative 2 · Rev
- **F-X32 Nunca cursor virtual moviendo el ratón del SO ni eventos de ratón
  sintéticos** — rompe la histéresis y el uso de dos dispositivos a la vez. —
  source: ADR-0006 Alternative 3 · Rev
- **F-X33 Nunca un aviso «asignaciones cambiadas» en el bus** — se usa
  `bindings_revision()`. — source: ADR-0006 Alternative 4 · Rev
- **F-X34 Nunca `int(x)`, `x as int` ni `floori(x)` sobre datos parseados** —
  `int(2.7)` trunca en silencio. — source: ADR-0005 § D4.3, G-5 · Rev
- **F-X35 Nunca confiar en el parser para rechazar claves duplicadas, comas finales
  ni BOM** — los tres pasan sin error en 4.7.2. — source: ADR-0005 § Spike Results
  A3, A4, A5 · Test
- **F-X36 Nunca leer un fichero de datos sin entrada en `DataCatalog`.** — source:
  ADR-0005 G-2 · Rev
- **F-X37 Nunca `tr()`, `TranslationServer` ni recursos `Translation` para texto del
  jugador; nunca concatenar IDs de variante a mano.** — source: ADR-0005 § D7, G-9,
  G-11, Alternative 3 · Rev
- **F-X38 Nunca `.tres` en lugar de JSON para datos de juego, ni ficheros
  `*.schema.json`** — contradice los GDD firmados; dos dialectos para un trabajo (el
  esquema es GDScript). — source: ADR-0005 Alternatives 1–2, § D2 · Rev
- **F-X39 Nunca validar todo en el arranque de release** (release = solo nivel L;
  nivel B solo en debug/CI). — source: ADR-0005 § D3, Alternative 4 · Rev
- **F-X40 Nunca borrar ni reutilizar un ID ya en `main`.** — source: ADR-0005 § D9,
  G-12 · CI‡

### Performance Guardrails

- **F-G01 Lectura de hechos** (`get_fact_at`, ~35 lecturas por paso de física):
  < 0,02 ms por paso en total. Medido en headless: 0,00073–0,00077 ms/paso
  (indexado); asignaciones no medidas. — source: ADR-0001 § Performance
  Implications; § Spike Results V-ENG-2
- **F-G02 Drenaje del bus**: < 0,05 ms por drenaje de 10 entradas; coste 0 por frame
  en reposo (sin `_process`). — source: ADR-0001 § Performance Implications
- **F-G03 Memoria del bus**: < 50 KB (20 hechos + ~60 suscripciones + cola ≤ 64);
  una escritura idéntica no asigna ni encola nada. — source: ADR-0001 § Performance
  Implications, I-2
- **F-G04 Cadena de avisos**: `max_chained_notices` = 64 (seguro 8–256) por drenaje
  síncrono; al superarlo: descarte + log + `ErrorPolicy.fail` + un
  `notices_dropped`. — source: ADR-0001 § D5, I-6
- **F-G05 Carga de `flags.json`**: < 1 ms. — source: ADR-0001 § Performance Implications
- **F-G06 `GameClock`**: un `advance()` por frame; ≤ ~50 temporizadores programados
  en el slice; < 1 KB. — source: ADR-0002 § Performance Implications
- **F-G07 Paso máximo de tiempo de juego**: `max_frame_delta_s` = 0,25 (seguro
  0,05–0,5) en `assets/data/core/clock.json` ‡; un tirón más largo ralentiza el
  tiempo de juego en vez de saltar temporizadores. — source: ADR-0002 § Tuning
- **F-G08 Composición**: coste 0 por frame; las búsquedas punteadas de `require()`
  solo en arranque/carga (~30 `configurar()` por carga). — source: ADR-0009
  § Performance Implications, § D3
- **F-G09 Entrada**: ≤ 0,05 ms/frame (≤ ~20 comparaciones por evento, un paso de
  cursor/imán sobre ≤ ~30 objetivos); < 50 KB; parseo de `default_bindings.json`
  < 1 ms. Medido por el test P-1. — source: ADR-0006 § Performance Implications
- **F-G10 Datos (provisional, registro, no puerta, hasta QQ-04)**: nivel L de todos
  los ficheros de arranque ≤ 50 ms y nivel B ≤ 150 ms en la máquina de desarrollo;
  memoria ≤ 2 MB ‡; coste 0 por frame. Medido: parseo de 317 KB sintéticos, mediana
  12,3 ms (máx. 16,5). — source: ADR-0005 § Performance Implications; § Spike Results
  A12

---

## Core Layer Rules

*Aplica a: 6 Ajustes (C1), 2 Jugador y 4 Escena (C2), 5 Guardado y 23 Audio (C3)
(`architecture.md` § System Layer Map; ADR-0009 § D4).*

**Reglas propias para 4 Escena (ADR-0003) y 2 Jugador (ADR-0012).** 6 Ajustes, 5
Guardado y 23 Audio siguen **sin reglas propias** (ADR-0007, -0004, -0008
`Proposed`); les obligan F-R16/F-R17, F-R18, F-R26, F-R32, F-R34, F-R39.

### Required Patterns

**Carga de escena (ADR-0003)**

- **C-R01** `Shell` (`res://src/shell/shell.tscn`) es la escena principal y nunca se
  descarga; tiene un único `Node3D` `WorldSlot` con **como mucho un** hijo (`title`,
  `planta` o `recepcion`). `SceneLoader` es el único código que añade o quita hijos
  de `WorldSlot`. — source: ADR-0003 § D1, § Implementation Guidelines · Rev
- **C-R02** `SceneLoader` es el único emisor de «carga de escena iniciada / lista /
  terminada / fallida», «escena lista», «partida terminada» y «descarga total
  solicitada / completada»; `ZoneHub` es el único emisor de «zona activada». «Partida
  terminada» solo justo tras «terminada» de `recepcion`, mismo fotograma;
  `request_full_unload()` es el único camino a «descarga total completada» (desde
  Lista y Error). — source: ADR-0003 § D7, § Implementation Guidelines · Test
- **C-R03** Carga síncrona en el fotograma siguiente a que el telón llega a α = 1,
  detrás de un `SceneSource` inyectado (real: `load` + `instantiate()`; test:
  fábrica falsa). — source: ADR-0003 § D4 · Test
- **C-R04** La escena nueva se instancia en un fotograma **estrictamente posterior**
  al `queue_free` de la vieja (paso 3 → paso 4 = U → U+1). Medido en 4.7.2: la
  instancia vieja sigue `is_instance_valid` en el fotograma U y deja de serlo en U+1
  (10/10, también con el árbol en pausa), 0 huérfanos. — source: ADR-0003
  § Implementation Guidelines; § Spike Results S-0003-A · Test
- **C-R05** `SceneLoader` lee el tiempo (`t_espera`, fundidos, `t_unload`) solo de un
  `RealClock` inyectado. — source: ADR-0003 § D5, § Implementation Guidelines · Test
- **C-R06** Todo elemento de escena con estado implementa `configurar(ctx:
  ServiceContext) -> void`, está en el grupo `scene_element`, lee ahí sus hechos y
  termina síncrono o toma un hold con ID único (`&"<system>:<element_id>"`); los
  holds se liberan por ID. «Escena lista» ⇔ conjunto de holds vacío tras el paso 6. —
  source: ADR-0003 § D5, § Implementation Guidelines · Test
- **C-R07** Ciclo de `sin control`: 4 lo **abre** (4, `D_carga`) justo tras emitir
  «iniciada»; pide reset de pila solo al liberar una escena de juego (liberar el
  título **no** es una descarga); pide `exploración` en «terminada» si
  `control_final = exploracion`; restaura `menú` en fallo y en descarga total. Con
  `control_final = ninguno`, 4 no toca la pila tras «terminada» y 21 hace el
  traspaso en ese fotograma. — source: ADR-0003 § D2, § D6 · Test
- **C-R08** Un `Player` por escena de juego, recolocado con `player.colocar(pos, yaw,
  pitch)` desde el ancla de aparición; nada del Player cruza una carga. — source:
  ADR-0003 § D3 · Test
- **C-R09** Zonas: cada `T-…` es un `Area3D` (`ZoneTrigger`) sin lógica salvo
  reenviar su ID al `ZoneHub`, con `monitoring = false` en el `.tscn` y máscara solo
  de la capa `zone_sensor`; el sensor del Player es una `SphereShape3D` de
  `radio_sensor_zona` solo en `zone_sensor` y `monitorable = true`. `SceneLoader`
  activa `monitoring` en el fotograma de «terminada» (medido: 0 entradas mientras
  está desactivado; 1 entrada un tick después de activarlo con el sensor dentro). —
  source: ADR-0003 § D8, § Implementation Guidelines; § Spike Results S-0003-B.3 · Test
- **C-R10** Banda de activación de zona: centro del sensor en `X = cara − radio +
  (0, v·dt]`; para `T-PAS-1` = **(8,95; 8,977]**, nunca antes de 8,95 (Jolt informa
  en el primer tick tras cruzar la cara; idéntico a 30, 60 y 144 fps). Tests y GDD
  usan este rango. — source: ADR-0003 § D8 (resuelto 2026-11-11), O8; § Spike Results
  S-0003-B.1, B.4 · Test (`adr0003_zone_sensor_jolt_test.gd`)
- **C-R11** `ZoneHub` sella cada entrada con `Engine.get_physics_frames()` y ordena
  él mismo por (tick, ID): el motor **no** entrega en orden de ID ni de alta (medido:
  T-A antes que T-B aunque T-B se añadió primero). — source: ADR-0003 § D8; § Spike
  Results S-0003-B.2, B.5 · Test
- **C-R12** `SceneLoader`, `Curtain` y `ErrorPanel` corren con
  `PROCESS_MODE_ALWAYS`; el `CanvasLayer` del telón tiene el `layer` más alto de la
  pila salvo `ErrorPanel`. — source: ADR-0003 § Implementation Guidelines · Rev
- **C-R13** `load_transitions.json` se valida en el arranque
  (`SceneLoader.validate`); inválido o ausente → manejador fatal con
  `DATOS_ESCENA_INVALIDOS`. — source: ADR-0003 § Implementation Guidelines · Test

**Jugador (ADR-0012)**

- **C-R14** El movimiento se integra solo en `_physics_process`, con `dt = 1 /
  f_fisica` fijo (60 Hz), tras la guarda de pausa; nunca se mueve el cuerpo desde
  `_process`. `player.json` lleva `f_fisica` y el arranque lo compara con la tasa del
  motor (discrepancia = fatal). — source: ADR-0012 § D1, P-1; § Spike Results NP-2 · Test
- **C-R15** La interpolación de presentación va por `TickInterpolator`
  (`prev ← curr ← new` por tick; `lerp(prev, curr, α)` por fotograma), con
  **α = `Engine.get_physics_interpolation_fraction()`**. `TickInterpolator` **no**
  lleva acumulador propio: el acumulador espejo de § D2 falló en S-0012-A (desviación
  13,8 % a 30 fps, 25,9 % a 60, 69,9 % a 144; saltos no monótonos), la fracción del
  motor dio ≤ 1e-13 y 0 fotogramas no monótonos, y funciona con la interpolación del
  motor apagada. `reset(p)` en `colocar` y en la recolocación de seguridad. — source:
  ADR-0012 § Status (R1); § Spike Results S-0012-A; § D2 (reset) · Test (T-U2) — ver
  contradicción X-01
- **C-R16** La interpolación física 3D del motor queda **apagada** y se fija
  explícitamente en `project.godot` (hoy lee `false` por defecto; los prototipos la
  ponen a `true`: no copiarlos). — source: ADR-0012 § D2, P-3; § Spike Results
  S-0012-F · Rev
- **C-R17** El cuerpo nunca se rota; yaw y pitch viven en floats del `Player` y se
  aplican solo a `Look`. La mirada se aplica 1:1 en el fotograma en que se consume,
  sin `dt`, filtro ni aceleración; el roll nunca se escribe. — source: ADR-0012 P-2,
  P-4 · Test (T-U3)
- **C-R18** Los servicios (`rayo_vision`, sensor de zona, `PoseHistory`,
  `pose_actual`) leen el estado **físico**; solo `Rig`/`Look`/`Bob`, `MainCamera` y
  `HandsRig` leen valores interpolados. — source: ADR-0012 P-5 · Rev
- **C-R19** Todo tiempo de arrendamiento de cámara, gestos, traspasos, fundidos de
  objeto, cadencia de pose segura y rampa de bob sale del `GameClock` inyectado. —
  source: ADR-0012 P-6 · Test
- **C-R20** Ángulos públicos en radianes, `fov_actual()` en grados; los datos usan
  claves `_deg` convertidas una vez en `PlayerConfig`. — source: ADR-0012 P-7 · Test
- **C-R21** La superficie pública es exactamente GDD 2 regla 33 + `configurar`; un
  test compara las listas de métodos y señales. Las peticiones se responden
  síncronas con `bool` (+ log) y nunca emiten señal reentrante; las señales de
  llegada salen de `_process`/`_physics_process`. — source: ADR-0012 P-8, P-9 · Test (T-U14)
- **C-R22** Lógica del Player (`Locomotion`, `StepTracker`, `BobMath`, `CameraFov`,
  `CameraLease`, `PoseHistory`, `YawWindow`, `StuckGuard`, `HandSlots`,
  `TickInterpolator`) = `RefCounted` sin motor; todo lo dependiente del motor detrás
  de los puertos de § Key Interfaces. — source: ADR-0012 P-11 · Test
- **C-R23** Mientras el Player sujeta un objeto, solo el Player escribe su
  `global_transform`. — source: ADR-0012 P-12 · Rev
- **C-R24** `CharacterBody3D` con propiedades por defecto (`floor_snap_length`,
  `safe_margin`, …); S-0012-C pasó sin ajustes. La etiqueta de suelo se lee como
  `get_slide_collision(i).get_collider().get_meta("surface")`. — source: ADR-0012
  § D1; § Spike Results S-0012-C · Test
- **C-R25** Red de seguridad por cápsula reducida: una consulta de forma por tick; el
  umbral `eps_atasco_m` se elige sabiendo que el caso de junta de 0,03 m cambia de
  resultado exactamente en eps (eps 0,02 → true; eps ≥ 0,03 → false). — source:
  ADR-0012 D11; § Spike Results S-0012-D · Test (T-U11)
- **C-R26** Animación de manos en modo manual (`ANIMATION_CALLBACK_MODE_PROCESS_MANUAL`
  + `advance(dt)` con `GameClock.delta()`); un parámetro de `AnimationTree` surte
  efecto en el siguiente `advance`. — source: ADR-0012 § Spike Results S-0012-E · Test
- **C-R27** FOV vertical (`keep_aspect` por defecto `KEEP_HEIGHT`, medido); el tope
  horizontal (p. ej. 32:9) lo aplica `CameraFov.to_engine()`, el motor no lo hace. —
  source: ADR-0012 § Spike Results S-0012-B · Test (T-U5)

### Forbidden Approaches

- **C-X01 Nunca `SceneTree.change_scene_to_file`, `change_scene_to_packed` ni
  `reload_current_scene`** — cede al motor el orden fotograma a fotograma de los
  pasos 3–6 e infla la lista de autoloads. — source: ADR-0003 § D1, Alternative 1 ·
  CI‡ (grep sobre `src/`; script no comprobado)
- **C-X02 Nunca dos escenas de juego residentes a la vez** (precarga aditiva). —
  source: ADR-0003 Alternative 2 · Rev
- **C-X03 Nunca carga en hilo (`ResourceLoader.load_threaded_*`)** sin un ADR nuevo
  que revise D4. — source: ADR-0003 § D4, Alternative 3 · Rev
- **C-X04 Nunca un `Player` persistente reparentado entre escenas.** — source:
  ADR-0003 § D3, Alternative 4 · Rev
- **C-X05 `SceneLoader` nunca lee `_process(delta)` ni `GameClock`, nunca escribe un
  hecho (solo lee `llamada_completada`) y nunca guarda ni pide guardar.** — source:
  ADR-0003 § Implementation Guidelines · Rev
- **C-X06 Nunca contar holds a mano.** — source: ADR-0003 § Implementation Guidelines · Rev
- **C-X07 Nunca exigir desuscribirse del bus en `_exit_tree` como requisito de
  corrección** (es higiene permitida; el bus tolera suscriptores liberados). —
  source: ADR-0003 § Implementation Guidelines · Rev — ver nota X-04
- **C-X08 Nunca una capa de UI por encima del telón salvo `ErrorPanel`.** — source:
  ADR-0003 § Implementation Guidelines · Rev
- **C-X09 Nunca un acumulador propio de α en `TickInterpolator`** (deriva respecto al
  motor, α se satura y la cámara salta). — source: ADR-0012 § Spike Results S-0012-A
  (R1) · Test (T-U2)
- **C-X10 Nunca suavizado exponencial de posición u orientación de cámara**
  (`lerp(cam, body, 1 − exp(−k·dt))`) — añade latencia dependiente de fps. —
  source: ADR-0012 P-3, Alternative 2 · Rev
- **C-X11 Nunca encender la interpolación física 3D del motor ni llamar a
  `get_global_transform_interpolated()` / `reset_physics_interpolation()`.** —
  source: ADR-0012 P-3, Alternative 1 · Rev (única API de NP-3 permitida: la de C-R15)
- **C-X12 Nunca mover el cuerpo con el delta de fotograma en `_process`.** — source:
  ADR-0012 P-1, Alternative 3 · Rev
- **C-X13 Nunca rotar el `CharacterBody3D` con el yaw.** — source: ADR-0012 P-2,
  Alternative 4 · Rev
- **C-X14 Nunca un informe de penetración del motor para la red de seguridad.** —
  source: ADR-0012 Alternative 5 · Rev
- **C-X15 Nunca terminar una regla del Player con `animation_finished`, `Timer`,
  `create_timer()`, `Tween` ni señales de `AnimationPlayer`** — el animador es
  orientativo; el tope (`tope`) decide. — source: ADR-0012 P-6, Alternative 6 · Rev
- **C-X16 El Player nunca se suscribe, emite ni lee el bus de 3, y nunca entra en el
  snapshot de guardado.** El contexto activo se sondea con `top()` por
  `PlayerInputPort`. — source: ADR-0012 P-10, C4 · Test (AC-39)

### Performance Guardrails

- **C-G01 Player (provisional hasta ADR-0019)**: ≤ 0,15 ms media / 0,40 ms pico por
  tick de física; ≤ 0,10 / 0,25 ms por fotograma en `_process`; manos + IK ≤ 0,20 ms;
  1 consulta de forma por tick; 0 asignaciones por fotograma salvo ≤ 1 `PlayerPose`;
  ≤ 64 KB; total ≤ 0,5 ms del fotograma. Un incumplimiento se escala a
  technical-director, no se ajusta en silencio. Medido: `move_and_slide` media 107 µs,
  p99 246 µs (headless, con registro); sonda 0,0024 ms. — source: ADR-0012 § D11;
  § Spike Results S-0012-C, S-0012-D
- **C-G02 Carga de escena**: `SceneLoader._process` despreciable en reposo;
  `ZoneHub` ordena unas pocas entradas por fotograma; una sola escena de juego
  residente. Negro nominal ≈ 1,63 s para `recepcion`; el tirón de `planta` gris está
  sin medir (P-20). — source: ADR-0003 § Performance Implications

---

## Feature Layer Rules

*Aplica a: 7 Interacción (F1), 20 Bolsillo (F2), 19 Ordenador (F3), 9 Marco y 10
Caja (F4), 8 Acceso, 11–16 controladores, 17 Pistas, 21 Director, 22 Llamada (F5).*

**Reglas propias para 7 Interacción (ADR-0011), 9 Marco y 11–16 (ADR-0010), 21
Director y 22 Llamada (ADR-0017).** 8, 10, 17, 19 y 20 no tienen ADR propio; les
obligan las reglas Foundation (F-R05, F-R08, F-R28–F-R35, F-X03, F-X23, F-X26) y los
contratos de abajo que los nombran.

### Required Patterns

**Interacción (ADR-0011)**

- **FE-R01** Los contactos de F1 se calculan con `PickMath` sobre `PickRegistry`
  (aritmética); la única consulta física de 7 es `intersect_ray` con
  `collision_mask = mascara_geometria` (bit 1), detrás de `OcclusionProbe`. Medido:
  error de profundidad ≤ 8,3e-7 m; `query.exclude: Array[RID]` salta el cuerpo; bit 1
  ignora bits 2–5. — source: ADR-0011 G-1, G-2; § Spike Results S-0011-B · Test (T-I1)
- **FE-R02** Un rayo cuyo origen está **dentro** de un sólido es un **fallo**: en
  4.7.2 `hit_from_inside` es `false` por defecto y devuelve `{}`. No se activa
  `hit_from_inside`. — source: ADR-0011 § Spike Results S-0011-B «inside» · Test (T-I1)
- **FE-R03** Si se usa `intersect_shape` (solo camino de escalado D11, no en el
  slice), se pasa **`max_results` explícito ≥ nº de volúmenes** de pick: por defecto
  es 32 y trunca (64 → 40, 32 → 32); el resultado **no** viene ordenado por distancia
  ni por ID. — source: ADR-0011 § D11; § Spike Results S-0011-A (a) · Test
- **FE-R04** Todo volumen de pick = un único `BoxShape3D` sin escalar en la capa
  bit 3 solamente, con `monitoring` y `monitorable` apagados (siguen siendo
  consultables, medido). — source: ADR-0011 G-3; § Spike Results S-0011-A (a) · Test
  (T-S3, lint de escena)
- **FE-R05** `_physics_process` de 7 empieza con la guarda de pausa y retorna pronto
  fuera de `EXPLORACION` estable; la pausa se detecta sondeando `is_paused()`. —
  source: ADR-0011 § D10, G-4, G-11 · Test (T-U10)
- **FE-R06** `can_interact` solo para supervivientes de D3 y el objetivo retenido, a
  lo sumo una vez por entrada y paso; los manejadores no tienen efectos laterales en
  él. — source: ADR-0011 G-5 · Test
- **FE-R07** 7 emite exactamente un `interaction_executed` por pulsación procesada,
  con `resultado` de `InteractionTypes.RESULTADO_*`; nunca en cooldown, transición o
  pulsación cancelada. — source: ADR-0011 G-6 · Test (T-U4)
- **FE-R08** `ViewMetrics` es el único sitio de conversión px ↔ m; el código de
  puzle la recibe por `InteractionQuery`. El eje de FOV le llega como dato; la cámara
  del Player fija keep-height **explícitamente** en su `.tscn` (por defecto ya es
  `KEEP_HEIGHT`, medido). — source: ADR-0011 G-7, G-8; § Spike Results S-0011-C · Test (T-U5)
- **FE-R09** `seleccionar` llega al receptor como un único evento `FIN` con
  `elemento` (pick al pulsar) y `elemento_bajo` (pick al soltar). — source: ADR-0011
  G-9 · Test (T-U6)
- **FE-R10** Sin asignaciones por paso en el barrido; `get_target()` devuelve un
  diccionario cacheado. — source: ADR-0011 G-10 · Test (T-P1)
- **FE-R11** El orden entre dos `_physics_process` se fija con
  `process_physics_priority` (medido: prioridad 0 antes que 10 en 30/30 pasos aunque
  se añadió segundo). — source: ADR-0011 § Spike Results S-0011-C «order» · Test

**Marco de puzles y controladores (ADR-0010)**

- **FE-R12** Los controladores extienden `PuzzleController` (forma de dos líneas
  `@abstract` / `class_name`); los overrides tipados hacen `return` explícito (4.7). —
  source: ADR-0010 § D2, Implementation Guidelines 1, 10 · Test (T-U1)
- **FE-R13** `evaluate()` es **pura**: sin lecturas de reloj, sin escribir miembros,
  sin señales. Solo `PuzzleFramework` la llama, desde un camino de
  `ValidationPolicy` o el recálculo de D5.1. — source: ADR-0010 § D2, Implementation
  Guidelines 2–3 · Test (T-U3)
- **FE-R14** Todo camino que cambia estado termina en `policy.on_change(rt)`. —
  source: ADR-0010 Implementation Guidelines 4 · Test
- **FE-R15** Todo tiempo del marco va por `PuzzleTimers`/`GameClock`. — source:
  ADR-0010 § D6, Implementation Guidelines 5 · Test
- **FE-R16** Escrituras antes que avisos, en el orden exacto de D5.3. — source:
  ADR-0010 § D5.3, Implementation Guidelines 6 · Test (T-U8)
- **FE-R17** Eventos durante un bloqueo se **descartan**, nunca se encolan. —
  source: ADR-0010 Implementation Guidelines 7 · Test (T-U7)
- **FE-R18** Los campos enteros llegan a los controladores ya convertidos a `int`
  (ADR-0005 D4). — source: ADR-0010 Implementation Guidelines 11 · Test
- **FE-R19** `request_hint` devuelve `HintOutcome` (`-> int`); la reaplicación nunca
  llama a `evaluate()`, nunca aplica `AUTO_SOLVE_ELEMENT` y nunca emite
  `hint_applied`; 9 nunca presenta efectos de pista `TEXT` (reenvía `text_key`). —
  source: ADR-0010 § D9, Implementation Guidelines 8–9, Alternative 5 · Test (T-U11)
- **FE-R20** `Verdict` es un objeto de valor tipado e inmutable (`payload` solo para
  fuentes `value_from`); las cinco políticas de validación son objetos estrategia. —
  source: ADR-0010 § D3, § D4, Alternatives 3–4 · Test (T-U2, T-U6)

**Director de escenas y llamada (ADR-0017)**

- **FE-R21** Línea de tiempo, cadena y llamada leen el tiempo solo del `GameClock`
  inyectado (`now`, `deadline`, `is_due`); `t_rel = now − origin`, nunca un
  acumulador. — source: ADR-0017 G-1 · Test (T-TL-01, T-TL-02)
- **FE-R22** 21 descarta toda ejecución viva y su cadena con `scene_load_started`,
  `scene_load_failed`, `no_control_absorbed` (`dueno = &"scene_director"`),
  `full_unload_requested`, `state_reset` y `state_restored`; descartar no emite
  órdenes, operaciones de pila ni hechos. — source: ADR-0017 G-2 · Test
- **FE-R23** 21 es el único emisor de `scene_effect_requested`,
  `object_state_requested` y `end_card_requested`, siempre vía `CueEmitter`. —
  source: ADR-0017 G-3 · Test (T-21-06)
- **FE-R24** `reducir_movimiento` se lee en cada emisión de un cue con
  `si_reducir_movimiento`, nunca cacheado en el arranque. — source: ADR-0017 G-5 ·
  Test (T-21-03)
- **FE-R25** 21 llega a `cerrar_modos()` solo por el contexto de escena entre
  `bind_scene()` y `unbind_scene()`. — source: ADR-0017 G-6; ADR-0009 § D6 · Test
- **FE-R26** Los valores de `scenes.json`, `director_config.json` y `call.json` no
  se duplican como constantes; los de dueño único se leen de su dueño (p. ej.
  `d_cierre` de 4). — source: ADR-0017 G-7 · Rev
- **FE-R27** `choose()` de 22 ignora la entrada antes del plazo de guarda y toda
  segunda elección; la primera aceptada es final. — source: ADR-0017 G-8 · Test (T-22-03)
- **FE-R28** Cada `LineWait` se construye en el fotograma en que se emite su
  `line_requested`, y su dueño le reenvía todo `line_finished`/`line_no_audio`/
  `line_failed`. — source: ADR-0017 G-9 · Test (T-TL-03)

### Forbidden Approaches

- **FE-X01 Nunca `intersect_shape` ni `ShapeCast3D` para el foco en el slice** —
  `ShapeCast3D` informa solo del contacto más cercano (medido: 1 de 8 cajas). —
  source: ADR-0011 G-1, Alternatives 1–2; § Spike Results S-0011-A (b) · Rev
- **FE-X02 Nunca abanico de 7 rayos para F1, ni picking por rayo físico en vistas.**
  — source: ADR-0011 Alternatives 3–4 · Rev
- **FE-X03 Nunca codificar 1080, 1920, 70° ni 1 200 ppm, ni asumir FOV vertical y
  H = 1080** (error de eje = 78 % de ppm). — source: ADR-0011 G-7, Alternative 5 · Rev
- **FE-X04 7 nunca abre `sin control`** (usa `begin_blocking`) **ni se conecta a
  `GameClock.paused_changed`.** — source: ADR-0006 § Implementation Guidelines;
  ADR-0011 G-11 · Rev
- **FE-X05 Un controlador nunca referencia `PuzzleFramework`, `GameState`,
  `FactWriter`, el bus, otro controlador ni `InteractionSystem`, ni re-parsea JSON.**
  — source: ADR-0010 Implementation Guidelines 1, 11; ADR-0009 § D7 · CI‡
  (`list_puzzle_cross_refs.sh`) + Test
- **FE-X06 Nunca `Timer`, `create_timer` ni `await` sobre temporizadores del árbol
  en `src/puzzles/`.** — source: ADR-0010 Implementation Guidelines 5 · CI (parcial,
  `forbid_timers.sh`) + Rev
- **FE-X07 Nunca controladores «gordos»** (temporizadores, escrituras y avisos
  propios), **ni puzles solo-datos con intérprete genérico.** — source: ADR-0010
  Alternatives 1–2 · Rev
- **FE-X08 Nunca `Timer`, `create_timer`, `GameClock.schedule()` ni `await` sobre
  tiempo en línea de tiempo, cadena o llamada** (más estricto que ADR-0002 D6, que
  admite `schedule()`). — source: ADR-0017 G-1, § D2.5, Alternative 1 · Rev
- **FE-X09 Nunca `AnimationPlayer`/`Tween` como línea de tiempo de escenas, ni un
  director con lenguaje de reglas en datos.** — source: ADR-0017 Alternatives 2–3 · Rev
- **FE-X10 Los ejecutores nunca responden a `scene_effect_requested`,
  `object_state_requested` ni `end_card_requested`.** — source: ADR-0017 G-3 · Rev
- **FE-X11 21 nunca pide líneas `VO_G_*` ni encola líneas (la cola es de 23); 22
  nunca pide `SFX_*` por `line_requested`.** — source: ADR-0017 G-4, § D10,
  Alternative 5 · Test (T-21-01)

### Performance Guardrails

- **FE-G01 Interacción (provisional hasta ADR-0019)**: barrido ≤ 0,25 ms media /
  0,5 ms pico por paso con 40 entradas (≤ 8 rayos de oclusión); picking ≤ 0,05 ms por
  fotograma en vistas; 0 fuera de `exploración`/vistas y en pausa; registro < 1 ms al
  construir. Medido (proxy): media 0,0137 ms, p99 0,029 ms. — source: ADR-0011
  § Performance Implications; § Spike Results S-0011-A (d)
- **FE-G02 Marco de puzles**: < 0,05 ms/fotograma (objetivo, registrar en S0);
  estado < 50 KB. — source: ADR-0010 § Performance Implications
- **FE-G03 Director y llamada**: ≤ 3 ejecuciones vivas + una cadena por fotograma,
  muy por debajo de 0,05 ms; sin asignaciones en régimen; < 50 KB; parseo < 5 ms. —
  source: ADR-0017 § Performance Implications

---

## Presentation Layer Rules

*Aplica a: 24 Prompt, 25 Pausa, 26 Subtítulos, 27 Título, 28 Atmósfera, 29 Shaders;
render, audio de presentación, UI, VFX.*

**SIN ADR PROPIO `Accepted`** (ADR-0013, -0014, -0015, -0016 son `Proposed`). Las
reglas de abajo vienen de ADR aceptados de otras capas que obligan a sistemas de
presentación; no cubren render, iluminación, shaders ni subtítulos.

### Required Patterns
- **P-R01** Foco de UI con mando/teclado por `grab_focus()`; toda pantalla se prueba
  por las dos vías (foco dual). — source: ADR-0006 § Implementation Guidelines · Test
- **P-R02** El telón (`Curtain`) es el `CanvasLayer` más alto salvo `ErrorPanel`, y
  corre en `ALWAYS`. — source: ADR-0003 § Implementation Guidelines (C-R12) · Rev
- **P-R03** El texto que muestran 24–27 sale de `ContentDB` (F-R61, F-X37). —
  source: ADR-0005 § D7, G-9 · Rev
- **P-R04** Las vistas de puzle convierten px ↔ m solo con `ViewMetrics` y leen el
  tamaño lógico de `ViewportMapper`, no de 1920×1080 fijo (FE-R08, FE-X03). —
  source: ADR-0011 § D7, G-7 · Test
- **P-R05** Objetos movidos por código (puertas 8, caja 10, objetivos de 29) se
  animan por fotograma con tiempo de juego, no por tick de física. — source:
  ADR-0012 OI-7 (consecuencia de § D2) · Rev
- Reglas Foundation que obligan aquí: F-R18 (25, 26 `ALWAYS`; HUD `PAUSABLE`),
  F-R20 (28, 29), F-R21 (29: `TIME` de shader no se congela en pausa), F-R22 (25),
  F-R38 (28).

### Forbidden Approaches
- **P-X01 Nunca colocar una capa por encima del telón** (C-X08). — source: ADR-0003
  § Implementation Guidelines · Rev
- Aplican además: F-X10 (`create_timer`), F-X11 (solo 25 pausa), F-X12, F-X13,
  F-X17, F-X28, F-X37.

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example | Source |
|---------|-----------|---------|--------|
| Classes | PascalCase | `NoticeChannel` | `naming.classes` in project.yaml |
| Variables | snake_case | `max_chained_notices` | `naming.variables` in project.yaml |
| Signals/Events | past_tense | `paused_changed`, `pause_opened` | `naming.signals` in project.yaml |
| Files | snake_case | `notice_ids.gd` | `naming.files` in project.yaml |
| Scenes | snake_case | `planta.tscn` | `naming.scenes` in project.yaml |
| Constants | SCREAMING_SNAKE | `PROCESS_PRIORITY` | `naming.constants` in project.yaml |
| Autoloads | `<ClassName>Autoload`, ≠ `class_name` | `GameStateAutoload` | ADR-0009 § D1 (F-R24) |
| Code identifiers | Inglés ASCII | `is_queue_empty()` | ADR-0001 G-13 (F-R12) |

### Performance Budgets

| Target | Value | Source |
|--------|-------|--------|
| Framerate | 60 fps | `performance.target_framerate` in project.yaml |
| Frame budget | 16,67 ms | `performance.frame_budget_ms` in project.yaml |
| Draw calls | 1500 | `performance.draw_call_limit` in project.yaml |
| Memory ceiling | 3072 MB | `performance.memory_ceiling_mb` in project.yaml |

`performance.enforce: warn` (project.yaml): los presupuestos avisan, no bloquean.
Hardware de referencia y reparto por sistema: ADR-0019 (`Proposed`) — **no hay
reglas de presupuesto por sistema fuera de Foundation**.

### Approved Libraries / Addons
- **Ninguna aprobada formalmente**: `technical-preferences.md` § Allowed Libraries
  dice «None configured yet».
- gdUnit4 es el framework de tests declarado (`technical-preferences.md` § Testing;
  comando CI en `coding-standards.md`); 6.2.2 corre sobre 4.7.2
  (`current-best-practices.md` § Command Line).

### Forbidden Patterns (technical-preferences.md)
- `technical-preferences.md` § Forbidden Patterns: «None configured yet». Nada que copiar.

### Forbidden APIs (Godot 4.7.2)

Source: `docs/engine-reference/godot/deprecated-apis.md`. Solo las filas que aplican a
un proyecto 3D GDScript con Jolt:

- `yield()` → `await signal` (4.0) · Rev
- `connect("signal", obj, "method")` / `connect()` por cadena → `signal.connect(callable)` (4.0) · Rev
- `instance()` / `PackedScene.instance()` → `instantiate()` (4.0) · Rev
- `get_world()` → `get_world_3d()` (4.0) · Rev
- `OS.get_ticks_msec()` → `Time.get_ticks_msec()` (4.0; es la fuente de `RealClock`) · Rev
- `VisibilityNotifier3D` → `VisibleOnScreenNotifier3D` (4.0) · Rev
- `duplicate()` para recursos anidados → `duplicate_deep()` (4.5) · Rev
- `Skeleton3D.bone_pose_updated` → `skeleton_updated` (4.3) · Rev
- `AnimationPlayer.method_call_mode` → `AnimationMixer.callback_mode_method`;
  `AnimationPlayer.playback_active` → `AnimationMixer.active` (4.3) · Rev
- GodotPhysics3D → Jolt Physics 3D (`engine.physics: Jolt` en project.yaml) · Rev
- `event.device == 0` para detectar ratón/teclado → `event is InputEventMouse` /
  `InputEventKey` o `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` (4.7) · Rev
- `$NodePath` en `_process()` → `@onready var` cacheado · Rev
- `Array` / `Dictionary` sin tipo → `Array[Type]`, variables tipadas · Rev
- `Texture2D` en `Shader.set_default_texture_parameter()` / `get_…()` → `Texture` (4.4) · Rev
- Cadenas manuales de viewports de postproceso → `Compositor` + `CompositorEffect` · Rev
- Al usar `RichTextLabel` con imágenes: `UPDATE_WIDTH_IN_PERCENT` →
  `ImageUpdateMask.UPDATE_WIDTH_UNIT`; `width_in_percent`/`height_in_percent` →
  `width_unit`/`height_unit` (4.7) · Rev
- Al usar `Control.accessibility_live`: `DisplayServer.AccessibilityLiveMode` →
  `AccessibilityServer.AccessibilityLiveMode` (4.7) · Rev
- `AudioEffectSpectrumAnalyzer.tap_back_pos` — eliminado en 4.7 · Rev
- Si se usa navegación: `Navigation3D` → `NavigationServer3D` · Rev
- Addons: pestaña AssetLib → espacio Asset Store del editor (4.7) · Rev

**Omitidas a propósito** (no aplican): `TileMap`, `VisibilityNotifier2D`, `YSort`,
`Navigation2D` (solo 2D). **Sin resolver**: `EditorSceneFormatImporterFBX` →
`…FBX2GLTF` y `EditorSceneFormatImporter.IMPORT_*` → `ImportFlags` — solo aplican
si el proyecto escribe plugins de importación del editor; no consta que lo haga.

### Required Engine Patterns (current-best-practices.md)

- **Un override de un método tipado hereda su tipo de retorno y necesita un `return`
  explícito** (4.7) — afecta a todo adaptador de puerto y a subclases de
  `LogSink`/`ErrorPolicy`. — source: `current-best-practices.md` § GDScript (4.7);
  ADR-0001 y ADR-0009 § Engine Compatibility · Test (T-U3) + parse check
- Escribir un elemento de un array empaquetado ya no llama al setter de la
  propiedad: asignar el array entero cuando el setter debe correr (4.7). — source:
  `current-best-practices.md` § GDScript (4.7) · Rev
- `@abstract func` sin cuerpo; las subclases deben sobrescribirla (4.5). — source:
  `current-best-practices.md` § GDScript (4.5+) · parse check
- Parámetro variádico `...name` al final, tipado `Array` o sin tipo
  (`values: Variant...` no parsea). — source: `current-best-practices.md` § GDScript (4.5+)
- Las lambdas capturan locales **por valor**: compartir estado mediante un tipo
  referencia (Dictionary/Array/objeto). — source: `current-best-practices.md`
  § GDScript (4.5+); ADR-0001 V-ENG-6 · Rev
- Comprobación de parseo: `godot --headless --path . -s
  res://.claude/scripts/godot-parse-check.gd -- res://<file>.gd` (`--check-only` y
  `--import` no son parse check). — source: `current-best-practices.md` § Command Line

### Cross-Cutting Constraints

- **Tipado estático**: miembros, parámetros, retornos y colecciones tipados
  (`Array[Type]`, `-> void`). — source: `deprecated-apis.md` § Patterns (untyped
  collections); ADR-0009 § D3 regla 4 (miembros tipados) · Rev (`project.godot` no
  activa avisos de declaración sin tipo; no hay chequeo mecánico)
- **Inyección de dependencias sobre singletons**; todo método público testeable. —
  source: `coding-standards.md`; implementado por ADR-0009 § D3
- **Comentarios de documentación `##`** en toda API pública. — source:
  `coding-standards.md`; ADR-0002 § Key Interfaces
- **Valores de juego en datos externos**, nunca en código. — source:
  `coding-standards.md`; ADR-0001 G-9, ADR-0002 § Tuning
- **Tests**: deterministas, aislados, sin E/S real (dobles: `MemoryFileStore`,
  `FakeClock`, `FakeRealClock`); en `tests/unit/[system]/` y
  `tests/integration/[system]/`. — source: `coding-standards.md` § Testing
  Standards; ADR-0009 § D9
- **Un parse check no es una ejecución**: todo cambio observable se lanza y se
  observa, con captura retenida en `production/qa/evidence/`. — source:
  `coding-standards.md`
- **Commits**: Conventional Commits con ID de historia/tarea en el cuerpo. — source:
  `coding-standards.md`
- **CI**: la suite gdUnit4 corre en cada push a `main`; no se desactivan tests que
  fallan. — source: `coding-standards.md` § CI/CD Rules

---

## Pendiente de spike / sin regla todavía

Lo que un ADR `Accepted` deja NOT SOURCEABLE, sin decidir o marcado ‡ **no es una
regla**. Ninguna historia puede apoyarse en estos puntos hasta que se cierren.

| # | Punto | Origen | Estado / cuándo se cierra |
|---|---|---|---|
| P-02 | Asignaciones de memoria en la lectura de hechos (V-ENG-2); tiempo medido solo en headless | ADR-0001 § Spike Results V-ENG-2 | Sin medir; medir con el juego en marcha |
| P-03 | Pausa del editor en `assert` (V-ENG-4) | ADR-0001 § Spike Results V-ENG-4 | Sin probar (sin sesión de editor) |
| P-04 | Foco con mando y conexión/desconexión del mando en pausa (S4 puntos 4 y 5) | ADR-0002 § Spike Results S4 | «No confirmado por separado»; reabrir si aparece un defecto de mando |
| P-05 | Comprobación audible de `stream_paused` (S8) y «pop» visual de la interpolación de cámara (S11) | ADR-0002 § Spike Results S8, S11 | Parte numérica PASS; parte manual pendiente |
| P-06 | Valor `TWEEN_PAUSE_*` que usa `FxTween.make()` | ADR-0002 G-9, § D3 fila 29 | S5 pasó con `BOUND` y con `STOP`; el ADR no registra cuál se elige. Decisión pendiente |
| P-07 | Mecanismo para diferimientos de un frame sin duración | ADR-0002 § D6 | «Not fixed here»; sin regla |
| P-08 | V1: ¿rechaza el parser de 4.7.2 un `class_name` igual a un nombre de autoload? | ADR-0009 § Engine Compatibility | NOT SOURCEABLE, asumido; evitado por F-R24. Registrar observación (O4) |
| P-09 | V2: orden de autoloads como hijos de `root` y orden `_ready()`/`_process()` | ADR-0009 § Engine Compatibility | NOT SOURCEABLE; mitigado por F-R23 (S15 confirma solo `process_priority`) |
| P-10 | V3: `@abstract` en `RefCounted` + subclase interna concreta | ADR-0009 § Engine Compatibility | Sintaxis documentada, combinación sin registro de observación; T-U3 |
| P-11 | V4: `print_orphan_nodes()` / `OBJECT_NODE_COUNT` desde gdUnit4 | ADR-0009 § Engine Compatibility | NOT SOURCEABLE; necesario para T-I2 |
| P-12 | V5: `mock()`/`spy()` de gdUnit4 sobre clases con miembros `@abstract` | ADR-0009 § Engine Compatibility, § D9 | NOT SOURCEABLE; no se depende de ello (F-X27) |
| P-13 | Mecanismo de T-U8 (introspección de propiedades de script) | ADR-0009 Open Items O3 | Confirmar en implementación o sustituir por escaneo de texto en CI |
| P-14 | Scripts de CI `list_autoload_refs.sh` y `list_puzzle_cross_refs.sh` | ADR-0009 § D10 ‡ | **No existen**; F-R25, F-X19 y F-X23 quedan solo en revisión hasta que existan |
| P-15 | Valores ‡ propuestos: `GameClock.PROCESS_PRIORITY := -1000`, ruta `assets/data/core/clock.json`, `FxTween`, `SubscriptionBag`, `ServiceContext`, firmas de puertos (O2) | ADR-0002 § Tuning; ADR-0009 § D2, § D3, Open Items O2 | La regla vale; el nombre/valor concreto puede cambiar (los nombres de autoload ya están en `project.godot`) |
| P-17 | ¿`JsonText` pre-chequea el texto para convertir coma final / cero a la izquierda / clave duplicada en error, o se toleran? | ADR-0005 § Spike Results A3, A4 (R2/G-16) | El ADR deja las dos salidas abiertas; F-R56 rige la autoría, la detección no es regla todavía |
| P-18 | **Mando físico** (NEEDS_MANUAL): valor en reposo y zona muerta real (S-0006-A), cadenas de familia DualSense/DS4/Xbox (S-0006-B, fallback `GENERIC`), conexión/desconexión y latencia en pausa (S-0006-C), `relative` a 1080p/1440p y captura tras perder foco (S-0006-D), foco de ventana a un autoload `ALWAYS` (S-0006-E), clic en `LineEdit` y navegación con stick/cruceta (S-0006-F), repetición de tecla del SO | ADR-0006 § Status, § Spike Results | Prototipo jugable (`prototypes/input-spike/` README) |
| P-19 | **Alto lógico bajo `canvas_items`/`expand`** a 1920×1080, 1920×1200, 2560×1600 (NEEDS_WINDOWED); de él dependen los números de AC-32 y la figura de cursor de ADR-0006 | ADR-0011 § Spike Results S-0011-C; contradicción X-03 | Prototipo jugable (`prototypes/physics-spike/`); dueño final ADR-0016 |
| P-20 | **Pasillo de 15,1 ± 0,3 s a cada tope de fps** (AC-06, NEEDS_WINDOWED) y píxeles renderizados tras cambio de FOV en ventana redimensionada | ADR-0012 § Spike Results S-0012-A «corridor», S-0012-B «same frame» | Prototipo jugable |
| P-21 | **Tirón de carga síncrona de `planta` gris** (S-0003-C, solo registro); si supera ~1 s en hardware de referencia, ADR nuevo revisa D4 | ADR-0003 § D4, § Spike Results S-0003-C | Cuando exista `planta` gris y `SceneSource` real |
| P-22 | A7 (export mantiene `assets/data/*.json` legible), A9 (`is_debug_build` en exports), A10 (args y código de salida): la cabecera de § Spike Results dice que se ejecutaron en un export release el 2026-11-11, pero la tabla sigue marcando NEEDS_MANUAL sin cifras | ADR-0005 § Spike Results | Registrar las cifras en el ADR; hasta entonces G-14 (F-R67) se aplica sin saber si hace falta filtro explícito |
| P-23 | Nombres de capas de colisión (`zone_sensor`, `player_body`, bit 3 de pick) no definidos en `project.godot` (`layer_names/3d_physics/layer_3` ausente) | ADR-0011 § Spike Results S-0011-A (c); ADR-0003 O7; ADR-0012 OI-9 | Historia de capas de ADR-0011 |
| P-24 | Fallback B de ADR-0002 con la fracción del motor: C-R15 no usa `GameClock.delta()` para α; en variante A el rig se congela porque el árbol se pausa (S-0012-F PASS). En variante B no está medido | ADR-0012 § D2 vs § Spike Results R1 | Solo si se activa el fallback B de ADR-0002 |

**Resuelto desde la versión 2026-11-11:** P-01 (C1/NS-7, medida en ADR-0006 S-0006
→ F-R48) y P-16 (`DebugFatalHandler` con `assert(false)`: ADR-0009 § D8 enmendado el
2026-11-11 a `push_error` + `quit(1)` → F-X09).

### Contradicciones entre ADR aceptados (para `/architecture-review`)

| # | Entre | Lectura que aplica este manifiesto |
|---|---|---|
| X-01 | ADR-0012 P-3 / tabla NP-3 («ninguna API de NP-3 se usa», y NP-3 lista `Engine.get_physics_interpolation_fraction()`) y § D2 (acumulador espejo propio) **vs** ADR-0012 § Status + § Spike Results R1 (usar esa función; sin acumulador propio) | Prevalece R1, que es la base de la aceptación: C-R15 / C-X09; C-X11 exceptúa esa única función. El texto de D2 y P-3 debe enmendarse |
| X-02 | ADR-0017 G-1 prohíbe `GameClock.schedule()` **vs** ADR-0002 § D6 / F-R17 lo propone para esperas de juego, y ADR-0010 § D6 lo usa vía `PuzzleTimers` | No es conflicto de comportamiento: 0017 restringe localmente (FE-X08); fuera de 21/22 rige F-R17 |
| X-03 | ADR-0006 D9 (cursor en «píxeles lógicos 1920×1080») **vs** ADR-0011 C1 (lo que reporte `ViewportMapper`; 1200 en 16:10) | Prevalece ADR-0011 (P-R04); cifra final de ADR-0016 (`Proposed`), pendiente de P-19 |
| X-04 | ADR-0009 § D3 regla 6 / F-R31 (`SubscriptionBag` liberado en `_exit_tree`) **vs** ADR-0003 (desuscribirse en `_exit_tree` no es requisito de corrección) | Compatibles: F-R31 es obligatorio como higiene; C-X07 solo prohíbe que la corrección dependa de ello |
| X-05 | ADR-0003 O8 y ADR-0006 § Spike Results dicen «Status stays `Proposed`», ADR-0006 § Related dice que sus dependencias están todas `Proposed` | Texto desfasado: `## Status` dice `Accepted`; manda `## Status` |

---

## Verification Status

- **TD-MANIFEST: NOT ASSESSED** — este manifiesto lo ha redactado el propio
  `technical-director`; una revisión del mismo agente no es independiente. Ejecutar
  la revisión con otra sesión o en `/architecture-review`.
- Regla con chequeo mecánico existente hoy: solo F-X10 (`tools/ci/forbid_timers.sh`,
  parcial; cubre también FE-X06 en `src/puzzles/`). Los grep de CI de C-X01, F-R40,
  F-X30 y F-R64 están decididos en sus ADR pero **no se ha comprobado que existan**
  (CI‡). El resto es Test (suites nombradas en los ADR, varias aún por escribir) o
  Rev. Las cifras «medido» proceden de `tests/unit/engine_facts/adr00*_test.gd`
  (headless, 4.7.2) según la § Spike Results de cada ADR.
- Secciones leídas por ADR nuevo: Decision (D1–D8 de 0003; D4–D5 de 0005; D2, D11
  de 0012; D10–D11 de 0011), Implementation Guidelines, Alternatives Considered,
  Consequences (0003), Performance Implications, Spike Results y Open
  Items/Contradictions. **No** se leyeron enteras las secciones Decision de 0006,
  0010, 0011 y 0017 (600+ líneas cada una): sus mandatos están tomados de
  Implementation Guidelines, que en esos ADR resume D1–Dn. Un mandato que solo esté
  en el cuerpo de Decision y no en las guías puede faltar.

## Recuento de reglas por capa

| Capa | Required | Forbidden | Guardrails | Total | ADR de origen |
|---|---|---|---|---|---|
| Foundation | 67 (F-R01–F-R67) | 40 (F-X01–F-X40) | 10 (F-G01–F-G10) | 117 | 0001, 0002, 0005, 0006, 0009 |
| Core | 27 (C-R01–C-R27) | 16 (C-X01–C-X16) | 2 (C-G01–C-G02) | 45 | 0003, 0012 |
| Feature | 28 (FE-R01–FE-R28) | 11 (FE-X01–FE-X11) | 3 (FE-G01–FE-G03) | 42 | 0010, 0011, 0017 |
| Presentation | 5 (P-R01–P-R05) | 1 (P-X01) | 0 | 6 | 0003, 0005, 0006, 0011, 0012 (ninguno propio) |
| **Total por capa** | **127** | **68** | **15** | **210** | 10 ADR |

Global (sin cambios respecto a 2026-11-11): 8 convenciones de nombre, 4
presupuestos, 0 librerías aprobadas, 21 APIs prohibidas, 6 patrones de motor, 8
restricciones transversales. Pendientes (no son reglas): 22 filas (P-02…P-15,
P-17…P-24) y 5 contradicciones (X-01…X-05).
