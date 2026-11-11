# Control Manifest

> **Engine**: Godot 4.7 (pin 4.7.2.stable.official.ed1daf0bf), GDScript, 3D, Forward+, Jolt
> **Last Updated**: 2026-11-11
> **Manifest Version**: 2026-11-11
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0009 (los tres `Accepted` de 19)
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

`Manifest Version` es la fecha en que se generó este manifiesto. Las historias la
incrustan al escribirse y `/story-readiness` la compara con esta para encontrar
historias escritas contra reglas viejas. Siempre igual a `Last Updated`.

Hoja de referencia rápida para programación, extraída **solo** de los ADR
`Accepted`, de `project.yaml`, de `.claude/docs/technical-preferences.md`, de
`.claude/docs/coding-standards.md` y de `docs/engine-reference/godot/`. El *porqué*
de cada regla está en su ADR y sección. Ninguna regla procede de un ADR `Proposed`
ni de memoria del modelo.

---

## Cobertura

**Este manifiesto cubre SOLO la capa Foundation, y solo parcialmente: 3 de 19 ADR.**

| ADR | Título | Estado | Capa (Engine Compatibility) |
|---|---|---|---|
| ADR-0001 | Event bus and fact contract | Accepted (2026-11-11; C1 diferida a S-0006) | Foundation |
| ADR-0002 | Pause and game time | Accepted (2026-11-11; variante **A** — árbol pausado + `process_mode` explícito) | Foundation |
| ADR-0009 | Service composition | Accepted (2026-11-11) | Foundation |

**Capas Core, Feature y Presentation: SIN REGLAS PROPIAS por falta de ADR
`Accepted`.** Las secciones de esas capas más abajo están vacías a propósito; solo
enumeran qué reglas de Foundation obligan también a sus sistemas (las decisiones
transversales de ADR-0001/0002/0009 sí son vinculantes para ellos). Que una capa no
tenga reglas aquí **no** significa que no tenga restricciones: significa que sus
decisiones aún pueden cambiar.

Foundation tampoco está completa: de sus sistemas (capa 1 de `architecture.md`
§ System Layer Map: 3 Estado, `GameClock`, 1 Entrada, 18 Contenido) quedan sin
reglas propias **1 Entrada** (ADR-0006) y **18 Contenido / validación de datos**
(ADR-0005), ambos `Proposed`.

**ADR excluidos (16, todos `Proposed`; ninguna regla extraída de ellos):**

| ADR | Título | Estado |
|---|---|---|
| ADR-0003 | Scene loading and sin-control handoff | Proposed |
| ADR-0004 | Save format and lifecycle | Proposed |
| ADR-0005 | Data schema validation and content catalog | Proposed |
| ADR-0006 | Input abstraction, contexts and binding labels | Proposed |
| ADR-0007 | Settings persistence, accessibility and UI scaling | Proposed |
| ADR-0008 | Audio buses, voice queue and process mode | Proposed |
| ADR-0010 | Puzzle framework and controller contract | Proposed |
| ADR-0011 | Interaction focus query and view picking | Proposed |
| ADR-0012 | Player controller, physics interpolation and camera | Proposed |
| ADR-0013 | First-person hands rendering and blackout lighting | Proposed |
| ADR-0014 | Atmosphere lighting budget and rain | Proposed |
| ADR-0015 | Glass and mirror shaders and draw order | Proposed |
| ADR-0016 | Subtitles and UI text rendering | Proposed |
| ADR-0017 | Scene director timeline and call data | Proposed |
| ADR-0018 | Build, export, CI and dev tooling | Proposed |
| ADR-0019 | Performance budgets and reference hardware | Proposed |

Consecuencias concretas de la exclusión: los presupuestos de rendimiento globales
vienen de `project.yaml`, no de ADR-0019; el CI `tools/ci/forbid_timers.sh` cita
también ADR-0018 D6, pero aquí se traza solo a ADR-0002 D6.

**Leyenda de verificación** (columna «Verif.»): **CI** = script existente que falla
el build · **CI‡** = chequeo decidido en el ADR pero el script **aún no existe** ·
**Test** = suite gdUnit4 nombrada en el ADR · **Rev** = solo revisión de código.

---

## Foundation Layer Rules

*Aplica a: bus de avisos y hechos (3 `GameState`, `NoticeChannel`), tiempo de juego
y pausa (`GameClock`, `RealClock`, `PauseBackend`), composición de servicios
(`Boot`, `ServiceContext`, autoloads). Por su naturaleza transversal, estas reglas
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
  `_physics_process` y `_process` de nodos distintos** — C1/NS-7 diferida al spike
  S-0006; las garantías de mismo frame vienen solo del drenaje síncrono. — source:
  ADR-0001 § Spike Results «Acceptance», NS-7 · Rev
- **F-X09 Nunca `assert` como única forma de detener la ejecución** — en 4.7.2 se
  elimina en release y, sin depurador, solo aborta la función actual. — source:
  ADR-0001 § Spike Results V-ENG-4 · Rev
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
  muestra UI de error por su cuenta.** — source: ADR-0009 § D8 · Rev (excepción
  única: la implementación de `ErrorPolicy`, F-R09; ver contradicción en «Pendiente»)
- **F-X25 Un servicio persistente nunca cachea un servicio de escena fuera de la
  ventana bind/unbind.** — source: ADR-0009 § D6 · Test (T-I2)
- **F-X26 17 (Pistas) nunca llama a 25**: publica `HintPanelProvider` en
  `SceneServices.hint_panel` y 25 lo consulta. — source: ADR-0009 § D6 · Rev
- **F-X27 Una suite unitaria nunca toca un autoload registrado ni depende de
  `mock()`/`spy()` de gdUnit4 para construir un sistema.** — source: ADR-0009 § D9 · Rev
- **F-X28 Nunca `Atmosphere` como autoload.** — source: ADR-0009 Alternative 4, § D11 · Rev

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

---

## Core Layer Rules

*Aplica a: 6 Ajustes (C1), 2 Jugador y 4 Escena (C2), 5 Guardado y 23 Audio (C3)
(`architecture.md` § System Layer Map; ADR-0009 § D4).*

**SIN REGLAS PROPIAS — ningún ADR de esta capa está `Accepted`** (ADR-0003, -0004,
-0007, -0008, -0012 son `Proposed`).

### Required Patterns
- *(ninguna propia)*. Reglas Foundation que obligan a sistemas de esta capa:
  F-R16 y F-R17 (6, 5, 4 usan `RealClock`), F-R18 (todos `ALWAYS` salvo 2 bajo
  `WorldSlot`), F-R19 (2), F-R26 (autoloads 4, 5, 6, 23), F-R32 (tabla de llamadas
  directas de 4, 5, 23), F-R34 (23 y `SceneLoader`), F-R39 (23).

### Forbidden Approaches
- *(ninguna propia)*. Aplican: F-X10, F-X14, F-X15 (4), F-X25.

### Performance Guardrails
- *(ninguno)*. Los presupuestos por sistema pertenecen a ADR-0019 (`Proposed`).

---

## Feature Layer Rules

*Aplica a: 7 Interacción (F1), 20 Bolsillo (F2), 19 Ordenador (F3), 9 Marco y 10
Caja (F4), 8 Acceso, 11–16 controladores, 17 Pistas, 21 Director, 22 Llamada (F5).*

**SIN REGLAS PROPIAS — ningún ADR de esta capa está `Accepted`** (ADR-0010, -0011,
-0017 son `Proposed`).

### Required Patterns
- *(ninguna propia)*. Reglas Foundation que obligan a sistemas de esta capa:
  F-R05 (escritores 9, 19, 20, 22), F-R08 (consumidores de `interaction_executed`),
  F-R28–F-R33, F-R35 (11–16).

### Forbidden Approaches
- *(ninguna propia)*. Aplican: F-X03, F-X12 (21, 22), F-X23 (11–16), F-X26 (17).

---

## Presentation Layer Rules

*Aplica a: 24 Prompt, 25 Pausa, 26 Subtítulos, 27 Título, 28 Atmósfera, 29 Shaders;
render, audio de presentación, UI, VFX.*

**SIN REGLAS PROPIAS — ningún ADR de esta capa está `Accepted`** (ADR-0013, -0014,
-0015, -0016 son `Proposed`).

### Required Patterns
- *(ninguna propia)*. Reglas Foundation que obligan a sistemas de esta capa:
  F-R18 (25, 26 `ALWAYS`; HUD `PAUSABLE`), F-R20 (28, 29), F-R21 (29), F-R22 (25),
  F-R38 (28).

### Forbidden Approaches
- *(ninguna propia)*. Aplican: F-X11 (solo 25 pausa), F-X12, F-X13, F-X17, F-X28.

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
| P-01 | Entrega del bus en el mismo frame respecto a los callbacks de entrada (C1, NS-7) | ADR-0001 § Spike Results «Acceptance» | Diferido al spike S-0006 (ADR-0006) en M1. Mientras tanto rige F-X08 |
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
| P-16 | **Contradicción**: `DebugFatalHandler` usa `assert(false, …)` «para que el editor se detenga», pero V-ENG-4 muestra que `assert` no es una parada fiable (F-X09) y la pausa del editor en `assert` está sin probar | ADR-0009 § D8 vs ADR-0001 § Spike Results V-ENG-4 | Para `/architecture-review`. Hasta entonces, la parada dev fiable es la de F-R09 |

---

## Verification Status

- **TD-MANIFEST: NOT ASSESSED** — este manifiesto lo ha redactado el propio
  `technical-director`; una revisión del mismo agente no es independiente. Ejecutar
  la revisión con otra sesión o en `/architecture-review`.
- Regla con chequeo mecánico existente hoy: solo F-X10 (`tools/ci/forbid_timers.sh`,
  parcial). El resto es Test (suites nombradas en los ADR, varias aún por escribir) o Rev.
