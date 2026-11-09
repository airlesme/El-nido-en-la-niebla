# Marco de puzles

> **Status**: Revisado (ronda 4) — pendiente de re-review (ronda 4 aplica B-1, AC-35, AC-47 y B-3 de `gdd-cross-review-2026-11-09-r2.md`; ronda 2: `design/gdd/reviews/marco-de-puzles-re-review.md`)
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Tensión sin castigo (sin fallos terminales, reinicio sin coste, nada bloquea la historia) · Autonomía como progresión (el jugador deduce la solución del contenido) · Información incompleta (los puzles entregan hechos, nunca intenciones)

## Summary

Es el esqueleto común de los seis puzles del slice: les da un mismo ciclo de vida (bloqueado, activo, resuelto), una misma manera de comprobar la solución, de reaccionar cuando el jugador se equivoca (sin castigo, sin contador, sin espera larga), de anunciar que se han resuelto y de dejar constancia en el estado del juego. Cada puzle aporta solo lo que es suyo (sus piezas y su regla); el marco aporta todo lo demás y garantiza que **ningún puzle puede dejar al jugador atascado**. Existe porque seis puzles distintos, escritos por separado, acabarían con seis formas de fallar, de guardarse y de pedir ayuda; y porque el pilar *Tensión sin castigo* se cumple o no en ese denominador común.

> **Quick reference** — Layer: `Feature` (categoría `Gameplay`) · Priority: `MVP` · Key deps: `3 Estado y bus de eventos`, `4 Escena de planta`, `7 Interacción e inspección`, `18 Base de contenido` (dura en validación) · blandas: `2 Jugador` (vía 7), `6 Ajustes`, `20 Documentos`, `23 Audio`, `25 Pausa`, `26 Subtítulos`


## Overview

El marco de puzles gestiona, para cada uno de los seis puzles del Anexo B del slice (`P1` Cronología, `P2` Memorando en el cristal, `P3` Encaje de la foto, `P4` Tablero de tareas, `P5` Espejo de la diferencia, `P6` Decisión), tres cosas: **qué es** (una definición en datos: dónde está, qué necesita, cómo se comprueba, qué ocurre al acertar, al equivocarse y al pedir ayuda), **en qué estado está** (`BLOQUEADO`, `ACTIVO` o `RESUELTO`, con el criterio de paso entre ellos) y **qué consecuencias deja** (hechos escritos en el estado del juego y el aviso `EV_PUZZLE_SOLVED_<ID>`).

Cada puzle se implementa como un *controlador* que cumple una interfaz común: recibe gestos de puntero (en las vistas cercanas) o activaciones de objeto (en el mundo), mantiene el estado de sus piezas, y responde a una única pregunta cuando el marco se la hace —«¿cómo está esto?»— con uno de cinco veredictos: nada, condición mantenida, progreso parcial, rechazo o resuelto. Lo que sigue (temporizar la comprobación, reproducir el rechazo, bloquear la entrada el tiempo justo, escribir hechos, avisar, restaurar tras cargar, enganchar pistas) lo hace el marco igual para todos.

Es un sistema invisible para el jugador, que solo percibe sus resultados: un panel que vibra y devuelve las referencias, una pieza que encaja con un chasquido, un compartimento que se abre. Existe por tres razones. (1) *Una sola política de fallo*: el slice declara que «ningún fallo en un puzle bloquea el avance» (§19.3) y esa garantía sólo se puede comprobar si hay un único lugar donde se aplica. (2) *Datos fuera del código*: soluciones, tolerancias, tiempos y pistas viven en un fichero editable por diseño y QA. (3) *Pistas*: el sistema 17 entrará después sin tocar los puzles, porque el marco ya expone qué pistas tiene cada uno y cómo aplicarlas.

## Player Fantasy

Vera no «resuelve acertijos»: **entiende lo que tiene delante**. El jugador debe sentir que cada puzle es una conversación con el mundo —ordenar los correos, mirar el memorando en el cristal, ver la foto a la que le falta alguien— y que equivocarse no es una derrota, sino una forma de probar. Estética principal (MDA): **Challenge** suave y **Discovery**; secundaria: **Narrative** (cada solución entrega un hecho). Necesidades SDT: **Competencia** (feedback legible en cada acción, correcta o no, y la solución se deduce del contenido), **Autonomía** (varios caminos de pensamiento y el orden libre de la caja). La tensión viene del ambiente y del tema, **nunca** de reloj, contador ni consecuencia.

*Curva de dificultad (sierra, flow):* P1 (recoger información y ordenarla) → P2 (deducción espacial en el mundo) → P3 (manipulación sencilla) → P4 (razonar sobre un texto) → P5 (observar y comparar) → P6 (sin dificultad, solo peso emocional). Cada tramo sube la exigencia mental un poco y la baja con un puzle más físico o contemplativo; el último puzle no tiene respuesta incorrecta por diseño.

## Detailed Design

### Core Rules

‡ = propuesta que debe confirmar el GDD del sistema afectado (aún sin redactar o en revisión). † = valor propuesto, a validar en playtest. Las **claves de datos y los nombres de la interfaz van en inglés** (identificadores de código); los IDs del slice (`P1`, `B01`, `I-01`, `caja_c1`, `SFX_REJECT`, `EV_PUZZLE_SOLVED_P1`…) se conservan tal cual. Los **nombres de gesto, fase y verbo son los de 7 y Entrada** (`seleccionar`, `mantener`, `agarrar`, `rotar`; fases `inicio`, `fin`, `cancelación`; verbo `Girar`); el vocabulario de gestos de manos (`HAND_*`) y sus duraciones los fija el Jugador (2), no este GDD. Identificadores de puzle adoptados: **`P1` a `P6`** (confirma lo propuesto en la regla 10 del GDD del 3). Los IDs de **elemento** de un puzle llevan siempre el prefijo de su vista o puzle (`D01a/piece_1`, `D01c/frame`, `C05/slot_2`, `B02`) para no colisionar con `P1`–`P5` (piezas del encaje, slice B.3) ni con otros IDs.

**Reparto de responsabilidades**

1. **Qué posee el marco.** El ciclo de vida de cada puzle, la planificación de la comprobación, la política de fallo y de bloqueo de entrada, la escritura de los hechos de puzle en el estado (3), el aviso `EV_PUZZLE_SOLVED_<ID>`, el aviso «compartimento completado» (n) (regla 16), la restauración tras cargar, las dependencias entre puzles y el enganche de pistas. Es el **único escritor** de los hechos `archivo_abierto`, `memo_leido`, `pos_L`, `pos_C`, `pos_R`, `caja_c1` a `caja_c4`, `pendiente_revelacion`, `carta_variante` y `t4_decision`. El GDD del 3 ya fija `owner = 9` para estos hechos (aplicado en la ronda 2; C-W9), así que las escrituras del marco son válidas. 11–16 actúan a través del marco.
2. **Qué no posee.** Las piezas y reglas de cada puzle (sistemas 11 a 16), las puertas y lectores (8), la animación y el hardware de la caja (10), el ordenador y la impresora (19), los documentos y el bolsillo (20), el reparto de pistas (17) y los gestos (7 y 1). El marco **no** conoce la solución de ningún puzle: la lee de los datos y se la pasa al controlador.
3. **Un puzle = datos + controlador.** Cada puzle tiene una entrada en `assets/data/puzzles/puzzles.json` (reglas 4 y 5) y una clase que hereda de la clase base abstracta `PuzzleController` (regla 9). Añadir un séptimo puzle de un tipo conocido es añadir datos; de un tipo nuevo, escribir un controlador.

**Datos**

4. **Esquema de una definición.** Cada puzle declara:
   - `id` (`P1`…`P6`) y `solved_flag` (el hecho que lo marca como resuelto: `archivo_abierto`, `memo_leido`, `caja_c1`…).
   - `mode`: `VIEW` (se resuelve en una vista cercana con cursor) o `WORLD` (se resuelve activando objetos desde la exploración; en 7 y en la prosa de este GDD, «modo `MUNDO`»: es el mismo modo; el identificador de código es `WORLD`, ver Cambios requeridos en 7).
   - `view` o `elements`: el ID de la vista (`C05`, `D01a`…) o los IDs de los objetos (`B01`, `B02`, `B03`).
   - `requires`: **solo** `all`, la lista de hechos que deben ser verdaderos para pasar de `BLOQUEADO` a `ACTIVO` (vacía = activo desde el inicio). Es la única condición de transición de estado.
   - `needs_items`: ítems (`I-01`) que el jugador necesita para *poder actuar* en un puzle ya `ACTIVO`. **No** cambia el estado: solo hace que la vista se abra con los elementos sin material y el texto de `locked_feedback` (S6). Es la **fuente única** del requisito, con **este nombre** (`needs_items`; `requires.all` queda reservado al estado): `interactables.json` (7) no debe duplicarlo (`requiere_ítem`) y 7 debe renombrar su `requires.items` a `needs_items` (Cambios requeridos); quien lo evalúa es el marco (regla 7).
   - `validation`: política de comprobación (regla 12) y sus tiempos.
   - `solution`: datos de la solución (permutación, ángulo y tolerancia, mapa pieza-hueco…); solo el controlador los interpreta.
   - `on_reject`: sonido, animación, duración y alcance del bloqueo (regla 14).
   - `on_unlock`: feedback al pasar a `ACTIVO` (`sfx`, y `ajar_cm` solo si el slice lo pide: P5).
   - `on_solved`: hechos a escribir en orden, `compartment` (1–4 si el puzle completa un compartimento), sonido, duración, recompensas (ítems), `close_view_after_s` (el nombre del marco; sustituye al `t_auto_salida_s` de 7).
   - `on_reopen`: qué ocurre si el jugador intenta abrir la vista de un puzle `RESUELTO` (regla 35); defecto `NO_VIEW`.
   - `resolution`: `IMMEDIATE` o `DEFERRED` con sus pasos y su hecho de reanudación (regla 17).
   - `persist`: hechos que reflejan estado intermedio (`pos_L/C/R`).
   - `hints`: lista de pistas (regla 25) con sus umbrales de inactividad (F3).
   - `assist`: ajuste de accesibilidad que cambia un parámetro (`asistencia_encaje`, `asistencia_rotacion`) y su valor asistido.
5. **Ejemplos (ilustrativos).**
   P1, resolución inmediata:
```json
{
  "id": "P1", "mode": "VIEW", "view": "C05",
  "solved_flag": "archivo_abierto",
  "requires": { "all": [] }, "needs_items": ["I-01"],
  "validation": { "policy": "DELAYED_AFTER_CHANGE", "delay_s": 0.6 },
  "solution": { "sequence": [2, 1, 3, 4] },
  "on_reject": { "sfx": "SFX_REJECT", "shake_s": 1.2, "reset_after_s": 1.5, "lock": "PUZZLE" },
  "on_solved": { "write": [{ "flag": "archivo_abierto", "value": true }],
                 "sfx": "SFX_UNLOCK", "sfx_s": 1.4, "close_view_after_s": 1.5 },
  "on_reopen": "NO_VIEW",
  "resolution": { "kind": "IMMEDIATE" },
  "hints": [ { "level": 1, "trigger": "REQUEST", "effects": [ { "type": "HIGHLIGHT", "targets": ["C05/paper"], "targets_if_missing_items": ["V08"], "duration_s": 3.0 } ] } ]
}
```
   P5, resolución diferida (los pasos suman 16,0 s con o sin audio; F8):
```json
{
  "id": "P5", "mode": "VIEW", "view": "D01c",
  "solved_flag": "caja_c3",
  "requires": { "all": ["caja_c1"] },
  "validation": { "policy": "SUSTAINED", "hold_s": 0.8, "dt_max": 0.1 },
  "solution": { "theta_deg": 40, "tol_deg": 3, "theta_initial_deg": 0 },
  "assist": { "setting": "asistencia_rotacion", "tol_deg": 6 },
  "on_unlock": { "sfx": "SFX_UNLOCK_SOFT", "ajar_cm": 2 },
  "on_solved": { "write": [{ "flag": "caja_c3", "value": true }], "compartment": 3, "close_view_after_s": 1.5 },
  "on_reopen": "NO_VIEW",
  "resolution": { "kind": "DEFERRED", "resume_flag": "pendiente_revelacion",
    "steps": [
      { "id": "FADE",    "kind": "OVERLAY_FADE", "duration_s": 1.2 },
      { "id": "OUTLINE", "kind": "OUTLINE",      "duration_s": 0.8 },
      { "id": "LINE",    "kind": "LINE", "line": "VO_G_07", "fallback_s": 14.0, "line_grace_s": 2.0 }
    ] }
}
```
   Todo valor numérico de los Anexos B vive aquí, nunca en el controlador. El marco valida el fichero al arrancar (regla 29). **Tipos:** el cargador convierte explícitamente los campos enteros (`sequence`, `pos_*`, `level`) a `int` y los comprueba (regla 29); ver Open Questions 4.

**Estados y modos**

6. **Tres estados públicos** (los del slice, Anexo B): `BLOQUEADO`, `ACTIVO`, `RESUELTO`. Pasos permitidos: `BLOQUEADO → ACTIVO` (cuando `requires.all` se cumple) y `ACTIVO → RESUELTO`. **Nunca hacia atrás** (regla 28): la API del marco no expone ningún método de retroceso. Dentro de `ACTIVO` hay cuatro fases internas (`IDLE`, `EVALUATING`, `FEEDBACK`, `RESOLVING`) que no se publican como estado (States and Transitions).
7. **Quién responde a un puzle no disponible: un único dueño por vista.** El marco **ofrece** `get_view_gate(view_id) -> { state: OPEN | BLOCKED | SOLVED, missing_items: bool, feedback_sfx, feedback_text_key }` y el **dueño del objeto** lo consulta **antes** de llamar a `abrir_vista`:
   - **`D01a`–`D01d`:** dueño Caja (10). Con `BLOCKED` (o `SOLVED`, regla 35) el compartimento sigue *habilitado* para 7 y el dueño contesta `SIN_EFECTO` con ese sonido y texto (por defecto `SFX_CLICK_SUBTLE`, sin texto): **la vista no llega a abrirse** y no hay acercamiento de cámara inútil. Con `OPEN` la abre. Tras resolverse P3–P6, 10 sigue contestando `SIN_EFECTO` (el compartimento resuelto no reabre su vista).
   - **`C05` (P1): sin dueño propio ni manejador.** 7 lo trata como `ABRIR_VISTA` genérico y **el marco es su receptor** (`registrar_receptor('C05', marco)`, regla 11). Su puerta es **declarativa**: 7 admite `habilitado_si: { ninguno: [archivo_abierto] }` en `C05` (esquema ya soportado, regla 2 de 7), de modo que con P1 `RESUELTO` el panel deja de ser objetivo (sin icono, sin vista, sin acercamiento). P1 nunca está `BLOQUEADO` (`requires.all` vacío), así que `get_view_gate('C05')` solo tiene sentido para pruebas y la red de seguridad. Cierra la Open Question 6 de la ronda anterior (se decide la opción de 7; el marco no necesita manejador de `C05`).
   - **Material (`missing_items`).** Lo calcula el marco **al abrirse la vista** (`on_open`, regla 9) llamando a `has_item` (regla 34), sea quien sea el dueño: con `missing_items` (P1 sin `I-01`, S6) la vista se abre con los elementos sin material y se muestra `locked_feedback`. `get_view_gate` lo devuelve solo como información.
   - **Red de seguridad:** si una vista de un puzle `BLOQUEADO` o `RESUELTO` se abre por otra vía (consola, orden de 21), el marco ejecuta `locked_feedback` y pide `cerrar_vista(view_id, 'sistema')`; el jugador nunca queda dentro de una vista muerta.
   - En un puzle `WORLD` no hay vista: el marco, como manejador de `B01`–`B03` (regla 11), contesta `SIN_EFECTO` si el puzle está `RESUELTO`.
   **Compromiso (engage):** en un puzle `VIEW`, el jugador está *comprometido* mientras su vista cercana está abierta (`on_open` … `on_close`, regla 11; avisos «vista cercana abierta/cerrada» de 7). En un `WORLD` no hay compromiso: las activaciones llegan mientras el puzle está `ACTIVO`.
8. **Configuración al cargar** (secuencia del GDD del 4, regla 9.6: síncrona y leyendo hechos). Para cada puzle, en este orden: (1) si `solved_flag` es verdadero queda `RESUELTO` y el controlador restaura su presentación final **al instante y sin avisos ni sonidos** (`restore_solved_presentation()`); si el hecho de reanudación (`pendiente_revelacion`) sigue verdadero en un puzle ya resuelto (cierre entre dos escrituras, regla 19), el marco lo limpia con la **escritura silenciosa** del 3 (regla 16: sin aviso al bus y sin rehacer la línea base de `dif`); (2) si no, `ACTIVO` si `requires.all` se cumple y `BLOQUEADO` si no; (3) restaura sus `persist` (las posiciones de las lámparas). El estado en memoria de piezas no persistidas (referencias del P1, fichas del P4) **empieza siempre vacío** (regla 22). Los avisos no se repiten: lo que ya ocurrió se reconstruye de los hechos (GDD del 3, regla 8). **Reevaluación inicial:** tras «escena lista», una sola vez, el marco llama a `evaluate()` en los puzles `ON_CHANGE` (P2): un estado `pos = 3,1,4` con `memo_leido` falso (cierre forzado entre la escritura de la lámpara y el guardado, o consola) se resuelve por el camino normal sin esperar a que el jugador mueva una lámpara.

**Interfaz común del controlador**

9. **`PuzzleController`** es una clase base **abstracta** (GDScript no tiene interfaces; `@abstract` está documentado desde 4.5 en `docs/engine-reference/godot/`). Los métodos abstractos los implementa cada puzle; el marco (`PuzzleFramework`, la lógica) mantiene un diccionario `id → controlador` y despacha por `mode`. **Separación de clases:** `PuzzleController` solo contiene los datos y la lógica de **su** puzle; el estado público, la planificación, el bloqueo, la escritura de hechos, los avisos y el *idle* son del `PuzzleFramework`, que posee el único acceso de escritura al estado (3). El controlador no recibe ninguna referencia de escritura (regla 10).
   - `configure(def, flags)`: lee su definición y sus hechos; no escribe nada.
   - `on_open()` / `on_close(motivo)`: el jugador entra o sale de la vista (`VIEW`); son los del contrato `ViewReceiver` de 7 (regla 30 de 7), con `motivo` ∈ `jugador` | `resuelto` | `sistema`. Efecto del `motivo`: `jugador` y `sistema` interrumpen una resolución diferida en curso (regla 18) y aplican la regla 21(b); `resuelto` es el cierre ordenado tras `SOLVED` y no interrumpe nada (la resolución ya terminó).
   - `elements() -> Array[ViewElement]`: contrato de 7: `{id, forma (rectángulo, círculo o polígono en coordenadas locales de la vista, en metros), z_orden, atraccion}`. El controlador emite `elements_changed` **cada vez que cambia una forma o su `z_orden`** (pieza del P3 arrastrada o encajada, referencia del P1 que pasa del papel al hueco, sello del P4); 7 vuelve a consultar `elements()` al abrir la vista y en cada `elements_changed`. `atraccion` es verdadero para lo que el jugador debe señalar con atracción asistida (piezas y huecos del P3, referencias y huecos del P1, botones del P6).
   - `handle_pointer(ev)`: recibe un `PointerEvent` de 7 (`{gesto, fase, elemento, elemento_bajo, pos_px, pos_vista, delta_px, delta_grados}`; gesto `seleccionar`, `mantener`, `agarrar` o `rotar`; fase `inicio`, `actualización`, `fin` o `cancelación`; elemento fijado al pulsar o al iniciar) y actualiza sus piezas. **Qué hace cada controlador con `actualización`:** P3 `agarrar`: mueve la pieza con `delta_px`; P5 `rotar`: suma `delta_grados` a θ (limitada a 0–90°); P1, P4 y P6 (`seleccionar`): ignoran `actualización` de gestos; la `actualización` de «desplazar cursor» (sin botón, `elemento` nulo, `elemento_bajo` informado) solo la usan las ayudas de pista (`AFFORDANCE` de resaltado al pasar el cursor del P4) y **nunca** cuenta como acción de inactividad (F3). Para `WORLD`, `handle_activation(element_id, verb) -> {HECHO, SIN_EFECTO}` (verbo `Girar` de B01–B03); el marco, como manejador de 7 (regla 3 de 7), lo devuelve tal cual desde `interact(verbo, contexto)`: con `HECHO`, **7** reproduce `gesto_hecho` (`HAND_TURN`) y el marco no reproduce ningún gesto de mano; con `SIN_EFECTO` (puzle `RESUELTO`), 7 reproduce `SFX_CLICK_SUBTLE` y `HAND_REACH`.
   - `cancel_gesture()`: regla 11b.
   - `evaluate() -> Verdict`: **función pura** de su estado y su definición; no recibe tiempo y no guarda ningún acumulador. `Verdict` = `NONE` (nada que decir), `HOLDING` (la condición de una política `SUSTAINED` se cumple **en este fotograma**; sin carga), `PARTIAL` (progreso; lleva `progress`, el conjunto de IDs de elemento ya correctos), `REJECT` (intento incorrecto, con el elemento afectado) o `SOLVED` (con carga útil, p. ej. la opción del P6). En `SUSTAINED` el controlador **nunca** devuelve `SOLVED`: el tiempo mantenido (`acum`, F2) es del **marco**, que convierte una racha de `HOLDING` en `SOLVED`.
   - `reset_attempt(scope, element)`: devuelve el intento fallido a un estado válido y reintentable (p. ej. la pieza a la bandeja).
   - `play_resolution(step)`: reproduce la presentación del acierto; en `IMMEDIATE`, una presentación no bloqueante (los hechos ya están escritos); en `DEFERRED`, un paso de la secuencia.
   - `restore_solved_presentation()`: ver regla 8.
   - `apply_hint_effect(effect) -> bool`: aplica un efecto de pista propio del puzle; devuelve si cambió el estado de algún elemento (regla 12b).
   Las formas de `elements()` las usan el picking de 7 y el solucionador de referencia de la regla 30. La clase base solo aporta utilidades de datos (lectura de la definición, formas); todo lo demás (estado, planificación, bloqueo, escritura de hechos, avisos, idle, acumulador de `SUSTAINED`) es del `PuzzleFramework`. No existe `debug_is_solvable()`: la resolubilidad se prueba con un oráculo independiente (regla 30).
10. **Veredicto, no acción.** El controlador *nunca* escribe hechos, emite avisos ni cambia el estado público: solo devuelve el veredicto. Es el marco quien decide qué ocurre con él (reglas 12 a 17). Esto es lo que permite comprobar la política de fallo una sola vez.

**Entrada y puntero**

11. **Gestos entregados (contrato con 7, nombres de 7).** En la **configuración** de la escena (antes de «escena lista», regla 8) el marco se registra con 7 como *receptor* de cada vista de puzle (`registrar_receptor(vista_id, marco)`, contrato `ViewReceiver` de 7: `elements()`, `handle_pointer(ev)`, `on_open()`, `on_close(motivo)`; el marco reenvía al controlador del puzle) y como *manejador* de `B01`–`B03` (`registrar_manejador`; `can_interact(Girar)` = `SI` siempre —un puzle resuelto contesta `SIN_EFECTO`, que 7 muestra—, `interact(Girar, ctx)` → `handle_activation`). `abrir_vista(vista_id)` **no lleva receptor**: lo llaman el dueño (10) o `ABRIR_VISTA` (7). En `VIEW`, el marco recibe los `PointerEvent` de 7 (reglas 20–21 de 7; fases `inicio`, `actualización`, `fin`, `cancelación`) y los reenvía al controlador, salvo que el puzle esté bloqueado por el alcance de un rechazo (regla 14) o en `RESOLVING`. Las formas de `elements()` y la señal `elements_changed` siguen el contrato de la regla 9. El *elemento* de un gesto es el que había bajo el cursor **al pulsar**. La conversión de tolerancias de metros o grados a píxeles la hace 7 (F6); el ratón rota a 1 px ≈ 0,25° (Entrada). **Vocabulario del Jugador (2):** los gestos de mano (`HAND_REACH`, `HAND_TURN`, `HAND_POINT`…) y sus duraciones los fija el Jugador; el regreso de cámara tras cerrar una vista dura `t_devolver` = 0,5 s (regla 18 de 2) y 7 conserva el contexto de entrada bloqueante hasta el aviso «cámara devuelta»; el marco no define ni duplica ninguna de esas duraciones. El `lock` de la regla 14 es un descarte **interno** de eventos del puzle, no un bloqueo de contexto de Entrada (`sin control`). Operaciones de 7 que usa el marco: `registrar_receptor`, `registrar_manejador`, `cerrar_vista(view_id, motivo)` (motivo `jugador`, `resuelto` o `sistema`) y `abrir_lectura(doc_id)`; `abrir_vista` lo llaman otros (10, `ABRIR_VISTA`).
11b. **Cancelación.** Cuando 7 entrega `cancelación` (cierre de la vista, `atrás`, pérdida de foco, pausa, `cerrar_modos()`), el marco llama a `cancel_gesture()`: el controlador devuelve **en silencio** la pieza en el aire a un estado válido (P1: la referencia a su origen; P3: la pieza a la bandeja; P5: el marco interior conserva su θ y se corta el gesto) sin `REJECT`, sin sonido y **sin evaluar** (el gesto cancelado no cuenta como intento). Una ficha del P4 con un solo selector elegido conserva su selección (no es un gesto en vuelo). No se pierde ninguna pieza.

**Comprobación (validación)**

12. **Cinco políticas de comprobación.** Cada puzle declara una; el marco decide cuándo llamar a `evaluate()`:
    - `DELAYED_AFTER_CHANGE` (P1): cuando todos los huecos requeridos están llenos, `delay_s` después del último cambio. Cualquier cambio dentro del retraso cancela y reinicia la cuenta (F1).
    - `ON_CHANGE` (P2): tras cada cambio de estado, sin retraso, y una vez tras la configuración (regla 8).
    - `PER_ELEMENT` (P3, P4): cuando un elemento termina su gesto (pieza soltada, ficha con sus dos selectores completos o «Devolver»); el puzle se resuelve cuando todos los elementos requeridos están correctos (la T4 del P4 está «correcta» al decidirse de cualquiera de las dos formas, regla 12c).
    - `SUSTAINED` (P5): el marco llama a `evaluate()` **cada fotograma** con la vista abierta; el controlador devuelve `HOLDING` mientras se cumple la condición y `NONE` si no. El **acumulador es del marco** (F2): suma `min(dt, dt_max)` por cada `HOLDING` seguido, lo pone a 0 con cualquier otro veredicto, con `on_close` o con `cancelación`, y al llegar a `hold_s` el marco decide `SOLVED` (el controlador no lo devuelve). Con la entrada bloqueada por `RESOLVING` no se evalúa.
    - `ON_CHOICE` (P6): al aceptar la elección; `SOLVED` inmediato con la opción como carga útil.
12b. **Todo cambio de estado pasa por `evaluate()`.** Cualquier operación que cambie el estado de un elemento —un gesto, un efecto de pista (`apply_hint_effect` devuelve `true`, incluido `AUTO_SOLVE_ELEMENT`), una restauración o un `reset_attempt`— cuenta como «un cambio» para la política del puzle: el marco llama a `evaluate()` por el camino normal y procesa el veredicto (`PARTIAL`, `REJECT`, `SOLVED`). Caso protegido: P4 con T2–T4 aceptadas y `request_hint(P4, 3)` resuelve T1 ⇒ `evaluate()` ⇒ `SOLVED` ⇒ `caja_c2` y el resto de la regla 16. Sin esta regla, un puzle podría quedar con todos sus elementos correctos y `ACTIVO` para siempre.
12c. **P4 · la ficha T4 tiene dos salidas válidas (decisión del usuario, 2026-11-09; D-B1 de la revisión cruzada, D9-39 a D9-42).** T1–T3 tienen una única solución (sus dos selectores; acción `ASSIGN`). T4 «Carta a Dirección» **acepta ambas acciones**: `RETURN` («Devolver») o `ASSIGN` (cualquier combinación completa de sus dos selectores, como T1–T3). Ninguna es incorrecta: **T4 no puede producir `REJECT`** (no existe «No corresponde» para T4; el rechazo sigue existiendo para T1–T3). Datos: `solution.T4 = {accept: [RETURN, ASSIGN]}`. Al completarse cualquiera de las dos, el controlador devuelve `PARTIAL` (sello «DEVUELTA» o «ACEPTADA», `SFX_STAMP`, ficha bloqueada) y recuerda `t4_action` ∈ {`RETURN`, `ASSIGN`}. El puzle es `SOLVED` cuando T1–T3 están correctas **y** T4 está decidida (de cualquiera de las dos formas). Una T4 sin decidir **bloquea** `caja_c2` (y por tanto P6) hasta que el jugador la decide, sin temporizador ni penalización; no hay softlock porque ambas acciones están siempre disponibles. **Hecho `t4_decision`** (enum `returned`/`assigned`, sin fijar; owner 9, un solo sentido): el veredicto `SOLVED` lleva el valor (`RETURN`→`returned`, `ASSIGN`→`assigned`) y se escribe en `on_solved.write` **antes** de `caja_c2` (regla 16, como `carta_variante`). **No** se escribe al decidir T4: el estado parcial del P4 no se persiste (D9-8) y, tras cerrar y cargar, el jugador podría decidir la otra opción contra un hecho de un solo sentido ya escrito. Los selectores concretos de una T4 `ASSIGN` no se guardan ni se leen. Ninguna pista decide T4 (regla 25).
13. **Veredictos.**
    - `NONE`: no hace nada (en `SUSTAINED`, además reinicia el acumulador).
    - `HOLDING`: solo en `SUSTAINED`; el marco acumula (F2) y no emite feedback ni `PARTIAL`. En cualquier otra política se trata como `NONE` y se registra como error de datos.
    - `PARTIAL`: el marco compara `progress` con el `progress` del veredicto anterior y emite el feedback parcial de la definición (`on_partial`, p. ej. `SFX_SNAP` del P3, `SFX_STAMP` del P4, `SFX_GLASS_HUM` en P2) **solo por cada elemento incorporado** (regla 13b); el puzle sigue en `IDLE`.
    - `REJECT`: regla 14.
    - `SOLVED`: reglas 16 y 17.
    Toda acción procesada genera una respuesta audible o visible: **el evento de feedback se emite en el mismo fotograma** que la acción (verificable en L); la latencia percibida (`latencia_feedback_ms`, ≤ 100 ms†) se mide en playtest, no es un knob. Si no hay veredicto, responde el objeto (7, regla 11 de 7).
13b. **Borde de `PARTIAL`.** El marco guarda el último `progress` por puzle. `evaluate()` puede llamarse en cada cambio, gesto o fotograma, pero el feedback solo se emite para `progress_nuevo − progress_previo`; si no hay elementos nuevos (p. ej. mover una lámpara del P2 entre dos posiciones sin fragmento) no hay sonido. Si el progreso **baja** (un fragmento del P2 se apaga), el cambio visual ocurre sin sonido de acierto ni de rechazo y el elemento que vuelva a entrar genera de nuevo su feedback. Tras un `REJECT` o un `reset_attempt`, `progress_previo` se recalcula con el estado reiniciado.

**Fallo sin castigo**

14. **Política única de fallo.** Un `REJECT` hace, siempre y solo, lo siguiente: (a) el marco emite el feedback de rechazo (`sfx`, animación, p. ej. `SFX_REJECT`); (b) el controlador ejecuta `reset_attempt(scope, element)` tras `reset_after_s`; (c) la entrada se bloquea según `lock`: `PUZZLE` (todo el puzle, P1: 1,5 s), `ELEMENT` (solo ese elemento, P3: 0,4 s) o `NONE` (P4: la ficha vuelve a neutra al instante y puede reeditarse); (d) las demás piezas **no se tocan** (las fichas correctas del P4 no se reinician). No hay: contador de fallos, límite de intentos, enfriamiento acumulativo, pérdida de piezas, cambio de dificultad, aviso al jugador del número de fallos ni consecuencia en la historia. El bloqueo máximo es `lock_max_s` (2,0 s†): ningún `reset_after_s` de los datos puede superarlo (validación de la regla 29). Los eventos de entrada durante un bloqueo se **descartan**, no se encolan. Una `cancelación` nunca produce `REJECT` (regla 11b).
14b. **«Reducir movimiento» (decisión del usuario, D9-31).** El marco lee la clave booleana `reducir_movimiento` de Ajustes (6) al configurar y al cambiar. Con ella activa: (a) el feedback de rechazo sustituye el temblor/vibración por **un cambio estático** de los elementos afectados (p. ej. los huecos del P1 cambian de tono) de la misma duración (`shake_s`), sin movimiento; (b) el fundido de superposición del P5 (paso `FADE`) pasa a un fundido fijo de 100 ms, **pero el paso conserva su `duration_s`** (la imagen final se mantiene el resto), de modo que F8 y los tiempos no cambian; (c) las demás animaciones del marco que sean movimiento (entreabierto, regreso de la pieza a la bandeja) las resuelve el controlador con cambio instantáneo. El cambio de ajuste con el puzle activo afecta al **siguiente** rechazo o paso, no al que está en curso (art bible §7.4). No altera ninguna regla de entrada, bloqueo ni hechos.
15. **Fallos que no existen.** Los puzles `ON_CHANGE`, `SUSTAINED` y `ON_CHOICE` pueden no tener veredicto `REJECT` (P2, P5 y P6: «el fallo no existe», B.2, B.5 y B.6). El marco los trata igual: si el controlador devuelve `NONE`/`PARTIAL`, no hay feedback de rechazo; un `REJECT` en ellos se trata como `NONE` y se registra como error de datos.

**Resolución**

16. **Orden de escritura al resolver** (`SOLVED`), todo en el mismo fotograma y antes de cualquier presentación larga:
    1. Los hechos de `on_solved.write` en el orden declarado (p. ej. `carta_variante` **antes** de `caja_c4`, para que quien reaccione a `caja_completa` ya lea la variante).
    2. El hecho `solved_flag` (si no estaba ya en la lista).
    3. El estado público pasa a `RESUELTO` (idempotente: si ya lo está no se repite nada).
    4. El aviso `EV_PUZZLE_SOLVED_<ID>`, con `{puzzle, rewards, choice}` (`choice` solo en P6).
    5. Si la definición declara `compartment: n` (P3→1, P4→2, P5→3, P6→4), el aviso «compartimento completado» (n). **Lo emite el marco** (ya posee el orden de escritura de `caja_c<n>`); el guardado (5) lo usa como causa `compartment_done:<n>` y 10 como orden de cierre.
    6. El feedback de acierto (`on_solved.sfx`) y la presentación del controlador (`play_resolution`). Es **no bloqueante**: ningún hecho ni aviso espera a que termine (P6: `SFX_LOCK_CLICK` 0,3 s, tapa 1,6 s, carta, B.6; su final pide `abrir_lectura(I-07)` a 7).
    7. Si la definición lo pide, el marco ordena a 7 `cerrar_vista(view_id, 'resuelto')` tras `close_view_after_s`.
    El hecho `caja_completa` lo recalcula el estado (3, regla 7); el marco no lo escribe. Las recompensas (`rewards`: `I-05`, `I-06a`, `I-07`) viajan en el aviso; el sistema 20 las deriva de los hechos (los ítems no son hechos propios, D.1 del slice).
17. **Resolución inmediata y diferida.** `IMMEDIATE`: la regla 16 se aplica al recibir `SOLVED`. `DEFERRED` (solo P5): el veredicto `SOLVED` inicia la fase `RESOLVING`, que recorre los pasos declarados en `resolution.steps` en orden. Cada paso tiene un `kind` (`OVERLAY_FADE`, `OUTLINE`, `LINE`, `WAIT`) y una duración fija `duration_s`; el paso `LINE` usa la regla 20. Los hechos finales y el estado público solo cambian **al terminar el último paso**. Durante `RESOLVING`: la entrada del puzle queda bloqueada salvo `atrás`; el tiempo es el del reloj de juego del marco (regla 36); y si se interrumpe (reglas 18 y 19) no se escribe nada de la regla 16. La duración total es la de F8 (nominal 16,0 s, **con o sin audio**). **Gesto activo al llegar `SOLVED`:** el marco llama a `cancel_gesture()` (regla 11b) **en silencio** (sin `REJECT`, sin sonido) antes de empezar la secuencia, y el controlador del P5 fija θ = θ* (el marco interior queda alineado).
18. **Interrupción de una resolución diferida.** `RESOLVING` se interrumpe **solo** por salida de la vista: `atrás`, `cerrar_modos()` (cierre forzado de 21), descarga de la escena o cierre por cualquier otra causa. **Un fallo o la ausencia de la línea de audio nunca la interrumpe** (regla 20). La interrupción detiene la secuencia, emite «resolución de puzle interrumpida» (el audio 23 corta la línea con fundido) y deja el puzle en `ACTIVO`/`IDLE` con el hecho de reanudación ya escrito (regla 19). **Nada se pierde ni se penaliza.**
19. **Reanudación.** En `DEFERRED` el marco escribe, **al iniciar** la secuencia, el hecho de reanudación (`resume_flag`: `pendiente_revelacion` = verdadero para P5). Al terminar el último paso escribe, en este orden: `caja_c3` = verdadero (regla 16.1–16.2), `pendiente_revelacion` = falso, y continúa con la regla 16.3 en adelante (estado público, aviso, «compartimento completado»). Este orden hace que cualquier lectura o cierre intermedio vea un estado que, al cargar, ya resuelve el puzle (regla 8.1 limpia el resto). Así cualquier interrupción —incluido cerrar el juego— deja el estado correcto sin lógica extra. Al volver a comprometerse con un puzle con ese hecho verdadero, el marco **salta la comprobación** (la alineación ya se hizo), el controlador del P5 **fija θ = θ\*** (la regla 8 deja θ en `theta_initial_deg`; las fotos «alineadas» de la secuencia lo exigen) y el marco reproduce la secuencia **desde el principio** (el jugador debe oír entera la grabación). Si el juego se cerró durante la secuencia, el último guardado puede ser anterior a la escritura del hecho: entonces el jugador repite la alineación, lo cual es inocuo. El guardado (5) ya guarda en cualquier cambio de `pendiente_revelacion` (causa `reveal_pending`, slice D.3), que cubre el cierre forzado.
20. **Líneas de audio dentro de la secuencia: nunca bloquean.** Un paso `LINE` declara `line` (`VO_G_07`), `fallback_s` (duración nominal de la línea, 14,0 s) y `line_grace_s` (2,0 s†). Al empezar el paso el marco emite «línea pedida» y mide el paso con su reloj; el audio (23) responde con una de tres señales: «línea terminada», «línea sin audio» (la base de contenido, regla 17, permite líneas sin audio durante el prototipado) o «línea fallida» (fallo a mitad o al empezar). El paso termina:
    - en la señal «línea terminada», pero **no más tarde de** `fallback_s + line_grace_s` (si el audio se alarga, 23 corta con fundido);
    - en `fallback_s` desde el inicio del paso si llega «línea sin audio» o «línea fallida» (el subtítulo de 26 dispone de ese tiempo, no de más ni de menos);
    - en `fallback_s + line_grace_s` si **no llega ninguna señal** (señal perdida).
    En ningún caso el puzle se atasca ni se interrumpe, y se registra un aviso de diagnóstico. Esta regla sustituye al `line_timeout_s` de 30 s.
    **Cargas útiles de los avisos de la secuencia** (para el registro y para la regla 10 del GDD del 3): «línea pedida» `{puzzle, line_id, fallback_s}`; las tres señales de 23 (el emisor es 23, no el marco) llevan `{line_id}`; «feedback de puzle» `{puzzle, sound_id, text_key?, element?}`; «puzle activado» `{puzzle, ajar_cm?}` (así recibe 10 el entreabierto sin leer los datos del marco). **Pausa:** una señal de 23 que llegue con el juego en pausa se **retiene** y se procesa al reanudar (el paso se mide con el reloj de juego, regla 36).

**Reinicio y persistencia**

21. **Tres reinicios, ninguno con coste.** (a) *Del intento*: tras un `REJECT` (regla 14) o una `cancelación` (regla 11b). (b) *Al salir*: por defecto **no** se pierde nada al cerrar la vista (`on_close(motivo)`: `KEEP`, con cualquier motivo): el puzle conserva sus piezas mientras dure la sesión de la escena; solo se descartan fases transitorias —el feedback en curso se completa al instante, una comprobación retrasada se cancela y se rearma al volver (F1), una pieza en el aire se devuelve (regla 11b)—. (c) *Al cargar la escena*: el estado en memoria vuelve a su inicio (regla 8). No existe botón de «reiniciar» en el slice; la operación `reset_attempt` se reserva para el sistema 17 y para QA.
22. **Qué se guarda.** Sólo hechos del catálogo del 3: `solved_flag` de cada puzle, y los `persist` del P2 (`pos_L`, `pos_C`, `pos_R`, escritos en **cada** cambio) y del P5 (`pendiente_revelacion`). El progreso parcial no persistido se pierde al cerrar el juego, y eso es deliberado: rehacer un puzle parcial no cuesta nada. El marco **no añade hechos nuevos** al catálogo. El **guardado** (5) tiene sus propias causas: `puzzle_solved:<ID>`, `compartment_done:<n>`, `reveal_pending`, `quit` y `periodic`; las lámparas del P2 no se pierden salvo por un cierre forzado anterior a la siguiente causa (límite `t_periodico` de 5, regla 14 de 5), y ese caso lo cubre la reevaluación inicial de la regla 8.
23. **Resolución sincronizada con el guardado.** El guardado (5) espera a que la cola de avisos esté vacía (GDD del 3, edge case), así que la instantánea nunca contiene un `caja_c4` sin su `caja_completa` ni un `caja_c3` sin su evento. El marco no dispara el guardado: emite `EV_PUZZLE_SOLVED_*` y «compartimento completado» y 5 reacciona a sus causas.

**Dependencias entre puzles**

24. **Cálculo.** El marco escucha el cambio de cada hecho de `requires.all` y, cuando todos son verdaderos, pasa el puzle de `BLOQUEADO` a `ACTIVO`: emite «puzle activado» (con ID) y el feedback `on_unlock`. **P5:** `SFX_UNLOCK_SOFT` y el compartimento entreabierto 2 cm (`ajar_cm`; B.5; lo anima Caja 10). **P6:** solo `SFX_UNLOCK_SOFT` (B.6 no pide entreabierto; `ajar_cm` no se aplica al P6 salvo confirmación, Open Questions 5). Al cargar con el requisito ya cumplido, pasa a `ACTIVO` en silencio (regla 8). El grafo de dependencias del slice es: `P5` requiere `caja_c1`; `P6` requiere `caja_c1`, `caja_c2` y `caja_c3`; el resto no requiere nada (D-16 del slice, pendiente de confirmar). El orden entre P3 y P4 es libre (autonomía).

**Pistas (enganche del sistema 17)**

25. **Datos de pista.** Cada puzle declara `hints`: por nivel, `trigger` (`REQUEST` si solo lo pide el jugador; `IDLE` si aparece tras `idle_s` segundos de inactividad, F3, **y además puede pedirse siempre** desde la pausa: `IDLE` implica `REQUEST`; pedirlo cuenta como alcanzar el nivel y consume el umbral `IDLE`, de modo que no se aplica dos veces), `condition` opcional (estado del puzle que debe cumplirse para aplicar el nivel; hoy solo `HELD_PIECE` en P3 nivel 3, F3; en una petición desde la pausa, donde no hay pieza sostenida, la condición se ignora y se aplica el efecto al hueco de la pieza más cercana a su sitio o, si no hay ninguna, a todos los huecos libres), `availability` (`ALWAYS`, el elemento existe sin pedirlo; `ON_HINT`, se activa al alcanzar ese nivel) y una lista de `effects`: `TEXT` (clave `PISTA_P<n>_N<k>` o una clave de interfaz de la base de contenido), `HIGHLIGHT` (`targets`: IDs de elementos de la vista o de objetos del mundo, y `duration_s`; `targets_if_missing_items` opcional lo sustituye cuando falta un `needs_items`, p. ej. P1 nivel 1 resalta el papel `C05/paper` y, sin `I-01`, la impresora `V08`, 3 s; **sin movimiento de cámara**: ninguna pista cede ni mueve la cámara, regla 14 de 2; decisión D9-32), `AFFORDANCE` (habilita un comportamiento: el halo por proximidad de P2, el número de fila de P3, el resaltado al pasar el cursor de P4) o `AUTO_SOLVE_ELEMENT` (P4: la ficha T1 se resuelve y muestra su explicación; regla 12b. **Solo T1**: la pista de nivel 3 nunca resuelve ni toca T4, porque decidirla es una elección del jugador (regla 12c); con T1–T3 correctas y T4 sin decidir, el nivel 3 no cambia nada más y el puzle sigue `ACTIVO` esperando esa decisión).
26. **API para el sistema 17.** El marco ofrece: `list_puzzles()` (estado de cada puzle y último compromiso), `get_hints(id)` (los datos de la regla 25), `request_hint(id, level)` (valida que el puzle esté `ACTIVO`, aplica los efectos, evalúa si procede —regla 12b— y emite «pista aplicada» con ID y nivel) y las notificaciones «puzle inactivo» (cuando la inactividad cruza el `idle_s` de un nivel; F3). El nivel alcanzado (`hint_level_reached`) se guarda **solo en memoria**, es monótono dentro de la sesión y no se persiste (D.2 no tiene hecho para ello). Mientras el sistema 17 no exista, `idle_hints_auto_apply` (verdadero†) aplica por sí mismo las pistas `IDLE` del slice (P3 nivel 3, P6 niveles 1 y 2); el 17 podrá desactivarlo y asumir ese reparto. **El marco no decide cuándo se ofrece una pista ni cuántas: eso es del 17.** Las pistas se piden desde el menú de pausa (25); el marco sólo las aplica. **Pistas pedidas en pausa:** `request_hint` valida y **escribe en el acto** (el nivel alcanzado; y, si `AUTO_SOLVE_ELEMENT` o una `evaluate()` llevan a `SOLVED`, los hechos y avisos de la regla 16, que son de estado y no de tiempo), pero **todo lo que dura** —la duración del `HIGHLIGHT` o del `TEXT`, la presentación de `play_resolution`, `close_view_after_s`— usa el reloj de juego (regla 36) y por tanto **empieza al reanudar**; el `idle` (F3) tampoco avanza en pausa. Si la pista se pide con la vista cerrada y el efecto es de vista, se aplica al estado y se muestra la próxima vez que se abra.
27. **Consistencia del contenido.** Todo puzle debe declarar **tres** pistas, salvo el **P6, que declara dos** (decisión del usuario, 2026-11-09, D9-14; el slice §10, §16 y §19.2 y la base de contenido (18) ya lo reflejan). Cada texto de pista debe existir en la base de contenido; un puzle sin pistas completas hace fallar la validación (regla 29). El slice exige que cada puzle se resuelva con información que está en el juego (§19.2): las pistas son *énfasis* de esa información, nunca información nueva.

**Garantías contra el atasco (anti-softlock)**

28. **Invariantes que el marco hace cumplir.**
    - **S1 · Sin estado terminal de fallo:** no existe `FALLIDO`; un puzle `ACTIVO` sólo puede ir a `RESUELTO`.
    - **S2 · Monotonía:** `RESUELTO` no vuelve a `ACTIVO` ni `ACTIVO` a `BLOQUEADO`, salvo la consola de desarrollo (regla 31).
    - **S3 · Ninguna regla castiga el tiempo ni lo exige al jugador:** no hay temporizadores de solución ni límites («este puzle no tiene reglas de tiempo», P4). Existen retrasos de *presentación* (`hold_s` 0,8 s, `delay_s` 0,6 s, la secuencia del P5) y de bloqueo (≤ `lock_max_s`), todos medidos con el reloj de juego propio (`GameClock`, regla 36).
    - **S4 · Salida siempre posible:** `atrás` cierra cualquier vista, con las excepciones de la regla 23 de 7 (transición de ≤ 3 s).
    - **S5 · Dependencias alcanzables:** todo hecho de `requires.all` lo escribe otro puzle del mismo fichero, sin ciclos (regla 29).
    - **S6 · Material recuperable:** si un puzle necesita un ítem (P1: `I-01`), la falta no bloquea la historia: el jugador puede ir a conseguirlo (imprimir en `V08` tras `correos_leidos`, repetible; regla 34), y la vista muestra los elementos sin material y el texto `locked_feedback`.
    - **S7 · Resolubilidad:** desde cualquier estado alcanzable —incluidas pistas, cancelaciones, cierres y reaperturas de vista, y guardar y cargar a mitad— existe una secuencia de acciones del jugador que lleva a `SOLVED` (regla 30).
    - **S8 · Reanudación:** toda resolución diferida es interrumpible y reanudable (reglas 18 y 19).
    - **S9 · Un solo acierto:** `SOLVED` sólo transiciona una vez (idempotente); un segundo `SOLVED` en el mismo fotograma se descarta.
29. **Validación de los datos al arrancar.** Corre en la secuencia de carga de 4 **después** de cargar los catálogos de 7 y las claves de 18 y **antes** de configurar los puzles y registrar receptores y manejadores (regla 8); ese es el punto en que 4 debe poder abortar con «datos de puzle inválidos» (Cambios requeridos en 4). Comprueba: `id` y `solved_flag` únicos y declarados en `flags.json`; `requires.all` sin ciclos y con escritor; cada tiempo de `on_reject` ≤ `lock_max_s`; tres pistas (dos en P6) con claves existentes en 18; el estado inicial **no** satisface su propia solución (p. ej. `pos_*` iniciales 2,2,2 frente a 3,1,4; θ inicial 0° frente a 40°); `view`/`elements` existen en el catálogo de 7; para vistas, los elementos cumplen `pick_min_px` y la separación mínima R₁+R₂ entre elementos con el R por elemento de Entrada F5b (regla 22 de 7), calculada con la tolerancia **asistida** (`asistencia_encaje` 0,10 m → 220 px, R = 128, separación 256 px, el peor caso); es una **advertencia de validación** (se registra en desarrollo; no es fallo de carga), salvo que la separación sea < R₁+R₂ con la tolerancia **normal** (88 px, R = 88, 176 px) **y** la zona no declare la excepción **«atracción desactivada en esa zona»** (campo de la vista en `puzzles.json`): entonces es fallo de arranque; `needs_items` y `rewards` existen en el catálogo de ítems; todo `DEFERRED` declara `resume_flag` y todo paso `LINE` su `fallback_s`; los campos enteros son enteros. **Fallo** (cualquier error de validación que no sea una de las advertencias anteriores): en **desarrollo**, error visible y la ejecución se detiene en el arranque. En la **build final**, cualquier error de validación se trata **igual que un `puzzles.json` ausente o corrupto**: fallo de carga del GDD del 4 (regla 14: mensaje claro y vuelta al título; el 4 emite «carga de escena fallida» del 3 y el marco no deja nada a medio configurar); **nunca** un puzle «inactivo». Justificación: los seis puzles están en el camino crítico (P1→puerta A; P3→P5→P6→llamada), de modo que un puzle inactivo es un softlock silencioso que contradice S1/S7 y el pilar *Tensión sin castigo*; un fichero empaquetado en solo lectura no puede ser inválido por una acción del jugador, así que un error aquí es un defecto de empaquetado y debe ser ruidoso. Consecuencia deliberada: tras el fallo se vuelve al título y «Continuar» repetiría el mismo fallo (no hay partida que rescatar de un defecto de empaquetado). Para que no llegue a ningún jugador, esta validación es una puerta de CI que bloquea el empaquetado (AC-47). No se mantiene una «definición de seguridad» embebida: duplicaría los datos y derivaría de ellos.
30. **Prueba de resolubilidad (desarrollo): oráculo independiente.** Una prueba automática ejecuta, por puzle, `N_fuzz` (1.000†) secuencias aleatorias de acciones válidas. Las acciones incluyen **también** pistas (`request_hint` de cualquier nivel), `cancelación`, cerrar y reabrir la vista, y guardar y cargar a mitad. Tras cada acción, un **solucionador de referencia** (código de test, fuera de los controladores) que conoce la solución *de los datos* y las posiciones de `elements()` la reproduce desde ese estado **por la tubería real** (`handle_pointer` → `evaluate()` → marco) sobre una copia del estado, y debe llegar a `RESUELTO` y a escribir el hecho esperado; además, ningún hecho inválido. El controlador no aporta su propio oráculo. Es el test que sostiene S7.
31. **Consola de desarrollo.** Si el estado (3) fuerza un `solved_flag` o un `requires` en una build de desarrollo, el marco reconcilia el puzle con los hechos (a `RESUELTO` en silencio, a `ACTIVO`/`BLOQUEADO` con el estado en memoria reiniciado) sin emitir `EV_PUZZLE_SOLVED_*`. Los hechos mandan.

**Instrumentación de playtest**

32. **Registro local (solo builds de desarrollo y de playtest).** Por puzle: tiempo hasta resolver, número de intentos y rechazos, pistas pedidas y aplicadas y cierres de vista. Sirve para el criterio 5 del slice (§19) y para calibrar los tiempos de Formulas. **Nunca** se muestra al jugador ni afecta a ninguna regla (pilar *Tensión sin castigo*). No existe en la build de la demo.

**Contratos añadidos en la revisión**

33. **Cierre de vistas.** El cierre automático tras resolver se llama `close_view_after_s` en datos (F4); 7 lo ejecuta con `cerrar_vista(view_id, 'resuelto')` y deja de usar `t_auto_salida_s`. Si el jugador pulsa `atrás` a la vez, 7 ignora la segunda petición (edge case).
34. **Ítems.** El marco consulta a 20 `has_item(item_id)` (‡) para calcular `missing_items` (regla 7). 20 deriva de los hechos los ítems que tienen hecho (D.1 del slice: `I-05`, `I-06a`, `I-07`…). **`I-01` es la excepción (decisión D9-33):** no tiene hecho propio y **no se conserva entre sesiones**; `correos_leidos` solo habilita la acción de imprimir en `V08`, que 19/20 deben hacer **repetible e ilimitada** (cada impresión entrega `I-01` si el jugador no lo tiene). Tras cargar con `correos_leidos` verdadero, `has_item('I-01')` es falso hasta que el jugador vuelva a imprimir: no se salta la impresión ni queda un atasco (S6, AC-39b). 19/20 deben cumplirlo (Cambios requeridos).
35. **Reapertura de un puzle `RESUELTO`.** `on_reopen` (defecto `NO_VIEW`): el dueño consulta `get_view_gate` (regla 7), recibe `SOLVED` y contesta `SIN_EFECTO`; la vista no se abre, el compartimento o el panel permanece en su presentación final (`restore_solved_presentation`). **P6:** la carta (D-14, «permanente») se relee desde el bolsillo con `abrir_lectura(I-07)`, que es una petición a 20/7 independiente de la vista; el compartimento queda abierto. Si una vista resuelta se abriera por otra vía, el marco la cierra de inmediato (`cerrar_vista`, motivo `sistema`) sin escribir nada. El P2 (`WORLD`) responde `SIN_EFECTO` con `SFX_CLICK_SUBTLE` a las lámparas.
36. **Reloj de juego propio (requisito de diseño).** Todo temporizador del marco (F1, F2, F3, F8, bloqueos de la regla 14, `close_view_after_s`, `line_grace_s`) usa un `GameClock` inyectable que avanza solo con el tiempo de juego, no `SceneTreeTimer` ni `await get_tree().create_timer()`. Esto permite pruebas deterministas (AC con reloj falso) y que la pausa detenga los temporizadores del marco por construcción. Que además se detengan los `Tween` y las líneas de audio de otros sistemas al pausar (`SceneTree.paused`, `process_mode`) **no está cubierto por `docs/engine-reference/godot/`**: pendiente de verificación en el editor 4.7 (Open Questions 4). Es el único término de «tiempo» de este GDD: «tiempo de juego» = lectura del `GameClock`.
37. **Gancho de audio.** «Línea terminada» de 23 se apoya en la señal `finished` de `AudioStreamPlayer` (documentada en `modules/audio.md`); el marco nunca temporiza audio con `_process`.


### States and Transitions

| Estado público | Fase interna | Qué ocurre | Sale hacia |
|---|---|---|---|
| `BLOQUEADO` | — | No admite compromiso: el dueño responde `SIN_EFECTO` (regla 7). Escucha los hechos de `requires.all`. | `ACTIVO` (requisitos cumplidos) |
| `ACTIVO` | `IDLE` | Espera acciones del jugador; cuenta inactividad si hay compromiso (F3). | `EVALUATING` · `FEEDBACK` · `RESOLVING` · `RESUELTO` |
| `ACTIVO` | `EVALUATING` | Cuenta atrás de una comprobación `DELAYED_AFTER_CHANGE` o acumulador `SUSTAINED` del marco en marcha (`evaluate()` devuelve `HOLDING`, F2). | `IDLE` (cambio o salida) · `FEEDBACK` (`REJECT`) · `RESOLVING`/`RESUELTO` (`SOLVED`) |
| `ACTIVO` | `FEEDBACK` | Reproduce el rechazo y bloquea la entrada según el alcance (regla 14). Dura ≤ `lock_max_s`. | `IDLE` |
| `ACTIVO` | `RESOLVING` | Secuencia diferida (P5). Sólo `atrás`. Un fallo de audio no la interrumpe (regla 20). | `RESUELTO` (fin) · `IDLE` (salida de la vista; hecho de reanudación ya escrito) |
| `RESUELTO` | — | Inerte; su vista no se abre (regla 35); ecos sin efecto (`SFX_CLICK_SUBTLE`) en `WORLD`. Su presentación final permanece. | — (terminal, salvo consola) |

Un puzle `RESUELTO` no cambia ninguna pieza ante ningún gesto. En el P2 esto significa que las lámparas dejan de girar una vez resuelto el memorando, que queda legible de forma permanente (Decisiones).

### Matriz de encaje: los seis puzles frente al marco

| | P1 Cronología | P2 Memorando | P3 Foto | P4 Tablero | P5 Espejo | P6 Decisión |
|---|---|---|---|---|---|---|
| `mode` · lugar | `VIEW` · `C05` | **`WORLD`** (modo `MUNDO` de 7) · `B01`–`B03` | `VIEW` · `D01a` | `VIEW` · `D01b` | `VIEW` · `D01c` | `VIEW` · `D01d` |
| Estado inicial | `ACTIVO` (+ `needs_items` `I-01`) | `ACTIVO` | `ACTIVO` | `ACTIVO` | `BLOQUEADO` (`caja_c1`) | `BLOQUEADO` (`caja_c1`∧`c2`∧`c3`) |
| Política | `DELAYED_AFTER_CHANGE` 0,6 s | `ON_CHANGE` | `PER_ELEMENT` | `PER_ELEMENT` | `SUSTAINED` 0,8 s | `ON_CHOICE` |
| `REJECT` | Sí: 1,2 s de vibración, 1,5 s de reset, `lock` `PUZZLE` | **No existe** | Sí: vuelve a bandeja 0,4 s, `lock` `ELEMENT` | Sí, **solo T1–T3**: ficha a neutra + «No corresponde» 1,5 s, `lock` `NONE`. **T4 nunca** (ambas acciones son válidas, regla 12c) | **No existe** | **No existe** |
| `PARTIAL` (`progress`) | — | Fragmentos iluminados (`SFX_GLASS_HUM`) | Piezas encajadas (`SFX_SNAP`) | Fichas selladas (`SFX_STAMP`) | — (usa `HOLDING`, sin sonido) | — |
| Resolución | `IMMEDIATE` (`SFX_UNLOCK` 1,4 s) | `IMMEDIATE` (`SFX_GLASS_HUM` 2,0 s) | `IMMEDIATE` (marco 1,0 s) | `IMMEDIATE` | **`DEFERRED`** (16,0 s nominales, F8) | `IMMEDIATE` + presentación (0,3 s + 1,6 s) y carta |
| Hechos al resolver | `archivo_abierto` | `memo_leido` | `caja_c1` | `t4_decision` → `caja_c2` | `caja_c3` → limpia `pendiente_revelacion` | `carta_variante` → `caja_c4` |
| «Compartimento completado» | — | — | 1 | 2 | 3 | 4 |
| `persist` | — | `pos_L/C/R` | — | — | `pendiente_revelacion` (reanudación) | — |
| `assist` | — | — | `asistencia_encaje` (0,10 m) | — | `asistencia_rotacion` (±6°) | — |
| Pistas | 3 | 3 | 3 (nivel 3 `IDLE` 60 s) | 3 | 3 | **2** (`IDLE` 10 s y 20 s) |
| Reapertura (`on_reopen`) | `NO_VIEW` | lámparas `SIN_EFECTO` | `NO_VIEW` | `NO_VIEW` | `NO_VIEW` | `NO_VIEW`; la carta se relee con `abrir_lectura(I-07)` |
| Encaja sin excepciones | Sí | No | Sí | Sí | No | No |

**Puzles que fuerzan excepciones al protocolo común** (cada una tiene un punto de extensión previsto, no un caso especial en el código):
- **P2 · modo `WORLD`**: se resuelve desde la exploración, sin vista ni cursor, y sin compromiso. Extensión: `mode: WORLD` y `handle_activation`; el idle y los gestos de puntero no aplican; persiste su estado intermedio (`pos_*`). **Discrepancia del slice:** §10.2 dice «si falla, las lámparas parpadean»; el Anexo B.2 dice «fallo: no existe». Se sigue B.2 (más específico).
- **P5 · resolución diferida e interrumpible**: la resolución dura 16,0 s nominales y puede interrumpirse sin perder nada; la línea de audio no la bloquea. Extensión: `resolution.kind: DEFERRED`, reglas 17 a 20, hecho de reanudación; veredicto `HOLDING` con acumulador del marco. **Discrepancia del slice:** §10.5 dice «si falla, el marco vuelve a su posición inicial»; B.5 dice «no hay fallo». Se sigue B.5.
- **P6 · elección única, sin fallo, con carga útil y dos pistas**: no hay respuesta incorrecta, la elección es definitiva (D-14, pendiente de confirmar) y fija un enumerado. Extensión: `ON_CHOICE`, `choice` en el aviso y **dos niveles de pista** (B.6; decisión D9-14, ya reflejada en el slice y en 18).
- **P1 · ítem necesario**: `ACTIVO` desde el inicio pero sin material. Extensión: `needs_items` y `locked_feedback`; no es una excepción de lógica.
- **P3 y P4**: encajan sin excepciones (P3 con un hueco que *debe* quedar vacío, expresado como «elementos requeridos = 5 de 6»; P4 con una ficha, T4, cuya solución es una lista de acciones aceptadas y cuyo valor se escribe como hecho en `on_solved.write`, regla 12c: es un dato de la definición, no un caso especial del código).

### Interactions with Other Systems

| Sistema | Qué recibe del marco | Qué entrega al marco |
|---|---|---|
| 3 Estado y bus | Escritura de `archivo_abierto`, `memo_leido`, `pos_*`, `caja_c1`–`c4`, `pendiente_revelacion`, `carta_variante`, `t4_decision`; avisos `EV_PUZZLE_SOLVED_P1`–`P6`, «compartimento completado» (1–4), «puzle activado», «resolución de puzle interrumpida», «pista aplicada», «puzle inactivo», «feedback de puzle», «línea pedida» | Lectura de hechos al configurar; avisos de cambio de los `requires.all` |
| 4 Escena de planta | — | Secuencia de configuración síncrona y «escena lista» (regla 8) |
| 7 Interacción e inspección | Receptor de las vistas de puzle (`registrar_receptor`, `elements()` y `elements_changed`, `on_open`/`on_close(motivo)`) y manejador de `B01`–`B03` (`interact` → `{HECHO, SIN_EFECTO}`); `cerrar_vista(view_id, 'resuelto')` tras `close_view_after_s`; `abrir_lectura(I-07)` | `PointerEvent` (fases `inicio`/`actualización`/`fin`/`cancelación`), activaciones `Girar` del modo `MUNDO`, avisos «vista cercana abierta/cerrada», gesto `gesto_hecho`; `habilitado_si` de `C05`; `abrir_vista(vista_id)` desde `ABRIR_VISTA` |
| 2 Jugador | — (vía 7) | Duración del regreso de cámara (0,5 s) y vocabulario `HAND_*`. **Sin** gesto de cámara de pista (D9-32) |
| 10 Caja y compartimentos ‡ | «Puzle activado» `{puzzle, ajar_cm?}`, `EV_PUZZLE_SOLVED_*`, «compartimento completado» y `get_view_gate` (que 10 consulta antes de `abrir_vista`) para responder `SIN_EFECTO` | `D01a`–`D01d` como vistas; las animaciones de apertura |
| 11–16 Puzles | Datos de su definición, gestos, tolerancia asistida | Veredictos, presentación |
| 17 Sistema de pistas ‡ | `list_puzzles`, `get_hints`, `request_hint`, avisos de inactividad | Cuándo y cuánto ofrecer |
| 6 Ajustes | — | `asistencia_encaje`, `asistencia_rotacion` y `reducir_movimiento` (lectura al configurar y al cambiar; afectan al siguiente rechazo o paso, regla 14b) |
| 8 Control de acceso | Hecho `archivo_abierto` (lo lee 8; la puerta A empieza a abrirse al escribirse) | — |
| 19 Ordenador | — | Origen de `I-01` (vía 20) y de `correos_leidos` |
| 20 Documentos y bolsillo | `rewards` en el aviso | `has_item(id)` ‡; ítems; `abrir_lectura` de la carta (P6) |
| 21 Director de escenas | `caja_completa` (derivado del 3) vía el estado | `cerrar_modos()` en cierres forzados |
| 23 Director de audio ‡ | «feedback de puzle», «línea pedida» | «línea terminada» / «línea sin audio» / «línea fallida» |
| 25 Menú de pausa | `request_hint` (a través de 17) | Pausa (detiene el reloj de juego, regla 36) |
| 26 Subtítulos | Subtítulo de líneas sin audio (el tiempo es `fallback_s`) | — |
| 28 Atmósfera · 29 Shaders | Avisos de resolución, estado de P2 y P5 | — |
| 5 Guardado y carga | Hechos de puzle y `pendiente_revelacion` en la instantánea; avisos que son sus causas (`puzzle_solved`, `compartment_done`, `reveal_pending`) | — |
| 18 Base de contenido | — | Claves de pistas (3 por puzle, 2 en P6) y textos de rechazo/bloqueo; invalida la carga si faltan (regla 29) |


## Formulas

### F1 · Comprobación retrasada con rebote

`t_comprobar = t_ultimo_cambio + delay_s;   se evalúa si, en t_comprobar, ningún cambio ocurrió en (t_ultimo_cambio, t_comprobar] y todos los huecos requeridos están llenos;   si el jugador sale de la vista, se cancela y se rearma al volver`

**Variables:** `delay_s` 0,6 s† (0,3–1,5; Anexo B.1); tiempos del `GameClock` (la pausa los detiene).
**Output Range:** evalúa una o cero veces por secuencia de cambios.
**Example:** el jugador completa H1 a H4 en t = 10,00 s; en t = 10,40 mueve la referencia de H3 → nuevo `t_comprobar` = 11,00 s. Si no toca más, a los 11,00 s se evalúa. Si sale de la vista en 10,70 s, se cancela; al volver con los cuatro huecos llenos se rearma otros 0,6 s.

### F2 · Condición mantenida

`acum' = acum + min(dt, dt_max)  si  evaluate() = HOLDING (|θ − θ*| ≤ tol),  si no  0;   el marco decide SOLVED cuando  acum ≥ hold_s − ε`

*(El controlador es puro: solo dice `HOLDING` o `NONE` según `|θ − θ*| ≤ tol` en este fotograma; `acum` y `dt` son del marco, regla 12.)*

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| θ | float (°) | 0–90 | calculated | Ángulo actual del marco interior |
| θ* | float (°) | — | data, 40 | Ángulo de la solución |
| tol | float (°) | 2–10 | data, 3 (normal) / 6 (asistido) | Tolerancia; se elige con `asistencia_rotacion` |
| hold_s | float (s) | 0,4–1,5 | data, 0,8† | Tiempo seguido dentro de la tolerancia |
| dt_max | float (s) | 0,05–0,2 | data, 0,1† | Tope por fotograma, para que un tirón no complete la cuenta |
| ε | float (s) | — | constante, 0,0001 | Épsilon de comparación en coma flotante; evita que `48 × (1/60)` falle por redondeo |

**Output Range:** `acum` ≥ 0; `SOLVED` o nada. A 60 fps con `dt` = 1/60 se resuelve en el fotograma 48 (o, como mucho, el 49, según el redondeo; ambos son válidos).
**Example:** con tol 3, θ = 38° (|Δ| = 2) y 60 fps, tras 48 fotogramas `acum` ≈ 0,80 s ≥ 0,7999 → `SOLVED` (47 fotogramas: 0,7833 < 0,7999, no). Si a los 0,5 s θ pasa a 43,5° (|Δ| = 3,5 > 3), `acum` = 0 y se necesita otro 0,8 s completo; con asistencia (tol 6), 43,5° seguiría dentro. Con un tirón de dt = 0,5 s, se acumulan solo 0,1 s.

### F3 · Inactividad

`idle = t_ahora − t_ultima_accion`  (solo con compromiso). **Una «acción»**, que reinicia `idle` a 0 y mueve el ancla del puntero, es: el **inicio, el fin o la cancelación de un gesto** (`seleccionar`, `mantener`, `agarrar`, `rotar`), el cambio de estado de un elemento o la aplicación de una pista. **El mero movimiento del cursor o la deriva de un stick no es una acción.** Cada puzle declara qué cuenta (`idle_reset`):
- `GESTURE` (por defecto): lo anterior.
- `GESTURE_AND_MOVE` (**P3**, «sin movimiento»): además, un desplazamiento del puntero superior a `idle_move_px` (40 px†, en el viewport lógico de 1920×1080) respecto al ancla; el ruido por debajo de esa zona muerta no reinicia.
- `PRESS_ONLY` (**P6**, «sin pulsar»): solo el inicio de un `seleccionar`; mover el cursor nunca reinicia.

**Umbrales y condición.** Cada nivel `IDLE` declara `idle_s` y, opcionalmente, una `condition` de estado (P3 nivel 3: `HELD_PIECE`, «la pieza sostenida»). Al cruzar `idle_s` el umbral queda **vencido** y se emite «puzle inactivo» (nivel); la pista se aplica en cuanto la condición se cumple —puede ser en ese instante o más tarde— aunque `idle` se reinicie entretanto, y se dispara **una vez por compromiso** (se rearma al volver a comprometerse). Si la condición no se cumple al vencer (P3 sin pieza en la mano), el umbral **no se consume**.

**Variables:** `t_ultima_accion` en reloj de juego (en pausa `idle` no avanza); los umbrales `idle_s` por nivel: P3 nivel 3 = 60 s† (30–120), P6 niveles 1 y 2 = 10 s† y 20 s† (5–60), ambos medidos desde la misma última acción (el nivel 2 no se reancla al mostrar el 1).
**Output Range:** ≥ 0 s.
**Example:** P6: con la vista abierta, a los 10 s sin pulsar aparece «Solo puedes elegir una vez»; a los 20 s, «La carta no cambia; cambia la primera frase». Si el jugador mueve el cursor a los 15 s, `idle` **no** cambia: el nivel 2 sale a los 20 s. P3: pieza sostenida quieta (ruido de 6 px < 40 px) desde t = 0: a los 60 s se marca el contorno de su hueco. Si a los 60 s la mano está vacía, el umbral queda vencido; cuando el jugador agarra una pieza, el contorno aparece en ese mismo momento.

### F4 · Cierre automático tras resolver

`t_cierre = t_resuelto + close_view_after_s;   si close_view_after_s es nulo: no hay cierre`

**Variables:** `close_view_after_s` 1,5 s† (0,5–3,0) en P1, P3, P4 y P5; nulo en P6 (el jugador cierra tras leer la carta). El regreso de cámara posterior dura `t_devolver` = 0,5 s (Jugador, regla 18).
**Output Range:** instante de la petición `cerrar_vista(view_id, 'resuelto')` a 7; la cámara está de vuelta en `t_cierre + 0,5 s`.
**Example:** P1 se resuelve en t = 20,0 s: `SFX_UNLOCK` (1,4 s) y la puerta A empieza a abrirse (8 reacciona a `archivo_abierto`); a 21,5 s se pide el cierre y a 22,0 s la cámara ha vuelto y el jugador ve la puerta abierta.

### F5 · Orden de los hechos al resolver (P6)

`escribir carta_variante = x  →  caja_c4 = verdadero  →  (el estado recalcula caja_completa)  →  aviso EV_PUZZLE_SOLVED_P6`

**Variables:** `x` ∈ {A, B, C}.
**Output Range:** tres cambios de hecho y un aviso, todo en el mismo fotograma.
**Example:** el jugador pulsa «Estoy bien» (A): `carta_variante` = A, `caja_c4` = verdadero, `caja_completa` = verdadero si `caja_c1`–`c3` ya lo eran; quien escuche `caja_completa` ya ve `carta_variante` = A.

### F6 · Coste de la fuerza bruta (comprobación del diseño)

`T_peor = (N − 1) · (delay_s + reset_after_s + t_gestos)`   ·   `T_media ≈ ((N − 1) / 2) · (delay_s + reset_after_s + t_gestos)`

**Variables:** `N` combinaciones posibles (opciones por elemento en `PER_ELEMENT`); `t_gestos` tiempo de colocar la combinación (clics del jugador, ~0,4 s cada uno).
**Output Range:** segundos.
**Example:** **P1**: N = 4! = 24; un intento necesita **8 clics** (cuatro veces «referencia, hueco») = 3,2 s, más 0,6 s de `delay_s` y 1,5 s de reset ⇒ 5,3 s por intento fallido; `T_peor` = 23 · 5,3 ≈ 122 s y `T_media` ≈ 11,5 · 5,3 ≈ 61 s. **P4**: cada ficha tiene **N = 10** opciones (3 × 3 combinaciones de selectores más «Devolver»); con `lock` `NONE` no hay `delay_s` ni reset, y una combinación son 2 clics (0,8 s): `T_peor` por ficha con solución única (T1–T3) = 9 · 0,8 ≈ 7,2 s y ≈ 22 s para las tres. T4 acepta las 10 opciones: un solo intento, 0 s de fuerza bruta (regla 12c). Se acepta: ver Edge Cases (degenerate strategies).

### F7 · Objetivos de duración (referencia de playtest, no de código)

| Puzle | Tiempo objetivo de un jugador nuevo (min)† |
|---|---|
| P1 Cronología | 2–4 (incluye ir al ordenador y a la impresora) |
| P2 Memorando | 3–6 |
| P3 Foto | 1,5–3 |
| P4 Tablero | 2–4 |
| P5 Espejo | 1,5–3 (más ~16 s de revelación) |
| P6 Decisión | 0,5–2 |
| **Total** | **10,5–22** dentro de los 25–30 min del slice (§19.1) |

Son los anclajes de tuning (TTC) que el registro de playtest de la regla 32 contrasta; el criterio 5 del slice (§19) añade: al menos la mitad de los jugadores identifica la diferencia del P5 sin pista de nivel 3.

### F8 · Duración de la secuencia diferida (P5)

`T_seq = Σ duration_s(pasos no LINE) + T_line`
`T_line = min(t_terminada, fallback_s + line_grace_s)   si llega «línea terminada»`
`T_line = fallback_s                                    si llega «línea sin audio» o «línea fallida»`
`T_line = fallback_s + line_grace_s                     si no llega ninguna señal`

**Variables:** `duration_s` de `FADE` (= `reveal_fade_s`) 1,2 s y de `OUTLINE` 0,8 s†; `fallback_s` 14,0 s (la línea `VO_G_07` dura «unos 14 s», B.5); `line_grace_s` 2,0 s†; `t_terminada` medido desde el inicio del paso `LINE`.
**Output Range:** `T_seq` ∈ [2,0, 18,0] s (el mínimo, 2,0 s, es el de una línea que termina al instante; en la práctica 2,0 + `t_terminada`); **nominal 16,0 s** (sin audio, o con audio de exactamente 14,0 s), enlazado con F7 («~16 s de revelación») y con AC-20.
**Example:** sin audio: 1,2 + 0,8 + 14,0 = **16,0 s**. Línea que termina a 13,2 s: 2,0 + 13,2 = 15,2 s. Línea de 15,5 s: 2,0 + 15,5 = 17,5 s. Línea de 17 s: se corta a 16,0 s ⇒ 18,0 s. Señal perdida: 2,0 + 16,0 = 18,0 s. Fallo de audio a los 7 s de la línea: el paso continúa hasta `fallback_s` ⇒ 16,0 s.

## Edge Cases

**Estado y ciclo de vida**
- **If el jugador intenta abrir la vista de un puzle `BLOQUEADO`** (p. ej. `D01c` antes de `caja_c1`): el dueño (10) consulta `get_view_gate`, recibe `BLOCKED` y contesta `SIN_EFECTO` con `locked_feedback`; la vista no se abre, no hay acercamiento de cámara ni consecuencia (regla 7). Si la vista se abriera por otra vía, el marco la cierra (red de seguridad).
- **If el jugador intenta abrir la vista de un puzle `RESUELTO`**: ídem con `SOLVED`; la presentación final permanece (regla 35). La carta del P6 se relee desde el bolsillo con `abrir_lectura(I-07)`.
- **If `requires.all` se cumple mientras el jugador está en otra sala**: el puzle pasa a `ACTIVO` y se emite «puzle activado»; Caja (10) anima el compartimento cuando el jugador lo vea (o lo deja ya entreabierto al cargar, P5).
- **If el jugador carga una partida con `caja_c1` verdadero**: P3 se restaura `RESUELTO` (marco completo y compartimento cerrado, sin avisos) y P5 queda `ACTIVO` en silencio (regla 8).
- **If se guarda con `pendiente_revelacion` verdadero y se reanuda**: P5 queda `ACTIVO` con la reanudación pendiente; al comprometerse, salta la alineación y reproduce la secuencia entera (regla 19). Si no estaba guardado, el jugador repite la alineación (inocuo).
- **If se carga con `caja_c3` verdadero y `pendiente_revelacion` verdadero** (cierre entre las dos escrituras de la regla 19): P5 se restaura `RESUELTO` y el marco limpia `pendiente_revelacion` en silencio (regla 8).
- **If se carga con P2 en la solución (`pos` = 3,1,4) y `memo_leido` falso**: tras «escena lista» el marco evalúa una vez el P2 y lo resuelve por el camino normal (regla 8).
- **If `SOLVED` llega dos veces en el mismo fotograma** (clic y mando): el segundo se descarta (S9, regla 28).
- **If se pide `request_hint` sobre un puzle `BLOQUEADO` o `RESUELTO`**: se rechaza y se registra; el 17 no debe ofrecerlo, pero el marco no depende de ello.
- **If una pista cambia el estado de un elemento** (`AUTO_SOLVE_ELEMENT`): el marco llama a `evaluate()` y procesa el veredicto; si era el último elemento pendiente, el puzle se resuelve (regla 12b).
- **If se fuerza un hecho con la consola**: regla 31; los hechos mandan.

**Comprobación y fallo**
- **If el jugador cambia una referencia durante el retraso de 0,6 s** (P1): se reinicia la cuenta (F1).
- **If el jugador sale de la vista durante `EVALUATING` o `FEEDBACK`**: la comprobación se cancela; el rechazo en curso se completa al instante (las referencias vuelven al papel, la pieza a la bandeja) y al volver el estado es válido y reintentable (regla 21).
- **If llega `cancelación` con una pieza en el aire** (P1, P3), un `rotar` en curso (P5) o un arrastre cualquiera: `cancel_gesture()` devuelve la pieza en silencio, sin `REJECT` y sin evaluar (regla 11b).
- **If llega una acción durante un bloqueo `PUZZLE`/`ELEMENT`**: se descarta, no se encola, y el cursor sigue moviéndose.
- **If la ventana pierde el foco o se pausa en medio de un rechazo, una comprobación o una secuencia**: todos los temporizadores del marco son del reloj de juego y se detienen (regla 36); al reanudar continúan donde estaban (Entrada, regla 7). `cancelación` llega primero si había un gesto en curso.
- **If el controlador devuelve `REJECT` en una política que no lo admite** (P2, P5, P6): el marco lo trata como `NONE` y, en desarrollo, lo registra como error de datos.
- **If `evaluate()` devuelve `PARTIAL` sin elementos nuevos** (mover una lámpara entre dos posiciones sin fragmento): no hay feedback (regla 13b). **If el progreso baja**: cambio visual sin sonido (regla 13b).
- **If dos elementos reciben `PARTIAL` a la vez** (dos fichas con selectores completados en el mismo fotograma): se procesan en el orden de llegada; cada una genera su feedback.
- **If el jugador intenta encajar en el hueco S6 vacío del P3**: el elemento lo rechaza (`REJECT`, `lock` `ELEMENT`), igual que una pieza equivocada; la pieza vuelve a la bandeja (B.3).
- **If el jugador deja una ficha del P4 sin decidir y sale**: permanece como está; el puzle sigue `ACTIVO` (§13.3). Con T1–T3 correctas y **T4 sin decidir**, `caja_c2` no se escribe hasta que el jugador devuelve T4 o completa sus dos selectores (regla 12c): sin temporizador ni pista que la decida.
- **If el jugador decide T4 (`RETURN` o `ASSIGN`) antes que T1–T3**: la ficha queda bloqueada con su sello; `t4_decision` aún no se escribe. **If cierra y carga antes de resolver el P4**: no se conserva (D9-8) y puede decidirla de nuevo, de la misma o de la otra forma.
- **If `t4_decision` ya tiene valor y `caja_c2` es falso** (consola de desarrollo o dato corrupto): al cargar, el marco no rescribe `t4_decision`; si el jugador resuelve el P4 con una decisión distinta, la escritura es rechazada por el estado (regla 6 de 3) y se trata como error de datos (como cualquier hecho de un solo sentido).
- **If el jugador pulsa un segundo botón del P6 en el mismo fotograma que el primero**: el primero que llegue al marco gana; el segundo se descarta (S9).
- **If el jugador cierra el juego en `RESOLVING`**: ver regla 19; no se escribe nada de la resolución.

**Resolución**
- **If una escritura de hecho es rechazada por el estado** (valor distinto en un hecho de un solo sentido): el puzle se queda en el estado anterior, se registra el error y, en desarrollo, la ejecución se detiene (regla 6 del GDD del 3).
- **If la línea de audio del P5 no existe, falla a mitad o no responde**: la secuencia **continúa** y dura lo que dicen la regla 20 y F8 (16,0 s con «sin audio» o «fallida»; 18,0 s con señal perdida); nunca se interrumpe por esa causa. El subtítulo se muestra según 26.
- **If el jugador sale de la vista durante la revelación** (`atrás`, `cerrar_modos()`, descarga): se trata como interrupción (regla 18).
- **If la vista se cierra por `resuelto` mientras el jugador pulsa `atrás`**: un solo cierre; 7 ignora la segunda petición.
- **If el jugador resuelve P4 antes que P3**: es válido (no tienen dependencias entre sí); la lista de tareas (I-05) llega antes que la nota (I-06a).
- **If falta el ítem necesario** (P1 sin `I-01`): la vista se abre con los elementos sin material y el texto de `locked_feedback`; el puzle sigue `ACTIVO` (regla 7). La pista de nivel 1 del P1 usa `targets_if_missing_items` (resalta la impresora `V08`; regla 25).
- **If se carga con `correos_leidos` verdadero y sin `I-01`** (no se conserva entre sesiones): `has_item('I-01')` es falso; P1 sigue `ACTIVO` y resoluble tras volver a imprimir (regla 34, AC-39b). No se salta la impresión.
- **If se pide una pista en pausa**: se escribe el estado en el acto y todo lo que dura empieza al reanudar (regla 26, AC-50).
- **If se cambia `asistencia_*` o `reducir_movimiento` con un puzle activo**: afecta a la siguiente tolerancia, rechazo o paso, no al que está en curso (regla 14b, AC-52).
- **If `HOLDING` se interrumpe** (θ sale de tolerancia, `on_close`, `cancelación`): `acum` vuelve a 0 (regla 12, AC-14).
- **If se resuelve un compartimento**: «compartimento completado» (n) se emite tras `EV_PUZZLE_SOLVED_*` (regla 16.5) y, en la carga, no se vuelve a emitir.

**Degenerate strategies (Sirlin, «Playing to Win»)**
- **Fuerza bruta (P1, P4):** P1 admite 24 intentos como máximo (F6: ≤ 122 s); P4, 10 opciones por ficha (≈ 22 s las tres con solución única; T4 acepta todas). Se acepta, no es dominante en términos de diseño: no daña al jugador (sin contador ni penalización) y todos los puzles entregan su contenido narrativo *después* de resolverse, de modo que forzarlos no se salta la historia. Se instrumenta (regla 32) para detectar si es común.
- **Barrido del P5:** girar el marco a toda velocidad y detenerse ante la marca de 40° es una estrategia legítima (la marca se ilumina en el nivel 3); `hold_s` evita que cruzarla en el barrido resuelva sin querer.
- **Pedir pistas de inmediato:** no existe coste que lo limite; es una decisión de autonomía. Si se abusa y daña el criterio 5 del slice, se resuelve en el sistema 17 (espaciado), no con una penalización aquí.
- **Dejar fichas sin decidir (P4) como «guardado»:** inocuo; no hay temporizador.
- **Resolver P6 sin pensar:** válido por diseño («No hay respuesta incorrecta»).

**Datos y herramientas**
- **If `puzzles.json` falta, está corrupto o falla cualquier validación de la regla 29**: en desarrollo, error visible y la ejecución se detiene; en la build final es un fallo de empaquetado, no un camino de juego: la escena no se activa a medias y se aplica el fallo de carga del GDD del 4 (regla 14: mensaje claro y vuelta al título). **Nunca** queda un puzle inactivo.
- **If un campo entero del JSON llega como `float`** (`pos`, `sequence`, `level`): el cargador lo convierte a `int` y lo comprueba; si no es exactamente entero, es un error de validación (regla 29).
- **If una pista `AFFORDANCE` se activa en un puzle ya `RESUELTO`**: no tiene efecto.

## Dependencies

**Aguas arriba (de qué depende)**

| Sistema | Tipo | Qué necesita |
|---|---|---|
| 3 Estado y bus de eventos | Dura | Leer y escribir los hechos de puzle (con `owner = 9` ‡); emitir `EV_PUZZLE_SOLVED_*` y los demás avisos; recibir cambios de los `requires.all` |
| 4 Escena de planta | Dura | Secuencia de configuración síncrona (regla 9.6) y «escena lista»; fallo de carga (regla 14) |
| 7 Interacción e inspección | Dura | Vistas cercanas (`registrar_receptor`, `cerrar_vista`), `PointerEvent` (4 fases), `elements()`/`elements_changed`, activaciones del modo `MUNDO`, `registrar_manejador` |
| 2 Jugador | Blanda (vía 7) | Regreso de cámara (0,5 s), vocabulario `HAND_*`; no entrega ningún gesto de cámara de pista |
| 18 Base de contenido | Dura en validación | Claves de pista (3 por puzle, 2 en P6) y de textos de rechazo/bloqueo; si faltan, falla la carga (regla 29) |
| 6 Ajustes persistentes | Blanda | `asistencia_encaje`, `asistencia_rotacion` y `reducir_movimiento` |
| 20 Documentos y bolsillo | Blanda (‡) | `has_item(id)` para `needs_items` |
| 23 Director de audio | Blanda (‡) | «línea terminada» / «sin audio» / «fallida» (si faltan, rige `fallback_s + line_grace_s`) |
| 26 Subtítulos | Blanda (‡) | Mostrar el subtítulo de una línea sin audio durante `fallback_s` |
| 25 Menú de pausa | Blanda (‡) | Pausa del reloj de juego; origen de `request_hint` |

**Aguas abajo**

| Sistema | Tipo | Interfaz |
|---|---|---|
| 10 Caja y compartimentos | Dura | «Puzle activado», `EV_PUZZLE_SOLVED_*`, «compartimento completado», `get_view_gate` |
| 11–16 Puzles | Dura | Implementan `PuzzleController` |
| 17 Sistema de pistas | Dura (cuando exista) | `list_puzzles`, `get_hints`, `request_hint`, «puzle inactivo» |
| 5 Guardado y carga | Blanda | Sus causas `puzzle_solved`, `compartment_done` y `reveal_pending` son avisos del marco |
| 8 Control de acceso | Indirecta | Lee `archivo_abierto` (`ANIM_DOOR_OPEN` del P1 tras la escritura) |
| 19 Ordenador · 20 Documentos | Indirecta | 20 recibe `rewards` y `abrir_lectura`; 19 origina `I-01` |
| 21 Director de escenas | Indirecta | Lee `caja_completa` (derivado); puede pedir `cerrar_modos()` |
| 28 Atmósfera · 29 Shaders | Blanda | Avisos de resolución |

**Índice de sistemas:** la fila 9 debe listar `3, 4, 7, 18 (dura en validación) · blandas 2, 6, 20, 23, 25, 26` y mover 18 de las blandas a la dura (Cambios requeridos). Las filas de los puzles 11 a 16 ya listan al 9. **Bidireccionalidad:** el GDD del 3 ya lista al 9 como escritor y emisor, con la salvedad de la propiedad de hechos (regla 1, ‡ 3); el GDD del 7 lista al 9 como receptor de las vistas y **debe corregir** `requires.items` → `needs_items`, la fila de `D01a`–`D01d`, `habilitado_si` de `C05` y citar `get_view_gate` (Cambios requeridos); el GDD de Ajustes lista a 13 y 15 «vía marco 9»; el GDD del 4 lista al 9 como *Dura*; el 5 usa los avisos del marco como causas; el 18 debe listar al 9 y declarar dos pistas para P6. Los GDD de 10 a 17 deben listar al 9 como dependencia, usar los veredictos y la interfaz de la regla 9, y no escribir hechos por su cuenta.

## Tuning Knobs

**F** = feel, **C** = curva, **G** = gate. Todos viven en `assets/data/puzzles/puzzles.json` (valores del slice en negrita: vienen del Anexo B; el resto es †).

| Knob | Cat. | Defecto | Rango seguro | Qué afecta y por qué ese valor |
|---|---|---|---|---|
| `delay_s` (P1) | F | **0,6 s** | 0,3–1,5 | Pausa antes de comprobar. Muy bajo: castiga corregir la última referencia; muy alto: se siente lento |
| `shake_s` / `reset_after_s` (P1) | F | **1,2 s / 1,5 s** | 0,6–2,0 / ≤ `lock_max_s` | Duración del rechazo y vuelta de las referencias |
| `unlock_sfx_s` (P1, `SFX_UNLOCK`) | F | **1,4 s** | 0,8–2,5 | Duración del acierto del P1 antes de `close_view_after_s` |
| `piece_return_s` (P3) | F | **0,4 s** | 0,2–1,0 | Vuelta de la pieza a la bandeja |
| `frame_lit_s` (P3) | F | **1,0 s** | 0,5–2,0 | Marco iluminado al resolver |
| `snap_radius_m` (P3) | F | **0,04 m** (asistido **0,10 m**) | 0,03–0,06 / 0,06–0,15 | Tolerancia de encaje; accesibilidad motriz |
| `view_distance_m` (P3) | F | **0,35 m** | 0,25–0,5 | Distancia de la vista de cierre |
| `no_corresponde_s` (P4) | F | **1,5 s** | 1,0–3,0 | Tiempo del mensaje de ficha incorrecta |
| `theta_solution_deg` (P5) | C | **40°** | 20–70 | Ángulo de la solución (valor de referencia del slice) |
| `tol_deg` (P5) | C | **3° (asistido 6°)** | 2–5 / 4–10 | Tolerancia de alineación |
| `hold_s` (P5) | F | **0,8 s** | 0,4–1,5 | Tiempo mantenido para iniciar la revelación |
| `theta_initial_deg` (P5) | C | 0°† | 0–90 (fuera de `θ* ± tol`) | Ángulo de partida |
| `reveal_fade_s` (P5, paso `FADE`) | F | **1,2 s** | 0,6–2,0 | Fundido de superposición (parte de F8) |
| `reveal_outline_s` (P5, paso `OUTLINE`) | F | 0,8 s† | 0,4–1,5 | Aparición del contorno de Vera (parte de F8) |
| `line_fallback_s` (P5, paso `LINE`) | G | **14,0 s** | = duración real de `VO_G_07` (±1) | Duración de reserva del paso de línea; define los 16,0 s nominales (F8) |
| `line_grace_s` | G | 2,0 s† | 1,0–4,0 | Margen máximo sobre `fallback_s` (sustituye a `line_timeout_s` de 30 s) |
| `fragment_fade_s` (P2) | F | **0,8 s** | 0,4–1,5 | Fundido al iluminar un fragmento |
| `glass_hum_s` (P2, resolución) | F | **2,0 s** | 1,0–3,0 | `SFX_GLASS_HUM` al resolver |
| `ajar_cm` (P5) | F | **2 cm** | 1–4 | Cuánto se entreabre el compartimento al desbloquearse. Solo P5 (B.5); P6 = 0 salvo confirmación (Open Questions 5) |
| `close_view_after_s` | F | 1,5 s† | 0,5–3,0 | Cuándo se pide cerrar la vista tras resolver (nombre único; sustituye a `t_auto_salida_s` de 7) |
| `lock_max_s` | G | 2,0 s† | 1,0–**2,0** | Tope de bloqueo de entrada tras un rechazo; el rango no supera el AC-X2 («≤ 2 s») |
| `locked_feedback` (por puzle) | F | `SFX_CLICK_SUBTLE`, sin texto | clave de 18 | Respuesta del dueño a un puzle `BLOQUEADO`/`RESUELTO` o sin material |
| `highlight_s` (P1 nivel 1) | F | **3,0 s** | 1,5–5,0 | Duración del resaltado de la pista del P1 (antes `camera_nudge_s`, D9-32) |
| `hint_text_s` (P2 nivel 1) | F | 2,0 s† | 1,0–4,0 | Duración del texto de pista del P2 |
| `idle_s` P3 nivel 3 | G | **60 s** | 30–120 | Cuándo aparece el contorno sin pedirlo |
| `idle_s` P6 niveles 1 y 2 | G | **10 s / 20 s** | 5–60 | Cuándo aparecen los mensajes |
| `idle_move_px` (P3) | G | 40 px† | 16–120 | Zona muerta del movimiento para F3 (viewport lógico 1920×1080) |
| `idle_hints_auto_apply` | G | verdadero† | bool | Aplicar pistas `IDLE` sin el sistema 17 |
| `dt_max` | F | 0,1 s† | 0,05–0,2 | Tope por fotograma de F2 |
| `N_fuzz` | G | 1.000† | 100–10.000 | Secuencias por puzle de la prueba de resolubilidad |

`latencia_feedback_ms` (100†, 50–200) **no es un knob de sensación**: es el umbral de verificación de la latencia percibida en playtest (AC-13, V/I); en pruebas automáticas se comprueba que el evento se emite en el mismo fotograma. Se mantiene en el registro como constante de verificación.

## Visual/Audio Requirements

*(Sección opcional para la categoría Gameplay; en modo `lean` no se consulta a `art-director` ni a `audio-director`: revisar antes de producción.)*

- **Sonidos** (de B.7 del slice, sin añadir): `SFX_SLIDE_OK`, `SFX_SLOT_IN` (P1), `SFX_UNLOCK` (P1), `SFX_UNLOCK_SOFT` (desbloqueo de compartimento), `SFX_REJECT` (cualquier rechazo), `SFX_GLASS_HUM` (P2), `SFX_SNAP` (P3), `SFX_STAMP` (P4), `SFX_LOCK_CLICK` (P6), `SFX_CLICK_SUBTLE` (eco sin efecto), `BOX_C1_OPEN`–`BOX_C4_OPEN`. El marco los pide por el aviso «feedback de puzle»; cómo suenan es de 23.
- **Rechazo:** debe ser **legible pero no punitivo**: vibración breve, sonido seco y bajo, sin tonos de error agudos ni destellos (pilar *Tensión sin castigo*; coherente con `reducir_sobresaltos`, que atenúa los destellos del pasillo y del apagón en 28).
- **Resolución:** cada acierto debe poder reconocerse con la pantalla apagada (sonido) y con el sonido apagado (cambio visible): doble canal para accesibilidad.
- **P5 · revelación:** la superposición de las fotos y el contorno de Vera la implementa 29 (versión provisional en el MVP, nota del índice). El marco sólo da el instante y la duración.
- **Desbloqueo:** en el P5 el compartimento entreabierto 2 cm es el único aviso **positivo** de que algo nuevo está disponible (no hay marcadores); el P6 solo suena `SFX_UNLOCK_SOFT` (Open Questions 5). Un compartimento bloqueado sigue mostrando el icono de interacción y contesta `SIN_EFECTO` (D9-34, pendiente de confirmar por el usuario).
- **Reducir movimiento:** con `reducir_movimiento` el rechazo es un cambio estático y el fundido del P5 dura 100 ms (regla 14b).

## Game Feel

- **Respuesta:** toda acción procesada emite su feedback en el mismo fotograma y se percibe en ≤ `latencia_feedback_ms` (100†, medida en playtest). Un rechazo nunca deja la pantalla «muerta» más de `lock_max_s` (2,0 s†).
- **Fallo:** el jugador debe sentir «lo intenté y no era», no «me han castigado»: rechazo corto (≤ 1,5 s), reintento inmediato posible, sin contador a la vista.
- **Acierto:** nítido y breve; el compartimento, la puerta o el cristal confirman con cambio de mundo, no con un cartel.
- **P5:** la alineación se siente «imanada» sin ser automática; la marca de 40° no se muestra hasta el nivel 3. La revelación tiene su ritmo propio (~16 s) y salir de ella nunca asusta.
- **Referencia de comparación:** valores † a afinar en el primer playtest (slice §23.4) con los tiempos objetivo de F7.

## UI Requirements

- **Sin barras, sin contadores de intentos, sin cronómetros, sin porcentaje de progreso** (slice §16). El único feedback es diegético (vibración, sellos, luz).
- **Textos de puzle** (reglas del tablero, «No corresponde» —solo T1–T3—, «ACEPTADA»/«DEVUELTA», pistas): claves de la base de contenido (18); ningún literal en el código.
- **Pistas:** se piden desde el menú de pausa (25), con tres niveles por puzle (dos en P6; las `IDLE` también se pueden pedir); la interfaz de pistas es del sistema 17. Los efectos empiezan al reanudar (regla 26).
- **Cursor y elementos:** los de 7 (`pick_min_px`) y los de Entrada (cursor virtual).
- **Accesibilidad:** `asistencia_encaje` y `asistencia_rotacion` se activan en Ajustes (6) y las lee el marco en cada puzle; el marco no tiene pantalla propia.

📌 **UX Flag — Marco de puzles**: los seis puzles tienen vistas con requisitos de interfaz (pistas, textos, sellos). En preproducción, ejecuta `/ux-design` para cada vista cercana antes de escribir las épicas.

## Cross-References

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · §10, §13.3, §16, §19 | Puzles, pistas, sin softlock, sin game over, criterios 2, 3, 5 y 7 | Define el alcance y las garantías (tres pistas por puzle, dos en P6: ya coherente desde `4636af1`). **Pendiente en el slice (D-B1, requiere autorización):** B.4 (solución y resultado de T4, sin «No corresponde» para T4), §10.4 y D.2 (20 hechos, `t4_decision`). **Pendiente en el slice:** el gesto de cámara de la pista del P1 (~l.136 y ~l.724) pasa a resaltado (D9-32); §8/§13.3 frente al Anexo B sobre el orden de la caja (Cambios requeridos) |
| `design/slice/slice-v0.3.md` · Anexo B (B.1–B.7) | Estados, políticas, tiempos, soluciones, resultados y pistas por puzle | Fuente de los datos de `puzzles.json` |
| `design/slice/slice-v0.3.md` · Anexo D.1, D.2, D.3, D.4 | Ítems, banderas, guardado, índice de IDs | Hechos que escribe el marco. **Desvío puntual de D.2:** `pendiente_revelacion` se escribe al *iniciar* la revelación (no «si se interrumpe»); cambia el *momento* de escritura, no el valor observable (D9-5) |
| `design/slice/slice-v0.3.md` · D-14, D-16 | Carta permanente; orden de la caja | Supuestos pendientes de confirmar |
| `design/gdd/estado-y-bus-de-eventos.md` · reglas 2, 4, 5, 7, 10, 11 | Propiedad, un solo sentido, `pos_*` y `pendiente_revelacion` reversibles, `caja_completa` derivado, avisos `EV_PUZZLE_SOLVED_<ID>` y «compartimento completado», orden de avisos | Contrato directo; el cambio de `owner` a 9 es bloqueo previo (regla 1) |
| `design/gdd/interaccion-e-inspeccion.md` · reglas 3, 8, 19–23, 27 y F6 | Contrato del dueño (`SIN_EFECTO`), habilitado, vista cercana, `PointerEvent`, picking, cierre, `abrir_lectura`, conversión px↔m | Contrato directo (vocabulario de las reglas 9 y 11: `registrar_receptor`, `ViewReceiver`, `ViewElement`, `elements_changed`, cuatro fases, `on_open`/`on_close(motivo)`) |
| `design/gdd/jugador-en-primera-persona.md` · reglas 18, tabla de gestos | `ceder_camara`/`devolver_camara`, `t_devolver` 0,5 s, `HAND_*` | Fija gestos y duraciones |
| `design/gdd/guardado-y-carga.md` · regla 6 | Causas `puzzle_solved`, `compartment_done`, `reveal_pending`, `quit`, `periodic` | Consume los avisos del marco |
| `design/gdd/entrada-y-controles.md` · reglas 6, 8, 12, 13, 14, F4–F6, F8 y Open Question 2 | Gestos, contextos, transiciones, `t_hold`, tolerancias | Origen de los gestos y tiempos |
| `design/gdd/ajustes-persistentes.md` · `asistencia_encaje`, `asistencia_rotacion` | Ayudas de los puzles 3 y 5 | Parámetros asistidos |
| `design/gdd/base-de-contenido-narrativo.md` · reglas 3, 10, 17 | `PISTA_P<n>_N<k>`, fragmentos de `DOC_01`, líneas sin audio | Textos de pistas y del P2 |
| `design/gdd/escena-de-planta.md` · regla 9.6 | Los elementos se configuran leyendo hechos | Base de la regla 8 |
| `docs/engine-reference/godot/` · `@abstract` (4.5+), `AudioStreamPlayer.finished` | Clase base abstracta y señal de fin de audio | Reglas 9 y 37 |
| `design/gdd/game-pillars.md` | *Tensión sin castigo*, *Autonomía como progresión*, *Información incompleta* | Pilares que este sistema sirve |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/puzzles/`), bloqueante; **I** = test de integración o playtest documentado (`tests/integration/puzzles/`), bloqueante; **V** = captura retenida en `production/qa/evidence/`, bloqueante. Los tests L usan un estado (3), un `GameClock` (regla 36), un audio y un 7 falsos, y una fixture de `puzzles.json` por caso. Tolerancia numérica ±0,001 salvo indicación. Los valores † pueden cambiar tras el playtest.

**Ciclo de vida (reglas 6 a 8, 24, 35)**
- **AC-01 (R6, R35, L)**: **GIVEN** la API pública del marco, **THEN** el objeto `PuzzleState` solo expone `activate()` y `resolve()` (no existe método de retroceso; se comprueba llamando a esa API y verificando que ningún otro punto de entrada altera el estado, sin reflexión); **GIVEN** un puzle `RESUELTO`, **WHEN** llega cualquier gesto (o `Girar` en P2), **THEN** no cambia ninguna pieza y suena `SFX_CLICK_SUBTLE`.
- **AC-02 (R8, L)**: **GIVEN** `caja_c1` verdadero al cargar, **THEN** P3 está `RESUELTO` con su presentación final y no se emitió ningún aviso `EV_PUZZLE_SOLVED_P3` ni «compartimento completado»; P5 está `ACTIVO` y no hubo `SFX_UNLOCK_SOFT`.
- **AC-03 (R24, L)**: **GIVEN** P5 `BLOQUEADO`, **WHEN** `caja_c1` pasa a verdadero, **THEN** P5 pasa a `ACTIVO`, se emite «puzle activado» (P5) una vez y suena `SFX_UNLOCK_SOFT` con `ajar_cm` = 2; **GIVEN** P6 con `caja_c1`, `c2` verdaderos y `c3` falso, **THEN** sigue `BLOQUEADO`; con `c3` verdadero, pasa a `ACTIVO` con `SFX_UNLOCK_SOFT` y sin entreabierto.
- **AC-04 (R7, L + I)**: **L:** **GIVEN** P6 `BLOQUEADO`, **THEN** `get_view_gate('D01d')` devuelve `BLOCKED` con `locked_feedback`, no se escribe ningún hecho y, si la vista se abre por otra vía, el marco pide `cerrar_vista('D01d', 'sistema')`. **I:** con 10 y 7 reales, pulsar el compartimento bloqueado produce `SIN_EFECTO` del dueño y **no** hay movimiento de cámara.
- **AC-04b (R7, R11, L)**: **GIVEN** la configuración de la escena, **THEN** el marco ha llamado a `registrar_receptor` para `C05` y `D01a`–`D01d` y a `registrar_manejador` para `B01`–`B03` antes de «escena lista»; **GIVEN** una vista abierta, **WHEN** un controlador cambia la forma de un elemento, **THEN** emite `elements_changed` y `elements()` devuelve `{id, forma, z_orden, atraccion}` actualizados; **WHEN** llega `actualización` de un `agarrar` (P3) o un `rotar` (P5), **THEN** mueve la pieza o suma `delta_grados` a θ; **WHEN** llega `actualización` de «desplazar cursor», **THEN** no cambia ninguna pieza ni reinicia `idle`.
- **AC-05 (R24, L)**: **GIVEN** el orden de resolución P4, P3, P5, P6 y también P3, P5, P4, P6, **THEN** ambos son válidos y terminan con `caja_completa` verdadero.
- **AC-41 (R8, L)**: **GIVEN** `pos` = (3,1,4) y `memo_leido` falso al cargar, **WHEN** llega «escena lista», **THEN** el marco evalúa el P2 una vez y escribe `memo_leido`; **GIVEN** `caja_c3` y `pendiente_revelacion` verdaderos al cargar, **THEN** P5 es `RESUELTO` y `pendiente_revelacion` queda falso sin avisos.
- **AC-42 (R7, R35, L + V)**: **GIVEN** P3, P4 y P5 `RESUELTO`, **THEN** `get_view_gate` devuelve `SOLVED` y el dueño (10) contesta `SIN_EFECTO` sin abrir vista; **GIVEN** P1 `RESUELTO` (`archivo_abierto` verdadero), **THEN** `C05` no es objetivo de interacción (`habilitado_si: ninguno: [archivo_abierto]`), no hay icono ni vista y, si la vista se abriera por otra vía, el marco la cierra con motivo `sistema` sin escribir nada; **GIVEN** P6 `RESUELTO`, **WHEN** el jugador relee la carta, **THEN** se pide `abrir_lectura('I-07')` y el compartimento sigue abierto. **V:** captura de P6 resuelto con el compartimento abierto.

**Veredictos y fallo (reglas 11b, 12 a 15, F1)**
- **AC-06 (R12, F1, L)**: **GIVEN** P1 con `delay_s` 0,6, **WHEN** se llenan los cuatro huecos en t = 10,00 y se cambia H3 en t = 10,40, **THEN** se evalúa a los 11,00 s y no antes; **WHEN** sale de la vista en 10,70, **THEN** no se evalúa y al volver se rearma otros 0,6 s.
- **AC-07 (R14, L)**: **GIVEN** P1 con la secuencia 1,2,3,4, **WHEN** se evalúa, **THEN** `REJECT`: `SFX_REJECT`, los huecos vibran 1,2 s, las referencias vuelven al papel a los 1,5 s, la entrada del puzle queda bloqueada 1,5 s (los eventos se descartan) y después acepta entrada; no existe contador de fallos ni ningún hecho cambia.
- **AC-08 (R14, L)**: **GIVEN** P3 con una pieza fuera del radio de 0,04 m, **WHEN** se suelta, **THEN** `REJECT`: vuelve a la bandeja en 0,4 s, solo esa pieza está bloqueada y las ya encajadas siguen intactas; **GIVEN** `asistencia_encaje` activa, **THEN** a 0,09 m encaja; a 0,11 m, no.
- **AC-09 (R14, L)**: **GIVEN** P4 con T1 aceptada y T2 con la selección incorrecta, **WHEN** se evalúa T2, **THEN** T2 vuelve a neutra, aparece «No corresponde» 1,5 s, T1 sigue bloqueada como correcta y T2 se puede reeditar de inmediato.
- **AC-10 (R14, L)**: **GIVEN** cualquier `on_reject` con `reset_after_s` > `lock_max_s`, **THEN** la validación de datos falla (regla 29).
- **AC-11 (R15, L)**: **GIVEN** P2, P5 y P6, **WHEN** el controlador devuelve `REJECT`, **THEN** se trata como `NONE` y se registra como error de datos.
- **AC-12 (R12, L)**: **GIVEN** P2 con L = 3, C = 1, R = 4, **THEN** `SOLVED`; con L = 3, C = 1, R = 2, **THEN** `PARTIAL` (`progress` = dos fragmentos) y no resuelve; con L = 2 (sello distractor), **THEN** no se ilumina F1.
- **AC-13 (R13, L + V/I)**: **L:** **GIVEN** cualquier acción procesada, **THEN** el evento de feedback se emite en el mismo fotograma de la acción. **V/I:** en playtest, la latencia percibida es ≤ 100 ms† (medida con captura de vídeo o con el registro de la regla 32).
- **AC-43 (R12b, L)**: **GIVEN** P4 con T2 y T3 aceptadas, T4 decidida (probar `RETURN` y `ASSIGN`) y T1 pendiente, **WHEN** `request_hint(P4, 3)`, **THEN** `AUTO_SOLVE_ELEMENT` resuelve T1, el marco llama a `evaluate()`, y se obtiene `SOLVED`: `t4_decision` (con el valor de T4) y luego `caja_c2` verdadero, `EV_PUZZLE_SOLVED_P4` una vez, «compartimento completado» (2) e `I-05` en las recompensas.
- **AC-44 (R13b, L)**: **GIVEN** P2 con 1 fragmento iluminado, **WHEN** se mueve otra lámpara a un punto sin fragmento nuevo, **THEN** `evaluate()` puede devolver `PARTIAL` pero no suena `SFX_GLASS_HUM`; **WHEN** se ilumina un segundo fragmento, **THEN** suena una vez; **WHEN** un fragmento se apaga, **THEN** cambia lo visual sin sonido y no hay `REJECT`.
- **AC-45 (R11b, L)**: **GIVEN** P1 con una referencia en el aire, P3 con una pieza en la mano, P5 en un `rotar`, y P4 con un selector elegido, **WHEN** llega `cancelación` (por `atrás`, pérdida de foco o pausa), **THEN** en cada caso: no hay `REJECT` ni sonido, no se evalúa, la referencia o la pieza vuelve a un estado válido, el marco interior conserva su θ, y la ficha del P4 conserva su selección.

**Comprobación mantenida (F2)**
- **AC-14 (R12, F2, L)**: **GIVEN** un controlador falso que devuelve `HOLDING` N fotogramas seguidos y luego `NONE` (el acumulador se prueba **sin** el controlador del P5), **THEN** el marco resuelve a `acum ≥ hold_s − ε`, nunca antes, y `NONE`, `on_close` o `cancelación` ponen `acum` a 0; el controlador real del P5 nunca devuelve `SOLVED`. **GIVEN** P5 con tol 3, hold 0,8 y 60 fps, **WHEN** θ = 38° se mantiene, **THEN** `SOLVED` se produce **entre el fotograma 48 y el 49** y no antes; **WHEN** θ = 43,5° a mitad, **THEN** `acum` = 0 y reinicia; **GIVEN** `asistencia_rotacion`, **THEN** 43,5° mantiene la cuenta (tol 6).
- **AC-15 (F2, L)**: **GIVEN** un tirón de dt = 0,5 s con θ dentro de tolerancia, **THEN** `acum` aumenta 0,1 s (tope `dt_max`).
- **AC-16 (F2, L)**: **GIVEN** un barrido de θ de 0° a 90° a 200°/s, **THEN** nunca se alcanza `hold_s` y no se resuelve.

**Resolución (reglas 16 a 20, F4, F5, F8)**
- **AC-17 (R16, F5, L)**: **GIVEN** P6 con la opción A, **WHEN** se acepta, **THEN** el orden de escrituras es `carta_variante` = A, `caja_c4`, el estado recalcula `caja_completa`, estado público `RESUELTO`, el aviso `EV_PUZZLE_SOLVED_P6` con `choice` = A y «compartimento completado» (4); ningún suscriptor ve `caja_completa` sin `carta_variante`; la presentación (0,3 s + 1,6 s) no retrasa ningún hecho.
- **AC-18 (R16, L)**: **GIVEN** P1 resuelto, **THEN** se escribe `archivo_abierto`, se emite `EV_PUZZLE_SOLVED_P1` una vez y a los 1,5 s se pide `cerrar_vista('C05', 'resuelto')`.
- **AC-19 (R16, L)**: **GIVEN** P3, P4 y P5 resueltos, **THEN** `caja_c1`, `caja_c2` y `caja_c3` son verdaderos con sus avisos `EV_PUZZLE_SOLVED_P3/P4/P5`, los avisos «compartimento completado» 1, 2 y 3 después de cada uno, y las recompensas `I-06a`, `I-05` en la carga útil.
- **AC-20 (R17, R19, F8, L)**: **GIVEN** P5 con la alineación mantenida y **sin audio** («línea sin audio»), **THEN** `pendiente_revelacion` = verdadero al iniciar la secuencia, `caja_c3` sigue falso; a 1,2 s termina `FADE`, a 2,0 s `OUTLINE`, y a **16,0 s** (±0,05 s de reloj falso) se escribe `caja_c3` = verdadero **y después** `pendiente_revelacion` = falso, con el aviso al final. **GIVEN** audio real que termina a 13,2 s, **THEN** la secuencia dura 15,2 s.
- **AC-21 (R18, L)**: **GIVEN** P5 en `RESOLVING`, **WHEN** el jugador pulsa `atrás` a los 5 s, **THEN** se emite «resolución de puzle interrumpida», `caja_c3` sigue falso, `pendiente_revelacion` sigue verdadero y el puzle vuelve a `IDLE`.
- **AC-46 (R18, L)**: **GIVEN** P5 en `RESOLVING`, **WHEN** llega `cerrar_modos()` (cierre forzado de 21) o la descarga de la escena, **THEN** se interrumpe igual que en AC-21, sin escribir `caja_c3`.
- **AC-22 (R19, L)**: **GIVEN** `pendiente_revelacion` verdadero, **WHEN** el jugador vuelve a comprometerse con P5, **THEN** no se pide alineación y la secuencia se reproduce desde el paso 1.
- **AC-23 (R20, F8, L)**: **GIVEN** que no llega ninguna señal de audio, **THEN** el paso `LINE` termina a `fallback_s + line_grace_s` (16,0 s desde su inicio; secuencia 18,0 s) y `caja_c3` pasa a verdadero; **GIVEN** «línea fallida» a los 7 s de la línea, **THEN** la secuencia **no se interrumpe** y termina a los 16,0 s; **GIVEN** una línea de 17 s, **THEN** se corta a los 16,0 s del paso (secuencia 18,0 s).
- **AC-24 (R16, L)**: **GIVEN** un segundo `SOLVED` en el mismo fotograma, **THEN** se descarta; el aviso se emite una vez.
- **AC-25 (R13, I)**: **GIVEN** P6, **WHEN** el jugador pulsa dos botones a la vez, **THEN** solo uno fija `carta_variante` y los otros dos se bloquean.

**Reinicio y persistencia (reglas 21 a 23)**
- **AC-26 (R21, L)**: **GIVEN** P3 con tres piezas encajadas, **WHEN** se cierra y se reabre la vista, **THEN** conserva las tres; **WHEN** se carga la escena de nuevo, **THEN** empieza vacío.
- **AC-27 (R22, L)**: **GIVEN** P2, **WHEN** cambia una lámpara, **THEN** `pos_X` se escribe en el mismo fotograma; **WHEN** se recarga, **THEN** las lámparas están en la última posición.
- **AC-28 (R22, L)**: **GIVEN** cualquier partida, **THEN** el marco no añade hechos nuevos al catálogo (siguen siendo 19).
- **AC-29 (R23, I)**: **GIVEN** la resolución del P4, **WHEN** se autoguarda, **THEN** la instantánea contiene `caja_c2` y, si procede, `caja_completa` coherente; reanudar muestra P4 `RESUELTO` y `I-05` disponible.

**Pistas (reglas 25 a 27, F3)**
- **AC-30 (R25, R27, L)**: **GIVEN** `puzzles.json` del slice, **THEN** P1–P5 tienen tres pistas, **P6 tiene dos**, y cada clave existe en la base de contenido (18).
- **AC-31 (R26, F3, L)**: **GIVEN** P6 con la vista abierta, **WHEN** pasan 10 s sin pulsar, **THEN** se emite «puzle inactivo» (nivel 1) una sola vez y, con `idle_hints_auto_apply`, se aplica el texto; a 20 s, el nivel 2; si se mueve el cursor a los 15 s (o hay deriva de stick), `idle` **no** se reinicia y el nivel 2 sale a los 20 s; un clic en vacío sí lo reinicia.
- **AC-32 (R26, F3, L)**: **GIVEN** P3 con 60 s sin actuar (ruido de puntero < 40 px) y una pieza sostenida, **THEN** se marca el contorno de su hueco correcto; **GIVEN** 60 s sin pieza en la mano, **THEN** el umbral queda vencido y no se consume, y al agarrar una pieza el contorno aparece en ese momento; **GIVEN** un desplazamiento del puntero de 60 px, **THEN** `idle` se reinicia.
- **AC-33 (R26, L)**: **GIVEN** `request_hint(P4, 3)`, **THEN** T1 se resuelve sola con su explicación («La urgencia sigue al plazo; el responsable, a quien ya lleva el caso») y cuenta como elemento correcto (consecuencias en AC-43); T4 no cambia (AC-55); **GIVEN** un puzle `RESUELTO`, **THEN** `request_hint` se rechaza.
- **AC-34 (R26, L)**: **GIVEN** que se cargó la escena, **THEN** `hint_level_reached` de todos los puzles es 0 (no se persiste).

**Anti-softlock y datos (reglas 28 a 31)**
- **AC-35 (R29, L)**: **GIVEN** un `puzzles.json` con un ciclo de `requires.all` (P5 requiere `caja_c3`), **THEN** la validación falla; **GIVEN** un puzle cuyo estado inicial satisface su solución, **THEN** la validación falla; **GIVEN** un `requires.all` sin escritor, **THEN** falla; **GIVEN** un `DEFERRED` sin `resume_flag` o un paso `LINE` sin `fallback_s`, **THEN** falla; **GIVEN** elementos con tolerancia normal (R = 88) separados menos de 176 px y sin la excepción «atracción desactivada en esa zona», **THEN** falla; **GIVEN** elementos que cumplen 176 px pero no 256 px (asistida, R = 128), **THEN** solo advertencia de validación y la carga continúa; **GIVEN** la excepción declarada, **THEN** ni fallo ni advertencia.
- **AC-36 (R30, L)**: **GIVEN** cada uno de los seis controladores y 1.000 secuencias aleatorias que incluyen gestos, pistas, `cancelación`, cerrar y reabrir la vista, y guardar y cargar, **THEN** tras cada acción el solucionador de referencia (código de test, no del controlador), que conoce la solución de los datos, la reproduce por la tubería real (`handle_pointer` → `evaluate()` → marco) y alcanza `RESUELTO` escribiendo el hecho esperado, y no se escribió ningún hecho inválido. **P4:** el solucionador ejecuta **las dos ramas** de T4 (`RETURN` y `ASSIGN` con una combinación cualquiera de selectores) desde cada estado alcanzable, también con T4 sin decidir, y exige `t4_decision` coherente con la rama; T1–T3 siguen con su solución de datos. **Sanity del oráculo:** con una solución deliberadamente corrupta en una fixture, el solucionador falla.
- **AC-37 (R28, L)**: **GIVEN** cada vista, **WHEN** llega `atrás` en cualquier fase salvo la transición de entrada, **THEN** la vista se cierra y el puzle conserva un estado válido.
- **AC-38 (R28, I)**: **GIVEN** un guion de QA por puzle con las N rutas de error de F6 (24 permutaciones del P1, las 10 opciones por ficha del P4, soltar cada pieza del P3 en cada hueco incorrecto, giros fuera de tolerancia del P5) y un bot que lo ejecuta, **THEN** ninguna ruta deja el puzle sin salida ni exige reiniciar el juego (slice §19.3 y §19.7).
- **AC-39 (S6, R34, L)**: **GIVEN** P1 sin `I-01` (`has_item` falso), **WHEN** se abre la vista, **THEN** muestra los elementos sin material y `locked_feedback`; no se escribe ningún hecho; con `correos_leidos` e `I-01` el puzle es resoluble.
- **AC-39b (S6, R34, L + I)**: **GIVEN** una partida cargada con `correos_leidos` verdadero y sin `I-01` en la sesión, **THEN** `has_item('I-01')` es falso, P1 está `ACTIVO` con la vista sin material y `locked_feedback`; **WHEN** el jugador imprime de nuevo en `V08`, **THEN** obtiene `I-01` (la impresión es repetible) y P1 es resoluble; la pista de nivel 1 resalta `V08` mientras falte `I-01` y `C05/paper` cuando lo tenga.
- **AC-40 (R31, L)**: **GIVEN** la consola forzando `caja_c1` = verdadero con P3 `ACTIVO`, **THEN** P3 pasa a `RESUELTO` en silencio sin `EV_PUZZLE_SOLVED_P3`.
- **AC-47 (R29, L + I)**: **GIVEN** un `puzzles.json` inválido, **THEN** en desarrollo la ejecución se detiene con error visible; en una build final simulada, la escena no se activa y se aplica el fallo de carga del 4 (vuelta al título), y **ningún** puzle queda inactivo; la validación corre como puerta de CI sobre el fichero empaquetado; la puerta **bloquea solo los fallos** de validación, no las advertencias (p. ej. la separación con tolerancia asistida).
- **AC-48 (R5, R29, L)**: **GIVEN** un `puzzles.json` cuyo `sequence` o `pos` se lee como `float` (2.0), **THEN** el cargador lo convierte a `int` y escribe `pos_*` como `int`; **GIVEN** 2.5, **THEN** la validación falla.
- **AC-49 (R16, R1, L)**: **GIVEN** P3 resuelto, **THEN** «compartimento completado» (1) se emite una vez, después de `EV_PUZZLE_SOLVED_P3`, y la causa `compartment_done:1` de 5 se dispara; en la carga no se emite.

**Pausa, ajustes y gestos en vuelo (reglas 14b, 19, 26, 36)**
- **AC-50 (R26, R36, L)**: **GIVEN** el juego en pausa y `request_hint(P4, 3)` sobre un P4 con T2 y T3 aceptadas y T4 decidida, **THEN** `caja_c2` y los avisos se escriben en el acto, y la presentación de `play_resolution` y `close_view_after_s` (reloj falso detenido) **no avanzan** hasta reanudar; **GIVEN** un `HIGHLIGHT` pedido en pausa, **THEN** su `duration_s` empieza a contar al reanudar; **GIVEN** pausa en el P6 con la vista abierta, **THEN** `idle` no avanza.
- **AC-51 (R25, L)**: **GIVEN** el P6 nivel 1 (`trigger: IDLE`), **WHEN** se pide con `request_hint(P6, 1)` desde la pausa, **THEN** se aplica, cuenta como nivel alcanzado y el umbral `IDLE` no lo vuelve a aplicar; **GIVEN** P3 nivel 3 pedido sin pieza en la mano, **THEN** se aplica con la regla de `condition` ignorada (regla 25).
- **AC-52 (R14b, L)**: **GIVEN** `reducir_movimiento` activo, **WHEN** P1 rechaza, **THEN** no hay temblor, los huecos cambian de tono (estático) durante `shake_s` y el bloqueo dura lo mismo; **GIVEN** P5 en la revelación, **THEN** el fundido visual dura 100 ms pero `T_seq` sigue siendo 16,0 s; **GIVEN** un cambio de `asistencia_rotacion` o `reducir_movimiento` durante un rechazo o paso en curso, **THEN** no afecta al en curso y sí al siguiente.
- **AC-53 (R17, R19, L)**: **GIVEN** un `rotar` activo cuando F2 llega a `hold_s`, **THEN** el marco llama a `cancel_gesture()` en silencio (sin `REJECT` ni sonido), el controlador fija θ = θ\* y empieza la secuencia; **GIVEN** `pendiente_revelacion` verdadero al reabrir, **THEN** θ = θ\* antes de la secuencia.
- **AC-54 (R20, L)**: **GIVEN** «línea terminada» recibida con el juego en pausa, **THEN** se retiene y el paso `LINE` termina al reanudar; **GIVEN** «puzle activado» de P5, **THEN** la carga útil lleva `ajar_cm` = 2.

**P4 · T4 de doble salida (regla 12c)**
- **AC-55 (R12c, L)**: **GIVEN** P4 con T1–T3 correctas y T4 sin decidir, **THEN** el puzle sigue `ACTIVO`, `caja_c2` falso y `t4_decision` sin fijar, aunque se pida `request_hint(P4, 3)` (T1 ya correcta, T4 intacta); **WHEN** el jugador pulsa «Devolver» en T4, **THEN** sello «DEVUELTA» (`SFX_STAMP`), ficha bloqueada, `SOLVED`, y las escrituras van en el orden `t4_decision` = `returned`, `caja_c2`, aviso `EV_PUZZLE_SOLVED_P4`.
- **AC-56 (R12c, L)**: **GIVEN** el mismo P4, **WHEN** el jugador completa los dos selectores de T4 con cualquiera de las 9 combinaciones, **THEN** sello «ACEPTADA», ficha bloqueada, `SOLVED`, `t4_decision` = `assigned` antes de `caja_c2`.
- **AC-57 (R12c, R14, L)**: **GIVEN** T4 en cualquier estado y cualquier gesto, **THEN** el controlador nunca devuelve `REJECT` para T4: no aparece «No corresponde» ni suena `SFX_REJECT` por T4; **GIVEN** T2 con selección incorrecta, **THEN** sigue el AC-09.
- **AC-58 (R12c, D9-8, L)**: **GIVEN** T4 decidida y T1–T3 pendientes, **WHEN** se guarda y se carga, **THEN** `t4_decision` sigue sin fijar y T4 puede decidirse de nuevo de cualquiera de las dos formas; la escritura de `t4_decision` es única (reescribir el mismo valor no hace nada; otro valor lo rechaza el estado).

**Experiencia (playtest, I)**
- **AC-X1 (I)**: **GIVEN** un jugador nuevo, **THEN** resuelve cada puzle con información del propio juego (slice §19.2); **y** cada pista de AC-30 referencia un elemento visible en la escena, comprobado por una checklist de QA firmada.
- **AC-X2 (I)**: **GIVEN** 6 testers, **WHEN** se equivocan en un puzle, **THEN** ninguno describe el fallo como «castigo» ni «penalización» (0 de 6) ante la pregunta literal: «¿Cómo describirías lo que pasó cuando te equivocaste?» (respuesta libre, codificada por QA); el tiempo hasta poder reintentar, **medido desde el inicio del rechazo** (la evaluación), es ≤ `lock_max_s` (2,0 s); en P1 el jugador puede actuar de nuevo 2,1 s después de su último clic (0,6 s de `delay_s` + 1,5 s de bloqueo).
- **AC-X3 (I)**: **GIVEN** el registro de la regla 32, **THEN** los tiempos de F7 se cumplen para ≥ 4 de 6 testers y ≥ 50 % identifica la diferencia del P5 sin pista de nivel 3 (slice §19.5).
- **AC-X4 (I)**: **GIVEN** el P5, **WHEN** el jugador sale a medio escuchar la grabación y vuelve, **THEN** la oye entera y se abre el compartimento sin repetir la alineación.

## Decisiones tomadas

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D9-1 | Los controladores devuelven un veredicto y el marco decide la consecuencia | Cada puzle gestiona su fallo, hechos y avisos | Una sola política de fallo verificable (slice §19.3) y un único escritor de hechos |
| D9-2 | Un controlador por puzle + datos para todo valor numérico | Puzle 100 % declarativo | P2 (espacial), P3 (arrastre) y P5 (rotación) necesitan lógica propia; los datos cubren soluciones, tolerancias y tiempos |
| D9-3 | Tres estados públicos del slice + fases internas no publicadas | Más estados públicos (`EVALUANDO`, `FALLIDO`…) | El Anexo B fija tres estados; `FALLIDO` contradeciría el pilar *Tensión sin castigo* |
| D9-4 | El marco es el único escritor de los hechos de puzle | Cada puzle escribe los suyos (como sugiere la tabla de 3) | Garantiza el orden de la regla 16 y la idempotencia; se propone `owner = 9` como bloqueo previo en 3 |
| D9-5 | P5 escribe `pendiente_revelacion` al *iniciar* la revelación y la limpia al terminar | Escribirla solo al interrumpirse | Cubre cerrar el juego, que no puede ejecutar código de interrupción; sin lógica extra (desvía D.2 del slice solo en el momento de escritura) |
| D9-6 | La revelación del P5 se reproduce desde el principio al reanudar | Reanudar la línea de audio donde se cortó | El jugador debe oír la grabación entera (función narrativa del puzle) |
| D9-7 | El P2 pasa a inerte al resolverse (lámparas bloqueadas, memorando permanente) | Dejar las lámparas manipulables | «El memorando completo queda legible» (B.2); evita deshacer visualmente un hecho ya adquirido (`memo_leido` es de un solo sentido) |
| D9-8 | El progreso parcial no se persiste (salvo `pos_*` y `pendiente_revelacion`); 5 guarda con sus propias causas (`puzzle_solved`, `compartment_done`, `reveal_pending`, `quit`, `periodic`) | Persistir piezas colocadas | Rehacer un parcial no cuesta nada; no se añaden hechos. (Sustituye a «el slice solo guarda al completar compartimentos», que ya no es cierto) |
| D9-9 | Rechazo con bloqueo máximo de 2 s y sin contador | Bloqueo creciente o límite de intentos | Pilar *Tensión sin castigo*; la fuerza bruta es barata y se acepta (F6) |
| D9-10 | Pistas `IDLE` se aplican solas hasta que exista el 17 | Dejarlas sin aplicar en el MVP | Son parte del Anexo B (P3 nivel 3, P6); el 17 es Vertical Slice |
| D9-11 | Dependencias de puzle calculadas por el marco (`requires.all`), y Caja (10) anima el hardware | Dependencias dentro de Caja | Misma mecánica para todos los puzles; Caja no necesita lógica de estado |
| D9-12 | Cuando el Anexo B contradice a §10 (P2 y P5 sin fallo; P6 con dos pistas) prevalece el Anexo | Seguir §10 | El Anexo B es la especificación de implementación y más reciente |
| D9-13 | `P1`–`P6` como identificadores de puzle en `EV_PUZZLE_SOLVED_<ID>`; los elementos llevan prefijo de vista (`D01a/piece_1`) | `PZ1`… o IDs planos de elemento | Confirma la propuesta de la regla 10 del GDD del 3; evita la colisión entre las piezas `P1`–`P5` del encaje (B.3) y los puzles |
| D9-14 | **(usuario, 2026-11-09)** P6 tiene **dos** niveles de pista (B.6) | Tres niveles (§10, §16, §19.2) | El Anexo B prevalece (D9-12). El slice y 18 ya lo reflejan (commit `4636af1`) |
| D9-15 | **(usuario)** Un fallo o ausencia de la línea de audio nunca interrumpe `RESOLVING`; reglas 18 y 20 unificadas; duración de reserva por pasos (`fallback_s`) y secuencia nominal de 16,0 s (F8) | Interrumpir por pérdida de audio; esperar `line_timeout_s` de 30 s | La revelación del P5 no puede depender de 23 ni de que exista el audio (prototipado); el tiempo es predecible con o sin audio |
| D9-16 | **(usuario)** Todo cambio de estado de un puzle, incluido `AUTO_SOLVE_ELEMENT`, pasa por `evaluate()` (regla 12b) | Dejar que las pistas fijen el estado sin evaluar | Evita el softlock del P4 (T2–T4 aceptadas + pista nivel 3) |
| D9-17 | **(usuario)** Contrato con 7 y 2: gestos y duraciones los fija el Jugador (`HAND_*`, regreso de cámara 0,5 s); un puzle bloqueado lo contesta su dueño con `SIN_EFECTO` antes de abrir la vista; el marco es receptor de vista y manejador de `B01`–`B03`; modo `WORLD` (código) = `MUNDO` (7); operaciones `abrir_vista`/`cerrar_vista(motivo)`; `close_view_after_s` | Que el marco abra y cierre la vista de un puzle bloqueado; durar 0,6 s el regreso | Un único sitio que decide «bloqueado» y sin acercamiento de cámara inútil; una sola fuente para cada duración. `close_view_after_s` se mantiene porque ya es la clave en datos y en F4 |
| D9-18 | Datos inválidos en la build final = fallo de carga (como fichero ausente) + puerta de CI; en desarrollo, parada con error visible | «Puzle inactivo»; definición de seguridad embebida | Un puzle inactivo es un softlock en el camino crítico; el fichero es de solo lectura (solo un defecto de empaquetado puede romperlo), así que lo correcto es ser ruidoso y bloquear el empaquetado; una definición embebida duplicaría datos y derivaría |
| D9-19 | Inactividad (F3) = gestos de inicio/fin/cancelación, no movimiento; P3 con zona muerta de 40 px; P6 solo pulsaciones; el umbral vence y se dispara cuando se cumple su condición | Reiniciar con cualquier `PointerEvent`; «una vez» consumido al cruzar el umbral | Coincide con «sin pulsar» (B.6) y «sin movimiento… pieza sostenida» (B.3) y no depende del ruido del puntero |
| D9-20 | Resolubilidad con solucionador de referencia externo al controlador, por la tubería real | `debug_is_solvable()` en cada controlador | Un oráculo propio es tautológico; el solucionador conoce los datos, no el código del controlador |
| D9-21 | `PARTIAL` lleva `progress` y el marco emite feedback solo por elementos nuevos; si baja, sin sonido | Feedback en cada `evaluate()` | Evita sonidos repetidos con `ON_CHANGE`/`SUSTAINED` |
| D9-22 | `cancelación` ⇒ `reset_attempt` silencioso, sin `REJECT` ni evaluación | Tratarla como suelta | 7 exige no perder ninguna pieza en el aire; un cierre no es un intento |
| D9-23 | Los puzles `RESUELTO` no abren su vista (`on_reopen: NO_VIEW`); la carta del P6 se relee con `abrir_lectura(I-07)` | Reabrir la vista en modo lectura | D-14 «permanente» se cumple por el bolsillo; evita estados de vista sin interacción |
| D9-24 | El marco emite «compartimento completado» (n) | Que lo emita Caja (10) | El marco ya posee el orden de escritura de `caja_c<n>`; 5 lo usa como causa de guardado y 10 aún no existe |
| D9-25 | `ajar_cm` solo en P5; P6 desbloquea con `SFX_UNLOCK_SOFT` | Aplicarlo también al P6 | B.6 no lo pide; añadirlo sería inventar contenido (Open Questions 5) |
| D9-26 | `requires.all` (transición de estado) separado de `needs_items` (solo `locked_feedback`), con `needs_items` en `puzzles.json` como fuente única | Un solo `requires` con ítems; `requiere_ítem` en `interactables.json` | P1 está `ACTIVO` sin el ítem (S6); duplicar el requisito en dos ficheros genera deriva |
| D9-27 | Orden de P5 al resolver: `caja_c3` y luego limpiar `pendiente_revelacion` | Limpiar primero | Cualquier lectura intermedia es un estado que, al cargar, ya resuelve el puzle |
| D9-28 | Reevaluación única de los puzles `ON_CHANGE` tras «escena lista» | Solo evaluar al cambiar una lámpara | Cubre `pos` en la solución con `memo_leido` falso tras un cierre forzado |
| D9-29 | `PuzzleController` como clase base abstracta (`@abstract`) y `GameClock` inyectable | Interfaz informal; `SceneTreeTimer` | GDScript no tiene interfaces; pruebas deterministas y pausa por construcción |
| D9-30 | `F6` corregida (8 clics por intento en P1; N = 10 por ficha en P4); `ε` en F2; knobs y rango de `lock_max_s` ≤ 2,0 s; S3 reformulada | Valores anteriores | Aritmética y coherencia con AC-X2 y con `hold_s`/`delay_s` |
| D9-31 | **(usuario, ronda 2)** `reducir_movimiento` (booleano de Ajustes) **entra en el MVP**: rechazo = cambio estático en vez de temblor; fundido fijo de 100 ms; los pasos conservan su duración | Dejarlo para después; acortar también las duraciones | Accesibilidad (art bible §7.4); conservar duraciones mantiene F8 y los AC de tiempo |
| D9-32 | **(usuario, ronda 2)** La pista de nivel 1 del P1 es un **resaltado** (`HIGHLIGHT`, 3 s), **sin `CAMERA_NUDGE`** ni ningún movimiento de cámara por el juego; el «gesto de cámara» del slice se reinterpreta. Sin impresión, resalta la impresora `V08` | `CAMERA_NUDGE` con propietario nuevo `pista` en 2 | Se mantiene la regla 14 de 2 (ningún evento mueve la cámara); no se añade ninguna API de cámara |
| D9-33 | `I-01` no se conserva entre sesiones; imprimir en `V08` es **repetible e ilimitado** (19/20) | `has_item('I-01')` verdadero siempre con `correos_leidos` (se salta la impresión y la pista apunta a nada) | Sin atasco tras cargar y sin hechos nuevos (el catálogo sigue en 19); lo recomendado por la re-review (hallazgo 4) |
| D9-34 | Un compartimento bloqueado conserva el icono y contesta `SIN_EFECTO` (D7-16). **Pendiente de confirmar por el usuario** | `can_interact = NO` hasta desbloquearse (sin icono) | Es el comportamiento ya publicado en 7; se pregunta porque es de tono (*Información incompleta* / *Autonomía*) |
| D9-35 | El orden de la caja sigue el **Anexo B** (P5←c1; P6←c1∧c2∧c3); se pide corregir §8/§13.3 del slice. **Pendiente de confirmar por el usuario** (D-16) | P5 y P6 independientes («cualquier orden») | El Anexo B es la especificación de implementación (D9-12) y B.5 usa la foto del P3 completa |
| D9-36 | `evaluate()` es pura; el acumulador de `SUSTAINED` es del marco; el controlador devuelve `HOLDING`; `C05` se cierra con `habilitado_si` en 7; el dueño de cada vista consulta `get_view_gate` (salvo `C05`) | Acumulador en el controlador; manejador propio de `C05` | Controladores deterministas y probables sin reloj; `C05` sin lógica nueva |
| D9-37 | Pistas `IDLE` también son pedibles (`IDLE` ⊃ `REQUEST`); en pausa los efectos empiezan al reanudar y la resolución se escribe en el acto | Solo por inactividad; empezar en pausa | Cumple «accesibles desde el menú de pausa» (slice §10, §16) con un solo reloj |
| D9-38 | Se mantiene `pendiente_revelacion` al *iniciar* la revelación (D9-5, confirmada) y las puertas B/D, la llamada D.2 y el título tras Recepción no cambian este GDD | — | Decisiones de la ronda 2 ya registradas en 3, 5 y 1; el progreso de pistas no se guarda (vuelve al nivel 1) |
| D9-39 | **(usuario, 2026-11-09, D-B1)** T4 acepta `RETURN` y `ASSIGN`; se elimina el `REJECT` «No corresponde» para T4 (T1–T3 lo conservan) | Solución única «Devolver» (B.4 original) · mantener la solución única y corregir solo el pilar | El pilar 1 («ninguna opción es incorrecta») y la «primera elección de autonomía» (§10.4) no admiten una acción moral que el juego declare errónea |
| D9-40 | Recomendación propia: una T4 `ASSIGN` vale con **cualquier** combinación completa de selectores (9); el hecho no guarda los selectores | Exigir una combinación concreta (p. ej. Media/Dirección) para `ASSIGN` | Una combinación «correcta» oculta reintroduciría una respuesta errónea dentro de la rama de aceptar; la elección que importa es devolver o aceptar |
| D9-41 | Recomendación propia: `t4_decision` es un enum de 2 valores + «sin fijar», se escribe en `on_solved.write` antes de `caja_c2`, no al decidir la ficha | Escribirlo al decidir T4 · `bool` `t4_devuelta` | El parcial no se persiste (D9-8): escribirlo antes crearía una contradicción de un solo sentido tras cargar; el enum se lee igual que `carta_variante` y admite un tercer valor |
| D9-42 | Recomendación propia: ninguna pista decide T4; `AUTO_SOLVE_ELEMENT` solo resuelve T1; un T4 sin decidir bloquea `caja_c2` sin softlock | Que el nivel 3 devuelva T4 · que T4 se decida sola tras un tiempo | Decidir T4 es la elección de autonomía; ambas acciones siempre disponibles garantizan S7 |
| D9-43 | **(Ronda 4, B-1)** La separación R₁+R₂ se valida con la tolerancia asistida (256 px) como advertencia de validación; es fallo de arranque solo con la normal (176 px) y sin la excepción «atracción desactivada en esa zona», que la regla 29 incorpora. La puerta de CI (AC-47) bloquea solo fallos | Validar con la normal y dejar lo asistido sin comprobar · fallo siempre (rompe la build con la asistida) | Severidad única con 7 (regla 22): cubre el peor caso sin bloquear el empaquetado por un modo opcional |
| D9-44 | **(Ronda 4, B-3)** Se cierra la Open Question 9 sobre los «20 hechos»: el slice D.2 ya los recoge (incluido `t4_decision`) | Mantener la pregunta abierta | El slice y el registro ya listan los 20; no queda nada que autorizar en ese punto |

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | ~~Dos o tres pistas en P6~~ **Cerrada (D9-14):** dos, ya reflejado en el slice y en 18 | — | — |
| 2 | ~~`abrir_lectura`~~ **Cerrada:** existe en 7 (regla 27b). Queda confirmar que 7/20 lo cierran bien cuando la lectura está apilada sobre la vista de P6 (H-09 de la revisión de 7) | GDD de 2, 7 y 20 | GDD 16 |
| 3 | ~~Guardar con `pendiente_revelacion`~~ **Cerrada:** 5 ya tiene la causa `reveal_pending` | — | — |
| 4 | **Pendiente de verificación en el editor 4.7** (no cubierto por `docs/engine-reference/godot/`): (a) el comportamiento de `SceneTree.paused`/`process_mode` con `Tween`, temporizadores y `AudioStreamPlayer` (el marco usa `GameClock`, pero la pausa de los otros sistemas debe comprobarse); (b) el tipado entero/flotante al parsear JSON (el cargador convierte y valida: AC-48) | `godot-specialist` / ADR | Antes de la ADR de 9 |
| 5 | **¿Debe el compartimento del P6 entreabrirse 2 cm al desbloquearse?** B.6 no lo pide; se mantiene solo en P5 | Creative director / 10 | GDD 10 |
| 6 | ~~Quién registra `C05`~~ **Cerrada (D9-36):** el marco es el receptor y `habilitado_si` de 7 cierra la reapertura. Queda confirmar la clave en 7 | GDD de 7 | Re-review de 7 |
| 9 | **Pendiente (D-B1):** la línea que cambia con `t4_decision` es una **propuesta** en 18 (variante de `VO_G_14`), pendiente de narrative-director/usuario; el slice (B.4, §10.4) debe actualizarse con autorización. *(B-3 cerrada: D.2 ya recoge los 20 hechos, incluido `t4_decision`.)* | Narrative-director / usuario | GDD 22 y 21 |
| 8 | **Pendiente de usuario:** icono en compartimentos bloqueados (D9-34) y orden de la caja frente a §8/§13.3 (D9-35) | Usuario | GDD 10 |
| 7 | Un `fallback_s` de 14,0 s y un `reveal_outline_s` de 0,8 s† deben reajustarse a la duración real de `VO_G_07` cuando exista el audio | Audio (23) | Playtest |

## Propuesta de registro

Para `design/registry/entities.yaml` (no se edita aquí; lo hará quien consolide). El registro **ya tiene** `lock_max_s` (actualizar su `referenced_by`, hoy vacío, a 9), `long_press_threshold`, `rotate_mouse_gain`, `save_periodic_interval_s`, `delay_s_P1`, `snap_radius_m_P3`, `theta_solution_deg_P5`, `hold_s_P5`, `reveal_fade_s_P5`, `line_fallback_s_P5`, `latencia_feedback_ms`, `idle_s_P3_N3` y `close_view_after_s`. **Faltan** (filas marcadas ▲ abajo): `reveal_outline_s_P5`, `line_grace_s`, `idle_s_P6_N1`/`N2`, `idle_move_px_P3`, `tol_deg` (3°/6° asistido), el valor asistido `snap_radius_m_P3` 0,10 m y `highlight_s_P1` (3,0 s). El resto de filas de la tabla es referencia.

| Tipo | Nombre | Valor / contenido | Fuente |
|---|---|---|---|
| constante | `P1`–`P6` | identificadores de puzle (`EV_PUZZLE_SOLVED_P1`…) | este GDD, regla 1 |
| constante | `delay_s_P1` | 0,6 s | slice B.1 |
| constante | `snap_radius_m_P3` / asistido | 0,04 m / 0,10 m | slice B.3 |
| constante | `theta_solution_deg_P5` / `tol_deg` / `hold_s` | 40° / 3° (asistido 6°) / 0,8 s | slice B.5 |
| constante ▲ | `highlight_s_P1` | 3,0 s | este GDD, D9-32 |
| constante | `reveal_fade_s_P5` / `reveal_outline_s_P5` ▲ / `line_fallback_s_P5` / `line_grace_s` ▲ | 1,2 s / 0,8 s† / 14,0 s / 2,0 s† (suma nominal 16,0 s) | slice B.5; F8 |
| constante | `lock_max_s` | 2,0 s† (rango 1,0–2,0) | este GDD, regla 14 (ya en el registro; actualizar el rango y `referenced_by`) |
| constante | `latencia_feedback_ms` | 100† (umbral de verificación, no knob) | este GDD |
| constante | `idle_s_P3_N3` / `idle_s_P6_N1,N2` / `idle_move_px_P3` | 60 s / 10 s y 20 s / 40 px† | slice B.3, B.6; F3 |
| constante | `close_view_after_s` | 1,5 s† (nombre único; sustituye a `t_auto_salida_s` de 7) | este GDD, F4 |
| fórmula | `F1`–`F8` | retraso con rebote, condición mantenida, inactividad, cierre automático, orden de escritura, coste de fuerza bruta, objetivos de duración, duración de la secuencia diferida | este GDD |
| aviso | `EV_PUZZLE_SOLVED_P1`–`P6` (`{puzzle, rewards, choice}`), «compartimento completado» (n; emisor 9), «puzle activado», «resolución de puzle interrumpida», «pista aplicada», «puzle inactivo», «feedback de puzle», «línea pedida» | emisor: 9 | este GDD |
| dato | `assets/data/puzzles/puzzles.json` | definiciones de los seis puzles | este GDD, regla 4 |
| hecho | propiedad (`owner`) de `archivo_abierto`, `memo_leido`, `pos_*`, `caja_c1`–`c4`, `pendiente_revelacion`, `carta_variante`, `t4_decision` (enum `returned`/`assigned`, sin fijar; nuevo, D9-39 a D9-41) | `9` (propuesta; el GDD del 3 dice «11–16») | este GDD, regla 1 |
| dependencia | índice, fila 9 | `3, 4, 7 (blandas 6, 18, 20, 23)` | este GDD |
| interfaz | `PuzzleController` (clase abstracta) | `configure`, `on_open/on_close(motivo)`, `handle_pointer/handle_activation`, `cancel_gesture`, `evaluate`, `reset_attempt`, `play_resolution`, `restore_solved_presentation`, `apply_hint_effect`, `elements` | este GDD, regla 9 |
| interfaz | API del marco | `get_view_gate`, `list_puzzles`, `get_hints`, `request_hint` | este GDD, reglas 7 y 26 |
| interfaz | `Verdict` | `NONE`, `HOLDING`, `PARTIAL`, `REJECT`, `SOLVED` | este GDD, regla 9 |
| clave de ajustes | `reducir_movimiento` (booleano, consumida por 9 y 4) | ajuste de 6 | decisión D9-31 |
