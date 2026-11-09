# Marco de puzles

> **Status**: Designed (pendiente de design-review)
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Tensión sin castigo (sin fallos terminales, reinicio sin coste, nada bloquea la historia) · Autonomía como progresión (el jugador deduce la solución del contenido) · Información incompleta (los puzles entregan hechos, nunca intenciones)

## Summary

Es el esqueleto común de los seis puzles del slice: les da un mismo ciclo de vida (bloqueado, activo, resuelto), una misma manera de comprobar la solución, de reaccionar cuando el jugador se equivoca (sin castigo, sin contador, sin espera larga), de anunciar que se han resuelto y de dejar constancia en el estado del juego. Cada puzle aporta solo lo que es suyo (sus piezas y su regla); el marco aporta todo lo demás y garantiza que **ningún puzle puede dejar al jugador atascado**. Existe porque seis puzles distintos, escritos por separado, acabarían con seis formas de fallar, de guardarse y de pedir ayuda; y porque el pilar *Tensión sin castigo* se cumple o no en ese denominador común.

> **Quick reference** — Layer: `Feature` (categoría `Gameplay`) · Priority: `MVP` · Key deps: `3 Estado y bus de eventos`, `7 Interacción e inspección` (blandas: `6 Ajustes`, `18 Base de contenido`)

## Overview

El marco de puzles gestiona, para cada uno de los seis puzles del Anexo B del slice (`P1` Cronología, `P2` Memorando en el cristal, `P3` Encaje de la foto, `P4` Tablero de tareas, `P5` Espejo de la diferencia, `P6` Decisión), tres cosas: **qué es** (una definición en datos: dónde está, qué necesita, cómo se comprueba, qué ocurre al acertar, al equivocarse y al pedir ayuda), **en qué estado está** (`BLOQUEADO`, `ACTIVO` o `RESUELTO`, con el criterio de paso entre ellos) y **qué consecuencias deja** (hechos escritos en el estado del juego y el aviso `EV_PUZZLE_SOLVED_<ID>`).

Cada puzle se implementa como un *controlador* que cumple una interfaz común: recibe gestos de puntero (en las vistas cercanas) o activaciones de objeto (en el mundo), mantiene el estado de sus piezas, y responde a una única pregunta cuando el marco se la hace —«¿cómo está esto?»— con uno de cuatro veredictos: nada, progreso parcial, rechazo o resuelto. Lo que sigue (temporizar la comprobación, reproducir el rechazo, bloquear la entrada el tiempo justo, escribir hechos, avisar, restaurar tras cargar, enganchar pistas) lo hace el marco igual para todos.

Es un sistema invisible para el jugador, que solo percibe sus resultados: un panel que vibra y devuelve las referencias, una pieza que encaja con un chasquido, un compartimento que se abre. Existe por tres razones. (1) *Una sola política de fallo*: el slice declara que «ningún fallo en un puzle bloquea el avance» (§19.3) y esa garantía sólo se puede comprobar si hay un único lugar donde se aplica. (2) *Datos fuera del código*: soluciones, tolerancias, tiempos y pistas viven en un fichero editable por diseño y QA. (3) *Pistas*: el sistema 17 entrará después sin tocar los puzles, porque el marco ya expone qué pistas tiene cada uno y cómo aplicarlas.

## Player Fantasy

Vera no «resuelve acertijos»: **entiende lo que tiene delante**. El jugador debe sentir que cada puzle es una conversación con el mundo —ordenar los correos, mirar el memorando en el cristal, ver la foto a la que le falta alguien— y que equivocarse no es una derrota, sino una forma de probar. Estética principal (MDA): **Challenge** suave y **Discovery**; secundaria: **Narrative** (cada solución entrega un hecho). Necesidades SDT: **Competencia** (feedback legible en cada acción, correcta o no, y la solución se deduce del contenido), **Autonomía** (varios caminos de pensamiento y el orden libre de la caja). La tensión viene del ambiente y del tema, **nunca** de reloj, contador ni consecuencia.

*Curva de dificultad (sierra, flow):* P1 (recoger información y ordenarla) → P2 (deducción espacial en el mundo) → P3 (manipulación sencilla) → P4 (razonar sobre un texto) → P5 (observar y comparar) → P6 (sin dificultad, solo peso emocional). Cada tramo sube la exigencia mental un poco y la baja con un puzle más físico o contemplativo; el último puzle no tiene respuesta incorrecta por diseño.

## Detailed Design

### Core Rules

‡ = propuesta que debe confirmar el GDD del sistema afectado (aún sin redactar). † = valor propuesto, a validar en playtest. Las **claves de datos y los nombres de la interfaz van en inglés** (identificadores de código); los IDs del slice (`P1`, `B01`, `I-01`, `caja_c1`, `SFX_REJECT`, `EV_PUZZLE_SOLVED_P1`…) se conservan tal cual. Identificadores de puzle adoptados: **`P1` a `P6`** (confirma lo propuesto en la regla 10 del GDD del 3).

**Reparto de responsabilidades**

1. **Qué posee el marco.** El ciclo de vida de cada puzle, la planificación de la comprobación, la política de fallo y de bloqueo de entrada, la escritura de los hechos de puzle en el estado (3), el aviso `EV_PUZZLE_SOLVED_<ID>`, la restauración tras cargar, las dependencias entre puzles y el enganche de pistas. Es el **único escritor** de los hechos `archivo_abierto`, `memo_leido`, `pos_L`, `pos_C`, `pos_R`, `caja_c1` a `caja_c4`, `pendiente_revelacion` y `carta_variante` (el GDD del 3 los asigna a «11 a 16», que actúan a través del marco; el campo `owner` de `flags.json` debe ser `9` ‡).
2. **Qué no posee.** Las piezas y reglas de cada puzle (sistemas 11 a 16), las puertas y lectores (8), la animación y el hardware de la caja (10), el ordenador y la impresora (19), los documentos y el bolsillo (20), el reparto de pistas (17) y los gestos (7 y 1). El marco **no** conoce la solución de ningún puzle: la lee de los datos y se la pasa al controlador.
3. **Un puzle = datos + controlador.** Cada puzle tiene una entrada en `assets/data/puzzles/puzzles.json` (reglas 4 y 5) y una clase `PuzzleController` que implementa la interfaz de la regla 9. Añadir un séptimo puzle de un tipo conocido es añadir datos; de un tipo nuevo, escribir un controlador.

**Datos**

4. **Esquema de una definición.** Cada puzle declara:
   - `id` (`P1`…`P6`) y `solved_flag` (el hecho que lo marca como resuelto: `archivo_abierto`, `memo_leido`, `caja_c1`…).
   - `mode`: `VIEW` (se resuelve en una vista cercana con cursor) o `WORLD` (se resuelve activando objetos desde la exploración).
   - `view` o `elements`: el ID de la vista (`C05`, `D01a`…) o los IDs de los objetos (`B01`, `B02`, `B03`).
   - `requires`: hechos que deben ser verdaderos para pasar de `BLOQUEADO` a `ACTIVO` (lista `all`; vacía = activo desde el inicio) y, opcionalmente, ítems necesarios (`items`).
   - `validation`: política de comprobación (regla 12) y sus tiempos.
   - `solution`: datos de la solución (permutación, ángulo y tolerancia, mapa pieza-hueco…); solo el controlador los interpreta.
   - `on_reject`: sonido, animación, duración y alcance del bloqueo (regla 14).
   - `on_solved`: hechos a escribir en orden, sonido, duración, recompensas (ítems), si se cierra la vista y cuándo.
   - `resolution`: `IMMEDIATE` o `DEFERRED` con sus pasos (regla 17).
   - `persist`: hechos que reflejan estado intermedio (`pos_L/C/R`, `pendiente_revelacion`).
   - `hints`: lista de pistas (regla 25).
   - `assist`: ajuste de accesibilidad que cambia un parámetro (`asistencia_encaje`, `asistencia_rotacion`) y su valor asistido.
5. **Ejemplo (P1, ilustrativo).**
```json
{
  "id": "P1", "mode": "VIEW", "view": "C05",
  "solved_flag": "archivo_abierto",
  "requires": { "all": [], "items": ["I-01"] },
  "validation": { "policy": "DELAYED_AFTER_CHANGE", "delay_s": 0.6 },
  "solution": { "sequence": [2, 1, 3, 4] },
  "on_reject": { "sfx": "SFX_REJECT", "shake_s": 1.2, "reset_after_s": 1.5, "lock": "PUZZLE" },
  "on_solved": { "write": [{ "flag": "archivo_abierto", "value": true }],
                 "sfx": "SFX_UNLOCK", "sfx_s": 1.4, "close_view_after_s": 1.5 },
  "resolution": { "kind": "IMMEDIATE" },
  "hints": [ { "level": 1, "trigger": "REQUEST", "effects": [ { "type": "CAMERA_NUDGE", "target": "I-01", "duration_s": 3.0 } ] } ]
}
```
   Todo valor numérico de los Anexos B vive aquí, nunca en el controlador. El marco valida el fichero al arrancar (regla 29).

**Estados y modos**

6. **Tres estados públicos** (los del slice, Anexo B): `BLOQUEADO`, `ACTIVO`, `RESUELTO`. Pasos permitidos: `BLOQUEADO → ACTIVO` (cuando `requires` se cumple) y `ACTIVO → RESUELTO`. **Nunca hacia atrás** (regla 28). Dentro de `ACTIVO` hay cuatro fases internas (`IDLE`, `EVALUATING`, `FEEDBACK`, `RESOLVING`) que no se publican como estado (States and Transitions).
7. **Compromiso (engage).** En un puzle `VIEW`, el jugador está *comprometido* mientras su vista cercana está abierta (avisos «vista cercana abierta/cerrada» de 7). En un `WORLD` no hay compromiso: las activaciones de los objetos llegan mientras el puzle está `ACTIVO`. Un puzle `BLOQUEADO` no admite compromiso: al abrir su vista, el marco responde con el sonido y texto de `locked_feedback` (por defecto `SFX_CLICK_SUBTLE`, sin texto) y pide cerrarla; el jugador nunca queda dentro de una vista muerta.
8. **Configuración al cargar** (secuencia del GDD del 4, regla 9.6: síncrona y leyendo hechos). Para cada puzle: si `solved_flag` es verdadero, queda `RESUELTO` y el controlador restaura su presentación final **al instante y sin avisos ni sonidos** (`restore_solved_presentation()`); si no, `ACTIVO` si `requires` se cumple y `BLOQUEADO` si no; después restaura sus `persist` (por ejemplo las posiciones de las lámparas). El estado en memoria de piezas no persistidas (referencias colocadas del P1, fichas del P4) **empieza siempre vacío** tras cargar (regla 22). Los avisos no se repiten: lo que ya ocurrió se reconstruye de los hechos (GDD del 3, regla 8).

**Interfaz común del controlador**

9. **`PuzzleController`** (la implementa cada puzle; el marco la invoca):
   - `configure(def, flags)`: lee su definición y sus hechos; no escribe nada.
   - `on_engage()` / `on_disengage(reason)`: el jugador entra o sale de la vista (`VIEW`).
   - `handle_pointer(ev)`: recibe un `PointerEvent` de 7 (gestos `CLICK`, `ARRASTRAR`, `ROTAR`, `PULSAR`; Anexo B) y actualiza sus piezas. Para `WORLD`, `handle_activation(element_id, verb)`.
   - `evaluate() -> Verdict`: **función pura** de su estado y su definición: `NONE` (nada que decir), `PARTIAL` (progreso, p. ej. una pieza encajada), `REJECT` (intento incorrecto) o `SOLVED`. Puede devolver también el elemento afectado.
   - `reset_attempt(scope, element)`: devuelve el intento fallido a un estado válido y reintentable (p. ej. la pieza a la bandeja).
   - `play_resolution(step)`: reproduce la presentación del acierto (solo `DEFERRED` tiene más de un paso).
   - `restore_solved_presentation()`: ver regla 8.
   - `apply_hint_effect(effect)`: aplica un efecto de pista propio del puzle (regla 25).
   - `debug_is_solvable() -> bool` (solo desarrollo): ¿se puede llegar a `SOLVED` desde el estado actual? (regla 30).
   El marco proporciona la clase base con todo lo demás (estado, planificación, bloqueo, escritura de hechos, avisos, idle).
10. **Veredicto, no acción.** El controlador *nunca* escribe hechos, emite avisos ni cambia el estado público: solo devuelve el veredicto. Es el marco quien decide qué ocurre con él (reglas 13 a 17). Esto es lo que permite comprobar la política de fallo una sola vez.

**Entrada y puntero**

11. **Gestos entregados.** En `VIEW`, el marco recibe los `PointerEvent` de 7 (regla 20 de 7) y los reenvía al controlador del puzle comprometido, salvo que el puzle esté bloqueado por el alcance de un rechazo (regla 14). La conversión de tolerancias de metros o grados a píxeles la hace 7 (F6). Los cuatro gestos del slice se corresponden así: `CLICK` = `seleccionar`; `PULSAR` corto = `seleccionar`; `PULSAR` largo = `mantener`; `ARRASTRAR` = `agarrar`; `ROTAR` = `rotar` (1 px ≈ 0,25°, Entrada).

**Comprobación (validación)**

12. **Cinco políticas de comprobación.** Cada puzle declara una; el marco decide cuándo llamar a `evaluate()`:
    - `DELAYED_AFTER_CHANGE` (P1): cuando todos los huecos requeridos están llenos, `delay_s` después del último cambio. Cualquier cambio dentro del retraso cancela y reinicia la cuenta (F1).
    - `ON_CHANGE` (P2): tras cada cambio de estado, sin retraso.
    - `PER_ELEMENT` (P3, P4): cuando un elemento termina su gesto (pieza soltada, ficha con sus dos selectores completos o «Devolver»); el puzle se resuelve cuando todos los elementos requeridos están correctos.
    - `SUSTAINED` (P5): cada fotograma mientras se cumple la condición; el veredicto es `SOLVED` cuando la condición se mantiene `hold_s` seguidos (F2).
    - `ON_CHOICE` (P6): al aceptar la elección; `SOLVED` inmediato con la opción como carga útil.
13. **Veredictos.**
    - `NONE`: no hace nada.
    - `PARTIAL`: el marco emite el feedback parcial de la definición (`on_partial`, p. ej. `SFX_SNAP` del P3, `SFX_STAMP` del P4, `SFX_GLASS_HUM` en P2) y el puzle sigue en `IDLE`.
    - `REJECT`: regla 14.
    - `SOLVED`: reglas 16 y 17.
    Toda acción procesada genera una respuesta audible o visible en ≤ `latencia_feedback_ms` (slice §16: «feedback visual y sonoro en cada acción, correcta o no»); si no hay veredicto, responde el objeto (7, regla 11 de 7).

**Fallo sin castigo**

14. **Política única de fallo.** Un `REJECT` hace, siempre y solo, lo siguiente: (a) el marco emite el feedback de rechazo (`sfx`, animación, p. ej. `SFX_REJECT`); (b) el controlador ejecuta `reset_attempt(scope, element)` tras `reset_after_s`; (c) la entrada se bloquea según `lock`: `PUZZLE` (todo el puzle, P1: 1,5 s), `ELEMENT` (solo ese elemento, P3: 0,4 s) o `NONE` (P4: la ficha vuelve a neutra al instante y puede reeditarse); (d) las demás piezas **no se tocan** (las fichas correctas del P4 no se reinician). No hay: contador de fallos, límite de intentos, enfriamiento acumulativo, pérdida de piezas, cambio de dificultad, aviso al jugador del número de fallos ni consecuencia en la historia. El bloqueo máximo es `lock_max_s` (2,0 s†): ningún `reset_after_s` de los datos puede superarlo (validación de la regla 29). Los eventos de entrada durante un bloqueo se **descartan**, no se encolan.
15. **Fallos que no existen.** Los puzles `ON_CHANGE` y `ON_CHOICE` pueden no tener veredicto `REJECT` (P2 y P6: «el fallo no existe», B.2 y B.6). El marco los trata igual: si el controlador devuelve `NONE`/`PARTIAL`, no hay feedback de rechazo.

**Resolución**

16. **Orden de escritura al resolver** (`SOLVED`), todo en el mismo fotograma y antes de cualquier presentación larga:
    1. Los hechos de `on_solved.write` en el orden declarado (p. ej. `carta_variante` **antes** de `caja_c4`, para que quien reaccione a `caja_completa` ya lea la variante).
    2. El hecho `solved_flag` (si no estaba ya en la lista).
    3. El estado público pasa a `RESUELTO` (idempotente: si ya lo está no se repite nada).
    4. El aviso `EV_PUZZLE_SOLVED_<ID>`, con `{puzzle, rewards, choice}` (`choice` solo en P6).
    5. El feedback de acierto (`on_solved.sfx`) y la presentación del controlador.
    6. Si la definición lo pide, el marco ordena a 7 cerrar la vista con motivo `resuelto` tras `close_view_after_s`.
    El hecho `caja_completa` lo recalcula el estado (3, regla 7); el marco no lo escribe. Las recompensas (`rewards`: `I-05`, `I-06a`, `I-07`) viajan en el aviso; el sistema 20 las deriva de los hechos (los ítems no son hechos propios, D.1 del slice).
17. **Resolución inmediata y diferida.** `IMMEDIATE`: la regla 16 se aplica al recibir `SOLVED`. `DEFERRED` (solo P5): el veredicto `SOLVED` inicia la fase `RESOLVING` con una secuencia de pasos declarada en los datos; los hechos y el estado público sólo cambian **al terminar el último paso**. Durante `RESOLVING`: la entrada del puzle queda bloqueada salvo `atrás`; el tiempo es de juego (la pausa lo detiene); y si se interrumpe (reglas 18 y 19) no se escribe nada de la regla 16.
18. **Interrupción de una resolución diferida.** `RESOLVING` se interrumpe si se cierra la vista (por `atrás`, cierre forzado o descarga), si se pierde la línea de audio por una causa externa o si el jugador se aleja. La interrupción detiene la secuencia, emite «resolución de puzle interrumpida» (el audio 23 corta la línea con fundido) y deja el puzle en `ACTIVO`/`IDLE` con el hecho de reanudación ya escrito (regla 19). **Nada se pierde ni se penaliza.**
19. **Reanudación.** En `DEFERRED` el marco escribe, **al iniciar** la secuencia, el hecho de reanudación declarado (`persist`: `pendiente_revelacion` = verdadero para P5) y lo vuelve a falso al terminarla (en el orden de la regla 16). Así cualquier interrupción —incluido cerrar el juego, que no guarda en ese momento— deja el estado correcto sin lógica extra. Al volver a comprometerse con un puzle con ese hecho verdadero, el marco **salta la comprobación** (la alineación ya se hizo) y reproduce la secuencia **desde el principio** (el jugador debe oír entera la grabación). Si el juego se cerró durante la secuencia, el último guardado puede ser anterior a la escritura del hecho: entonces el jugador repite la alineación, lo cual es inocuo; el sistema de guardado (5) debe guardar también cuando `pendiente_revelacion` pasa a verdadero (slice D.3) ‡.
20. **Líneas de audio dentro de la secuencia.** Un paso puede pedir una línea (`VO_G_07`): el marco emite «línea pedida» y espera «línea terminada» del audio (23) ‡. Si no llega en `line_timeout_s` (30 s†, bien por encima de los ~14 s de la línea), la secuencia **continúa** y se registra el aviso: una línea sin audio o un fallo de audio nunca atascan el puzle (base de contenido, regla 17: «sin audio» muestra solo el subtítulo).

**Reinicio y persistencia**

21. **Tres reinicios, ninguno con coste.** (a) *Del intento*: tras un `REJECT` (regla 14). (b) *Al salir*: por defecto **no** se pierde nada al cerrar la vista (`on_disengage`: `KEEP`): el puzle conserva sus piezas mientras dure la sesión de la escena; solo se descartan fases transitorias —el feedback en curso se completa al instante, una comprobación retrasada se cancela y se rearma al volver— (F1). (c) *Al cargar la escena*: el estado en memoria vuelve a su inicio (regla 8). No existe botón de «reiniciar» en el slice; la operación `reset_attempt` se reserva para el sistema 17 y para QA.
22. **Qué se guarda.** Sólo hechos del catálogo del 3: `solved_flag` de cada puzle, y los `persist` del P2 (`pos_L`, `pos_C`, `pos_R`, escritos en **cada** cambio) y del P5 (`pendiente_revelacion`). El progreso parcial no persistido se pierde al cerrar el juego, y eso es deliberado: el autoguardado del slice ocurre al completar cada compartimento (D.3), y rehacer un puzle parcial no cuesta nada. El marco **no añade hechos nuevos** al catálogo.
23. **Resolución sincronizada con el guardado.** El guardado (5) se dispara al cambiar los hechos `caja_c*` y `archivo_abierto` y espera a que la cola de avisos esté vacía (GDD del 3, edge case), así que la instantánea nunca contiene un `caja_c4` sin su `caja_completa` ni un `caja_c3` sin su evento.

**Dependencias entre puzles**

24. **Cálculo.** El marco escucha el cambio de cada hecho de `requires` y, cuando todos son verdaderos, pasa el puzle de `BLOQUEADO` a `ACTIVO`: emite «puzle activado» (con ID) y el feedback de desbloqueo (`on_unlock`: `SFX_UNLOCK_SOFT` y el compartimento entreabierto 2 cm, que anima Caja 10). Al cargar con el requisito ya cumplido, pasa a `ACTIVO` en silencio (regla 8). El grafo de dependencias del slice es: `P5` requiere `caja_c1`; `P6` requiere `caja_c1`, `caja_c2` y `caja_c3`; el resto no requiere nada (D-16 del slice, pendiente de confirmar). El orden entre P3 y P4 es libre (autonomía).

**Pistas (enganche del sistema 17)**

25. **Datos de pista.** Cada puzle declara `hints`: por nivel, `trigger` (`REQUEST` si lo pide el jugador, `IDLE` si aparece tras `idle_s` segundos sin actuar), `availability` (`ALWAYS`, el elemento existe sin pedirlo; `ON_HINT`, se activa al alcanzar ese nivel) y una lista de `effects`: `TEXT` (clave `PISTA_P<n>_N<k>` o una clave de interfaz de la base de contenido), `HIGHLIGHT` (IDs de elementos y duración), `CAMERA_NUDGE` (objetivo y duración, p. ej. 3 s en P1), `AFFORDANCE` (habilita un comportamiento: el halo por proximidad de P2, el número de fila de P3, el resaltado al pasar el cursor de P4) o `AUTO_SOLVE_ELEMENT` (P4: la ficha T1 se resuelve y muestra su explicación).
26. **API para el sistema 17.** El marco ofrece: `list_puzzles()` (estado de cada puzle y último compromiso), `get_hints(id)` (los datos de la regla 25), `request_hint(id, level)` (valida que el puzle esté `ACTIVO`, aplica los efectos y emite «pista aplicada» con ID y nivel) y las notificaciones «puzle inactivo» (cuando el tiempo sin actuar cruza el `idle_s` de un nivel; F3). El nivel alcanzado (`hint_level_reached`) se guarda **solo en memoria**, es monótono dentro de la sesión y no se persiste (D.2 no tiene hecho para ello). Mientras el sistema 17 no exista, `idle_hints_auto_apply` (verdadero†) aplica por sí mismo las pistas `IDLE` del slice (P3 nivel 3, P6 niveles 1 y 2); el 17 podrá desactivarlo y asumir ese reparto. **El marco no decide cuándo se ofrece una pista ni cuántas: eso es del 17.** Las pistas se piden desde el menú de pausa (25) o con el gesto de cámara (slice §10); el marco sólo las aplica.
27. **Consistencia del contenido.** Todo puzle debe declarar tres pistas (`P6`: dos, ver Open Questions) y cada texto de pista debe existir en la base de contenido (18); un puzle sin pistas completas hace fallar la validación (regla 29). El slice exige que cada puzle se resuelva con información que está en el juego (§19.2): las pistas son *énfasis* de esa información, nunca información nueva.

**Garantías contra el atasco (anti-softlock)**

28. **Invariantes que el marco hace cumplir.**
    - **S1 · Sin estado terminal de fallo:** no existe `FALLIDO`; un puzle `ACTIVO` sólo puede ir a `RESUELTO`.
    - **S2 · Monotonía:** `RESUELTO` no vuelve a `ACTIVO` ni `ACTIVO` a `BLOQUEADO`, salvo la consola de desarrollo (regla 31).
    - **S3 · Sin reloj:** ninguna regla de puzle depende de tiempo real. Los retrasos del marco (comprobación, bloqueo) son de ≤ `lock_max_s` y de tiempo de juego; no hay temporizadores de solución («este puzle no tiene reglas de tiempo», P4).
    - **S4 · Salida siempre posible:** `atrás` cierra cualquier vista, con las excepciones de la regla 23 de 7 (transición de ≤ 3 s).
    - **S5 · Dependencias alcanzables:** todo hecho de `requires` lo escribe otro puzle del mismo fichero, sin ciclos (regla 29).
    - **S6 · Material recuperable:** si un puzle requiere un ítem (P1: `I-01`), la falta no bloquea la historia: el jugador puede ir a conseguirlo (`V08` tras `correos_leidos`), y la vista muestra el panel con los huecos vacíos y el texto `locked_feedback`.
    - **S7 · Resolubilidad:** desde cualquier estado alcanzable el controlador puede llegar a `SOLVED` (regla 30).
    - **S8 · Reanudación:** toda resolución diferida es interrumpible y reanudable (reglas 18 y 19).
    - **S9 · Un solo acierto:** `SOLVED` sólo transiciona una vez (idempotente); un segundo `SOLVED` en el mismo fotograma se descarta.
29. **Validación de los datos al arrancar** (error visible en desarrollo; en la build final, el puzle afectado queda inactivo y se registra, y los demás siguen): `id` y `solved_flag` únicos y declarados en `flags.json`; `requires` sin ciclos y con escritor; cada tiempo de `on_reject` ≤ `lock_max_s`; tres pistas (dos en P6) con claves existentes; el estado inicial **no** satisface su propia solución (p. ej. `pos_*` iniciales 2,2,2 frente a 3,1,4; θ inicial 0° frente a 40°); `view`/`elements` existen en el catálogo de 7; y, para vistas, los elementos cumplen `pick_min_px` (regla 22 de 7).
30. **Prueba de resolubilidad (desarrollo).** Una prueba automática ejecuta, por puzle, `N_fuzz` (1.000†) secuencias aleatorias de acciones válidas y comprueba tras cada acción que `debug_is_solvable()` es verdadero y que no se escribió ningún hecho inválido. Es el test que sostiene S7.
31. **Consola de desarrollo.** Si el estado (3) fuerza un `solved_flag` o un `requires` en una build de desarrollo, el marco reconcilia el puzle con los hechos (a `RESUELTO` en silencio, a `ACTIVO`/`BLOQUEADO` con el estado en memoria reiniciado) sin emitir `EV_PUZZLE_SOLVED_*`. Los hechos mandan.

**Instrumentación de playtest**

32. **Registro local (solo builds de desarrollo y de playtest).** Por puzle: tiempo hasta resolver, número de intentos y rechazos, pistas pedidas y aplicadas y cierres de vista. Sirve para el criterio 5 del slice (§19) y para calibrar los tiempos de Formulas. **Nunca** se muestra al jugador ni afecta a ninguna regla (pilar *Tensión sin castigo*). No existe en la build de la demo.

### States and Transitions

| Estado público | Fase interna | Qué ocurre | Sale hacia |
|---|---|---|---|
| `BLOQUEADO` | — | No admite compromiso (regla 7). Escucha los hechos de `requires`. | `ACTIVO` (requisitos cumplidos) |
| `ACTIVO` | `IDLE` | Espera acciones del jugador; cuenta inactividad si hay compromiso (F3). | `EVALUATING` · `FEEDBACK` · `RESOLVING` · `RESUELTO` |
| `ACTIVO` | `EVALUATING` | Cuenta atrás de una comprobación `DELAYED_AFTER_CHANGE` o acumulador `SUSTAINED` en marcha. | `IDLE` (cambio o salida) · `FEEDBACK` (`REJECT`) · `RESOLVING`/`RESUELTO` (`SOLVED`) |
| `ACTIVO` | `FEEDBACK` | Reproduce el rechazo y bloquea la entrada según el alcance (regla 14). Dura ≤ `lock_max_s`. | `IDLE` |
| `ACTIVO` | `RESOLVING` | Secuencia diferida (P5). Sólo `atrás`. | `RESUELTO` (fin) · `IDLE` (interrupción; hecho de reanudación ya escrito) |
| `RESUELTO` | — | Inerte salvo ecos sin efecto (`SFX_CLICK_SUBTLE`). Su presentación final permanece. | — (terminal, salvo consola) |

Un puzle `RESUELTO` rechaza todo gesto con `SFX_CLICK_SUBTLE` (sin alterar sus piezas). En el P2 esto significa que las lámparas dejan de girar una vez resuelto el memorando, que queda legible de forma permanente (Decisiones).

### Matriz de encaje: los seis puzles frente al marco

| | P1 Cronología | P2 Memorando | P3 Foto | P4 Tablero | P5 Espejo | P6 Decisión |
|---|---|---|---|---|---|---|
| `mode` · lugar | `VIEW` · `C05` | **`WORLD`** · `B01`–`B03` | `VIEW` · `D01a` | `VIEW` · `D01b` | `VIEW` · `D01c` | `VIEW` · `D01d` |
| Estado inicial | `ACTIVO` (+ ítem `I-01`) | `ACTIVO` | `ACTIVO` | `ACTIVO` | `BLOQUEADO` (`caja_c1`) | `BLOQUEADO` (`caja_c1`∧`c2`∧`c3`) |
| Política | `DELAYED_AFTER_CHANGE` 0,6 s | `ON_CHANGE` | `PER_ELEMENT` | `PER_ELEMENT` | `SUSTAINED` 0,8 s | `ON_CHOICE` |
| `REJECT` | Sí: 1,2 s de vibración, 1,5 s de reset, `lock` `PUZZLE` | **No existe** | Sí: vuelve a bandeja 0,4 s, `lock` `ELEMENT` | Sí: ficha a neutra + «No corresponde» 1,5 s, `lock` `NONE` | **No existe** | **No existe** |
| `PARTIAL` | — | Fragmento iluminado (`SFX_GLASS_HUM`) | Pieza encajada (`SFX_SNAP`) | Ficha sellada (`SFX_STAMP`) | — | — |
| Resolución | `IMMEDIATE` (`SFX_UNLOCK` 1,4 s) | `IMMEDIATE` (`SFX_GLASS_HUM` 2,0 s) | `IMMEDIATE` (marco 1,0 s) | `IMMEDIATE` | **`DEFERRED`** (~16 s) | `IMMEDIATE` + abre la carta |
| Hechos al resolver | `archivo_abierto` | `memo_leido` | `caja_c1` | `caja_c2` | `pendiente_revelacion`↔`caja_c3` | `carta_variante` → `caja_c4` |
| `persist` | — | `pos_L/C/R` | — | — | `pendiente_revelacion` | — |
| `assist` | — | — | `asistencia_encaje` (0,10 m) | — | `asistencia_rotacion` (±6°) | — |
| Pistas | 3 | 3 | 3 (nivel 3 `IDLE` 60 s) | 3 | 3 | **2** (`IDLE` 10 s y 20 s) |
| Encaja sin excepciones | Sí | No | Sí | Sí | No | No |

**Puzles que fuerzan excepciones al protocolo común** (cada una tiene un punto de extensión previsto, no un caso especial en el código):
- **P2 · modo `WORLD`**: se resuelve desde la exploración, sin vista ni cursor, y sin compromiso. Extensión: `mode: WORLD` y `handle_activation`; el idle y los gestos de puntero no aplican; persiste su estado intermedio (`pos_*`). **Discrepancia del slice:** §10.2 dice «si falla, las lámparas parpadean»; el Anexo B.2 dice «fallo: no existe». Se sigue B.2 (más específico).
- **P5 · resolución diferida e interrumpible**: la resolución dura ~16 s, depende de una línea de audio y puede interrumpirse sin perder nada. Extensión: `resolution.kind: DEFERRED`, reglas 17 a 20, hecho de reanudación. **Discrepancia del slice:** §10.5 dice «si falla, el marco vuelve a su posición inicial»; B.5 dice «no hay fallo». Se sigue B.5.
- **P6 · elección única, sin fallo, con carga útil y dos pistas**: no hay respuesta incorrecta, la elección es definitiva (D-14, pendiente de confirmar) y fija un enumerado. Extensión: `ON_CHOICE`, `choice` en el aviso, y excepción de «tres niveles de pista» (B.6 declara dos; §10 dice tres: ver Open Questions).
- **P1 · ítem requerido**: `ACTIVO` desde el inicio pero sin material. Extensión: `requires.items` y `locked_feedback`; no es una excepción de lógica.
- **P3 y P4**: encajan sin excepciones (P3 con un hueco que *debe* quedar vacío, expresado como «elementos requeridos = 5 de 6»).

### Interactions with Other Systems

| Sistema | Qué recibe del marco | Qué entrega al marco |
|---|---|---|
| 3 Estado y bus | Escritura de `archivo_abierto`, `memo_leido`, `pos_*`, `caja_c1`–`c4`, `pendiente_revelacion`, `carta_variante`; avisos `EV_PUZZLE_SOLVED_P1`–`P6`, «puzle activado», «resolución de puzle interrumpida», «pista aplicada», «puzle inactivo», «feedback de puzle» | Lectura de hechos al configurar; avisos de cambio de los `requires` |
| 7 Interacción e inspección | Peticiones de abrir y cerrar vistas; cierre con motivo `resuelto` | `PointerEvent`, activaciones `WORLD`, avisos «vista cercana abierta/cerrada» |
| 10 Caja y compartimentos ‡ | «Puzle activado» y `EV_PUZZLE_SOLVED_*` para animar el hardware (`BOX_C*_OPEN`, 2 cm entreabierto, cierre) | `D01a`–`D01d` como vistas; las animaciones de apertura |
| 11–16 Puzles | Datos de su definición, gestos, tolerancia asistida | Veredictos, presentación |
| 17 Sistema de pistas ‡ | `list_puzzles`, `get_hints`, `request_hint`, avisos de inactividad | Cuándo y cuánto ofrecer |
| 6 Ajustes | — | `asistencia_encaje` y `asistencia_rotacion` (lectura al configurar y al cambiar) |
| 8 Control de acceso | Hecho `archivo_abierto` (lo lee 8, no el marco) | — |
| 20 Documentos y bolsillo | `rewards` en el aviso; petición `abrir_lectura` de la carta (P6) | Ítems para `requires.items` |
| 21 Director de escenas | `caja_completa` (derivado del 3) vía el estado | — |
| 23 Director de audio ‡ | «feedback de puzle», «línea pedida» | «línea terminada» |
| 28 Atmósfera · 29 Shaders | Avisos de resolución, estado de P2 y P5 | — |
| 5 Guardado y carga | Hechos de puzle y `pendiente_revelacion` en la instantánea | Guardar al cambiar los `caja_c*` y `pendiente_revelacion` ‡ |
| 18 Base de contenido | — | Claves de pistas y textos de rechazo |

## Formulas

### F1 · Comprobación retrasada con rebote

`t_comprobar = t_ultimo_cambio + delay_s;   se evalúa si, en t_comprobar, ningún cambio ocurrió en (t_ultimo_cambio, t_comprobar] y todos los huecos requeridos están llenos;   si el jugador sale de la vista, se cancela y se rearma al volver`

**Variables:** `delay_s` 0,6 s† (0,3–1,5; Anexo B.1); tiempos en tiempo de juego (la pausa los detiene).
**Output Range:** evalúa una o cero veces por secuencia de cambios.
**Example:** el jugador completa H1 a H4 en t = 10,00 s; en t = 10,40 mueve la referencia de H3 → nuevo `t_comprobar` = 11,00 s. Si no toca más, a los 11,00 s se evalúa. Si sale de la vista en 10,70 s, se cancela; al volver con los cuatro huecos llenos se rearma otros 0,6 s.

### F2 · Condición mantenida

`acum' = acum + min(dt, dt_max)  si  |θ − θ*| ≤ tol,  si no  0;   SOLVED cuando  acum ≥ hold_s`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| θ | float (°) | 0–90 | calculated | Ángulo actual del marco interior |
| θ* | float (°) | — | data, 40 | Ángulo de la solución |
| tol | float (°) | 2–10 | data, 3 (normal) / 6 (asistido) | Tolerancia; se elige con `asistencia_rotacion` |
| hold_s | float (s) | 0,4–1,5 | data, 0,8† | Tiempo seguido dentro de la tolerancia |
| dt_max | float (s) | 0,05–0,2 | data, 0,1† | Tope por fotograma, para que un tirón no complete la cuenta |

**Output Range:** `acum` ≥ 0; `SOLVED` o nada.
**Example:** con tol 3, θ = 38° (|Δ| = 2) y 60 fps, tras 48 fotogramas `acum` = 0,80 s → `SOLVED`. Si a los 0,5 s θ pasa a 43,5° (|Δ| = 3,5 > 3), `acum` = 0 y se necesita otro 0,8 s completo; con asistencia (tol 6), 43,5° seguiría dentro. Con un tirón de dt = 0,5 s, se acumulan solo 0,1 s.

### F3 · Inactividad

`idle = t_ahora − t_ultima_accion`  (sólo con compromiso; reinicia a 0 con cualquier `PointerEvent`, cambio de estado de un elemento o aplicación de pista)

**Variables:** `t_ultima_accion` en tiempo de juego; los umbrales `idle_s` por nivel de pista: P3 nivel 3 = 60 s† (30–120), P6 niveles 1 y 2 = 10 s† y 20 s† (5–60).
**Output Range:** ≥ 0 s; cada umbral se notifica **una vez** por compromiso.
**Example:** P6: con la vista abierta, a los 10 s sin pulsar aparece «Solo puedes elegir una vez»; a los 20 s, «La carta no cambia; cambia la primera frase». Si el jugador mueve el cursor a los 15 s, `idle` = 0 pero el nivel 1 ya se mostró y no se repite.

### F4 · Cierre automático tras resolver

`t_cierre = t_resuelto + close_view_after_s;   si close_view_after_s es nulo: no hay cierre`

**Variables:** `close_view_after_s` 1,5 s† (0,5–3,0) en P1, P3, P4 y P5; nulo en P6 (el jugador cierra tras leer la carta).
**Output Range:** instante de petición de cierre a 7 con motivo `resuelto`.
**Example:** P1 se resuelve en t = 20,0 s: `SFX_UNLOCK` (1,4 s) y la puerta A empieza a abrirse; a 21,5 s la vista se cierra y el jugador ve la puerta abierta.

### F5 · Orden de los hechos al resolver (P6)

`escribir carta_variante = x  →  caja_c4 = verdadero  →  (el estado recalcula caja_completa)  →  aviso EV_PUZZLE_SOLVED_P6`

**Variables:** `x` ∈ {A, B, C}.
**Output Range:** tres cambios de hecho y un aviso, todo en el mismo fotograma.
**Example:** el jugador pulsa «Estoy bien» (A): `carta_variante` = A, `caja_c4` = verdadero, `caja_completa` = verdadero si `caja_c1`–`c3` ya lo eran; quien escuche `caja_completa` ya ve `carta_variante` = A.

### F6 · Coste de la fuerza bruta (comprobación del diseño)

`T_peor = (N − 1) · (delay_s + reset_after_s + t_gestos)`

**Variables:** `N` combinaciones posibles; `t_gestos` tiempo de colocar la combinación (clics del jugador).
**Output Range:** segundos.
**Example:** P1 tiene N = 4! = 24; con 0,6 + 1,5 + 1,5 (cuatro clics a ~0,4 s) = 3,6 s por intento, `T_peor` = 23 · 3,6 = 83 s (media ≈ 43 s). P4 tiene 9 combinaciones por ficha (3 × 3) más «Devolver»; `T_peor` por ficha ≈ 9 intentos. Se acepta: ver Edge Cases (degenerate strategies).

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

## Edge Cases

**Estado y ciclo de vida**
- **If se abre la vista de un puzle `BLOQUEADO`** (p. ej. `D01c` antes de `caja_c1`): el marco ejecuta `locked_feedback` y pide a 7 cerrarla (regla 7). No hay mensaje de error ni consecuencia.
- **If `requires` se cumple mientras el jugador está en otra sala**: el puzle pasa a `ACTIVO` y se emite «puzle activado»; Caja (10) anima el compartimento cuando el jugador lo vea (o lo deja ya entreabierto al cargar).
- **If el jugador carga una partida con `caja_c1` verdadero**: P3 se restaura `RESUELTO` (marco completo y compartimento cerrado, sin avisos) y P5 queda `ACTIVO` en silencio (regla 8).
- **If se guarda con `pendiente_revelacion` verdadero y se reanuda**: P5 queda `ACTIVO` con la reanudación pendiente; al comprometerse, salta la alineación y reproduce la secuencia entera (regla 19). Si no estaba guardado, el jugador repite la alineación (inocuo).
- **If `SOLVED` llega dos veces en el mismo fotograma** (clic y mando): el segundo se descarta (S9, regla 28).
- **If se pide `request_hint` sobre un puzle `BLOQUEADO` o `RESUELTO`**: se rechaza y se registra; el 17 no debe ofrecerlo, pero el marco no depende de ello.
- **If se fuerza un hecho con la consola**: regla 31; los hechos mandan.

**Comprobación y fallo**
- **If el jugador cambia una referencia durante el retraso de 0,6 s** (P1): se reinicia la cuenta (F1).
- **If el jugador sale de la vista durante `EVALUATING` o `FEEDBACK`**: la comprobación se cancela; el rechazo en curso se completa al instante (las referencias vuelven al papel, la pieza a la bandeja) y al volver el estado es válido y reintentable (regla 21).
- **If llega una acción durante un bloqueo `PUZZLE`/`ELEMENT`**: se descarta, no se encola, y el cursor sigue moviéndose.
- **If la ventana pierde el foco o se pausa en medio de un rechazo, una comprobación o una secuencia**: todos los temporizadores del marco son de tiempo de juego y se detienen; al reanudar continúan donde estaban (Entrada, regla 7).
- **If el controlador devuelve `REJECT` en una política que no lo admite** (P2, P5, P6): el marco lo trata como `NONE` y, en desarrollo, lo registra como error de datos.
- **If dos elementos reciben `PARTIAL` a la vez** (dos fichas con selectores completados en el mismo fotograma): se procesan en el orden de llegada; cada una genera su feedback.
- **If el jugador intenta encajar en el hueco S6 vacío del P3**: el elemento lo rechaza (`REJECT`, `lock` `ELEMENT`), igual que una pieza equivocada; la pieza vuelve a la bandeja (B.3).
- **If el jugador deja una ficha del P4 sin decidir y sale**: permanece como está; el puzle sigue `ACTIVO` (§13.3).
- **If el jugador pulsa un segundo botón del P6 en el mismo fotograma que el primero**: el primero que llegue al marco gana; el segundo se descarta (S9).
- **If el jugador cierra el juego en `RESOLVING`**: ver regla 19; no se escribe nada de la resolución.

**Resolución**
- **If una escritura de hecho es rechazada por el estado** (valor distinto en un hecho de un solo sentido): el puzle se queda en el estado anterior, se registra el error y, en desarrollo, la ejecución se detiene (regla 6 del GDD del 3).
- **If la línea de audio del P5 no existe o falla**: la secuencia continúa pasados `line_timeout_s` (regla 20) o al terminar la duración fija del paso; el subtítulo se muestra según 26.
- **If el jugador se aleja del compartimento durante la revelación sin cerrar la vista** (otra acción obliga a salir): se trata como interrupción (regla 18).
- **If la vista se cierra por `resuelto` mientras el jugador pulsa `atrás`**: un solo cierre; 7 ignora la segunda petición (Entrada, edge case de contexto).
- **If el jugador resuelve P4 antes que P3**: es válido (el 2 no tiene dependencias); la lista de tareas (I-05) llega antes que la nota (I-06a).
- **If falta el ítem requerido** (P1 sin `I-01`): la vista se abre con los huecos vacíos y el texto de `locked_feedback`; el puzle sigue `ACTIVO`. Qué pista corresponde a un jugador sin impresión (la de cámara apunta a la impresión, que no tiene) lo decide el sistema 17.

**Degenerate strategies (Sirlin, «Playing to Win»)**
- **Fuerza bruta (P1, P4):** P1 admite 24 intentos como máximo (F6: ≤ 83 s); P4, 9 por ficha. Se acepta, no es dominante en términos de diseño: no daña al jugador (sin contador ni penalización) y todos los puzles entregan su contenido narrativo *después* de resolverse, de modo que forzarlos no se salta la historia. Se instrumenta (regla 32) para detectar si es común.
- **Barrido del P5:** girar el marco a toda velocidad y detenerse ante la marca de 40° es una estrategia legítima (la marca se ilumina en el nivel 3); `hold_s` evita que cruzarla en el barrido resuelva sin querer.
- **Pedir pistas de inmediato:** no existe coste que lo limite; es una decisión de autonomía. Si se abusa y daña el criterio 5 del slice, se resuelve en el sistema 17 (espaciado), no con una penalización aquí.
- **Dejar fichas sin decidir (P4) como «guardado»:** inocuo; no hay temporizador.
- **Resolver P6 sin pensar:** válido por diseño («No hay respuesta incorrecta»).

**Datos y herramientas**
- **If el fichero `puzzles.json` falta o está corrupto**: en desarrollo, error visible; en la build final se trata como un fallo de empaquetado, no como un camino de juego: la escena no se activa a medias y se aplica el fallo de carga del GDD del 4 (regla 14: mensaje claro y vuelta al título), en vez de dejar puzles inalcanzables.
- **If una pista `AFFORDANCE` se activa en un puzle ya `RESUELTO`**: no tiene efecto.

## Dependencies

**Aguas arriba (de qué depende)**

| Sistema | Tipo | Qué necesita |
|---|---|---|
| 3 Estado y bus de eventos | Dura | Leer y escribir los hechos de puzle; emitir `EV_PUZZLE_SOLVED_*` y los demás avisos; recibir cambios de los `requires` |
| 7 Interacción e inspección | Dura | Vistas cercanas, `PointerEvent`, activaciones de objetos (modo `WORLD`), cierre de vistas |
| 6 Ajustes persistentes | Blanda | `asistencia_encaje` y `asistencia_rotacion` |
| 18 Base de contenido | Blanda | Claves de pista y de textos de rechazo/bloqueo |
| 2 Jugador | Blanda (‡ vía 7) | `CAMERA_NUDGE` de las pistas (nudge de cámara hacia un objetivo) |
| 23 Director de audio | Blanda (‡) | «línea terminada» (si falta, rige `line_timeout_s`) |

**Aguas abajo**

| Sistema | Tipo | Interfaz |
|---|---|---|
| 10 Caja y compartimentos | Dura | «Puzle activado» y `EV_PUZZLE_SOLVED_*` |
| 11–16 Puzles | Dura | Implementan `PuzzleController` |
| 17 Sistema de pistas | Dura (cuando exista) | `list_puzzles`, `get_hints`, `request_hint`, «puzle inactivo» |
| 21 Director de escenas | Indirecta | Lee `caja_completa` (derivado) |
| 28 Atmósfera · 29 Shaders | Blanda | Avisos de resolución |
| 5 Guardado y carga | Blanda | Instantánea; guardar al cambiar `caja_c*` y `pendiente_revelacion` ‡ |

**Índice de sistemas:** la fila 9 lista `3, 7`; faltan como dependencias blandas `6` y `18` (propuesta en «Propuesta de registro»). Las filas de los puzles 11 a 16 ya listan al 9. **Bidireccionalidad:** el GDD del 3 ya lista al 9 como escritor y emisor (su tabla de Dependencies y su regla 10), con la salvedad de la propiedad de hechos (regla 1); el GDD del 7 lista al 9 como receptor de las vistas; el GDD de Ajustes lista a 13 y 15 «vía marco 9». Los GDD de 10 a 17 deben listar al 9 como dependencia, usar los veredictos y la interfaz de la regla 9, y no escribir hechos por su cuenta.

## Tuning Knobs

**F** = feel, **C** = curva, **G** = gate. Todos viven en `assets/data/puzzles/puzzles.json` (valores del slice en negrita: vienen del Anexo B; el resto es †).

| Knob | Cat. | Defecto | Rango seguro | Qué afecta y por qué ese valor |
|---|---|---|---|---|
| `delay_s` (P1) | F | **0,6 s** | 0,3–1,5 | Pausa antes de comprobar. Muy bajo: castiga corregir la última referencia; muy alto: se siente lento |
| `shake_s` / `reset_after_s` (P1) | F | **1,2 s / 1,5 s** | 0,6–2,0 / ≤ `lock_max_s` | Duración del rechazo y vuelta de las referencias |
| `piece_return_s` (P3) | F | **0,4 s** | 0,2–1,0 | Vuelta de la pieza a la bandeja |
| `snap_radius_m` (P3) | F | **0,04 m** (asistido **0,10 m**) | 0,03–0,06 / 0,06–0,15 | Tolerancia de encaje; accesibilidad motriz |
| `view_distance_m` (P3) | F | **0,35 m** | 0,25–0,5 | Distancia de la vista de cierre |
| `no_corresponde_s` (P4) | F | **1,5 s** | 1,0–3,0 | Tiempo del mensaje de ficha incorrecta |
| `theta_solution_deg` (P5) | C | **40°** | 20–70 | Ángulo de la solución (valor de referencia del slice) |
| `tol_deg` (P5) | C | **3° (asistido 6°)** | 2–5 / 4–10 | Tolerancia de alineación |
| `hold_s` (P5) | F | **0,8 s** | 0,4–1,5 | Tiempo mantenido para iniciar la revelación |
| `theta_initial_deg` (P5) | C | 0°† | 0–90 (fuera de `θ* ± tol`) | Ángulo de partida |
| `reveal_fade_s` (P5) | F | **1,2 s** | 0,6–2,0 | Fundido de superposición |
| `fragment_fade_s` (P2) | F | **0,8 s** | 0,4–1,5 | Fundido al iluminar un fragmento |
| `ajar_cm` (P5/P6 desbloqueo) | F | **2 cm** | 1–4 | Cuánto se entreabre el compartimento al desbloquearse |
| `close_view_after_s` | F | 1,5 s† | 0,5–3,0 | Cuándo se cierra la vista tras resolver |
| `lock_max_s` | G | 2,0 s† | 1,0–3,0 | Tope de bloqueo de entrada tras un rechazo (garantía de «sin espera larga») |
| `latencia_feedback_ms` | F | 100† | 50–200 | Tope de respuesta percibida |
| `idle_s` P3 nivel 3 | G | **60 s** | 30–120 | Cuándo aparece el contorno sin pedirlo |
| `idle_s` P6 niveles 1 y 2 | G | **10 s / 20 s** | 5–60 | Cuándo aparecen los mensajes |
| `idle_hints_auto_apply` | G | verdadero† | bool | Aplicar pistas `IDLE` sin el sistema 17 |
| `line_timeout_s` | G | 30 s† | 20–60 | Tope de espera de una línea de audio en una secuencia |
| `dt_max` | F | 0,1 s† | 0,05–0,2 | Tope por fotograma de F2 |
| `N_fuzz` | G | 1.000† | 100–10.000 | Secuencias por puzle de la prueba de resolubilidad |

## Visual/Audio Requirements

*(Sección opcional para la categoría Gameplay; en modo `lean` no se consulta a `art-director` ni a `audio-director`: revisar antes de producción.)*

- **Sonidos** (de B.7 del slice, sin añadir): `SFX_SLIDE_OK`, `SFX_SLOT_IN` (P1), `SFX_UNLOCK` (P1), `SFX_UNLOCK_SOFT` (desbloqueo de compartimento), `SFX_REJECT` (cualquier rechazo), `SFX_GLASS_HUM` (P2), `SFX_SNAP` (P3), `SFX_STAMP` (P4), `SFX_LOCK_CLICK` (P6), `SFX_CLICK_SUBTLE` (eco sin efecto), `BOX_C1_OPEN`–`BOX_C4_OPEN`. El marco los pide por el aviso «feedback de puzle»; cómo suenan es de 23.
- **Rechazo:** debe ser **legible pero no punitivo**: vibración breve, sonido seco y bajo, sin tonos de error agudos ni destellos (pilar *Tensión sin castigo*; coherente con `reducir_sobresaltos`, que atenúa los destellos del pasillo y del apagón en 28).
- **Resolución:** cada acierto debe poder reconocerse con la pantalla apagada (sonido) y con el sonido apagado (cambio visible): doble canal para accesibilidad.
- **P5 · revelación:** la superposición de las fotos y el contorno de Vera la implementa 29 (versión provisional en el MVP, nota del índice). El marco sólo da el instante y la duración.
- **Desbloqueo:** el compartimento entreabierto 2 cm es el único «aviso» visual de que algo nuevo está disponible (no hay marcadores).

## Game Feel

- **Respuesta:** toda acción procesada responde en ≤ `latencia_feedback_ms` (100†). Un rechazo nunca deja la pantalla «muerta» más de `lock_max_s` (2,0 s†).
- **Fallo:** el jugador debe sentir «lo intenté y no era», no «me han castigado»: rechazo corto (≤ 1,5 s), reintento inmediato posible, sin contador a la vista.
- **Acierto:** nítido y breve; el compartimento, la puerta o el cristal confirman con cambio de mundo, no con un cartel.
- **P5:** la alineación se siente «imanada» sin ser automática; la marca de 40° no se muestra hasta el nivel 3. La revelación tiene su ritmo propio (~16 s) y salir de ella nunca asusta.
- **Referencia de comparación:** valores † a afinar en el primer playtest (slice §23.4) con los tiempos objetivo de F7.

## UI Requirements

- **Sin barras, sin contadores de intentos, sin cronómetros, sin porcentaje de progreso** (slice §16). El único feedback es diegético (vibración, sellos, luz).
- **Textos de puzle** (reglas del tablero, «No corresponde», «ACEPTADA»/«DEVUELTA», pistas): claves de la base de contenido (18); ningún literal en el código.
- **Pistas:** se piden desde el menú de pausa (25), con tres niveles por puzle; la interfaz de pistas es del sistema 17.
- **Cursor y elementos:** los de 7 (`pick_min_px`) y los de Entrada (cursor virtual).
- **Accesibilidad:** `asistencia_encaje` y `asistencia_rotacion` se activan en Ajustes (6) y las lee el marco en cada puzle; el marco no tiene pantalla propia.

📌 **UX Flag — Marco de puzles**: los seis puzles tienen vistas con requisitos de interfaz (pistas, textos, sellos). En preproducción, ejecuta `/ux-design` para cada vista cercana antes de escribir las épicas.

## Cross-References

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · §10, §13.3, §16, §19 | Puzles, pistas, sin softlock, sin game over, criterios 2, 3, 5 y 7 | Define el alcance y las garantías |
| `design/slice/slice-v0.3.md` · Anexo B (B.1–B.7) | Estados, políticas, tiempos, soluciones, resultados y pistas por puzle | Fuente de los datos de `puzzles.json` |
| `design/slice/slice-v0.3.md` · Anexo D.1, D.2, D.3, D.4 | Ítems, banderas, guardado, índice de IDs | Hechos que escribe el marco |
| `design/slice/slice-v0.3.md` · D-14, D-16 | Carta permanente; orden de la caja | Supuestos pendientes de confirmar |
| `design/gdd/estado-y-bus-de-eventos.md` · reglas 2, 4, 5, 7, 10, 11 | Propiedad, un solo sentido, `pos_*` y `pendiente_revelacion` reversibles, `caja_completa` derivado, `EV_PUZZLE_SOLVED_<ID>`, orden de avisos | Contrato directo |
| `design/gdd/interaccion-e-inspeccion.md` · reglas 19–23, 27 y F6 | Vista cercana, `PointerEvent`, picking, cierre y conversión px↔m | Contrato directo |
| `design/gdd/entrada-y-controles.md` · reglas 8, 12, 13, 14, F4–F6, F8 y Open Question 2 | Gestos, contextos, transiciones, `t_hold`, tolerancias | Origen de los gestos y tiempos |
| `design/gdd/ajustes-persistentes.md` · `asistencia_encaje`, `asistencia_rotacion` | Ayudas de los puzles 3 y 5 | Parámetros asistidos |
| `design/gdd/base-de-contenido-narrativo.md` · reglas 3, 10 | `PISTA_P<n>_N<k>`, fragmentos de `DOC_01` | Textos de pistas y del P2 |
| `design/gdd/escena-de-planta.md` · regla 9.6 | Los elementos se configuran leyendo hechos | Base de la regla 8 |
| `design/gdd/game-pillars.md` | *Tensión sin castigo*, *Autonomía como progresión*, *Información incompleta* | Pilares que este sistema sirve |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/puzzles/`), bloqueante; **I** = test de integración o playtest documentado (`tests/integration/puzzles/`), bloqueante; **V** = captura retenida en `production/qa/evidence/`, bloqueante. Los tests L usan un estado (3), un reloj, un audio y un 7 falsos, y una fixture de `puzzles.json` por caso. Tolerancia numérica ±0,001 salvo indicación. Los valores † pueden cambiar tras el playtest.

**Ciclo de vida (reglas 6 a 8, 24)**
- **AC-01 (R6, L)**: **GIVEN** un puzle `ACTIVO`, **WHEN** se intenta pasar a `BLOQUEADO`, **THEN** se rechaza; **GIVEN** `RESUELTO`, **WHEN** llega cualquier gesto, **THEN** no cambia ninguna pieza y suena `SFX_CLICK_SUBTLE`.
- **AC-02 (R8, L)**: **GIVEN** `caja_c1` verdadero al cargar, **THEN** P3 está `RESUELTO` con su presentación final y no se emitió ningún aviso `EV_PUZZLE_SOLVED_P3`; P5 está `ACTIVO` y no hubo `SFX_UNLOCK_SOFT`.
- **AC-03 (R24, L)**: **GIVEN** P5 `BLOQUEADO`, **WHEN** `caja_c1` pasa a verdadero, **THEN** P5 pasa a `ACTIVO`, se emite «puzle activado» (P5) una vez y suena `SFX_UNLOCK_SOFT`; **GIVEN** P6 con `caja_c1`, `c2` verdaderos y `c3` falso, **THEN** sigue `BLOQUEADO`; con `c3` verdadero, pasa a `ACTIVO`.
- **AC-04 (R7, L)**: **GIVEN** P6 `BLOQUEADO`, **WHEN** se abre su vista, **THEN** se ejecuta `locked_feedback` y se pide cerrarla; no se escribe ningún hecho.
- **AC-05 (R24, L)**: **GIVEN** el orden de resolución P4, P3, P5, P6 y también P3, P5, P4, P6, **THEN** ambos son válidos y terminan con `caja_completa` verdadero.

**Veredictos y fallo (reglas 12 a 15, F1)**
- **AC-06 (R12, F1, L)**: **GIVEN** P1 con `delay_s` 0,6, **WHEN** se llenan los cuatro huecos en t = 10,00 y se cambia H3 en t = 10,40, **THEN** se evalúa a los 11,00 s y no antes; **WHEN** sale de la vista en 10,70, **THEN** no se evalúa y al volver se rearma otros 0,6 s.
- **AC-07 (R14, L)**: **GIVEN** P1 con la secuencia 1,2,3,4, **WHEN** se evalúa, **THEN** `REJECT`: `SFX_REJECT`, los huecos vibran 1,2 s, las referencias vuelven al papel a los 1,5 s, la entrada del puzle queda bloqueada 1,5 s (los eventos se descartan) y después acepta entrada; no existe contador de fallos ni ningún hecho cambia.
- **AC-08 (R14, L)**: **GIVEN** P3 con una pieza fuera del radio de 0,04 m, **WHEN** se suelta, **THEN** `REJECT`: vuelve a la bandeja en 0,4 s, solo esa pieza está bloqueada y las ya encajadas siguen intactas; **GIVEN** `asistencia_encaje` activa, **THEN** a 0,09 m encaja; a 0,11 m, no.
- **AC-09 (R14, L)**: **GIVEN** P4 con T1 aceptada y T2 con la selección incorrecta, **WHEN** se evalúa T2, **THEN** T2 vuelve a neutra, aparece «No corresponde» 1,5 s, T1 sigue bloqueada como correcta y T2 se puede reeditar de inmediato.
- **AC-10 (R14, L)**: **GIVEN** cualquier `on_reject` con `reset_after_s` > `lock_max_s`, **THEN** la validación de datos falla (regla 29).
- **AC-11 (R15, L)**: **GIVEN** P2 y P6, **WHEN** el controlador devuelve `REJECT`, **THEN** se trata como `NONE` y se registra como error de datos.
- **AC-12 (R12, L)**: **GIVEN** P2 con L = 3, C = 1, R = 4, **THEN** `SOLVED`; con L = 3, C = 1, R = 2, **THEN** `PARTIAL` (dos fragmentos) y no resuelve; con L = 2 (sello distractor), **THEN** no se ilumina F1.
- **AC-13 (R13, L)**: **GIVEN** cualquier acción procesada, **THEN** hay un feedback audible o visible en ≤ 100 ms (reloj falso).

**Comprobación mantenida (F2)**
- **AC-14 (R12, F2, L)**: **GIVEN** P5 con tol 3, hold 0,8 y 60 fps, **WHEN** θ = 38° durante 48 fotogramas, **THEN** `SOLVED`; **WHEN** θ = 43,5° a mitad, **THEN** `acum` = 0 y reinicia; **GIVEN** `asistencia_rotacion`, **THEN** 43,5° mantiene la cuenta (tol 6).
- **AC-15 (F2, L)**: **GIVEN** un tirón de dt = 0,5 s con θ dentro de tolerancia, **THEN** `acum` aumenta 0,1 s (tope `dt_max`).
- **AC-16 (F2, L)**: **GIVEN** un barrido de θ de 0° a 90° a 200°/s, **THEN** nunca se alcanza `hold_s` y no se resuelve.

**Resolución (reglas 16 a 20, F4, F5)**
- **AC-17 (R16, F5, L)**: **GIVEN** P6 con la opción A, **WHEN** se acepta, **THEN** el orden de escrituras es `carta_variante` = A, `caja_c4`, el estado recalcula `caja_completa`, estado público `RESUELTO`, y después el aviso `EV_PUZZLE_SOLVED_P6` con `choice` = A; ningún suscriptor ve `caja_completa` sin `carta_variante`.
- **AC-18 (R16, L)**: **GIVEN** P1 resuelto, **THEN** se escribe `archivo_abierto`, se emite `EV_PUZZLE_SOLVED_P1` una vez y a los 1,5 s se pide cerrar la vista con motivo `resuelto`.
- **AC-19 (R16, L)**: **GIVEN** P3, P4 y P5 resueltos, **THEN** `caja_c1`, `caja_c2` y `caja_c3` son verdaderos con sus avisos `EV_PUZZLE_SOLVED_P3/P4/P5` y las recompensas `I-06a`, `I-05` en la carga útil.
- **AC-20 (R17, R19, L)**: **GIVEN** P5 con la alineación mantenida, **THEN** `pendiente_revelacion` = verdadero al iniciar la secuencia, `caja_c3` sigue falso, y al terminar los 16 s `pendiente_revelacion` = falso y `caja_c3` = verdadero, en ese orden, con el aviso al final.
- **AC-21 (R18, L)**: **GIVEN** P5 en `RESOLVING`, **WHEN** el jugador pulsa `atrás` a los 5 s, **THEN** se emite «resolución de puzle interrumpida», `caja_c3` sigue falso, `pendiente_revelacion` sigue verdadero y el puzle vuelve a `IDLE`.
- **AC-22 (R19, L)**: **GIVEN** `pendiente_revelacion` verdadero, **WHEN** el jugador vuelve a comprometerse con P5, **THEN** no se pide alineación y la secuencia se reproduce desde el paso 1.
- **AC-23 (R20, L)**: **GIVEN** que «línea terminada» no llega, **WHEN** pasan `line_timeout_s` (30 s), **THEN** la secuencia termina y `caja_c3` pasa a verdadero.
- **AC-24 (R16, L)**: **GIVEN** un segundo `SOLVED` en el mismo fotograma, **THEN** se descarta; el aviso se emite una vez.
- **AC-25 (R13, I)**: **GIVEN** P6, **WHEN** el jugador pulsa dos botones a la vez, **THEN** solo uno fija `carta_variante` y los otros dos se bloquean.

**Reinicio y persistencia (reglas 21 a 23)**
- **AC-26 (R21, L)**: **GIVEN** P3 con tres piezas encajadas, **WHEN** se cierra y se reabre la vista, **THEN** conserva las tres; **WHEN** se carga la escena de nuevo, **THEN** empieza vacío.
- **AC-27 (R22, L)**: **GIVEN** P2, **WHEN** cambia una lámpara, **THEN** `pos_X` se escribe en el mismo fotograma; **WHEN** se recarga, **THEN** las lámparas están en la última posición.
- **AC-28 (R22, L)**: **GIVEN** cualquier partida, **THEN** el marco no añade hechos nuevos al catálogo (siguen siendo 19).
- **AC-29 (R23, I)**: **GIVEN** la resolución del P4, **WHEN** se autoguarda, **THEN** la instantánea contiene `caja_c2` y, si procede, `caja_completa` coherente; reanudar muestra P4 `RESUELTO` y `I-05` disponible.

**Pistas (reglas 25 a 27, F3)**
- **AC-30 (R25, L)**: **GIVEN** `puzzles.json` del slice, **THEN** P1–P5 tienen tres pistas, P6 tiene dos, y cada clave existe en la base de contenido (18).
- **AC-31 (R26, F3, L)**: **GIVEN** P6 con la vista abierta, **WHEN** pasan 10 s sin actuar, **THEN** se emite «puzle inactivo» (nivel 1) una sola vez y, con `idle_hints_auto_apply`, se aplica el texto; a 20 s, el nivel 2; si se mueve el cursor a los 15 s, `idle` = 0 y el nivel 1 no se repite.
- **AC-32 (R26, L)**: **GIVEN** P3 con 60 s sin actuar y una pieza sostenida, **THEN** se marca el contorno de su hueco correcto.
- **AC-33 (R26, L)**: **GIVEN** `request_hint(P4, 3)`, **THEN** T1 se resuelve sola con su explicación («La urgencia sigue al plazo; el responsable, a quien ya lleva el caso») y cuenta como elemento correcto; **GIVEN** un puzle `RESUELTO`, **THEN** `request_hint` se rechaza.
- **AC-34 (R26, L)**: **GIVEN** que se cargó la escena, **THEN** `hint_level_reached` de todos los puzles es 0 (no se persiste).

**Anti-softlock (reglas 28 a 31)**
- **AC-35 (R29, L)**: **GIVEN** un `puzzles.json` con un ciclo de `requires` (P5 requiere `caja_c3`), **THEN** la validación falla; **GIVEN** un puzle cuyo estado inicial satisface su solución, **THEN** la validación falla; **GIVEN** un `requires` sin escritor, **THEN** falla.
- **AC-36 (R30, L)**: **GIVEN** cada uno de los seis controladores y 1.000 secuencias aleatorias de acciones válidas, **THEN** tras cada acción `debug_is_solvable()` es verdadero y no se escribió ningún hecho inválido.
- **AC-37 (R28, L)**: **GIVEN** cada vista, **WHEN** llega `atrás` en cualquier fase salvo la transición de entrada, **THEN** la vista se cierra y el puzle conserva un estado válido.
- **AC-38 (R28, I)**: **GIVEN** un tester que se equivoca todo lo posible en cada puzle durante la partida, **THEN** nunca queda bloqueado ni necesita reiniciar el juego (slice §19.3 y §19.7).
- **AC-39 (S6, L)**: **GIVEN** P1 sin `I-01`, **WHEN** se abre la vista, **THEN** muestra los huecos vacíos y `locked_feedback`; no se escribe ningún hecho; con `correos_leidos` e `I-01` el puzle es resoluble.
- **AC-40 (R31, L)**: **GIVEN** la consola forzando `caja_c1` = verdadero con P3 `ACTIVO`, **THEN** P3 pasa a `RESUELTO` en silencio sin `EV_PUZZLE_SOLVED_P3`.

**Experiencia (playtest, I)**
- **AC-X1 (I)**: **GIVEN** un jugador nuevo, **THEN** resuelve cada puzle con información del propio juego y las pistas en tres niveles (slice §19.2).
- **AC-X2 (I)**: **GIVEN** 6 testers, **WHEN** se equivocan en un puzle, **THEN** ninguno describe el fallo como «castigo» ni «penalización» (cuestionario de una pregunta); el tiempo hasta reintentar es ≤ 2 s.
- **AC-X3 (I)**: **GIVEN** el registro de la regla 32, **THEN** los tiempos de F7 se cumplen para ≥ 4 de 6 testers y ≥ 50 % identifica la diferencia del P5 sin pista de nivel 3 (slice §19.5).
- **AC-X4 (I)**: **GIVEN** el P5, **WHEN** el jugador sale a medio escuchar la grabación y vuelve, **THEN** la oye entera y se abre el compartimento sin repetir la alineación.

## Decisiones tomadas

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D9-1 | Los controladores devuelven un veredicto y el marco decide la consecuencia | Cada puzle gestiona su fallo, hechos y avisos | Una sola política de fallo verificable (slice §19.3) y un único escritor de hechos |
| D9-2 | Un controlador por puzle + datos para todo valor numérico | Puzle 100 % declarativo | P2 (espacial), P3 (arrastre) y P5 (rotación) necesitan lógica propia; los datos cubren soluciones, tolerancias y tiempos |
| D9-3 | Tres estados públicos del slice + fases internas no publicadas | Más estados públicos (`EVALUANDO`, `FALLIDO`…) | El Anexo B fija tres estados; `FALLIDO` contradeciría el pilar *Tensión sin castigo* |
| D9-4 | El marco es el único escritor de los hechos de puzle | Cada puzle escribe los suyos (como sugiere la tabla de 3) | Garantiza el orden de la regla 16 (p. ej. `carta_variante` antes de `caja_c4`) y la idempotencia; se propone `owner = 9` |
| D9-5 | P5 escribe `pendiente_revelacion` al *iniciar* la revelación y la limpia al terminar | Escribirla solo al interrumpirse | Cubre cerrar el juego, que no puede ejecutar código de interrupción; sin lógica extra |
| D9-6 | La revelación del P5 se reproduce desde el principio al reanudar | Reanudar la línea de audio donde se cortó | El jugador debe oír la grabación entera (función narrativa del puzle) |
| D9-7 | El P2 pasa a inerte al resolverse (lámparas bloqueadas, memorando permanente) | Dejar las lámparas manipulables | «El memorando completo queda legible» (B.2); evita deshacer visualmente un hecho ya adquirido (`memo_leido` es de un solo sentido) |
| D9-8 | El progreso parcial no se persiste (salvo `pos_*` y `pendiente_revelacion`) | Persistir piezas colocadas | El slice sólo guarda al completar compartimentos (D.3); rehacer un parcial no cuesta nada; no se añaden hechos |
| D9-9 | Rechazo con bloqueo máximo de 2 s y sin contador | Bloqueo creciente o límite de intentos | Pilar *Tensión sin castigo*; la fuerza bruta es barata y se acepta (F6) |
| D9-10 | Pistas `IDLE` se aplican solas hasta que exista el 17 | Dejarlas sin aplicar en el MVP | Son parte del Anexo B (P3 nivel 3, P6); el 17 es Vertical Slice |
| D9-11 | Dependencias de puzle calculadas por el marco (`requires`), y Caja (10) anima el hardware | Dependencias dentro de Caja | Misma mecánica para todos los puzles; Caja no necesita lógica de estado |
| D9-12 | Cuando el Anexo B contradice a §10 (P2 y P5 sin fallo; P6 con dos pistas) prevalece el Anexo | Seguir §10 | El Anexo B es la especificación de implementación y más reciente |
| D9-13 | `P1`–`P6` como identificadores de puzle en `EV_PUZZLE_SOLVED_<ID>` | `PZ1`… o nombres descriptivos | Confirma la propuesta de la regla 10 del GDD del 3; corto y estable |

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | **P6 tiene dos niveles de pista (B.6) y el slice §10 declara «tres niveles de pista» para todos.** El marco admite dos; si el slice exige tres, hay que escribir un tercero (¿qué diría sin condicionar la elección, que es una cuestión emocional?). Contradice §10 y toca el pilar *Autonomía* | Creative director / narrativa | Cierre del GDD 16 |
| 2 | **Qué hace el compartimento 4 al abrirse** (¿la carta se muestra sola en `lectura` o queda en la bandeja para leerla?). Se asume lectura automática vía `abrir_lectura` (nueva petición a 7) | GDD de los sistemas 16 y 20 | GDD 16 |
| 3 | **Guardar con `pendiente_revelacion`**: D.3 del slice implica un guardado al empezar la revelación del P5 que no figura entre los disparadores de §13.2. El marco lo asume (regla 19) | GDD del sistema 5 | GDD 5 |

## Propuesta de registro

Para `design/registry/entities.yaml` (no se edita aquí; lo hará quien consolide):

| Tipo | Nombre | Valor / contenido | Fuente |
|---|---|---|---|
| constante | `P1`–`P6` | identificadores de puzle (`EV_PUZZLE_SOLVED_P1`…) | este GDD, regla 1 |
| constante | `delay_s_P1` | 0,6 s | slice B.1 |
| constante | `snap_radius_m_P3` / asistido | 0,04 m / 0,10 m | slice B.3 |
| constante | `theta_solution_deg_P5` / `tol_deg` / `hold_s` | 40° / 3° (asistido 6°) / 0,8 s | slice B.5 |
| constante | `lock_max_s` | 2,0 s† | este GDD, regla 14 |
| constante | `latencia_feedback_ms` | 100† | este GDD |
| constante | `idle_s_P3_N3` / `idle_s_P6_N1,N2` | 60 s / 10 s y 20 s | slice B.3, B.6 |
| fórmula | `F1`–`F7` | retraso con rebote, condición mantenida, inactividad, cierre automático, orden de escritura, coste de fuerza bruta, objetivos de duración | este GDD |
| aviso | `EV_PUZZLE_SOLVED_P1`–`P6` (`{puzzle, rewards, choice}`), «puzle activado», «resolución de puzle interrumpida», «pista aplicada», «puzle inactivo», «feedback de puzle» | emisor: 9 | este GDD |
| dato | `assets/data/puzzles/puzzles.json` | definiciones de los seis puzles | este GDD, regla 4 |
| hecho | propiedad (`owner`) de `archivo_abierto`, `memo_leido`, `pos_*`, `caja_c1`–`c4`, `pendiente_revelacion`, `carta_variante` | `9` (propuesta; el GDD del 3 dice «11–16») | este GDD, regla 1 |
| dependencia | índice, fila 9 | añadir las blandas `6` y `18` | este GDD |
| interfaz | `PuzzleController` | `configure`, `on_engage/on_disengage`, `handle_pointer/handle_activation`, `evaluate`, `reset_attempt`, `play_resolution`, `restore_solved_presentation`, `apply_hint_effect`, `debug_is_solvable` | este GDD, regla 9 |
