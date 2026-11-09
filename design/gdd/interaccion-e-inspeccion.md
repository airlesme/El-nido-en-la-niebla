# Interacción e inspección

> **Status**: Designed (pendiente de design-review)
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Autonomía como progresión (el jugador decide qué mirar y qué tocar) · Tensión sin castigo (un solo botón, sin precisión temporal, nunca bloquea) · Información incompleta (inspeccionar describe, nunca confirma intenciones)

## Summary

Es lo que permite a Vera tocar el mundo: decide qué objeto tiene delante, qué ofrece el botón contextual (activar, coger, examinar, leer, abrir un puzle), y lleva al jugador a los modos de mirar de cerca: girar un objeto en la mano, leer un documento o acercarse a un panel de puzle. No decide qué *hace* cada objeto (eso es de quien lo posee: puertas, ordenador, puzles…); decide *cómo se llega a él* y que siempre se sienta igual. Existe porque el slice se juega con un único botón y porque descubrir objetos con la mirada es la forma de avanzar del pilar *Autonomía como progresión*.

> **Quick reference** — Layer: `Feature` (categoría `Gameplay`) · Priority: `MVP` · Key deps: `1 Entrada y controles`, `2 Jugador en primera persona`, `18 Base de contenido narrativo` (blanda: `3 Estado y bus`)

## Overview

Interacción e inspección es la capa entre el jugador y los objetos del mundo. En `exploración`, cada fotograma lanza un barrido desde el centro de la cámara de Vera y decide cuál es el **objetivo de interacción**: el objeto interactuable más cercano al que se mira, a alcance de mano y sin nada delante. Si hay uno, el sistema de prompt (24) muestra el icono discreto del slice (§16) con la etiqueta del verbo («Abrir», «Girar», «Examinar», «Leer»). El jugador pulsa `interactuar` y ocurre lo que ese objeto declara.

Cada objeto interactuable se describe en datos (`assets/data/interaction/interactables.json`) con sus IDs del slice (`V02`, `B01`, `D01a`…): qué verbo ofrece con pulsación corta, cuál con pulsación prolongada (`leer`), cuándo está habilitado y qué efecto genérico tiene. El efecto puede ser **delegar** en el dueño del objeto (la puerta la lleva Control de acceso 8; el teléfono, la Llamada 22), o uno de los tres modos propios de este sistema: **inspección** (objeto pequeño girado en la mano), **lectura** (documento a pantalla) y **vista cercana** (cámara acercada a un panel, con cursor, para los puzles y el ordenador).

El sistema no guarda estado propio: lo que un objeto «es» (abierto, leído, usado) son hechos del juego (3) escritos por su dueño. Existe por tres razones: (1) el slice se maneja con *una sola tecla contextual* y esa promesa debe cumplirse igual en los 40 y pico objetos; (2) todos los puzles necesitan el mismo puente entre el cursor y sus piezas (apuntar, agarrar, rotar), y resolverlo una vez evita que cada puzle reinvente su control; (3) mirar de cerca y leer son el verbo central del juego —*descubrir qué pasó*— y deben ser cómodos, nunca punitivos: no hay tiempo, no hay fallos y siempre se puede volver atrás.

## Player Fantasy

Vera es una persona cansada en una planta vacía que **mira antes de tocar**. El jugador siente que cada objeto tiene un peso: la taza fría que alguien dejó a las siete, el peluche cúbico con la pegatina del equipo antiguo, el formulario que se lee despacio. Sentir (aesthetics del MDA): **Discovery** (encontrar el detalle en la mano), **Sensation** (manos que cogen, giran y pasan páginas) y **Narrative** (la información llega al ritmo de la mirada). Nunca debe sentir que «pelea con el apuntado» o que pierde algo por haber pulsado mal.

## Detailed Design

### Core Rules

‡ = propuesta que debe confirmar el GDD del sistema afectado (aún sin redactar). † = valor propuesto, a validar en playtest. Los identificadores de código van en inglés; los IDs del slice (`V02`, `I-01`, `SFX_CLICK_SUBTLE`…) se conservan tal cual.

**Reparto de responsabilidades**

1. **Qué hace y qué no.** Este sistema *detecta* el objetivo, *interpreta* la pulsación y *hospeda* tres modos de mirada (inspección, lectura, vista cercana). **No** decide el resultado de activar un objeto: lo hace su dueño a través del contrato de la regla 3. Tampoco dibuja el icono (24), ni muestra los documentos (20), ni valida puzles (9).
2. **Catálogo en datos.** Los objetos interactuables se declaran en `assets/data/interaction/interactables.json`. Cada entrada tiene: `id` (el del slice), `verbo_corto` (nullable), `verbo_largo` (nullable, solo `leer`), `etiqueta_corto` y `etiqueta_largo` (claves de la base de contenido 18), `efecto` (ver regla 6), `habilitado_si` (condición sobre hechos: lista `todos` y lista `ninguno`), `alcance_m` (opcional, por defecto el global), `prioridad` (entero, 0 por defecto), `bloquea_s` (duración de la animación que bloquea el control, 0 por defecto), `texto` (clave `OBJ_<id>` si procede) y los datos del modo que abre (pose de inspección, anclaje de vista, documento). Un objeto que no está en el catálogo **no es interactuable** (por ejemplo `V07` el umbral, `R03` el ventanal, `D-MOB-*`).
3. **Contrato del dueño.** Cada sistema dueño de objetos (8, 10, 19, 20, 22, 9) registra un manejador por ID con dos operaciones: `can_interact(verbo) -> {SI, NO, SIN_EFECTO}` e `interact(verbo, contexto) -> {HECHO, SIN_EFECTO}`. `SIN_EFECTO` hace sonar `SFX_CLICK_SUBTLE` (slice B.7) y, si el objeto tiene `texto`, lo muestra como pie (regla 12). El manejador es quien escribe hechos y quien emite sus propios avisos; este sistema nunca escribe hechos.
4. **Sin estado propio.** No se guarda nada de este sistema. Al cargar la escena el objetivo está vacío y ningún modo está abierto. El estado de cada objeto lo reconstruyen sus dueños leyendo hechos (GDD del 4, regla 9.6).

**Detección del objetivo**

5. **Barrido de foco.** Solo en el contexto `exploración` y fuera de transiciones, cada fotograma de física se lanza un barrido de esfera de radio `radio_apuntado_m` desde la posición de la cámara y a lo largo de su eje de mirada (supuesto A1 sobre el sistema 2). Cuenta el **primer** contacto del barrido, entre geometría del mundo (que ocluye) y objetos interactuables. Si ese primer contacto es un interactuable habilitado y está a menos de su alcance (`alcance_interaccion_m` global o `alcance_m` propio), es el candidato. Si hay varios interactuables a menos de `desempate_prof_m` de profundidad entre sí (por ejemplo la nota `B05` bajo la lámpara `B02`), gana la mayor `prioridad`, y a igualdad el más cercano al centro del rayo.
6. **Efectos genéricos.** Cada objeto declara un `efecto`:
   - `DELEGAR`: llama a `interact()` del dueño (puertas, cajones, interruptores, teléfono, impresora, caja…).
   - `INSPECCION_MANO`: entra en `inspección` con el objeto en la mano (reglas 13 a 15). Solo objetos pequeños y manipulables.
   - `INSPECCION_TEXTO`: muestra el texto `OBJ_<id>` como pie, sin cambiar de contexto (regla 12).
   - `LEER`: abre `lectura` con un documento (reglas 16 a 18).
   - `ABRIR_VISTA`: abre `vista cercana` sobre un anclaje (reglas 19 a 23).
   - `ABRIR_ORDENADOR`: pide a Entrada el contexto `ordenador` y bloquea la cámara en el anclaje de `V01` (regla 24).
7. **Estabilidad del foco.** El objetivo se conserva `t_gracia_foco_s` después de que el barrido lo pierda, y mientras el rayo siga a menos de `radio_pegajoso_m` de su colisionador (histéresis espacial), para que el temblor del ratón o del stick no haga parpadear el icono ni cancele una pulsación prolongada. Un objeto que pasa a deshabilitado (o se retira) deja de ser objetivo en el mismo fotograma, sin gracia.
8. **Habilitado no es visible.** Un objeto cuya condición `habilitado_si` es falsa **no tiene icono ni reacciona** (no revela que existe una interacción futura; pilar *Autonomía como progresión*). Los objetos que deben explicar por qué no ceden (los lectores de tarjeta sin tarjeta, un compartimento bloqueado) están habilitados y es su dueño quien contesta `SIN_EFECTO` con su texto.

**Pulsación y verbos**

9. **Momento de disparo** (desarrolla la regla 10 de Entrada). Si el objeto solo tiene `verbo_corto`, se dispara **al pulsar**. Si tiene `verbo_largo` (`leer`), la pulsación corta se decide **al soltar** (si se suelta antes de `t_hold`) y la prolongada se dispara en cuanto el tiempo mantenido alcanza `t_hold` (F2). El anillo de progreso aparece a los `t_anillo_inicio_s` de mantener, no antes, para que un toque no parpadee. Si el objeto solo tiene `verbo_largo`, un toque corto no hace nada salvo hacer pulsar el anillo una vez y sonar `SFX_CLICK_SUBTLE`: la tecla *indica* que hay que mantener (slice §5: «pulsación prolongada para leer»).
10. **Enfriamiento y bloqueo.** Tras ejecutarse un verbo, el mismo objeto no admite otra pulsación hasta pasados `t_enfriamiento_s`, para evitar dobles disparos con un botón mantenido. Si el objeto declara `bloquea_s` > 0 (por ejemplo `ANIM_PHONE_PICKUP`, 0,8 s), este sistema pide a Entrada `sin control` durante ese tiempo, con la duración declarada (Entrada, regla 8 y F8) y lo libera al terminar; el tope de seguridad de Entrada (3 s) lo cubre si la animación no termina.
11. **Respuesta inmediata.** Toda pulsación que se procesa produce una respuesta audible o visible dentro de `latencia_feedback_ms` (slice §16: «feedback en cada acción»): el efecto del dueño, o `SFX_CLICK_SUBTLE` si es `SIN_EFECTO`. No existe una pulsación «muda» salvo que el objeto esté en enfriamiento o en transición.
12. **Pie de texto** (`INSPECCION_TEXTO` y `SIN_EFECTO` con texto). Un texto breve de objeto (`OBJ_<id>`, de la base de contenido) se muestra como pie no bloqueante durante la duración de F5. El jugador sigue en `exploración`: puede moverse, mirar o activar otro objeto, lo que sustituye el pie. Un texto de más de `texto_max_caracteres` (90†) no es un pie: es un documento (`LEER`). El pie lo dibuja el sistema 24; este sistema entrega la clave y la duración.

**Inspección (objeto en la mano)**

13. **Entrar.** `INSPECCION_MANO` pide el contexto `inspección`. El objeto pasa de su sitio a la mano en `t_mano_s` (animación `ANIM_HAND_*`, ‡ nombres a fijar con animación) hasta la distancia de F3, con su **pose canónica** (`pose_inspeccion` del catálogo: la cara que mejor lo presenta). El mundo sigue vivo (audio, eventos): inspeccionar nunca detiene el tiempo.
14. **Girar.** En `inspección`, `rotar_objeto` (el eje `mirar` de Entrada, regla 11) gira el objeto en torno a su centro con F3: sin límites de ángulo, sin inercia, sin modo «desbloquear». Los detalles de las caras ocultas (la pegatina del peluche `V05`) son geometría o textura reales, de modo que girarlo *revela* información. El objeto nunca atraviesa la cámara: la distancia de F3 es fija.
15. **Salir.** `atrás` devuelve el objeto a su sitio en `t_mano_s`; no hay otra forma de «gastarlo». Un objeto inspeccionado no cambia de estado ni escribe hechos por el mero hecho de mirarlo; si sus dueños quieren registrar que se ha visto, lo piden con el aviso «interacción ejecutada» (regla 29).

**Lectura (documento)**

16. **Entrar.** `LEER` (pulsación prolongada, o corta si el documento se declara con `verbo_corto = leer`) pide el contexto `lectura` y entrega al sistema 20 la clave del documento y su estilo de presentación (`impreso`, `manuscrito_*`, `pantalla`, `libro`; base de contenido 18, regla 1). El documento se muestra a pantalla; quien lo dibuja es el sistema 20.
17. **Páginas.** En `lectura`, `interactuar` pasa de página si el documento tiene varias (R01 el libro de visitas, dos páginas; `ANIM_PAGE_TURN`). En la última página `interactuar` no hace nada. No hay retroceso de página: cierra con `atrás`.
18. **Lectura completada.** Si el objeto declara `lectura_min_s` (A04 el formulario: **2 s**†, interpretación de «Leer (2 s)» del slice A.4), este sistema mide el tiempo que `lectura` permanece abierta (tiempo de juego, la pausa lo detiene) y, al alcanzarlo, emite una vez por apertura el aviso «lectura completada» con el ID del documento. Quien escribe el hecho (`formulario_leido`) es el sistema 20. Cerrar antes de tiempo no tiene coste: se vuelve a leer.

**Vista cercana (puzles y paneles)**

19. **Abrir.** `ABRIR_VISTA` pide a Entrada el contexto `vista cercana` (que bloquea las acciones durante la transición, regla 8 de Entrada) y al Jugador (2) que sitúe y bloquee la cámara en un anclaje (supuesto A2) con la curva de F4 y la duración `t_vista_entrada_s` de la vista (por ejemplo 1,0 s para `D01a`, slice B.3). Al terminar se muestra el cursor en `cursor_inicial` (por defecto, el centro de la vista) y se emite el aviso «vista cercana abierta» con el ID de la vista. Una vista puede declarar `requiere_ítem` (p. ej. `I-01` para el panel `C05`); si falta, la vista se abre igualmente (mostrar el panel vacío no es un fallo) y es el marco de puzles quien dice qué falta.
20. **Cursor y gestos.** Mientras la vista está abierta, la posición del cursor (real o virtual, Entrada regla 12) se convierte en un rayo desde la cámara bloqueada (F6) y se hace **picking** contra los elementos de la vista. Cada gesto de Entrada (`seleccionar`, `agarrar`, `rotar`, `mantener`, y el desplazamiento del cursor) se entrega al **receptor** de la vista (el marco de puzles 9 para los puzles, el ordenador 19 para `V01`) como un `PointerEvent`: `{gesto, fase (inicio | actualización | fin | cancelación), elemento (ID o nulo), pos_px, pos_vista (coordenadas locales en metros), delta}`.
21. **Captura del arrastre.** Una vez iniciado un `agarrar` o `rotar` sobre un elemento, todos los eventos hasta el final van a ese elemento, aunque el cursor salga de él. Si el contexto cambia (pausa que cierra la vista, `atrás`, pérdida de foco) se entrega `cancelación` y el receptor devuelve el elemento a un estado válido (no se pierde ninguna pieza en el aire).
22. **Tamaño de los elementos.** Todo elemento de vista que el jugador deba señalar mide al menos `pick_min_px` píxeles de lado a 1920 × 1080 (el hit-test se amplía hasta ese mínimo aunque el modelo sea menor) y se separa de otros elementos al menos 2·R (R = radio de atracción asistida de Entrada, 64 px†) entre centros, salvo que su puzle desactive la atracción en esa zona. Es una condición de diseño de los puzles; el marco (9) la comprueba en desarrollo (F6).
23. **Cerrar.** `atrás` cierra la vista: el receptor recibe antes `cancelación` de cualquier gesto en curso, la cámara vuelve en `t_vista_salida_s`, se emite «vista cercana cerrada» con el motivo (`jugador`, `resuelto` o `sistema`) y Entrada devuelve el contexto anterior. El receptor puede pedir cerrar la vista por sí mismo (p. ej. el marco, `t_auto_salida_s` después de resolver un puzle, F4 de 9); `atrás` durante la propia transición de entrada se ignora (Entrada, regla 8). **Siempre** se puede cerrar: ningún puzle puede impedir `atrás`, salvo los ≤ 3 s de una transición.

**Ordenador**

24. **Abrir el ordenador.** `ABRIR_ORDENADOR` (`V01`) pide a Entrada el contexto `ordenador`, bloquea la cámara en el anclaje de la pantalla (igual que la regla 19) y entrega el control al receptor (19). Cerrar con `atrás`. El contenido, la búsqueda y la impresora son de 19.

**Casos de objetos con estados** (resumen; el comportamiento es del dueño, el catálogo declara solo el verbo y la condición)

25. **Qué verbo ofrece cada objeto del slice** (tabla en Interactions with Other Systems). Los tres verbos de etiqueta del slice —«Abrir», «Girar», «Examinar», «Leer»— existen como claves de la base de contenido (18); este sistema solo las nombra.
26. **Objetos sin interacción.** Los objetos decorativos (mobiliario, `V07`, `R03`, `B08` las marcas del suelo) no se declaran: no se pueden enfocar, no ocluyen más que la geometría normal. La puerta de salida de Recepción «no es interactuable» (slice A.7): no está en el catálogo.

**Peticiones externas**

27. **Peticiones externas.** (a) *Cierre forzado:* el director de escenas (21) o la descarga de escena pueden pedir `cerrar_modos()`: se sale de `inspección`, `lectura` o `vista cercana` abiertas como si se pulsara `atrás` (con cancelación de gestos y aviso de cierre con motivo `sistema`). Para `ordenador` y `llamada` no aplica (los cierran 19 y 22). (b) *Lectura programática:* un dueño puede pedir `abrir_lectura(doc_id)` sin que el jugador mantenga `interactuar` (p. ej. el marco de puzles al abrirse la carta del puzle 6). Si hay una `vista cercana` abierta, `lectura` se apila encima y `atrás` vuelve a la vista; pedirla con otro modo de lectura ya abierto se rechaza y se registra.
28. **Pausa.** Con el menú abierto, la pulsación en curso (anillo) se cancela sin disparar nada (Entrada, edge case de foco); al reanudar, el objetivo se recalcula en el primer fotograma.
29. **Avisos que emite** (se documentan aquí según la regla 10 del GDD del 3): «vista cercana abierta» (ID de vista), «vista cercana cerrada» (ID de vista, motivo), «lectura completada» (ID de documento) e «interacción ejecutada» (ID de objeto, verbo, resultado), este último solo para quien quiera reaccionar (audio 23, atmósfera 28, director de escenas 21). El cambio del objetivo (para el prompt) **no** viaja por el bus: 24 consulta `get_target()` cada fotograma (una señal por fotograma saturaría el bus y su valor es transitorio).

### States and Transitions

Dentro del contexto `exploración`, el sistema tiene estos estados (el resto de contextos los posee Entrada):

| Estado | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin objetivo** | El barrido no encuentra candidato. No hay icono. | Con objetivo |
| **Con objetivo** | Hay un objeto enfocado; 24 muestra icono y etiqueta. | Sin objetivo · Pulsando |
| **Pulsando** | `interactuar` mantenida sobre un objeto con `verbo_largo`; el anillo avanza. | Con objetivo (suelta antes de `t_hold`: se dispara el verbo corto, si lo hay) · Ejecutando (alcanza `t_hold`) · Sin objetivo (cancelación) |
| **Ejecutando** | Se llama al manejador o se abre un modo. Enfriamiento y `bloquea_s`. | Con objetivo · Modo abierto |
| **Modo abierto** | `inspección`, `lectura`, `vista cercana` u `ordenador` en la pila de Entrada. El barrido de foco está suspendido. | Con objetivo (al salir, por `atrás` o cierre forzado) |

El estado interno de cada modo:

| Modo | Subestados | Notas |
|---|---|---|
| `inspección` | Entrando (`t_mano_s`) → Girando → Saliendo (`t_mano_s`) | Entrando y Saliendo descartan acciones salvo `pausa` (Entrada, regla 8) |
| `lectura` | Abierta (con contador de `lectura_min_s`) | Sin transiciones largas |
| `vista cercana` | Entrando (`t_vista_entrada_s`) → Abierta → Saliendo (`t_vista_salida_s`) | Los gestos solo se entregan en Abierta |
| `ordenador` | Entrando → Abierto → Saliendo | Igual que la vista cercana |

### Interactions with Other Systems

**Objetos del slice y su efecto** (verbos propuestos †; los textos de etiqueta son de la base de contenido 18)

| Objeto | Corto | Largo | Efecto | Dueño del resultado |
|---|---|---|---|---|
| `V01` ordenador | Abrir | — | `ABRIR_ORDENADOR` | 19 |
| `V02` teléfono | Descolgar (solo `vibrando`) | — | `DELEGAR` (`bloquea_s` 0,8) | 22 |
| `V03`, `A05`, `D05` cajones | Abrir | — | `DELEGAR` | 8 (A05) · 20 (contenidos) |
| `V04` caja de cartón, `V05` peluche | Examinar | — | `INSPECCION_TEXTO` (V04) · `INSPECCION_MANO` (V05) | 7 |
| `V06` lámpara de escritorio | Encender/Apagar | — | `DELEGAR` | 28 |
| `V08` impresora | Imprimir | — | `DELEGAR` | 19 |
| `A02`, `A06`, `B06`, `B07`, `D02`, `D03`, `D04`, `R02` | Examinar | — | `INSPECCION_TEXTO` | 7 |
| `A03` caja del traslado | Abrir | — | `DELEGAR` | 20 |
| `A04` formulario | — | Leer (`lectura_min_s` 2) | `LEER` | 20 |
| `B01`, `B02`, `B03` lámparas | Girar | — | `DELEGAR` (modo `MUNDO` del puzle 2) | 9 |
| `B05` nota | — | Leer | `LEER` (`prioridad` 2) | 20 |
| `C05` panel de cronología | Examinar | — | `ABRIR_VISTA` | 9 |
| `C06`, `C07`, `D06` lectores | Usar | — | `DELEGAR` | 8 |
| `C08` ascensor | Entrar | — | `DELEGAR` | 8 · 21 |
| `D01a` a `D01d` compartimentos | Abrir | — | `DELEGAR` → abre su vista | 10 + 9 |
| `R01` libro de visitas | — | Leer | `LEER` (dos páginas) | 20 |

| Sistema | Qué recibe de Interacción e inspección | Qué entrega a Interacción e inspección |
|---|---|---|
| 1 Entrada y controles | Peticiones de entrar y salir de `inspección`, `lectura`, `vista cercana`, `ordenador`; `sin control` con duración declarada | `interactuar`, `leer`, `rotar_objeto`, `atrás`, gestos de puntero, dispositivo activo |
| 2 Jugador en primera persona | Peticiones de bloqueo y desbloqueo de cámara, animaciones de manos ‡ | Posición y orientación de la cámara; ocultar/mostrar manos |
| 3 Estado y bus | Los avisos de la regla 29 | Lectura de hechos para `habilitado_si`; aviso «escena lista» (para configurarse) |
| 18 Base de contenido | Claves de etiqueta, texto de objeto y documento | Los textos (solo lectura) |
| 24 Prompt de interacción | `get_target()`: ID, etiqueta corta y larga, progreso del anillo | — |
| 20 Documentos y bolsillo | Documento a mostrar, estilo, aviso «lectura completada» | Dibujo de la pantalla de lectura |
| 9 Marco de puzles | `PointerEvent` de la vista, «vista cercana abierta/cerrada», activaciones del modo `MUNDO` | Petición de cierre automático de la vista |
| 19 Ordenador | Control del cursor y `seleccionar` en `ordenador` | — |
| 8, 10, 22, 28 | Activaciones (`interact`) | Manejadores por ID |
| 21 Director de escenas | Aviso «interacción ejecutada» | `cerrar_modos()` |

## Formulas

### F1 · Elección del objetivo de interacción

`candidato = primer contacto del barrido ∈ {interactuables habilitados}  si  profundidad ≤ alcance;   si varios con |Δprofundidad| ≤ desempate_prof_m:  argmax(prioridad), después argmin(distancia al eje)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| alcance_interaccion_m | float (m) | 1,2–3,0 | data, 1,8† | Distancia máxima desde la cámara |
| radio_apuntado_m | float (m) | 0–0,15 | data, 0,06† | Radio de la esfera del barrido (ayuda a objetos pequeños, p. ej. `V02`, 15 × 8 cm) |
| desempate_prof_m | float (m) | 0,01–0,08 | data, 0,03† | Diferencia de profundidad que se considera «mismo sitio» |
| radio_pegajoso_m | float (m) | 0–0,30 | data, 0,15† | Distancia a la que se retiene el objetivo actual |
| t_gracia_foco_s | float (s) | 0–0,3 | data, 0,12† | Tiempo de retención |

**Output Range:** un ID de objeto o nulo.
**Example:** Vera de pie a 1,40 m del teléfono `V02`, apuntando a su borde; el barrido de 6 cm de radio toca su colisionador a 1,38 m (≤ 1,8): objetivo. En `B02`/`B05` (dos contactos a 1,10 y 1,12 m, Δ = 0,02 ≤ 0,03) gana `B05` por `prioridad` 2 > 1.

### F2 · Progreso de la pulsación prolongada

`p = clamp((t_ahora − t_pulsado) / t_hold, 0, 1);   anillo visible si (t_ahora − t_pulsado) ≥ t_anillo_inicio_s;   largo si p = 1`

**Variables:** `t_hold` es el de Entrada F6 (0,5 s; 0,3–1,0; hasta 1,5 en accesibilidad); `t_anillo_inicio_s` 0,12 s† (0,05–0,25). El tiempo es el de juego (la pausa lo detiene).
**Output Range:** 0 a 1.
**Example:** con `t_hold` 0,5 s, a los 0,30 s p = 0,6 y el anillo es visible; soltar ahí dispara el verbo corto (si lo hay). Con `t_hold` = 1,5 s (accesible) el anillo aparece con p = 0,08.

### F3 · Distancia y giro de inspección

`d_ins = clamp(r / tan(θ_fill / 2), d_ins_min, d_ins_max);   q' = R_arriba(yaw_Δ · k_inspeccion) · R_derecha(pitch_Δ · k_inspeccion) · q`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| r | float (m) | > 0 | calculated | Radio de la esfera que envuelve el objeto |
| θ_fill | float (°) | 15–40 | data, 25† | Ángulo de visión que debe ocupar el objeto |
| d_ins_min / d_ins_max | float (m) | 0,20–0,40 / 0,40–0,80 | data, 0,25† / 0,60† | Distancia mínima y máxima a la cámara |
| yaw_Δ, pitch_Δ | float (°) | — | Entrada F2/F3 | Cambio de orientación del fotograma (con la inversión vertical del jugador) |
| k_inspeccion | float | 0,3–2,0 | data, 1,0† | Escala del giro del objeto respecto a la mirada |
| q | cuaternión | — | calculated | Orientación del objeto; inicial = `pose_inspeccion` |

**Output Range:** `d_ins` en metros; `q` sin límite (giro libre, normalizado).
**Example:** peluche `V05` (cubo de 0,12 m): r = 0,12·√3/2 = 0,104 m; tan(12,5°) = 0,2217 → d = 0,469 m (dentro de 0,25–0,60). Con yaw_Δ = 1,8° y k = 1 el objeto gira 1,8°.

### F4 · Transición de cámara (vista cercana y ordenador)

`s(x) = 3x² − 2x³;   x = clamp(t / T, 0, 1);   pos = lerp(pos₀, pos₁, s(x));   rot = slerp(rot₀, rot₁, s(x))`

**Variables:** `T` = `t_vista_entrada_s` de la vista (0,6–1,5 s; 1,0 para `D01a`) o `t_vista_salida_s` (0,3–1,0 s; 0,6†); `t` tiempo de juego desde el inicio. La transición nunca supera el tope de Entrada (3 s).
**Output Range:** posición y rotación de la cámara entre origen y anclaje.
**Example:** T = 1,0 s: s(0,25) = 0,156; s(0,5) = 0,5; s(0,75) = 0,844. Al pausar en x = 0,5 la cámara se queda ahí y reanuda desde ahí.

### F5 · Duración del pie de texto

`t_pie = clamp(0,5 + n / cps_pie, pie_min_s, pie_max_s)`

**Variables:** `n` caracteres del texto (≤ 90); `cps_pie` 14† (10–20), caracteres por segundo; `pie_min_s` 2,0† (1,5–3,0); `pie_max_s` 8,0† (4–12).
**Output Range:** 2,0 a 8,0 s.
**Example:** «Café frío. Lo dejó a las siete» (30 caracteres): 0,5 + 30/14 = 2,64 s. Un texto de 90 caracteres: 0,5 + 6,43 = 6,93 s.

### F6 · Píxeles por metro de una vista cercana

`ppm = (H_px / 2) / (d · tan(FOV_v / 2));   tolerancia_px = tolerancia_m · ppm`

**Variables:** `H_px` altura de la ventana en píxeles (1080 de referencia); `d` distancia de la cámara al plano de la vista (m); `FOV_v` campo de visión vertical (70°‡ según el slice A.0; el eje no está especificado); `tolerancia_m` tolerancia de un puzle en el espacio de la vista.
**Output Range:** píxeles por metro, positivo.
**Example:** `D01a`, d = 0,35 m, FOV_v = 70°: ppm = 540 / (0,35 · 0,7002) = 2.203 px/m; 0,04 m = 88 px y 0,10 m = 220 px. Si los 70° fueran el FOV horizontal (16:9), ppm = 3.917 px/m. **Esto sustituye el supuesto de 1.200 px/m de Entrada (Open Question 2)**: cada puzle entrega su tolerancia en metros y el sistema la convierte a píxeles con la vista real.

## Edge Cases

**Detección**
- **If dos interactuables se solapan en pantalla (nota bajo lámpara)**: regla 5 y F1; gana `prioridad`, nunca «el que se carga primero».
- **If el objeto enfocado queda detrás de una puerta que se abre o de otro objeto que se mueve**: el barrido es continuo; el objetivo se pierde en el fotograma siguiente a quedar ocluido (sin gracia por oclusión, solo por temblor, regla 7).
- **If el jugador mira un objeto desde más de `alcance_interaccion_m`**: no hay objetivo; ningún icono. El slice no tiene «marcadores a distancia».
- **If un objeto deshabilitado se enfoca**: no hay icono ni reacción (regla 8). `SFX_CLICK_SUBTLE` no suena porque no se ha interpretado la pulsación como interacción.
- **If el barrido empieza dentro de un colisionador** (cámara pegada a una pared): se ignora ese contacto; la cámara la gobierna el sistema 2.
- **If se retira un objeto (se coge) mientras es el objetivo**: el objetivo pasa a nulo ese fotograma; la pulsación en curso se cancela.

**Pulsación**
- **If se mantiene `interactuar` sobre un objeto sin `verbo_largo`**: se dispara al pulsar y la tecla mantenida no repite (enfriamiento y regla 10 de Entrada).
- **If se suelta `interactuar` antes de `t_hold` sobre un objeto solo `leer`**: no abre; el anillo pulsa una vez y suena `SFX_CLICK_SUBTLE` (regla 9).
- **If el objetivo cambia durante la pulsación prolongada**: si el rayo sale del radio pegajoso más de `t_gracia_foco_s`, la pulsación se cancela sin disparar nada.
- **If se pulsa a la vez con teclado y mando**: la primera entrada procesada abre el modo; la segunda se descarta por enfriamiento.
- **If `interactuar` se pulsa durante una transición que bloquea el contexto**: se descarta y no se guarda (Entrada, regla 8).
- **If el jugador activa el modo «alternar en lugar de mantener»** (Entrada, regla 14): `leer` empieza con una pulsación y se completa con la segunda tras `t_hold`; el anillo queda a la vista hasta completarse o cancelarse con `atrás`.

**Inspección**
- **If el objeto en la mano tiene detalle en una cara que el jugador no gira**: no hay aviso ni pista forzosa; el detalle es información incompleta (pilar *Información incompleta*).
- **If se pausa con el objeto en la mano**: al reanudar sigue en la misma orientación (Entrada, regla 6).
- **If un evento del mundo ocurre mientras se inspecciona** (megafonía, parpadeo): sucede con normalidad; no se cierra la inspección.
- **If una escena dirigida necesita las manos de Vera**: el director pide `cerrar_modos()` (regla 27) antes de pedir `sin control`.

**Lectura**
- **If el documento tiene una sola página y se pulsa `interactuar`**: no ocurre nada; `atrás` cierra.
- **If se cierra la lectura antes de `lectura_min_s`**: no se emite «lectura completada»; se puede volver a leer sin coste.
- **If se abre otro documento antes de cerrar el primero**: no es posible; `lectura` es un contexto único.
- **If el jugador pausa durante la cuenta de `lectura_min_s`**: la cuenta se detiene (tiempo de juego).

**Vista cercana**
- **If el jugador pulsa `atrás` antes de que acabe la transición de entrada**: se ignora (Entrada, regla 8); a los 3 s como máximo se libera.
- **If una vista se abre con `requiere_ítem` y falta el ítem**: se abre igualmente; el marco (9) decide qué mostrar (Edge Cases de 9). No hay mensaje de este sistema.
- **If el cursor virtual sale de la zona de la vista**: Entrada lo detiene en el borde (Entrada, edge case de gestos).
- **If se suelta `seleccionar` fuera de todo elemento durante `agarrar`**: se entrega `fin` con `elemento` nulo; el receptor decide a dónde vuelve la pieza.
- **If un elemento es menor que `pick_min_px`**: el hit-test se amplía hasta el mínimo; si dos elementos ampliados se solapan, gana el más cercano al centro del cursor; en desarrollo se registra una advertencia por incumplir la regla 22.
- **If dos elementos están a menos de 2·R y la atracción asistida está activa**: la ambigüedad es de Entrada (F5b: gana el más cercano a la dirección del stick); este sistema no corrige y la advertencia de la regla 22 lo señala en desarrollo.
- **If la vista se cierra durante un `agarrar`**: `cancelación` antes del cierre (regla 23).
- **If el jugador carga una partida con una vista abierta**: no existe tal estado; al cargar, la escena se recrea en `exploración` (GDD del 4, regla 10).

**Escenas y estado**
- **If la escena se descarga con un modo abierto**: Entrada reinicia su pila a `sin control`; este sistema libera los recursos y no emite avisos de cierre (los suscriptores desaparecen con la escena).
- **If el catálogo declara un ID que la escena no tiene (o al revés)**: en desarrollo, error visible al configurar; en la build final, el objeto no es interactuable y se registra una línea.
- **If `habilitado_si` cita un hecho no declarado en el catálogo del 3**: error de datos en desarrollo (regla 6 del GDD del 3); en la build final el objeto queda deshabilitado y se registra.

## Dependencies

**Aguas arriba (de qué depende)**

| Sistema | Tipo | Qué necesita |
|---|---|---|
| 1 Entrada y controles | Dura | Las acciones (`interactuar`, `leer`, `rotar_objeto`, `atrás`, gestos de puntero), la pila de contextos y el dispositivo activo |
| 2 Jugador en primera persona | Dura (**GDD sin redactar: supuestos**) | A1: la transformación de la cámara para lanzar el barrido; A2: bloquear y desbloquear la cámara en un anclaje con transición, y fijar el campo de visión; A3: reproducir una animación de manos por ID (`ANIM_HAND_*`) y ocultar las manos; A4: devolver el eje de la cámara y el FOV vertical. Si el GDD del 2 los contradice, se actualiza este documento |
| 18 Base de contenido narrativo | Dura | Claves de etiquetas («Abrir», «Girar», «Examinar», «Leer», «Usar»…), `OBJ_<id>` y documentos |
| 3 Estado y bus de eventos | Blanda | Lee hechos para `habilitado_si`; emite los avisos de la regla 29 |

El **índice** lista como dependencias 1, 2 y 18; falta el 3 como blanda (propuesta en «Propuesta de registro»).

**Aguas abajo (quién depende de este sistema)**

| Sistema | Tipo | Interfaz |
|---|---|---|
| 8 Control de acceso | Dura | Manejadores de puertas, lectores, ascensor |
| 9 Marco de puzles | Dura | Vista cercana, `PointerEvent`, activaciones del modo `MUNDO` |
| 10 Caja y compartimentos | Dura | Manejadores `D01a`–`D01d` y apertura de la vista |
| 11–16 Puzles | Indirecta (vía 9) | Gestos de puntero |
| 19 Ordenador, correo e impresora | Dura | `ABRIR_ORDENADOR`, cursor, `V08` |
| 20 Documentos y bolsillo | Dura | `LEER`, «lectura completada» |
| 22 Llamada telefónica | Dura | `V02` |
| 24 Prompt de interacción y feedback | Dura | `get_target()` |
| 21 Director de escenas | Blanda | `cerrar_modos()`, «interacción ejecutada» |
| 28 Atmósfera reactiva · 23 Audio | Blanda | «interacción ejecutada» |

**Bidireccionalidad.** El GDD de Entrada ya lista a este sistema como dependiente (reglas 6, 10 y 11; tabla de Dependencies). El GDD del 18 lo lista en su tabla de interacciones («7 Interacción · 8 Control de acceso · 24 Prompt · 25 Pausa»). El GDD del 3 lo trata como indirecto. Ningún otro sistema tiene GDD aún: cada uno debe, al redactarse, listar a Interacción e inspección y usar los nombres del contrato de la regla 3.

## Tuning Knobs

Categorías: **F** = feel (se afina jugando), **C** = curva, **G** = gate (ritmo). Todos viven en `assets/data/interaction/` (nunca en código).

| Knob | Cat. | Defecto | Rango seguro | Qué afecta y por qué ese valor |
|---|---|---|---|---|
| `alcance_interaccion_m` | F | 1,8† | 1,2–3,0 | Distancia de mano. Los despachos miden 5–6 m; con 1,8 m se alcanza el escritorio desde la silla sin pegarse. Muy alto: iconos por toda la sala (ruido); muy bajo: obliga a pegarse |
| `radio_apuntado_m` | F | 0,06† | 0–0,15 | Tolerancia de puntería. Cubre el teléfono (15 × 8 cm). Muy alto: se enfoca lo que no se mira |
| `radio_pegajoso_m` / `t_gracia_foco_s` | F | 0,15† / 0,12 s† | 0–0,3 / 0–0,3 | Estabilidad del icono ante temblor; accesibilidad motriz |
| `desempate_prof_m` | F | 0,03† | 0,01–0,08 | Resolución entre objetos apilados |
| `t_anillo_inicio_s` | F | 0,12† | 0,05–0,25 | Que un toque no haga parpadear el anillo |
| `t_enfriamiento_s` | F | 0,25† | 0,1–0,6 | Evita dobles disparos; muy alto parece lento |
| `latencia_feedback_ms` | F | 100† | 50–200 | Tope de respuesta percibida (criterio, no mecanismo) |
| `t_mano_s` | F | 0,4† | 0,2–0,8 | Coger y devolver en la inspección |
| `theta_fill_deg` / `d_ins_min` / `d_ins_max` | F | 25° / 0,25 / 0,60† | 15–40 / 0,2–0,4 / 0,4–0,8 | Tamaño del objeto en la mano |
| `k_inspeccion` | F | 1,0† | 0,3–2,0 | Sensibilidad del giro; el ajuste de sensibilidad del jugador (Entrada) multiplica |
| `t_vista_entrada_s` (por vista) | F | 1,0 (`D01a`)† | 0,6–1,5 | Peso del gesto de acercarse; la entrada no puede superar 3 s |
| `t_vista_salida_s` | F | 0,6† | 0,3–1,0 | Salida más rápida que la entrada: el jugador tiene el control |
| `pick_min_px` | F | 44† | 32–64 | Tamaño mínimo de objetivo en 1080p; accesibilidad motriz |
| `cps_pie` / `pie_min_s` / `pie_max_s` | F | 14 / 2,0 / 8,0† | 10–20 / 1,5–3 / 4–12 | Lectura cómoda de pies; con el subtítulo largo no es pie |
| `texto_max_caracteres` | C | 90† | 60–140 | Frontera entre pie y documento |
| `lectura_min_s` (por documento) | G | 2,0 para `A04`† | 0–5 | Cuánto hay que mirar el formulario para contarlo como leído |
| `t_hold` | F | **de Entrada** (0,5) | 0,3–1,0 (1,5 acc.) | No se duplica aquí |

## Visual/Audio Requirements

*(Sección opcional para la categoría Gameplay; en modo `lean` no se consulta a `art-director` ni a `audio-director`: revisar antes de producción.)*

- **Icono y anillo:** los define el art bible (§3.3 y §7.3); este sistema solo da el objetivo, la etiqueta y `p` de F2. El anillo no es barra; el cursor de las vistas no es un círculo (Entrada, Visual/Audio).
- **Manos:** animaciones por verbo (`ANIM_HAND_OPEN`, `ANIM_HAND_TAKE`, `ANIM_HAND_TURN`, `ANIM_HAND_READ`, `ANIM_HAND_PRESS`): nombres propuestos ‡ a validar con animación. Las que declaran `bloquea_s` dependen del slice (`ANIM_PHONE_PICKUP` 0,8 s, `ANIM_PAGE_TURN`).
- **Audio:** `SFX_CLICK_SUBTLE` para toda interacción sin efecto. Los demás sonidos los emite el dueño del objeto. Al entrar en `inspección` y `lectura` el mundo se atenúa levemente (propuesta a `audio-director`).
- **Inspección:** el objeto en la mano se ilumina con una luz de relleno propia para que sus detalles sean legibles incluso en la oscuridad de la escena (pilar *El espacio expresa la emoción* sin sacrificar legibilidad).

## Game Feel

- **Respuesta:** cada pulsación procesada responde en ≤ `latencia_feedback_ms` (100†).
- **Foco:** el icono aparece y desaparece sin parpadeo ante el temblor; no se «roba» el foco entre objetos apilados.
- **Inspección:** el objeto responde al giro sin retardo ni inercia; un objeto pequeño llena aproximadamente un cuarto del campo de visión (F3).
- **Vista cercana:** la cámara se acerca con una curva suave (F4) y se siente deliberada, no lenta; salir es más rápido que entrar.
- **Referencia de comparación:** los valores † se afinan en el primer playtest (slice §23.4) frente a otros juegos de caminar en primera persona (por elegir, como en Entrada).

## UI Requirements

- **Prompt (24):** icono discreto (§16) con etiqueta del verbo, glifo según el dispositivo activo (Entrada, regla 3) y anillo de progreso para `leer`.
- **Pie de objeto:** texto no bloqueante abajo-centro, dentro de los márgenes seguros del 5 % (art bible §4.5), con clave `OBJ_<id>`.
- **Pantalla de lectura:** contenido y estilo por el sistema 20; este sistema solo pide abrirla y cerrarla.
- **Cursor de vista:** visible con ratón y mando (cursor virtual), forma no circular; definición visual en la fase de UX.
- **Sin inventario ni menú de objetos** en el slice (D.1 del slice).

📌 **UX Flag — Interacción e inspección**: el prompt, el pie de objeto, la pantalla de lectura y la presentación de la vista cercana tienen requisitos de interfaz. En preproducción, ejecuta `/ux-design` antes de escribir las épicas.

## Cross-References

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · §5 y §16 | Una sola tecla contextual; girar objetos; pulsación prolongada para leer; icono discreto; feedback en cada acción | Define el alcance |
| `design/slice/slice-v0.3.md` · Anexo A (A.2 a A.7) | Objetos interactuables, IDs, verbos y estados | Fuente del catálogo de `interactables.json` |
| `design/slice/slice-v0.3.md` · Anexo B (B.1, B.3, B.5) | Vista cercana 0,35 m y 1,0 s (B.3); `CLICK`/`PULSAR`/`ARRASTRAR`/`ROTAR` | Origen de F4 y de los gestos |
| `design/slice/slice-v0.3.md` · A.4 | «Leer (2 s)» del formulario | Interpretación de `lectura_min_s` |
| `design/slice/slice-v0.3.md` · D.1 | Ítems y bolsillo visual sin menú | Justifica la ausencia de inventario |
| `design/gdd/entrada-y-controles.md` · reglas 6, 8, 10–13, 14, F6, F8 y Open Questions 2 y 3 | Contextos, gestos, pulsación prolongada y transiciones | Contrato directo; F6 resuelve la Open Question 2 |
| `design/gdd/base-de-contenido-narrativo.md` · reglas 1, 3 | Etiquetas, `OBJ_`, documentos y estilos | Origen de los textos |
| `design/gdd/estado-y-bus-de-eventos.md` · regla 10 | Documentación de avisos por el emisor | Los avisos de la regla 29 se añaden allí |
| `design/gdd/escena-de-planta.md` · reglas 4, 9.6 y 10 | Contenedores e IDs; configuración leyendo hechos; punto de aparición | Los objetos se localizan por ID |
| `design/gdd/game-pillars.md` | *Autonomía como progresión*, *Tensión sin castigo*, *Información incompleta* | Pilares que este sistema sirve |
| `design/gdd/marco-de-puzles.md` | Receptor de las vistas de puzle y modo `MUNDO` | Sistema que consume este |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/interaction/`), bloqueante; **I** = test de integración o playtest documentado (`tests/integration/interaction/`), bloqueante; **V** = captura retenida en `production/qa/evidence/`, bloqueante. Los tests L usan un mundo de física falso, un reloj inyectado y un catálogo de prueba. Tolerancia numérica ±0,001 salvo indicación. Los valores † pueden cambiar tras el playtest.

**Detección (reglas 2 a 8, F1)**
- **AC-01 (R2, L)**: **GIVEN** un objeto del mundo que no está en `interactables.json`, **WHEN** el barrido lo toca, **THEN** no es objetivo.
- **AC-02 (R5, F1, L)**: **GIVEN** el teléfono a 1,38 m y alcance 1,8, **WHEN** el barrido lo toca, **THEN** es el objetivo; **GIVEN** que está a 1,9 m, **THEN** no hay objetivo.
- **AC-03 (R5, L)**: **GIVEN** una pared entre la cámara y un objeto a 1,0 m, **THEN** no hay objetivo.
- **AC-04 (R5, F1, L)**: **GIVEN** `B02` a 1,10 m y `B05` a 1,12 m (prioridad 1 y 2), **THEN** el objetivo es `B05`; **GIVEN** que `B05` está a 1,20 m (Δ = 0,10 m > 0,03), **THEN** es `B02`.
- **AC-05 (R7, L)**: **GIVEN** un objetivo, **WHEN** el rayo lo pierde durante 0,10 s y vuelve, **THEN** el objetivo no cambia ni se emite pérdida; **WHEN** lo pierde durante 0,13 s y ningún otro objeto está a menos de `radio_pegajoso_m`, **THEN** el objetivo pasa a nulo.
- **AC-06 (R8, L)**: **GIVEN** un objeto con `habilitado_si = {todos: [caja_c1]}` y `caja_c1` falso, **THEN** no es objetivo; **WHEN** `caja_c1` pasa a verdadero, **THEN** lo es en el fotograma siguiente.
- **AC-07 (R5, L)**: **GIVEN** un contexto distinto de `exploración`, **THEN** el barrido no se ejecuta y no hay objetivo.

**Pulsación (reglas 9 a 12, F2)**
- **AC-08 (R9, L)**: **GIVEN** un objeto solo con `verbo_corto`, **WHEN** se pulsa `interactuar`, **THEN** el verbo se dispara en ese fotograma.
- **AC-09 (R9, F2, L)**: **GIVEN** un objeto con `verbo_corto` y `verbo_largo` y `t_hold` = 0,5 s, **WHEN** se mantiene 0,18 s y se suelta, **THEN** se dispara el verbo corto al soltar; **WHEN** se mantiene 0,62 s, **THEN** se dispara `leer` a los 0,50 s y la suelta posterior no dispara nada.
- **AC-10 (R9, F2, L)**: **GIVEN** `t_hold` = 0,5 y 0,30 s mantenidos, **THEN** p = 0,6 y el anillo es visible; **GIVEN** 0,10 s, **THEN** el anillo no es visible.
- **AC-11 (R9, L)**: **GIVEN** un objeto solo `leer` (`B05`), **WHEN** se pulsa un toque corto, **THEN** no se abre `lectura` y suena `SFX_CLICK_SUBTLE`.
- **AC-12 (R10, L)**: **GIVEN** un objeto en enfriamiento de 0,25 s, **WHEN** se pulsa a los 0,10 s, **THEN** se descarta; a los 0,30 s, se procesa.
- **AC-13 (R10, L)**: **GIVEN** `V02` con `bloquea_s` 0,8, **WHEN** se activa, **THEN** se pide `sin control` con duración declarada 0,8 s y se libera a los 0,8 s.
- **AC-14 (R11, L)**: **GIVEN** un objeto cuyo manejador devuelve `SIN_EFECTO`, **THEN** suena `SFX_CLICK_SUBTLE` dentro de `latencia_feedback_ms` y, si tiene `texto`, se pide el pie.
- **AC-15 (R12, F5, L)**: **GIVEN** el texto de 30 caracteres, **THEN** el pie dura 2,64 s (±0,01); un texto de 90 caracteres dura 6,93 s; uno de 120 caracteres se rechaza en datos (excede `texto_max_caracteres`).
- **AC-16 (R28, L)**: **GIVEN** una pulsación prolongada en curso, **WHEN** llega `pausa`, **THEN** se cancela sin disparar `leer`.

**Inspección (reglas 13 a 15, F3)**
- **AC-17 (R13, F3, L)**: **GIVEN** el peluche (r = 0,104 m), **THEN** `d_ins` = 0,469 m (±0,005); **GIVEN** un objeto con r = 0,02 m, **THEN** se limita a 0,25 m; **GIVEN** r = 0,5 m, **THEN** 0,60 m.
- **AC-18 (R14, L)**: **GIVEN** `inspección` con yaw_Δ = 1,8° y `k_inspeccion` = 1, **THEN** el objeto gira 1,8° y la cámara no gira; **WHEN** se gira 3.600°, **THEN** no hay tope.
- **AC-19 (R15, L)**: **WHEN** llega `atrás` en `inspección`, **THEN** el objeto vuelve a su sitio en `t_mano_s` y el contexto vuelve a `exploración`; no se ha escrito ningún hecho.
- **AC-20 (R13, I)**: **GIVEN** `V05` en la mano, **WHEN** se gira hasta ver la pegatina, **THEN** el detalle es legible (playtest documentado, 3 de 3 testers).
- **AC-21 (R13, I)**: **GIVEN** `inspección` abierta, **WHEN** suena `MEGA_01`, **THEN** la megafonía suena y la inspección no se cierra.

**Lectura (reglas 16 a 18)**
- **AC-22 (R16, L)**: **GIVEN** `A04`, **WHEN** se mantiene `interactuar` 0,5 s, **THEN** se pide `lectura` con la clave del formulario y su estilo.
- **AC-23 (R17, L)**: **GIVEN** `R01` con dos páginas en la página 1, **WHEN** llega `interactuar`, **THEN** pasa a la página 2 (`ANIM_PAGE_TURN`); **WHEN** llega otra vez, **THEN** no hace nada.
- **AC-24 (R18, L)**: **GIVEN** `A04` con `lectura_min_s` 2,0, **WHEN** `lectura` permanece abierta 2,0 s de tiempo de juego, **THEN** se emite una sola vez «lectura completada» (`A04`); **WHEN** se cierra a 1,9 s, **THEN** no se emite.
- **AC-25 (R18, L)**: **GIVEN** `lectura` abierta con la pausa de 10 s, **THEN** el contador no avanza durante la pausa.

**Vista cercana y ordenador (reglas 19 a 24, F4, F6)**
- **AC-26 (R19, F4, L)**: **GIVEN** `D01a` con `t_vista_entrada_s` 1,0 s, **THEN** la cámara llega al anclaje a 0,35 m del marco en 1,0 s; a 0,5 s está a mitad de camino (s = 0,5); **WHEN** el tiempo supera 3 s sin acabar, **THEN** se libera el contexto y se registra el error (Entrada, F8).
- **AC-27 (R19, L)**: **GIVEN** `D01a` abierto, **THEN** se emite una sola vez «vista cercana abierta» con el ID de la vista y el cursor aparece en el centro.
- **AC-28 (R20, L)**: **GIVEN** una vista abierta, **WHEN** el cursor se mueve sobre un elemento, **THEN** el receptor recibe `PointerEvent` con `elemento` = ID y `pos_vista` en metros; **WHEN** se hace `agarrar`, **THEN** recibe `inicio`, `actualización`… y `fin` con la misma `elemento` aunque el cursor salga.
- **AC-29 (R21, L)**: **GIVEN** un `agarrar` en curso, **WHEN** llega `atrás`, **THEN** el receptor recibe `cancelación` antes del aviso de cierre.
- **AC-30 (R22, L)**: **GIVEN** un elemento de 20 px de lado, **THEN** su hit-test es de al menos 44 px; **GIVEN** dos elementos con centros a menos de 128 px, **THEN** en desarrollo se registra una advertencia.
- **AC-31 (R23, L)**: **WHEN** llega `atrás` con la vista abierta, **THEN** la cámara vuelve en 0,6 s, se emite «vista cercana cerrada» con motivo `jugador` y el contexto vuelve a `exploración`; **WHEN** llega `atrás` durante la entrada, **THEN** se ignora.
- **AC-32 (F6, L)**: **GIVEN** H = 1080, d = 0,35 m, FOV_v = 70°, **THEN** ppm = 2.203 (±1), 0,04 m = 88 px (±0,5) y 0,10 m = 220 px (±0,5); con FOV horizontal 70° en 16:9, ppm = 3.917 (±2).
- **AC-33 (R24, I)**: **GIVEN** `V01`, **WHEN** se activa, **THEN** Entrada entra en `ordenador`, la cámara se acerca a la pantalla y `atrás` sale.

**Estado y escenas (reglas 3, 4, 27)**
- **AC-34 (R4, L)**: **GIVEN** cualquier partida, **THEN** este sistema no escribe ningún hecho ni guarda nada.
- **AC-35 (R27, L)**: **GIVEN** `lectura` abierta, **WHEN** el director pide `cerrar_modos()`, **THEN** se cierra con motivo `sistema` y se emite el aviso; **GIVEN** `ordenador` abierto, **THEN** no se cierra.
- **AC-36 (R3, L)**: **GIVEN** un manejador que devuelve `HECHO`, **THEN** se emite «interacción ejecutada» con el ID, el verbo y el resultado.
- **AC-37 (R6, R8, L)**: **GIVEN** el catálogo del slice, **THEN** `V07`, `R03` y la puerta de salida de Recepción no están en él, y todos los IDs del slice con interacción (Anexo A) sí.

**Criterios de experiencia (playtest, I)**
- **AC-X1 (I)**: **GIVEN** un jugador nuevo, **WHEN** juega la escena 1 sin guía, **THEN** abre el ordenador y descuelga el teléfono sin preguntar cómo interactuar (≥ 4 de 5 testers; slice §19.1).
- **AC-X2 (I)**: **GIVEN** un tester con temblor simulado (ratón con ruido de 6 px), **WHEN** intenta leer `A04`, **THEN** completa la lectura prolongada sin que el icono parpadee.
- **AC-X3 (I)**: **GIVEN** el recorrido completo del slice, **THEN** ningún tester informa de un objeto que «no deja interactuar» ni de una pulsación sin respuesta.

## Decisiones tomadas

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D7-1 | Un solo sistema posee foco, verbos y los tres modos de mirada | Un sistema por modo (inspección, lectura, vista) | Comparten transición de cámara, pila de contextos de Entrada y el mismo contrato con los dueños; separarlos duplicaría el foco |
| D7-2 | Catálogo en datos con contrato de manejador del dueño | Cada objeto con su script de interacción | Coding standards (datos fuera de código); permite comprobar de forma automática que cada ID del slice está |
| D7-3 | Barrido de esfera de 6 cm con histéresis (gracia + radio pegajoso) | Rayo puntual sin gracia | Objetos pequeños (teléfono) y temblor motriz: accesibilidad sin ayuda visual extra |
| D7-4 | Un objeto deshabilitado no muestra icono | Icono atenuado con «aún no» | Pilar *Autonomía como progresión*: el icono revela que hay algo que hacer; lo no disponible lo explica su dueño con `SIN_EFECTO` |
| D7-5 | Objeto solo `leer`: el toque corto no abre y avisa | El toque corto también abre | Fidelidad al slice (§5, pulsación prolongada para leer); `alternar` de Entrada cubre la accesibilidad |
| D7-6 | Inspección en la mano solo para objetos pequeños; el resto, pie de texto no bloqueante | Todo objeto con modo de inspección | Evita contextos innecesarios (pilar *Tensión sin castigo*: nada que bloquee) y trabajo de arte de rotación en objetos fijos |
| D7-7 | El mundo no se detiene en inspección ni lectura | Pausa del tiempo al inspeccionar | Mantiene la tensión (megafonía, parpadeo); no hay temporizadores de puzle que puedan castigar |
| D7-8 | `lectura_min_s` = 2 s para el formulario, con aviso «lectura completada» | Marcar leído al abrir | «Leer (2 s)» del slice A.4; evita que abrir y cerrar cuente como leer |
| D7-9 | La conversión píxeles ↔ metros se calcula por vista (F6) | Constante fija de 1.200 px/m | Depende de FOV, distancia y resolución; sustituye el supuesto de Entrada |
| D7-10 | El cambio de objetivo no viaja por el bus (24 consulta cada fotograma) | Aviso «objetivo cambiado» | Valor transitorio por fotograma; saturaría el bus |
| D7-11 | `atrás` siempre cierra una vista (salvo ≤ 3 s de transición) | Puzles que impiden salir mientras algo se resuelve | Pilar *Tensión sin castigo*: sin fallos ni encierros |

## Open Questions

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | **Contrato con el sistema 2** (supuestos A1 a A4: transformada de cámara, bloqueo de cámara con transición y FOV, animaciones de manos, eje del FOV 70°). No cambia pilares, pero fija una interfaz | GDD del sistema 2 | GDD del sistema 2 |
| 2 | **Nombres de animaciones de manos** `ANIM_HAND_*` y las claves de etiqueta de verbo (`UI_VERBO_*`) que faltan en la base de contenido | Animación y GDD del 18 | Preproducción |

## Propuesta de registro

Para `design/registry/entities.yaml` (no se edita aquí; lo hará quien consolide):

| Tipo | Nombre | Valor / contenido | Fuente |
|---|---|---|---|
| constante | `alcance_interaccion_m` | 1,8 m† (1,2–3,0) | este GDD, Tuning Knobs |
| constante | `radio_apuntado_m` | 0,06 m† | este GDD, F1 |
| constante | `pick_min_px` | 44 px† | este GDD, regla 22 |
| constante | `lectura_min_s_A04` | 2,0 s† | este GDD, regla 18; slice A.4 |
| constante | `t_vista_entrada_D01a_s` | 1,0 s | slice B.3 |
| fórmula | `F6_ppm` | `(H/2)/(d·tan(FOV_v/2))`; 2.203 px/m en `D01a` | este GDD |
| aviso | «vista cercana abierta/cerrada», «lectura completada», «interacción ejecutada» | emisor: 7 | este GDD, regla 29 |
| dato | `assets/data/interaction/interactables.json` | catálogo de objetos | este GDD, regla 2 |
| dependencia | índice, fila 7 | añadir la dependencia blanda `3` | este GDD |
