# Interacción e inspección

> **Status**: Revisado — pendiente de re-review (aplica `reviews/interaccion-e-inspeccion-review.md`, H-01 a H-20)
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Autonomía como progresión (el jugador decide qué mirar y qué tocar) · Tensión sin castigo (un solo botón, sin precisión temporal, nunca bloquea) · Información incompleta (inspeccionar describe, nunca confirma intenciones)

## Summary

Es lo que permite a Vera tocar el mundo: decide qué objeto tiene delante, qué ofrece el botón contextual (activar, examinar, leer, abrir un puzle), y lleva al jugador a los modos de mirar de cerca: girar un objeto en la mano, leer un documento o acercarse a un panel de puzle. No decide qué *hace* cada objeto (eso es de quien lo posee: puertas, ordenador, puzles…); decide *cómo se llega a él* y que siempre se sienta igual. Existe porque el slice se juega con un único botón y porque descubrir objetos con la mirada es la forma de avanzar del pilar *Autonomía como progresión*.

> **Quick reference** — Layer: `Feature` (categoría `Gameplay`) · Priority: `MVP` · Key deps: `1 Entrada y controles`, `2 Jugador en primera persona`, `18 Base de contenido narrativo` (blanda: `3 Estado y bus`)

## Overview

Interacción e inspección es la capa entre el jugador y los objetos del mundo. En `exploración`, cada paso de física lanza un barrido desde los ojos de Vera (rayo de visión del Jugador, sin balanceo) y decide cuál es el **objetivo de interacción**: el objeto interactuable al que se mira, a alcance de mano y sin nada delante. Si hay uno, el sistema de prompt (24) muestra el icono discreto del slice (§16) con la etiqueta del verbo («Abrir», «Girar», «Examinar», «Leer»). El jugador pulsa `interactuar` y ocurre lo que ese objeto declara.

Cada objeto interactuable se describe en datos (`assets/data/interaction/interactables.json`) con sus IDs del slice (`V02`, `B01`, `D01a`…): qué verbo ofrece con pulsación corta, cuál con pulsación prolongada (`leer`), cuándo está habilitado y qué efecto genérico tiene. El efecto puede ser **delegar** en el dueño del objeto (los lectores y el ascensor los lleva Control de acceso 8; el teléfono, la Llamada 22), o uno de los tres modos propios de este sistema: **inspección** (objeto pequeño girado en la mano), **lectura** (documento a pantalla) y **vista cercana** (cámara acercada a un panel, con cursor, para los puzles y el ordenador).

El sistema no guarda estado propio: lo que un objeto «es» (abierto, leído, usado) son hechos del juego (3) escritos por su dueño. Existe por tres razones: (1) el slice se maneja con *una sola tecla contextual* y esa promesa debe cumplirse igual en las 35 entradas del catálogo del slice; (2) todos los puzles necesitan el mismo puente entre el cursor y sus piezas (apuntar, agarrar, rotar), y resolverlo una vez evita que cada puzle reinvente su control; (3) mirar de cerca y leer son el verbo central del juego —*descubrir qué pasó*— y deben ser cómodos, nunca punitivos: no hay tiempo, no hay fallos y siempre se puede volver atrás.

## Player Fantasy

Vera es una persona cansada en una planta vacía que **mira antes de tocar**. El jugador siente que cada objeto tiene un peso: la taza fría que alguien dejó a las siete, el peluche cúbico con la pegatina del equipo antiguo, el formulario que se lee despacio. Sentir (aesthetics del MDA): **Discovery** (encontrar el detalle en la mano), **Sensation** (manos que cogen, giran y pasan páginas) y **Narrative** (la información llega al ritmo de la mirada). Nunca debe sentir que «pelea con el apuntado» o que pierde algo por haber pulsado mal.

## Detailed Design

### Core Rules

‡ = propuesta que debe confirmar el GDD del sistema afectado (aún sin redactar). † = valor propuesto, a validar en playtest. Los identificadores de código van en inglés; los IDs del slice (`V02`, `I-01`, `SFX_CLICK_SUBTLE`…) se conservan tal cual.

**Reparto de responsabilidades**

1. **Qué hace y qué no.** Este sistema *detecta* el objetivo, *interpreta* la pulsación y *hospeda* tres modos de mirada (inspección, lectura, vista cercana). **No** decide el resultado de activar un objeto: lo hace su dueño a través del contrato de la regla 3. Tampoco dibuja el icono (24), ni muestra los documentos (20), ni valida puzles (9).
2. **Catálogo en datos.** Los objetos interactuables se declaran en `assets/data/interaction/interactables.json` (esquema y ejemplo en la regla 31). Cada entrada tiene: `id` (el del slice), `verbo_corto` (nullable), `verbo_largo` (nullable, solo `leer`), `etiqueta_corto` y `etiqueta_largo` (claves de la base de contenido 18; el manejador puede sustituirlas según el estado, regla 3), `efecto` (ver regla 6), `habilitado_si` (condición sobre hechos: lista `todos` y lista `ninguno`), `alcance_m` (opcional, por defecto el global), `prioridad` (entero, 0 por defecto), `gesto_hecho` (ID de gesto `HAND_*` del Jugador que se reproduce cuando el manejador devuelve `HECHO`; opcional), `texto` (clave `OBJ_<id>` si procede) y los datos del modo que abre (pose de inspección, vista, documento). **No hay duración de bloqueo en el catálogo:** la duración de cada gesto es la del Jugador (regla 10). Un objeto que no está en el catálogo **no es interactuable** (por ejemplo `V07` el umbral, `R03` el ventanal, `B04`, `D-MOB-*`; lista completa en el Anexo de cobertura, regla 31).
3. **Contrato del dueño.** Cada sistema dueño de objetos (8, 10, 19, 20, 22, 9, 28) registra un manejador por ID (`registrar_manejador`, regla 30) con estas operaciones:
   - `can_interact(verbo) -> {SI, NO, SIN_EFECTO}`: función pura y barata (sin efectos), consultada solo para los candidatos del barrido que pasan `habilitado_si` y para el objetivo retenido, en cada paso de física. `SI`: el objeto es objetivo, con icono. **`NO`: el objeto no está disponible ahora y se trata exactamente como deshabilitado (regla 8): sin icono, sin reacción, sin `SFX_CLICK_SUBTLE`; si era el objetivo, deja de serlo en ese mismo paso, sin gracia.** `SIN_EFECTO`: es objetivo con icono, pero al pulsar no cambia nada (suena `SFX_CLICK_SUBTLE` y, si hay `texto`, se muestra el pie).
   - `etiqueta(verbo) -> clave | nulo` (opcional): permite al dueño dar la etiqueta según el estado («Encender»/«Apagar» en `V06`). Si devuelve nulo, se usa `etiqueta_corto`/`etiqueta_largo` del catálogo. 24 recibe la clave ya resuelta con `get_target()`.
   - `interact(verbo, contexto) -> {HECHO, SIN_EFECTO}`. Con `HECHO` se reproduce `gesto_hecho` (regla 10); con `SIN_EFECTO` suena `SFX_CLICK_SUBTLE`, se muestra `texto` como pie (regla 12) y se reproduce `HAND_REACH`.
   El manejador es quien escribe hechos y quien emite sus propios avisos; este sistema nunca escribe hechos.
4. **Sin estado propio.** No se guarda nada de este sistema. Al cargar la escena el objetivo está vacío y ningún modo está abierto. El estado de cada objeto lo reconstruyen sus dueños leyendo hechos (GDD del 4, regla 9.6).

**Detección del objetivo**

5. **Barrido de foco.** Solo en el contexto `exploración` y fuera de transiciones, **en cada paso de física** (60 Hz por defecto) se ejecuta el algoritmo de F1 con el **rayo de visión del Jugador** (origen en los ojos **sin balanceo**, dirección de la cámara; Jugador, reglas 16 y 19), no con la posición de la cámara con balanceo. Se usa la transformada del paso de física, no la interpolada de render (ver Open Questions, V5). En resumen: (a) se **recogen todos** los contactos de interactuables dentro de la esfera de radio `radio_apuntado_m` hasta su alcance; (b) se descartan los **ocluidos** por geometría del mundo; (c) de los que quedan, se elige el más cercano y, entre los que están a menos de `desempate_prof_m` de él, el que **contiene el eje exacto** del rayo, luego la mayor `prioridad`, luego el más cercano al eje y por último el ID menor. Los pasos exactos, con las máscaras de colisión, son F1. Un interactuable **plano sobre una superficie** (la nota `B05`, el formulario `A04`, el libro `R01`) no queda ocluido por esa superficie (F1, paso 2). El cuerpo del Jugador está en su propia capa y se excluye (Jugador, regla 5).
6. **Efectos genéricos.** Cada objeto declara un `efecto`:
   - `DELEGAR`: llama a `interact()` del dueño (cajones, interruptores, lectores, ascensor, teléfono, impresora, caja…). Ninguna puerta del slice es interactuable (se abren por disparador o por puzle; la de Recepción «no es interactuable», slice A.7).
   - `INSPECCION_MANO`: entra en `inspección` con el objeto en la mano (reglas 13 a 15). Solo objetos pequeños y manipulables.
   - `INSPECCION_TEXTO`: muestra el texto `OBJ_<id>` como pie, sin cambiar de contexto (regla 12).
   - `LEER`: abre `lectura` con un documento (reglas 16 a 18).
   - `ABRIR_VISTA`: abre `vista cercana` sobre un anclaje (reglas 19 a 23).
   - `ABRIR_ORDENADOR`: pide a Entrada el contexto `ordenador` y bloquea la cámara en el anclaje de `V01` (regla 24).
7. **Estabilidad del foco.** Cuando el barrido deja de elegir el objetivo actual, este se **retiene** mientras se cumplan **a la vez** (Y) dos condiciones: (i) han pasado como máximo `t_gracia_foco_s` desde que se perdió, medidos en **pasos de física** (a 60 Hz, 0,12 s = 7 pasos: se retiene durante 7 pasos y se pierde en el 8.º), y (ii) la distancia del rayo a su colisionador es ≤ `radio_pegajoso_m`. Si no se cumple alguna, el objetivo pasa a nulo. **Un candidato nuevo válido (F1) sustituye siempre al retenido en ese mismo paso**; la retención solo evita el parpadeo hacia «sin objetivo». Así el temblor del ratón o del stick no hace parpadear el icono ni cancela una pulsación prolongada, y mirar de un objeto a otro no tiene retardo. Un objeto que pasa a deshabilitado, a `NO` (regla 3) o se retira deja de ser objetivo en el mismo paso, sin gracia. No se emite ningún aviso de «pérdida» (regla 29).
8. **Habilitado no es visible.** Un objeto cuya condición `habilitado_si` es falsa, o cuyo manejador contesta `NO`, **no tiene icono ni reacciona** (no revela que existe una interacción futura; pilar *Autonomía como progresión*). `habilitado_si` se evalúa leyendo los hechos del 3 (lectura directa) **solo para los candidatos del paso de física actual**, no por suscripción: un cambio de hecho se ve en el paso siguiente. Los objetos que deben explicar por qué no ceden (los lectores de tarjeta sin tarjeta, un compartimento bloqueado) están habilitados y es su dueño quien contesta `SIN_EFECTO` con su texto. Criterio objeto a objeto: columna «Disponibilidad» de la tabla de objetos.

**Pulsación y verbos**

9. **Momento de disparo** (desarrolla la regla 10 de Entrada; `t_hold` es la clave `long_press_threshold` del registro). Si el objeto solo tiene `verbo_corto`, se dispara **al pulsar**. Si tiene `verbo_largo` (`leer`), la pulsación corta se decide **al soltar** (la combinación `verbo_corto` + `verbo_largo` es una capacidad del catálogo que **ningún objeto del slice usa**; ver D7-24) (si se suelta antes de `t_hold`) y la prolongada se dispara en cuanto el tiempo mantenido alcanza `t_hold` (F2). El anillo de progreso aparece a los `t_anillo_inicio_s` de mantener, no antes, para que un toque no parpadee. Si el objeto solo tiene `verbo_largo`, un toque corto no hace nada salvo hacer pulsar el anillo una vez y sonar `SFX_CLICK_SUBTLE`: la tecla *indica* que hay que mantener (slice §5: «pulsación prolongada para leer»).
10. **Enfriamiento y bloqueo por gesto.** Tras ejecutarse un verbo, el mismo objeto no admite otra pulsación hasta pasados `t_enfriamiento_s`, para evitar dobles disparos con un botón mantenido. **Los gestos de las manos son del Jugador** (2): nombres, catálogo y duraciones están en su sección Visual/Audio (`HAND_REACH` ≤ 0,5 s, `HAND_DRAWER` ≤ 1,2 s, `HAND_TURN` ≤ 0,8 s, `HAND_CARD_SWIPE` ≤ 1,0 s, `ANIM_PAGE_TURN` ≤ 1,0 s, `ANIM_PHONE_PICKUP` 0,8 s…) y este documento **no los repite ni los acota**. Cuando este sistema pide un gesto que el Jugador marca «bloquea contexto» (`reproducir_gesto`), declara a Entrada una **transición** (Entrada, regla 8: solo se acepta `pausa`, lo demás se descarta sin guardarse; tope de seguridad de 3 s, F8) y la mantiene **hasta el aviso «gesto terminado» del Jugador**. **No se pide `sin control`** (lo pide solo el director de escenas, Entrada regla 6). Una tecla que sigue mantenida al terminar el bloqueo se ignora hasta soltarla (Entrada F8). Si el Jugador rechaza el gesto (otro bloqueante en curso), no se ejecuta el efecto del objeto y se registra.
11. **Respuesta inmediata.** Toda pulsación que se procesa produce una respuesta audible o visible dentro de `latencia_feedback_ms` (slice §16: «feedback en cada acción»): el efecto del dueño, o `SFX_CLICK_SUBTLE` si es `SIN_EFECTO`. No existe una pulsación «muda» salvo que el objeto esté en enfriamiento o en transición.
12. **Pie de texto** (`INSPECCION_TEXTO` y `SIN_EFECTO` con texto). Un texto breve de objeto (`OBJ_<id>`, de la base de contenido) se muestra como pie no bloqueante durante la duración de F5. El jugador sigue en `exploración`: puede moverse, mirar o activar otro objeto, lo que sustituye el pie. Un texto de más de `texto_max_caracteres` (90†) no es un pie: es un documento (`LEER`). El pie lo dibuja el sistema 24; este sistema entrega la clave y la duración. **El pie no se puede releer**, por eso un pie nunca lleva información necesaria para avanzar (es ambiente y relleno; lo clave va en `LEER`, D7-25); un registro de últimos textos queda fuera del slice (Open Questions). Accesibilidad: el ajuste `multiplicador_pie` alarga la duración (F5) y `pie_persistente` lo mantiene hasta que cambie el objetivo o se active otro objeto (ajustes ‡ para el sistema 6).

**Inspección (objeto en la mano)**

13. **Entrar.** `INSPECCION_MANO` pide el contexto `inspección`. 7 **mueve el objeto de la escena** de su sitio a la mano en `t_mano_s` (0,4 s ≤ 0,5 s de `HAND_REACH`) hasta la distancia de F3, con su **pose canónica** (`pose_inspeccion` del catálogo: la cara que mejor lo presenta), y pide al Jugador `reproducir_gesto(HAND_REACH)` seguido de `reproducir_gesto(HAND_HOLD_ITEM)` (bucle, no bloquea). **No se usa `sostener(item_id)`**: `V05` no es un ítem, sino un objeto de escena que posiciona 7 (‡ el Jugador debe admitir `HAND_HOLD_ITEM` sin ítem, ver «Cambios requeridos»). Solo se inspeccionan objetos de radio envolvente ≤ `r_max_inspeccion_m` (0,20 m†; F3). Las tarjetas y la caja del traslado `A03` **no** son inspeccionables (los ítems los sostiene 20 con `sostener`). El mundo sigue vivo (audio, eventos): inspeccionar nunca detiene el tiempo.
14. **Girar.** En `inspección`, `rotar_objeto` (el eje `mirar` de Entrada, regla 11) gira el objeto en torno a su centro con F3: sin límites de ángulo, sin inercia, sin modo «desbloquear». Los detalles de las caras ocultas (la pegatina del peluche `V05`) son geometría o textura reales, de modo que girarlo *revela* información. El objeto nunca atraviesa la cámara: la distancia de F3 es fija y, con `r ≤ r_max_inspeccion_m`, la superficie queda siempre a ≥ 0,19 m de la cámara (F3).
15. **Salir.** `atrás` devuelve el objeto a su sitio en `t_mano_s`, después `reposo()` al Jugador; no hay otra forma de «gastarlo». Un objeto inspeccionado no cambia de estado ni escribe hechos por el mero hecho de mirarlo; si sus dueños quieren registrar que se ha visto, lo piden con el aviso «interacción ejecutada» (regla 29).

**Lectura (documento)**

16. **Entrar.** `LEER` (pulsación prolongada, o corta si el documento se declara con `verbo_corto = leer`) pide el contexto `lectura` y entrega al sistema 20 la clave del documento y su estilo de presentación (`impreso`, `manuscrito_*`, `pantalla`, `libro`; base de contenido 18, regla 1). El documento se muestra a pantalla; quien lo dibuja es el sistema 20. Las manos hacen `HAND_READ` (bucle, no bloquea) y al cerrar vuelven a `reposo()`.
17. **Páginas.** En `lectura`, `interactuar` pasa de página si el documento tiene varias (R01 el libro de visitas, dos páginas; gesto `ANIM_PAGE_TURN`, ≤ 1,0 s del Jugador, que bloquea el contexto como en la regla 10). El slice llama a la acción de `R01` «Pasar página»; aquí es `LEER` mantenido para abrir y `interactuar` para pasar (D7-23). En la última página `interactuar` no hace nada. No hay retroceso de página: cierra con `atrás`.
18. **Lectura completada.** Si el objeto declara `lectura_min_s` (A04 el formulario: **2 s**†, interpretación de «Leer (2 s)» del slice A.4), este sistema mide el tiempo que `lectura` permanece abierta (tiempo de juego, la pausa lo detiene) y, al alcanzarlo, emite una vez por apertura el aviso «lectura completada» con el ID del documento. Quien escribe el hecho (`formulario_leido`) es el sistema 20. Cerrar antes de tiempo no tiene coste: se vuelve a leer.

**Vista cercana (puzles y paneles)**

19. **Abrir.** `abrir_vista` (regla 30; lo llama `ABRIR_VISTA` o un dueño) pide a Entrada el contexto `vista cercana` (transición bloqueante, regla 8 de Entrada) y al Jugador `ceder_camara(propietario = "interaccion:vista", pose = anclaje de la vista, fov_destino = fov_vista_deg, duración = t_vista_entrada_s)`; la curva es la del Jugador (F4). La vista pasa a **Abierta** cuando el Jugador avisa «cámara cedida» (red de seguridad: a los 3 s se libera el bloqueo y se registra). Entonces se muestra el cursor en `cursor_inicial` (por defecto, el centro de la vista), las manos pasan a `apuntar` (`HAND_POINT`, una llamada por fotograma con el punto 3D del cursor sobre el plano de la vista) y se emite «vista cercana abierta» con el ID. **Secuencia de `D01a`–`D01d` (slice B.3):** *encadenada*, no paralela: el dueño (10) anima el compartimento (`BOX_Cn_OPEN`, 1,6 s, transición propia de su gesto) y, **al terminar**, llama a `abrir_vista` (1,0 s de cámara); son dos transiciones consecutivas, cada una bajo el tope de 3 s (peor caso 2,6 s hasta la primera acción, y la pausa detiene ambos relojes, Entrada «Edge Cases»). El anclaje de toda vista es **perpendicular a su plano** (la cámara mira de frente al panel): condición de diseño para que F6 sea exacta. El requisito de ítems de una vista (p. ej. `I-01` para `C05`) lo posee **el marco de puzles (`requires.items`)**, no este catálogo (D7-22): la vista se abre igualmente (mostrar el panel vacío no es un fallo) y el marco dice qué falta.
20. **Cursor, picking y gestos.** Mientras la vista está abierta, la posición del cursor (real o virtual, Entrada regla 12) se convierte a coordenadas del plano de la vista con F6 y se hace **picking 2D** contra las formas que el receptor declara en `elements()` (regla 30): no hay colliders 3D ni rayo de física, de modo que el picking es aritmética pura y comprobable sin motor. Cada gesto de Entrada se entrega al **receptor** (9 para los puzles, 19 para `V01`) como `PointerEvent = {gesto, fase, elemento, elemento_bajo, pos_px, pos_vista, delta_px, delta_grados}`, con esta tabla (H-07):

   | Gesto de Entrada | Fases entregadas | `elemento` | `pos_px` | Delta |
   |---|---|---|---|---|
   | desplazar cursor (sin botón) | `actualización` | nulo; `elemento_bajo` = bajo el cursor | actual | `delta_px` |
   | `seleccionar` (clic; Entrada F6 solo lo conoce al soltar) | `inicio` y `fin` **en el mismo fotograma, al soltar** | el que había bajo el cursor **al pulsar** | `inicio` = al pulsar; `fin` = al soltar | 0 |
   | `agarrar` (tras `d_arrastre` = 8 px, Entrada) | `inicio` → `actualización`… → `fin` o `cancelación` | el que había bajo el cursor **al pulsar** (la pieza no «salta» 8 px) | `inicio` = posición **al pulsar**; después la actual | `delta_px` por fotograma; en `fin`, `elemento_bajo` = destino |
   | `mantener` (≥ `t_hold`) | `inicio` (al alcanzar `t_hold`) → `fin` o `cancelación` | el de al pulsar | actual | 0 |
   | `rotar` | `inicio` → `actualización`… → `fin` o `cancelación` | el que había bajo el cursor al **iniciar** el gesto | actual | `delta_grados`: ratón 1 px = 0,25°; mando = velocidad angular × Δt (Entrada) |

   La acción `leer` de Entrada, activa en `inspección` según su tabla de contextos, **no tiene uso aquí** (D7-28): se pide a Entrada retirarla de ese contexto.
21. **Captura del arrastre.** El `elemento` de un `agarrar`, `mantener` o `rotar` **se fija al pulsar/iniciar** y todos los eventos hasta el final van a ese elemento, aunque el cursor salga de él (`elemento_bajo` informa de lo que hay debajo). Si el contexto cambia (pausa que cierra la vista, `atrás`, pérdida de foco) se entrega `cancelación` y el receptor devuelve el elemento a un estado válido (no se pierde ninguna pieza en el aire).
22. **Tamaño de los elementos.** Todo elemento de vista que el jugador deba señalar mide al menos `pick_min_px` píxeles de lado en el viewport lógico (1920 × 1080 de referencia; F6) (el hit-test se amplía hasta ese mínimo aunque el modelo sea menor) y se separa de otros elementos al menos 2·R (R = radio de atracción asistida de Entrada, 64 px†) entre centros, salvo que su puzle desactive la atracción en esa zona. Es una condición de diseño de los puzles; el marco (9) la comprueba en desarrollo (F6).
23. **Cerrar.** `atrás` (o `cerrar_vista(id, motivo)`, regla 30) cierra la vista en este orden: (1) el receptor recibe `cancelación` de cualquier gesto en curso y `on_close(motivo)`; (2) se pide al Jugador `reposo()` y `devolver_camara("interaccion:vista")`; la cámara vuelve en `t_devolver` (0,5 s, **valor del Jugador**: este sistema no tiene duración propia de regreso) con la curva del Jugador y recupera el FOV de `campo_vision`; (3) **7 mantiene el contexto bloqueante** (Entrada, regla 8) hasta el aviso «cámara devuelta» del Jugador (red de seguridad: 3 s), porque hasta entonces el Jugador descarta `mover` y `mirar`; (4) se emite «vista cercana cerrada» con el motivo (`jugador`, `resuelto` o `sistema`) y Entrada devuelve el contexto anterior. El receptor/marco puede pedir el cierre por sí mismo con motivo `resuelto` (el marco lo hace tras su `close_view_after_s`, F4 de 9; el temporizador es del marco, no de 7). `atrás` durante la transición de entrada o de regreso se ignora (Entrada, regla 8). **Siempre** se puede cerrar: ningún puzle puede impedir `atrás`, salvo los ≤ 3 s de una transición.

**Ordenador**

24. **Abrir el ordenador.** `ABRIR_ORDENADOR` (`V01`) pide a Entrada el contexto `ordenador` y al Jugador `ceder_camara(propietario = "interaccion:ordenador", pose = anclaje de la pantalla, fov_destino, duración)` (igual que la regla 19) y entrega el control al receptor (19). **No hay animación de sentarse ni cambio de posición del cuerpo:** solo se acerca la cámara (el texto de «sentarse» de Entrada debe corregirse). Cerrar con `atrás`, con el mismo orden que la regla 23. El contenido, la búsqueda y la impresora son de 19; `HAND_TYPE` lo pide 19 al Jugador.

**Casos de objetos con estados** (resumen; el comportamiento es del dueño, el catálogo declara solo el verbo y la condición)

25. **Qué verbo ofrece cada objeto del slice** (tabla en Interactions with Other Systems). Las nueve etiquetas del slice —«Abrir», «Girar», «Examinar», «Leer», «Descolgar», «Encender»/«Apagar», «Imprimir», «Usar», «Entrar»— existen como claves de la base de contenido (18) (las que falten se piden allí); este sistema solo las nombra.
26. **Objetos sin interacción.** Los objetos decorativos (mobiliario, `V07`, `R03`, `B04`, `B08` las marcas del suelo) no se declaran: no se pueden enfocar, no ocluyen más que la geometría normal. La puerta de salida de Recepción «no es interactuable» (slice A.7): no está en el catálogo.

**Peticiones externas**

27. **Peticiones externas y pila de modos.** (a) *Cierre forzado:* el director de escenas (21) o la descarga de escena pueden pedir `cerrar_modos()`: se cierran **todos** los modos de la pila (`lectura` primero y luego `vista cercana` o `inspección`), de arriba abajo, con cancelación de gestos y avisos de cierre con motivo `sistema`. `atrás` del jugador cierra **solo el modo superior**. Para `ordenador` y `llamada` no aplica (los cierran 19 y 22). (b) *Lectura programática:* un dueño puede pedir `abrir_lectura(doc_id)` sin que el jugador mantenga `interactuar` (p. ej. el marco de puzles al abrirse la carta del puzle 6). Si hay una `vista cercana` abierta, `lectura` se apila encima: la cámara sigue cedida (propietario `interaccion:vista`), las manos pasan de `HAND_POINT` a `HAND_READ` y, al cerrar la lectura con `atrás`, vuelven a `apuntar` y la vista queda como estaba (combinación Cámara cedida + `lectura`: ‡ el Jugador debe recogerla). Pedirla con otro modo de lectura ya abierto se rechaza y se registra. (c) *Cierre `resuelto` con una lectura encima:* `cerrar_vista(id, resuelto)` se **aplaza** hasta que se cierre la lectura (no se le quita al jugador lo que está leyendo) y se ejecuta en el paso siguiente.
28. **Pausa.** Con el menú abierto, la pulsación en curso (anillo) se cancela sin disparar nada (Entrada, edge case de foco); al reanudar, el objetivo se recalcula en el primer fotograma.
29. **Avisos que emite** (se documentan aquí según la regla 10 del GDD del 3): «vista cercana abierta» (ID de vista), «vista cercana cerrada» (ID de vista, motivo), «lectura completada» (ID de documento), «lectura cerrada» (ID de documento, motivo: `jugador` o `sistema`) e «interacción ejecutada» (ID de objeto, verbo, resultado), este último solo para quien quiera reaccionar (audio 23, atmósfera 28, director de escenas 21). El cambio del objetivo (para el prompt) **no** viaja por el bus: 24 consulta `get_target()` cada fotograma (una señal por fotograma saturaría el bus y su valor es transitorio); tampoco hay aviso de «pérdida de foco».

**API pública** (lo que 8, 9, 10, 19, 20, 21, 22, 24 y 28 pueden llamar; nombres definitivos del contrato)

30. **Operaciones.**
   - `registrar_manejador(id, manejador)`: durante la configuración de la escena (antes de «escena lista», dentro de la retención de arranque del 4, regla 9, paso 6). Un ID repetido o ausente del catálogo es error visible en desarrollo (Edge Cases). Contrato del manejador: regla 3.
   - `registrar_receptor(vista_id, receptor)`: asocia el receptor de una vista (9 para las vistas de puzle, 19 para `V01`). **Contrato `ViewReceiver`:** `elements() -> Array[ViewElement]` con `{id, forma (rectángulo, círculo o polígono en coordenadas locales de la vista, en metros), z_orden, atraccion (bool)}`, consultada al abrir la vista y cada vez que el receptor emite `elements_changed`; `handle_pointer(ev: PointerEvent)`; `on_open()`; `on_close(motivo)`. Con las formas, 7 hace el picking (regla 20), amplía el hit-test hasta `pick_min_px` y entrega a Entrada las **posiciones en píxeles** de los elementos con `atraccion` para su atracción asistida (Entrada F5b).
   - `abrir_vista(vista_id) -> {ACEPTADA, RECHAZADA(motivo)}`: la llama `ABRIR_VISTA` o un dueño (10, tras animar el compartimento). Rechaza si hay otro modo abierto, si la vista o su receptor no existen o si la llamada no ocurre en `exploración` o en la transición del propio dueño. Secuencia: regla 19.
   - `cerrar_vista(vista_id, motivo)`: `motivo` ∈ `jugador` | `resuelto` | `sistema`. La llaman el marco (`resuelto`, tras `close_view_after_s`), 21 y la descarga (`sistema`) y `atrás` (`jugador`). Idempotente: si la vista no está abierta, no hace nada y se registra. Secuencia: regla 23; con una lectura encima, regla 27c.
   - `abrir_lectura(doc_id)` / `cerrar_lectura(motivo)`: lectura programática (regla 27b); el cierre emite «lectura cerrada».
   - `cerrar_modos()`: regla 27a. `get_target() -> {id, etiqueta, ¿largo?, p} | nulo` (para 24; `p` = F2). `modo_actual() -> {NINGUNO, INSPECCION, LECTURA, VISTA, ORDENADOR}` y la pila.
31. **Esquema del catálogo y cobertura.** Ejemplo (una entrada por efecto relevante; el campo `modo` solo existe en los efectos que abren un modo):
```json
[
  { "id": "V02", "verbo_corto": "UI_VERBO_DESCOLGAR", "verbo_largo": null,
    "etiqueta_corto": "UI_VERBO_DESCOLGAR", "efecto": "DELEGAR",
    "habilitado_si": { "todos": [], "ninguno": [] }, "prioridad": 0,
    "gesto_hecho": "ANIM_PHONE_PICKUP", "texto": null },
  { "id": "A04", "verbo_corto": null, "verbo_largo": "UI_VERBO_LEER",
    "etiqueta_largo": "UI_VERBO_LEER", "efecto": "LEER", "prioridad": 0,
    "modo": { "doc_id": "DOC_A04", "estilo": "impreso", "lectura_min_s": 2.0 } },
  { "id": "D01a", "verbo_corto": "UI_VERBO_ABRIR", "etiqueta_corto": "UI_VERBO_ABRIR",
    "efecto": "DELEGAR", "gesto_hecho": "HAND_REACH",
    "modo": { "vista_id": "D01a", "anclaje": "ANC_D01A", "fov_vista_deg": 70,
              "t_vista_entrada_s": 1.0, "cursor_inicial": "centro" } }
]
```
   Las claves `UI_VERBO_*`, `DOC_*` y `ANC_*` son ilustrativas. **Cobertura (AC-37):** el catálogo debe contener todos los IDs del Anexo A del slice cuya columna «Interacción» no sea «Ninguna», «Visibles siempre», «Ver…» o «Emite…», con esta correspondencia: `A02` (estanterías) → **tres entradas** `A02a`, `A02b`, `A02c` (`INSPECCION_TEXTO`, `OBJ_A02a`…`OBJ_A02c`: los tres textos de relleno del slice A.4); `D01` → solo sus compartimentos `D01a`–`D01d`. **Excluidos del catálogo** (decorativos o sin acción del jugador): `V07`, `R03`, `B04` (el ventanal del puzle 2 no se toca: los fragmentos F1 a F3 los muestra el marco como consecuencia de las lámparas `B01`–`B03`), `B08`, `C01`–`C04`, `D01` y la puerta de salida de Recepción. El conjunto esperado se deriva del Anexo A en las pruebas, no se enumera a mano.
32. **Reloj.** Los temporizadores de este sistema (`t_anillo_inicio_s`, `t_enfriamiento_s`, `lectura_min_s`, gracia del foco) son de **tiempo de juego**: la pausa los detiene. El tope de 3 s de las transiciones es de Entrada y también se detiene con el menú abierto (Entrada «Edge Cases», `sin control`); 7 no lo duplica.

### States and Transitions

Dentro del contexto `exploración`, el sistema tiene estos estados (el resto de contextos los posee Entrada):

| Estado | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin objetivo** | El barrido no encuentra candidato. No hay icono. | Con objetivo |
| **Con objetivo** | Hay un objeto enfocado; 24 muestra icono y etiqueta. | Sin objetivo · Pulsando |
| **Pulsando** | `interactuar` mantenida sobre un objeto con `verbo_largo`; el anillo avanza. | Con objetivo (suelta antes de `t_hold`: se dispara el verbo corto, si lo hay) · Ejecutando (alcanza `t_hold`) · Sin objetivo (cancelación) |
| **Ejecutando** | Se llama al manejador o se abre un modo. Enfriamiento y bloqueo por gesto (regla 10). | Con objetivo · Modo abierto |
| **Modo abierto** | `inspección`, `lectura`, `vista cercana` u `ordenador` en la pila de Entrada. El barrido de foco está suspendido. | Con objetivo (al salir, por `atrás` o cierre forzado, **y tras el aviso «cámara devuelta»** si había cámara cedida) |

El estado interno de cada modo:

| Modo | Subestados | Notas |
|---|---|---|
| `inspección` | Entrando (`t_mano_s`) → Girando → Saliendo (`t_mano_s`) | Entrando y Saliendo descartan acciones salvo `pausa` (Entrada, regla 8) |
| `lectura` | Abierta (con contador de `lectura_min_s`) | Puede apilarse sobre una vista (regla 27b). `atrás` cierra solo la superior |
| `vista cercana` | Entrando (hasta «cámara cedida», `t_vista_entrada_s`) → Abierta → Saliendo (hasta «cámara devuelta», `t_devolver` del Jugador) | Los gestos solo se entregan en Abierta; en Entrando y Saliendo el contexto está bloqueado |
| `ordenador` | Entrando → Abierto → Saliendo | Igual que la vista cercana, con propietario de cámara `interaccion:ordenador` |

### Interactions with Other Systems

**Objetos del slice y su efecto** (verbos propuestos †; los textos de etiqueta son de la base de contenido 18)

`Prior.` = `prioridad` (0 si no se indica). «Disponibilidad» dice cómo se aplica la regla 8: `hecho` = `habilitado_si` sobre hechos; `NO` = el manejador oculta el objeto; `SIN_EFECTO` = visible, el dueño contesta con texto. «Gesto» es el `gesto_hecho` (nombres del Jugador). 35 entradas.

| Objeto | Corto | Largo | Efecto | Prior. | Disponibilidad | Gesto | Dueño del resultado |
|---|---|---|---|---|---|---|---|
| `V01` ordenador | Abrir | — | `ABRIR_ORDENADOR` | 0 | siempre | `HAND_TYPE` lo pide 19 | 19 |
| `V02` teléfono | Descolgar | — | `DELEGAR` | 0 | `NO` salvo estado `vibrando` | `ANIM_PHONE_PICKUP` (0,8 s, Jugador) | 22 |
| `V03`, `A05`, `D05` cajones | Abrir | — | `DELEGAR` | 0 | `NO` si ya está abierto | `HAND_DRAWER` | 8 (A05) · 20 (contenidos) |
| `V04` caja de cartón | Examinar | — | `INSPECCION_TEXTO` | 0 | siempre | — | 7 |
| `V05` peluche | Examinar | — | `INSPECCION_MANO` | 0 | siempre | `HAND_REACH` → `HAND_HOLD_ITEM` | 7 |
| `V06` lámpara de escritorio | Encender/Apagar (etiqueta dinámica) | — | `DELEGAR` | 0 | siempre | `HAND_REACH` | 28 |
| `V08` impresora | Imprimir | — | `DELEGAR` | 0 | `NO` mientras `imprimiendo`; `SIN_EFECTO` con `sin_resultados` | `HAND_REACH` | 19 |
| `A02a`, `A02b`, `A02c` cajas de la estantería; `A06`, `B06`, `B07`, `D02`, `D03`, `D04`, `R02` | Examinar | — | `INSPECCION_TEXTO` | 0 | siempre | — | 7 |
| `A03` caja del traslado | Abrir (tapa) | — | `DELEGAR` | 0 | `NO` si ya está abierta | `HAND_REACH` | 20 |
| `A04` formulario | — | Leer (`lectura_min_s` 2) | `LEER` | 0 | `NO` mientras `A03` esté cerrada | — | 20 |
| `B01`, `B02`, `B03` lámparas | Girar | — | `DELEGAR` (modo `WORLD` del puzle 2; 9 implementa el manejador) | 1 | siempre; `SIN_EFECTO` lo decide 9 si el puzle está resuelto | `HAND_TURN` | 9 |
| `B05` nota | — | Leer | `LEER` | 2 | siempre (slice A.5) | — | 20 |
| `C05` panel de cronología | Examinar | — | `ABRIR_VISTA` | 0 | siempre | `HAND_POINT` dentro de la vista | 9 |
| `C06`, `C07`, `D06` lectores | Usar | — | `DELEGAR` | 0 | siempre; `SIN_EFECTO` sin tarjeta (con texto) | `HAND_CARD_SWIPE` (con `HECHO`) | 8 |
| `C08` ascensor | Entrar | — | `DELEGAR` | 0 | hecho: `todos: [llamada_completada]` | `HAND_REACH` | 8 · 21 |
| `D01a` a `D01d` compartimentos | Abrir | — | `DELEGAR` → 10 anima y llama a `abrir_vista` | 0 | siempre; `SIN_EFECTO` en `D01b`–`D01d` hasta que el anterior esté resuelto (10 consulta al marco antes de abrir) | `HAND_REACH` | 10 + 9 |
| `R01` libro de visitas | — | Leer | `LEER` (dos páginas) | 0 | siempre | `ANIM_PAGE_TURN` al pasar página | 20 |

**Dónde está el collider de `B05`.** Para que la nota (`prioridad` 2) no robe `B02` (`prioridad` 1): el collider de `B05` es solo la parte de la nota **que asoma fuera de la base** de la lámpara C, con ≥ 0,02 m de margen en planta respecto del collider de la base de `B02`, y el collider de `B02` cubre **toda** la base útil. Con el desempate de F1 (el que contiene el eje gana antes que `prioridad`), apuntar a la base da «Girar» y apuntar a la nota da «Leer». Es una condición para el diseño de nivel (4) y se comprueba en AC-04c.

| Sistema | Qué recibe de Interacción e inspección | Qué entrega a Interacción e inspección |
|---|---|---|
| 1 Entrada y controles | Peticiones de entrar y salir de `inspección`, `lectura`, `vista cercana`, `ordenador`; transiciones bloqueantes (regla 8) mientras dura un gesto o un movimiento de cámara; posiciones en px de los elementos con atracción (F5b). **No pide `sin control`** | `interactuar`, `rotar_objeto`, `atrás`, gestos de puntero, dispositivo activo |
| 2 Jugador en primera persona | `ceder_camara(propietario, pose, fov_destino, duración)` y `devolver_camara(propietario)` (propietarios `interaccion:vista` e `interaccion:ordenador`), `reproducir_gesto(id)`, `apuntar(punto_3d)`, `reposo()`. **No se piden `sostener` ni ocultar manos** | Rayo de visión (ojos sin balanceo, dirección de cámara); avisos «gesto terminado» y ‡ «cámara cedida» / «cámara devuelta»; ‡ `fov_vigente()` |
| 3 Estado y bus | Los avisos de la regla 29 | Lectura de hechos para `habilitado_si` (lectura directa por paso de física, regla 8) |
| 4 Escena de planta | — | Aviso «escena lista» y la retención de arranque (regla 9, paso 6) durante la que 7 carga el catálogo y registra manejadores y receptores; contenedores e IDs de los objetos; anclajes de las vistas |
| 18 Base de contenido | Claves de etiqueta, texto de objeto y documento | Los textos (solo lectura) |
| 24 Prompt de interacción | `get_target()`: ID, etiqueta corta y larga, progreso del anillo | — |
| 20 Documentos y bolsillo | Documento a mostrar, estilo, aviso «lectura completada» | Dibujo de la pantalla de lectura |
| 9 Marco de puzles | `PointerEvent` de la vista, «vista cercana abierta/cerrada», activaciones del modo `WORLD` (`handle_activation`) | `registrar_receptor` (con `elements()`), `cerrar_vista(id, resuelto)` tras su `close_view_after_s`, manejador de `B01`–`B03` |
| 19 Ordenador | Control del cursor y `seleccionar` en `ordenador` | `registrar_receptor` de `V01`; manejador de `V01` y `V08` |
| 10 Caja y compartimentos | Activaciones (`interact`) de `D01a`–`D01d` | Manejadores; llamada a `abrir_vista` tras animar el compartimento |
| 8, 22, 28 | Activaciones (`interact`) | Manejadores por ID (`etiqueta()` opcional) |
| 21 Director de escenas | Aviso «interacción ejecutada» | `cerrar_modos()` |

## Formulas

### F1 · Elección del objetivo de interacción

Se ejecuta en cada paso de física con el rayo de visión del Jugador (origen en los ojos sin balanceo). Pasos:

1. **Contactos.** `C = { c : el collider de un interactuable (máscara «interactuable») queda a distancia ≤ radio_apuntado_m del eje del rayo, con profundidad d_c ≤ alcance_c }`, donde `d_c` es la distancia **a lo largo del eje** hasta el punto de contacto y `alcance_c = alcance_m` propio o `alcance_interaccion_m`. Se descartan los que no pasan `habilitado_si` o cuyo `can_interact` es `NO` (regla 3).
2. **Oclusión con tolerancia.** `c` queda **ocluido** si el segmento ojos → punto de contacto de `c` corta geometría del mundo (máscara «geometría», sin la capa «interactuable» ni la del Jugador) a una profundidad `d_g < d_c − desempate_prof_m`. Una superficie que sostiene al objeto (mesa bajo la nota `B05`, caja bajo el formulario `A04`) queda a `d_g ≈ d_c` y por tanto **no ocluye**.
3. **Grupo.** `d_min = mín d_c` de los no ocluidos; `G = { c : d_c ≤ d_min + desempate_prof_m }`. Los de fuera de `G` no compiten.
4. **Desempate en `G`**, por orden: (i) los que **contienen el eje exacto** (rayo de radio 0) frente a los que solo toca la esfera; (ii) mayor `prioridad`; (iii) menor distancia al eje; (iv) menor ID (determinista). El primero de esa ordenación es el candidato.
5. **Retención** (regla 7): si no hay candidato y se cumple (t desde la pérdida ≤ `t_gracia_foco_s`) **Y** (distancia rayo–collider ≤ `radio_pegajoso_m`), el objetivo es el retenido; si hay candidato, sustituye siempre.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| prioridad | int | 0–9 | catálogo, 0 por defecto (`B01`–`B03` 1; `B05` 2) | Desempata objetos apilados en el mismo sitio |
| d_c, d_g, d_min | float (m) | ≥ 0 | calculated | Profundidad del contacto del candidato, de la geometría que lo oculta y del contacto más cercano |
| alcance_interaccion_m | float (m) | 1,2–3,0 | data, 1,8† | Distancia máxima desde los ojos |
| radio_apuntado_m | float (m) | 0–0,15 | data, 0,06† | Radio de la esfera del barrido (ayuda a objetos pequeños, p. ej. `V02`, 15 × 8 cm) |
| desempate_prof_m | float (m) | 0,01–0,08 | data, 0,03† | Diferencia de profundidad que se considera «mismo sitio» |
| radio_pegajoso_m | float (m) | 0–0,30 | data, 0,15† | Distancia a la que se retiene el objetivo actual |
| t_gracia_foco_s | float (s) | 0–0,3 | data, 0,12† | Tiempo de retención |

**Output Range:** un ID de objeto o nulo.
**Example:** (1) Vera a 1,40 m del teléfono `V02`, apuntando a su borde; el barrido de 6 cm toca su colisionador a 1,38 m (≤ 1,8), sin geometría delante: objetivo. (2) `B02` a 1,10 m y `B05` a 1,12 m, ambos con el eje dentro: `d_min` = 1,10, límite del grupo 1,13 (Δ = 0,02 ≤ 0,03), ambos en `G`, ambos contienen el eje → `prioridad` 2 > 1: gana `B05`. Con `B05` a 1,20 m (Δ = 0,10 > 0,03) queda fuera de `G`: gana `B02`. (3) El eje cae dentro de la base de `B02` y la esfera solo roza `B05`: `B02` contiene el eje y `B05` no → gana `B02` aunque `B05` tenga más `prioridad`. (4) La nota `B05` sobre una mesa: el segmento al punto de contacto de la nota a 1,50 m corta la mesa a 1,499 m (`d_g` = 1,499 ≥ 1,50 − 0,03 = 1,47): no está ocluida. Una pared a 1,0 m delante (`d_g` = 1,0 < 1,47): sí.
**Implementación (pendiente de ADR):** la forma de obtener «todos los contactos de la esfera» (consulta de forma o `ShapeCast3D` con Jolt) no está cubierta por `docs/engine-reference/godot/` (solo `intersect_ray`); respaldo documentado: un haz de 7 rayos (1 central + 6 en un anillo de radio `radio_apuntado_m`) con `intersect_ray`. La equivalencia de ambos para los casos de los AC (que usan un mundo de física falso) se verifica en el ADR.

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
| r | float (m) | 0 < r ≤ `r_max_inspeccion_m` (0,20†) | calculated | Radio de la esfera que envuelve el objeto; un `INSPECCION_MANO` con r mayor es error de datos |
| θ_fill | float (°) | 15–40 | data, 25† | Ángulo de visión que debe ocupar el objeto |
| d_ins_min / d_ins_max | float (m) | 0,20–0,40 / 0,40–0,80 | data, 0,25† / 0,60† | Distancia mínima y máxima a la cámara |
| yaw_Δ, pitch_Δ | float (°) | — | Entrada F2/F3 | Cambio de orientación del fotograma (con la inversión vertical del jugador) |
| k_inspeccion | float | 0,3–2,0 | data, 1,0† | Escala del giro del objeto respecto a la mirada |
| q | cuaternión | — | calculated | Orientación del objeto; inicial = `pose_inspeccion` |

**Output Range:** `d_ins` en metros; `q` sin límite (giro libre, normalizado).
**Garantía de no atravesar la cámara:** con r ≤ 0,20 m, la superficie más cercana queda a `d_ins − r` ≥ 0,19 m de la cámara. Peor caso: para r < 0,0554 m, `d_ins` = 0,25 y `d_ins − r` > 0,19; para 0,0554 ≤ r ≤ 0,20, `d_ins` = r/0,2217 (o 0,60 si lo supera) y `d_ins − r` = 3,51·r ≥ 0,19. (El plano cercano de la cámara lo fija el Jugador y debe ser < 0,19 m: ver Cambios requeridos.)
**Example:** peluche `V05` (cubo de 0,12 m): r = 0,12·√3/2 = 0,1039 m; tan(12,5°) = 0,2217 → d = 0,469 m (dentro de 0,25–0,60); `d − r` = 0,365 m. Un objeto de r = 0,20 m: 0,20/0,2217 = 0,902 → se limita a 0,60 m (ocupa 2·atan(0,20/0,60) = 36,9°). Con yaw_Δ = 1,8° y k = 1 el objeto gira 1,8°. θ_fill = 25° de un FOV vertical de 70° es el 36 % de la altura de pantalla (25/70).

### F4 · Duraciones de la transición de cámara (vista cercana y ordenador)

**La curva es del Jugador** (smoothstep `s(x) = 3x² − 2x³` en `ceder_camara`/`devolver_camara`, Jugador regla 18 y F-cámara); este sistema **no la implementa ni la duplica** y solo aporta las duraciones:

`T_entrada = min(t_vista_entrada_s, t_transicion_max) ;   T_salida = t_devolver (0,5 s, del Jugador) ;   bloqueo ≤ 3 s por transición (Entrada F8)`

**Variables:** `t_vista_entrada_s` por vista (0,6–1,5 s; 1,0 para `D01a`), pasado como `duración` de `ceder_camara`; `t_transicion_max` = 3 s (Jugador/Entrada); `t_devolver` es del Jugador (0,2–1,5 s, 0,5 por defecto). **No existe `t_vista_salida_s`.**
**Output Range:** duraciones en segundos; la posición y rotación intermedias las calcula el Jugador.
**Example:** `D01a`: entrada 1,0 s y regreso 0,5 s. Referencia del comportamiento esperado del Jugador (T = 1,0 s): s(0,25) = 0,15625; s(0,5) = 0,5; s(0,75) = 0,84375. Con la secuencia encadenada de `D01a` (regla 19): 1,6 s de `BOX_C1_OPEN` + 1,0 s de cámara = 2,6 s hasta la primera acción, cada tramo bajo el tope de 3 s.

### F5 · Duración del pie de texto

`t_pie = clamp(0,5 + n / cps_pie, pie_min_s, pie_max_s) · multiplicador_pie`   (con `pie_persistente` activo, el pie dura hasta que cambie el objetivo o se active otro objeto)

**Variables:** `n` caracteres del texto (≤ 90 en español; otros idiomas, regla de datos en Tuning Knobs); `cps_pie` 14† (10–20), caracteres por segundo; `pie_min_s` 2,0† (1,5–3,0); `pie_max_s` 8,0† (4–12); `multiplicador_pie` 1,0 (1,0–3,0, ajuste de accesibilidad ‡).
**Output Range:** 2,0 a 8,0 s (hasta 24 s con el multiplicador máximo).
**Example:** «Café frío. Lo dejó a las siete» (30 caracteres): 0,5 + 30/14 = 2,64 s. Un texto de 90 caracteres: 0,5 + 6,43 = 6,93 s. Con `multiplicador_pie` 2,0 el primero dura 5,29 s.

### F6 · Píxeles por metro de una vista cercana

`ppm = (H_px / 2) / (d · tan(FOV_v / 2));   tolerancia_px = tolerancia_m · ppm`

**Variables:** `H_px` altura del **viewport lógico** donde viven el cursor, los elementos y `pick_min_px` (1080 con la base 1920 × 1080 en 16:9; con otra relación de aspecto cambia según el estiramiento del proyecto, ver Open Questions V4, p. ej. 1200 en 16:10 con `expand`); `d` distancia de la cámara al plano de la vista (m); `FOV_v` campo de visión **vertical** efectivo de la vista (`fov_vista_deg`, 70° de referencia, slice A.0, limitado por el Jugador según su F5; se lee con `fov_vigente()` ‡, no se asume); `tolerancia_m` tolerancia de un puzle en el espacio de la vista. Válida porque el anclaje es perpendicular al plano (regla 19).
**Output Range:** píxeles por metro, positivo.
**Example:** `D01a`, d = 0,35 m, FOV_v = 70°, H = 1080: ppm = 540 / (0,35 · 0,7002) = 2.203 px/m; 0,04 m = 88 px y 0,10 m = 220 px. Con H = 1200 (16:10 lógico): 600 / 0,24507 = 2.448 px/m. Si los 70° fueran el FOV horizontal (16:9), ppm = 3.917 px/m (por eso el eje es una verificación pendiente). **Esto sustituye el supuesto de 1.200 px/m de Entrada (Open Question 2)**: cada puzle entrega su tolerancia en metros y el sistema la convierte a píxeles con la vista real.

## Edge Cases

**Detección**
- **If dos interactuables se solapan en pantalla (nota bajo lámpara)**: regla 5 y F1; gana `prioridad`, nunca «el que se carga primero».
- **If el objeto enfocado queda detrás de una puerta que se abre o de otro objeto que se mueve**: el barrido es continuo; el objetivo se pierde en el fotograma siguiente a quedar ocluido (sin gracia por oclusión, solo por temblor, regla 7).
- **If el jugador mira un objeto desde más de `alcance_interaccion_m`**: no hay objetivo; ningún icono. El slice no tiene «marcadores a distancia».
- **If un objeto deshabilitado se enfoca**: no hay icono ni reacción (regla 8). `SFX_CLICK_SUBTLE` no suena porque no se ha interpretado la pulsación como interacción.
- **If el barrido empieza dentro de un colisionador** (cámara pegada a una pared): se ignora ese contacto; la cámara la gobierna el sistema 2.
- **If se retira un objeto de la escena o su dueño responde `NO` mientras es el objetivo** (p. ej. un ítem que su dueño pasa al bolsillo): el objetivo pasa a nulo en ese paso de física; la pulsación en curso se cancela.
- **If un objeto plano (nota, formulario, libro) está sobre una mesa o dentro de una caja**: la superficie que lo sostiene no lo ocluye (F1, paso 2); sí lo ocluye una pared o un objeto a más de `desempate_prof_m` por delante.
- **If el eje cae dentro de la base de `B02` y la esfera solo roza `B05`**: gana `B02` (F1, paso 4 i). El collider de `B05` no cubre la base (tabla de objetos).
- **If dos candidatos empatan en todo el desempate**: gana el ID menor (determinista); no depende del orden de carga.

**Pulsación**
- **If se mantiene `interactuar` sobre un objeto sin `verbo_largo`**: se dispara al pulsar y la tecla mantenida no repite (enfriamiento y regla 10 de Entrada).
- **If se suelta `interactuar` antes de `t_hold` sobre un objeto solo `leer`**: no abre; el anillo pulsa una vez y suena `SFX_CLICK_SUBTLE` (regla 9).
- **If el objetivo cambia durante la pulsación prolongada**: si la retención (regla 7) deja de cumplirse o aparece un candidato distinto, la pulsación se cancela sin disparar nada.
- **If el Jugador rechaza el gesto pedido** (otro gesto bloqueante en curso): no se ejecuta el efecto, no se bloquea el contexto y se registra; no se encola.
- **If el manejador de un objeto no está registrado**: el objeto no es objetivo y se registra una línea (build final) o error visible (desarrollo).
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
- **If el jugador pulsa `atrás` antes de que acabe la transición de entrada o durante el regreso de la cámara**: se ignora (Entrada, regla 8); a los 3 s como máximo se libera. Una tecla mantenida al terminar se ignora hasta soltarla (Entrada F8).
- **If una vista se abre y falta el ítem que su puzle requiere** (`requires.items` del marco): se abre igualmente; el marco (9) decide qué mostrar (Edge Cases de 9). No hay mensaje de este sistema.
- **If `abrir_vista` se llama con otro modo abierto, sin receptor o desde un contexto que no es `exploración`**: devuelve `RECHAZADA(motivo)`, no se mueve nada y se registra.
- **If el cursor virtual sale de la zona de la vista**: Entrada lo detiene en el borde (Entrada, edge case de gestos).
- **If se suelta `agarrar` fuera de todo elemento**: se entrega `fin` con `elemento` = la pieza agarrada (captura, regla 21) y `elemento_bajo` nulo; el receptor decide a dónde vuelve la pieza.
- **If hay una `lectura` apilada sobre una vista y llega `cerrar_modos()`**: se cierran las dos, `lectura` primero (regla 27a). Con `atrás`, solo la lectura. Con `cerrar_vista(resuelto)`, se aplaza hasta cerrar la lectura (regla 27c).
- **If el Jugador no avisa «cámara cedida» o «cámara devuelta»**: a los 3 s se libera el bloqueo, se registra el fallo y la vista queda Abierta (entrada) o se devuelve el contexto (regreso).
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
| 2 Jugador en primera persona | Dura (**contrato; el GDD del 2 es la fuente de verdad**, decisión 2026-11-09) | Rayo de visión (ojos sin balanceo); `ceder_camara(propietario, pose, fov_destino, duración)` / `devolver_camara(propietario)` (regreso fijo `t_devolver` 0,5 s); `reproducir_gesto(id)` con los nombres `HAND_*` del Jugador y sus duraciones; `apuntar`, `reposo`. No se pide ocultar manos ni `sin control`. Solicitudes ‡ pendientes al Jugador: avisos «cámara cedida» / «cámara devuelta», `fov_vigente()`, `HAND_HOLD_ITEM` sin ítem, plano cercano < 0,19 m, estado Cámara cedida + `lectura` |
| 4 Escena de planta | Dura | «Escena lista» y la retención de arranque (regla 9, paso 6): 7 carga el catálogo y registra manejadores y receptores antes de que suba el telón; los objetos se localizan por ID en los contenedores (regla 4); anclajes de las vistas |
| 18 Base de contenido narrativo | Dura | Claves de etiquetas («Abrir», «Girar», «Examinar», «Leer», «Descolgar», «Encender»/«Apagar», «Imprimir», «Usar», «Entrar»), `OBJ_<id>` (incluidos `OBJ_A02a` a `OBJ_A02c`) y documentos |
| 3 Estado y bus de eventos | Blanda | Lee hechos para `habilitado_si` (lectura directa por paso de física); emite los avisos de la regla 29. El GDD del 3 **aún no lista** a 7 como emisor: cambio requerido |

El **índice** (fila 7) ya lista «1, 2, 18 (blanda: 3)»; solo la lista por capas (Feature Layer, punto 1) conserva «1, 2, 18» y falta el 4 en ambas.

**Aguas abajo (quién depende de este sistema)**

| Sistema | Tipo | Interfaz |
|---|---|---|
| 8 Control de acceso | Dura | Manejadores de lectores y ascensor (ninguna puerta es interactuable) |
| 9 Marco de puzles | Dura | `registrar_receptor` / `elements()`, `PointerEvent`, `abrir_vista`/`cerrar_vista` (`close_view_after_s`), activaciones del modo `WORLD` |
| 10 Caja y compartimentos | Dura | Manejadores `D01a`–`D01d`; `abrir_vista` tras animar el compartimento |
| 11–16 Puzles | Indirecta (vía 9) | Gestos de puntero |
| 19 Ordenador, correo e impresora | Dura | `ABRIR_ORDENADOR`, cursor, `V08` |
| 20 Documentos y bolsillo | Dura | `LEER`, «lectura completada» |
| 22 Llamada telefónica | Dura | `V02` |
| 24 Prompt de interacción y feedback | Dura | `get_target()` |
| 21 Director de escenas | Blanda | `cerrar_modos()`, «interacción ejecutada» |
| 28 Atmósfera reactiva · 23 Audio | Blanda | «interacción ejecutada» |

**Bidireccionalidad.** Entrada (reglas 6, 10 y 11; tabla de Dependencies), el Jugador (2), el 18 («7 Interacción · 8 Control de acceso · 24 Prompt · 25 Pausa») y el Marco (9) ya listan a este sistema. **Faltan** el 3 (como receptor de los avisos de la regla 29; el GDD del 3 no dice nada de 7, así que la afirmación anterior de que «lo trata como indirecto» se retira) y el 4. Ningún otro sistema tiene GDD aún: cada uno debe, al redactarse, listar a Interacción e inspección y usar los nombres de la API (reglas 3 y 30). Cambios en otros GDDs: sección final de la revisión.

## Tuning Knobs

Categorías: **F** = feel (se afina jugando), **C** = curva, **G** = gate (ritmo). Todos viven en `assets/data/interaction/` (nunca en código).

| Knob | Cat. | Defecto | Rango seguro | Qué afecta y por qué ese valor |
|---|---|---|---|---|
| `alcance_interaccion_m` | F | 1,8† | 1,2–3,0 | Distancia de mano. Los despachos miden 5–6 m; con 1,8 m se alcanza el escritorio desde el centro del despacho sin pegarse (la silla es decorativa en el slice). Muy alto: iconos por toda la sala (ruido); muy bajo: obliga a pegarse |
| `radio_apuntado_m` | F | 0,06† | 0–0,15 | Tolerancia de puntería. Cubre el teléfono (15 × 8 cm). Muy alto: se enfoca lo que no se mira |
| `radio_pegajoso_m` / `t_gracia_foco_s` | F | 0,15† / 0,12 s† | 0–0,3 / 0–0,3 | Estabilidad del icono ante temblor; accesibilidad motriz |
| `desempate_prof_m` | F | 0,03† | 0,01–0,08 | Resolución entre objetos apilados y tolerancia de oclusión por la superficie que sostiene a un objeto plano |
| `mascara_interactuable` / `mascara_geometria` | G | capas del proyecto | — | Qué capas de colisión consulta el barrido (F1). Datos de proyecto; el cuerpo del Jugador queda fuera |
| `cursor_inicial` (por vista) | F | `centro` | `centro` · punto de la vista | Dónde aparece el cursor al abrir la vista (regla 19) |
| `fov_vista_deg` (por vista) | F | 70† | 40–90 | FOV vertical de la vista, pasado a `ceder_camara`; entra en F6 |
| `r_max_inspeccion_m` | G | 0,20† | 0,05–0,25 | Radio máximo de un objeto en la mano; garantiza que no atraviesa la cámara (F3) |
| `multiplicador_pie` / `pie_persistente` | F | 1,0 / falso | 1,0–3,0 / bool | Accesibilidad: el pie no se puede releer (ajustes ‡ para el 6) |
| `t_anillo_inicio_s` | F | 0,12† | 0,05–0,25 | Que un toque no haga parpadear el anillo |
| `t_enfriamiento_s` | F | 0,25† | 0,1–0,6 | Evita dobles disparos; muy alto parece lento |
| `latencia_feedback_ms` | F | 100† | 50–200 | Tope de respuesta percibida (criterio, no mecanismo) |
| `t_mano_s` | F | 0,4† | 0,2–0,8 | Coger y devolver en la inspección |
| `theta_fill_deg` / `d_ins_min` / `d_ins_max` | F | 25° / 0,25 / 0,60† | 15–40 / 0,2–0,4 / 0,4–0,8 | Tamaño del objeto en la mano |
| `k_inspeccion` | F | 1,0† | 0,3–2,0 | Sensibilidad del giro; el ajuste de sensibilidad del jugador (Entrada) multiplica |
| `t_vista_entrada_s` (por vista) | F | 1,0 (`D01a`)† | 0,6–1,5 | Peso del gesto de acercarse; la entrada no puede superar 3 s. **El regreso no tiene knob aquí:** es `t_devolver` del Jugador (0,5 s; salir sigue siendo más rápido que entrar) |
| `pick_min_px` | F | 44† | 32–64 | Tamaño mínimo de objetivo en 1080p; accesibilidad motriz |
| `cps_pie` / `pie_min_s` / `pie_max_s` | F | 14 / 2,0 / 8,0† | 10–20 / 1,5–3 / 4–12 | Lectura cómoda de pies; con el subtítulo largo no es pie |
| `texto_max_caracteres` | C | 90† (español) | 60–140 | Frontera entre pie y documento. Se valida en español; en otros idiomas, advertencia si el texto supera 1,3× el límite (†) y la frontera real la decide la UI de 24 |
| `lectura_min_s` (por documento) | G | 2,0 para `A04`† | 0–5 | Cuánto hay que mirar el formulario para contarlo como leído |
| `t_hold` (= `long_press_threshold` del registro) | F | **de Entrada** (0,5) | 0,3–1,0 (1,5 acc.) | No se duplica aquí |
| Duración de los gestos de manos y `t_devolver` | — | **del Jugador** | — | No se duplican aquí (regla 10, F4) |

## Visual/Audio Requirements

*(Sección opcional para la categoría Gameplay; en modo `lean` no se consulta a `art-director` ni a `audio-director`: revisar antes de producción.)*

- **Icono y anillo:** los define el art bible (§3.3 y §7.3); este sistema solo da el objetivo, la etiqueta y `p` de F2. El anillo no es barra; el cursor de las vistas no es un círculo (Entrada, Visual/Audio).
- **Manos:** este sistema **no define animaciones**; pide los gestos del catálogo del Jugador (Visual/Audio del GDD del 2) por su nombre: `HAND_REACH`, `HAND_DRAWER`, `HAND_TURN`, `HAND_CARD_SWIPE`, `HAND_HOLD_ITEM`, `HAND_READ`, `HAND_POINT`, `ANIM_PAGE_TURN`, `ANIM_PHONE_PICKUP`. Las manos están siempre visibles (no se ocultan) y vuelven a `reposo()` al cerrar cada modo.
- **Audio:** `SFX_CLICK_SUBTLE` para toda interacción sin efecto. Los demás sonidos los emite el dueño del objeto. Al entrar en `inspección` y `lectura` el mundo se atenúa levemente (propuesta a `audio-director`).
- **Inspección:** el objeto en la mano se ilumina con una luz de relleno propia para que sus detalles sean legibles incluso en la oscuridad de la escena (pilar *El espacio expresa la emoción* sin sacrificar legibilidad).

## Game Feel

- **Respuesta:** cada pulsación procesada responde en ≤ `latencia_feedback_ms` (100†).
- **Foco:** el icono aparece y desaparece sin parpadeo ante el temblor; no se «roba» el foco entre objetos apilados.
- **Inspección:** el objeto responde al giro sin retardo ni inercia; un objeto pequeño ocupa unos 25° de un campo vertical de 70°, es decir, algo más de un tercio (36 %) de la altura de pantalla (F3).
- **Vista cercana:** la cámara se acerca con la curva suave del Jugador y se siente deliberada, no lenta; salir (0,5 s) es más rápido que entrar (1,0 s).
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
| `design/gdd/jugador-en-primera-persona.md` · reglas 16 a 19, 23, 24; Visual/Audio (gestos); D-16 | Rayo sin balanceo, cesión y devolución de cámara, gestos `HAND_*` | **Fuente de verdad** del contrato 2↔7 (decisión 2026-11-09) |
| `design/gdd/entrada-y-controles.md` · reglas 6, 8, 10–13, 14, F6, F8 y Open Questions 2 y 3 | Contextos, gestos, pulsación prolongada y transiciones | Contrato directo; F6 resuelve la Open Question 2 |
| `design/gdd/base-de-contenido-narrativo.md` · reglas 1, 3 | Etiquetas, `OBJ_`, documentos y estilos | Origen de los textos |
| `design/gdd/estado-y-bus-de-eventos.md` · regla 10 | Documentación de avisos por el emisor | Los avisos de la regla 29 se añaden allí |
| `design/gdd/escena-de-planta.md` · reglas 4, 9.6 y 10 | Contenedores e IDs; configuración leyendo hechos; punto de aparición | Los objetos se localizan por ID |
| `design/gdd/game-pillars.md` | *Autonomía como progresión*, *Tensión sin castigo*, *Información incompleta* | Pilares que este sistema sirve |
| `design/gdd/marco-de-puzles.md` | Receptor de las vistas de puzle, modo `WORLD`, `close_view_after_s` | Sistema que consume este |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/interaction/`), bloqueante; **I** = test de integración o playtest documentado (`tests/integration/interaction/`), bloqueante; **V** = captura retenida en `production/qa/evidence/`, bloqueante. Los tests L usan un mundo de física falso, un reloj inyectado y un catálogo de prueba. Tolerancia numérica ±0,001 salvo indicación. Los valores † pueden cambiar tras el playtest.

**Detección (reglas 2 a 8, F1)**
- **AC-01 (R2, L)**: **GIVEN** un objeto del mundo que no está en `interactables.json`, **WHEN** el barrido lo toca, **THEN** no es objetivo.
- **AC-02 (R5, F1, L)**: **GIVEN** el teléfono a 1,38 m y alcance 1,8, **WHEN** el barrido lo toca, **THEN** es el objetivo; **GIVEN** que está a 1,9 m, **THEN** no hay objetivo.
- **AC-03 (R5, L)**: **GIVEN** una pared entre la cámara y un objeto a 1,0 m, **THEN** no hay objetivo.
- **AC-04 (R5, F1, L)**: **GIVEN** `B02` (prioridad 1) a 1,10 m y `B05` (prioridad 2) a 1,12 m, con el eje dentro de ambos colliders, **THEN** el objetivo es `B05`; **GIVEN** que `B05` está a 1,20 m (Δ = 0,10 m > 0,03), **THEN** es `B02`.
- **AC-04b (R5, F1, L)**: **GIVEN** el eje dentro del collider de `B02` y `B05` solo tocada por la esfera (ambos en `G`), **THEN** el objetivo es `B02` aunque `B05` tenga mayor prioridad; **GIVEN** el eje fuera de ambos y los dos tocados por la esfera, **THEN** es `B05` (prioridad); **GIVEN** empate total, **THEN** gana el ID menor, con independencia del orden de carga.
- **AC-04c (R5, F1, L)**: **GIVEN** `B05` plana a 1,50 m sobre una mesa cuya superficie corta el segmento a 1,499 m, **THEN** `B05` es objetivo (no ocluida); **GIVEN** una pared a 1,0 m entre la cámara y `B05`, **THEN** no hay objetivo. **GIVEN** la escena del slice (I), **THEN** `B02` es alcanzable en toda su base útil sin que `B05` la robe (collider de `B05` con ≥ 0,02 m de margen en planta).
- **AC-05 (R7, L)**: **GIVEN** un objetivo y un paso de física de 1/60 s, **WHEN** el rayo lo pierde durante 7 pasos y vuelve, **THEN** `get_target()` no cambia en ningún paso; **WHEN** lo pierde durante 8 pasos y el rayo está a menos de `radio_pegajoso_m`, **THEN** el objetivo pasa a nulo en el 8.º; **WHEN** lo pierde durante 3 pasos y el rayo sale a más de `radio_pegajoso_m`, **THEN** pasa a nulo de inmediato; **WHEN** aparece otro candidato válido durante la retención, **THEN** lo sustituye en ese mismo paso. No se emite ningún aviso de pérdida.
- **AC-06 (R8, L)**: **GIVEN** un objeto con `habilitado_si = {todos: [caja_c1]}` y `caja_c1` falso, **THEN** no es objetivo; **WHEN** `caja_c1` pasa a verdadero, **THEN** lo es en el paso de física siguiente.
- **AC-06b (R3, R8, L)**: **GIVEN** un objeto cuyo manejador contesta `can_interact = NO`, **THEN** no es objetivo, no hay icono y no suena `SFX_CLICK_SUBTLE` al pulsar; **WHEN** pasa a `SI`, **THEN** es objetivo en el paso siguiente; **GIVEN** `SIN_EFECTO`, **THEN** es objetivo con icono y al pulsar suena `SFX_CLICK_SUBTLE`. **GIVEN** un manejador con `etiqueta()` que devuelve una clave distinta, **THEN** `get_target()` entrega esa clave.
- **AC-07 (R5, L)**: **GIVEN** un contexto distinto de `exploración`, **THEN** el barrido no se ejecuta y no hay objetivo.
- **AC-07b (R5, L)**: **GIVEN** balanceo `completo` y la cámara desplazada por el balanceo, **THEN** el origen del barrido es el del rayo de visión del Jugador (ojos sin balanceo), no el de la cámara.

**Pulsación (reglas 9 a 12, F2)**
- **AC-08 (R9, L)**: **GIVEN** un objeto solo con `verbo_corto`, **WHEN** se pulsa `interactuar`, **THEN** el verbo se dispara en ese fotograma.
- **AC-09 (R9, F2, L, consultivo: capacidad no usada en el slice, D7-24)**: **GIVEN** un objeto con `verbo_corto` y `verbo_largo` y `t_hold` = 0,5 s, **WHEN** se mantiene 0,18 s y se suelta, **THEN** se dispara el verbo corto al soltar; **WHEN** se mantiene 0,62 s, **THEN** se dispara `leer` a los 0,50 s y la suelta posterior no dispara nada.
- **AC-10 (R9, F2, L)**: **GIVEN** `t_hold` = 0,5 y 0,30 s mantenidos, **THEN** p = 0,6 y el anillo es visible; **GIVEN** 0,10 s, **THEN** el anillo no es visible.
- **AC-11 (R9, L)**: **GIVEN** un objeto solo `leer` (`B05`), **WHEN** se pulsa un toque corto, **THEN** no se abre `lectura` y suena `SFX_CLICK_SUBTLE`.
- **AC-12 (R10, L)**: **GIVEN** un objeto en enfriamiento de 0,25 s, **WHEN** se pulsa a los 0,10 s, **THEN** se descarta; a los 0,30 s, se procesa.
- **AC-13 (R10, L)**: **GIVEN** `V02` con `gesto_hecho = ANIM_PHONE_PICKUP` y un doble del Jugador, **WHEN** el manejador devuelve `HECHO`, **THEN** se pide `reproducir_gesto(ANIM_PHONE_PICKUP)`, el contexto queda bloqueado (transición de Entrada, **no** `sin control`) hasta el aviso «gesto terminado» y un `interactuar` recibido en ese intervalo se descarta; **WHEN** el doble rechaza el gesto, **THEN** no se bloquea el contexto y se registra. No existe ningún campo de duración de bloqueo en el catálogo.
- **AC-14 (R11, L)**: **GIVEN** un objeto cuyo manejador devuelve `SIN_EFECTO`, **THEN** en ≤ 6 pasos de física (100 ms a 60 Hz = `latencia_feedback_ms`) suena `SFX_CLICK_SUBTLE`, se pide `HAND_REACH` y, si tiene `texto`, se pide el pie.
- **AC-15 (R12, F5, L)**: **GIVEN** el texto de 30 caracteres, **THEN** el pie dura 2,64 s (±0,01); un texto de 90 caracteres dura 6,93 s; uno de 120 caracteres se rechaza en datos (excede `texto_max_caracteres`); con `multiplicador_pie` 2,0 el de 30 caracteres dura 5,29 s (±0,01).
- **AC-16 (R28, L)**: **GIVEN** una pulsación prolongada en curso, **WHEN** llega `pausa`, **THEN** se cancela sin disparar `leer`.

**Inspección (reglas 13 a 15, F3)**
- **AC-17 (R13, F3, L)**: **GIVEN** el peluche (r = 0,104 m), **THEN** `d_ins` = 0,469 m (±0,005); **GIVEN** un objeto con r = 0,02 m, **THEN** se limita a 0,25 m; **GIVEN** r = 0,20 m, **THEN** 0,60 m y `d_ins − r` = 0,40 m; **GIVEN** cualquier r en (0, 0,20], **THEN** `d_ins − r` ≥ 0,19 m; **GIVEN** un `INSPECCION_MANO` con r = 0,5 m, **THEN** se rechaza en datos (excede `r_max_inspeccion_m`).
- **AC-18 (R14, L)**: **GIVEN** `inspección` con yaw_Δ = 1,8° y `k_inspeccion` = 1, **THEN** el objeto gira 1,8° y la cámara no gira; **WHEN** se gira 3.600°, **THEN** no hay tope.
- **AC-19 (R15, L)**: **WHEN** llega `atrás` en `inspección`, **THEN** el objeto vuelve a su sitio en `t_mano_s` y el contexto vuelve a `exploración`; no se ha escrito ningún hecho.
- **AC-20 (R13, I)**: **GIVEN** `V05` en la mano, **WHEN** se gira hasta ver la pegatina, **THEN** la pegatina se ve entera, mide ≥ 80 px de lado a 1080p (†) y 3 de 3 testers la describen como «del equipo antiguo» o equivalente (playtest documentado).
- **AC-20b (R13, R15, L)**: **GIVEN** un doble del Jugador, **WHEN** se entra en `inspección` con `V05`, **THEN** se pide `reproducir_gesto(HAND_REACH)` y después `HAND_HOLD_ITEM` sin llamar a `sostener` ni a ninguna operación de ocultar manos; **WHEN** llega `atrás`, **THEN** tras `t_mano_s` se pide `reposo()`.
- **AC-21 (R13, I)**: **GIVEN** `inspección` abierta, **WHEN** suena `MEGA_01`, **THEN** la megafonía suena y la inspección no se cierra.

**Lectura (reglas 16 a 18)**
- **AC-22 (R16, L)**: **GIVEN** `A04`, **WHEN** se mantiene `interactuar` 0,5 s, **THEN** se pide `lectura` con la clave del formulario y su estilo.
- **AC-23 (R17, L)**: **GIVEN** `R01` con dos páginas en la página 1, **WHEN** llega `interactuar`, **THEN** pasa a la página 2 (`ANIM_PAGE_TURN`); **WHEN** llega otra vez, **THEN** no hace nada.
- **AC-24 (R18, L)**: **GIVEN** `A04` con `lectura_min_s` 2,0, **WHEN** `lectura` permanece abierta 2,0 s de tiempo de juego, **THEN** se emite una sola vez «lectura completada» (`A04`); **WHEN** se cierra a 1,9 s, **THEN** no se emite.
- **AC-25 (R18, L)**: **GIVEN** `lectura` abierta con la pausa de 10 s, **THEN** el contador no avanza durante la pausa.

**Vista cercana y ordenador (reglas 19 a 24, F4, F6)**
- **AC-26 (R19, F4, L)**: **GIVEN** `D01a` con `t_vista_entrada_s` 1,0 s y un doble del Jugador, **THEN** 7 pide `ceder_camara("interaccion:vista", anclaje, 70°, 1,0 s)` (la curva y la pose final son AC-20 del Jugador); **WHEN** el doble avisa «cámara cedida» a 1,0 s, **THEN** la vista pasa a Abierta; **GIVEN** un doble que **nunca** avisa, **THEN** a los 3 s se libera el contexto, la vista queda Abierta y se registra el error (Entrada F8). **GIVEN** la secuencia del slice (dueño anima 1,6 s y llama a `abrir_vista`), **THEN** hay dos transiciones consecutivas y la primera acción se acepta a los 2,6 s.
- **AC-27 (R19, L)**: **GIVEN** `D01a` abierto, **THEN** se emite una sola vez «vista cercana abierta» con el ID de la vista, el cursor aparece en el centro y se pide `apuntar` cada fotograma.
- **AC-27b (R30, L)**: **GIVEN** `abrir_vista` con otro modo abierto, sin receptor registrado o fuera de `exploración`, **THEN** devuelve `RECHAZADA(motivo)` y no se pide ninguna cesión; **GIVEN** `cerrar_vista` sobre una vista no abierta, **THEN** no hace nada y se registra.
- **AC-28 (R20, L)**: **GIVEN** una vista abierta con un receptor de prueba cuyo `elements()` declara una forma, **WHEN** el cursor se mueve sobre ella, **THEN** recibe `actualización` con `elemento_bajo` = ID y `pos_vista` en metros (picking 2D, sin física); **WHEN** se hace `agarrar` pulsando sobre el elemento y moviendo 12 px, **THEN** recibe `inicio` con `elemento` = ID y `pos_px` = la posición **al pulsar**, `actualización`… y `fin` con el mismo `elemento` aunque el cursor salga (y `elemento_bajo` nulo); **WHEN** hace un clic, **THEN** recibe `inicio` y `fin` en el mismo fotograma; **WHEN** hace `rotar` con el ratón 40 px, **THEN** `delta_grados` suma 10,0° (1 px = 0,25°).
- **AC-29 (R21, L)**: **GIVEN** un `agarrar` en curso, **WHEN** llega `atrás`, **THEN** el receptor recibe `cancelación` antes del aviso de cierre.
- **AC-30 (R22, L)**: **GIVEN** un elemento de 20 px de lado, **THEN** su hit-test es de al menos 44 px; **GIVEN** dos elementos con centros a menos de 128 px, **THEN** en desarrollo se registra una advertencia.
- **AC-31 (R23, L)**: **WHEN** llega `atrás` con la vista abierta, **THEN** se pide `devolver_camara("interaccion:vista")` (el regreso dura `t_devolver` = 0,5 s del Jugador, AC-20 del Jugador; 7 no tiene duración propia) y `reposo()`; el contexto **permanece bloqueado** y un `interactuar`/`mover` recibido antes del aviso «cámara devuelta» se descarta; **WHEN** llega el aviso, **THEN** se emite «vista cercana cerrada» con motivo `jugador` y el contexto vuelve a `exploración`; **WHEN** llega `atrás` durante la entrada o el regreso, **THEN** se ignora.
- **AC-31b (R23, L)**: **GIVEN** `cerrar_vista(D01a, resuelto)` tras `close_view_after_s`, **THEN** el cierre sigue el mismo orden (cancelación, `on_close(resuelto)`, devolución de cámara, aviso con motivo `resuelto`) y 7 no tiene temporizador propio de auto-salida.
- **AC-32 (F6, L)**: **GIVEN** H = 1080, d = 0,35 m, FOV_v = 70°, **THEN** ppm = 2.203 (±1), 0,04 m = 88 px (±0,5) y 0,10 m = 220 px (±0,5); **GIVEN** H = 1200 (viewport lógico 16:10), **THEN** ppm = 2.448 (±1); con FOV horizontal 70° en 16:9, ppm = 3.917 (±2) (caso de control del eje del FOV, verificación pendiente V2).
- **AC-33 (R24, I)**: **GIVEN** `V01`, **WHEN** se activa, **THEN** Entrada entra en `ordenador`, se pide `ceder_camara("interaccion:ordenador", …)` (sin animación de sentarse ni movimiento del cuerpo), la cámara se acerca a la pantalla y `atrás` sale con el mismo orden que la vista.

**Estado y escenas (reglas 3, 4, 27)**
- **AC-34 (R4, L)**: **GIVEN** cualquier partida, **THEN** este sistema no escribe ningún hecho ni guarda nada.
- **AC-35 (R27, L)**: **GIVEN** `lectura` abierta, **WHEN** el director pide `cerrar_modos()`, **THEN** se cierra con motivo `sistema` y se emite el aviso; **GIVEN** `ordenador` abierto, **THEN** no se cierra.
- **AC-35b (R27, L)**: **GIVEN** una vista abierta con una `lectura` apilada, **WHEN** llega `atrás`, **THEN** se cierra solo la lectura (aviso «lectura cerrada», motivo `jugador`), las manos vuelven a `apuntar` y la vista sigue abierta; **WHEN** llega `cerrar_modos()`, **THEN** se cierran `lectura` y luego la vista, ambas con motivo `sistema`; **WHEN** el marco pide `cerrar_vista(resuelto)` con la lectura abierta, **THEN** no se cierra nada hasta cerrar la lectura y la vista se cierra en el paso siguiente con motivo `resuelto`.
- **AC-35c (R9, Edge Cases, L)**: **GIVEN** el modo «alternar en lugar de mantener» (Entrada, regla 14), **WHEN** se pulsa `interactuar` sobre `A04` y se vuelve a pulsar tras `t_hold`, **THEN** se abre `lectura`; **WHEN** llega `atrás` antes de la segunda pulsación, **THEN** el anillo se cancela sin abrir.
- **AC-36 (R3, L)**: **GIVEN** un manejador que devuelve `HECHO`, **THEN** se emite «interacción ejecutada» con el ID, el verbo y el resultado.
- **AC-37 (R2, R6, R31, L)**: **GIVEN** el catálogo del slice, **THEN** contiene exactamente las 35 entradas de la tabla de objetos, derivadas del Anexo A del slice (columna «Interacción» distinta de «Ninguna», «Visibles siempre», «Ver…», «Emite…»), con `A02` como `A02a`–`A02c` y `D01` solo como `D01a`–`D01d`; **y** `V07`, `R03`, `B04`, `B08`, `C01`–`C04`, `D01` y la puerta de salida de Recepción **no** están en él. La lista esperada se calcula desde el Anexo A en la prueba, no se enumera a mano.
- **AC-38 (R2, R3, R30, L)**: **GIVEN** el catálogo de ejemplo de la regla 31 (`V02`, `A04`, `D01a`), **THEN** valida contra el esquema; **GIVEN** una entrada con un campo de duración de bloqueo, `requiere_ítem` o un `INSPECCION_MANO` con r > `r_max_inspeccion_m`, **THEN** se rechaza en datos.

**Evidencia visual (V, captura retenida en `production/qa/evidence/`; estándar de UI y Visual/Feel del proyecto)**
- **AC-V1 (R5, UI, V)**: icono y etiqueta («Descolgar») sobre `V02` en estado `vibrando`, a ~1,4 m, y la misma vista sin icono con `V02` en `reposo`.
- **AC-V2 (R12, UI, V)**: el pie de `D03` («Café frío. Lo dejó a las siete») dentro de los márgenes seguros del 5 %.
- **AC-V3 (R9, UI, V)**: el anillo de `leer` sobre `B05` con p ≈ 0,6 (0,30 s mantenidos).
- **AC-V4 (R13, R14, Visual, V)**: `V05` en la mano a 0,469 m con las manos `HAND_HOLD_ITEM`, y otra captura con la pegatina de frente (sirve de evidencia de AC-20).
- **AC-V5 (R16, UI, V)**: `A04` en `lectura` (estilo `impreso`) con las manos `HAND_READ`.
- **AC-V6 (R19, R20, UI, V)**: `D01a` en vista cercana con el cursor visible y no circular, en 16:9 y en 16:10, y los elementos con el tamaño mínimo `pick_min_px` indicado en la captura de depuración.
- **AC-V7 (R24, UI, V)**: el ordenador (`V01`) abierto con la cámara acercada.
- **AC-V8 (R10, Visual, V)**: `HAND_TURN` sobre `B02` y `HAND_REACH` ante un `SIN_EFECTO` (lector `C06` sin tarjeta con su pie), para comprobar que el gesto se reconoce como propio.

**Criterios de experiencia (playtest, I)**
- **AC-X1 (I)**: **GIVEN** un jugador nuevo, **WHEN** juega la escena 1 sin guía, **THEN** abre el ordenador y descuelga el teléfono sin preguntar cómo interactuar. El umbral **≥ 4 de 5 testers es una propuesta (†) de este GDD**, no una cita; solo se apoya en el criterio 1 de slice §19.1 («sin guía externa»).
- **AC-X2 (I)**: **GIVEN** un tester con temblor simulado (ratón con ruido de ±6 px a 1080p, es decir ±0,39° con 70° de FOV vertical, ≈ ±1,2 cm a 1,8 m, muy por debajo de `radio_pegajoso_m`), **WHEN** intenta leer `A04`, **THEN** completa la lectura prolongada sin que el icono parpadee.
- **AC-X2b (R7, R9, L)**: mismo caso con una entrada simulada: el rayo oscila ±0,39° a 8 Hz sobre el collider de `A04` durante 0,6 s mantenidos; `get_target()` es `A04` en todos los pasos y `leer` se dispara a los 0,5 s.
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
| D7-12 | **(Usuario, 2026-11-09)** El GDD del Jugador (2) es la fuente de verdad del contrato 2↔7: nombres `HAND_*`, duraciones de gesto y `t_devolver` = 0,5 s del Jugador, rayo desde los ojos sin balanceo, sin ocultar manos (se piden gestos) | Duraciones propias (`t_vista_salida_s`, `bloquea_s`), `ANIM_HAND_*`, ocultar manos, rayo desde la cámara | Una sola fuente por número; el Jugador ya lo tenía implementado en sus ACs |
| D7-13 | **(Usuario)** 7 no pide `sin control`: bloquea el contexto con una transición de Entrada (regla 8) hasta el aviso «gesto terminado» / «cámara devuelta» | `bloquea_s` + `sin control` | `sin control` es solo del director de escenas (Entrada regla 6) |
| D7-14 | Picking 2D en el plano de la vista contra las formas que declara el receptor (`elements()`) | Colliders 3D y rayo de física por elemento | Aritmética pura y comprobable sin motor; evita depender de consultas de forma no verificadas; da a Entrada las posiciones en px para F5b |
| D7-15 | Detección en 4 pasos: contactos → oclusión con tolerancia → grupo por profundidad → «contiene el eje» antes que `prioridad` | «Primer contacto» (regla 5 original) | El primer contacto hacía inalcanzable AC-04; el criterio del eje evita que la nota `B05` robe la base de `B02`; la tolerancia deja ver objetos planos sobre una mesa |
| D7-16 | `can_interact = NO` equivale a deshabilitado (sin icono ni reacción); `SIN_EFECTO` es visible y explica | `NO` con icono atenuado | D7-4 (*Autonomía como progresión*); permite `A04` dentro de `A03`, cajones abiertos y teléfono en reposo sin hechos nuevos |
| D7-17 | El dueño puede dar la etiqueta según el estado (`etiqueta()` opcional) | Un único `etiqueta_corto` por entrada | «Encender/Apagar» de `V06` sin duplicar entradas |
| D7-18 | `B04` no es interactuable en 7; `A02` son tres entradas (`A02a`–`A02c`) | `B04` examinable; una entrada con tres textos | El slice no le da verbo al ventanal (sus fragmentos los muestra el marco); `OBJ_<id>` admite un texto por ID |
| D7-19 | Secuencia de `D01a` encadenada (compartimento 1,6 s, luego cámara 1,0 s) | Paralela | Es lo que dice el slice B.3; son dos transiciones bajo el tope de 3 s, peor caso 2,6 s |
| D7-20 | `atrás` cierra el modo superior; `cerrar_modos()` toda la pila; `cerrar_vista(resuelto)` espera a que se cierre la lectura apilada | Cerrar todo con `atrás`; cerrar la vista con la lectura abierta | No quitar al jugador lo que está leyendo; `atrás` siempre vuelve un paso |
| D7-21 | El cierre automático se llama `close_view_after_s` y su temporizador es del marco (9); 7 solo ejecuta `cerrar_vista(…, resuelto)` | `t_auto_salida_s` propio de 7 | Un nombre y un dueño; ya está en `puzzles.json` |
| D7-22 | `requiere_ítem` sale del catálogo de 7; lo posee el marco (`requires.items`) | Declararlo en los dos ficheros | Evita requisitos duplicados (revisión del Marco, hallazgo 14) |
| D7-23 | `R01`: `LEER` mantenido para abrir y `interactuar` para pasar página | «Pasar página» como verbo corto del objeto | Mantiene una sola tecla y el verbo «Leer»; el slice dice «Pasar página» para la acción dentro del libro |
| D7-24 | Mantener `verbo_corto` + `verbo_largo` como capacidad del catálogo; AC-09 pasa a consultivo | Retirar la capacidad | Ningún objeto del slice la usa, pero retirarla costaría rehacerla si aparece; no bloquea el slice |
| D7-25 | Un pie de texto nunca lleva información necesaria; accesibilidad con `multiplicador_pie` y `pie_persistente` | Registro de últimos textos en el slice | No se puede releer; el registro queda fuera de alcance |
| D7-26 | Inspección en mano limitada a r ≤ 0,20 m | Distancia variable sin tope | Garantiza `d_ins − r` ≥ 0,19 m; solo `V05` (r = 0,104 m) la usa |
| D7-27 | Barrido de esfera con respaldo de 7 rayos (`intersect_ray`, documentado) | Fijar ya `ShapeCast3D` | Las consultas de forma con Jolt no están cubiertas por la referencia del motor; decide el ADR tras verificar |
| D7-28 | `leer` de Entrada no se usa en `inspección`: se pide retirarlo de ese contexto | Darle un uso (releer inscripción) | Una acción sin función es ruido para el jugador y para el rebinding |
| D7-29 | `V01` solo acerca la cámara (sin sentarse); `A03` y las tarjetas no son inspeccionables | Animación de sentarse; inspeccionar la caja | El slice no tiene silla interactuable; los ítems los sostiene 20 |

## Open Questions

**Cerradas (2026-11-09):** (1) Contrato con el sistema 2: adoptado el GDD del Jugador como fuente de verdad (D7-12), sin supuestos A1 a A4. (2) Nombres de gestos: son los `HAND_*` del Jugador.

**Pendientes de verificación en el editor Godot 4.7** (la referencia `docs/engine-reference/godot/` no los cubre; no se afirman aquí; propietario `godot-specialist` / ADR, antes de implementar los sistemas 7 y 9):

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| V1 | Consultas de forma (`intersect_shape`, `ShapeCast3D`) con Jolt: devolución de todos los contactos y orden; si no sirven, el haz de 7 rayos (D7-27) | `godot-specialist` | ADR de interacción |
| V2 | Eje por defecto del FOV de `Camera3D` (`keep_aspect`): F6 y AC-32 asumen FOV **vertical** | `godot-specialist` | ADR de interacción |
| V3 | Colocar el cursor en `cursor_inicial` (`warp_mouse`) y pasar de ratón capturado a visible y viceversa | `godot-specialist` | ADR de interacción |
| V4 | Altura lógica del viewport (`H_px`) con el estiramiento del proyecto (`canvas_items`, `expand`) en 16:9 y 16:10 | `godot-specialist` + UI | Antes de AC-V6 |
| V5 | Transformada del barrido: interpolación de física 3D frente a render (la cámara se interpola a la tasa de render) | `godot-specialist` + Jugador | ADR del Jugador |
| 3 | ¿`D04` (marco de foto, «usada en el puzle 5») es solo `INSPECCION_TEXTO` o abre una vista del puzle 5? | GDD del puzle 5 | GDD del puzle 5 |
| 4 | Registro de «últimos textos» de pie (releer) | Producción / UX | Fuera del slice; tras playtest (H-19) |
| 5 | ¿La pausa a mitad de una transición detiene el tope de 3 s? Entrada lo afirma para `sin control`; confirmar para transiciones de 7 | GDD de Entrada | Re-review |

## Propuesta de registro

Para `design/registry/entities.yaml` (no se edita aquí; lo hará quien consolide):

| Tipo | Nombre | Valor / contenido | Fuente |
|---|---|---|---|
`alcance_interaccion_m` (1,8 m) **ya está en el registro** (propietario: este GDD): no se vuelve a proponer. `lock_max_s` figura allí como referenciado por 7, pero **este GDD no lo usa** (el tope de transición de 3 s es de Entrada): quitar a 7 de su `referenced_by`.

| Tipo | Nombre | Valor / contenido | Fuente |
|---|---|---|---|
| constante | `radio_apuntado_m` | 0,06 m† | este GDD, F1 |
| constante | `pick_min_px` | 44 px† (ya citada por el Marco) | este GDD, regla 22 |
| constante | `r_max_inspeccion_m` | 0,20 m† | este GDD, F3 |
| constante | `lectura_min_s_A04` | 2,0 s† | este GDD, regla 18; slice A.4 |
| constante | `t_vista_entrada_D01a_s` | 1,0 s | slice B.3 |
| fórmula | `F6_ppm` | `(H/2)/(d·tan(FOV_v/2))`; 2.203 px/m en `D01a` (H = 1080) | este GDD |
| aviso | «vista cercana abierta/cerrada», «lectura completada», «lectura cerrada», «interacción ejecutada» | emisor: 7 | este GDD, regla 29 |
| dato | `assets/data/interaction/interactables.json` | catálogo de 35 objetos | este GDD, reglas 2 y 31 |
| dependencia | índice, fila 7 y Feature Layer punto 1 | añadir 4 y la blanda `3` | este GDD |
