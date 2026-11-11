# Puzle 1 · Cronología

> **Status**: Revisado (ronda de corrección 9) — pendiente de re-review
> **Author**: game-designer (lote autónomo) + usuario
> **Last Updated**: 2026-11-09
> **Sistema**: 11 (`design/gdd/systems-index.md`) · Capa `Feature` · Categoría `Gameplay` · Prioridad `MVP`
> **Fuente de verdad del slice**: `design/slice/slice-v0.3.md` (contenido v0.4.2): §10.1, §19.1, Anexo B.1, D.2. Marco que lo instancia: `design/gdd/marco-de-puzles.md` (9).
> **Implements Pillar**: Autonomía como progresión (el jugador reconstruye la cronología, nadie se la dicta) · Información incompleta (el puzle entrega *hechos* —fechas y horas—, no intenciones) · Tensión sin castigo (error = las referencias vuelven al papel, sin contador ni espera larga)

Convenciones: `†` = valor propuesto, a validar en playtest. `‡` = propuesta que debe confirmar el GDD del sistema afectado. Claves de datos e identificadores de código en inglés; IDs del slice (`P1`, `C05`, `I-01`, `V08`, `archivo_abierto`, `SFX_REJECT`, `EV_PUZZLE_SOLVED_P1`) tal cual. «Regla N de X» = regla N del GDD X (marco de puzles = 9).

## Summary

El Puzle 1 es el primer puzle del slice y el que enseña la gramática de todos: una hoja impresa con cuatro correos numerados (más dos de ruido) y un panel de cuatro huecos en el pasillo (`C05`, junto a la puerta del Archivo). El jugador coloca las referencias 1 a 4 en los huecos H1–H4 por orden de envío (día y hora). La solución es `2 · 1 · 3 · 4`. Acertar escribe `archivo_abierto` (lo escribe 9, no 11) y la puerta A empieza a abrirse; fallar hace vibrar los huecos y devuelve las referencias a la hoja, sin contador ni consecuencia. 11 define lo que es propio de este puzle (qué es una colocación, la solución y su derivación, el reparto de pistas N1–N3, la geometría de referencia de la vista, la tabla de rutas de fuerza bruta); 9 aporta el ciclo de vida, la comprobación retrasada, la política de fallo y la escritura de hechos; 19 aporta el contenido de la hoja `I-01`; 20 guarda si el jugador la tiene.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Depende de: `9 Marco de puzles`, `18 Base de contenido`, `19 Ordenador, correo e impresora`, `20 Documentos y bolsillo` (declaradas por 11, el dependiente) · Lo consumen: `8` (hecho `archivo_abierto`), `17` (pistas), `7` (vista `C05`) · Estado inicial: `ACTIVO`, sin material (`needs_items: ["I-01"]`) · Política: `DELAYED_AFTER_CHANGE` 0,6 s · Resolución: `IMMEDIATE`

## Overview

**Qué es.** Un puzle de ordenar: cuatro huecos en fila (H1–H4) y una hoja `I-01` en la misma vista con seis bloques (cuatro con referencia `1`–`4`, dos de ruido sin referencia). Cada bloque trae su día y su `Enviado: hh:mm`; el pie de la hoja dice «Ordena por hora de envío» (B.1 literal, confirmado en v0.4). El jugador pulsa una referencia y después un hueco para colocarla; con los cuatro huecos llenos y 0,6 s sin cambios, el marco comprueba la secuencia.

**Qué lo hace un puzle y no un trámite.** La solución no está en ninguna parte tal cual: hay que *derivarla* comparando fechas y horas de cuatro correos que el jugador ha leído antes en el ordenador (`V01`) y reimpreso en `V08`. Hay una trampa legítima y deducible: el correo 4 es del martes 08:55, una hora «más temprana» que el correo 2 del lunes 09:14; ordenar solo por la hora da `4 · 2 · 1 · 3` y falla; el día lo evita. Los dos correos de ruido (lunes 10:30, martes 14:00) no tienen referencia y no se pueden colocar: dan textura y obligan a leer la hoja, no solo a contar.

**Qué entrega.** Un hecho observable (cronología: lunes 09:14 «¿te viene bien que lo hablemos?» → 11:40 «pendiente de tu confirmación» → 16:02 «solicitud registrada a nombre de Vera» → martes 08:55 «Vera ya figura en la unidad nueva»). El puzle no interpreta ni valora nada (Pilar 5): confirma que la solicitud se registró después de que el formulario pareciera firmado y sin que Vera lo confirmara, y lo deja al jugador. Mecánicamente entrega `archivo_abierto` (la puerta A se abre; detrás están el cajón `A05` y las tarjetas de 20).

**Dónde vive en el árbol de sistemas.** Es `ACTIVO` desde el inicio (`requires.all` vacío), pero nunca está *accionable* hasta que el jugador tiene `I-01` (S6 de 9). Eso conecta tres sistemas en una cadena de investigación: leer (19) → imprimir (19→20) → ordenar (11 sobre 9) → abrir (8).

## Player Fantasy

Vera no «resuelve un acertijo»: **ordena lo que ya sabe** y de pronto la historia tiene forma. Estética principal (MDA): **Discovery** (comparar documentos) y **Narrative** (la cronología reconstruida es el hallazgo); secundaria: **Challenge** suave. La emoción buscada es la del *clic* silencioso de entender —«la solicitud se registró a las 16:02, *después* de pedirme confirmación a las 11:40»— y no la de acertar un código. Es el primer puzle: debe enseñar que *equivocarse es probar* (los huecos vibran y todo vuelve a la hoja, sin drama; Pilar *Tensión sin castigo*), que *la información está en el juego* (la hoja lo trae todo; Pilar *Autonomía como progresión*) y que *el juego no te dice qué significa* (Pilar *Información incompleta*: la hoja da horas, nunca intenciones). Necesidades SDT: **Competencia** (feedback legible; el jugador sabe por qué falló: lo ve en la hoja) y **Autonomía** (cómo ordenar y en qué orden colocar es libre). Motivaciones Bartle/Quantic: Explorer (leer y cruzar) y Mastery ligera. Curva de dificultad: es el punto bajo de la sierra de 9 (recoger y ordenar), con una única arruga deducible (día frente a hora).

## Detailed Rules

Todas las reglas son de **11 instanciando 9**: no redefinen el ciclo de vida, la política de fallo ni la escritura de hechos; las citan («regla N de 9»). El controlador del P1 (`Puzzle1Controller`, clase que hereda de `PuzzleController`, regla 9 de 9) **solo devuelve veredictos** (regla 10 de 9): nunca escribe hechos, emite avisos ni cambia el estado público.

### A. Propiedad y alcance

**R1. Qué posee 11.** La definición `P1` de `puzzles.json` (sección «Datos del puzle»), el estado de colocación en memoria, las reglas de interacción con la hoja (sección C), la solución y su derivación (D), el reparto de las pistas N1–N3 (G) y la geometría de referencia de `C05` (R14).

**R2. Qué no posee.** El ciclo de vida, la comprobación retrasada, el bloqueo y la escritura de hechos (9); el contenido, el orden y las horas de la hoja `I-01` (19 `compose_i01()`, que lee los registros de 18; regla 11 de 18); la pertenencia de `I-01` al bolsillo (20: solo `has_item("I-01")`); la puerta A, su animación y `ANIM_DOOR_OPEN` (8, regla 6 de 8); el panel `C05` como objeto de la escena (4), su presentación visual (arte) y sus gestos de mano (2).

**R3. Hechos.** 11 **no escribe ni lee ningún hecho**. El único hecho del P1 es `archivo_abierto` (bool, falso al inicio, un solo sentido, owner 9; tabla de hechos de 3, D.2 del slice) y lo escribe **9** al resolverse (R34). 11 no lee `correos_leidos` (solo lo lee 19; D9-50). No hay hecho de estado intermedio (`persist` vacío): las colocaciones **no se guardan** (R44).

**R4. Identificadores.** Puzle `P1`; vista `C05`; hoja `C05/paper`; referencias clicables `C05/paper/ref_1`…`ref_4`; huecos `C05/slot_1`…`slot_4` (H1–H4 del slice; `slot_k` = Hk); marcas de sello `C05/paper/stamp_1`…`stamp_4` (día + hora de cada bloque numerado; **no** clicables, solo objetivo de la pista N3, R30). Los IDs llevan prefijo de vista (regla 4 de 9) para no colisionar con `P1`–`P5` (piezas del encaje, B.3).

### B. Estado inicial y apertura de la vista

**R5. Estado.** `P1` está `ACTIVO` desde el inicio (`requires.all` vacío) y nunca `BLOQUEADO` (regla 6 de 9). Fase inicial `IDLE`. Todos los huecos vacíos y ninguna referencia en mano.

**R6. `C05` como objetivo.** 7 trata `C05` como `ABRIR_VISTA` genérico (verbo `EXAMINAR`, `t_vista_entrada_s` 1,0 s, fov 70°) con `habilitado_si: { ninguno: [archivo_abierto] }` (catálogo de 7, regla 7 de 9). Sin dueño propio: el receptor es el marco (regla 7 de 9). Con `archivo_abierto` verdadero, `C05` deja de ser objetivo (sin icono, sin vista, sin acercamiento).

**R7. Al abrirse la vista (`on_open`).** El marco calcula `missing_items` (lista de IDs de ítem que faltan; `[I-01]` o vacía) con `has_item("I-01")` (regla 7 de 9) y **el controlador del P1** construye sus elementos (H4, ADR-0010 C5/C10):
- **Con `I-01`:** **el controlador del P1 llama a `compose_i01()`** en su `on_open()` (R30 de 19: síncrona, pura, sin estado; el marco ya no la llama, solo es dueño de la puerta) y dibuja `C05/paper` con sus bloques en el orden que devuelve 19 (presentación `3 · 1 · 4 · 2` con los dos de ruido intercalados, B.1). **Reparto único de `elements()`** (alineado con la regla 7 de 9, D11-18 y D9-85): `compose_i01()` de 19 aporta los bloques y sus 4 referencias (`ref` ≠ null); **el controlador de 11** crea un elemento clicable `C05/paper/ref_N` por cada una (exactamente 4) y declara los 4 huecos `C05/slot_k` y las marcas no clicables `C05/paper/stamp_N` (una por bloque con referencia, a partir de `dia` y `hora_envio` del mismo `compose_i01()`).
- **Sin `I-01`:** se dibujan los cuatro huecos vacíos y **ninguna** hoja ni referencia; los huecos responden con `locked_feedback` (`SFX_CLICK_SUBTLE`, sin texto, R27). El puzle sigue `ACTIVO`; no se escribe nada (S6, AC-39 de 9).
- Se llama a `compose_i01()` en **cada** apertura, también al reabrir mientras P1 sigue `ACTIVO` (D9-49). Si `compose_i01()` devuelve un número de bloques con `ref` distinto de 4, el marco registra un error de datos y trata el puzle como sin material (nunca se bloquea la vista; Edge Cases; AC-21).

**R8. Pistas y material.** La falta de `I-01` es un estado de **material**, no de bloqueo (regla 34 de 9): la ruta para conseguirlo existe siempre (leer en `V01`, imprimir en `V08`, repetible e ilimitado; R23–R24 de 19) y la pista N1 la señala (R28).

**R9. Memoria de la vista.** Las colocaciones viven en el controlador **mientras dure la sesión de la escena** (regla 21b de 9: `KEEP`); empiezan siempre vacías al cargar (regla 8 de 9, R28 de 19).

### C. Interacción del jugador con la hoja

**R10. Un solo gesto.** El P1 solo usa `seleccionar` (pulsar y soltar sobre el mismo elemento; el elemento es el que había bajo el cursor al pulsar, regla 11 de 9). La acción se confirma en la fase `fin`. Ignora `actualización`, `agarrar`, `mantener` y `rotar`. Sin arrastrar: no hay pieza «en el aire» salvo la referencia seleccionada (R12).

**R11. Qué es una colocación.** Un estado `S = (s1, s2, s3, s4)` con `sk ∈ {1, 2, 3, 4, vacío}` e inyectivo (una referencia ocupa a lo sumo un hueco). Hay 209 estados posibles (F1); de ellos, 24 son **completos** (los cuatro huecos llenos) y solo uno es la solución. «Colocación» sin más = el contenido de un hueco; «intento» = un estado completo que el marco evalúa.

**R12. Referencia en mano.** `en_mano ∈ {ninguna, 1, 2, 3, 4}`. Es la referencia pulsada y aún sin soltar en un hueco; se muestra resaltada. **No es un cambio de colocación** (no emite `SFX_SLOT_IN`, no altera los huecos), pero **sí cuenta como «un cambio» para la comprobación retrasada** (regla 12b de 9: toda operación que cambia el estado de un elemento): seleccionar, deseleccionar o perder la referencia en mano reinicia la cuenta de 0,6 s de F1 de 9, y `evaluate()` devuelve `NONE` mientras `en_mano ≠ ninguna` (R21). Así el jugador que va a corregir la última referencia (dos pulsaciones, ≈ 0,8 s, más que `delay_s`) nunca recibe un rechazo a mitad de la corrección (F5). Una `cancelación` (cierre de la vista, `atrás`, pérdida de foco, pausa; regla 11b de 9) deja `en_mano` en `ninguna` **en silencio**, sin `REJECT` y sin evaluar en ese instante; si los cuatro huecos están llenos, ese cambio rearma la cuenta (si la vista sigue abierta; si se cerró, la rearma la reapertura, R41). Cuenta como acción de inactividad (F3 de 9) pero el P1 no tiene pistas `IDLE`.

**R13. Tabla de interacción (completa, sin huecos).** Cada fila es la respuesta del controlador a un `seleccionar` ya confirmado, con la vista abierta y con material:

| # | Pulsación sobre… | `en_mano` antes | Efecto en la colocación | `en_mano` después | Sonido |
|---|---|---|---|---|---|
| 1 | `ref_N` (esté en la hoja o colocada) | ninguna | ninguno | `N` | ninguno propio (responde el objeto, regla 11 de 7) |
| 2 | `ref_N` | `N` | ninguno | ninguna (se deselecciona) | ninguno |
| 3 | `ref_M` | `N` ≠ `M` | ninguno | `M` (cambia la selección) | ninguno |
| 4 | `slot_k` **vacío** | `N` | `sk = N`; si `N` ya estaba en `sj` (j ≠ k), `sj` queda vacío (**se mueve**, B.1) | ninguna | `SFX_SLOT_IN` |
| 5 | `slot_k` **lleno** (`sk = M`) | `N` | `sk = N`; si `N` estaba en `sj`, `sj = M` (**intercambio**); si `N` no estaba colocada, `M` vuelve a la hoja | ninguna | `SFX_SLOT_IN` |
| 6 | `slot_k` **lleno** | ninguna | `sk` queda vacío: la referencia vuelve a la hoja (B.1) | ninguna | ninguno (cambio visual) |
| 7 | `slot_k` **vacío** | ninguna | ninguno | ninguna | ninguno (7: `SIN_EFECTO`) |
| 8 | Fuera de todo elemento (hoja o fondo) | cualquiera | ninguno | ninguna | ninguno |
| 9 | Cualquier elemento, **con el puzle bloqueado** (R22/R25) | — | el evento se **descarta** (regla 14 de 9) | — | ninguno |

Notas: (a) una referencia colocada sigue siendo pulsable en la hoja (la hoja la muestra atenuada con el hueco que ocupa), lo que permite «mover» sin pasar por el hueco (fila 1 + fila 4/5); (b) no hay ninguna pulsación que borre más de un hueco; (c) las filas 4 y 5 son un **cambio de colocación** (un `elements_changed` y un cambio para F1 de 9); la 6 también; (d) cualquier combinación de filas es reversible: no existe estado sin salida (R39).

**R14. Geometría de referencia (‡ la fija 9 al dibujar, D9-49; 11 aporta las restricciones).** Viewport lógico 1920×1080 (regla 22 de 7):
- Hoja `C05/paper`: 1000×960 px a la izquierda; seis bloques de **150 px** de paso (cuatro líneas de 32 px = 128 px, F4 de 19), cabecera y pie incluidos en 960 px.
- `ref_N`: 112×56 px en el margen izquierdo de su bloque; **paso vertical entre chips ≥ 150 px**.
- `slot_k`: 160×160 px en fila a la derecha (x desde 1100), separación 40 px (paso 200 px): ancho de fila 760 px.
- Comprobaciones que 9 aplica al validar (regla 29 de 9): todos los elementos ≥ `pick_min_px` (44 px, mucho menor que 56 y 160); separación entre centros ≥ R₁+R₂ con R = min(max(64, tolerancia), 128) de la F5b de Entrada. El P1 **no declara `assist`** (solo P3 y P5) y sus elementos no tienen tolerancia propia: con R = 64 la separación mínima es 128 px (‡ 7: R = 64 para elementos sin tolerancia es la propuesta de 9, regla 4b-c, D9-78); margen: 22 px en los chips (150 frente a 128) y 72 px en los huecos (200 frente a 128). **Resuelto por 7 (AC-30b de 7):** la «tolerancia normal» se evalúa **por elemento** (64 px → umbral 128 px; a 170 px solo hay advertencia por la asistida de 256), de modo que los chips a 150 px y los huecos a 200 px pasan la validación sin excepción (antes OQ-8, ya no es pregunta; D11-17).
- `atraccion` (atracción asistida): verdadera en `slot_k`; la zona `ref_N` declara `atraccion_desactivada` = verdadero (nombre único de 7 y 9) **de forma definitiva** (D11-17): los chips miden 112×56 px y están separados 150 px, así que la asistencia aporta poco (y, con la asistida de 256 px, 150 px solo daría advertencia, AC-30b de 7). Consecuencia aceptada: con mando/stick el cursor no es atraído por las referencias, solo por los huecos; la regla 9 de 9 («referencias y huecos del P1») pide atracción en ambos y 9 debe aceptar la excepción por zona (Cambios requeridos).

**R15. Hueco de entrada.** El primer hueco en llegar a «lleno» no tiene orden obligatorio: el jugador puede rellenar H1–H4 en cualquier orden y reordenar hasta el último momento (Pilar *Autonomía como progresión*).

### D. La solución y su derivación

**R16. Solución.** La secuencia `solution.sequence = [2, 1, 3, 4]` (H1 = 2, H2 = 1, H3 = 3, H4 = 4; B.1). H1 es el primer envío cronológico.

**R17. Derivación (regla de diseño, no de código del controlador).** La secuencia correcta es el orden ascendente por **(día, hora de envío)** de los cuatro bloques con referencia, con `Lunes < Martes`:

| Ref. | Día | Enviado | Clave (día, hora) | Posición |
|---|---|---|---|---|
| 2 | Lunes | 09:14 | (1, 09:14) | H1 |
| 1 | Lunes | 11:40 | (1, 11:40) | H2 |
| 3 | Lunes | 16:02 | (1, 16:02) | H3 |
| 4 | Martes | 08:55 | (2, 08:55) | H4 |

Los dos bloques sin referencia (Lunes 10:30, Martes 14:00) no participan: no son pulsables ni colocables. **Los seis sellos son distintos** (sin empates: la ordenación es total).

**R18. Lecturas erróneas previstas (no se corrigen con texto).** Ordenar por número de referencia (`1·2·3·4`), por el orden de impresión (`3·1·4·2`) o solo por la hora sin el día (`4·2·1·3`) falla. Las tres lecturas se resuelven con lo que la hoja ya muestra (día y hora en cada bloque); ninguna recibe un rechazo distinto (R26: el rechazo no informa).

**R19. Fuente única y deriva de datos.** `solution.sequence` es dato de `puzzles.json` (regla 4 de 9), pero **debe coincidir con la derivación de R17 sobre los registros de 18**. Una prueba de datos (L) lo comprueba: calcula la ordenación a partir de `compose_i01()` y la compara con `solution.sequence`; si un correo cambia de hora en 18 y el puzle no se actualiza, falla la CI (AC-3). El controlador no deriva la solución en ejecución (regla 2 de 9: el marco no la conoce; la lee de los datos). El Pilar *Información incompleta* exige que los hechos sean fijos: ninguna hora depende del jugador (sin aleatoriedad en los datos de 18).

### E. Comprobación

**R20. Política.** `DELAYED_AFTER_CHANGE`, `delay_s` 0,6 s† (regla 12 y F1 de 9; rango 0,3–1,5). Con los cuatro huecos llenos y 0,6 s del `GameClock` sin **cambios** (de colocación o de `en_mano`, R12), el marco llama a `evaluate()` **una vez**. Con algún hueco vacío no se evalúa. Salir de la vista cancela la cuenta; al volver con los cuatro llenos se rearma otros 0,6 s (regla 21b y F1 de 9).

**R21. Veredictos de `evaluate()` (función pura del estado de colocación y de `solution`).**
- Estado completo y `S = [2,1,3,4]` → `SOLVED` (sin carga útil).
- Estado completo y `S ≠ [2,1,3,4]` → `REJECT` (con el scope «todos los huecos»; R26).
- Estado incompleto **o con `en_mano ≠ ninguna`** → `NONE` (la política no la llama con huecos vacíos, pero la función lo define: «nada que decir»; con una referencia en mano el jugador está corrigiendo). El P1 **no usa** `PARTIAL` ni `HOLDING`: devolver uno es un error de datos (regla 13 de 9). La razón es R26: ninguna información de acierto parcial.

**R22. Bloqueo.** El `REJECT` bloquea la entrada del puzle (`lock: PUZZLE`) durante `reset_after_s` = 1,5 s (≤ `lock_max_s` = 2,0 s, regla 14 de 9); los eventos de entrada en ese tiempo se **descartan** (R13 fila 9). El jugador vuelve a poder actuar 2,1 s después de su último clic (0,6 s de `delay_s` + 1,5 s de reset; AC-X2 de 9).

### F. Feedback de acierto y de error (sin castigo)

**R23. Cada acción procesada tiene respuesta visible en el mismo fotograma** (regla 13 de 9): seleccionar = resaltado de la referencia (R12); colocar = la referencia aparece en el hueco **con su sello (día y hora de envío, en pequeño, tomado de `compose_i01()`; propuesta D11-6, pendiente de confirmación, OQ-4)** y atenuada en la hoja + `SFX_SLOT_IN`; devolver = la referencia vuelve a la hoja (visual); `elements_changed` en cada cambio de forma (regla 9 de 9).

**R24. `SFX_SLOT_IN` lo pide el marco** (evento «feedback de puzle» `{puzzle:'P1', sound_id:'SFX_SLOT_IN', element:'C05/slot_k'}`) **por cada cambio que deja una referencia en un hueco** (filas 4 y 5 de R13), independientemente del veredicto. Se declara en datos como `on_change` ‡ (campo opcional nuevo del esquema; Cambios requeridos en 9). Los cambios que vacían un hueco (fila 6) no suenan (como en la regla 13b de 9: lo que disminuye no tiene sonido de acierto ni de rechazo).

**R25. Rechazo (`REJECT`).** Siempre y solo lo que dicta la regla 14 de 9: (a) `SFX_REJECT`; los cuatro huecos vibran `shake_s` = 1,2 s; (b) a `reset_after_s` = 1,5 s `reset_attempt` devuelve **todas** las referencias a la hoja (ninguna queda en un hueco; `en_mano = ninguna`); (c) entrada bloqueada 1,5 s; (d) nada más se toca (la hoja, las pistas alcanzadas y el estado público no cambian). Sin contador, sin límite de intentos, sin texto, sin cambio de dificultad, sin consecuencia en la historia. **Con `reducir_movimiento`** (regla 14b de 9): sin temblor; los cuatro huecos cambian de **tono** de forma estática durante `shake_s` (sin rojo ni verde: Pilar *Ambivalencia*, tabla de arte).

**R26. El rechazo no informa.** Todos los 23 estados completos incorrectos producen **el mismo** rechazo (mismo sonido, misma animación, mismo reset); no se indica qué huecos son correctos ni cuántos. Esto es deliberado: con feedback de acierto parcial, la fuerza bruta bajaría de 23 a ≤ 6 fallos en el peor caso y de 11,5 a 3 de media (F3) y el puzle dejaría de pedir la lectura (anti-degenerado, Pilar *Autonomía*). El jugador sabe *que* falló y *por qué* lo deduce de la hoja (Competencia).

**R27. Sin material.** `locked_feedback` por defecto: `SFX_CLICK_SUBTLE`, **sin texto** (regla 7 de 9; Tuning Knobs de 9). No se añade texto porque ninguna clave de 18 lo cubre y un texto de «te falta la hoja» sería dirección (Pilar *Autonomía*); la pista N1 es la ayuda (OQ-2).

### G. Pistas N1–N3 (enganche del sistema 17)

Tres niveles, todos `REQUEST` (los pide el jugador desde la pausa vía 17; **no** hay `IDLE` en el P1; regla 25 de 9). Ninguna mueve la cámara (decisión del usuario, D9-32; regla 14 de 2). Los niveles se acumulan: pedir un nivel no quita los anteriores. Las pistas **no** dan información nueva (§19.2 del slice): señalan lo que ya está.

**R28. N1 · resaltado.** `HIGHLIGHT` de `C05/paper`, 3,0 s (`highlight_s`), y **sin `I-01`** de `V08` (`targets_if_missing_items`). Sin clave de 18 (no textual). Es la única pista que orienta de verdad (B.1 confirmado en v0.4).

**R29. N2 · pie de la hoja.** `TEXT` con la clave **`PISTA_P1_N2`** de 18: «Ordena por hora de envío» (mismo texto del pie que 19 compone con `pie_ordena`; D18-3). **No añade información**: la hoja ya lo trae siempre (B.1 literal); aquí funciona como énfasis. La clave `PISTA_P1_N2` es la **única** clave `PISTA_*` del P1.

**R30. N3 · sellos de envío.** `HIGHLIGHT` de `C05/paper/stamp_1`…`stamp_4` (la línea de día y hora de los cuatro bloques numerados), 3,0 s. Sin clave de 18 (el dato lo sirve el registro del correo, regla 11 de 18). Tampoco añade información: la hoja ya muestra hora y día.

**R31. Rango efectivo de la escalera.** Por B.1 literal, N2 y N3 no añaden información sobre la hora de envío; solo N1 orienta. Aceptado por el usuario (v0.4); se registra como Open Question de playtest (OQ-1) por si el criterio 3 del slice (competencia) lo desmiente.

**R32. Interacción con el estado.** Una pista pedida con la vista cerrada se aplica al estado y se muestra la próxima vez que se abra (regla 26 de 9). Una pista pedida con P1 `RESUELTO` no se aplica (`request_hint` valida que el puzle esté `ACTIVO`, regla 26 de 9). Los `HIGHLIGHT` duran `duration_s` de reloj de juego (regla 36 de 9); en pausa no avanzan. `apply_hint_effect` devuelve `false` en P1 (ninguna pista cambia el estado de colocación, regla 12b de 9): ninguna pista resuelve nada por el jugador.

**R33. Límite conocido de N1 (OQ-3).** Con `I-01` ausente, N1 resalta `V08` aunque el jugador aún no haya leído los correos; 9 no lee `correos_leidos` (D9-50), así que no puede apuntar a `V01`. La respuesta de `V08` en ese caso (`OBJ_V08_SIN_RESULTADOS`, 19) hace el resto.

### H. Resolución, hechos y recompensa

**R34. Resolución `IMMEDIATE`** (regla 17 de 9). Al recibir `SOLVED` el marco, en el mismo fotograma y por este orden (regla 16 de 9):
1. Escribe `archivo_abierto = verdadero` (`on_solved.write`; también es el `solved_flag`).
2. Pasa `P1` a `RESUELTO` (idempotente: S9).
3. Emite `EV_PUZZLE_SOLVED_P1` con `{puzzle:'P1', rewards:[]}` (sin `choice`).
4. No emite «compartimento completado» (P1 no completa ninguno; sin `compartment`).
5. Pide `SFX_UNLOCK` (1,4 s) y llama a `play_resolution` (R35).
6. A `close_view_after_s` = 1,5 s pide `cerrar_vista('C05','resuelto')` (F4 de 9); la cámara vuelve en 0,5 s (`t_devolver`).

**R35. Presentación (no bloqueante).** Los huecos quedan fijos mostrando `2 · 1 · 3 · 4` con sus sellos (la cronología queda visible en fila incluso para quien llegó por tanteo; mitigación de D-W1, propuesta D11-6 pendiente, OQ-4; sin sellos, los huecos muestran solo la referencia) y con un cambio de tono estático (sin movimiento extra y **sin verde**: el acierto no se codifica como «bueno», Pilar *Ambivalencia*); la hoja permanece. Ningún hecho ni aviso espera a la presentación.

**R36. La puerta.** 8 reacciona al **hecho** `archivo_abierto` (no al aviso): al escribirse, la puerta A pasa a `ABRIÉNDOSE` en el mismo paso y reproduce `ANIM_DOOR_OPEN` (1,2 s); **no** reproduce `SFX_UNLOCK` (es de 9; regla 6 de 8). Con el cierre a 1,5 s y el regreso en 0,5 s, la puerta ya está abierta cuando el jugador vuelve a `exploración` (F4 de 9, ejemplo).

**R37. Recompensa.** `rewards: []`. La recompensa del P1 es **acceso** (la puerta A y, tras ella, el cajón `A05`). Las tarjetas `tarjeta_B` (`I-02`) y `tarjeta_D` (`I-03`) las recoge el jugador en `A05` y las escribe 20 (R10 de 20; 8). El §8 del slice dice «se entregan `tarjeta_B` y `tarjeta_D`»: se lee como «quedan al alcance» (D11-9).

**R38. Hechos que escribe 9 y quién los lee.** `archivo_abierto`: escribe 9 (único escritor); lee 8 (puerta A), 7 (`habilitado_si` de `C05`) y 20 (`A05` accesible).

**R39. Sin atasco (S1–S9 de 9 instanciados).** (S1) no hay estado de fallo: desde cualquier `S` el jugador puede llegar a `[2,1,3,4]` con acciones R13; (S3) ningún reloj exige nada; (S4) `atrás` cierra la vista siempre; (S6) `I-01` es recuperable y repetible; (S7) cubierto por el oráculo de la regla 30 de 9 (AC-12); (S9) un solo acierto.

### I. Cargar, cerrar y guardar

**R40. Cerrar la vista (`on_close(motivo)`).** `KEEP` con cualquier motivo (regla 21b de 9): se conservan las colocaciones; se descartan `en_mano` (cancelación en silencio) y la comprobación retrasada pendiente. Si el feedback de rechazo estaba en curso, se completa al instante (regla 21b).

**R41. Reabrir con P1 `ACTIVO`.** Las colocaciones previas se mantienen y la hoja se reconstruye con `compose_i01()` (R7). Con los cuatro huecos llenos se rearma la cuenta de 0,6 s (R20).

**R42. Reabrir con P1 `RESUELTO`.** No se puede por la vía normal (R6). Si otra vía (consola, orden de 21) abre `C05`, el marco lo cierra de inmediato (`cerrar_vista('C05','sistema')`) sin escribir (regla 35 de 9).

**R43. Cargar.** Con `archivo_abierto` verdadero: `P1` queda `RESUELTO` en silencio (sin `SFX_UNLOCK`, sin aviso; regla 8 de 9) y la puerta A ya abierta (8). Con `archivo_abierto` falso: `P1` `ACTIVO`, **todas las colocaciones vacías**, `I-01` **ausente** del bolsillo aunque `correos_leidos` sea verdadero (R9 de 20, AC-39b de 9): el jugador imprime de nuevo (repetible, R24 de 19) y la hoja se reconstruye idéntica.

**R44. Qué se guarda.** Solo el hecho `archivo_abierto` (por la regla 22 de 9). Las colocaciones, `en_mano` y la hoja **no** se guardan: rehacerlo no cuesta nada (Pilar *Tensión sin castigo*). El nivel de pista alcanzado es solo de memoria (regla 26 de 9).

**R45. Reevaluación inicial.** El P1 no es `ON_CHANGE`: no hay reevaluación al configurarse (regla 8 de 9). Un estado completo en memoria no puede existir tras cargar (R43).

### J. Lo que P1 no hace

**R46.** Sin contador de intentos, sin «has fallado N veces», sin límite, sin enfriamiento acumulativo, sin temporizador de solución, sin indicador de «casi», sin valoración de ningún correo (R29 de 19), sin ordenación automática de la hoja (PA-6 de 19) y sin botón «ordenar por hora» (regalaría la solución). Las intenciones de «G.» o de «Dirección» no se confirman en ningún texto del puzle (Pilar *Información incompleta*; anti-pilar «historia explicada»).

## Formulas

Valores marcados † = hipótesis de diseño **sin medir** (no hay datos de playtest; el registro de la regla 32 de 9 los contrastará). Constantes de partida: `t_clic` = 0,4 s† (F6 de 9), `delay_s` = 0,6 s, `reset_after_s` = 1,5 s, `shake_s` = 1,2 s, `n` = 4 huecos.

### F1 · Espacio de estados y de intentos

`E = Σ_{k=0..n} C(n,k) · P(n,k)`  con `P(n,k) = n!/(n−k)!` · estados completos `n! `

**Variables:** `n` = 4 (huecos = referencias numeradas; entero fijo del slice). **Rango de salida:** `E` ∈ ℕ.
**Cálculo:** k=0: 1; k=1: 4·4 = 16; k=2: 6·12 = 72; k=3: 4·24 = 96; k=4: 1·24 = 24 → **E = 209**; completos = 4! = **24**; evaluables con acierto = **1**. Probabilidad de acertar a ciegas en el primer intento = 1/24 = **4,17 %**.

### F2 · Coste de la fuerza bruta (instancia de F6 de 9)

`t_fallo = n_clics·t_clic + delay_s + reset_after_s`  ·  `t_acierto = n_clics·t_clic + delay_s`  ·  `n_clics = 2n = 8`

Tras un `REJECT` **todas** las referencias vuelven a la hoja (R25), así que cada intento parte de cero: 8 pulsaciones (referencia + hueco, cuatro veces).

| Magnitud | Cálculo | Resultado |
|---|---|---|
| `t_fallo` | 8·0,4 + 0,6 + 1,5 | **5,3 s** |
| `t_acierto` | 8·0,4 + 0,6 | **3,8 s** |
| Peor caso sin repetir (tanteo sistemático, N = 24) | 23·5,3 + 3,8 | 121,9 + 3,8 = **125,7 s** (F6 de 9 cita 122 s hasta el último fallo) |
| Media sin repetir | ((24−1)/2)·5,3 + 3,8 = 11,5·5,3 + 3,8 | 60,95 + 3,8 = **64,8 s** |
| Media con repetición (jugador sin memoria: geométrica p = 1/24, 23 fallos esperados) | 23·5,3 + 3,8 | **125,7 s** |
| Quien ya sabe que el 4 (martes) va último (N = 3! = 6) | peor 5·5,3 + 3,8; media 2,5·5,3 + 3,8 | **30,3 s** / **17,1 s** |

**Lectura (D-W1 y D-W4 de las revisiones cruzadas).** El tanteo cuesta ≈ 1 a 2 min y **sigue exigiendo antes** leer los correos y reimprimir (la hoja solo existe si se ha buscado «transición»). No se bloquea (anti-pilar de castigo; Pilar *Tensión sin castigo*): es una consecuencia aceptada **a medir**. Mitigación barata (propuesta D11-6, pendiente de confirmación, OQ-4; sin ella el tanteo es igual de caro pero no deja la cronología a la vista): los huecos muestran el sello de cada referencia, de modo que quien acierta por tanteo ve la cronología en fila al resolver. **Umbral de revisión (†):** si en playtest la mediana de rechazos por jugador es ≥ 6 (≈ un barrido de tanteo), se reabre R26 y la decisión de D11-6 antes del hito.

### F3 · Contrafactual: por qué el rechazo no informa (R26)

Si el rechazo indicara qué huecos son correctos, el jugador fijaría un hueco tras otro: fallos esperados = (0+1+2+3)/4 + (0+1+2)/3 + (0+1)/2 + 0 = 1,5 + 1,0 + 0,5 = **3,0**; peor caso = 3+2+1 = **6** (frente a 11,5 y 23). Con el diseño actual (sin información parcial) el tanteo no mejora con los intentos: cada fallo elimina una de las 24 combinaciones y nada más.

### F4 · Tiempo esperado de resolución frente a F7 de 9 (objetivo 2–4 min†)

`T = T_leer + T_trayectos + T_ordenar + T_fallos + T_desvío + T_cierre`   (segundos; jugador nuevo)

| Componente | Qué incluye | Bajo | Central | Alto |
|---|---|---|---|---|
| `T_leer` | abrir `V01`, buscar «transición», leer resultados (19) | 45 | 65 | 90 |
| `T_trayectos` | `V01`→`V08` (8/11/15) + imprimir y recoger (4/6/8) + `V08`→`C05` (12/18/25) + apertura de vista (1,0) | 25 | 36 | 49 |
| `T_ordenar` | leer la hoja y deducir (20/40/60) + 8 pulsaciones (3,2) + comprobación (0,6) | 23,8 | 43,8 | 63,8 |
| `T_fallos` | `E[rechazos]` · (`t_fallo` 5,3 + repensar 10): 0 / 0,7 / 1,5 rechazos | 0 | 10,7 | 23,0 |
| `T_desvío` | ir a `C05` sin hoja, volver a buscarla (R7, S6) | 0 | 20 | 45 |
| `T_cierre` | `close_view_after_s` 1,5 + `t_devolver` 0,5 | 2 | 2 | 2 |
| **Total** | suma | **95,8 s = 1,6 min** | **177,5 s = 2,96 min** | **272,8 s = 4,55 min** |

La **central (≈ 3,0 min) cae dentro de 2–4 min**; los extremos son la suma de todos los extremos a la vez (pesimista/optimista) y se salen por poco a ambos lados. Tiempo dentro de `C05` solamente (`T_ordenar + T_fallos + T_cierre`, central) = **56,5 s**. Criterio de revisión (†): mediana de playtest > 4 min → revisar `T_leer` (19, no 11) y la ayuda de N1; < 2 min → no es un problema (el primer puzle debe ser amable), solo se anota.

### F5 · Ventana de corrección (por qué `en_mano` suspende la comprobación)

`t_corregir = 2·t_clic = 0,8 s  >  delay_s = 0,6 s`

Corregir una referencia colocada exige dos pulsaciones (referencia + hueco). Con `delay_s` = 0,6 s contado desde el último cambio y sin R12, el marco evaluaría a mitad de la corrección. Con R12 la **selección** es un cambio que reinicia la cuenta y `evaluate()` devuelve `NONE` mientras haya referencia en mano: la comprobación solo ocurre con los cuatro huecos llenos, sin referencia en mano y 0,6 s de calma. **Ejemplo:** los huecos se completan en t = 10,00 (4.º `SFX_SLOT_IN`); en t = 10,35 el jugador pulsa la referencia del H3 (en mano) → la cuenta se reinicia y a t = 10,95 el marco llama a `evaluate()` → `NONE` (en mano); en t = 11,20 la coloca en H4 (intercambio, fila 5) → nueva cuenta, `t_comprobar` = 11,80 → si `S = [2,1,3,4]`, `SOLVED`; si no, `REJECT` y bloqueo hasta 13,30.
**Rango de `delay_s`:** 0,3–1,5 s (9). Por debajo de 0,4 s la pulsación de corrección de un jugador rápido cae fuera; por encima de 1,0 s la respuesta se siente lenta (anclaje: AC-X2 de 9, 2,1 s hasta poder actuar tras el último clic).

### F6 · Márgenes de geometría (R14)

`margen_chip = paso_chip − (R₁+R₂) = 150 − 128 = 22 px`  ·  `margen_hueco = 200 − 128 = 72 px`  ·  `R = min(max(64, tol), 128) = 64` con `tol` = 0 (sin `assist`, el P1 no tiene tolerancia espacial; la tolerancia se evalúa por elemento, AC-30b de 7; D11-17)

**Rangos válidos:** `paso_chip ≥ 128 px`; `paso_hueco ≥ 128 px`; tamaño ≥ `pick_min_px` = 44 px (chips 112×56 y huecos 160×160 lo cumplen con holgura). Bloque de 4 líneas: 4·32 = 128 px ≤ paso 150 px (22 px de aire). Altura total: 6·150 + cabecera y pie = 960 px ≤ 1080 px.

### F7 · Orden cronológico (R17)

`clave(b) = (dia_orden(b), minutos(hh:mm(b)))`, orden lexicográfico ascendente sobre los bloques con `ref ≠ null`; `solution.sequence = [ref(b₁), …, ref(b₄)]`.
**Ejemplo:** (1, 554) → ref 2; (1, 700) → ref 1; (1, 962) → ref 3; (2, 535) → ref 4 → **`[2, 1, 3, 4]`**. (09:14 = 554 min; 11:40 = 700; 16:02 = 962; 08:55 = 535.) Sin el día: 535 < 554 < 700 < 962 → `[4, 2, 1, 3]` (la lectura errónea R18).

## Edge Cases

Cada caso dice qué ocurre, no «se gestiona».

**Material y apertura**
- **Abrir `C05` sin `I-01`** (antes de imprimir o tras cargar con `correos_leidos` verdadero): la vista se abre con los huecos vacíos y sin hoja; pulsar un hueco = `SFX_CLICK_SUBTLE`, sin texto; no se escribe nada; el puzle sigue `ACTIVO` (R7, AC-5). La salida es siempre posible (`atrás`).
- **`I-01` conseguida con la vista cerrada:** la siguiente apertura llama a `compose_i01()` y dibuja la hoja; las colocaciones previas (ninguna, porque sin hoja no se puede colocar nada) están vacías.
- **Cargar con `correos_leidos` verdadero:** `I-01` no está (R9 de 20); `V08` nace en `lista`; el jugador reimprime (repetible, sin tope; R24 de 19) y la hoja es idéntica (función pura, AC-29 de 19). No se salta la impresión ni queda atasco (S6; AC-39b de 9).
- **`compose_i01()` devuelve ≠ 4 bloques con `ref`** (correo ausente o ilegible; R30 de 19: el bloque se omite con «—»): el marco registra un error de datos y trata la vista como **sin material** (AC-21). Es un defecto de datos que **debe** atraparlo también la prueba AC-3 en CI (no es alcanzable por el jugador); no hay solución de ejecución que invente una referencia (Pilar *Información incompleta*: hechos fijos).
- **Hora o día repetidos entre bloques con referencia:** la validación de datos (AC-3) lo rechaza; no existe empate en producción (R17).

**Interacción**
- **Doble pulsación sobre la misma referencia:** fila 1 y fila 2 de R13 (selecciona y deselecciona). Sin efecto neto, sin sonido.
- **Pulsar el hueco que ya contiene la referencia en mano** (fila 5 con `M = N`): `sk` no cambia, `en_mano` pasa a `ninguna`; cuenta como cambio de `en_mano` (rearma la cuenta si los cuatro están llenos); sin `SFX_SLOT_IN` (no hay cambio de colocación).
- **Pulsar durante el bloqueo del rechazo (1,5 s):** el evento se descarta, no se encola (regla 14 de 9); nada se coloca «con retraso».
- **`cancelación` con una referencia en mano** (cierre, `atrás`, pérdida de foco, pausa): `en_mano = ninguna` en silencio; sin `REJECT`, sin evaluar (regla 11b de 9; AC-9).
- **Cerrar la vista durante la comprobación retrasada (0,6 s):** se cancela; al volver con los cuatro huecos llenos se rearma otros 0,6 s (F1 de 9; R41).
- **Cerrar la vista durante el rechazo:** el feedback se completa al instante y el `reset_attempt` se aplica ya (regla 21b de 9): al volver, hoja con todas las referencias sin colocar.
- **Pausa durante la cuenta, el rechazo o un `HIGHLIGHT`:** el `GameClock` se detiene (regla 36 de 9); no corre nada hasta reanudar.
- **`atrás` y acierto a la vez:** 7 ignora la segunda petición de cierre (regla 33 de 9).
- **`reducir_movimiento` cambia durante un rechazo:** afecta al siguiente (regla 14b de 9).
- **Mando / stick:** `slot_k` tiene atracción asistida y `ref_N` declara `atraccion_desactivada` (R14, D11-17); el gesto es un `seleccionar` sin mantener ni arrastrar, accesible con un solo botón; no hay ninguna acción solo-ratón.

**Estado y persistencia**
- **Estado completo con `S = [2,1,3,4]` pero el jugador sale antes de 0,6 s:** no se resuelve en ese instante; al reabrir se rearma y se resuelve a los 0,6 s (no hay estado sin salida).
- **Dos `SOLVED` en el mismo fotograma:** se descarta el segundo (S9 de 9).
- **`archivo_abierto` forzado a verdadero por consola/21 con la vista abierta:** el marco reconcilia a `RESUELTO` en silencio, sin `EV_PUZZLE_SOLVED_P1` (regla 31 de 9) y cierra la vista con motivo `sistema`.
- **Reabrir `C05` con P1 `RESUELTO` por otra vía:** cierre inmediato con motivo `sistema`, sin escritura (R42).
- **Pedir una pista con P1 `RESUELTO`:** `request_hint` no la aplica (regla 26 de 9).
- **Pista N1 con `I-01` ausente y `correos_leidos` falso:** resalta `V08`, que responde `OBJ_V08_SIN_RESULTADOS` (19); no mueve al jugador a `V01` (OQ-3).
- **Pista pedida con la vista cerrada:** se muestra en la siguiente apertura (regla 26 de 9).

**Estrategias degeneradas (Sirlin, *Playing to Win*) y su tratamiento**
| Estrategia | Por qué es (o no) un problema | Tratamiento |
|---|---|---|
| **Tanteo de las 24 permutaciones** | 65–126 s de media (F2); no mejora con los intentos (F3); salta la deducción, no la lectura (hay que buscar e imprimir antes). Falla D-W1 de las revisiones cruzadas | **Aceptada y medida** (regla 32 de 9: rechazos por jugador; umbral de revisión de F2). Mitigación D11-6 (sellos en los huecos) |
| **Ordenar por número (`1·2·3·4`) o por orden de impresión (`3·1·4·2`)** | Lecturas erróneas deducibles; fallan | Ninguna (el rechazo es idéntico, R26); la hoja trae todo (R18) |
| **Ordenar solo por la hora, sin el día (`4·2·1·3`)** | Es la «arruga» deliberada del puzle (R18) | La hoja muestra el día en cada bloque; no hay texto que lo explique (Pilar *Autonomía*) |
| **Soluciones copiadas de una guía** | La solución es fija (Pilar *Información incompleta*) | Aceptada: el contenido narrativo (los correos) ya se leyó antes |
| **Imprimir muchas veces** | Sin coste ni efecto (19, R24) | Nada que prevenir |
| **Entrar y salir de la vista para «reiniciar»** | Las colocaciones se conservan (R40): no sirve para nada | Ninguno |

## Dependencies

La dureza de cada dependencia la declara **el dependiente** (regla de `.claude/rules/design-docs.md`); aquí, 11 declara las suyas, y las filas «lo consume» las declaran los otros GDD (se repiten solo como contraparte). Una sola pareja por fila.

**11 depende de (declaradas por 11):**

| Sistema | Dureza | Qué recibe 11 | Contrato / regla |
|---|---|---|---|
| **9 Marco de puzles** | **Dura** | Ciclo de vida, `evaluate()` temporizado (`DELAYED_AFTER_CHANGE`), política de fallo, escritura de `archivo_abierto`, aviso `EV_PUZZLE_SOLVED_P1`, `needs_items`/`missing_items` (lista), API de pistas, cierre de vista, gestos de 7 | Reglas 4–7, 9–14b, 16, 21, 25–26, 28, 29, 33–36 de 9; F1, F4, F6, F7 de 9; AC-06, AC-07, AC-18, AC-39, AC-39b |
| **19 Ordenador, correo e impresora** | **Dura** | `compose_i01() → SheetI01` (bloques, `ref`, `dia`, `hora_envio`, `hora_visible`, `pie_ordena`); impresión repetible; `V08` objetivo resaltable por ID | R20, R23, R24, R26–R28, R30 de 19; AC-16, AC-23, AC-29 de 19. Sin ella el P1 no tiene material |
| **20 Documentos y bolsillo** | **Dura** (sin `has_item("I-01")` el puzle no distingue si hay material; la consulta pasa por 9, regla 34 de 9, que declara su propia pareja 9 → 20 como blanda) | `has_item("I-01")` (conjunto de sesión, `Relegible = No`), vía 9 | R8, R9, F3 de 20 |
| **18 Base de contenido narrativo** | **Dura en validación** | Registros de los 6 correos (día, hora, cuerpo, firma), clave `PISTA_P1_N2`, cabecera `DOC_I01` | Reglas 11 y 20 de 18; D18-3, D18-17, D18-23 |

**Lo consumen / actúan con 11 (contraparte; lo declaran ellos):**

| Sistema | Naturaleza | Qué recibe de 11 o del marco gracias a 11 |
|---|---|---|
| **8 Control de acceso** | blanda (la declara 8) | Hecho `archivo_abierto` (escrito por 9 por el veredicto de 11); abre la puerta A (regla 6 de 8) |
| **7 Interacción e inspección** | la declara 7 | `elements()` de `C05` (`C05/paper/ref_N`, `C05/slot_k`), `elements_changed`; vista `C05` con `habilitado_si: ninguno [archivo_abierto]` |
| **17 Sistema de pistas** (futuro) | blanda | N1–N3 vía `get_hints('P1')`/`request_hint('P1', n)`; no hay `IDLE` en el P1; R26 de 19: `V08` objetivo |
| **20 Documentos y bolsillo** | contraparte | A `A05` se accede tras la puerta A; el P1 **no** da `rewards` (R37) |
| **3 Estado y bus** | la declara 3 | `archivo_abierto` (owner 9); `EV_PUZZLE_SOLVED_P1` |
| **5 Guardado y carga** | indirecta | `archivo_abierto` y la causa `puzzle_solved:P1` |
| **6 Ajustes** | blanda | `reducir_movimiento` (R25) |
| **23 Audio** | blanda | `SFX_SLOT_IN`, `SFX_REJECT`, `SFX_UNLOCK`, `SFX_CLICK_SUBTLE` por «feedback de puzle» |
| **2 Jugador** | indirecta (vía 7) | Sin gesto de cámara de pista (D9-32); `HAND_POINT` dentro de la vista |
| **Datos (`assets/data/puzzles/puzzles.json`)** | — | La entrada `P1` de «Datos del puzle» |

Tablas de los GDD ya existentes que 11 reciproca: matriz de encaje y filas de 19/20/8 de `marco-de-puzles.md`; R26–R28 y R30 de 19; D19-11; R9 de 20; D18-3; catálogo `C05` de 7 (D7-42, D7-59, D7-61). Lo que **no** cierra 11 en esos GDD está en «Cambios requeridos en otros GDDs».

## Tuning Knobs

Todos viven en datos externos, nunca en el controlador (estándar de `coding-standards.md`): los de tiempo y feedback en la entrada `P1` de `assets/data/puzzles/puzzles.json` (sección «Datos del puzle»); los de geometría en el fichero de la vista de `C05` que fija 9 (D9-49; `assets/data/puzzles/p1_view.json` ‡). † = valor propuesto, a validar en playtest. Categorías: **F**eel / **C**urve / **G**ate.

| Knob | Cat. | Defecto | Rango seguro | Qué afecta y por qué ese valor |
|---|---|---|---|---|
| `validation.delay_s` | F | **0,6 s†** | 0,3–1,5 | Pausa antes de evaluar con los cuatro llenos y sin referencia en mano. < 0,4: el jugador rápido no llega a corregir; > 1,0: respuesta lenta (F5). Valor de B.1 |
| `on_reject.shake_s` | F | **1,2 s** | 0,6–2,0 | Duración de la vibración (o del cambio de tono con `reducir_movimiento`). B.1 |
| `on_reject.reset_after_s` | F | **1,5 s** | 0,6–2,0 (≤ `lock_max_s` 2,0 s, validado por 9) | Cuándo vuelven las referencias a la hoja y cuánto dura el bloqueo. Ajusta el coste de la fuerza bruta (F2: +0,1 s ≈ +2,3 s de peor caso) |
| `on_solved.sfx_s` (`SFX_UNLOCK`) | F | **1,4 s** | 0,8–2,5 | Duración del sonido de acierto (B.1) |
| `on_solved.close_view_after_s` | F | **1,5 s†** | 0,5–3,0 | Tiempo que el jugador ve el resultado antes del cierre; debe permitir ver los sellos en fila (D11-6); < 1,0 s los esconde |
| `hints[0].effects[0].duration_s` (N1) | F | **3,0 s** (`highlight_s` de 9) | 1,5–5,0 | Duración del resaltado de N1 (B.1) |
| `hints[2].effects[0].duration_s` (N3) | F | **3,0 s†** | 1,5–5,0 | Duración del resaltado de los sellos; igual que N1 por coherencia |
| `ui.show_stamp_in_slot` | C | **verdadero†** (propuesta pendiente, OQ-4) | bool | Muestra día y hora bajo cada referencia colocada (D11-6). Falso = B.1 estricto sin sello; sube la dificultad y quita la mitigación de D-W1 |
| `ui.chip_pitch_px` | F | **150 px** | ≥ 128 (R₁+R₂, F6) | Paso vertical entre referencias; define el tamaño del bloque (4 líneas = 128 px) |
| `ui.slot_pitch_px` | F | **200 px** | ≥ 128 | Paso entre huecos |
| `ui.slot_size_px` / `ui.chip_size_px` | F | **160×160 / 112×56** | ≥ `pick_min_px` 44 | Objetivos de pulsación (accesibilidad motriz) |
| `i01_hora_visible`, `i01_pie_ordena_visible` (datos de **19**) | C | **verdadero / verdadero** (B.1 literal, no se toca) | bool | Si la hoja lleva hora y pie. Falsos = versión sin B.1 (N2/N3 recuperan función); 11 no los modifica |
| Umbral de revisión de fuerza bruta | C | **6 rechazos (mediana)†** | 4–10 | Criterio de playtest de F2; no es un valor de juego |

**Constantes fijas (no son knobs):** `n` = 4 huecos y 4 referencias (el slice, B.1); la secuencia `[2,1,3,4]` (R19: derivada de 18); `requires.all` vacío; sin reglas de tiempo de solución (S3 de 9); 3 niveles de pista (regla 27 de 9). Ningún knob de P1 es de categoría **Gate** (el puzle no depende de otros ni tiene reloj).

## Acceptance Criteria

Tipos: **L** = lógica (prueba automática con reloj falso, `tests/unit/puzzle_1/`), **I** = integración (`tests/integration/puzzle_1/` o playtest documentado), **PV** = playtest/visual (captura retenida en `production/qa/evidence/`; `qa.level` no exime de la captura). Todos GIVEN/WHEN/THEN y verificables por QA.

**Estado y apertura**
- **AC-1 (R5, R6, L):** **GIVEN** una partida nueva, **THEN** `P1` está `ACTIVO`, `archivo_abierto` falso, los cuatro huecos vacíos y `en_mano = ninguna`; `C05` es objetivo en 7; **GIVEN** `archivo_abierto` verdadero, **THEN** `C05` no es objetivo (sin icono ni vista) y `P1` está `RESUELTO`.
- **AC-2 (R7, I):** **GIVEN** `has_item("I-01")` verdadero, **WHEN** se abre `C05`, **THEN** el marco llama una vez a `compose_i01()`, `elements()` contiene exactamente 4 `C05/paper/ref_N` (N = 1..4), 4 `C05/slot_k` y la hoja muestra los 6 bloques en orden `3,1,4,2` con los dos de ruido sin referencia; **WHEN** se cierra y reabre, **THEN** se llama de nuevo y el resultado es idéntico.
- **AC-3 (R17, R19, L):** **GIVEN** `compose_i01()` con los datos de 18, **WHEN** una prueba ordena los bloques con `ref` por el campo entero `ts_envio` de `compose_i01()` (minutos desde el lunes 00:00; sin analizar texto; Cambios requeridos en 19), ascendente, **THEN** el resultado es `[2,1,3,4]` y coincide con `solution.sequence` de `puzzles.json`; **WHEN** se cambia la hora de `MAIL_2` en 18 a «17:00» sin tocar `puzzles.json`, **THEN** la prueba falla; **GIVEN** dos bloques con `ref` con el mismo sello, **THEN** la validación de datos falla (sin empates).
- **AC-21 (R7, L):** **GIVEN** `has_item("I-01")` verdadero y un doble de `compose_i01()` que devuelve 3 (o 5) bloques con `ref` ≠ null, **WHEN** se abre `C05`, **THEN** se registra un error de datos, la vista se abre como sin material (4 huecos vacíos, 0 referencias, `SFX_CLICK_SUBTLE` al pulsar un hueco), no se escribe ningún hecho y `atrás` cierra la vista.
- **AC-5 (R7, R27, S6, L):** **GIVEN** `has_item("I-01")` falso, **WHEN** se abre `C05`, **THEN** hay 4 huecos vacíos y 0 referencias; **WHEN** se pulsa un hueco, **THEN** suena `SFX_CLICK_SUBTLE`, no hay texto, no se escribe ningún hecho y el puzle sigue `ACTIVO`; **WHEN** se pulsa `atrás`, **THEN** la vista se cierra.

**Interacción**
- **AC-4 (R13, L):** **GIVEN** cada fila de la tabla de R13 (con `en_mano` y colocación de partida indicadas), **WHEN** llega el `seleccionar`, **THEN** el estado resultante es el de la tabla, incluidas la mudanza (fila 4), el intercambio (fila 5), «misma referencia en el mismo hueco» (sin cambio de colocación) y el descarte en bloqueo (fila 9); en ninguna fila quedan dos huecos con la misma referencia ni se pierde una referencia.
- **AC-9 (R12, R40, L):** **GIVEN** una referencia en mano, **WHEN** llega `cancelación` (cierre, `atrás`, pérdida de foco o pausa), **THEN** `en_mano = ninguna`, no hay `REJECT`, no suena nada y no se evalúa en ese instante; **GIVEN** cuatro huecos llenos y la vista abierta, **THEN** la cuenta se rearma a 0,6 s.
- **AC-16 (R24, L):** **GIVEN** cualquier acción de las filas 4 o 5 de R13, **THEN** se emite una sola vez «feedback de puzle» con `SFX_SLOT_IN` y el hueco; **GIVEN** la fila 6, **THEN** no se emite sonido.

**Comprobación y rechazo**
- **AC-6 (R20, R12, F5, L):** **GIVEN** el `GameClock` falso y P1 con material, **WHEN** los cuatro huecos se llenan en t = 10,00 y el jugador **selecciona** la referencia de H3 en t = 10,40 (primera pulsación, `en_mano`) y la **coloca** en otro hueco en t = 10,80 (segunda pulsación; R12: cada una reinicia la cuenta), **THEN** no se llama a `evaluate()` en t = 10,60 ni en t = 11,00 (la cuenta de 10,00 y la de 10,40 quedan canceladas por el cambio siguiente) y se llama **una sola vez** en t = 11,40 (10,80 + 0,6); **WHEN** en cambio sale de la vista en t = 10,70 con la referencia en mano, **THEN** `en_mano = ninguna`, no se evalúa y al volver con los cuatro llenos se rearma 0,6 s. (La corrección completa con `NONE` intermedio: AC-7.)
- **AC-7 (R12, R21, F5, L):** **GIVEN** los cuatro huecos llenos con un estado incorrecto y el jugador pulsa una referencia en t = 0,35 s tras el 4.º hueco, **THEN** a los 0,95 s `evaluate()` devuelve `NONE` (en mano) y no hay rechazo; **WHEN** coloca la referencia a los 1,20 s, **THEN** nueva evaluación a 1,80 s.
- **AC-8 (R25, R22, L):** **GIVEN** `S = [1,2,3,4]` completo, **WHEN** el marco evalúa, **THEN** `REJECT`: `SFX_REJECT`, los cuatro huecos vibran 1,2 s, a los 1,5 s las cuatro referencias vuelven a la hoja, la entrada del puzle queda descartada 1,5 s y después acepta entrada; no existe contador de fallos, ni texto, ni hecho cambiado, y el nivel de pista alcanzado no varía.
- **AC-10 (R26, L):** **GIVEN** los 23 estados completos incorrectos, **WHEN** se evalúa cada uno, **THEN** los 23 producen veredicto, sonido, animación y duración idénticos y ninguno lleva información de qué hueco es correcto.
- **AC-17 (R25, L; AC-52 de 9):** **GIVEN** `reducir_movimiento` activo, **WHEN** P1 rechaza, **THEN** no hay temblor, los huecos cambian de tono estático durante 1,2 s y el bloqueo dura lo mismo; **GIVEN** un cambio del ajuste durante un rechazo en curso, **THEN** no afecta al en curso y sí al siguiente.

**Resolución**
- **AC-11 (R34, L):** **GIVEN** `S = [2,1,3,4]` y 0,6 s de calma, **THEN**, en el mismo fotograma y por este orden: `archivo_abierto` = verdadero, `P1` `RESUELTO`, `EV_PUZZLE_SOLVED_P1` con `rewards: []` (una vez), ningún aviso «compartimento completado», `SFX_UNLOCK` 1,4 s; a 1,5 s `cerrar_vista('C05','resuelto')`; un segundo `SOLVED` se descarta.
- **AC-15 (R36, I):** **GIVEN** 8 y 9 reales, **WHEN** se escribe `archivo_abierto`, **THEN** la puerta A inicia `ANIM_DOOR_OPEN` en ese mismo paso, 8 no reproduce `SFX_UNLOCK` y, al volver la cámara (t = 2,0 s), la puerta está abierta; **GIVEN** `archivo_abierto` ya verdadero al cargar, **THEN** `P1` es `RESUELTO` sin `SFX_UNLOCK` ni aviso.
- **AC-12 (R39, S7, L; regla 30 de 9):** **GIVEN** 1.000 secuencias aleatorias de acciones válidas (R13, pistas de cualquier nivel, cancelaciones, cerrar y reabrir, guardar y cargar), **WHEN** el solucionador independiente (código de test que conoce la solución de los datos y `elements()`) la reproduce desde cada estado por `handle_pointer`, **THEN** siempre llega a `RESUELTO` y escribe `archivo_abierto`, y ningún hecho inválido.

**Pistas**
- **AC-13 (R28–R32, L):** **GIVEN** el JSON de P1, **THEN** declara exactamente tres niveles `REQUEST`; N1 = `HIGHLIGHT` de `C05/paper` con `targets_if_missing_items: ["V08"]` y 3 s; N2 = `TEXT` con la clave `PISTA_P1_N2` (existe en 18); N3 = `HIGHLIGHT` de `C05/paper/stamp_1..4` sin clave; **WHEN** se pide N1 sin `I-01`, **THEN** se resalta `V08` y no se mueve la cámara; **WHEN** se pide cualquier nivel con P1 `RESUELTO`, **THEN** no se aplica; **THEN** ningún nivel cambia `en_mano` ni los huecos (`apply_hint_effect` = `false`).

**Cargar, cerrar y guardar**
- **AC-14 (R43, R44, I; AC-39b de 9):** **GIVEN** una partida guardada con `correos_leidos` verdadero y `archivo_abierto` falso, **WHEN** se carga, **THEN** P1 `ACTIVO`, huecos vacíos, `has_item("I-01")` falso; **WHEN** el jugador imprime de nuevo en `V08`, **THEN** P1 es resoluble y la hoja es idéntica; el guardado no contiene colocaciones ni `en_mano`.
- **AC-20 (R40, R41, L):** **GIVEN** dos huecos llenos, **WHEN** se cierra y reabre la vista, **THEN** los dos siguen llenos, `en_mano = ninguna` y la hoja se reconstruye con `compose_i01()`.

**Datos y geometría**
- **AC-18 (R14, F6, L):** **GIVEN** el fichero de vista, **THEN** todos los elementos ≥ 44 px, la separación entre centros de `ref_N` ≥ 128 px y de `slot_k` ≥ 128 px (valores por defecto: 150 y 200), y la zona `ref_N` declara `atraccion_desactivada` = verdadero y `slot_k` no (D11-17).
- **AC-19 (Datos del puzle, L; regla 29 de 9):** **GIVEN** la entrada `P1`, **THEN** pasa la validación de 9 (tres niveles de pista, `needs_items` existe en el catálogo de ítems, `reset_after_s` ≤ 2,0 s, `solution` no satisfecha por el estado inicial, `solved_flag` declarado en `flags.json`, enteros como `int`).

**Experiencia (playtest)**
- **AC-PV1 (F4, PV):** **GIVEN** ≥ 6 jugadores nuevos, **THEN** la **mediana** del tiempo total del P1 (desde el primer correo hasta `archivo_abierto`) está en 2–4 min (F7 de 9) con el registro de la regla 32 de 9; si no, se aplican los criterios de revisión de F4.
- **AC-PV2 (R25, R46, PV):** **GIVEN** 6 testers que han fallado el P1, **THEN** 0 de 6 describen el fallo como «castigo» o «penalización» (AC-X2 de 9) y el tiempo hasta poder reintentar es ≤ 2,0 s desde el inicio del rechazo (2,1 s desde el último clic).
- **AC-PV3 (R18, PV):** **THEN** al menos 4 de 6 testers resuelven sin pista N1 con ≤ 3 rechazos, y al menos 4 de 6 explican, al terminar, que había que fijarse en el **día** además de la hora (comprensión de la arruga).
- **AC-PV4 (F2, D11-6, PV):** **THEN** la mediana de rechazos por jugador es < 6; si ≥ 6, se reabre D11-6 y R26 antes del hito.
- **AC-PV5 (R35, PV):** captura retenida de `C05` resuelto con los huecos `2·1·3·4` y sus sellos legibles a 1080p, en 16:9 y 16:10, sin verde ni rojo.

## Datos del puzle

Entrada completa de `assets/data/puzzles/puzzles.json` según el esquema de la regla 4 de 9 (ejemplo de la regla 5, ampliado con los tres niveles de pista, `rewards`, `persist` y `locked_feedback`). Esquema v2 de la regla 4b de 9 (D9-67 a D9-79): `schema_version: 2` (raíz del fichero), `on_change`, `element_zones` y `solution.visual_elements` ya los admite 9; no queda ningún campo ‡ en la entrada. Los enteros (`sequence`, `level`) se convierten a `int` en la carga (regla 29 de 9).

```json
{
  "schema_version": 2,
  "id": "P1",
  "mode": "VIEW",
  "view": "C05",
  "solved_flag": "archivo_abierto",
  "requires": { "all": [] },
  "needs_items": ["I-01"],
  "locked_feedback": { "sfx": "SFX_CLICK_SUBTLE" },
  "validation": { "policy": "DELAYED_AFTER_CHANGE", "delay_s": 0.6 },
  "solution": { "sequence": [2, 1, 3, 4],
    "visual_elements": ["C05/paper/stamp_1", "C05/paper/stamp_2", "C05/paper/stamp_3", "C05/paper/stamp_4"] },
  "element_zones": [ { "ids": ["C05/paper/ref_*"], "atraccion_desactivada": true } ],
  "on_change": { "sfx": "SFX_SLOT_IN", "when": "REF_PLACED" },
  "on_reject": { "sfx": "SFX_REJECT", "shake_s": 1.2, "reset_after_s": 1.5, "lock": "PUZZLE" },
  "on_solved": {
    "write": [ { "flag": "archivo_abierto", "value": true } ],
    "sfx": "SFX_UNLOCK", "sfx_s": 1.4,
    "rewards": [],
    "close_view_after_s": 1.5
  },
  "on_reopen": "NO_VIEW",
  "resolution": { "kind": "IMMEDIATE" },
  "persist": [],
  "idle_reset": "GESTURE",
  "hints": [
    { "level": 1, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [ { "type": "HIGHLIGHT", "targets": ["C05/paper"], "targets_if_missing_items": ["V08"], "duration_s": 3.0 } ] },
    { "level": 2, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [ { "type": "TEXT", "key": "PISTA_P1_N2" } ] },
    { "level": 3, "trigger": "REQUEST", "availability": "ON_HINT",
      "effects": [ { "type": "HIGHLIGHT", "targets": ["C05/paper/stamp_1", "C05/paper/stamp_2", "C05/paper/stamp_3", "C05/paper/stamp_4"], "duration_s": 3.0 } ] }
  ]
}
```

**Notas de datos.** (1) Sin `assist`, sin `on_unlock` ni `compartment` (P1 no completa compartimento ni se desbloquea). (2) `rewards: []` (R37). (3) `on_change` lo admite 9 (regla 4b, D9-67; R24). (4) El layout y los tamaños de `ui.*` están en el fichero de vista (Tuning Knobs). (5) `targets` de N3 son marcas **no clicables** declaradas por el controlador (R4); van en `solution.visual_elements` y la regla 29 de 9 las acepta como `targets` (regla 4b-e, D9-71). (6) Las claves de contenido las posee 18 (`PISTA_P1_N2`). (7) La zona `ref_N` se declara en `element_zones` (`ids: ["C05/paper/ref_*"]`, `atraccion_desactivada: true`; definitivo, R14, D11-17; el nombre `element_zones` y su forma son de la regla 4b-c de 9); `slot_k` mantiene la atracción. Sin `tolerance_px` en la zona, R = 64 px (‡ 7, propuesta de 9). (8) `schema_version: 2` es de la raíz del fichero (regla 4b); se repite en el ejemplo para fijar la versión de la entrada. El campo de efecto de pista sería `affordance` (D9-72), pero el P1 no usa ninguno: N1 y N3 son `HIGHLIGHT` y N2 `TEXT`.

## Decisiones tomadas

Formato: decisión · alternativa descartada · motivo. (Modo por lotes: decididas por el autor del borrador con su recomendación; la aprobación es la del lote.)

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D11-1 | **B.1 literal**: la hoja lleva siempre `Enviado: hh:mm` y el pie «Ordena por hora de envío»; N2 y N3 son énfasis, no información | Quitar la hora o el pie para que las pistas valgan | Decisión del usuario ya tomada (v0.4, D7-61, D18-23). Consecuencia aceptada: escalera efectiva de un solo nivel (OQ-1) |
| D11-2 | La selección de una referencia (`en_mano`) es un **cambio** que reinicia la cuenta de F1 de 9 y `evaluate()` devuelve `NONE` con referencia en mano (R12, R21) | Subir `delay_s` a ≥ 1,0 s; evaluar tras cada cambio | `t_corregir` (0,8 s) > `delay_s` (0,6 s): sin esto se rechaza a mitad de una corrección (F5). No toca los 0,6 s de B.1 |
| D11-3 | Pulsar un hueco lleno con una referencia en mano **la intercambia** (o devuelve la anterior a la hoja) | Rechazar la pulsación; devolver ambas a la hoja | B.1 no cubre este caso; intercambiar es reversible, no pierde piezas y reduce pulsaciones (Competencia) |
| D11-4 | **El rechazo no informa** (R26): los 23 incorrectos son idénticos | Indicar los huecos acertados; mostrar «n/4» | Sería un medidor de acierto, bajaría la fuerza bruta a ≤ 6 fallos (F3) y anula el pie de B.1; coherente con «sin contador» (regla 14 de 9) |
| D11-5 | `SFX_SLOT_IN` mediante un campo `on_change` de datos (absorbido en 9, esquema v2, D9-67); el P1 no usa `PARTIAL` | `PARTIAL` con la ocupación como `progress`; que lo reproduzca 7 como respuesta del objeto | `PARTIAL` está definido para aciertos parciales y la matriz de 9 dice «—» para P1; la regla 13 de 9 exige respuesta a toda acción procesada |
| D11-6 | **PROPUESTA PENDIENTE DE CONFIRMACIÓN (OQ-4):** los **huecos muestran el sello** (día y hora) de la referencia colocada (`ui.show_stamp_in_slot`, †) y quedan visibles al resolver | B.1 estricto sin sello; mostrar el cuerpo del correo al colocarlo | Mitiga D-W1 (quien tantea ve la cronología) con coste mínimo; no revela la solución; apoya la comparación en fila (Competencia). **Se aparta de B.1** (que no menciona el sello en el hueco) y baja algo la dificultad (criterio de competencia del slice): no es decisión del autor del GDD; si el autor del slice dice no, `show_stamp_in_slot = false` sin otro cambio |
| D11-7 | Una referencia **colocada sigue siendo pulsable en la hoja** (atenuada) | Retirarla de la hoja al colocarla | B.1 dice «si ya estaba en otro hueco, se mueve»: implica poder pulsarla colocada |
| D11-8 | N2 = `TEXT` con `PISTA_P1_N2` (firme); **PROPUESTA PENDIENTE DE CONFIRMACIÓN (OQ-9):** N3 = `HIGHLIGHT` de los sellos `C05/paper/stamp_N` | N3 como `AFFORDANCE` nuevo; N3 con texto sin clave; N3 = «la hora de envío aparece en letra pequeña» (B.1 literal) | Reutiliza efectos existentes (regla 25 de 9) sin añadir información ni una clave `PISTA_*` (conjunto cerrado de 8). El slice B.1 define N3 como la hora de envío en letra pequeña; v0.4 solo confirma que no añade información: la forma concreta de N3 es una lectura del autor del GDD |
| D11-9 | `rewards: []`; las tarjetas las recoge el jugador en `A05` (20 y 8) | Que 9 entregue `tarjeta_B/D` al resolver | 9 no escribe `tarjeta_*` (son de 20, R10 de 20); el recorrido ya está decidido; se lee «se entregan» del slice como «quedan al alcance» (OQ-5) |
| D11-10 | Sin material: `SFX_CLICK_SUBTLE`, **sin texto** | Texto «Falta consultar los correos» | No hay clave en 18; un texto sería dirección contraria a Pilar *Autonomía*; N1 ya orienta (OQ-2) |
| D11-11 | Geometría de referencia con restricciones numéricas (R14, F6) | Dejarlo íntegramente a 9 | La validación de 7/9 (R₁+R₂) y el tamaño del bloque (F4 de 19) condicionan el diseño; si 9 elige otro layout debe cumplir los mismos límites |
| D11-12 | La solución es **dato** de `puzzles.json` verificado por una prueba contra `compose_i01()` (R19, AC-3) | Derivarla en ejecución desde 18 | El marco no conoce la solución (regla 2 de 9); la prueba cierra la deriva sin acoplar sistemas |
| D11-13 | Las tres pistas son `REQUEST` (sin `IDLE`) | Aplicar N1 tras inactividad | La matriz de 9 solo reserva `IDLE` para P3 y P6; ayuda no pedida sería dirección (Pilar *Autonomía*) |
| D11-14 | Colocaciones en memoria, `KEEP` al cerrar, no persistidas | Persistirlas con un hecho | Regla 22 de 9: rehacerlo no cuesta nada; evita hechos nuevos |
| D11-15 | `restore_solved_presentation()` del P1 es **vacío** (la vista no se reabre; el panel del mundo no cambia) | Mostrar `2·1·3·4` en el panel 3D | No es accesible (R6) y requeriría arte/escena; puede añadirse después sin tocar reglas (OQ-6) |
| D11-16 | Fuerza bruta **aceptada y medida** con umbral de revisión (F2, AC-PV4) | Limitar intentos, enfriamiento o rechazo creciente | Pilar *Tensión sin castigo* y anti-pilares; D-W1 queda vigente con medición, no se bloquea |
| D11-17 | (Ronda 7, aviso 1-2 del review) `ref_N` declara `atraccion_desactivada` de forma **definitiva**; `slot_k` mantiene la atracción; OQ-8 queda resuelta por AC-30b de 7 (tolerancia normal por elemento: 64 px → 128 px, advertencia solo a 170 px frente a la asistida de 256) y se retira como pregunta | Atracción también en `ref_N` (pide la regla 9 de 9); dejar `atraccion_desactivada` «provisional» a la espera de 7/9 | Los chips (112×56, paso 150) pasan sin excepción; Edge Cases, R14, AC-18 y Datos nota 7 dicen ahora lo mismo. Coste aceptado: sin asistencia con mando en los chips; 9 debe admitir la excepción por zona (Cambios requeridos) |
| D11-18 | (Ronda 7, aviso 5-6) Reparto de `elements()`: 19 (`compose_i01()`) aporta bloques y 4 referencias; el **marco** crea `ref_N` (regla 7 de 9); el **controlador de 11** declara `slot_k` y `stamp_N`. `compose_i01()` con ≠ 4 referencias = error de datos + sin material, con criterio propio (AC-21) | Que el controlador cree también `ref_N` (redacción anterior de R7) | Una sola fuente por elemento; evita que el programador adivine y coincide con la regla 7 de 9 y R30 de 19 |
| D11-19 | (Ronda 7, aviso 7) AC-3 ordena por un entero `ts_envio` que debe aportar `compose_i01()` (petición a 19), no por cadenas | Analizar «Lunes»/«09:14» en la prueba | La prueba de la solución no debe depender de un formato de texto; AC-3 no es ejecutable hasta que 19 lo acepte (dependencia declarada en Cambios requeridos) |
| D11-20 | (Ronda 7, aviso 8) D11-6 y D11-8 (N3 = resaltado de sellos) pasan de «decididas» a **propuesta pendiente de confirmación** y suben a Open Questions (OQ-4, OQ-9); el encabezado de Open Questions reconoce que OQ-5 contradice el slice | Mantenerlas como decididas por defecto | Tocan la dificultad/competencia frente a B.1 y el §8 del slice: según el modo por lotes solo se decide por defecto lo que no contradice el slice |
| D11-21 | (Ronda 8) Alineado con el esquema v2 de `puzzles.json` (regla 4b de 9): `schema_version: 2`, zona `ref_N` en `element_zones`, stamps en `solution.visual_elements`, `on_change` sin ‡; R = 64 px sin tolerancia queda ‡ 7 | Mantener `atraccion_desactivada` suelto y la validación especial de stamps | Un nombre por concepto y datos validables por el marco (D9-69, D9-71, D9-78); sin cambio de diseño ni de tiempos; cierra las peticiones (a) y (c) a 9 |
| D11-23 | **(M1 cola de diseño A, H4, 2026-11-11; ADR-0010 C5/C10; D9-85)** R7: `missing_items` es una lista (`[I-01]` o vacía) y es el controlador del P1 quien llama a `compose_i01()` en `on_open()` y crea también `ref_N`; el marco conserva la puerta y el cálculo de `missing_items`. H1 ya estaba reflejado aquí (R14, AC-18, D11-17: `ref_N` con `atraccion_desactivada`) | Que el marco llame a 19 y cree `ref_N` (redacción anterior de R7); el reparto no cambia el diseño ni los tiempos | ADR-0010 D15; coincide con la regla 7 de 9 |
| D11-22 | **(Ronda de corrección 9, `gdd-cross-review-2026-11-10.md`)** «17 Sistema de pistas (sin GDD)» pasa a citar `sistema-de-pistas.md` (regla 32: con `I-01` ausente 9 aplica `targets_if_missing_items` y 17 no interviene). Sin cambios de reglas | Dejar el texto hasta el próximo lote | Un «sin GDD» obsoleto sugiere un contrato abierto que ya está cerrado |

## Open Questions

**OQ-5 contradice la letra del slice** (§8 «se entregan `tarjeta_B` y `tarjeta_D`») y OQ-4 y OQ-9 se apartan de B.1 (sello en los huecos; forma de N3): las tres requieren al autor del slice. El resto no cambia pilares ni tono. (OQ-8 se retiró en la ronda 7: resuelta por AC-30b de 7, D11-17.)

| # | Pregunta | Quién | Valor provisional / impacto |
|---|---|---|---|
| OQ-1 | **Escalera de pistas efectiva de un solo nivel.** Con B.1 literal, N2 y N3 no añaden información sobre día ni hora (D-W4, A-C1 de la revisión r5: quien se atasca no recibe ayuda sobre el **día**, que es la arruga del puzle). ¿Se acepta tras playtest o se vuelve a decidir B.1? | autor del slice | Aceptado (v0.4, D7-61/D18-23); N3 como énfasis de sellos. Se mide con AC-PV3 |
| OQ-2 | ¿Debe haber un texto de «sin material» al pulsar los huecos sin hoja? Necesitaría una clave `UI_*` en 18. | narrative-director / ux-designer | Sin texto (D11-10); N1 y `V08` orientan |
| OQ-3 | N1 con `I-01` ausente resalta `V08` aunque el jugador no haya leído los correos (9 no lee `correos_leidos`, D9-50) y `V08` responde «sin resultados». ¿Debe poder apuntar a `V01`? | 9 / 17 | Aceptado: `OBJ_V08_SIN_RESULTADOS` completa el camino |
| OQ-4 | **Sello en los huecos (D11-6, propuesta pendiente de confirmación):** añade un apoyo que B.1 no menciona; baja algo la dificultad (criterio de competencia del slice) y mitiga D-W1. ¿Se confirma? | autor del slice | Propuesta no confirmada: se diseña con él (`show_stamp_in_slot` verdadero†) pero no se da por decidido; se anula con `ui.show_stamp_in_slot = false` sin otro cambio. Si se rechaza, se reabre la mitigación de D-W1 (F2) y AC-PV5 cambia a «sin sellos» |
| OQ-5 | El §8 del slice dice que al resolver P1 «se entregan `tarjeta_B` y `tarjeta_D`»; 8 y 20 las ponen en `A05` tras la puerta A. ¿Se reformula el §8 (v0.4.x)? | autor del slice | Se lee como «quedan al alcance» (D11-9) |
| OQ-6 | ¿Muestra el panel 3D de `C05` la cronología `2·1·3·4` tras resolver (arte/escena)? | art-director / 4 | No (D11-15) |
| OQ-7 | **Tiempos sin medir:** `T_leer`, `T_trayectos`, `T_ordenar` y los rechazos esperados de F4 son hipótesis; no hay datos. La distancia `V01`→`V08`→`C05` depende de la escena de planta (4). | producer / QA | F4 da ≈ 3,0 min central; se contrasta con AC-PV1 |
| OQ-9 | **Forma de N3 (D11-8, propuesta pendiente de confirmación):** B.1 dice que N3 es «la hora de envío aparece en letra pequeña»; el GDD la modela como resaltado de los sellos (`stamp_N`, marcas no clicables) porque la hoja ya trae día y hora (B.1 literal). ¿Se confirma el resaltado o se prefiere otra forma? | autor del slice | Propuesta no confirmada; no añade información (R31). Si se cambia, solo varía `hints[2]` de los datos y AC-13 |

## Cambios requeridos en otros GDDs

No se ha editado ninguno desde 11. Para el siguiente paso del lote (el esquema de `puzzles.json` versión 2 de 9 lo definió otro agente y no se reabre aquí; (a) de 9 debe contrastarse con él):

- **9 Marco de puzles:** (a) **absorbido en 9 (esquema v2, D9-67, D9-69, D9-73; regla 4b):** `on_change` (`{sfx, when: REF_PLACED}`, R24), `idle_reset`, `element_zones` y `schema_version`; `on_solved.rewards` y `persist` ya estaban; los tres niveles de pista del P1 sustituyen al ejemplo de la regla 5 (4b); (b) regla 12/F1: dejar escrito que en `DELAYED_AFTER_CHANGE` el cambio de estado de un elemento (p. ej. `en_mano` del P1) cuenta como cambio y que `evaluate()` puede devolver `NONE` con todos los huecos llenos (R12, R21; F5 de 11); (c) **absorbido en 9 (esquema v2, D9-71, D9-72):** `HIGHLIGHT` sobre marcas no clicables (`C05/paper/stamp_N`, vía `solution.visual_elements`); (d) matriz de encaje y regla 7: apuntar al GDD 11 para las reglas del P1 y a R14 (geometría) en D9-49; (e) `restore_solved_presentation()` del P1 vacío (D11-15); (f) Dependencies: fila 11 con las reglas de esta página (9 → 11 es dependen-de-9, la declara 11); (g) AC-07/AC-06: citar los AC-6, AC-8 de 11 como instanciación.
- **19 Ordenador, correo e impresora:** (a) **petición bloqueante para AC-3:** `compose_i01()` devuelve además un **`ts_envio` entero** (minutos desde el lunes 00:00) por bloque (alternativa: `dia_orden` entero más `hora_envio`), para que la prueba R19/AC-3 no analice cadenas de texto; hasta que 19 lo acepte, AC-3 no es ejecutable (D11-19); (b) confirmar que `hora_visible` falso oculta también el sello en los huecos (D11-6, pendiente) o que 11 usa `dia` solo; (c) **reciprocidad:** añadir a la tabla de dependientes/Dependencies de 19 la fila «11 Puzle 1 (dura): consume `compose_i01()`, `V08` objetivo resaltable y la impresión repetible» (hoy 19 solo nombra «P1»); (d) R27/R28/R30 ya son recíprocos: sin otro cambio.
- **18 Base de contenido:** (a) (si 19 opta por `dia_orden` en vez de `ts_envio`) los registros de correo exponen el día de forma ordenable (`dia_orden`) además de la etiqueta («Lunes»); (b) sin claves nuevas (`PISTA_P1_N2` basta; OQ-2 sería la excepción).
- **7 Interacción e inspección (y 9, regla 29):** sin pregunta pendiente sobre tolerancias (AC-30b de 7 ya cubre «normal» por elemento; OQ-8 retirada, D11-17); `atraccion_desactivada` por zona en `ref_N` queda absorbido en 9 (`element_zones`, regla 4b-c, D9-69); queda ‡ 7 el R = 64 px de los elementos sin tolerancia (D9-78); confirmar que `elements()` de `C05` (4 chips, 4 huecos y la hoja) cabe en el picking y que `atraccion_desactivada` por zona queda disponible (ya definido).
- **17 Sistema de pistas (`sistema-de-pistas.md`, regla 32):** el P1 no tiene niveles `IDLE`; N1 es la única con orientación real; resaltar `V08` por `targets_if_missing_items`.
- **8 Control de acceso:** sin cambios (regla 6 de 8 ya cubre `archivo_abierto`).
- **20 Documentos y bolsillo:** **reciprocidad:** añadir a su lista de dependientes/Dependencies la fila «11 Puzle 1 (dura): consulta `has_item("I-01")` vía 9; no recibe `rewards`» (hoy 20 solo nombra «P1»). Sin cambios de reglas.
- **Slice (`slice-v0.3.md`):** OQ-5 (§8, «se entregan `tarjeta_B` y `tarjeta_D`»). No se edita.
- **`systems-index.md`:** fila 11: estado «Revisado (ronda de corrección 7) — pendiente de re-review», enlace `design/gdd/puzle-1-cronologia.md`; dependencias 9, 18, 19, 20 (duras) como están; añadir en la columna de 9 y 19 que los dependientes incluyen 11.

## Entradas para el registro

Propuestas para `design/registry/entities.yaml` (no se ha editado):

```yaml
constants:
  - name: P1_DELAY_S
    value: 0.6
    unit: s
    range: [0.3, 1.5]
    source: design/gdd/puzle-1-cronologia.md
    note: "slice B.1; F1 de marco-de-puzles; la selección de una referencia reinicia la cuenta (R12)"
  - name: P1_SHAKE_S
    value: 1.2
    unit: s
    range: [0.6, 2.0]
    source: design/gdd/puzle-1-cronologia.md
    note: "slice B.1"
  - name: P1_RESET_AFTER_S
    value: 1.5
    unit: s
    range: [0.6, 2.0]
    source: design/gdd/puzle-1-cronologia.md
    note: "<= lock_max_s (2,0); slice B.1"
  - name: P1_UNLOCK_SFX_S
    value: 1.4
    unit: s
    range: [0.8, 2.5]
    source: design/gdd/puzle-1-cronologia.md
    note: "SFX_UNLOCK; slice B.1"
  - name: P1_CLOSE_VIEW_AFTER_S
    value: 1.5
    unit: s
    range: [0.5, 3.0]
    source: design/gdd/puzle-1-cronologia.md
    note: "F4 de marco-de-puzles"
  - name: P1_SOLUTION_SEQUENCE
    value: [2, 1, 3, 4]
    unit: ref
    source: design/gdd/puzle-1-cronologia.md
    note: "H1..H4; derivada de (día, hora) de los correos (R17); prueba AC-3"
  - name: P1_SLOT_COUNT
    value: 4
    unit: huecos
    source: design/gdd/puzle-1-cronologia.md
    note: "slice B.1; 24 permutaciones"
  - name: P1_CHIP_PITCH_PX
    value: 150
    unit: px
    range: [128, 200]
    source: design/gdd/puzle-1-cronologia.md
    note: "R1+R2 de Entrada con R=64; layout de referencia (R14)"
  - name: P1_SLOT_PITCH_PX
    value: 200
    unit: px
    range: [128, 260]
    source: design/gdd/puzle-1-cronologia.md
    note: "idem"
formulas:
  - name: p1_attempt_fail_cost_s
    expression: "8*t_clic + delay_s + reset_after_s"
    output: 5.3
    unit: s
    source: design/gdd/puzle-1-cronologia.md
    note: "F2; t_clic 0,4 s†"
  - name: p1_bruteforce_worst_s
    expression: "23*p1_attempt_fail_cost_s + (8*t_clic + delay_s)"
    output: 125.7
    unit: s
    source: design/gdd/puzle-1-cronologia.md
    note: "F2; la media sin repetir es 64,8 s"
  - name: p1_time_central_s
    expression: "T_leer + T_trayectos + T_ordenar + T_fallos + T_desvio + T_cierre"
    output: 177.5
    unit: s
    range: [95.8, 272.8]
    source: design/gdd/puzle-1-cronologia.md
    note: "F4; objetivo F7 de marco-de-puzles 120-240 s; hipótesis sin medir"
entities:
  - name: C05/slot_1..4 , C05/paper/ref_1..4 , C05/paper/stamp_1..4
    kind: view_element
    source: design/gdd/puzle-1-cronologia.md
    note: "IDs de elemento de la vista C05 (R4); los stamp no son clicables"
```

Hechos: sin entradas nuevas (`archivo_abierto` ya está en el catálogo de 3). Avisos: sin nuevos (`EV_PUZZLE_SOLVED_P1`, «feedback de puzle» ya existen).

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 (ronda de corrección 8) | Alineación mecánica con el esquema v2 de `puzzles.json` (regla 4b de 9): `schema_version: 2`, `element_zones` para `ref_N`, `solution.visual_elements` para los sellos, quitadas las ‡ de campos ya absorbidos (`on_change`, `idle_reset`), ‡ 7 en R = 64 px; peticiones a 9 marcadas como absorbidas; D11-21. Sin cambio de diseño. Estado: Revisado (ronda 8), pendiente de re-review. |
| 2026-11-09 (ronda de corrección 7) | Corrección según `reviews/puzle-1-cronologia-review.md` (0 bloqueantes, 9 avisos): `ref_N` con `atraccion_desactivada` definitiva y OQ-8 retirada (R14, Edge Cases, AC-18, Datos nota 7, F6; D11-17); R4 cita R30 (no R34); AC-6 reescrito como dos pulsaciones (R12); reparto de `elements()` único en R7 alineado con la regla 7 de 9 (D11-18) y nuevo AC-21 para `compose_i01()` con ≠ 4 referencias; AC-3 por `ts_envio` entero pedido a 19 (D11-19); D11-6 y D11-8 pasan a propuesta pendiente (OQ-4, nueva OQ-9) y el encabezado de Open Questions reconoce que OQ-5 contradice el slice (D11-20); filas de reciprocidad para 19 y 20 en Cambios requeridos. Estado: Revisado (ronda 7), pendiente de re-review. Fórmulas F1–F7 sin cambio numérico (solo la nota de F6 sobre la tolerancia). |
| 2026-11-09 | Esqueleto y primer borrador completo (lote Feature 3): Summary, Overview, Player Fantasy, Detailed Rules (R1–R46), Formulas (F1–F7), Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria, Datos del puzle, Decisiones D11-1 a D11-16, Open Questions OQ-1 a OQ-7, Cambios requeridos y Entradas para el registro. Estado: pendiente de review independiente. |
| 2026-11-10 | Ronda de corrección 9: «17 (sin GDD)» sustituido por `sistema-de-pistas.md`; D11-22. Estado: Revisado (ronda de corrección 9) — pendiente de re-review. |
