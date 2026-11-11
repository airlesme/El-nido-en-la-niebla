# Baseline de requisitos técnicos (provisional)

> Extraído el 2026-11-10 de los 30 GDDs por 10 agentes (lectura parcial: cada bloque lista su «NO LEÍDO»). Los TR-ID son **provisionales**: `/architecture-review` les da el definitivo en `tr-registry.yaml`. Sin cotejar entre bloques.

---

<!-- bloque G1 -->
# Baseline TR - Grupo 1 (state, input, content)

## GDD 3: estado-y-bus-de-eventos.md (slug `state`)

| TR-ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-state-001 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Catálogo cerrado de exactamente 20 hechos cargado de `assets/data/state/flags.json` (nombre, tipo `bool`/`int` con rango/`enum`, inicial, `owner`, regla de derivación opcional); fichero ausente o corrupto impide entrar en partida, muestra error y cierra (CA-26) | Data |
| TR-state-002 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Lectura del valor de un hecho en coste constante y sin asignaciones (lo lee el 7 en cada paso de física para ~35 objetos con `habilitado_si`) | Core |
| TR-state-003 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Una escritura válida se aplica en el acto (y recalcula derivados) aunque ocurra durante una entrega de avisos; solo el aviso puede diferirse; lectura posterior devuelve el valor nuevo | Core |
| TR-state-004 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Validación estricta de escritura sin conversiones de tipo (float en int, int en bool inválidos), rango, hecho no declarado, derivado, y cambio de hecho de un solo sentido; en dev detiene la ejecución, en build final ignora y escribe una línea de log | Core |
| TR-state-005 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Comprobación de `owner` por escritor solo en builds de desarrollo (no en la final); el `owner` de los hechos de puzle es el 9 | Core |
| TR-state-006 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Hechos de un solo sentido (bool/enum salvo `pendiente_revelacion`); solo `pos_L/C/R` (int 1-4, inicial 2) y `pendiente_revelacion` son reversibles | Data |
| TR-state-007 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Hecho derivado declarado en datos como combinación de otros (`caja_completa` = `caja_c1`∧`caja_c2`∧`caja_c3`∧`caja_c4`), recalculado automáticamente tras cada cambio de entrada y no escribible; su aviso llega después del de `caja_c4` | Data |
| TR-state-008 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Aviso automático de cambio (nombre, valor anterior, valor nuevo) solo si el valor cambia realmente; suscripción por hecho concreto, a todos los cambios o por aviso con nombre (filtrado en el bus) | Events |
| TR-state-009 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Avisos no persistentes (se pierden si nadie escucha); entrega en orden de ocurrencia y de suscripción, sin reentrada: los avisos provocados durante una entrega se encolan hasta terminar la actual | Events |
| TR-state-010 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Baja de suscripción durante una entrega surte efecto al terminar esa entrega; suscriptores liberados con su escena no deben producir errores en el siguiente cambio (CA-17) | Events |
| TR-state-011 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Tope `max_chained_notices` (propuesta 64, rango 8-256, en datos junto al catálogo): al superarse se descarta la cola, se registra (dev: detiene) y se emite «avisos descartados» | Events |
| TR-state-012 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Un único mecanismo de avisos debe cubrir también el aviso propio de Ajustes (6); el formato técnico (señales/cadenas) y el de la instantánea los fija un ADR | Events |
| TR-state-013 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Instantánea = mapa nombre→valor con `snapshot_version` (inicial 1, consultable); solo los 20 hechos, sin ajustes de volumen/subtítulos/controles | Save/Load |
| TR-state-014 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Restauración síncrona y atómica dentro de una sola llamada (estado «Restaurando»: rechaza lecturas/escrituras/restauraciones reentrantes), descarta la cola, emite un único «estado restaurado» ya en «Listo» | Save/Load |
| TR-state-015 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Tolerancia de tipos al restaurar desde JSON: número con fracción nula se acepta como `int` (2.0→2), con fracción o fuera de rango→inicial con log; hecho ausente→inicial; no declarado→ignorado con log; derivados recalculados. Comportamiento del parser JSON de Godot 4.7 pendiente de verificar | Save/Load |
| TR-state-016 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Petición de instantánea síncrona que nunca espera: devuelve «no disponible» si la cola no está vacía (consulta `cola_vacía()`); Guardado reintenta | Save/Load |
| TR-state-017 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | `escribir_silencioso(hecho, valor)`: solo `owner` (9), solo hechos reversibles, solo en la ventana entre «carga de escena iniciada» y «escena lista» (el 3 se suscribe a ambos), valida como normal, no emite ni encola avisos | Core |
| TR-state-018 (provisional) | estado-y-bus-de-eventos.md | 3 Estado | Consola de pruebas solo en builds de desarrollo (fuerza valores saltando reglas 4 y 6, emite aviso normal y deja log); ausente de la demo, verificado por script CI en `tools/ci/`; logs a destino sustituible por tests | Tooling |

### Contratos (3 Estado)

| Aspecto | Contenido |
|---|---|
| Emite | «estado restablecido», «estado restaurado», «avisos descartados» (Guardado: causa `notices_dropped`), todos sin datos; aviso automático de cambio de hecho (nombre, valor anterior, valor nuevo) |
| Consume | «carga de escena iniciada» y «escena lista» (4; para la ventana de la escritura silenciosa), «carga de escena fallida» (cierra la ventana) |
| API pública | lectura de hecho (valor actual); escritura validada; `escribir_silencioso(hecho, valor)`; petición de instantánea (síncrona; devuelve «no disponible» si hay cola); restaurar desde instantánea; partida nueva (restablecer); `snapshot_version` (solo lectura, inicial 1); `cola_vacía()`; suscripción por hecho / a todos / por aviso con nombre; baja. Nombres de código no fijados salvo los citados (ADR pendiente) |
| Estado que posee | 20 hechos (`correos_leidos`, `archivo_abierto`, `formulario_leido`, `tarjeta_B`, `tarjeta_D`, `memo_leido`, `pos_L`, `pos_C`, `pos_R`, `caja_c1`-`caja_c4`, `pendiente_revelacion`, `caja_completa` (derivado, dueño 3), `carta_variante`, `t4_decision`, `llamada_iniciada`, `respuesta_llamada`, `llamada_completada`); catálogo en `assets/data/state/flags.json`; cola de avisos; estados del sistema Sin cargar/Listo/Restaurando. No persiste a disco (lo hace 5) |
| Nodo/autoload | El GDD no lo dice (formato y mecanismo en ADR). Tabla de avisos con nombre de otros emisores: `EV_PUZZLE_SOLVED_<ID>` (`P1`-`P6`), «puerta abierta» (`A`/`B`/`D`), «línea pedida», «sonido pedido» `{sound_id, fuente?, accion, valor?}`, `pause_opened`/`pause_closed`, «línea iniciada» `{line_id, duracion_s, canal}`, etc. |

## GDD 1: entrada-y-controles.md (slug `input`)

| TR-ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-input-001 (provisional) | entrada-y-controles.md | 1 Entrada | El resto del juego solo conoce acciones lógicas (nunca teclas/botones): acciones físicas (`mover`, `mirar`, `interactuar`, `pausa`, `atrás`, `mover_cursor`, `seleccionar`, `ui_arriba/abajo/izquierda/derecha`, `ui_aceptar`, `ui_atrás`) más gestos derivados (`repasar_bolsillo`, `leer`, `agarrar`, `rotar`, `mantener`) calculados por este sistema; capa de abstracción sobre el Input Map de Godot | Input |
| TR-input-002 (provisional) | entrada-y-controles.md | 1 Entrada | Teclado/ratón y mando activos a la vez; dispositivo activo = último usado, solo para iconos; inicial teclado/ratón; «dispositivo de entrada cambiado» una sola vez por cambio, con histéresis F7 (ratón 12 px en 0,2 s†; stick dz_in+0,15 durante 0,10 s†; `t_lock` 0,4 s†) | Input |
| TR-input-003 (provisional) | entrada-y-controles.md | 1 Entrada | Pila de contextos (`exploración`, `inspección`, `lectura`, `vista cercana`, `ordenador`, `llamada`, `menú`, `sin control`): solo la cima recibe acciones; salir restaura el contexto inferior con la posición del cursor; entrar en el que ya está arriba se ignora y salir de uno que no es cima se rechaza con log; «contexto de entrada cambiado» (anterior, nuevo) solo en cambio efectivo | Input |
| TR-input-004 (provisional) | entrada-y-controles.md | 1 Entrada | `sin control` con dueño y duración declarada; operaciones abrir / cerrar (solo dueño) / traspasar (sin salir ni emitir aviso, renueva tope) / pedir `exploración` (dueño) / reponer `menú` / descartar pila entera al aceptar carga `partida_nueva` o `reanudar` (emite «`sin control` absorbido» con el dueño descartado) / reinicio de pila al descargar escena (conserva dueño, duración y cuenta del tope) | Core |
| TR-input-005 (provisional) | entrada-y-controles.md | 1 Entrada | Tope de seguridad de contextos bloqueantes: 3 s† en transiciones de cámara/animación (cubre `BOX_OPEN_MAX` 1,6 s + `t_vista_entrada_s` ≤1,2 s = 2,8 s) y duración declarada + margen 2 s† en `sin control` (p. ej. `D_carga` 11,67 s → 13,67 s); al vencer registra error y libera (pila vacía → `exploración`); sin duración declarada 3 s con log; el contador se detiene con la pausa | Core |
| TR-input-006 (provisional) | entrada-y-controles.md | 1 Entrada | Estado interno `carga_en_curso` derivado de «carga de escena iniciada»/«terminada»/«fallida» (de 4) que bloquea la pausa; sin esos avisos nunca se bloquea; la pausa por pérdida de foco o mando durante la carga se abre al terminar (o se descarta tras fallo, AC-E14) | Events |
| TR-input-007 (provisional) | entrada-y-controles.md | 1 Entrada | En transiciones bloqueantes solo se acepta `pausa`; el resto se descarta sin guardarse (excepción `repasar_bolsillo`, entregada a 20 sin cola); una tecla mantenida durante la transición no dispara al terminar (salvo el eje continuo `mover`) | Input |
| TR-input-008 (provisional) | entrada-y-controles.md | 1 Entrada | Pausa: el menú consume el evento (`Esc` compartido `pausa`/`ui_atrás` produce un solo cierre), el tiempo de juego se detiene, el ratón se libera/recaptura; pérdida de foco de ventana y desconexión del mando activo abren la pausa en el acto, incluso en transición bloqueante | Input |
| TR-input-009 (provisional) | entrada-y-controles.md | 1 Entrada | Mirada con ratón por píxeles relativos sin delta: Δθ = px·0,10°/px†·s_m·inv, tope ±45°/fotograma, idéntica a 30 y a 144 fps; mirada con stick: ω_max 120°/s†·r^1,5·s_s con delta limitado a 0,1 s | Input |
| TR-input-010 (provisional) | entrada-y-controles.md | 1 Entrada | Zona muerta radial reescalada F1 (dz_in 0,15†, dz_out 0,05†, mínimo dz_in 0,05) evaluada en radial sobre ejes crudos (sin la zona muerta del motor) | Input |
| TR-input-011 (provisional) | entrada-y-controles.md | 1 Entrada | Cursor virtual de mando en viewport lógico 1920x1080 (modo de estiramiento a confirmar en ADR): v_c = 900 px/s†·r²·s_c (máx. 2.400 px/s), limitado a la ventana; atracción F5b (R 64 px†, tope 0,5·v_c·delta, delta ≤0,1 s, un único objetivo por centro más cercano); visibilidad del cursor controlada por 22 (oculto en `llamada`) | Input |
| TR-input-012 (provisional) | entrada-y-controles.md | 1 Entrada | Reconocedor de gestos de puntero por pulsación de `seleccionar`: decide la primera señal (`t_hold` 0,5 s en tiempo real vs `d_arrastre` 8 px†); `gestos_aceptados` ⊆ {`agarrar`,`rotar`,`mantener`} por elemento (aportado por 7 con posición y tolerancia en px); `seleccionar` se emite al soltar; `rotar` ratón 0,25°/px (160 px = 40°, aplica los px previos al umbral), mando F4 (±60 °/s†, freno 0,5† junto a marcas de 5°) | Input |
| TR-input-013 (provisional) | entrada-y-controles.md | 1 Entrada | `interactuar`: verbo corto al pulsar si el objeto no tiene `verbo_largo` (7 informa); con `verbo_largo` decide al soltar o a `t_hold` (`leer`) y exige indicador de progreso; la pulsación se cancela al cambiar de contexto o perder el foco antes de `t_hold` | Input |
| TR-input-014 (provisional) | entrada-y-controles.md | 1 Entrada | `repasar_bolsillo`: derivada de `atrás` solo si la pulsación empieza en `exploración`, en el flanco de pulsación, ignorando auto-repetición del teclado; entregada a 20 (`repasar_bolsillo()`) aun con transición bloqueante, sin guardarla | Input |
| TR-input-015 (provisional) | entrada-y-controles.md | 1 Entrada | Reasignación por dispositivo (hasta 2 asignaciones por acción), validador de conflictos por contexto con lista de pares permitidos (`pausa`/`ui_atrás` en `Esc`), mínimos garantizados (`interactuar`, `atrás`, `pausa`; `atrás` teclado/ratón con una no imprimible), `ui_*` y `mover_cursor` no reasignables, restablecer por acción y por dispositivo | Input |
| TR-input-016 (provisional) | entrada-y-controles.md | 1 Entrada | Asignaciones y valores iniciales en `assets/data/input/default_bindings.json` (recargable sin tocar código); exportar/importar el bloque de asignaciones y ajustes de manejo para persistirlo en Ajustes (6); import tolerante: acción inexistente descartada con log, conflicto en mismo contexto gana la primera | Data |
| TR-input-017 (provisional) | entrada-y-controles.md | 1 Entrada | Campo de texto enfocado en `ordenador` consume antes que cualquier acción las teclas imprimibles, Retroceso, Supr, flechas y Enter; `Esc` y clic derecho siguen siendo `pausa`/`atrás`; `Retroceso` no asignado por defecto | Input |
| TR-input-018 (provisional) | entrada-y-controles.md | 1 Entrada | `get_binding_label(accion, dispositivo) -> {tipo, texto, glifo_id} \| nulo`: consulta pura y determinista (primera asignación por orden de alta), resuelve derivadas a su base, sin aviso propio; la detección de familia de mando (`A`/`✕`) no está verificada en Godot 4.7 | Input |
| TR-input-019 (provisional) | entrada-y-controles.md | 1 Entrada | Ajuste «alternar en lugar de mantener» (`leer`, `mantener`, `agarrar`, `rotar`: una pulsación empieza, otra termina; cancelación con `atrás` o cambio de contexto) y `t_hold` hasta 1,5 s en modo accesible | Accessibility |

### Contratos (1 Entrada)

| Aspecto | Contenido |
|---|---|
| Emite | «dispositivo de entrada cambiado» (teclado/ratón o mando); «contexto de entrada cambiado» (contexto anterior, contexto nuevo); «`sin control` absorbido» (dueño descartado, p. ej. 21). Hacia gameplay: `mover` (vector 2D), `mirar` (Δ orientación), `interactuar` (pulsada, toque corto), `leer`, `rotar_objeto`, `atrás`, `repasar_bolsillo`, `seleccionar`, `agarrar`, `rotar`, `mantener`, `ui_*`, `pausa` |
| Consume | «carga de escena iniciada» (destino, `motivo`, `D_carga`), «carga de escena terminada», «carga de escena fallida» (de 4, bus); «ajustes aplicados» (de 6, fuera del bus). De 7: `gestos_aceptados`, posición y tolerancia en px por elemento, si el objeto tiene `verbo_largo`, transición bloqueante con fin «cámara cedida» / «cámara devuelta» / «gesto terminado». Peticiones de contexto: 7 (`inspección`, `lectura`, `vista cercana`, `ordenador`), 25 (`menú`), 22 (`llamada`, mostrar/ocultar cursor), 21 y 4 (`sin control`); de 4: pedir `exploración`, reponer `menú` |
| API pública | «entrar en» / «salir de» contexto; `sin control`: abrir(dueño, duración), cerrar, traspasar(nuevo dueño, nueva duración), pedir `exploración`, *Reponer `menú`*; `get_binding_label(accion, dispositivo) -> {tipo, texto, glifo_id} \| nulo`; API de reasignación (para 25 y 30); exportar/importar bloque de asignaciones y ajustes de manejo |
| Estado que posee | Pila de contextos, dueño/duración/tope de `sin control`, dispositivo activo, `carga_en_curso`, asignaciones vigentes y ajustes de manejo (los persiste 6); `assets/data/input/default_bindings.json`. No lee ni escribe hechos del bus |
| Nodo/autoload | No lo dice el GDD (ADR pendiente). `t_hold` = `long_press_threshold` en el registro de entidades |

## GDD 18: base-de-contenido-narrativo.md (slug `content`)

| TR-ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-content-001 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Catálogo de 8 tipos de contenido (línea, documento, correo, ficha de tarea T1-T4, pista, texto de interfaz/mensaje del sistema, sonido no verbal con subtítulo `SUB_…`, texto de objeto), cada uno con campos obligatorios no vacíos, en ficheros bajo `assets/data/narrative/` | Data |
| TR-content-002 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Contenido inicial del slice: 28 entradas del §12 (21 líneas audibles + 7 de documento), 6 correos, fichas T1-T4 y 8 claves `PISTA_*`; la lista de claves `UI_…`/`OBJ_…` de la regla 23 es provisional | Data |
| TR-content-003 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Identificadores estables y sensibles a mayúsculas (`VO_G_12A`, `MEGA_02`, `DOC_01`…, prefijos `PISTA_P<n>_N<k>`, `UI_`, `SUB_<EVENTO>`, `OBJ_<id>`, `MAIL_1-4`/`MAIL_X1-X2`); nunca se reutilizan ni renombran: un identificador retirado se marca inactivo y se trata como «no encontrado» | Data |
| TR-content-004 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Grupos de variantes declarados en datos con prefijo y sufijos (incluidos sufijos de varias letras): `CARTA_` A-C, `VO_G_12` A-C, `VO_G_13` A-D, `VO_G_14` `RET`/`ASG`, `VO_V_12` A-D; el consumidor construye el id con el valor de `carta_variante`, `respuesta_llamada` o `t4_decision`; el catálogo nunca lee estado del juego | Data |
| TR-content-005 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Capa de idioma obligatoria en toda lectura: texto por (identificador, idioma); fallback a `es` con log, y «no encontrado» si falta también en `es`; solo `es` en el slice, idioma fijo durante la partida | Localization |
| TR-content-006 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Ningún texto visible al jugador en scripts ni escenas (solo por identificador); escaneo estático de literales en propiedades de texto de nodos de interfaz con lista de excepciones (únicas: «…» y el mensaje de fallo de carga, constantes fuera del catálogo) | Tooling |
| TR-content-007 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Sustitución en lectura de 4 marcadores `{vera}`, `{guardian}`, `{vera_inicial}`, `{guardian_inicial}` desde una tabla de nombres; marcador desconocido inválido (verificador falla); tabla sin alguno de los cuatro lleva el catálogo a «Error» | Localization |
| TR-content-008 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Línea = 1..n segmentos con pausa previa opcional (subtítulo = secuencia de segmentos); documento en fragmentos ordenados (`DOC_01` F1-F3, concatenación con espacio) | Data |
| TR-content-009 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Un dato, un registro: día/hora/remitente/asunto/etiquetas de correo en un único registro (la impresión `I-01` se compone de ellos); orden de presentación como lista explícita (3, X1, 1, 4, X2, 2) distinta del orden cronológico de la solución | Data |
| TR-content-010 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Líneas audibles con campo `audio` (ruta o nulo); sin audio o fichero ausente se trata como «sin audio» (solo subtítulo, duración decidida por 26), con log y sin error en juego | Audio |
| TR-content-011 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Ciclo de vida del catálogo Sin cargar → Cargando → Listo / Error; carga única al arrancar (ficheros leídos una vez), petición en Sin cargar/Cargando = error visible en dev y «…» con log en build final; fichero ausente/corrupto/duplicado → Error, mensaje de fallo de carga y no entra en partida | Core |
| TR-content-012 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Solo lectura en juego (sin operaciones de escritura en la interfaz pública, sin leer estado); recarga en caliente solo en dev como intercambio atómico (validar catálogo nuevo aparte, servir el anterior, sustituir de golpe o conservar y mostrar error; una recarga nunca produce peticiones «Cargando»); inexistente en el export de la demo | Core |
| TR-content-013 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Verificador en `tools/` con código de salida 0/≠0 y parámetro `--hito=calidad`: sin ids duplicados, referencias existentes, líneas audibles con texto, grupos completos, marcadores y nombres literales, conjunto exacto de 8 `PISTA_*`, formato `SUB_<EVENTO>`, marcador de pendiente en texto provisional (aviso → error con hito), audio (aviso → error con hito) | Tooling |
| TR-content-014 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Verificación contra el slice: entradas `fuente: slice_§12` comparadas con la tabla §12 de `design/slice/slice-v0.3.md` (texto entre « », marcadores sustituidos, `[pausa]` → segmentos, fragmentos unidos con espacio, normalización de espacios); falla si falta la fila o el texto difiere | Tooling |
| TR-content-015 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Duplicados entre ficheros: en dev detiene la ejecución, en build final gana el primero cargado con log; en recarga que retira un id en uso, el consumidor conserva el último texto con log y el siguiente intento da «no encontrado» | Data |
| TR-content-016 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Contrato con 9: un efecto `TEXT` de pista referencia siempre una clave `PISTA_P<n>_N<k>` (no `UI_…`) y la carga de `puzzles.json` falla si no existe; las pistas no textuales no llevan clave | Data |
| TR-content-017 (provisional) | base-de-contenido-narrativo.md | 18 Contenido | Gramática de token `{accion:<id>}` en textos de interfaz, sustituida por 24 con el glifo y texto de `get_binding_label`; id desconocido se muestra como nombre de la acción | UI |

### Contratos (18 Contenido)

| Aspecto | Contenido |
|---|---|
| Emite | Nada (no usa el bus; no emite avisos con nombre) |
| Consume | Ficheros de datos de `assets/data/narrative/`; `design/slice/slice-v0.3.md` §12 (solo el verificador); nada del estado ni del bus |
| API pública | Petición de contenido por identificador (y fragmento/segmento) con idioma activo, devuelve texto o «no encontrado»; declaración de letras/sufijos por grupo; lista de presentación de correos y etiquetas; tabla de nombres; recarga en caliente (solo dev). Solo lectura. Nombres de métodos no fijados en el GDD |
| Estado que posee | Catálogo en memoria (read-only), tabla de nombres, listas de presentación, estado Sin cargar/Cargando/Listo/Error; no persiste nada (lo leído/hecho vive en 3). Ficheros bajo `assets/data/narrative/` (nombres exactos no dados) |
| Nodo/autoload | No lo dice el GDD (capa de idioma y formato por ADR). Consumidores por id: 19 (`UI_MAIL_*`, `OBJ_V01`/`OBJ_V08`, `DOC_I01`), 20 (`DOC_FORMULARIO`, `DOC_LISTA_TAREAS`, `UI_BOLSILLO_AYUDA`), 22 (`VO_G_12A/B/C`, `VO_G_13A-D`, `VO_G_14_RET`/`VO_G_14_ASG`, `UI_LLAMADA_OPCION_A-D`, `SUB_BREATH_BROKEN`), 8 (`OBJ_C06`, `OBJ_C07`, `OBJ_D06`, `OBJ_C08`, `MEGA_03`), 14/16/17/25/26 (`UI_P4_*`, `UI_P6_BOTON_A-C`, `UI_PISTAS_*`, `UI_PAUSA_*`, `UI_SUB_HABLANTE_*`) |

## NO LEÍDO

- `estado-y-bus-de-eventos.md`: Summary, Overview, Edge Cases (líneas 128-160: tope de cadena y otros), Visual/Audio, Game Feel, UI Requirements, Cross-References, Open Questions, Decisiones tomadas, Historial. No hay sección Formulas.
- `entrada-y-controles.md`: Summary, Overview, Edge Cases (337-386), Visual/Audio, Game Feel, UI Requirements, Cross-References, Open Questions (522-546; incluye OQ 19), Decisiones tomadas, Historial. No hay sección Tuning Knobs propia (los valores están en Formulas, tabla de rangos). Formulas leídas por completo.
- `base-de-contenido-narrativo.md`: Summary, Overview, Edge Cases (194-223), Visual/Audio, Game Feel, UI Requirements, Cross-References, Open Questions, Decisiones tomadas, Historial. No hay Formulas ni Tuning Knobs.
- Sin verificar contra el slice, los registros ni los GDD vecinos; numeración TR provisional.



---

<!-- bloque G2 -->
# Baseline de requisitos técnicos — lote g2 (settings, scene, player)

## 1. ajustes-persistentes.md (sistema 6, slug `settings`)

### Requisitos técnicos

| TR-ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-settings-001 (provisional) | ajustes-persistentes.md | 6 Ajustes | Catálogo cerrado de claves declarado en `assets/data/settings/defaults.json` (clave, tipo bool/float+rango/enum, inicial); 20 claves con valor + bloque `controles`; escribir una clave no declarada se rechaza. | Data |
| TR-settings-002 (provisional) | ajustes-persistentes.md | 6 Ajustes | Cualquier sistema puede leer cualquier ajuste en cualquier momento (síncrono) y obtiene siempre un valor válido (jugador, inicial si falta/inválido); una escritura válida se aplica al instante (la lectura siguiente ya devuelve el valor nuevo). | Core |
| TR-settings-003 (provisional) | ajustes-persistentes.md | 6 Ajustes | Validación de escritura: float fuera de rango se ajusta al límite y se registra; NaN, clave desconocida, tipo erróneo o enum fuera de lista se rechazan (build de desarrollo: error visible que detiene la ejecución; build final: conserva valor anterior + línea de log). | Core |
| TR-settings-004 (provisional) | ajustes-persistentes.md | 6 Ajustes | Cuantización a rejilla de todo float con paso antes de comparar y guardar: `n = floor(v×N_pasos+0,5)` (N_pasos=20 por defecto, rango 10–40); `campo_vision` paso 5 (n 0–6); `multiplicador_pie` paso 0,25 (n 0–8); el cambio real se decide comparando `n`, no el float. | Core |
| TR-settings-005 (provisional) | ajustes-persistentes.md | 6 Ajustes | Aviso de cambio propio (independiente del bus de eventos de 3) con 3 datos (clave, valor anterior, valor nuevo); solo si cambia realmente; para `controles` solo lleva la clave (igualdad profunda del bloque). | Events |
| TR-settings-006 (provisional) | ajustes-persistentes.md | 6 Ajustes | Semántica de entrega de avisos idéntica al bus (3): orden de suscripción, valor aplicado al instante, aviso encolado si el cambio se provoca dentro de una entrega (sin reentrada), baja de suscriptor efectiva al terminar la entrega en curso. | Events |
| TR-settings-007 (provisional) | ajustes-persistentes.md | 6 Ajustes | Los suscriptores que viven en la escena de planta se dan de baja automáticamente al descargarse; el nodo de Ajustes debe sobrevivir a los cambios de escena sin referencias colgantes (autoload o equivalente). | Scene |
| TR-settings-008 (provisional) | ajustes-persistentes.md | 6 Ajustes | Máquina de 3 estados (Sin cargar, Cargando, Listo); en Cargando no se entregan avisos de cambio; se entra en Listo ANTES de emitir un único aviso «ajustes aplicados» sin datos, y las lecturas dentro de ese aviso ya devuelven los valores cargados. | Core |
| TR-settings-009 (provisional) | ajustes-persistentes.md | 6 Ajustes | Lectura/escritura en Sin cargar/Cargando por terceros: error visible en desarrollo; en build final lectura = inicial (o valor seguro si el catálogo no se pudo leer) y escritura rechazada + log. | Core |
| TR-settings-010 (provisional) | ajustes-persistentes.md | 6 Ajustes | Fichero propio de valores del jugador en la carpeta de datos del usuario, con número de versión de formato (mayor que la conocida o ausente/no numérica = ilegible; menor = claves reconocidas, ausentes = inicial); ruta y formato por ADR (JSON estándar no admite NaN). | Save/Load |
| TR-settings-011 (provisional) | ajustes-persistentes.md | 6 Ajustes | Carga tolerante por clave: ausente, tipo erróneo, enum fuera de lista o NaN toma el inicial solo para esa clave; float fuera de rango se ajusta al límite; clave desconocida se ignora y no se reescribe. | Save/Load |
| TR-settings-012 (provisional) | ajustes-persistentes.md | 6 Ajustes | Fichero ilegible o de estructura inválida: arranca siempre con valores iniciales, renombra el dañado a una sola copia (la segunda sustituye a la primera) sin diálogo bloqueante; si el renombrado falla, el guardado atómico posterior lo sustituye. | Save/Load |
| TR-settings-013 (provisional) | ajustes-persistentes.md | 6 Ajustes | Guardado diferido: escribe si pendiente ∧ (silencio ≥ `t_guardado` 0,5 s [0,2–2,0] ∨ ≥ `t_guardado_max` 5,0 s [2,0–30,0] desde el primer cambio ∨ cierre normal ∨ apertura del menú de pausa); restricción `t_guardado_max ≥ 2×t_guardado`. | Save/Load |
| TR-settings-014 (provisional) | ajustes-persistentes.md | 6 Ajustes | El temporizador del guardado usa reloj monotónico de tiempo real (no afectado por pausa ni escala de tiempo); instantánea al escribir: un cambio durante la escritura mantiene `pendiente`; fallo de escritura mantiene `pendiente` y reintenta tras `t_guardado_max` sin avisar al jugador; el fallo en el cierre no bloquea. | Save/Load |
| TR-settings-015 (provisional) | ajustes-persistentes.md | 6 Ajustes | Escritura atómica (temporal + sustitución); temporal huérfano al arrancar se ignora y elimina; crea la carpeta de datos si no existe. | Save/Load |
| TR-settings-016 (provisional) | ajustes-persistentes.md | 6 Ajustes | El bloque `controles` es opaco: se guarda y devuelve tal cual lo exporta Entrada (sin interpretar); bloque ilegible no impide arrancar (queda «ausente»); Entrada lo importa al recibir «ajustes aplicados». | Input |
| TR-settings-017 (provisional) | ajustes-persistentes.md | 6 Ajustes | Curva de volumen lineal en dB: `vol_db = db_min×(1−v)` (db_min −40, rango −60 a −30), n=0 → marca de silencio y ganancia lineal exactamente 0 (nunca −inf ni log(0)); NaN nunca llega a la curva; entrega al bus de audio (23). | Audio |
| TR-settings-018 (provisional) | ajustes-persistentes.md | 6 Ajustes | `modo_ventana` es el único ajuste que Ajustes aplica al motor (al cargar y en cada cambio, sin reiniciar); si el SO lo rechaza, el ajuste vuelve al valor realmente aplicado, emite aviso y registra; sincroniza si el modo cambia fuera del juego. | Core |
| TR-settings-019 (provisional) | ajustes-persistentes.md | 6 Ajustes | Parámetros de catálogo inválidos (`N_pasos` fuera de 10–40, `db_min` fuera de rango, `t_guardado_max < 2×t_guardado`, `defaults.json` ausente/corrupto) = catálogo corrupto: no se carga la escena de partida y se invoca un manejador de error fatal inyectado con código `CATALOGO_INVALIDO` + parámetro culpable (texto independiente de 18). | Core |
| TR-settings-020 (provisional) | ajustes-persistentes.md | 6 Ajustes | Los ajustes quedan fuera del estado del juego (3) y de la partida guardada (5): ficheros independientes; restablecer todos cubre 18 claves y excluye `modo_ventana`, `advertencias_vistas` y `controles`. | Save/Load |
| TR-settings-021 (provisional) | ajustes-persistentes.md | 6 Ajustes | Testabilidad: lógica L sin E/S real con almacenamiento falso, reloj inyectado (ticks enteros), manejador de errores y destino de log sustituibles (gdUnit4, `tests/unit/settings/`). | Tooling |

(21 filas; el tope de ~18 se excede en 3 por atomicidad del GDD.)

### Contratos

| Aspecto | Contenido (nombres exactos del GDD) |
|---|---|
| Emite | Aviso de cambio propio: (clave, valor anterior, valor nuevo); para `controles` solo la clave. Aviso único «ajustes aplicados» (sin datos) tras entrar en «Listo». Nombre técnico/formato de señal: lo fija un ADR (no nombrado en el GDD). |
| Consume | Bloque `controles` exportado por 1 Entrada; escrituras de 25 Menú de pausa, 30 Accesibilidad, 27 Pantalla de título (`advertencias_vistas`); eventos «cierre normal del juego» y «apertura del menú de pausa» (para volcar pendientes); descarga de la escena de planta (4) para baja de suscriptores. |
| API pública | Leer ajuste por clave; escribir ajuste por clave; «restablecer un ajuste»; «restablecer todos» (18 claves); suscribirse/darse de baja al aviso de cambio y a «ajustes aplicados». Sin firmas ni nombres de método en el GDD (nombres literales no definidos). |
| Estado/persistencia | Claves: `vol_voces`, `vol_efectos`, `vol_musica`, `subtitulos_activos`, `reducir_sobresaltos`, `asistencia_encaje`, `asistencia_rotacion`, `balanceo_camara` (`completo`/`reducido`/`ninguno`), `campo_vision` (60–90, paso 5), `reducir_movimiento`, `multiplicador_pie` (1,0–3,0, paso 0,25), `pie_persistente`, `escala_texto_ui` (`1_00`/`1_25`/`1_50`), `icono_grande`, `etiqueta_accion_visible`, `subtitulos_tamano`, `subtitulos_fondo`, `subtitulos_hablante`, `modo_ventana`, `advertencias_vistas`, `controles`. Ficheros: `assets/data/settings/defaults.json` (iniciales, rangos, `N_pasos`, `db_min`, `t_guardado`, `t_guardado_max`) y fichero de usuario con versión de formato (ruta por ADR) + copia del dañado. Flag interno `pendiente`. |
| Nodo/autoload propuesto | El GDD no nombra un autoload; exige un nodo de Ajustes que sobreviva a cambios de escena (regla 1 de GDD 4, AC-01 de 4). |

## 2. escena-de-planta.md (sistema 4, slug `scene`)

### Requisitos técnicos

| TR-ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-scene-001 (provisional) | escena-de-planta.md | 4 Escena de planta | Exactamente una escena de juego activa a la vez (`planta` o `recepcion`, nunca ambas); la planta es una escena continua sin cargas entre despachos, pasillo, A, B, D y hueco de ascensor. | Scene |
| TR-scene-002 (provisional) | escena-de-planta.md | 4 Escena de planta | Los sistemas 1 Entrada, 3 Estado, 6 Ajustes, 21 Director de escenas y 23 Audio son nodos persistentes fuera de las escenas de juego: sobreviven a cambios de escena con el mismo `get_instance_id()`; 21 queda inactivo (no escucha ni emite) durante la descarga total hasta «descarga total completada» (conserva estado volátil y lo borra al recibirla). | Scene |
| TR-scene-003 (provisional) | escena-de-planta.md | 4 Escena de planta | Contenedores con nombre (`office`, `corridor`, `archive`, `meeting_room`, `guardian_office`, `reception`) y IDs del slice como nombre de nodo con prefijo fijo (V→office, A→archive, B→meeting_room, D→guardian_office, C y T→corridor, R→reception), localizables por ID único; anclas duplicadas: error en dev, primera en orden de árbol en build final. | Scene |
| TR-scene-004 (provisional) | escena-de-planta.md | 4 Escena de planta | Convención espacial fija: metros, X oeste→este, Z sur→norte, Y arriba, origen en el centro del umbral del Despacho de Vera; techo 2,70 m (Recepción 3,20 m); huecos de puerta 1,00×2,10 m; tolerancia de cajas ±0,05 m. | Scene |
| TR-scene-005 (provisional) | escena-de-planta.md | 4 Escena de planta | Anclas obligatorias: `door_slot_a`, `door_slot_b`, `door_slot_d`, `door_slot_elevator` (X 1,4–2,6, 1,2 m), `drawer_slot_a05` (animable por 8), `spawn_office` (propuesto (−3,0; 0,0), yaw hacia V01) y `spawn_elevator` en Recepción (X 3,0–5,0, mira al norte); ausencia = fallo de carga. | Scene |
| TR-scene-006 (provisional) | escena-de-planta.md | 4 Escena de planta | Zonas disparadoras `T-…` como detectores puros (sin lógica ni lectura de hechos) que detectan el sensor esférico del Jugador (radio 0,02–0,05 m, Area3D bajo Jolt) y emiten «zona activada» con su ID en CADA entrada; entradas simultáneas en el mismo fotograma de física se emiten ordenadas lexicográficamente por ID. | Physics |
| TR-scene-007 (provisional) | escena-de-planta.md | 4 Escena de planta | Contrato geométrico con Jugador: paso mínimo 0,60 m (`player_min_passage_width_m`), cápsula fija 0,25 m (`player_capsule_radius_m`), las hojas de puerta desactivan colisión al empezar a abrir, suelo con etiqueta de superficie (`default` si falta) para pasos. | Physics |
| TR-scene-008 (provisional) | escena-de-planta.md | 4 Escena de planta | Petición de carga con 3 datos: `destino` (`planta`/`recepcion`), `motivo` (`partida_nueva`/`reanudar`/`recepcion`), `control_final` (`exploracion`/`ninguno`); precondición: estado (3) «Listo», fuera de restauración y sin otra carga en curso; si no, rechazo (error visible en dev; log en build final). | Core |
| TR-scene-009 (provisional) | escena-de-planta.md | 4 Escena de planta | Recarga completa: cada petición de `planta` descarta la instancia anterior y crea otra nueva (nunca se reutiliza); los nodos huérfanos y suscriptores del bus deben volver al valor de arranque tras 10 ciclos (`OBJECT_NODE_COUNT`, `print_orphan_nodes()`). | Scene |
| TR-scene-010 (provisional) | escena-de-planta.md | 4 Escena de planta | Secuencia de arranque ordenada de 9 pasos: «iniciada» → cortina opaca → descarga → instanciación → colocar jugador → configurar elementos (síncrono, mismo fotograma, con retenciones) → «escena lista» → aclarado → «terminada»; la descarga no empieza hasta α = 1. | Core |
| TR-scene-011 (provisional) | escena-de-planta.md | 4 Escena de planta | Orden de configuración en `planta`: 7 Interacción (catálogo, retención) → 9 valida datos de puzle y configura → resto (8, 10, 20…); validación fallida = fallo de carga inmediato sin esperar `T_cap`; 8 falla abierto (log, sin fallo de carga); no se valida en `recepcion`. | Core |
| TR-scene-012 (provisional) | escena-de-planta.md | 4 Escena de planta | Mecanismo de retención (n_ret) con identificador propio e idempotente (doble liberación no baja de 0); «escena lista» ⇔ n_ret = 0; retención tomada tras «escena lista» se ignora. | Core |
| TR-scene-013 (provisional) | escena-de-planta.md | 4 Escena de planta | Tope total de espera en negro `T_cap` = 10 s (3–30) en tiempo real sin escalar (Δ_real sin recortar), corre aunque la ventana pierda el foco; no se acumula por retención; el fallo se registra con el nombre del elemento. | Core |
| TR-scene-014 (provisional) | escena-de-planta.md | 4 Escena de planta | Cortina como capa negra opaca a pantalla completa por encima del mundo y la interfaz de juego (solo el mensaje de error está por encima), propiedad del sistema 4: `α_out = α_0+(1−α_0)·S(t/d)`, `S(x)=x²(3−2x)`, `t += min(Δ_real, Δ_max)` (Δ_max 0,1 s), d=0 se salta sin división por cero. | Rendering |
| TR-scene-015 (provisional) | escena-de-planta.md | 4 Escena de planta | Duraciones de fundido por `motivo` en `assets/data/scene/load_transitions.json` (0,8 s; partida_nueva d_in 2,0 s; `cierre` solo oscurece); con `reducir_movimiento` de 6 todas pasan a 0,1 s, leído en el paso 1 y fijo durante esa carga. | Accessibility |
| TR-scene-016 (provisional) | escena-de-planta.md | 4 Escena de planta | `D_carga = d_out + T_cap + N_gap·Δ_ref + d_in` (≈11,67 s para recepcion) declarado a Entrada como duración de `sin control` en «iniciada»; N_gap = 2 fotogramas de gracia entre «escena lista» y aclarado; el fallo por `T_cap` debe ocurrir antes del tope de Entrada (D_carga + margen 2 s). | Input |
| TR-scene-017 (provisional) | escena-de-planta.md | 4 Escena de planta | Modelo de pila de contextos de Entrada durante la carga: abrir `sin control`(4) en «iniciada», reiniciar a [`sin control`] al descargar conservando dueño y duración, operación «traspasar `sin control`» a 21 en el fotograma de «terminada» si `control_final`=`ninguno`, pedir `exploración`, y «reponer `menú`» en fallo/descarga total. | Input |
| TR-scene-018 (provisional) | escena-de-planta.md | 4 Escena de planta | Máquina de 4 estados (Sin escena, Cargando, Lista, Error); Cargando rechaza nuevas peticiones y la pausa; en Error de build final la cortina queda en negro con mensaje y una sola acción «Volver al título» (`ui_aceptar` o cursor); nunca se cierra la aplicación ni se aclara una escena a medias. | Core |
| TR-scene-019 (provisional) | escena-de-planta.md | 4 Escena de planta | Descarga total (volver al título): emite «descarga total solicitada», descarga, repone `menú` y emite «descarga total completada»; duración declarada ≤ 3,0 s (`t_descarga_total_max_s`, 1–5); único camino que emite «descarga total completada». | Scene |
| TR-scene-020 (provisional) | escena-de-planta.md | 4 Escena de planta | 4 es el único emisor de «partida terminada» (en el mismo fotograma, tras «carga de escena terminada» de `recepcion`; nunca en fallo); 4 no escribe hechos y solo lee `llamada_completada` (regla 13); no guarda ni pide guardados ni almacena posición. | Events |
| TR-scene-021 (provisional) | escena-de-planta.md | 4 Escena de planta | Escena obsoleta: «estado restablecido»/«estado restaurado» con escena cargada y sin recarga pedida = advertencia (error visible en dev), sin parchear elementos. | Events |
| TR-scene-022 (provisional) | escena-de-planta.md | 4 Escena de planta | Validación de `load_transitions.json` al arrancar (`d` ≤5 s, `T_cap` 3–30, `N_gap` 0–10, `Δ_max` 0,05–0,1); inválido/ausente = no se entra en partida, manejador fatal con código `DATOS_ESCENA_INVALIDOS`. | Data |
| TR-scene-023 (provisional) | escena-de-planta.md | 4 Escena de planta | Testabilidad con dobles inyectados (cargador de escenas falso, cortina doble, jugador espía, elemento espía con `configurar()`, estado falso, bus falso, reloj de ticks enteros); varios AC marcados PV (APIs de Godot 4.7 sin referencia en `docs/engine-reference`: instanciación/liberación de escenas, Area3D bajo Jolt). | Tooling |

(23 filas; excede ~18 por densidad del GDD.)

### Contratos

| Aspecto | Contenido (nombres exactos del GDD) |
|---|---|
| Emite | «carga de escena iniciada» (destino, `motivo`, `D_carga`); «escena lista» (destino); «carga de escena terminada»; «carga de escena fallida» (destino, `motivo`, causa); «partida terminada» (sin datos); «zona activada» (ID de zona `T-…`); «descarga total solicitada» (sin datos); «descarga total completada» (sin datos). Avisos pasan por el bus de 3. A Entrada: abrir `sin control` con duración, cerrarlo, reponer `menú`, pedir `exploración`. |
| Consume | «ascensor llamado» (vía 21, emitido por 8 desde `C08`); petición de carga de `planta` de 5 (`nueva_partida()` → `partida_nueva`, `continuar()` → `reanudar`); petición de `recepcion` y de fundido `cierre` de 21; petición de descarga total (27, 25 «Volver al título»); «estado restablecido», «estado restaurado»; estado (3) «Listo"; hecho `llamada_completada`; `reducir_movimiento` de 6; retenciones de elementos (7, 9, 8, 10, 20…); resultado de validación de datos de puzle de 9. |
| API pública | Petición de carga (`destino`, `motivo`, `control_final`); petición de descarga total; petición de fundido propio (motivo `cierre`); toma/liberación de retención (identificador propio, idempotente); invoca al Jugador «colocar en un ancla con orientación» (`colocar`); elementos exponen `configurar()`. Sin firmas literales. |
| Estado/persistencia | No persiste ni guarda; estados Sin escena/Cargando/Lista/Error; `n_ret`, `t_espera`, α de cortina; fichero de datos `assets/data/scene/load_transitions.json` (tabla d_out/d_in por `motivo`, `T_cap`/`scene_load_timeout`, `N_gap`, `Δ_max`, `Δ_ref`, `d_out` de `cierre`, `t_descarga_total_max_s`); fixtures `floor_layout.json`, `element_ids.json`. Claves de nodo/ancla: `spawn_office`, `spawn_elevator`, `door_slot_*`, `drawer_slot_a05`. |
| Nodo/autoload propuesto | La cortina es propiedad del 4; persistentes fuera de escenas: 1, 3, 6, 21, 23. El GDD no nombra el nodo del propio 4; si el Jugador (2) es persistente o por escena lo fija un ADR (Open Question). |

## 3. jugador-en-primera-persona.md (sistema 2, slug `player`)

### Requisitos técnicos

| TR-ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-player-001 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Cuerpo cinemático (Jolt) con cápsula fija `radio_capsula` 0,25 m / `altura_capsula` 1,75 m, sin sprint/salto/agacharse; desliza por tangente sin rebote ni vibración (<1 mm en 60 pasos); no empuja nada; capa de colisión propia excluida del rayo de 7. | Physics |
| TR-player-002 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Invariante `2×radio_capsula + margen_paso (0,10) = player_min_passage_width_m (0,60)`; validación de datos al arrancar (radio 0,30/0,40, `pitch_max` 95, `T_hist` 0,4, `g_reducido` ≥ `g_completo`, `radio_sensor_zona` 0,10 o sin fichero) = no entra en partida, manejador fatal inyectado con nombre del parámetro. | Data |
| TR-player-003 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Sensor de zona esférico (`radio_sensor_zona` 0,05 m, rango 0,02–0,05) a la cintura, separado de la cápsula, que es lo que detectan los `T-…` (Area3D bajo Jolt, PV): activación con centro en X ∈ (8,95; 8,977] para `T-PAS-1` (9,0 − radio + (0, v·dt]; corregido 2026-11-11, spike S-0003-B). | Physics |
| TR-player-004 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Movimiento en paso de física fijo `f_fisica` = 60 Hz con presentación interpolada entre pasos (misma distancia/s a 30, 60 y 144 fps; pasillo de 24 m ≈ 15,1±0,3 s); interpolación de física 3D en 4.7 pendiente de verificar (alternativa: seguimiento por fotograma con suavizado). | Core |
| TR-player-005 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Transformada que lee cada servicio: rayo de visión (origen), sensor de zona y memoria de poses leen estado de física (sin interpolar, sin balanceo); cámara y manos leen la presentación interpolada; la mirada se aplica por fotograma. | Core |
| TR-player-006 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Velocidad calculada en el marco del cuerpo y luego girada por yaw: `v_obj = v_paseo×m'` (1,6 m/s, k_atras 0,8), `move_toward` con `a_acel` 8,0 / `a_freno` 10,67 m/s², regla de elección con histéresis 0,001; integración semi-implícita; NaN en `mover` = (0,0) + log; objetivo 0 fuera de `exploración`. | Core |
| TR-player-007 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Orientación 1:1 sin `dt`, sin suavizado, yaw wrap [−180,180), pitch ±80° (`pitch_max`), roll = 0 siempre (incluso en interpolación de cesión: Euler yaw/pitch separado, no slerp); único sitio que limita ángulos. | Core |
| TR-player-008 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Cámara principal con FOV vertical (`keep_aspect` = mantener altura, a verificar en 4.7), `campo_vision` 60–90° vía Ajustes aplicado en el acto, tope horizontal `fov_h_max` 120° por F5 con el aspecto vigente, plano cercano `near` 0,05 m; también `fov_destino` de cesiones pasa por F5. | Rendering |
| TR-player-009 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Balanceo de cámara solo traslación ligado a distancia real recorrida (`L_paso` 0,75 m, `A_v` 0,015, `A_h` 0,010, g por nivel `balanceo_camara`, `t_cambio_balanceo` 0,25 s, sin saltos >2 mm); con `ninguno` el offset es exactamente 0. | Animation |
| TR-player-010 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Manos en plano propio dibujadas encima del mundo con `fov_manos` 60° independiente de `campo_vision`/aspecto, sin atravesar muros (técnica —shader, sub-viewport, segunda cámara— por ADR/spike D-28), siempre visibles, con luz mínima garantizada en el apagón. | Rendering |
| TR-player-011 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Sistema de gestos de manos con dos ranuras (derecha/izquierda), gestos de fondo (bucle) vs bloqueantes (duración fija en datos, ≤ `t_transicion_max` 3 s), reglas de rechazo/suspensión/reanudación (D-33), sin cola de peticiones, timeout de 3 s con vuelta a reposo y log. | Animation |
| TR-player-012 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Objeto sostenido: el Jugador posee y mueve su transformada (F10: smoothstep `t_mano_s` 0,4 s, `pos_mano` = ojos + dirección×`distancia_m`, slerp de objeto, `girar_objeto`); `sostener` solo para ítems del catálogo de 20 y objetos de escena sostenibles en datos (solo `V05`), rechaza IDs desconocidos o con gesto bloqueante en curso. | Animation |
| TR-player-013 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Cesión de cámara con un único propietario de lista cerrada en datos (`propietarios_camara`: `interaccion:vista`, `interaccion:ordenador`); F9 smoothstep, duración acotada a `t_transicion_max` 3 s (= Entrada F8), devolución en `t_devolver` 0,5 s sin parámetro de duración; otro propietario rechazado también durante la devolución; poses cedidas con pitch ≤ `pitch_cesion_max` 89°. | Core |
| TR-player-014 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Máquina de 4 estados (Sin escena, Libre, Congelado, Cámara cedida) dirigida por el aviso «contexto de entrada cambiado»; al salir de `exploración` frena con `t_freno` (sin anular de golpe); `mover`/`mirar` descartados durante la devolución; `colocar` deja Congelado hasta `exploración`. | Input |
| TR-player-015 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Pausa: con tiempo de juego detenido velocidad, frenado, interpolaciones, balanceo, gestos y traslados se congelan y reanudan desde donde estaban; `t` de F9/F10 y `t_juego` de F7 es tiempo de juego. | Core |
| TR-player-016 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Memoria circular de poses de `N = ceil(T_hist×f_fisica)+2` = 62 muestras (posición, yaw, pitch, velocidad horizontal, fase del paso) escrita solo por el Jugador, `pose_con_retardo(τ)` con τ clamped a [0, `T_hist`] sin leer fuera del búfer, rellenada con la pose inicial en `colocar`. | Core |
| TR-player-017 (provisional) | jugador-en-primera-persona.md | 2 Jugador | `giro_acumulado()` = suma de \|Δyaw\| por tick en ventana `T_giro` 0,5 s; `paso(superficie, intensidad)` es señal directa a Audio 23 (NO por el bus de 3, alta frecuencia) disparada cada `L_paso`, con etiqueta de superficie del suelo (`default` si falta). | Audio |
| TR-player-018 (provisional) | jugador-en-primera-persona.md | 2 Jugador | `colocar(posición, yaw, pitch)` síncrona en el mismo tick: velocidad 0, cancela cesión sin `camara_devuelta`, manos en reposo sin objeto, memoria de poses rellena, `giro_acumulado` 0; el Jugador no escribe ni lee hechos y no entra en el guardado (todo se reconstruye en `colocar`). | Scene |
| TR-player-019 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Red de seguridad contra atasco/caída: penetración >`eps_atasco_m` 0,02 con desplazamiento menor durante `t_atasco` 0,5 s, o `y` < `y_min` −2,0 m, devuelve a la última pose segura (`t_pose_segura` 0,25 s) o al ancla de aparición, con log; empujar un muro sin penetración no reubica. | Physics |
| TR-player-020 (provisional) | jugador-en-primera-persona.md | 2 Jugador | API pública cerrada y verificada por igualdad (AC): operaciones `colocar`, `ceder_camara`, `devolver_camara`, `rayo_vision`, `fov_actual`, `reproducir_gesto`, `sostener`, `soltar`, `girar_objeto`, `apuntar`, `reposo`, `pose_actual`, `pose_con_retardo`, `giro_acumulado`; nada que escriba la memoria de poses o el estado. | Core |
| TR-player-021 (provisional) | jugador-en-primera-persona.md | 2 Jugador | Todos los parámetros de feel/curva en `assets/data/player/player.json` (salvo `balanceo_camara` y `campo_vision` que viven en Ajustes 6); tests L con reloj inyectado en pasos enteros, entrada falsa y colisión falsa (gdUnit4, `tests/unit/player/`). | Data |

(21 filas; el GDD no define presupuesto de rendimiento: hueco.)

### Contratos

| Aspecto | Contenido (nombres exactos del GDD) |
|---|---|
| Emite | Señales: `paso(superficie, intensidad)` (directa a 23, no por bus); `gesto_terminado(id, motivo)` con `motivo` ∈ `completo`/`cancelado`/`tope`; `camara_cedida(propietario)`; `camara_devuelta(propietario)`; `objeto_sujeto(obj_id)`; `objeto_soltado(obj_id)` (sin destinatario fijo; filtran 7, 8, 20). No emite avisos del bus (3). |
| Consume | De 1 Entrada: `mover` (Vector2), `mirar` (Δyaw, Δpitch), aviso «contexto de entrada cambiado»; de 6 Ajustes: `balanceo_camara`, `campo_vision` y su aviso de cambio; de 4: `colocar`, anclas `spawn_office`/`spawn_elevator`, etiquetas de superficie, geometría; de 7, 8, 19, 20, 22: peticiones de gesto/objeto/cámara. |
| API pública | `colocar(posición, yaw, pitch)`; `ceder_camara(propietario, pose_destino, fov_destino, duración)`; `devolver_camara(propietario)`; `rayo_vision()`; `fov_actual()`; `reproducir_gesto(id, parámetros)`; `sostener(obj_id, mano = izquierda, pose_inspeccion = nulo)`; `soltar()`; `girar_objeto(Δyaw, Δpitch)`; `apuntar(punto_3d)`; `reposo()`; `pose_actual`; `pose_con_retardo(τ)`; `giro_acumulado()`. Gestos `HAND_*` (`HAND_IDLE`, `HAND_READ`, `HAND_HOLD_ITEM`, `HAND_TYPE`, `HAND_PHONE_HOLD`, `HAND_POINT`, `HAND_REACH`, `HAND_PLACE`, `HAND_DRAWER`, `HAND_CARD_SWIPE`, `HAND_TURN`, `HAND_PHONE_PUTDOWN`) e ids del slice `ANIM_PAGE_TURN`, `ANIM_PHONE_PICKUP`. |
| Estado/persistencia | Sin hechos ni guardado (regla 32). Estado volátil: estados Sin escena/Libre/Congelado/Cámara cedida, velocidad, yaw/pitch, distancia `d`, memoria de poses (62 muestras), `ω_f`, propietario de cámara, ranuras de manos, objeto sujeto, última pose segura. Fichero `assets/data/player/player.json`; claves en Ajustes (6): `balanceo_camara`, `campo_vision`. |
| Nodo/autoload propuesto | Una sola instancia (cuerpo cinemático + nodo de cabeza con yaw del cuerpo y pitch propio, cámara separable al ceder); si es persistente o por escena lo fija un ADR (según GDD 4); mecanismo de interpolación y dibujo de manos: ADR. No es autoload. |

## NO LEÍDO

- ajustes-persistentes.md: Overview, Edge Cases (181–215), Visual/Audio, Game Feel, UI Requirements, Cross-References, Open Questions, Decisiones tomadas, Historial.
- escena-de-planta.md: Overview, Edge Cases (171–209), Visual/Audio, Game Feel, UI Requirements, Cross-References, Decisiones tomadas (358–412), Open Questions (OQ 1, ADR de carga de escenas), Historial.
- jugador-en-primera-persona.md: Overview, Player Fantasy, Edge Cases (225–282; la red de seguridad se tomó de Tuning/AC), Visual/Audio (tabla de duraciones de gestos), Game Feel, UI, Cross-References, Decisiones tomadas (454–502), Open Questions, Historial.



---

<!-- bloque G3 -->
# TR baseline g3 (save, interact, puzzles)

## guardado-y-carga.md (sistema 5, slug `save`)

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-save-001 (provisional) | guardado-y-carga.md | 5 Guardado y carga | Una sola ranura: `autosave.json` en `user://saves/`; sin guardado manual ni selección de ranura (regla 1) | Save/Load |
| TR-save-002 (provisional) | guardado-y-carga.md | 5 | Formato de fichero en 3 partes: línea `v<N>` (constante de código, =1 en slice), línea `checksum` hex (64 car. con SHA-256†, algoritmo por ADR) y cuerpo JSON UTF-8 con claves `seq`, `saved_at_utc`, `build`, `cause`, `snapshot`, `completed` (opc.) | Save/Load |
| TR-save-003 (provisional) | guardado-y-carga.md | 5 | `checksum` se calcula y valida sobre los bytes exactos del cuerpo, sin re-serializar (F3); tolerar int devuelto como float (`17.0`) del parser JSON (pendiente verificar en editor) | Save/Load |
| TR-save-004 (provisional) | guardado-y-carga.md | 5 | Escritura atómica con respaldo de 1 generación: tmp -> releer/validar tmp -> validar principal -> borrar prev -> renombrar json->prev -> renombrar tmp->json; NUNCA renombra sobre fichero existente (no depende de sobrescritura del motor) | Save/Load |
| TR-save-005 (provisional) | guardado-y-carga.md | 5 | Cinco ficheros: `autosave.json`, `.prev.json`, `.tmp`, `.corrupt`, `.incompatible`; garantía total ante cierre de proceso, mejor esfuerzo ante corte de energía (AC-42 bloqueante, verificar Windows y Linux) | Save/Load |
| TR-save-006 (provisional) | guardado-y-carga.md | 5 | Toda E/S de guardado síncrona en el hilo principal en el slice (`quit` intenta una sola vez); mover a hilo obliga a revisar `quit` y regla 16 | Core |
| TR-save-007 (provisional) | guardado-y-carga.md | 5 | Una petición de guardado espera a cola de avisos del sistema 3 vacía antes de capturar la instantánea (nunca estado a medias) | Events |
| TR-save-008 (provisional) | guardado-y-carga.md | 5 | Fusión de peticiones en ventana `t_agrupar` (0,1 s, rango 0–1,0); causas urgentes (`call_started`, `slice_completed`, `quit`, `dev`) sin agrupación pero respetan `t_intento` salvo `quit` | Save/Load |
| TR-save-009 (provisional) | guardado-y-carga.md | 5 | Reintentos con backoff exponencial saturado: `t_reintento_base` 2 s, max 30 s, exponente saturado con k>30; "guardado en riesgo" a `n_fallos_aviso`=3; "guardado restablecido" al éxito | Save/Load |
| TR-save-010 (provisional) | guardado-y-carga.md | 5 | Reloj monotónico de tiempo real para `t` (no afectado por pausa ni escala de tiempo); `seq` entero creciente decide el más reciente, nunca el reloj del sistema | Core |
| TR-save-011 (provisional) | guardado-y-carga.md | 5 | Solo se escribe si `dif`: comparación del contenido canónico (JSON claves ordenadas, sin espacios, enteros normalizados, sin `seq`/`saved_at_utc`/`build`/`cause`) contra línea base `base_dif` | Save/Load |
| TR-save-012 (provisional) | guardado-y-carga.md | 5 | Causas de guardado (11 + `dev`): `door_opened:<ID>`, `compartment_done:<n>`, `call_started`, `card_acquired:<id>`, `slice_completed`, `notices_dropped`, `puzzle_solved:<ID>`, `reveal_pending`, `pause_opened`, `quit`, `periodic` (`t_periodico` 120 s, 0 o 30–600) | Events |
| TR-save-013 (provisional) | guardado-y-carga.md | 5 | Máquina de estados: Sin inspeccionar, Sin partida, Cargando partida, En partida (+subestado Sellando), Sellada; en Cargando y Sellada se ignoran causas (no se encolan) | Core |
| TR-save-014 (provisional) | guardado-y-carga.md | 5 | Sellado: al llegar `call_started` capturar instantánea en el primer instante con cola vacía (mismo fotograma lógico), reintentos escriben ese contenido capturado; Sellada solo admite `slice_completed` (reescribe con `completed`=true) | Save/Load |
| TR-save-015 (provisional) | guardado-y-carga.md | 5 | Estado persistido = solo el mapa de hechos del sistema 3 (20 hechos) + `snapshot_version`; NO persisten posición, temporizadores, pistas, puertas B/D abiertas, ajustes, ítems de sesión ni estado interno de puzles | Save/Load |
| TR-save-016 (provisional) | guardado-y-carga.md | 5 | Inspección de solo lectura (al arrancar y al llegar «descarga total completada»): valida y migra en memoria hasta 3 candidatos, elige válido de mayor `seq` (empate: json, tmp, prev); resultado `ninguna`/`valida`/`irrecuperable`/`version_futura` + indicadores `con_futura`, `terminada` | Save/Load |
| TR-save-017 (provisional) | guardado-y-carga.md | 5 | Validación en dos tiempos: antes de conocer versión solo tamaño ≤ `max_bytes_lectura` (65 536 B) y `v<N>`; versión mayor no se valida más; semántica de hechos la resuelve el sistema 3 | Save/Load |
| TR-save-018 (provisional) | guardado-y-carga.md | 5 | Migraciones `v->v+1` como funciones puras objeto->objeto en código (tabla vacía en slice), cada una con test propio, ejecutadas durante inspección; fallo trata candidato como dañado | Save/Load |
| TR-save-019 (provisional) | guardado-y-carga.md | 5 | Continuar: entregar instantánea migrada al sistema 3, esperar «estado restaurado», fijar base `dif` y `seq` = mayor válido+1, pedir `planta` (motivo `reanudar`, `control_final`=`exploracion`), pasar a En partida en «carga de escena terminada» | Scene |
| TR-save-020 (provisional) | guardado-y-carga.md | 5 | `nueva_partida()`: restablecer estado vía 3 («estado restablecido»), base `dif` = estado restablecido, pedir `planta` (`partida_nueva`, `control_final`=`ninguno`); no borra fichero existente; desde En partida descarta sin escribir | Core |
| TR-save-021 (provisional) | guardado-y-carga.md | 5 | Configuración en `assets/data/save/save-config.json` (`t_agrupar`, `t_periodico`, `t_reintento_base`, `t_reintento_max`, `n_fallos_aviso`, `max_bytes_lectura`, `causas_activas`); valor inválido -> error `CATALOGO_INVALIDO` con nombre del parámetro | Data |
| TR-save-022 (provisional) | guardado-y-carga.md | 5 | Herramientas dev (borrar partida, guardar ahora/`dev`) solo en builds de desarrollo; excluidas de la demo (verificado por comprobación de builds de entrega) | Tooling |

### Contratos (save)

| Aspecto | Contenido (nombres del GDD) |
|---|---|
| Emite | «guardado en riesgo», «guardado restablecido» (sin datos descritos; los consume 25 para indicador) |
| Consume | «puerta abierta» (datos: ID `A`/`B`/`D`), «compartimento completado» (1–4), «llamada iniciada», cambio de hecho `tarjeta_B`/`tarjeta_D`, «partida terminada» (4, único emisor), cualquier `EV_PUZZLE_SOLVED_*`, cambio de `pendiente_revelacion`, `pause_opened` (25), «avisos descartados» (3), «estado restaurado»/«estado restablecido» (3), «carga de escena terminada»/«carga de escena fallida» (destino, `motivo`, causa) y «descarga total completada» (4), petición «salir al título» (25/27) |
| API pública | `continuar()`, `nueva_partida()` (rechazada en carga, Sellando y Sellada); consulta del resultado de la última inspección (`ninguna`/`valida`/`irrecuperable`/`version_futura` + `con_futura`, `terminada`); petición de guardado `quit`/`dev` (sin firma en GDD) |
| Pide a otros | 3: instantánea, restaurar, restablecer; 4: carga de `planta` con motivo (`reanudar`/`partida_nueva`) y `control_final` |
| Estado que posee/persiste | `autosave.json` (+ `.prev.json`, `.tmp`, `.corrupt`, `.incompatible`) en `user://saves/`; claves `seq`, `saved_at_utc`, `build`, `cause`, `snapshot`, `completed`; estado de sesión: base `dif`, `t_ref`, `k`, `t_intento`, contenido capturado; Sellada derivada del hecho `llamada_iniciada` |
| Nodo/autoload | El GDD NO propone nodo/autoload (ruta y E/S definitivas por ADR, Open Questions 1) |

Huecos save: no definido presupuesto de rendimiento (OQ 6); sin firma de API ni nodo; ADR pendiente para hash, ruta, rename seguro; AC (líneas 395–497) y Edge Cases no leídos.


## interaccion-e-inspeccion.md (sistema 7, slug `interact`)

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-interact-001 (provisional) | interaccion-e-inspeccion.md | 7 Interacción e inspección | Catálogo de interactuables en datos `assets/data/interaction/interactables.json` validado contra `interactables.schema.json` en carga y CI; campo desconocido = error de datos; prohibidos campos de duración de bloqueo y `requiere_ítem` (reglas 2, 31) | Data |
| TR-interact-002 (provisional) | interaccion-e-inspeccion.md | 7 | Barrido de foco en cada paso de física (60 Hz) solo en contexto `exploración`, con `rayo_vision()` del Jugador (ojos sin balanceo, estado de física sin interpolar) (regla 5, F1) | Physics |
| TR-interact-003 (provisional) | interaccion-e-inspeccion.md | 7 | F1 exige recoger TODOS los contactos de una esfera `radio_apuntado_m` 0,06 m (consulta de forma o `ShapeCast3D` con Jolt); no cubierto por engine-reference; el respaldo de 7 rayos `intersect_ray` no cumple F1; ADR V1 bloquea AC-05 y la historia de detección | Physics |
| TR-interact-004 (provisional) | interaccion-e-inspeccion.md | 7 | Máscaras de colisión separadas `mascara_interactuable` y `mascara_geometria`; cuerpo del Jugador en capa propia excluida; oclusión con tolerancia `desempate_prof_m` 0,03 m | Physics |
| TR-interact-005 (provisional) | interaccion-e-inspeccion.md | 7 | Retención de foco medida en pasos de física: `t_gracia_foco_s` 0,12 s = 7 pasos a 60 Hz, `radio_pegajoso_m` 0,15 m; un candidato nuevo válido sustituye siempre | Physics |
| TR-interact-006 (provisional) | interaccion-e-inspeccion.md | 7 | `can_interact(verbo)` pura y barata: se llama por paso de física solo para candidatos que pasan `habilitado_si` y para el objetivo retenido; `habilitado_si` por lectura directa de hechos del 3, sin suscripción | Core |
| TR-interact-007 (provisional) | interaccion-e-inspeccion.md | 7 | Contrato de manejador por ID (`registrar_manejador`): `can_interact`->{SI,NO,SIN_EFECTO}, `etiqueta(verbo)->clave\|nulo`, `interact(verbo, contexto)`->{HECHO,SIN_EFECTO}; registro antes de «escena lista» dentro de la retención de arranque de 4; ID repetido o ausente = error en desarrollo | Core |
| TR-interact-008 (provisional) | interaccion-e-inspeccion.md | 7 | Orden al pulsar: 7 reserva el gesto del Jugador (`gesto_hecho` o `HAND_REACH`) ANTES de `interact()`; si el Jugador rechaza, no se llama a `interact()` | Core |
| TR-interact-009 (provisional) | interaccion-e-inspeccion.md | 7 | Bloqueo de contexto por transición de Entrada hasta `gesto_terminado(id, motivo)`; tope único 3 s de tiempo de juego (la pausa lo detiene); `bloquear_contexto(razon)->token\|nulo` solo dentro de `interact()` o con token vigente; `liberar_contexto` idempotente | Input |
| TR-interact-010 (provisional) | interaccion-e-inspeccion.md | 7 | Pulsación: corta se decide al soltar si hay `verbo_largo`; `t_hold` 0,5 s de Entrada; anillo a `t_anillo_inicio_s` 0,12 s; `t_enfriamiento_s` 0,25 s; F2 `p=clamp((t-t_pulsado)/t_hold,0,1)` con tiempo de juego | Input |
| TR-interact-011 (provisional) | interaccion-e-inspeccion.md | 7 | Respuesta audible/visible a toda pulsación procesada ≤ `latencia_feedback_ms` 100 ms (50–200) | Audio |
| TR-interact-012 (provisional) | interaccion-e-inspeccion.md | 7 | Pila de modos (`exploración`, `inspección`, `lectura`, `vista cercana`, `ordenador`); `atrás` cierra solo el superior; `cerrar_modos()` cierra todos y emite una vez «modos cerrados»; la descarga de escena entrega `cancelación`/`on_close(sistema)` síncronos sin avisos al bus | Core |
| TR-interact-013 (provisional) | interaccion-e-inspeccion.md | 7 | Vista cercana: cámara cedida al Jugador vía `ceder_camara(propietario "interaccion:vista", pose, fov_destino, duración)`/`devolver_camara` con señales `camara_cedida`/`camara_devuelta`; red de seguridad 3 s; `t_devolver` 0,5 s y curva smoothstep del Jugador | Rendering |
| TR-interact-014 (provisional) | interaccion-e-inspeccion.md | 7 | Cadena de apertura D01a–D01c con un solo bloqueo transferido por token (`abrir_vista(id, desde_token)`); `BOX_Cn_OPEN` ≤ `BOX_OPEN_MAX` 1,6 s + `t_vista_entrada_s` ≤ 1,2 s => T_cadena ≤ 2,8 s < tope único 3 s de Entrada | Core |
| TR-interact-015 (provisional) | interaccion-e-inspeccion.md | 7 | Picking 2D aritmético contra formas de `ViewReceiver.elements()` (rect/círculo/polígono en metros locales, `z_orden`, `atraccion`), sin colliders 3D; conversión F6 `ppm=(H_px/2)/(d·tan(FOV_v/2))` con viewport lógico 1920x1080 | Input |
| TR-interact-016 (provisional) | interaccion-e-inspeccion.md | 7 | `PointerEvent = {gesto, fase, elemento, elemento_bajo, pos_px, pos_vista, delta_px, delta_grados}`; fases inicio/actualización/fin/cancelación; elemento fijado al pulsar y capturado; `seleccionar` emite un único evento al soltar; `actualización` no cuenta como actividad (el filtro es del receptor) | Input |
| TR-interact-017 (provisional) | interaccion-e-inspeccion.md | 7 | `gestos_aceptados` por elemento ⊆ {seleccionar, agarrar, rotar, mantener}; relectura en el siguiente fotograma tras `elements_changed`; un gesto en curso no cambia de elegibilidad | Input |
| TR-interact-018 (provisional) | interaccion-e-inspeccion.md | 7 | Elementos señalables ≥ `pick_min_px` 44 px de lado (hit-test ampliado) y separación ≥ R1+R2 con R=min(max(64 px, tol),128 px); `atraccion_desactivada` por vista/zona en `puzzles.json`; validado al arrancar (advertencia; fallo si tolerancia normal 88 px da separación <176 px) | Data |
| TR-interact-019 (provisional) | interaccion-e-inspeccion.md | 7 | Inspección: objeto `sostenible:true` (solo V05) con radio ≤ `r_max_inspeccion_m` 0,20 m; `d_ins=clamp(r/tan(θ_fill/2),0,25–0,60 m)`, giro libre por cuaternión; objeto a ≥0,15 m de cámara (near 0,05 m); secuencia `HAND_REACH` -> `sostener` -> `HAND_HOLD_ITEM` | Animation |
| TR-interact-020 (provisional) | interaccion-e-inspeccion.md | 7 | `abrir_lectura(doc_id)->{ACEPTADA,APLAZADA,RECHAZADA(motivo)}` según tabla de estado; una única petición aplazada con tope 3 s de tiempo de juego; `cerrar_vista(resuelto)` se aplaza si hay lectura encima | Core |
| TR-interact-021 (provisional) | interaccion-e-inspeccion.md | 7 | Sin estado propio ni persistencia: al cargar escena objetivo vacío y ningún modo abierto; el estado de objetos lo reconstruyen los dueños desde hechos | Save/Load |
| TR-interact-022 (provisional) | interaccion-e-inspeccion.md | 7 | El objetivo no viaja por el bus: 24 consulta `get_target()` cada fotograma; pie vía `mostrar_pie(clave, duracion_pie(clave), retener)`; F5 `t_pie=clamp(0,5+n/14,2,8)·multiplicador_pie`, `texto_max_caracteres` 90 | UI |

### Contratos (interact)

| Aspecto | Contenido (nombres del GDD) |
|---|---|
| Emite (bus) | «vista cercana abierta» (ID vista); «vista cercana cerrada» (ID, motivo `jugador`/`resuelto`/`sistema`); «lectura abierta» (ID doc, solo si aplazada); «lectura descartada» (ID doc, motivo); «lectura completada» (ID doc); «lectura cerrada» (ID doc, motivo); «modos cerrados» (lista); «interacción ejecutada» (ID objeto, verbo, `resultado` ∈ HECHO/SIN_EFECTO/GESTO_RECHAZADO/TOQUE_CORTO). Sin aviso de cambio de objetivo ni de pérdida de foco |
| Consume | De 1: acciones `interactuar`, `leer`, `rotar_objeto`, `atrás`, gestos de puntero; de 2: `gesto_terminado(id, motivo)`, `camara_cedida`/`camara_devuelta(propietario)`, `objeto_sujeto(id)`, `objeto_soltado(id)`; de 4: «escena lista»; de 6: aviso de cambio de `multiplicador_pie`/`pie_persistente`; lectura de hechos del 3 (`habilitado_si`); `elements_changed` del receptor |
| API pública | `registrar_manejador(id, manejador)`; `registrar_receptor(vista_id, receptor)`; `abrir_vista(vista_id, desde_token = nulo) -> {ACEPTADA, RECHAZADA(motivo)}`; `bloquear_contexto(razon) -> token \| nulo`; `liberar_contexto(token)`; `cerrar_vista(vista_id, motivo)`; `abrir_lectura(doc_id) -> {ACEPTADA, APLAZADA, RECHAZADA(motivo)}`; `cerrar_lectura(motivo)`; `cerrar_modos()`; `get_target() -> {id, etiqueta, ¿largo?, p, anillo_visible} \| nulo`; `duracion_pie(clave) -> float \| PERSISTENTE`; `modo_actual() -> {NINGUNO, INSPECCION, LECTURA, VISTA, ORDENADOR}` y la pila. Interfaz `ViewReceiver`: `elements() -> Array[ViewElement]` ({id, forma, z_orden, atraccion}), `handle_pointer(ev: PointerEvent)`, `on_open()`, `on_close(motivo)`. Manejador: `can_interact`, `etiqueta`, `interact`. Llama al Jugador: `rayo_vision()`, `fov_actual()`, `ceder_camara`, `devolver_camara`, `reproducir_gesto`, `sostener(id, izquierda, pose_inspeccion)`, `soltar()`, `girar_objeto(Δyaw, Δpitch)`, `apuntar`, `reposo()`; a 24: `mostrar_pie`, `ocultar_pie` |
| Estado que posee/persiste | Nada persistido. Sesión: objetivo, retención de foco, pila de modos, petición de lectura aplazada, tokens de bloqueo. Ficheros de datos: `assets/data/interaction/interactables.json` + `interactables.schema.json` |
| Nodo/autoload | No propuesto por el GDD; depende de «escena lista» de 4 y de contenedores localizados por ID |

Huecos interact: sin presupuesto de CPU del barrido (solo 60 Hz); ADR V1 pendiente (forma Jolt); eje FOV y H_px en 16:10 pendientes (Open Questions V4); sin nodo/autoload; Edge Cases y AC (518–609) y tabla de objetos (186–269) no leídos.

## marco-de-puzles.md (sistema 9, slug `puzzles`)

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-puzzles-001 (provisional) | marco-de-puzles.md | 9 Marco de puzles | Un puzle = entrada en `assets/data/puzzles/puzzles.json` (raíz `{ "schema_version": 2, "puzzles": [...] }`, otra versión = fallo de validación) + subclase de `PuzzleController`; todo valor numérico vive en datos, nunca en el controlador (reglas 3, 4b, 5) | Data |
| TR-puzzles-002 (provisional) | marco-de-puzles.md | 9 | Esquema de definición: `id` (P1–P6), `solved_flag`, `mode` (`VIEW`/`WORLD`), `view`/`elements`, `requires.all`, `needs_items`, `validation`, `solution`, `on_reject`, `on_partial`, `on_change`, `locked_feedback`, `element_zones`, `idle_reset`, `idle_move_px`, `on_unlock`, `on_solved` (`write[]`, `compartment`, `rewards`, `close_view_after_s`, `presentation`, `request_reading`), `on_reopen`, `resolution`, `persist`, `hints`, `assist` (regla 4) | Data |
| TR-puzzles-003 (provisional) | marco-de-puzles.md | 9 | `on_solved.write[]` admite `{flag,value}` XOR `{flag,value_from,map?}`; `value_from` toma una clave de la carga útil del veredicto `SOLVED` (`choice` P6, `t4_action` P4) y `map` traduce a un valor válido del enum del hecho en `flags.json` (regla 4b-a) | Data |
| TR-puzzles-004 (provisional) | marco-de-puzles.md | 9 | Catálogos cerrados validados: `commit_on` (`SELECT_END_SAME_ELEMENT`/`SELECT_START`), `idle_reset` (`GESTURE`/`GESTURE_AND_MOVE`/`PRESS_ONLY`), `AFFORDANCE.affordance` (`MIRROR_PREVIEW`, `FLOOR_MARKS`, `BEAM_HALO`, `SLOT_SILHOUETTES`, `ROW_NUMBER_ON_HOLD`, `CORRECT_SLOT_OUTLINE`, `HOVER_HIGHLIGHT`, `MARK_LIT`), `presentation[].call` (solo `play_open(n)`), `resolution.steps[].kind` (`OVERLAY_FADE`,`OUTLINE`,`LINE`,`WAIT`) | Data |
| TR-puzzles-005 (provisional) | marco-de-puzles.md | 9 | Validación de datos al arrancar (regla 29), tras cargar catálogos de 7 y claves de 18 y antes de configurar puzles/registrar receptores: unicidad, `requires.all` sin ciclos y con escritor, `on_reject`≤`lock_max_s` 2,0 s, 3 pistas (2 en P6), estado inicial no satisface la solución, separación de elementos con tolerancia asistida (R=128 px, 256 px); fallo en build final = fallo de carga de 4 (nunca puzle inactivo); en CI como puerta de empaquetado (AC-47) | Tooling |
| TR-puzzles-006 (provisional) | marco-de-puzles.md | 9 | Tipos: el cargador convierte explícitamente a `int` los campos enteros (`sequence`, `pos_*`, `level`) y los comprueba (parser JSON devuelve float; Open Questions 4) | Data |
| TR-puzzles-007 (provisional) | marco-de-puzles.md | 9 | Tres estados públicos `BLOQUEADO`→`ACTIVO`→`RESUELTO`, monótonos, sin método de retroceso (salvo consola dev, regla 31); fases internas `IDLE`/`EVALUATING`/`FEEDBACK`/`RESOLVING` no publicadas; `SOLVED` idempotente (el segundo en el mismo fotograma se descarta) | Core |
| TR-puzzles-008 (provisional) | marco-de-puzles.md | 9 | `PuzzleController` clase abstracta (`@abstract`, Godot ≥4.5) con `configure(def, flags)`, `on_open()`, `on_close(motivo)`, `elements()`, `handle_pointer(ev)`, `handle_activation(element_id, verb)`, `cancel_gesture()`, `evaluate()->Verdict`, `reset_attempt(scope, element)`, `play_resolution(step)`, `restore_solved_presentation()`, `apply_hint_effect(effect)->bool` | Core |
| TR-puzzles-009 (provisional) | marco-de-puzles.md | 9 | El controlador nunca escribe hechos ni emite avisos ni recibe referencia de escritura; `evaluate()` es función pura sin tiempo ni acumulador; `Verdict` ∈ {`NONE`,`HOLDING`,`PARTIAL`(progress),`REJECT`,`SOLVED`(carga)}; el `PuzzleFramework` es único escritor de `archivo_abierto`, `memo_leido`, `pos_L/C/R`, `caja_c1..c4`, `pendiente_revelacion`, `carta_variante`, `t4_decision` | Core |
| TR-puzzles-010 (provisional) | marco-de-puzles.md | 9 | Cinco políticas de comprobación: `DELAYED_AFTER_CHANGE` (0,6 s), `ON_CHANGE` (+reevaluación única tras «escena lista»), `PER_ELEMENT`, `SUSTAINED` (`evaluate()` cada fotograma, acumulador del marco `min(dt,dt_max=0,1)`, `hold_s` 0,8 s), `ON_CHOICE`; todo cambio de estado (pista, restauración, `reset_attempt`) pasa por `evaluate()` (regla 12b) | Core |
| TR-puzzles-011 (provisional) | marco-de-puzles.md | 9 | Orden de escritura al resolver en el mismo fotograma: hechos de `on_solved.write` en orden declarado -> `solved_flag` -> estado `RESUELTO` -> `EV_PUZZLE_SOLVED_<ID>` {puzzle, rewards, choice} -> «compartimento completado» (n) -> feedback/presentación (no bloqueante) -> `cerrar_vista(resuelto)` tras `close_view_after_s` | Events |
| TR-puzzles-012 (provisional) | marco-de-puzles.md | 9 | Resolución `DEFERRED` (P5, 16,0 s nominales): escribe `pendiente_revelacion`=true al iniciar; al acabar escribe `caja_c3`, luego limpia `pendiente_revelacion`; interrumpible solo por salida de la vista, emite «resolución de puzle interrumpida»; reanuda desde el principio | Core |
| TR-puzzles-013 (provisional) | marco-de-puzles.md | 9 | Pasos `LINE`: duración = `fallback_s` 14,0 s si «línea sin audio»/«línea fallida», termina en «línea terminada» sin pasar de `fallback_s + line_grace_s` (2,0 s) si no hay señal; el audio nunca bloquea; señales de 23 durante pausa se retienen | Audio |
| TR-puzzles-014 (provisional) | marco-de-puzles.md | 9 | `GameClock` inyectable que avanza solo con tiempo de juego para todo temporizador del marco (F1, F2, F3, F8, locks, `close_view_after_s`, `line_grace_s`); prohibido `SceneTreeTimer`/`create_timer`; pausa detiene por construcción; comportamiento de `Tween`/audio con `SceneTree.paused` pendiente en editor 4.7 | Core |
| TR-puzzles-015 (provisional) | marco-de-puzles.md | 9 | Configuración síncrona al cargar la escena (regla 9.6 de 4): por puzle, resolver `RESUELTO` si `solved_flag` (restaurar presentación sin avisos), `ACTIVO`/`BLOQUEADO` según `requires.all`, restaurar `persist`; luego emitir una vez «puzles configurados» antes de «escena lista»; limpiar `pendiente_revelacion` en puzle resuelto con escritura silenciosa del 3 | Scene |
| TR-puzzles-016 (provisional) | marco-de-puzles.md | 9 | Estado persistido solo como hechos de `flags.json`: `solved_flag` por puzle, `pos_L/C/R` (escritos en cada cambio del P2), `pendiente_revelacion`, `carta_variante`, `t4_decision`; sin hechos nuevos; el progreso parcial y `hint_level_reached` solo en memoria | Save/Load |
| TR-puzzles-017 (provisional) | marco-de-puzles.md | 9 | Registro como `ViewReceiver` de cada vista de puzle y como manejador de `B01`–`B03` (`registrar_receptor`, `registrar_manejador`) antes de «escena lista»; `get_view_gate(view_id) -> {state: OPEN/BLOCKED/SOLVED, missing_items, feedback_sfx, feedback_text_key}` consultado por el dueño antes de `abrir_vista`; `missing_items` por `has_item` en `on_open` | Core |
| TR-puzzles-018 (provisional) | marco-de-puzles.md | 9 | Política única de fallo: `REJECT` -> feedback, `reset_attempt` tras `reset_after_s`, `lock` (`PUZZLE`/`ELEMENT`/`NONE`) ≤ `lock_max_s` 2,0 s; eventos durante el bloqueo se descartan (no se encolan); `cancelación` nunca produce `REJECT` ni evalúa | Input |
| TR-puzzles-019 (provisional) | marco-de-puzles.md | 9 | API de pistas para 17: `list_puzzles()`, `get_hints(id)`, `request_hint(id, level)` (ignorada en `RESOLVING`), notificación «puzle inactivo» al cruzar `idle_s`; `idle_hints_auto_apply` en datos; inactividad F3 medida solo con `inicio`/`fin`/`cancelación` (no `actualización`) | Events |
| TR-puzzles-020 (provisional) | marco-de-puzles.md | 9 | Avisos del marco con nombre y carga: `EV_PUZZLE_SOLVED_<ID>` {puzzle, rewards, choice}, «compartimento completado» (n), «puzle activado» {puzzle, ajar_cm?}, «feedback de puzle» {puzzle, sound_id, text_key?, element?}, «línea pedida» {puzzle, line_id, fallback_s}, «pista aplicada», «resolución de puzle interrumpida», «puzles configurados» | Events |
| TR-puzzles-021 (provisional) | marco-de-puzles.md | 9 | Resolubilidad (S7): prueba automática con oráculo independiente: `N_fuzz` 1.000 secuencias por puzle (incluye pistas, cancelaciones, cierre/reapertura, guardar/cargar), solucionador de referencia por la tubería real (`handle_pointer`->`evaluate()`->marco) sobre copia de estado | Tooling |
| TR-puzzles-022 (provisional) | marco-de-puzles.md | 9 | Registro de playtest local (solo builds dev/playtest, ausente en demo): tiempo a resolver, intentos, rechazos, pistas pedidas/ignoradas, cierres; accesibilidad: lee `reducir_movimiento`, `asistencia_encaje` (0,10 m), `asistencia_rotacion` (±6°) al configurar y al cambiar; afecta al siguiente rechazo/paso | Accessibility |

### Contratos (puzzles)

| Aspecto | Contenido (nombres del GDD) |
|---|---|
| Emite | `EV_PUZZLE_SOLVED_P1`–`P6` {puzzle, rewards, choice (solo P6)}; «compartimento completado» (1–4); «puzle activado» {puzzle, ajar_cm?}; «resolución de puzle interrumpida»; «pista aplicada» (ID, nivel); «puzle inactivo» (al cruzar `idle_s`); «puzles configurados» (sin datos, una vez por carga/Nueva partida); «feedback de puzle» {puzzle, sound_id, text_key?, element?}; «línea pedida» {puzzle, line_id, fallback_s}. NO existe `puzzle_solved {id}`. Emite `elements_changed(tag?)` el controlador |
| Consume | De 7: `PointerEvent` (fases inicio/actualización/fin/cancelación), avisos «vista cercana abierta/cerrada», activaciones `Girar` (B01–B03); de 3: cambios de hechos de `requires.all`; de 4: secuencia de configuración y «escena lista»; de 23: «línea terminada», «línea sin audio», «línea fallida» {line_id}; de 6: `asistencia_encaje`, `asistencia_rotacion`, `reducir_movimiento`; de 20: `has_item(id)`; de 19: `compose_i01()` |
| API pública | `PuzzleFramework`: `get_view_gate(view_id) -> { state, missing_items, feedback_sfx, feedback_text_key }`; `list_puzzles()`; `get_hints(id)`; `request_hint(id, level) -> bool`; interfaz `ViewReceiver` (`elements()`, `handle_pointer(ev)`, `on_open()`, `on_close(motivo)`) y manejador (`can_interact`, `interact`) hacia 7. `PuzzleController` (abstracta): ver TR-puzzles-008. Llama a otros: `registrar_receptor`, `registrar_manejador`, `cerrar_vista(view_id, motivo)`, `abrir_lectura(doc_id)` (7); `play_open(n)`, `set_final_pose(n)` (10); `has_item(id)` (20); `compose_i01()` (19); escritura silenciosa del 3 |
| Estado que posee/persiste | Hechos con `owner = 9`: `archivo_abierto`, `memo_leido`, `pos_L`, `pos_C`, `pos_R`, `caja_c1`–`caja_c4`, `pendiente_revelacion`, `carta_variante`, `t4_decision`; (`caja_completa` lo deriva el 3). En memoria: estado público de cada puzle, `hint_level_reached`, `progress` previo, acumulador `acum`; fichero `assets/data/puzzles/puzzles.json` |
| Nodo/autoload | `PuzzleFramework` (lógica con diccionario `id -> controlador`; despacha por `mode`) y `GameClock` inyectable; el GDD no fija nodo/autoload concreto |

Huecos puzzles: leído solo Detailed Rules (30–338), Dependencies y Tuning Knobs; las secciones Formulas (340–447; F1 retraso, F2 acumulador, F3 inactividad, F8 duración 16,0 s, F9 llamada) y Acceptance Criteria (637–738) NO leídas; ejemplos JSON de P1–P4 (líneas 89–132) no leídos; no hay nodo/autoload ni presupuesto de CPU/memoria; `has_item`, `get_view_gate` y `compose_i01` están marcados ‡ (por confirmar por 20/10/19); Open Questions 4 (tipos int y pausa de Tween) abiertas.

## NO LEÍDO

- guardado-y-carga.md: Edge Cases (246–311), Visual/Audio, Game Feel, UI Requirements (355–377), Cross-References, Acceptance Criteria (395–497), Open Questions, Decisiones tomadas, Propuesta de registro.
- interaccion-e-inspeccion.md: tabla de objetos y ejemplos JSON (líneas 186–269), Formulas parte F7+ (352 en adelante parcial), Edge Cases (352–410), Visual/Audio/Game Feel/UI, Acceptance Criteria (518–609), Decisiones, Open Questions.
- marco-de-puzles.md: ejemplos P1–P4 (89–132), Formulas (340–447), Edge Cases (448–503), Visual/Audio/Game Feel/UI (585–613), Cross-References, Acceptance Criteria (637–738), Decisiones, Open Questions, Propuesta de registro.

---

<!-- bloque G4 -->
# Baseline TR — lote g4 (access, box, pocket)

## control-de-acceso.md (sistema 8, slug `access`)

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-access-001 (provisional) | control-de-acceso.md | 8 | Todos los valores (tiempos, ángulos, LED, claves, IDs) viven en `assets/data/access/access.json` con esquema `doors[]`/`readers[]`/`drawers[]`/`elevator`, validado en carga y en CI | Data |
| TR-access-002 (provisional) | control-de-acceso.md | 8 | El mapa lector→hecho/tarjeta es fijo (`C06`→`tarjeta_B`/`I-02`; `C07` y `D06`→`tarjeta_D`/`I-03`) y el CI lo valida; ID repetido, ancla/hecho inexistente = dato inválido | Data |
| TR-access-003 (provisional) | control-de-acceso.md | 8 | Datos inválidos: en desarrollo error que detiene la ejecución; en build final falla abierto (puerta `ABIERTA`, lector `LISTO`, `A05` `CERRADO`, ascensor con defaults 2,0/8/20,0 s) con una línea de log, y el CI marca la build rota | Core |
| TR-access-004 (provisional) | control-de-acceso.md | 8 | Estados de puerta (`CERRADA`,`LEYENDO`,`ABRIÉNDOSE`,`ABIERTA`), lector, ascensor y cajón son derivados de hechos + temporizadores; 8 no persiste nada ni escribe ningún hecho | Save/Load |
| TR-access-005 (provisional) | control-de-acceso.md | 8 | Configuración al arrancar síncrona en el mismo fotograma, en el paso 6 del arranque de 4 (tras 7 y 9, con hechos ya definitivos), sin emitir «puerta abierta»; A nace según `archivo_abierto`, B/D siempre `CERRADA` | Scene |
| TR-access-006 (provisional) | control-de-acceso.md | 8 | `can_interact` de lectores/ascensor/cajón es puro y barato (lectura directa de hechos en el paso de física); `interact` revalida el estado | Core |
| TR-access-007 (provisional) | control-de-acceso.md | 8 | Aviso «puerta abierta» (A/B/D) se emite una sola vez por apertura, en el primer paso de `ABRIÉNDOSE`; es idempotente ante avisos duplicados | Events |
| TR-access-008 (provisional) | control-de-acceso.md | 8 | La colisión de la hoja se desactiva en el primer paso de `ABRIÉNDOSE`; las puertas nunca se cierran; hueco 1,00 × 2,10 m | Physics |
| TR-access-009 (provisional) | control-de-acceso.md | 8 | Hoja animada con `ANIM_DOOR_OPEN` 1,2 s, θ(t)=90°·(3x²−2x³), x=clamp(t/1,2) | Animation |
| TR-access-010 (provisional) | control-de-acceso.md | 8 | `interact(Usar)` de lector: `bloquear_contexto("tarjeta")` solo dentro de `interact()` (nulo → `SIN_EFECTO`); cuenta `t_lectura_s` 0,5 s; la apertura no depende del gesto ni de 20 | Input |
| TR-access-011 (provisional) | control-de-acceso.md | 8 | Gesto de tarjeta orquestado en paralelo: `sostener_item` → `objeto_sujeto` (tope 0,6 s) → `reproducir_gesto(HAND_CARD_SWIPE)` ≤1,0 s → `gesto_terminado` → `guardar_item` → `liberar_contexto`; secuencia ≈1,6 s bajo el tope de 3 s de 7; `HAND_HOLD_ITEM` y `HAND_CARD_SWIPE` nunca coexisten | Animation |
| TR-access-012 (provisional) | control-de-acceso.md | 8 | Todos los temporizadores (8 en total) son de tiempo de juego y se detienen con la pausa | Core |
| TR-access-013 (provisional) | control-de-acceso.md | 8 | Ascensor: estados evaluados por prioridad `EN_USO`>`LISTO`>`ESPERA`>`EN_APAGON`>`INACTIVO`; `LISTO` tras `t_ascensor_s` 2,0 s de `llamada_completada` (inmediato si ya verdadero) | Core |
| TR-access-014 (provisional) | control-de-acceso.md | 8 | `EN_USO` siempre sale: «ascensor rechazado» o `t_en_uso_tope_s` 20,0 s (> traspaso de 21 de 12,0 s) | Events |
| TR-access-015 (provisional) | control-de-acceso.md | 8 | Enfriamiento único de `MEGA_03` de 8 s (≥ duración+2 s) con reloj de juego; «línea pedida» solo en `INACTIVO` | Audio |
| TR-access-016 (provisional) | control-de-acceso.md | 8 | Cajón `A05`: tras `gesto_terminado(HAND_DRAWER, cualquier motivo)` o `t_cajon_tope_s` 3,0 s llama una sola vez a `otorgar("A05")` (idempotente); nace `ABIERTO` solo si ambas tarjetas son verdaderas | Save/Load |
| TR-access-017 (provisional) | control-de-acceso.md | 8 | LED de lector con 3 presentaciones distinguibles sin color (reposo 30 %, leyendo 30–80 % a 2 Hz, abierto 100 %; ≥30 puntos de diferencia); `SIN_TARJETA` y `LISTO` comparten presentación | Accessibility |
| TR-access-018 (provisional) | control-de-acceso.md | 8 | Invariantes no-softlock: ninguna puerta cerrada con condición cumplida sin forma de activarla; tarjetas no se gastan; rechazo/cancelación del gesto nunca bloquea apertura ni entrega | Core |

### Contratos — access

| Campo | Contenido |
|---|---|
| Emite | «puerta abierta» (`A`/`B`/`D`; causa `door_opened:<ID>` en 5); «ascensor llamado» (sin datos; consume 21); «línea pedida» (`MEGA_03`; consume 23) |
| Consume | Cambio del hecho `archivo_abierto`; «ascensor rechazado» (sin datos, de 21); `gesto_terminado(id, motivo)` y `objeto_sujeto(id)` del Jugador (2), filtrados por el `id` pedido. Lectura directa de `tarjeta_B`, `tarjeta_D`, `caja_completa`, `llamada_completada` |
| API pública | Manejadores `can_interact`/`interact`/`etiqueta` de `C06`, `C07`, `D06`, `C08`, `A05` (verbos «Usar», «Entrar», «Abrir»; retornos `SI`/`NO`/`SIN_EFECTO`, `HECHO`). Llama a: `bloquear_contexto("tarjeta")`/`liberar_contexto` (7), `sostener_item(id)`→`ACEPTADA`/`RECHAZADA`, `guardar_item()`, `otorgar("A05")` (20), `reproducir_gesto(HAND_CARD_SWIPE)` (2) |
| Estado que posee/persiste | Posee: hoja/marco de A, B, D, lectores, cajón `A05`, ascensor `C08` (estados derivados). Persiste: nada; no escribe hechos |
| Nodo/autoload propuesto | Nodo de escena de planta (hijo de la escena de planta de 4, colocado en `door_slot_a/b/d/elevator`), cargado con `access.json`; sin autoload |


## caja-y-compartimentos.md (sistema 10, slug `box`)

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-box-001 (provisional) | caja-y-compartimentos.md | 10 | La caja no decide disponibilidad: toda consulta pasa por `get_view_gate(view_id)` de 9 (`OPEN`/`BLOCKED`/`SOLVED`); `caja_c1`–`caja_c4` se leen solo para reconstruir pose | Core |
| TR-box-002 (provisional) | caja-y-compartimentos.md | 10 | La pose de cada compartimento (`CERRADO`,`ENTREABIERTO`,`ABRIENDO`,`ABIERTO`,`CERRANDO`,`FINAL_CERRADO`,`FINAL_ABIERTO`) es estado de presentación en memoria, nunca guardado ni expuesto como hecho; transiciones inválidas se registran | Scene |
| TR-box-003 (provisional) | caja-y-compartimentos.md | 10 | Configuración síncrona al arrancar `planta`, después de 9 (orden 7→9→resto), reconstruyendo pose sin animar, sin sonido y sin emitir nada; si 9 falla validación, la caja no se configura | Scene |
| TR-box-004 (provisional) | caja-y-compartimentos.md | 10 | `can_interact` devuelve solo `SI` o `SIN_EFECTO`, nunca `NO`; `SIN_EFECTO` no mueve tapa, no abre vista ni pide bloqueo | Core |
| TR-box-005 (provisional) | caja-y-compartimentos.md | 10 | `interact()` C1–C3: dentro de `interact()` pide `bloquear_contexto("D01x")` (nulo → `SIN_EFECTO` + log), anima `BOX_Cn_OPEN` y al terminar reconsulta el gate y llama `abrir_vista(id, desde_token)` transfiriendo el bloqueo sin fotograma en `exploración` | Input |
| TR-box-006 (provisional) | caja-y-compartimentos.md | 10 | La caja detecta fin de animación por señal (no temporizador de fotograma); vigilantes: token de 3 s (apertura), `BOX_Cn_CLOSE`+1,0 s y `BOX_C4_OPEN`+1,0 s fuerzan la pose final sin animar y registran error | Animation |
| TR-box-007 (provisional) | caja-y-compartimentos.md | 10 | Cadena de apertura T_cadena = BOX_Cn_OPEN + min(t_vista_entrada_s, t_transicion_max) ≤ 2,8 s peor caso con margen ≥ 0,2 s sobre el tope de 3 s; `BOX_Cn_OPEN` ≤ 1,6 s validado en datos | Data |
| TR-box-008 (provisional) | caja-y-compartimentos.md | 10 | Configuración en `assets/data/box/box.json` (BOX_C1..C4_OPEN, BOX_Cn_CLOSE, close_delay_s, ajar_s, ajar_visible_dist_m, margen_min, flags) con validación; fuera de rango = error en desarrollo, recorte a 1,6 s y aviso en la demo | Data |
| TR-box-009 (provisional) | caja-y-compartimentos.md | 10 | C4 no se abre antes: `interact` llama `abrir_vista("D01d")` directo sin token; `play_open(4)` lo invoca el controlador de P6 tras `SFX_LOCK_CLICK` (0,3 s) y dura 1,6 s (carta visible a 1,9 s) | Animation |
| TR-box-010 (provisional) | caja-y-compartimentos.md | 10 | Entreabierto de C3: desplazamiento `ajar_cm` (2 cm, de 9) en `ajar_s` (0,6 s) con suavizado 3u²−2u³, diferido hasta que `VIS_D01C` esté en frustum (`Camera3D.is_position_in_frustum`) y ≤ `ajar_visible_dist_m` (2,0 m), sin oclusión | Rendering |
| TR-box-011 (provisional) | caja-y-compartimentos.md | 10 | Una pulsación cancela el entreabierto y `BOX_C3_OPEN` parte de la posición real de la tapa (0 a `ajar_cm`) | Animation |
| TR-box-012 (provisional) | caja-y-compartimentos.md | 10 | Cierre de C1–C3 al recibir «compartimento completado»: empieza `close_delay_s` (0,3 s) tras «vista cercana cerrada», sin token ni bloqueo, cierres independientes entre sí | Events |
| TR-box-013 (provisional) | caja-y-compartimentos.md | 10 | La caja ofrece `set_final_pose(n)` (idempotente, silenciosa, sin animar, mismo fotograma) y `play_open(n)`; son lo único que un controlador pide a la caja | Scene |
| TR-box-014 (provisional) | caja-y-compartimentos.md | 10 | Debe ofrecer anclajes de cámara `ANC_D01A`–`ANC_D01D` perpendiculares al plano del puzle (ANC_D01A desplazado lateralmente, `view_center_m` = (0,185; 0)), nodos `D01d/button_A/B/C` y fuente 3D `SPK_D01C` | Scene |
| TR-box-015 (provisional) | caja-y-compartimentos.md | 10 | Toda animación y vigilante usa tiempo de juego; el comportamiento de `AnimationPlayer`/audio bajo `SceneTree.paused` en Godot 4.7 NO está confirmado (bloquea AC-21) | Core |
| TR-box-016 (provisional) | caja-y-compartimentos.md | 10 | La caja no guarda, no pide guardado, no escribe hechos, no escribe/emite/lee `caja_completa` y no consulta `has_item` (verificable por análisis estático) | Save/Load |
| TR-box-017 (provisional) | caja-y-compartimentos.md | 10 | Respuesta de primer feedback audible ≤ 1 paso de física (< 0,5 s) tras pulsar | Audio |
| TR-box-018 (provisional) | caja-y-compartimentos.md | 10 | Con `reducir_movimiento` solo pueden acortarse `ajar_s` y `BOX_Cn_CLOSE`, nunca `BOX_Cn_OPEN` bajo su rango (pendiente Pregunta abierta 5) | Accessibility |

### Contratos — box

| Campo | Contenido |
|---|---|
| Emite | Ningún aviso ni hecho; solo señales/estado de presentación internos (fin de animación). Lee de 9: «puzle activado» `{puzzle, ajar_cm?}` |
| Consume | «puzle activado» (`{puzzle, ajar_cm?}`), `EV_PUZZLE_SOLVED_*`, «compartimento completado» (n=1–4) de 9; «vista cercana abierta/cerrada» de 7; `get_view_gate(view_id)` de 9; hechos `caja_c1`–`caja_c4` (lectura solo al configurar) |
| API pública | `can_interact`/`interact` de `D01a`–`D01d` (verbo `ABRIR`, `UI_VERBO_ABRIR`); `play_open(n)` (n=4); `set_final_pose(n)`. Llama a `bloquear_contexto("D01x")` → token / `liberar_contexto(token)`, `abrir_vista(id, desde_token)` → `ACEPTADA`/`RECHAZADA(motivo)` |
| Estado que posee/persiste | Pose por compartimento, `cierre_pendiente[n]`, `final_pendiente[4]` (en memoria); persiste nada |
| Nodo/autoload propuesto | Escena `D01` (nodo hijo del escritorio en la escena de D de `planta`, con `AnimationPlayer`, anclajes y `SPK_D01C`) + datos `assets/data/box/box.json`; sin autoload |


## documentos-y-bolsillo.md (sistema 20, slug `pocket`)

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-pocket-001 (provisional) | documentos-y-bolsillo.md | 20 | Catálogo cerrado de 7 ítems (`I-01`,`I-02`,`I-03`,`I-04`,`I-05`,`I-06a`,`I-07`) en `assets/data/items/items.json`; ninguno se crea en ejecución; ID fuera de catálogo → `has_item` falso + log (error visible en desarrollo) | Data |
| TR-pocket-002 (provisional) | documentos-y-bolsillo.md | 20 | El bolsillo no tiene almacenamiento propio: `has_item(id)` se deriva del hecho (`tarjeta_B/D`, `formulario_leido`, `caja_c1/c2/c4`) o del conjunto de sesión; guardar/cargar/reiniciar no requieren campos nuevos | Save/Load |
| TR-pocket-003 (provisional) | documentos-y-bolsillo.md | 20 | `I-01` es el único ítem de sesión: en memoria, no persistido, se vacía al descargar planta, nueva partida y carga (`otorgar_sesion("I-01")`) | Save/Load |
| TR-pocket-004 (provisional) | documentos-y-bolsillo.md | 20 | 20 es dueño y escritor de `formulario_leido`, `tarjeta_B`, `tarjeta_D` (monótonos, solo falso→verdadero); `otorgar("A05")` escribe B y luego D, idempotente | Core |
| TR-pocket-005 (provisional) | documentos-y-bolsillo.md | 20 | Hecho primero, presentación después: toda adquisición escribe el hecho antes de mostrar nada; cancelar/rechazar la presentación no afecta hecho, avance ni guardado | Core |
| TR-pocket-006 (provisional) | documentos-y-bolsillo.md | 20 | Presentación de tarjetas en serie por tarjeta (`t_item_dentro` 0,3 + `t_mostrar_item_s` 0,7 + `t_item_fuera` 0,3 = 1,3 s; 2,6 s con dos), sin bloquear contexto; se aborta ante `reposo()`, lectura, inspección, modo abierto o escena `sin control` | Animation |
| TR-pocket-007 (provisional) | documentos-y-bolsillo.md | 20 | `sostener(id, izquierda)`/`soltar()` al Jugador solo tras `gesto_terminado`; si rechaza, no reintenta; espera `objeto_sujeto`/`objeto_soltado`; detecta aborto externo por `objeto_soltado` no propio | Animation |
| TR-pocket-008 (provisional) | documentos-y-bolsillo.md | 20 | `sostener_item(id)` devuelve `ACEPTADA` o `RECHAZADA(motivo)` (incl. `presentacion_en_curso`); `HAND_HOLD_ITEM` (izq.) y `HAND_CARD_SWIPE` (der.) nunca coexisten | Input |
| TR-pocket-009 (provisional) | documentos-y-bolsillo.md | 20 | Las tarjetas no se consumen; `guardar_item()` no cambia ningún hecho; no existe API para tirar/soltar/combinar/consumir | Core |
| TR-pocket-010 (provisional) | documentos-y-bolsillo.md | 20 | Documentos = entradas de 18 (clave, fragmentos ordenados, estilo ∈ `impreso`,`manuscrito_vera`,`manuscrito_guardian`,`cristal_espejo`,`pantalla`,`libro`); estilo y correspondencia ítem→documento salen de datos, nunca del código; `I-07` = `CARTA_<carta_variante>` + `CARTA_CUERPO` | Data |
| TR-pocket-011 (provisional) | documentos-y-bolsillo.md | 20 | Dibuja la pantalla de `lectura` para cualquier documento que 7 entregue (clave+estilo); sin estado de página propio (7 indica la página); texto idéntico al de 18 sin marcas | UI |
| TR-pocket-012 (provisional) | documentos-y-bolsillo.md | 20 | `formulario_leido` se escribe al recibir «lectura completada» de `A04` (≥ `lectura_min_s` 2 s, de 7); lectura <2 s no lo escribe | Events |
| TR-pocket-013 (provisional) | documentos-y-bolsillo.md | 20 | `repasar_bolsillo()` (acción derivada de `atrás` en `exploración`, de 1) llama `abrir_lectura(item_id)` de 7 con resultado `ACEPTADA`/`APLAZADA`/`RECHAZADA(motivo)` | Input |
| TR-pocket-014 (provisional) | documentos-y-bolsillo.md | 20 | Cursor de repaso de sesión (no guardado) sobre lista fija `I-07,I-05,I-06a,I-04` filtrada por `has_item`; `i_siguiente = (pos+1) mod m` con `repaso_cerrar_ciclo`; `repaso_pendiente` evita avanzar con lecturas ajenas (N4-1) | Core |
| TR-pocket-015 (provisional) | documentos-y-bolsillo.md | 20 | Suscripción a «lectura abierta(ID)», «lectura cerrada», «lectura descartada», «lectura completada» (7); petición aplazada descartada a los 3 s por 7 | Events |
| TR-pocket-016 (provisional) | documentos-y-bolsillo.md | 20 | `A03` (DELEGAR a 20): estados `cerrada`/`abierta` no guardados; se reconstruye `abierta` si `formulario_leido`; tapa anima `t_tapa_s` 0,6 s sin bloquear; `A04` habilitado solo con `A03` abierta | Scene |
| TR-pocket-017 (provisional) | documentos-y-bolsillo.md | 20 | Al descargar la escena: cancelar presentación, cerrar lectura sin avisos al bus y vaciar el conjunto de sesión | Scene |
| TR-pocket-018 (provisional) | documentos-y-bolsillo.md | 20 | Pista `UI_BOLSILLO_AYUDA` una vez por sesión (indicador no persistido) vía pie de 7/24; sin HUD ni icono de «obtenido» y sin audio de recompensa; `items.json` + `inventory_config.json` con `t_mostrar_item_s`, `t_tapa_s`, `repaso_orden`, `repaso_cerrar_ciclo`, `mostrar_pista_bolsillo` | Accessibility |

### Contratos — pocket

| Campo | Contenido |
|---|---|
| Emite | Ningún aviso propio (el «ítem obtenido» opcional no está incluido); escribe hechos `formulario_leido`, `tarjeta_B`, `tarjeta_D` (los avisos de cambio los genera 3). Pide a 24 el pie `UI_BOLSILLO_AYUDA` |
| Consume | «lectura completada» (ID `A04`), «lectura abierta» (ID, solo tras `APLAZADA`), «lectura cerrada», «lectura descartada» (7); `objeto_sujeto(id)`, `objeto_soltado(id)`, `gesto_terminado` (2); cambio de `caja_c1`, `caja_c2`, `caja_c4`, `carta_variante` (3, lectura); acción `repasar_bolsillo` (1); descarga de escena (4); `cerrar_modos()` (21 vía 7) |
| API pública | `has_item(id)`; `otorgar("A05")` (de 8); `otorgar_sesion("I-01")` (de 19); `sostener_item(id) -> {ACEPTADA, RECHAZADA(motivo)}`; `guardar_item()`; `repasar_bolsillo()`; maneja `A03` (`can_interact`/`interact`). Llama a: `sostener(id, izquierda)`, `soltar()` (2), `abrir_lectura(item_id)` (7) |
| Estado que posee/persiste | Posee: conjunto de sesión (`I-01`), cursor de repaso `c`, `repaso_pendiente`, indicador «pista ya mostrada», estado de la presentación, estado de `A03` (reconstruido). Persiste (vía hechos de 3/5): `formulario_leido`, `tarjeta_B`, `tarjeta_D`; nada más |
| Nodo/autoload propuesto | Servicio de bolsillo/documentos con interfaz inyectable (nodo en la escena de planta o autoload con interfaz, no singleton de estado de juego; hechos en 3) + pantalla de lectura en capa UI; datos en `assets/data/items/` |

## NO LEÍDO

- Edge Cases, Visual/Audio, UI Requirements, Decisiones tomadas, Preguntas abiertas, Cambios requeridos, Entradas para el registro e Historial de los tres GDD; Summary, Overview y Player Fantasy.
- Dependencies de `access` leído; Tuning Knobs de `access` leído. Los GDD de 3, 4, 7, 9 y 2 no se abrieron, de modo que firmas como `bloquear_contexto`, `abrir_vista` y `get_view_gate` se toman tal como las citan estos tres GDD.
- Huecos: `box` no cita el tipo exacto de `get_view_gate` (solo `OPEN`/`BLOCKED`/`SOLVED`); `pocket` fija lectura y gestos de 2 como "‡ por confirmar"; la pausa de `AnimationPlayer` en Godot 4.7 queda NOT SOURCEABLE (TR-box-015).

---

<!-- bloque G5 -->
# Baseline de requisitos técnicos — lote G5 (sistemas 19, 21, 22)

## GDD 19 — ordenador-correo-impresora.md (slug `computer`)

### Requisitos

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-computer-001 (provisional) | ordenador-correo-impresora.md | 19 | El receptor de 19 implementa `ViewReceiver` de 7 (`registrar_receptor`, `elements()`, `handle_pointer`, `on_open()`, `on_close(motivo)`); no recibe puntero hasta `on_open()`, que 7 llama solo tras `camara_cedida`. | Core |
| TR-computer-002 (provisional) | ordenador-correo-impresora.md | 19 | `on_close(motivo ∈ {jugador, sistema})` se ejecuta antes de devolver la cámara, comportamiento idéntico en ambos motivos: saca foco, oculta teclado, llama `reposo()`, conserva consulta y lista solo en memoria de sesión. | Core |
| TR-computer-003 (provisional) | ordenador-correo-impresora.md | 19 | `atrás` cierra siempre el ordenador (nunca `Retroceso`/`Esc`); 19 no puede bloquearlo ni siquiera con teclado en pantalla abierto. | Input |
| TR-computer-004 (provisional) | ordenador-correo-impresora.md | 19 | Con foco en el campo de búsqueda, la UI consume teclas imprimibles, `Retroceso`, `Supr`, flechas e `Intro` antes que cualquier acción de Entrada (regla 20 de 1). | Input |
| TR-computer-005 (provisional) | ordenador-correo-impresora.md | 19 | Estado de `V01` `apagado`→`sesión abierta` solo en memoria; no es hecho ni se guarda; tras cargar partida vuelve a `apagado`. | Save/Load |
| TR-computer-006 (provisional) | ordenador-correo-impresora.md | 19 | Único hecho escrito: `correos_leidos = verdadero` (3), una vez, en el mismo fotograma del primer resultado, sin vuelta atrás; 19 es su único lector. | Events |
| TR-computer-007 (provisional) | ordenador-correo-impresora.md | 19 | Búsqueda por coincidencia exacta tras normalizar (minúsculas, sin tildes ni signos, recortada) contra etiquetas de 18; longitud 3 ≤ n ≤ 32; sin prefijos ni búsqueda al teclear. | Data |
| TR-computer-008 (provisional) | ordenador-correo-impresora.md | 19 | Latencia de búsqueda `t_busqueda` = 0,4 s en tiempo de juego (se detiene en pausa; `reducir_movimiento` no la altera); si se cierra antes, no hay lista ni `correos_leidos`. | Core |
| TR-computer-009 (provisional) | ordenador-correo-impresora.md | 19 | Temporizadores de 19 (`t_busqueda`, `t_impresion` 1,5 s, `t_tipeo_inactivo` 1,0 s) usan tiempo de juego y se pausan con la pausa. | Core |
| TR-computer-010 (provisional) | ordenador-correo-impresora.md | 19 | La lista muestra 6 correos (4 si `resultados_incluyen_ruido` = falso) en el orden fijo de 18 (`MAIL_3, MAIL_X1, MAIL_1, MAIL_4, MAIL_X2, MAIL_2`), sin reordenación. | Data |
| TR-computer-011 (provisional) | ordenador-correo-impresora.md | 19 | Teclado en pantalla activo si el dispositivo activo es mando, operado con el cursor y `seleccionar` existentes (sin acciones nuevas de Entrada); teclas ≥ 56 px lógicos (≥ `pick_min_px` 44), separación 8 px, 27 letras + Espacio/Borrar/Buscar. | Input |
| TR-computer-012 (provisional) | ordenador-correo-impresora.md | 19 | Cambio de dispositivo (mando→teclado) conserva texto y foco y oculta el teclado en pantalla. | Input |
| TR-computer-013 (provisional) | ordenador-correo-impresora.md | 19 | UI a resolución lógica 1920×1080 escalando con viewport, sin recortes en 16:9 y 16:10 (y 1280×720 físicos mínimo); pantalla ≥ 1280 px lógicos; modo teclado cabe en 520 px ≤ 720. | UI |
| TR-computer-014 (provisional) | ordenador-correo-impresora.md | 19 | Texto ≥ 24 px lógicos (cuerpo 28), contraste ≥ 4,5:1 (7:1 en cuerpo); cada estado con atributo no cromático y el botón deshabilitado expuesto como «no disponible» al lector de pantalla. | Accessibility |
| TR-computer-015 (provisional) | ordenador-correo-impresora.md | 19 | Fundido de encendido 0,3 s (`t_encendido`); con `reducir_movimiento` de 6, 100 ms fijos; precisión ± 1 fotograma. | Rendering |
| TR-computer-016 (provisional) | ordenador-correo-impresora.md | 19 | `V08` es máquina de estados `sin_resultados`→`lista`⇄`imprimiendo` (1,5 s) con indicador de sesión `hoja_en_bandeja`; tras cargar con `correos_leidos` verdadero nace en `lista`, `hoja_en_bandeja` falso. | Core |
| TR-computer-017 (provisional) | ordenador-correo-impresora.md | 19 | El trabajo de impresión enviado no se cancela al cerrar el ordenador, salir de sala, cambiar de escena ni pausar; se completa y deja la hoja en bandeja. | Core |
| TR-computer-018 (provisional) | ordenador-correo-impresora.md | 19 | Dos puntos de entrada (botón «Imprimir» y verbo de `V08`) comparten una máquina de estados; el botón está habilitado ⇔ `correos_leidos` ∧ `V08` ≠ `imprimiendo`; reenvío con hoja en bandeja es idempotente. | Core |
| TR-computer-019 (provisional) | ordenador-correo-impresora.md | 19 | Entrega: 19 llama a `otorgar_sesion("I-01")` de 20 (idempotente) solo si `has_item('I-01')` es falso; `I-01` no persiste y tras cargar se reimprime. | Save/Load |
| TR-computer-020 (provisional) | ordenador-correo-impresora.md | 19 | `compose_i01() -> SheetI01` es síncrona y pura (sin estado ni escritura): 6 bloques en orden de presentación, `ts_envio` entero en minutos desde lunes 00:00 siempre presente, `hora_envio`/`pie_ordena` null según datos `i01_*`; bloque con dato inválido se omite con «—» y se registra el error. | Data |
| TR-computer-021 (provisional) | ordenador-correo-impresora.md | 19 | Todos los valores de ajuste (tiempos, tamaños, `i01_*`, `pantalla_muestra_hora`, `resultados_incluyen_ruido`) se cargan de `assets/data/`, no constantes en código. | Data |
| TR-computer-022 (provisional) | ordenador-correo-impresora.md | 19 | Durante el tecleo 19 pide `reproducir_gesto('HAND_TYPE')` (bucle) y `reposo()` tras 1,0 s de inactividad o en `on_close`; un rechazo del Jugador no impide escribir. | Animation |

### Contratos

| Aspecto | Contenido |
|---|---|
| Emite | Hecho `correos_leidos = verdadero` (a 3, escritor único). `reproducir_gesto('HAND_TYPE')` y `reposo()` a 2. `otorgar_sesion("I-01")` a 20. Sonidos `SFX_PRINTER`, `SFX_KEY`, `SFX_CLICK_SUBTLE` a 23. No emite avisos propios (R15: sin aviso de pantalla). |
| Consume | `on_open()`, `on_close(motivo)`, `camara_cedida` (vía 7); `PointerEvent`/`handle_pointer`; dispositivo activo y `seleccionar`, `atrás`, `pausa` (1); `reducir_movimiento` (6; no consume `reducir_sobresaltos`); `has_item('I-01')` (20); registros de 18 (6 correos, etiquetas, orden, claves `UI_MAIL_*`, `OBJ_V08_*`, `PISTA_P1_N2`); `correos_leidos` al cargar (3); interacción `interact()` de `V08` desde 7. |
| API pública | `compose_i01() -> SheetI01` (`{cabecera, bloques:[{mail_id, ref:int 1..4\|null, dia, ts_envio:int, hora_envio:"hh:mm"\|null, hora_visible:bool, cuerpo, firma}], pie_ordena: clave\|null}`); `on_open()`, `on_close(motivo)`, `interact()` de `V08`; `V08` expuesto como objetivo resaltable por ID (`targets_if_missing_items`). |
| Estado que posee o persiste | Persiste solo `correos_leidos` (hecho de 3). Sesión en memoria (no guardado): consulta, lista abierta, `V01` sesión abierta, estado de `V08`, `hoja_en_bandeja`. Datos de configuración: `i01_hora_visible`, `i01_pie_ordena_visible`, `pantalla_muestra_hora`, `resultados_incluyen_ruido`. |
| Nodo/autoload propuesto | Sin autoload: escena/nodo de UI `ComputerScreen` (receptor `ViewReceiver`) + controlador `V08` (printer) en la escena de planta; `compose_i01()` en un servicio sin estado (`I01Composer`, RefCounted) inyectado a 9 (propuesta mía; el GDD no nombra nodos). |

## GDD 21 — director-de-escenas.md (slug `director`)

### Requisitos

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-director-001 (provisional) | director-de-escenas.md | 21 | El director es un sistema persistente (no pertenece a `planta` ni `recepcion`): se suscribe al bus al arrancar y no se da de baja; sobrevive a los cambios de escena. | Core |
| TR-director-002 (provisional) | director-de-escenas.md | 21 | Estado «inactivo» desde la petición de descarga total hasta «descarga total completada» (≤ 3,0 s†): ni escucha (salvo esa señal) ni emite, reloj parado; conserva el estado volátil y lo borra al recibir «descarga total completada»; se reactiva con la siguiente «carga de escena iniciada». | Core |
| TR-director-003 (provisional) | director-de-escenas.md | 21 | Escenas definidas por datos en `assets/data/scenes/scenes.json` (`id`, `tipo` momento\|dirigida, `disparador`, `condiciones` sobre hechos, `linea_de_tiempo` de pares `t_rel`→orden, y en dirigidas `t_fin` y `duracion_declarada`); parámetros en `scene-config.json`. | Data |
| TR-director-004 (provisional) | director-de-escenas.md | 21 | Validación al arrancar: ID repetido, orden desconocida o `t_rel` decreciente descartan esa escena (error visible en desarrollo; en build, descarte + una línea de log); el resto funciona. | Data |
| TR-director-005 (provisional) | director-de-escenas.md | 21 | Reloj de línea de tiempo `t_rel(n)=t_rel(n−1)+Δ_juego`, con tiempo de juego escalado; vale 0 con pausa, sin foco o sin mando; las órdenes vencidas en un mismo fotograma salen todas, en orden de tabla, una vez. | Core |
| TR-director-006 (provisional) | director-de-escenas.md | 21 | Las líneas de tiempo de `ESC1_LLEGADA` y `ESC8_ASCENSOR` se miden desde «escena lista» (no desde el fin del aclarado); precisión de ±1 fotograma. | Events |
| TR-director-007 (provisional) | director-de-escenas.md | 21 | El director lee hechos (`formulario_leido`, `caja_completa`, `llamada_iniciada`, `llamada_completada`, `respuesta_llamada`) y nunca escribe ninguno; reacciona al aviso de cambio, no al valor al cargar (salvo reanudación). | Events |
| TR-director-008 (provisional) | director-de-escenas.md | 21 | Órdenes emitidas por el bus sin esperar al ejecutor (salvo cierre de modos y líneas del cierre): «línea pedida», «efecto de escena pedido», «estado de objeto pedido», «tarjeta final pedida». | Events |
| TR-director-009 (provisional) | director-de-escenas.md | 21 | Dos canales de voz independientes (`VO_V_*` y `MEGA_*`, deducidos del prefijo del ID); dentro de un canal la nueva línea se aplaza hasta «línea terminada» con tope `t_cola_canal_s` (8,0†, dueño 23), tras el cual se descarta y se registra. | Audio |
| TR-director-010 (provisional) | director-de-escenas.md | 21 | Traspaso de `sin control` en el mismo fotograma de «carga de escena terminada» con `control_final` = `ninguno`; si `t_rel` ≥ `t_fin`, pide `exploración` en ese fotograma; nunca hay fotograma sin dueño ni pila vacía. | Input |
| TR-director-011 (provisional) | director-de-escenas.md | 21 | Duración declarada `duracion_declarada = t_fin + h_decl_s` (1,0†); tope de Entrada = + `margen_E` (2,0†) medido desde traspaso/apertura; toda escena dirigida debe declararla. | Input |
| TR-director-012 (provisional) | director-de-escenas.md | 21 | Traspaso o petición de `exploración` rechazados (`sin control` ya no es suyo): el director no recupera control, degrada la escena a momento y registra; nunca reintenta. | Input |
| TR-director-013 (provisional) | director-de-escenas.md | 21 | Al terminar escena pide `exploración` (nunca «cerrar»); solo el cierre de la escena 8 abre un `sin control` propio, con 25,8 s declarados. | Input |
| TR-director-014 (provisional) | director-de-escenas.md | 21 | Cancelación sin órdenes ni hechos ante «carga de escena fallida», «carga de escena iniciada» no pedida y «`sin control` absorbido» (dueño 21); estado volátil borrado y arma de nuevo escena 1 en `partida_nueva`. | Events |
| TR-director-015 (provisional) | director-de-escenas.md | 21 | Estado volátil de sesión (no hechos, no guardado): `esc4_mega_hecha`, `esc4_reflejo_hecho`, `apagon_activo`, `mensaje_telefono_pendiente`, `cierre_iniciado`; se borra en descarga total, «estado restablecido» y «estado restaurado»; sin guardado ni reloj persistente. | Save/Load |
| TR-director-016 (provisional) | director-de-escenas.md | 21 | Reanudación (`motivo` = `reanudar`): con `caja_completa` ∧ ¬`llamada_completada` aplica apagón reducido (`LUCES_APAGON` duración 0) y, al volver `exploración` con ¬`llamada_iniciada`, ejecuta `ESC7_TIMBRE`; con `llamada_iniciada`, `V02` es de 22. La escena 1 nunca se repite. | Save/Load |
| TR-director-017 (provisional) | director-de-escenas.md | 21 | Cada zona del pasillo (`T-PAS-1`, `T-PAS-2`) dispara su momento una vez por carga de `planta`, solo con ¬`caja_completa`; `T-D-OUT` dispara el apagón una vez (`apagon_activo`). | Scene |
| TR-director-018 (provisional) | director-de-escenas.md | 21 | `ESC7_APAGON` y `ESC7_TIMBRE` no toman `sin control` ni piden `cerrar_modos()`; el temporizador de 60,0† s hasta `TELEFONO_SUENA` corre en tiempo de juego y solo si ¬`llamada_iniciada`. | Core |
| TR-director-019 (provisional) | director-de-escenas.md | 21 | 21 es el único emisor de «estado de objeto pedido»; `V02` en `vibrando` solo por `ESC7_TIMBRE` o a los 60,0 s†; devuelve a `reposo` con el primer «interacción ejecutada» `resultado` = `HECHO` o «llamada iniciada»; desde ahí el dueño es 22. | Events |
| TR-director-020 (provisional) | director-de-escenas.md | 21 | «ascensor llamado» (de 8) → petición a 4 de `recepcion` con `control_final` = `ninguno`; si 4 la rechaza emite «ascensor rechazado» (sin datos) sin reintento; arma `ESC8_ASCENSOR` (`t_fin` = 6,0 s). | Scene |
| TR-director-021 (provisional) | director-de-escenas.md | 21 | `cerrar_modos()` + espera «modos cerrados» con tope `t_modos_max_s` = 2,0† (si no llega abre igualmente y registra); único uso: antes de `ESC8_CIERRE`. | Core |
| TR-director-022 (provisional) | director-de-escenas.md | 21 | Cadena de cierre `ESC8_CIERRE`: línea de 12A–12D según `respuesta_llamada`, +3,0 s, `VO_V_12E`, +2,0 s, fundido 0,8†, tarjeta 3,0 s, descarga total; esperas = min(evento, `t_linea_max_s` 8,0†); `D_cierre` = 25,8 s y tope duro `t_duro` = 24,8 s hacia descarga total. | Core |
| TR-director-023 (provisional) | director-de-escenas.md | 21 | `ESC8_CIERRE` se arma en «carga de escena terminada» de `recepcion` y se dispara con el primer «lectura completada» de `R01`; `cierre_iniciado` ignora los siguientes; espera `g_post_lectura_s` 3,0 s. | Events |
| TR-director-024 (provisional) | director-de-escenas.md | 21 | Con `reducir_movimiento` (leído en cada disparo, no al arrancar) sustituye `LUCES_PARPADEO` por una atenuación de 0,6 s† y pide aparición gradual en `REFLEJO_RETARDADO`; fundido propio de 0,1 s. | Accessibility |
| TR-director-025 (provisional) | director-de-escenas.md | 21 | Traspaso viable si `M_traspaso = (D_carga + margen_E) − t_terminada ≥ 0` (nominal ≈ 12,0 s); si es < 0 se rechaza y aplica la degradación a momento. | Core |
| TR-director-026 (provisional) | director-de-escenas.md | 21 | Líneas `fallida`/`sin audio` no se reintentan; la línea de tiempo continúa con subtítulo; el director no genera texto propio (solo IDs del catálogo de 18). | Audio |
| TR-director-027 (provisional) | director-de-escenas.md | 21 | Pruebas con reloj de test y dobles de 4 y Entrada reales (AC-21-23b/c): avance manual de fotogramas, `D_carga` reducido; tests en `tests/unit/director_de_escenas/` y `tests/integration/director_de_escenas/`. | Tooling |

### Contratos

| Aspecto | Contenido |
|---|---|
| Emite | «línea pedida» (ID de línea, fuente opcional p. ej. `C01`); «efecto de escena pedido» ‡ (`id_efecto`, objetivo, duración, parámetros: `TELEFONO_PULSOS`, `LLUVIA_REALCE`, `LUCES_PARPADEO`, `REFLEJO_RETARDADO`, `LUCES_APAGON`, `SILLAS_RODANDO`, `TECLEO_LEJANO`, `TELEFONO_SUENA`, `LUCES_RESTAURAR`, `LLUVIA_VUELVE`, `LLUVIA_CESA`, `PUERTAS_ASCENSOR_ABREN`); «estado de objeto pedido» ‡ (objeto, estado; `V02` `vibrando`/`reposo`, puertas del ascensor); «tarjeta final pedida» ‡ (claves de 18); «ascensor rechazado» (sin datos); «traspasar `sin control`» (dueño 21, duración declarada); `exploración` al terminar; petición de `recepcion` (`control_final` = `ninguno`), fundido propio (`d_cierre`) y descarga total a 4; `cerrar_modos()` a 7. Ningún hecho. |
| Consume | «escena lista» (con `motivo` = `partida_nueva`/`reanudar`), «carga de escena iniciada/terminada/fallida», «descarga total solicitada/completada», «zona activada» (`T-PAS-1`, `T-PAS-2`, `T-D-OUT`, `T-OFI-IN`); «interacción ejecutada» (`V02`, `resultado`), «lectura completada» (`R01`) ‡, «modos cerrados»; «ascensor llamado» (8); «línea terminada»/«línea sin audio»/«línea fallida» (23); «`sin control` absorbido» (1); `EV_PUZZLE_SOLVED_P2`; «llamada iniciada»; «estado restablecido»/«estado restaurado»; `pause_opened`/pausa cerrada; avisos de cambio de `formulario_leido`, `llamada_completada`; `caja_completa`, `llamada_iniciada`, `respuesta_llamada`; `reducir_movimiento` (6); `t_cola_canal_s` (23). |
| API pública | Ninguna firma nombrada: se integra solo por bus y datos (`scenes.json`). Llama a `cerrar_modos()` de 7. |
| Estado que posee o persiste | Nada persistente. Memoria de sesión: `esc4_mega_hecha`, `esc4_reflejo_hecho`, `apagon_activo`, `mensaje_telefono_pendiente`, `cierre_iniciado`; relojes `t_rel`/`t_sc`; escenas armadas. |
| Nodo/autoload propuesto | Autoload `SceneDirector` (persistente, fuera de `planta`/`recepcion`) que carga `scenes.json` y `scene-config.json`; la línea de tiempo en un ejecutor interno con reloj propio (propuesta mía; el GDD no nombra nodo). |

## GDD 22 — llamada-telefonica.md (slug `call`)

### Requisitos

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-call-001 (provisional) | llamada-telefonica.md | 22 | Máquina de estados lineal `INACTIVA`→`DESCOLGANDO`→`SILENCIO`→`RESPIRACION`→`LINEA`→`ANTES_OPCIONES`→`OPCIONES` (subestados `ESPERA`/`SENAL`)→`RESPUESTA`→`CIERRE`→`COMPLETADA`; nunca retrocede; `COMPLETADA` vuelve a `INACTIVA` solo al descargar la escena del despacho. | Core |
| TR-call-002 (provisional) | llamada-telefonica.md | 22 | Sin disparador propio: `can_interact(V02, Descolgar)` ⇔ `V02` `vibrando` ∧ `caja_completa` ∧ ¬`llamada_completada` ∧ máquina `INACTIVA`; verbo delegado por 7 (`DELEGAR`). | Core |
| TR-call-003 (provisional) | llamada-telefonica.md | 22 | `interact(Descolgar)` ejecuta en un mismo fotograma y en orden: (a) escribe `llamada_iniciada` y emite «llamada iniciada» si era falso, (b) pide contexto `llamada` a 1, (c) `V02`→`en_llamada`, (d) entra en `DESCOLGANDO`; es el único punto de sellado de guardado. | Save/Load |
| TR-call-004 (provisional) | llamada-telefonica.md | 22 | Si `llamada_iniciada` ya es verdadero (reanudación) no se reescribe ni se reemite «llamada iniciada»; la llamada se repite entera desde `DESCOLGANDO`; `respuesta_llamada` y `llamada_completada` nunca llegan a disco. | Save/Load |
| TR-call-005 (provisional) | llamada-telefonica.md | 22 | Secuencia temporizada en tiempo de juego (pausa no cuenta): pick 0,8 s, silencio 2,0†, respiración 2,0†, línea `VO_G_12x` a 4,8 s, opciones a 10,8 s (con `L12` 5,0), cierre 1,0†; `T_compl` 16,4–44,8 s; precisión ±0,05 s. | Core |
| TR-call-006 (provisional) | llamada-telefonica.md | 22 | Contexto `llamada` de Entrada tratado por 2 como «Congelado» (no es `sin control`); `atrás`/`ui_atrás` no hacen nada; `pausa` permitida y congela máquina, cuenta de espera y audio. | Input |
| TR-call-007 (provisional) | llamada-telefonica.md | 22 | Cuatro opciones A–D en orden fijo, sin foco inicial, aspecto idéntico y sin aleatorizar; el cursor está oculto hasta `OPCIONES` y se oculta al elegir (cambio requerido en 1). | UI |
| TR-call-008 (provisional) | llamada-telefonica.md | 22 | Guarda `t_guarda_opciones_s` 0,6† tras aparecer las opciones: pulsaciones ignoradas, no encoladas; la guarda cuenta solo tiempo de juego. | Input |
| TR-call-009 (provisional) | llamada-telefonica.md | 22 | Elección por ratón, `ui_arriba`/`ui_abajo` + `ui_aceptar`/`seleccionar`; con mando solo el stick derecho mueve el cursor; mover foco no elige; la primera elección es definitiva (segunda en el mismo fotograma o después se ignora). | Input |
| TR-call-010 (provisional) | llamada-telefonica.md | 22 | `t_espera_s` 20,0† empieza al aparecer las opciones; al cumplirse sin elección entra en `SENAL` una sola vez (`SFX_BREATH_BROKEN` 4,0† + `VO_G_14_RET`/`VO_G_14_ASG` según `t4_decision`); sin límite posterior; no elige por el jugador. | Events |
| TR-call-011 (provisional) | llamada-telefonica.md | 22 | Elegir durante `SENAL` interrumpe el sonido (`accion` = `interrupt`, ≤ 0,3 s con `t_interrupt_s` 0,2† de 23); si 23 no puede, la respuesta espera como máximo `T_breath + L14`. | Audio |
| TR-call-012 (provisional) | llamada-telefonica.md | 22 | Al elegir: escribe `respuesta_llamada` (A–D, un solo sentido), oculta opciones y cursor, pide `VO_G_13A`–`VO_G_13D`; si la escritura es rechazada reproduce la línea del valor guardado y registra la discrepancia. | Events |
| TR-call-013 (provisional) | llamada-telefonica.md | 22 | `CIERRE` en orden: silencio 1,0†, `SFX_PHONE_END`, `llamada_completada` = verdadero (una sola vez), aviso «llamada completada», `HAND_PHONE_PUTDOWN` (≤ 0,6†); luego libera contexto `llamada`, `V02`→`reposo`, máquina `COMPLETADA`. | Events |
| TR-call-014 (provisional) | llamada-telefonica.md | 22 | 22 es el único escritor de `llamada_iniciada`, `respuesta_llamada`, `llamada_completada`; lee `carta_variante`, `t4_decision`, `caja_completa`; solo emite avisos «llamada iniciada» y «llamada completada». | Events |
| TR-call-015 (provisional) | llamada-telefonica.md | 22 | Tolerancia a fallo de audio: tras «línea sin audio»/«línea fallida» espera `fallback_s` (de 18), y sin respuesta de 23 `fallback_s` + `line_grace_s` (2,0†); la llamada nunca se bloquea y no tiene estado de fallo. | Audio |
| TR-call-016 (provisional) | llamada-telefonica.md | 22 | «línea pedida» solo para voz (`VO_G_12*`, `VO_G_13*`, `VO_G_14_*`); SFX por «sonido pedido» con `accion` ∈ `play`/`stop`/`interrupt` (`SFX_PHONE_BUZZ`, `SFX_BREATH_BROKEN`, `SFX_PHONE_END`, `SFX_CALL_BREATH`). | Audio |
| TR-call-017 (provisional) | llamada-telefonica.md | 22 | 22 es dueño de `V02` desde la llamada: ejecuta «estado de objeto pedido» solo para `V02` y reafirma `en_llamada` tras cada aviso recibido entre `DESCOLGANDO` y `CIERRE`, sea cual sea el orden de llegada; ignora otros objetos. | Events |
| TR-call-018 (provisional) | llamada-telefonica.md | 22 | Reanudación con `llamada_iniciada` ∧ ¬`llamada_completada`: tras «escena lista» y al volver `exploración` pone `V02` `vibrando` y pide `SFX_PHONE_BUZZ` en bucle una sola vez; el timbre tiene un único dueño por caso (21 si ¬`llamada_iniciada`, 22 si no). | Save/Load |
| TR-call-019 (provisional) | llamada-telefonica.md | 22 | Rechazo del contexto `llamada` por Entrada: máquina sigue `INACTIVA`, `V02` vuelve a `vibrando`, `llamada_iniciada` sigue verdadero, no se pide línea ni buzz, se registra. | Core |
| TR-call-020 (provisional) | llamada-telefonica.md | 22 | Manos: 22 solo pide `HAND_PHONE_PUTDOWN` y espera su fin (o `t_putdown_s` 0,6 si 2 lo rechaza); `ANIM_PHONE_PICKUP` (0,8 s) lo pide 7 antes de `interact()`; `HAND_PHONE_HOLD` lo mantiene 2. | Animation |
| TR-call-021 (provisional) | llamada-telefonica.md | 22 | Subtítulo `SUB_BREATH_BROKEN` («[Llanto contenido]» provisional) durante `SFX_BREATH_BROKEN`; solo si los subtítulos están activos (muestra 26). | Accessibility |
| TR-call-022 (provisional) | llamada-telefonica.md | 22 | Valores de tiempo en datos externos (`call.json` propuesto ‡), no en código: `t_sil_s`, `t_resp_s`, `t_ante_s`, `t_guarda_opciones_s`, `t_espera_s`, `t_cierre_s`, `line_grace_s`, `fallback_s`, `t_putdown_s`. | Data |
| TR-call-023 (provisional) | llamada-telefonica.md | 22 | Edge: `carta_variante` sin fijar → no se pide `VO_G_12*`, avanza y advierte; `t4_decision` sin fijar → `VO_G_14_RET` + una advertencia. | Data |
| TR-call-024 (provisional) | llamada-telefonica.md | 22 | Con `V01` abierto el verbo «Descolgar» no inicia llamada ni cierra el ordenador; disponible al volver a `exploración`. | Core |

### Contratos

| Aspecto | Contenido |
|---|---|
| Emite | Avisos «llamada iniciada» y «llamada completada»; «línea pedida» (`VO_G_12A/B/C`, `VO_G_13A–D`, `VO_G_14_RET/ASG`); «sonido pedido» (`accion` play/stop/interrupt; `SFX_PHONE_BUZZ`, `SFX_BREATH_BROKEN`, `SFX_PHONE_END`, `SFX_CALL_BREATH` ‡); escritura de hechos `llamada_iniciada`, `respuesta_llamada`, `llamada_completada`; peticiones a 1 (entrar/salir de `llamada`, mostrar/ocultar cursor) y a 2 (`HAND_PHONE_PUTDOWN`). |
| Consume | «estado de objeto pedido» (solo `V02`, de 21); «línea terminada»/«línea sin audio»/«línea fallida» (23); «pausa abierta»/«pausa cerrada»; «escena lista» y descarga de la escena del despacho; hechos `carta_variante`, `t4_decision`, `caja_completa`, `llamada_iniciada`, `llamada_completada`; fin de `ANIM_PHONE_PICKUP`/`HAND_PHONE_PUTDOWN`; `ui_arriba`, `ui_abajo`, `ui_aceptar`, `seleccionar`, `pausa`; claves de 18 (`UI_LLAMADA_OPCION_A`–`_D` propuesta, `SUB_BREATH_BROKEN`, `fallback_s`). |
| API pública | `can_interact(V02, Descolgar)` y `interact(Descolgar)` (manejador de `V02` delegado por 7); sin firmas más precisas en el GDD. |
| Estado que posee o persiste | Persiste solo `llamada_iniciada` (sellado por 5); `respuesta_llamada` y `llamada_completada` son hechos de 3 que no llegan a disco. Memoria: estado de la máquina, subestado `ESPERA`/`SENAL`, cuenta de espera, foco de opciones. Posee el estado de `V02` desde la llamada (`en_llamada`, `reposo`, `vibrando` en reanudación). |
| Nodo/autoload propuesto | Sin autoload: nodo `CallController` en la escena de planta/despacho (vive en la planta, descarga con ella), con datos en `call.json`, y panel de opciones diegético sobre la vista del teléfono (propuesta mía; el GDD no nombra nodo). |

## NO LEÍDO

Edge Cases, Decisiones tomadas, Preguntas abiertas, Cambios requeridos, Entradas para el registro, Historial (los tres GDDs); además PA-n/D19-n citados solo por referencia.

---

<!-- bloque G6 -->
# Baseline de requisitos técnicos, lote G6 (puzles 1–3)

Todos los TR son provisionales. Lo que ya pertenece a `marco-de-puzles.md` (9) no se repite; solo se señala qué hace el controlador propio.

## puzle-1-cronologia.md (sistema 11, slug `puzzle1`)

Leído: Detailed Rules R1–R46, Formulas F1–F7, Dependencies, Tuning Knobs, Acceptance Criteria, Datos del puzle.

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-puzzle1-001 (provisional) | puzle-1-cronologia | 11 | La entrada `P1` de `assets/data/puzzles/puzzles.json` usa `schema_version: 2`, `mode: VIEW`, `view: C05`, `solved_flag: archivo_abierto`, `requires.all: []`, `needs_items: ["I-01"]` y `persist: []`; pasa la validación de 9 (AC-19). | Data |
| TR-puzzle1-002 (provisional) | puzle-1-cronologia | 11 | `solution.sequence = [2,1,3,4]` (enteros, convertidos a `int` en la carga) es dato; una prueba de CI ordena los 4 bloques con `ref` por el entero `ts_envio` de `compose_i01()` y falla si difiere de `solution.sequence` o si hay dos sellos iguales (AC-3). El controlador no deriva la solución en ejecución. | Data |
| TR-puzzle1-003 (provisional) | puzle-1-cronologia | 11 | `Puzzle1Controller` hereda de `PuzzleController` y solo devuelve veredictos: no escribe ni lee hechos, no emite avisos y no cambia el estado público (el hecho `archivo_abierto` lo escribe 9 al resolver). | Core |
| TR-puzzle1-004 (provisional) | puzle-1-cronologia | 11 | El controlador posee dos estados en memoria: la colocación `S=(s1..s4)`, con `sk ∈ {1..4, vacío}` e inyectiva (209 estados, 24 completos), y `en_mano ∈ {ninguna,1..4}`. | Core |
| TR-puzzle1-005 (provisional) | puzle-1-cronologia | 11 | Solo procesa el gesto `seleccionar` (confirmado en fase `fin`) e ignora actualización, agarrar, mantener y rotar. Implementa las 9 filas de R13, incluidos mover (fila 4), intercambiar (fila 5), descartar en bloqueo (fila 9) y no perder ni duplicar referencias (AC-4). | Input |
| TR-puzzle1-006 (provisional) | puzle-1-cronologia | 11 | `evaluate()` es función pura de (colocación, `en_mano`, `solution`) y devuelve `SOLVED` con `[2,1,3,4]`, `REJECT` con cualquier otro estado completo y `NONE` con estado incompleto o `en_mano ≠ ninguna`; nunca `PARTIAL` ni `HOLDING` (error de datos). | Core |
| TR-puzzle1-007 (provisional) | puzle-1-cronologia | 11 | Seleccionar, deseleccionar o perder la referencia en mano cuenta como cambio para `DELAYED_AFTER_CHANGE` (`delay_s` 0,6 s en `GameClock`, rango 0,3–1,5). Una cancelación (cierre, `atrás`, pérdida de foco, pausa) pone `en_mano = ninguna` en silencio, sin `REJECT`, y rearma la cuenta si los 4 huecos están llenos. | Core |
| TR-puzzle1-008 (provisional) | puzle-1-cronologia | 11 | Reparto de `elements()`: 19 aporta los bloques y las 4 refs vía `compose_i01()`; el marco crea `C05/paper/ref_N` (exactamente 4); el controlador declara `C05/slot_1..4` y las marcas no clicables `C05/paper/stamp_1..4` (de `dia` y `hora_envio`). `compose_i01()` se llama en cada apertura; si no devuelve 4 bloques con `ref`, se registra error de datos y se abre como sin material (AC-21). | Scene |
| TR-puzzle1-009 (provisional) | puzle-1-cronologia | 11 | Sin `I-01` (`has_item`, vía marco), la vista muestra 4 huecos vacíos sin hoja ni refs; pulsar un hueco da `locked_feedback` `SFX_CLICK_SUBTLE` sin texto, sin escribir hechos y con P1 `ACTIVO`. | Core |
| TR-puzzle1-010 (provisional) | puzle-1-cronologia | 11 | La geometría de la vista vive en `assets/data/puzzles/p1_view.json`, no en el controlador. Viewport 1920×1080, hoja 1000×960, `ref_N` 112×56 con paso ≥150, `slot_k` 160×160 con paso 200 desde x=1100. El validador exige elementos ≥44 px y separación de centros ≥128 px (AC-18). | Data |
| TR-puzzle1-011 (provisional) | puzle-1-cronologia | 11 | `element_zones` con `ids: ["C05/paper/ref_*"]` y `atraccion_desactivada: true`; `slot_k` mantiene la atracción asistida (mando/stick atraído solo por los huecos). No declara `assist` y usa R=64 px por elemento. Excepción por zona a la regla 9 del marco. | Input |
| TR-puzzle1-012 (provisional) | puzle-1-cronologia | 11 | `on_change: {sfx:"SFX_SLOT_IN", when:"REF_PLACED"}`: el marco emite «feedback de puzle» una vez por cada cambio que deja una referencia en un hueco (filas 4 y 5), y ninguno al vaciar (fila 6). | Events |
| TR-puzzle1-013 (provisional) | puzle-1-cronologia | 11 | Rechazo uniforme para los 23 estados incorrectos: `lock: PUZZLE` 1,5 s con eventos descartados, `shake_s` 1,2 s, `reset_after_s` 1,5 s (≤ `lock_max_s` 2,0). `reset_attempt` devuelve las 4 refs a la hoja. Sin contador ni texto. Con `reducir_movimiento`, cambio de tono estático en lugar de temblor; un cambio del ajuste durante un rechazo en curso solo afecta al siguiente. | Animation |
| TR-puzzle1-014 (provisional) | puzle-1-cronologia | 11 | Persistencia: solo `archivo_abierto`. Colocaciones, `en_mano`, hoja y nivel de pista no se guardan; las colocaciones sobreviven al cierre de la vista (`KEEP`) y se pierden al cargar. Al cargar con `archivo_abierto` falso, P1 `ACTIVO`, huecos vacíos e `I-01` ausente aunque `correos_leidos` sea verdadero (AC-14). | Save/Load |
| TR-puzzle1-015 (provisional) | puzle-1-cronologia | 11 | Resolución `IMMEDIATE`, en el mismo fotograma y por este orden: escribir `archivo_abierto`, P1 `RESUELTO`, `EV_PUZZLE_SOLVED_P1 {puzzle:'P1', rewards:[]}`, sin «compartimento completado», `SFX_UNLOCK` 1,4 s y `cerrar_vista('C05','resuelto')` a `close_view_after_s` 1,5 s. La puerta A (8) reacciona al hecho, no al aviso. | Events |
| TR-puzzle1-016 (provisional) | puzle-1-cronologia | 11 | Tres pistas `REQUEST` sin `IDLE` y sin mover cámara: N1 `HIGHLIGHT` de `C05/paper` 3,0 s con `targets_if_missing_items:["V08"]`; N2 `TEXT` con la clave `PISTA_P1_N2` de 18; N3 `HIGHLIGHT` de `stamp_1..4` 3,0 s. `apply_hint_effect` devuelve `false`; los stamps van en `solution.visual_elements`. | Core |
| TR-puzzle1-017 (provisional) | puzle-1-cronologia | 11 | Tras resolver, el marco cierra de inmediato una apertura por vía no normal (`cerrar_vista('C05','sistema')`). `C05` deja de ser objetivo con `archivo_abierto` verdadero (`habilitado_si: {ninguno:[archivo_abierto]}`). | Scene |
| TR-puzzle1-018 (provisional) | puzle-1-cronologia | 11 | Pruebas en `tests/unit/puzzle_1/` con `GameClock` falso: oráculo de 1.000 secuencias aleatorias que llega siempre a `RESUELTO` (AC-12), 23 rechazos idénticos (AC-10) y temporización F5 (AC-6/7). Captura retenida de `C05` resuelto con sellos legibles a 1080p, 16:9 y 16:10 (AC-PV5). | Tooling |

### Contratos P1

| Campo | Contenido (nombres del GDD) |
|---|---|
| Emite | El controlador no emite nada. Emite el marco por él: `EV_PUZZLE_SOLVED_P1 {puzzle:'P1', rewards:[]}`; «feedback de puzle» `{puzzle:'P1', sound_id:'SFX_SLOT_IN', element:'C05/slot_k'}`; `SFX_REJECT`, `SFX_UNLOCK`, `SFX_CLICK_SUBTLE`; `elements_changed`; `cerrar_vista('C05','resuelto')`. Hecho escrito por 9: `archivo_abierto`. |
| Consume | `compose_i01() → SheetI01` de 19 (bloques, `ref`, `dia`, `hora_envio`, `hora_visible`, `pie_ordena`, `ts_envio`); `has_item("I-01")` vía 9 (de 20); `GameClock`; ajuste `reducir_movimiento` (6); `seleccionar` y `cancelación` de 7; `get_hints('P1')` y `request_hint('P1', n)` de 17; clave `PISTA_P1_N2` (18); `V08` como objetivo resaltable (19). |
| API pública del controlador | `evaluate()`, `elements()`, `on_open`, `on_close(motivo)`, `apply_hint_effect` (devuelve `false`), `reset_attempt`, `play_resolution`; maneja `seleccionar`. IDs: `C05`, `C05/paper`, `C05/paper/ref_1..4`, `C05/slot_1..4`, `C05/paper/stamp_1..4`. |
| Estado que posee o persiste | En memoria: colocación `S` y `en_mano` (KEEP en la sesión de escena). Persiste solo `archivo_abierto` (owner 9, escrito por el marco). |
| Nodo propuesto | `Puzzle1Controller` (hereda `PuzzleController`), cargado por el marco para la vista `C05`; geometría en `p1_view.json`. |

## puzle-2-memorando-en-el-cristal.md (sistema 12, slug `puzzle2`)

Leído: Detailed Rules R1–R32, Formulas F1–F6, Dependencies, Tuning Knobs, Visual/Audio Requirements, Acceptance Criteria, Datos del puzle.

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-puzzle2-001 (provisional) | puzle-2-memorando-en-el-cristal | 12 | La entrada `P2` de `puzzles.json` usa `mode: WORLD`, `elements: ["B01","B02","B03",{"id":"B08","decor":true}]`, `solved_flag: memo_leido`, `requires.all: []`, `validation.policy: ON_CHANGE` y `resolution: IMMEDIATE`. No declara `on_reject`, `assist`, `needs_items` ni `close_view_after_s`. | Data |
| TR-puzzle2-002 (provisional) | puzle-2-memorando-en-el-cristal | 12 | `pointing_map` (12 puntos: `EMPTY`, `SEAL`, `F1..F3` por lámpara y posición 1–4), `solution.lamps[]` (`initial` 2,2,2; `target` 3,1,4), `fragments` (`DOC_01#1..3`) y `positions: 4` viven en datos; el controlador no contiene valores. | Data |
| TR-puzzle2-003 (provisional) | puzle-2-memorando-en-el-cristal | 12 | `P2Controller` hereda de `PuzzleController`, solo devuelve veredictos y presenta (no escribe hechos ni emite avisos). Los hechos `pos_L`, `pos_C`, `pos_R` (int 1–4, `persist`, escritos en cada cambio), `memo_leido` y `EV_PUZZLE_SOLVED_P2` los escribe y emite el marco. | Core |
| TR-puzzle2-004 (provisional) | puzle-2-memorando-en-el-cristal | 12 | Una activación del verbo `Girar` en `B01..B03` llega vía `interact(Girar,ctx)` a `handle_activation(element_id,'Girar')`, que avanza `pos' = (pos mod 4)+1` (un paso, un sentido, sin arrastre) y devuelve `HECHO`. En el mismo fotograma: el marco escribe `pos_*`, llama a `evaluate()` (`ON_CHANGE`) y 7 reproduce `HAND_TURN` (≤0,8 s). | Input |
| TR-puzzle2-005 (provisional) | puzle-2-memorando-en-el-cristal | 12 | `evaluate()` es pura sobre el estado de las 3 lámparas. `progress` es el subconjunto iluminado de {F1,F2,F3} (el sello `SEAL` no cuenta): 3 → `SOLVED`, 1–2 → `PARTIAL(progress)`, 0 → `NONE`. Nunca `REJECT` (se trata como `NONE` y es error de datos). | Core |
| TR-puzzle2-006 (provisional) | puzle-2-memorando-en-el-cristal | 12 | `on_partial: SFX_GLASS_HUM`: el marco compara `progress` con el anterior y emite el sonido una vez por fragmento incorporado; no suena al apagarse, ni al mover entre puntos sin fragmento nuevo, ni por el sello. | Audio |
| TR-puzzle2-007 (provisional) | puzle-2-memorando-en-el-cristal | 12 | Presentación del cristal: visibilidad lógica instantánea y fundido de opacidad `clamp(op0 ± dt/fragment_fade_s, 0, 1)` con `fragment_fade_s` = 0,8 s (0,4–1,5). Cada transición parte de la opacidad actual y se conserva con `reducir_movimiento`, porque es luminancia. | Rendering |
| TR-puzzle2-008 (provisional) | puzle-2-memorando-en-el-cristal | 12 | La cabeza de cada lámpara gira a su nuevo punto en `lamp_turn_s` = 0,4 s† (≤ `HAND_TURN`); con `reducir_movimiento` cambia al instante. | Animation |
| TR-puzzle2-009 (provisional) | puzle-2-memorando-en-el-cristal | 12 | Requisito de nivel y arte (R10): los 12 puntos del cristal no se solapan y el haz de una lámpara no cubre el punto de otra. La validación al arrancar exige un solo punto con fragmento por lámpara, 3 elementos de 4 posiciones, estado inicial ≠ solución y claves `DOC_01#n` y `PISTA_P2_N1` en 18. | Scene |
| TR-puzzle2-010 (provisional) | puzle-2-memorando-en-el-cristal | 12 | Resolución `IMMEDIATE` en el mismo fotograma: `memo_leido = true`, `RESUELTO`, `EV_PUZZLE_SOLVED_P2 {puzzle:'P2', rewards:[]}`, sin `compartment`, `SFX_GLASS_HUM` `glass_hum_s` 2,0 s y `play_resolution()`. Sin `close_view_after_s`. 21 pide `VO_V_08` a +3,0 s del evento. | Events |
| TR-puzzle2-011 (provisional) | puzle-2-memorando-en-el-cristal | 12 | `play_resolution()` deja `DOC_01` completo y permanente (F1..F3 iluminados, cabezas en 3,1,4). Con P2 `RESUELTO`, `Girar` devuelve `SIN_EFECTO` con `SFX_CLICK_SUBTLE` y `HAND_REACH`, sin cambiar `pos_*`. | Animation |
| TR-puzzle2-012 (provisional) | puzle-2-memorando-en-el-cristal | 12 | Carga: con `memo_leido` verdadero, `restore_solved_presentation()` coloca el memorando completo y las cabezas en 3,1,4 al instante, sin sonidos ni avisos y sin reescribir `pos_*`. Con `memo_leido` falso restaura `pos_*` en silencio (sin fundido, sin `SFX_GLASS_HUM`, sin `PARTIAL`; `progress_previo` calculado en silencio). | Save/Load |
| TR-puzzle2-013 (provisional) | puzle-2-memorando-en-el-cristal | 12 | Tras «escena lista», el marco llama una vez a `evaluate()` (regla 8 de 9). Con `pos=(3,1,4)` y `memo_leido` falso (cierre forzado), P2 se resuelve por el camino normal. Al recargar `planta`, las lámparas toman el valor actual de sus hechos. | Save/Load |
| TR-puzzle2-014 (provisional) | puzle-2-memorando-en-el-cristal | 12 | Pistas, 3 `REQUEST` sin `IDLE` con `apply_hint_effect = false`. N1: `TEXT` `PISTA_P2_N1` más `AFFORDANCE MIRROR_PREVIEW` (F1 en espejo 2,0 s† en una zona neutra, sin `targets`). N2: `AFFORDANCE FLOOR_MARKS` sobre `B08` (números 1–4 y marca de la posición actual). N3: `AFFORDANCE BEAM_HALO` sobre `B01..B03`. | Core |
| TR-puzzle2-015 (provisional) | puzle-2-memorando-en-el-cristal | 12 | El controlador implementa un catálogo cerrado de affordances (`MIRROR_PREVIEW`, `FLOOR_MARKS`, `BEAM_HALO`). `BEAM_HALO` es por frame: halo si distancia horizontal cámara–base ≤ `halo_distance_m` = 1,5 m† (< separación 1,6 m), también sobre puntos vacíos. | Rendering |
| TR-puzzle2-016 (provisional) | puzle-2-memorando-en-el-cristal | 12 | Las pistas duran en `GameClock` (la cuenta empieza al reanudar de la pausa); `hint_level_reached` no se persiste. Efecto `BEAM_HALO` y `FLOOR_MARKS` permanecen durante la sesión de escena. | Core |
| TR-puzzle2-017 (provisional) | puzle-2-memorando-en-el-cristal | 12 | Pruebas: solucionador exhaustivo de 64 estados a través de la tubería real, ≤9 pulsaciones (AC-P2-16); 64 combinaciones solo (3,1,4) = `SOLVED` (AC-P2-04); validación de arranque falla con 2 fragmentos por lámpara (AC-P2-15). Captura retenida con `reducir_movimiento` (AC-P2-17). | Tooling |

### Contratos P2

| Campo | Contenido (nombres del GDD) |
|---|---|
| Emite | El controlador no emite. Emite el marco: `EV_PUZZLE_SOLVED_P2 {puzzle:"P2", rewards:[]}`; `SFX_GLASS_HUM` (`on_partial`, y 2,0 s al resolver); 7 reproduce `HAND_TURN`, `HAND_REACH`, `SFX_CLICK_SUBTLE`. Hechos escritos por 9: `pos_L`, `pos_C`, `pos_R`, `memo_leido`. |
| Consume | `handle_activation(element_id,'Girar')` (vía 9 y 7); `interact(Girar, ctx)`; `DOC_01#1..3` y `PISTA_P2_N1` (18); `reducir_movimiento` (6); `GameClock`; posición de cámara (halo); instancias de lámparas, cristal y `B08` (4); `request_hint` (17 vía 25). `memo_leido` no tiene lector (17 no lo lee, D17-10). |
| API pública del controlador | `handle_activation()`, `evaluate()` (→ `NONE`/`PARTIAL`/`SOLVED`), `play_resolution()`, `restore_solved_presentation()`, `apply_hint_effect()` (devuelve `false`). |
| Estado que posee o persiste | Posición interna de cada lámpara (reflejo de los hechos), `progress` derivado, `progress_previo` (en el marco). Persiste `pos_L`, `pos_C`, `pos_R` y `memo_leido`; no persiste `progress`, `hint_level_reached` ni los fundidos. |
| Nodo propuesto | `P2Controller` (hereda `PuzzleController`) en la escena de planta (4), con lámparas `B01..B03`, el cristal `B04` (no interactuable) y `B08` decorado. |

Huecos P2: (a) `cobertura_anexo_a.json` (`B04` con `interactuable:false`) es un fichero planificado que hoy no existe (R1). (b) En N1 el JSON da `duration_s: 2.0` al `TEXT`, pero las reglas dicen que la duración la fija F2 de 17 (≈6 s) y que no hay `duration_s` propio. (c) Falta la validación de que `MIRROR_PREVIEW` no cae en ninguno de los 12 puntos. (d) Q12-1 (tanteo frente a deducción), Q12-2 (objetivo de F7 de 9: 3–6 min frente a 1,1–4,5 min) y Q12-8 (`VO_V_08` en la carga) siguen abiertas.
## puzle-3-encaje-de-la-foto.md (sistema 13, slug `puzzle3`)

Leído: Detailed Rules 1–27, Formulas F1–F5, Dependencies, Tuning Knobs, Acceptance Criteria, Datos del puzle.

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-puzzle3-001 (provisional) | puzle-3-encaje-de-la-foto | 13 | La entrada `P3` de `puzzles.json` usa `mode: VIEW`, `view: D01a`, `solved_flag: caja_c1`, `requires.all: []`, `validation.policy: PER_ELEMENT`, `resolution: IMMEDIATE`, `on_reopen: NO_VIEW`, sin `persist`, `needs_items`, `on_unlock` ni `TEXT` en pistas. | Data |
| TR-puzzle3-002 (provisional) | puzle-3-encaje-de-la-foto | 13 | Datos propios en `solution`: `required` (5 piezas), `map` inyectivo `piece_i→slot_i`, `empty:["D01a/slot_6"]`, `slots{center_m,size_m}`, `pieces{rest_m,size_m,row}`, `tray_rect_m`, `snap_radius_m`, `view_distance_m`, `view_center_m`, `tray_drop_verdict`, `snap_anim_s` y `t_centrar_s`. El controlador falla la validación de datos con `map` no inyectivo o `required` ≠ 5 (AC-14). | Data |
| TR-puzzle3-003 (provisional) | puzle-3-encaje-de-la-foto | 13 | `P3Controller` hereda de `PuzzleController`, solo devuelve veredictos (`NONE`, `PARTIAL`, `REJECT`, `SOLVED`; nunca `HOLDING`) y no lee ni escribe hechos. `caja_c1`, `EV_PUZZLE_SOLVED_P3` y «compartimento completado» los emite el marco. Sin hechos para las piezas. | Core |
| TR-puzzle3-004 (provisional) | puzle-3-encaje-de-la-foto | 13 | `elements()` devuelve `D01a/slot_1..6` (`atraccion` verdadero en los 6, también `slot_6`) y `D01a/piece_1..5` aún no encajadas (`atraccion` verdadero). Las encajadas salen de `elements()`. `elements_changed` se emite al agarrar, soltar y encajar. `frame`, `tray` y `NOTA_01` son decorado fuera de `elements()`. | Scene |
| TR-puzzle3-005 (provisional) | puzle-3-encaje-de-la-foto | 13 | Gestos: `agarrar` en piezas de bandeja (flujo único ratón y mando, `d_arrastre` 8 px, `elemento` fijado al pulsar) y `mantener` solo con el nivel 2 alcanzado. `seleccionar` no hace nada ni cuenta como intento. Los huecos no aceptan gestos. | Input |
| TR-puzzle3-006 (provisional) | puzle-3-encaje-de-la-foto | 13 | Al `inicio` el centro de la pieza pasa a la posición del cursor en `t_centrar_s` = 0,08 s† (instantáneo con `reducir_movimiento`); en `actualización` sigue al cursor (`delta_px` a metros con ppm). Z-orden máximo mientras se agarra. | Input |
| TR-puzzle3-007 (provisional) | puzle-3-encaje-de-la-foto | 13 | Comprobación `PER_ELEMENT` solo en `fin` de `agarrar`: encaja si `|c−p_i| ≤ r` (euclídea, borde incluido, ε=1e-6 m) y `slot_i` libre. `r` = 0,04 m (88 px) o 0,10 m (220 px) con `asistencia_encaje`. El ajuste se lee al configurar y al cambiar; un cambio con el puzle activo afecta al siguiente intento. | Core |
| TR-puzzle3-008 (provisional) | puzle-3-encaje-de-la-foto | 13 | Conversión de metros a píxeles `ppm = (H/2)/(d·tan(FOV_v/2))` con d = 0,35 m y FOV_v = 70° (2.203 ppm a H=1080; 2.448 a H=1200). El controlador trabaja en metros y 7 convierte. La validación de separación (hueco–hueco 264 px frente a 256 px asistido) avisa con ppm < 2.133. | Core |
| TR-puzzle3-009 (provisional) | puzle-3-encaje-de-la-foto | 13 | Encuadre: `view_center_m` = (0,185; 0)† materializado por el anclaje `ANC_D01A` (7 y 10); la conversión de pantalla a metros resta `view_center_m`. Debe caber todo en 16:9 y 16:10 con margen ≥0,09 m horizontal y ≥0,05 m vertical. Con `view_center_m` = (0;0) la validación debe fallar (AC-27). | Rendering |
| TR-puzzle3-010 (provisional) | puzle-3-encaje-de-la-foto | 13 | Rechazo: cualquier suelta fuera de radio, sobre otro hueco, sobre `slot_6` o en la bandeja devuelve `REJECT` con `lock: ELEMENT` (solo esa pieza), `reset_after_s` = `piece_return_s` = 0,4 s y `shake_s` 0. Las demás piezas siguen agarrables. `tray_drop_verdict` = `REJECT` por defecto; `NONE` (D13-4‡) pendiente de decisión del usuario y no se implementa hasta entonces. | Core |
| TR-puzzle3-011 (provisional) | puzle-3-encaje-de-la-foto | 13 | Encaje: `PARTIAL` con `progress` = piezas encajadas, `SFX_SNAP` 0,2 s una vez, deslizamiento a `snap_anim_s` = 0,2 s† (instantáneo con `reducir_movimiento`); una pieza encajada no se vuelve a coger. Resolución `SOLVED` en la misma suelta que encaja la quinta; `slot_6` no interviene. | Animation |
| TR-puzzle3-012 (provisional) | puzle-3-encaje-de-la-foto | 13 | Cancelación (cierre, `atrás`, pausa, pérdida de foco, `cerrar_modos()`): la pieza vuelve instantánea y en silencio a su reposo, sin `REJECT`, evaluación ni bloqueo. Todo temporizador usa `GameClock` (la pausa detiene el bloqueo de 0,4 s). | Core |
| TR-puzzle3-013 (provisional) | puzle-3-encaje-de-la-foto | 13 | `play_resolution`: `frame_lit_s` = 1,0 s de luz cálida sobre `D01a/frame` con `slot_6` iluminado igual; con `reducir_movimiento`, luz final sin transición. `close_view_after_s` 1,5 s†, regreso de cámara 0,5 s. `NOTA_01` y la tapa son de 10 (por el aviso); `I-06a` lo deriva 20. `rewards: ["I-06a"]`. | Animation |
| TR-puzzle3-014 (provisional) | puzle-3-encaje-de-la-foto | 13 | Persistencia: no se guarda el progreso parcial (sin `persist`). Cerrar y reabrir la vista conserva las piezas encajadas (`KEEP`); cargar la escena reinicia vacío salvo `caja_c1` verdadero. `restore_solved_presentation()` muestra 5 piezas encajadas, `slot_6` vacío y marco apagado, sin avisos ni sonidos; la tapa la coloca `set_final_pose(1)` de 10. | Save/Load |
| TR-puzzle3-015 (provisional) | puzle-3-encaje-de-la-foto | 13 | Tres pistas sin texto, como `AFFORDANCE` implementadas por el controlador. N1 `SLOT_SILHOUETTES` (`REQUEST`, `slot_6` con silueta sin pieza). N2 `ROW_NUMBER_ON_HOLD` (`REQUEST`; `mantener` ≥ `t_hold` 0,5 s muestra la fila 1,1,2,2,3 sin mover la pieza). N3 `CORRECT_SLOT_OUTLINE` (`IDLE` 60 s†, `condition: HELD_PIECE`, `idle_reset: GESTURE_AND_MOVE`, `idle_move_px` 40). Ninguna mueve la cámara, coloca piezas ni usa `AUTO_SOLVE_ELEMENT`. | Core |
| TR-puzzle3-016 (provisional) | puzle-3-encaje-de-la-foto | 13 | Un «hueco libre» para las pistas es solo `slot_1..5` sin su pieza; `slot_6` nunca lo es. Es el único cambio que 13 pide a la regla 25 de 9 (el destino lo decide 9 cuando se pide desde la pausa). | Core |
| TR-puzzle3-017 (provisional) | puzle-3-encaje-de-la-foto | 13 | Accesibilidad de entrada: `asistencia_encaje` (bool, falso por defecto, ajuste de 6) sube el radio a 0,10 m. El radio asistido debe ser <0,18 m para no entrar en la bandeja (x ≥ 0,24). `reducir_movimiento` hace instantáneos el centrado, el encaje, la vuelta y la luz del marco, pero conserva las duraciones de los bloqueos. | Accessibility |
| TR-puzzle3-018 (provisional) | puzle-3-encaje-de-la-foto | 13 | Pruebas en `tests/unit/puzzle_3/` con reloj falso: umbral de radio 0,039/0,040/0,041 m, 25 combinaciones incorrectas con `REJECT`, 120 permutaciones con `SOLVED` solo en la quinta, 1.000 secuencias del solucionador (AC-17), validación de separación (AC-12). Capturas retenidas del marco iluminado y del encuadre 16:9 y 16:10 (AC-21, AC-27). | Tooling |

### Contratos P3

| Campo | Contenido (nombres del GDD) |
|---|---|
| Emite | El controlador emite `elements_changed`. El marco emite por él: `caja_c1` (hecho), `EV_PUZZLE_SOLVED_P3 {rewards:[I-06a]}`, «compartimento completado» (1), «feedback de puzle» con `SFX_SNAP` y `SFX_REJECT`, «pista aplicada», `cerrar_vista(D01a,'resuelto')`. |
| Consume | `handle_pointer`/`PointerEvent` con fases `inicio`, `actualización`, `fin`, `cancelación` (7 y Entrada); `cancel_gesture`; `request_hint` → `apply_hint_effect`; ajustes `asistencia_encaje` y `reducir_movimiento` (6); ppm y F6 de 7; vista `D01a`, bandeja y `set_final_pose(1)` de 10; `GameClock`; `t_hold` de Entrada. |
| API pública del controlador | `elements()`, `elements_changed`, veredictos (`NONE`/`PARTIAL`/`REJECT`/`SOLVED`), `apply_hint_effect()` (3 `AFFORDANCE`), `restore_solved_presentation()`, `play_resolution()`. |
| Estado que posee o persiste | En memoria: conjunto `placed`, pieza agarrada, estado de los efectos de pista; `piece_return_s` y bloqueo `ELEMENT` los gestiona el marco. No persiste nada propio; solo `caja_c1` y las causas `compartment_done:1` y `puzzle_solved:P3` (5). |
| Nodo propuesto | `P3Controller` (hereda `PuzzleController`) como controlador de la vista `D01a` de la caja (10), con anclaje `ANC_D01A` desplazado a `view_center_m`. |

Huecos P3: (a) Decisión del usuario pendiente D13-4‡ (`tray_drop_verdict` REJECT o NONE). (b) `snap_radius_m` y `view_distance_m` van en `solution` (‡), a confirmar con 9. (c) El JSON mezcla `assist` (`setting`, `snap_radius_m` 0,10) con `solution.snap_radius_m`, y la definición del campo no está fijada. (d) El margen de separación asistida es de solo 8 px (264 frente a 256) y depende de V2 de 7 (FOV 70° sin verificar). (e) Contradicción del slice sobre el número de fila (siempre visible o solo en `mantener`): se resolvió con N2 oculto (D13-11, OQ-8). (f) El anclaje `ANC_D01A` y el catálogo de 7 y 10 figuran como «Cambios requeridos».

## NO LEÍDO

- Los tres GDDs: no se leyeron Summary, Overview, Player Fantasy, Edge Cases, Decisiones tomadas, Open Questions, Cambios requeridos en otros GDDs, Entradas para el registro ni Historial.
- P1: las líneas 256–297 (Edge Cases). P2: las líneas 209–233 (Edge Cases). P3: las líneas 153–176 (Edge Cases).
- P2: Visual/Audio Requirements sí leído. P1: no tiene esa sección.
- Todo lo que dicen sobre el marco `marco-de-puzles.md`: no se abrió (las reglas citadas, como regla 4b, 12, 14 o 25 de 9, no se verificaron).
- Los GDDs de 7, 10, 17, 18, 19 y 20 que referencian los tres puzles tampoco se abrieron.

---

<!-- bloque G7 -->
# TR baseline G7 (puzle 4, 5, 6)

## puzle-4-tablero-de-tareas.md (sistema 14, slug puzzle4)

Leído: Detailed Rules (R1-R20), Formulas (F1-F5), Dependencies, Tuning Knobs, Acceptance Criteria, Datos del puzle. No leído: Edge Cases, Decisiones, Open Questions, Cambios requeridos, Entradas para el registro.

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-puzzle4-001 (provisional) | puzle-4-tablero-de-tareas.md | 14 | La entrada `P4` de `assets/data/puzzles/puzzles.json` (schema_version 2) declara mode VIEW, view `D01b`, policy `PER_ELEMENT`, resolution `IMMEDIATE`, on_reopen `NO_VIEW`, requires.all vacío, persist `[]`; la validación (regla 29 de 9) exige que el estado inicial no satisfaga la solución | Data |
| TR-puzzle4-002 (provisional) | puzle-4-tablero-de-tareas.md | 14 | La vista expone 28 elementos señalables (4 fichas x [3 urgencia + 3 responsable + return]) más 4 `Tn/body` y `D01b/rule` no interactivo, con IDs `D01b/Tn/{urg_alta,urg_media,urg_baja,resp_vera,resp_guardian,resp_direccion,return}`, ≥ `pick_min_px` 44 px y separación entre centros ≥ 128 px (`element_zones[].min_separation_px`, R=64) | Input |
| TR-puzzle4-003 (provisional) | puzle-4-tablero-de-tareas.md | 14 | Los selectores son segmentos siempre visibles (no desplegables); único gesto `seleccionar` (`agarrar`, `rotar`, `mantener` se ignoran); una combinación completa = 2 `seleccionar`, «Devolver» = 1 | Input |
| TR-puzzle4-004 (provisional) | puzle-4-tablero-de-tareas.md | 14 | Estado por ficha en memoria `{urgencia ∈ nula/Alta/Media/Baja, responsable ∈ nulo/Vera/Guardián/Dirección, devuelta:bool, bloqueada:bool}`; un selector solo = sin evaluación y se conserva al salir/cancelar durante la sesión de escena | Core |
| TR-puzzle4-005 (provisional) | puzle-4-tablero-de-tareas.md | 14 | `evaluate()` por ficha (`PER_ELEMENT`) se dispara al completar los 2 selectores o `devuelta`; devuelve `PARTIAL`, `REJECT` (solo T1-T3), `SOLVED` o `NONE`; una ficha bloqueada no se reevalúa y sus elementos no producen sonido, cambio ni aviso | Core |
| TR-puzzle4-006 (provisional) | puzle-4-tablero-de-tareas.md | 14 | `PARTIAL` debe transportar `{element:"Tn", action: ASSIGN\|RETURN}` (cambio requerido en 9); `on_partial.stamp_text_keys` mapea por `action` a `UI_P4_SELLO_ACEPTADA`/`UI_P4_SELLO_DEVUELTA` | Events |
| TR-puzzle4-007 (provisional) | puzle-4-tablero-de-tareas.md | 14 | Solución T1-T3 como datos (`solution.Tn.{accept:[ASSIGN], urgency, owner}`: HIGH/VERA, MEDIUM/GUARDIAN, LOW/DIRECTION); 1 acierto y 9 `REJECT` por ficha de las 10 acciones | Data |
| TR-puzzle4-008 (provisional) | puzle-4-tablero-de-tareas.md | 14 | `REJECT` (T1-T3, `lock: NONE`): `SFX_REJECT`, ficha a neutra al instante, mensaje `UI_P4_NO_CORRESPONDE` 1,5 s (`message_s`), vibración `shake_s` 0,4 s, reedición inmediata en el fotograma siguiente; sin contador ni escritura de hechos ni reset de otras fichas | UI |
| TR-puzzle4-009 (provisional) | puzle-4-tablero-de-tareas.md | 14 | Con «reducir movimiento» (ajuste 6) la vibración se sustituye por cambio de tono estático de la misma duración (0,4 s) | Accessibility |
| TR-puzzle4-010 (provisional) | puzle-4-tablero-de-tareas.md | 14 | T4 acepta `{accept:[RETURN, ASSIGN]}` (no editable): el controlador nunca devuelve `REJECT` para T4 en ninguna de las 10 acciones; sin `SFX_REJECT` ni «No corresponde» | Core |
| TR-puzzle4-011 (provisional) | puzle-4-tablero-de-tareas.md | 14 | Sello al aceptar: `SFX_STAMP` + sello sobre la ficha + bloqueo; la animación, el sonido y el registro visual (sin rojo/verde moral) son idénticos para las dos salidas de T4, difiere solo la palabra; duración `stamp_s` fijada por 23 | Rendering |
| TR-puzzle4-012 (provisional) | puzle-4-tablero-de-tareas.md | 14 | El controlador guarda `t4_action ∈ {RETURN, ASSIGN}` solo en memoria; los selectores de una T4 `ASSIGN` no se guardan ni se leen (D9-40); no sobrevive a guardar/cargar con `caja_c2` falso | Core |
| TR-puzzle4-013 (provisional) | puzle-4-tablero-de-tareas.md | 14 | `SOLVED` (T1-T3 aceptadas y T4 decidida) lleva `t4_action`; 9 escribe en el mismo fotograma y en orden: `t4_decision` (`returned`/`assigned` vía `value_from`/`map`), `caja_c2`=true, estado RESUELTO, `EV_PUZZLE_SOLVED_P4 {puzzle:P4, rewards:[I-05]}`, «compartimento completado» (2), feedback; `t4_decision` es de un solo sentido y no se escribe al decidir T4 | Events |
| TR-puzzle4-014 (provisional) | puzle-4-tablero-de-tareas.md | 14 | El controlador P4 no escribe hechos ni emite avisos (AC-14-18, comprobable por revisión estática o estado de solo lectura); `t4_decision` solo lo lee 22, sin efecto sobre puzles, puertas, ítems, cartas o finales y sin texto/sonido de «elección recordada» | Core |
| TR-puzzle4-015 (provisional) | puzle-4-tablero-de-tareas.md | 14 | Carga: con `caja_c2`=true P4 RESUELTO en silencio, `restore_solved_presentation()` llama `set_final_pose(2)` de 10 y sella las 4 fichas (T4 «DEVUELTA» si `returned`, «ACEPTADA» si `assigned`, «ACEPTADA» con `t4_decision` sin fijar); con `caja_c2`=false fichas neutras (el parcial no se persiste) y `t4_decision` previo no se reescribe, escritura contradictoria rechazada con error de datos sin excepción y escritura idéntica idempotente | Save/Load |
| TR-puzzle4-016 (provisional) | puzle-4-tablero-de-tareas.md | 14 | Pista 3 `AUTO_SOLVE_ELEMENT` solo sobre `D01b/T1` pasa por `evaluate()`, nunca toca T4; pista 2 `AFFORDANCE HOVER_HIGHLIGHT` en `Tn/body` (`ON_HINT`) y el movimiento del cursor no cuenta como inactividad; pista 1 `TEXT` `PISTA_P4_N1` siempre visible (misma clave que `D01b/rule`); ninguna pista usa `IDLE`; 3 niveles exactos | UI |
| TR-puzzle4-017 (provisional) | puzle-4-tablero-de-tareas.md | 14 | Procesar en orden de llegada eventos en el mismo fotograma (`PARTIAL` luego `SOLVED`); un segundo `SOLVED` (p. ej. por pista nivel 3) se descarta con una sola tanda de escrituras (S9 de 9) | Events |
| TR-puzzle4-018 (provisional) | puzle-4-tablero-de-tareas.md | 14 | Cierre: 9 pide `cerrar_vista('D01b','resuelto')` a `close_view_after_s` 1,5 s tras `SOLVED`, regreso de cámara 0,5 s; sin temporizador, límite de intentos ni evento por inactividad (sin `*_timeout`/`max_attempts` en datos) | Scene |

(18 filas: se excede el tope de ~15 por atomicidad de 013/015.)

Nota de lectura P4: `t4_decision` no se escribe al decidir T4 sino al resolver (R13). Hueco: `view_distance_m` de D01b pendiente (Open Question 1); maquetación de la vista de ux/arte.

## puzle-5-espejo-de-la-diferencia.md (sistema 15, slug puzzle5)

Leído: Detailed Rules (reglas 1-29), Formulas (F-P5-1..5), Dependencies, Tuning Knobs, Acceptance Criteria, Datos del puzle. No leído: Edge Cases, Decisiones, Open Questions, Cambios requeridos, Entradas para el registro.

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-puzzle5-001 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Entrada `P5` en `puzzles.json` (schema_version 2): mode VIEW, view `D01c`, `solved_flag` `caja_c3`, `requires.all`=[`caja_c1`], policy `SUSTAINED`, resolution `DEFERRED` con `resume_flag` `pendiente_revelacion`, `on_reject` null, `persist`=[`pendiente_revelacion`], `on_reopen` `NO_VIEW`; enteros (`level`, `ajar_cm`, `compartment`, `theta_*_deg`, `mark_step_deg`) como int y `tol_deg`, `hold_s`, `settle_s`, `duration_s` como float | Data |
| TR-puzzle5-002 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | `P5Controller` expone θ, `evaluate()`, `apply_hint_effect()`, `restore_solved_presentation()`, `play_resolution(step)`; `evaluate()` es función pura de θ y devuelve solo `HOLDING` (si abs(θ-θ*) <= tol) o `NONE`, nunca `PARTIAL`/`REJECT`/`SOLVED` | Core |
| TR-puzzle5-003 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | `elements()` = [`D01c/frame`] (único interactivo, `rotar`, `atraccion` falso); `D01c/reflection`, `box_photo`, `marks` (19 marcas cada 5°, sin cifras), `mark_40`, `speaker` son elementos visuales declarados en `solution.visual_elements` y fuera del catálogo de 7 | Input |
| TR-puzzle5-004 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Gesto `rotar` (fases `inicio/actualización/fin/cancelación`) acumula `delta_grados` (ratón 0,25°/px; mando velocidad angular x Δt) a θ, limitado a [0°, 90°] sin envoltura; admite modo «alternar» | Input |
| TR-puzzle5-005 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | θ parte de `theta_initial_deg`=0°, se conserva al cerrar la vista durante la sesión de escena (`KEEP`), no se guarda en disco: tras cargar vuelve a 0° | Save/Load |
| TR-puzzle5-006 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Tolerancia `tol_deg` 3° (6° con ajuste `asistencia_rotacion` de 6); el cambio aplica al siguiente gesto; restricción de datos: θ*±tol_asistida dentro de [0,90] y θ_initial fuera de la ventana asistida | Accessibility |
| TR-puzzle5-007 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | El marco llama `evaluate()` cada fotograma y acumula `min(dt, dt_max=0,1 s)` mientras `HOLDING` seguido; `SOLVED` a `hold_s`=0,8 s; acumulador a 0 con `NONE`, `on_close` y `cancelación`; v_max = W/hold_s = 7,5°/s (30 px/s) normal, 15°/s asistido | Core |
| TR-puzzle5-008 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Reflejo puramente geométrico: la foto de `D04` rota con θ sobre la foto de la caja completa de P3 (recurso reutilizado de 13); sin ayuda de coherencia ni sonido en `HOLDING`; Vera debe ocupar la posición del hueco S6 en el reflejo (requisito de contenido para 13/arte) | Rendering |
| TR-puzzle5-009 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Inicio de la revelación, mismo fotograma y orden: `cancel_gesture()` silencioso si hay `rotar` activo; θ=θ* con tween `theta_settle_s` 0,3 s (instantáneo con `reducir_movimiento`); el marco escribe `pendiente_revelacion`=true y entra en `RESOLVING`; entrada bloqueada salvo `atrás` | Core |
| TR-puzzle5-010 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Secuencia de 3 pasos por reloj de juego (`GameClock`): `FADE` `OVERLAY_FADE` 0,0-1,2 s (superpone el reflejo de D04 a la foto de la caja), `OUTLINE` 1,2-2,0 s (contorno solo sobre la silueta de Vera), `LINE` desde 2,0 s hasta 16,0 s nominal con la imagen fija | Animation |
| TR-puzzle5-011 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | `LINE`: `VO_G_07` suena desde `SPK_D01C` (audio 3D de 10); subtítulo de 26 durante `fallback_s` 14,0 s; el paso dura hasta el fin de línea o `fallback_s`+`line_grace_s` 2,0 s; fallo/ausencia/señal perdida no interrumpen; T_seq entre 2,0+t_línea y 18,0 s, nominal 16,0 s; sin sonido de acierto | Audio |
| TR-puzzle5-012 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | La revelación no muestra texto, flecha, etiqueta, destello, zoom, movimiento de cámara ni música; el contorno se distingue por forma y luminancia (legible en escala de grises), sin rojo/verde moral; color y brillo del art bible; el dibujo del contorno es de 29 (shaders) | Rendering |
| TR-puzzle5-013 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Fin de secuencia: 9 escribe en orden `caja_c3`=true, `pendiente_revelacion`=false, RESUELTO, `EV_PUZZLE_SOLVED_P5` con `rewards` vacío, «compartimento completado» (3); a `close_view_after_s` 1,5 s `cerrar_vista('D01c','resuelto')`, cámara vuelve en 0,5 s; el controlador no recibe referencia de escritura | Events |
| TR-puzzle5-014 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Interrupción solo por salida de la vista (`atrás`, `cerrar_modos()`, descarga): detiene la secuencia, 23 corta la línea con fundido, se emite «resolución de puzle interrumpida», `caja_c3` false, `pendiente_revelacion` true, puzle `ACTIVO`/`IDLE`, 10 deja C3 `ENTREABIERTO`; la pausa solo detiene el reloj y retiene señales de 23 | Events |
| TR-puzzle5-015 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Reapertura/carga con `pendiente_revelacion` true y `caja_c3` false: el marco salta la comprobación, θ=θ* sin tween y la secuencia reinicia desde 0 s (hasta 18,0 s por intento, sin límite); ambos true: RESUELTO y limpieza silenciosa del hecho; `caja_c3` true: `restore_solved_presentation()` con `set_final_pose(3)` y marco a θ* sin sonido; guardado con causa `reveal_pending` | Save/Load |
| TR-puzzle5-016 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Pistas, 3 niveles todos `REQUEST` sin `IDLE`: N1 `TEXT PISTA_P5_N1` + `HIGHLIGHT` de `D01c/reflection` 3,0 s; N2 `PISTA_P5_N2` + `HIGHLIGHT` de reflection y box_photo 3,0 s; N3 `AFFORDANCE MARK_LIT` de `D01c/mark_40`, persistente en la sesión, sin mover el marco ni resolver; `request_hint` en `RESOLVING` se ignora y no cuenta nivel | UI |
| TR-puzzle5-017 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Con `reducir_movimiento`: `FADE` y `OUTLINE` a 100 ms fijos (`fade_reduced_ms`) conservando los `duration_s`, θ recolocada al instante, T_seq inalterada; un cambio con la secuencia en curso aplica al siguiente paso o apertura; 15 no lee `reducir_sobresaltos` y no hay destellos ni cambios bruscos de luminancia | Accessibility |
| TR-puzzle5-018 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Al activarse por `caja_c1`, 9 emite «puzle activado» con `ajar_cm`=2 y suena `SFX_UNLOCK_SOFT` una vez; 10 anima el entreabierto de 2 cm y no cierra la tapa de C3 durante la secuencia | Animation |
| TR-puzzle5-019 (provisional) | puzle-5-espejo-de-la-diferencia.md | 15 | Solicitud provisional a 23 de lazo `SFX_FRAME_TURN` (madera/metal) con volumen según velocidad de giro, que cesa al terminar o cancelar el gesto; el puzle funciona sin él | Audio |

(19 filas: se excede ~15 por la secuencia de 16 s y la persistencia, que son el núcleo del puzle.) Huecos P5: ID `SFX_FRAME_TURN` provisional; quién resuelve el entreabierto con `reducir_movimiento` (10 asumido); atenuación del golpe de puerta de `VO_G_07` con `reducir_sobresaltos` (23); lectura de F7 de 9 con revelación incluida (D15-7).

### Contratos P5

| Campo | Valor |
|---|---|
| Emite | Nada (regla 3: no escribe hechos ni emite avisos). Veredictos `HOLDING`/`NONE` a 9. 9 emite «puzle activado» (`ajar_cm`=2), `SFX_UNLOCK_SOFT`, «resolución de puzle interrumpida», `EV_PUZZLE_SOLVED_P5` (rewards vacío), «compartimento completado» (3), «línea pedida» (`VO_G_07`), `cerrar_vista('D01c','resuelto')`; petición a 23 de `SFX_FRAME_TURN` |
| Consume | Hechos `caja_c1`, `caja_c3`, `pendiente_revelacion` (vía 9); `asistencia_rotacion`, `reducir_movimiento` (6); `rotar`/`delta_grados` y `cancel_gesture()` (7); `GameClock` (regla 36 de 9); `SPK_D01C`, vista `D01c`, `set_final_pose(3)`, `BOX_C3_OPEN`/`BOX_C3_CLOSE` (10); señales de línea de 23; subtítulo de 26; claves `PISTA_P5_N1`, `PISTA_P5_N2` (18); foto de la caja completa (13) y foto `D04` |
| API pública del controlador | `P5Controller`: θ, `evaluate()`, `apply_hint_effect()`, `restore_solved_presentation()`, `play_resolution(step)` |
| Estado que posee o persiste | Posee en memoria: θ (conservado en la sesión de escena, 0° tras carga), nivel de pista alcanzado (monótono), marca `MARK_LIT`. Persiste solo (vía 9/5) `pendiente_revelacion` (causa `reveal_pending`) y `caja_c3` |
| Nodo propuesto | `P5Controller` bajo la vista `D01c` (escena de 10) con `D01c/frame` interactivo y nodos visuales `reflection`, `box_photo`, `marks`, `mark_40`, `speaker` (anclado a `SPK_D01C`); datos en `puzzles.json` entrada `P5` |

## puzle-6-decision.md (sistema 16, slug puzzle6)

Leído: Detailed Rules (reglas 1-25), Formulas (F1-F3), Dependencies, Tuning Knobs, Acceptance Criteria, Datos del puzle. No leído: Edge Cases, Decisiones, Open Questions, Cambios requeridos, Entradas para el registro.

| ID | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-puzzle6-001 (provisional) | puzle-6-decision.md | 16 | Entrada `P6` en `puzzles.json` (schema_version 2): mode VIEW, view `D01d`, `solved_flag` `caja_c4`, `requires.all`=[`caja_c1`,`caja_c2`,`caja_c3`], policy `ON_CHOICE`, resolution `IMMEDIATE`, `on_reject` null, `on_reopen` `NO_VIEW`, `close_view_after_s` null, sin `ajar_cm` | Data |
| TR-puzzle6-002 (provisional) | puzle-6-decision.md | 16 | `Puzzle6Controller` hereda de `PuzzleController` y solo devuelve veredictos (`SOLVED` con `choice` ∈ {A,B,C}); no escribe hechos, no emite avisos ni llama a 3; si devolviera `REJECT` el marco lo trata como `NONE` con error de datos | Core |
| TR-puzzle6-003 (provisional) | puzle-6-decision.md | 16 | `elements()` = exactamente `D01d/button_A`, `D01d/button_B`, `D01d/button_C` (A «Estoy bien», B «La verdad», C «Todavía no»), los tres `atraccion`=true, misma forma y tamaño, equidistantes (≥128 px, R=64), sin foco ni preselección inicial; la zona no declara `atraccion_desactivada` | Input |
| TR-puzzle6-004 (provisional) | puzle-6-decision.md | 16 | Compromiso `commit_on` = `SELECT_END_SAME_ELEMENT`: acepta `seleccionar` (inicio y fin en el mismo fotograma, al soltar) cuyo `elemento_bajo` coincide con `elemento` pulsado; arrastre (`agarrar`), `cancelación` y clic en vacío no eligen (el clic en vacío sí reinicia `idle`); depende de que 7 defina `elemento_bajo` para `seleccionar` | Input |
| TR-puzzle6-005 (provisional) | puzle-6-decision.md | 16 | Una sola elección: el primer botón aceptado fija `SOLVED`; en el mismo fotograma gana el primero que llega al marco (S9), los otros dos botones quedan inertes sin sonido ni `REJECT` | Core |
| TR-puzzle6-006 (provisional) | puzle-6-decision.md | 16 | `carta_variante` = opción pulsada (`value_from: "choice"`, sin `map`: `A`/`B`/`C`) e independiente de `t4_decision` y `respuesta_llamada`; es hecho de un solo sentido, nunca toma `D`; solo cambia `VO_G_12A/B/C` (22) y el primer fragmento de `I-07` (20) | Events |
| TR-puzzle6-007 (provisional) | puzle-6-decision.md | 16 | Orden de escritura de 9 en el mismo fotograma: `carta_variante`, `caja_c4`=true, recálculo de `caja_completa` (lo escribe el estado, no 9 ni 16), estado `RESUELTO`, `EV_PUZZLE_SOLVED_P6 {puzzle:P6, rewards:[I-07], choice}`, «compartimento completado» (4), presentación; ninguna escritura espera a la presentación | Events |
| TR-puzzle6-008 (provisional) | puzle-6-decision.md | 16 | Presentación no bloqueante, `on_solved.presentation`: t=0 `SFX_LOCK_CLICK` (0,3 s), t=0,3 s `play_open(4)` de 10 (`BOX_C4_OPEN` 1,6 s†, `FINAL_ABIERTO`), carta plegada visible a t=1,9 s; sin stinger, luz, sonido de «caja completa» ni cierre automático de la vista | Animation |
| TR-puzzle6-009 (provisional) | puzle-6-decision.md | 16 | `request_reading {doc:"I-07", at_s:1.9}`: el marco pide `abrir_lectura(I-07)` a 7 al final de la presentación; `ACEPTADA` apilada con la vista abierta, `APLAZADA` hasta `exploración` estable (tope 3 s de tiempo de juego, luego se descarta y la carta queda en el bolsillo); un `atrás` en la salida no es `repasar_bolsillo`; 9 no reintenta ni cancela | UI |
| TR-puzzle6-010 (provisional) | puzle-6-decision.md | 16 | Pistas `IDLE` de 2 niveles solo `TEXT` (`PISTA_P6_N1` a `idle_s`=10 s†, `PISTA_P6_N2` a 20 s†, rango 5-60 s con N1<N2), `availability: ALWAYS`, ambas medidas desde la misma última acción; sin `PISTA_P6_N3`, sin `HIGHLIGHT`/`AFFORDANCE`/`AUTO_SOLVE_ELEMENT`, textos que no nombran opción alguna | UI |
| TR-puzzle6-011 (provisional) | puzle-6-decision.md | 16 | `idle_reset` = `PRESS_ONLY`: `idle` solo se reinicia con un `seleccionar` recibido (incluido clic en vacío), no con mover cursor, stick ni pausa; `idle` se mide con reloj de juego y la pausa lo congela | Core |
| TR-puzzle6-012 (provisional) | puzle-6-decision.md | 16 | `hint_level_reached` ∈ {0,1,2} monótono solo en memoria; al reabrir la vista `idle` vuelve a 0, se rearman los niveles superiores y el texto del nivel más alto alcanzado se reaplica una vez; `request_hint` desde la pausa cuenta como alcanzar el nivel (consume su umbral), muestra al reanudar y se rechaza con P6 `RESUELTO`; `idle_hints_auto_apply` verdadero† hasta que exista 17 | Core |
| TR-puzzle6-013 (provisional) | puzle-6-decision.md | 16 | Carga con `caja_c4` true: P6 `RESUELTO`, `restore_solved_presentation()` llama `set_final_pose(4)` (tapa abierta con carta plegada, idempotente, sin animación ni sonido), sin avisos ni `abrir_lectura` ni pistas; con `caja_c4` false: `ACTIVO`/`BLOQUEADO` en silencio con estado en memoria vacío; guardado con causas `puzzle_solved:P6` y `compartment_done:4` tras vaciarse la cola de avisos | Save/Load |
| TR-puzzle6-014 (provisional) | puzle-6-decision.md | 16 | Reapertura tras resolver: `NO_VIEW` (10 responde `SIN_EFECTO` y suena `SFX_CLICK_SUBTLE`, sin movimiento de cámara); no existe deshacer; `I-07` queda en el bolsillo derivada de `caja_c4` y `carta_variante` por 20 y se relee con `repasar_bolsillo`; `atrás` cierra la carta y otro `atrás` la vista | Scene |
| TR-puzzle6-015 (provisional) | puzle-6-decision.md | 16 | Acceso: en `BLOQUEADO` 10 devuelve `SIN_EFECTO` (`get_view_gate('D01d')` = `BLOCKED`); al activarse solo suena `SFX_UNLOCK_SOFT`, C4 no se entreabre; `D01d` se abre sin apertura previa de tapa (botones y cerradura en el frontal) | Scene |
| TR-puzzle6-016 (provisional) | puzle-6-decision.md | 16 | P6 no lee `reducir_movimiento` ni `reducir_sobresaltos`: presentación y `t_carta`=1,9 s idénticas con cualquier ajuste y un cambio durante la presentación no tiene efecto; sin destellos, parpadeo ni sobresalto sonoro | Accessibility |
| TR-puzzle6-017 (provisional) | puzle-6-decision.md | 16 | Sin confirmación ni medidor: ningún diálogo «¿seguro?», aviso previo de definitividad, hecho/ítem/línea de moralidad ni diferencia visible o audible entre variantes de la caja; el panel no codifica bueno/malo (sin rojo/verde moral) | UI |

(17 filas.) Huecos P6: `elemento_bajo` de `seleccionar` aún no especificado en 7; claves de textos de los botones pendientes de nombre en 18; permanencia de la elección frente a «cerrar antes de guardar» (Open Question 12, no decidido); aspecto del panel (arte, OQ 6); recuento de palabras de la carta sin fuente (21-25).

### Contratos P6

| Campo | Valor |
|---|---|
| Emite | Nada (regla 11). Veredicto `SOLVED{choice}` a 9. 9 emite «puzle activado» (P6), «puzle inactivo» (nivel 1/2), `EV_PUZZLE_SOLVED_P6 {puzzle:P6, rewards:[I-07], choice}`, «compartimento completado» (4); sonidos `SFX_UNLOCK_SOFT`, `SFX_LOCK_CLICK`; llamadas `play_open(4)` (10) y `abrir_lectura(I-07)` (7) |
| Consume | Hechos `caja_c1`, `caja_c2`, `caja_c3` (`requires.all`); `seleccionar`/`elemento_bajo` (7); `GameClock` (regla 36 de 9); `play_open(4)`, `set_final_pose(4)`, `ANC_D01d`, nodos de botones, `SIN_EFECTO` (10); claves `PISTA_P6_N1`, `PISTA_P6_N2` y textos de botones (18); `request_hint(P6, n)` (17/25) |
| API pública del controlador | `Puzzle6Controller` (hereda `PuzzleController`): `evaluate()`/veredicto `SOLVED{choice}`, `elements()`, `play_resolution`, `restore_solved_presentation()` |
| Estado que posee o persiste | Posee en memoria: ningún botón elegido, `idle`, `hint_level_reached`. Persiste (vía 9/3/5): `caja_c4` y `carta_variante`; la elección no existe hasta guardarse la resolución |
| Nodo propuesto | `Puzzle6Controller` bajo la vista `D01d` (de 10) con tres nodos de botón `button_A/B/C` colgando de los nodos de la caja; datos en `puzzles.json` entrada `P6` |

## NO LEÍDO

- Edge Cases, Decisiones tomadas, Open Questions, Cambios requeridos en otros GDDs, Entradas para el registro e Historial de los tres GDD; Summary/Overview/Player Fantasy.
- `design/gdd/marco-de-puzles.md` (no abierto: el esquema v2, S7, S9, reglas 12-27 se citan por referencia de los GDD).

### Contratos P4

| Campo | Valor |
|---|---|
| Emite | Nada directamente (R17). Devuelve a 9 los veredictos `PARTIAL{element,action}`, `REJECT`, `SOLVED{t4_action}`, `NONE`. 9 emite `EV_PUZZLE_SOLVED_P4 {puzzle:P4, rewards:[I-05]}`, «compartimento completado» (2), «feedback de puzle», «pista aplicada»; sonidos `SFX_STAMP`, `SFX_REJECT` |
| Consume | `get_view_gate('D01b')`/`BOX_C2_OPEN` (10); `set_final_pose(2)` (10); `PointerEvent`/`seleccionar`, `elements()`, `pick_min_px` (7); hecho `caja_c2` y `t4_decision` (3, escritos por 9); `request_hint(P4, n)` (17); `reducir_movimiento` (6); `GameClock` (36); claves de 18: `PISTA_P4_N1`, `PISTA_P4_N3`, `UI_P4_SELLO_ACEPTADA`, `UI_P4_SELLO_DEVUELTA`, `UI_P4_NO_CORRESPONDE`, `DOC_LISTA_TAREAS` |
| API pública del controlador | `PuzzleController` de 9: `evaluate()`, `elements()`, `restore_solved_presentation()`, aplicación de pistas (`request_hint(P4, n)` vía 9) |
| Estado que posee o persiste | Posee en memoria: estado por ficha (urgencia, responsable, devuelta, bloqueada) y `t4_action`. Persiste: nada propio (`persist: []`); `caja_c2` y `t4_decision` los persiste 3/5 (causa `compartment_done:2`) |
| Nodo propuesto | `PuzzleController` de P4 como hijo de la vista `D01b` (escena de 10), más datos en `puzzles.json` (entrada `P4`); 20 deriva `has_item('I-05')` de `caja_c2` |


---

<!-- bloque G8 -->
# TR baseline g8 (17 hints, 24 prompt, 25 pause)

Nota: los GDD nombran los avisos en español entre comillas («pista aplicada»); no dan ID `EV_*` para ellos (se declaran en la regla 10 de 3). Se usan tal cual.

## Sistema 17 — sistema-de-pistas.md (slug `hints`)

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-hints-001 (provisional) | sistema-de-pistas.md | 17 | `HintService` es un servicio inyectado, sin singleton/autoload de estado, con `HintLedger` (registro en memoria) y `HintPanel` (UI); no escribe hechos ni emite avisos propios (salvo «sonido pedido») | Core |
| TR-hints-002 (provisional) | sistema-de-pistas.md | 17 | Estado por puzle solo en memoria: `applied` (conjunto de niveles), `t_ref` (instante GameClock o −∞), `last_applied`, `notes` (lista ordenada de claves `PISTA_*`), `pending_text` (≤1 clave por puzle) | Data |
| TR-hints-003 (provisional) | sistema-de-pistas.md | 17 | `hint_level_reached` sigue siendo propiedad de 9 (monótono); 17 no lo duplica ni guarda | Data |
| TR-hints-004 (provisional) | sistema-de-pistas.md | 17 | 17 no guarda nada: sin hecho nuevo en el catálogo de 3 ni causa de guardado en 5; tras guardar/cargar `applied`, `notes`, `t_ref` quedan vacíos | Save/Load |
| TR-hints-005 (provisional) | sistema-de-pistas.md | 17 | El registro se vacía (`applied=∅`, `notes=[]`, `t_ref` indefinido) y la lista se rehace en cada «puzles configurados» de 9 (carga, nueva partida, carga de escena de planta) | Events |
| TR-hints-006 (provisional) | sistema-de-pistas.md | 17 | Un puzle se lista solo si `ACTIVO`/`RESOLVING`, tiene ≥1 nivel en `get_hints(id)` y cumple `discover_if` (`COMMITMENT` vía último compromiso de `list_puzzles()`, `FIRST_ACTION` vía `first_action` ‡ nuevo en 9, o hecho `correos_leidos`) | Core |
| TR-hints-007 (provisional) | sistema-de-pistas.md | 17 | `list_puzzles()` debe exponer estado, `mode`, vista, último compromiso, `hint_level_reached` y `first_action` ‡ (cambio requerido en 9) | Data |
| TR-hints-008 (provisional) | sistema-de-pistas.md | 17 | Orden fijo P1–P6; estados vacíos distintos: `UI_PISTAS_NADA` (ningún puzle ACTIVO/RESOLVING) vs `UI_PISTAS_SIN_LISTA` (hay ACTIVO sin listado); preselección: vista abierta > compromiso más reciente > primero | UI |
| TR-hints-009 (provisional) | sistema-de-pistas.md | 17 | Pedir = siempre el menor nivel `k` ∈ 1..N (N=3; 2 en P6) no presente en `applied`; el jugador no elige nivel | Core |
| TR-hints-010 (provisional) | sistema-de-pistas.md | 17 | Validación en orden estricto devolviendo `HintResult` (`BUSY`, `COMPLETE`, `WAIT`, `REJECTED`, `APPLIED`); `applied/last_applied/t_ref` cambian solo si `request_hint` devuelve `true` | Core |
| TR-hints-011 (provisional) | sistema-de-pistas.md | 17 | Espera F1 `espera=max(0, gap(p,k)−(t_ahora−t_ref))` evaluada al abrir el panel y por pulsación (no por fotograma), con `GameClock` (parado en pausa); `gap` 0/20/40 s (P6: 10 s) desde datos | Core |
| TR-hints-012 (provisional) | sistema-de-pistas.md | 17 | El `GameClock` de 9 se detiene en pausa: 25 debe pausarlo sin afectar a la UI del panel (que funciona en pausa) | Core |
| TR-hints-013 (provisional) | sistema-de-pistas.md | 17 | `request_hint(id, level)` de 9 debe soportar reaplicación («Repetir» con `last_applied`): repite solo la presentación, sin cambiar `hint_level_reached`, sin `AUTO_SOLVE_ELEMENT` ni `evaluate()` (cambio requerido en 9, punto 3) | Core |
| TR-hints-014 (provisional) | sistema-de-pistas.md | 17 | `idle_hints_auto_apply` de 9 se entrega en falso mientras 17 exista; 17 se suscribe a «puzle inactivo» `(id, nivel)` y llama `request_hint` sin comprobar espera; 9 debe volver a emitirlo si la `condition` se cumple tras vencer el umbral; 9 debe funcionar sin 17 | Events |
| TR-hints-015 (provisional) | sistema-de-pistas.md | 17 | «pista aplicada» lleva `(id, nivel, text_key)` (`text_key` nulo sin `TEXT`); 9 aplica efectos no textuales y delega el `TEXT` en 17, único que muestra la nota (una por aplicación) | Events |
| TR-hints-016 (provisional) | sistema-de-pistas.md | 17 | `HintNote`: una nota a la vez, cola de `queue_max`=1 (gana la más reciente), sustitución tras `note_min_s` con fundido cruzado, fundido `note_fade_s` 0,3 s, reloj GameClock; no bloquea entrada ni cursor | UI |
| TR-hints-017 (provisional) | sistema-de-pistas.md | 17 | Duración F2 `clamp(n_palabras/3,0+1,0; 3,0; 8,0)` s con `n_palabras` contadas por espacios al cargar (y recalculadas al cambiar idioma/escala); `duration_s` del dato manda | Localization |
| TR-hints-018 (provisional) | sistema-de-pistas.md | 17 | Las notas de puzles `VIEW` se muestran solo con su vista abierta (avisos «vista cercana abierta/cerrada» de 7); si no, `pending_text`; se descartan al cerrar vista, `RESUELTO` o reset; P6 reaplica una vez la nota más alta al reabrir | Events |
| TR-hints-019 (provisional) | sistema-de-pistas.md | 17 | Datos en `assets/data/hints_policy.json` (`schema_version: 1`, `defaults`, `puzzles` con `label_key`, `discover_if`, `gap_s`, `reapply_text_on_reopen`); validar al cargar que `label_key` existen en 18 | Data |
| TR-hints-020 (provisional) | sistema-de-pistas.md | 17 | Panel accesible solo con `ui_*` (contexto `menú` de 1) en teclado, ratón y mando; sin mantener ni precisión; espera indicada con botón apagado + texto, sin animación de relleno | Accessibility |
| TR-hints-021 (provisional) | sistema-de-pistas.md | 17 | Clave `PISTA_*` ausente en runtime: no mostrar nada, registrar error y NO añadir el nivel a `applied`; 17 no cuenta ni expone nº de pistas (sin telemetría/logros) | Core |
| TR-hints-022 (provisional) | sistema-de-pistas.md | 17 | Lee `correos_leidos` vía 3 (sin escribir hechos); emite «sonido pedido» `SFX_CLICK_SUBTLE` con botón inerte | Audio |

### Contratos 17

| Campo | Contenido |
|---|---|
| Emite | «sonido pedido» (`SFX_CLICK_SUBTLE`, botón inerte; reglas 10 de 3 y R5 de 23). Ningún otro aviso ni hecho |
| Consume | «pista aplicada» `(id, nivel, text_key)`; «puzle inactivo» `(id, nivel)`; «puzle activado»; «puzles configurados» (todos de 9); «vista cercana abierta/cerrada» (id de vista, de 7); hecho `correos_leidos` (propietario 19, vía 3); estado `ACTIVO/RESOLVING/BLOQUEADO/RESUELTO` de 9 |
| API pública (llamada a 9) | `list_puzzles()`, `get_hints(id)`, `request_hint(id, level) -> bool` (`true` = aplicado; incluye reaplicación ‡). 17 no define API pública propia con firma; usa `HintResult` {`BUSY`,`COMPLETE`,`WAIT`,`REJECTED`,`APPLIED`} y `reset()` (vaciado interno). GameClock de 9 (regla 36) |
| Estado que posee/persiste | `HintLedger` por puzle: `applied`, `t_ref`, `last_applied`, `notes`, `pending_text`. NADA persistido. `hint_level_reached` es de 9 (tampoco se guarda) |
| Nodo/autoload propuesto | `HintService` inyectado (RefCounted/Node no autoload) + `HintLedger` (RefCounted) + `HintPanel` (Control alojado por 25 bajo «Pistas») + `HintNote` (Control overlay en el HUD) |

## Sistema 24 — prompt-de-interaccion.md (slug `prompt`)

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-prompt-001 (provisional) | prompt-de-interaccion.md | 24 | Sondea `get_target()` de 7 en cada fotograma de render (sin aviso de cambio de objetivo) y no recalcula objetivo, verbo ni `p`; entrada `{id, etiqueta, largo, p, anillo_visible} \| nulo` | UI |
| TR-prompt-002 (provisional) | prompt-de-interaccion.md | 24 | Anillo/etiqueta dibujados solo con contexto de Entrada `exploración` y objetivo ≠ nulo; ocultos en menú, lectura, inspección, vista cercana, ordenador, llamada, sin control; sin punto de mira permanente | Input |
| TR-prompt-003 (provisional) | prompt-de-interaccion.md | 24 | Anillo fijo en el centro de pantalla; 28 px a 1080p (48 px con `icono_grande`), opacidad 80 %; fundidos 250 ms in / 150 ms out; cambio directo de objeto sin parpadeo (cruzado 120 ms) | UI |
| TR-prompt-004 (provisional) | prompt-de-interaccion.md | 24 | Relleno del anillo `360·p` grados horario desde las 12 h (p de 7); vaciado 100 ms al soltar; permanece en modo «alternar» | Rendering |
| TR-prompt-005 (provisional) | prompt-de-interaccion.md | 24 | Pulso de aceptación (80→100 % en 120 ms) y de rechazo (80→40 % en 120 ms) disparados solo por el aviso «interacción ejecutada (id, verbo, resultado)» de 7; inicio ≤ `latencia_feedback_ms` 100 ms | Events |
| TR-prompt-006 (provisional) | prompt-de-interaccion.md | 24 | Dominio de `resultado` ampliado a `HECHO`, `SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO` (aplicado en 7); un gesto = un aviso = un pulso | Events |
| TR-prompt-007 (provisional) | prompt-de-interaccion.md | 24 | Tope de fotosensibilidad: ignorar pulso nuevo si el anterior empezó hace < `pulso_min_intervalo_ms` 340 ms (≤ 2,9/s, nunca bajar de 334); sin cola de pulsos | Accessibility |
| TR-prompt-008 (provisional) | prompt-de-interaccion.md | 24 | Etiqueta `[glifo] + texto` apagada por defecto (`etiqueta_accion_visible`=falso); glifo siempre acompañado de texto, en línea; clave 18 ausente → no dibujar etiqueta y log de dev, nunca mostrar la clave | UI |
| TR-prompt-009 (provisional) | prompt-de-interaccion.md | 24 | Glifo desde `get_binding_label(accion, dispositivo) -> {tipo, texto, glifo_id}` de 1 (asignación vigente, orden determinista); sin teclas hardcodeadas (ni «Retroceso»/«Backspace» en código/datos) | Input |
| TR-prompt-010 (provisional) | prompt-de-interaccion.md | 24 | Re-resolver glifos solo al cambiar dispositivo («dispositivo de entrada cambiado») o al recibir «pausa cerrada»; una consulta por cambio, no por fotograma; sin reiniciar el reloj de pies | Input |
| TR-prompt-011 (provisional) | prompt-de-interaccion.md | 24 | API `mostrar_pie(clave, duracion_s \| PERSISTENTE, retener = falso)` y `ocultar_pie()`; llamadores 7 y 20; 24 no sabe el origen | Core |
| TR-prompt-012 (provisional) | prompt-de-interaccion.md | 24 | Un solo hueco de pie, sustitución con fundido cruzado 150 ms (100 con `reducir_movimiento`), sin cola; dos pies en el mismo fotograma: gana el último | UI |
| TR-prompt-013 (provisional) | prompt-de-interaccion.md | 24 | Duración la calcula el llamador (`duracion_pie(clave)` de 7, F5); `PERSISTENTE` dura hasta cambiar `get_target().id` respecto del del instante de dibujo o hasta otro pie; el reloj es de tiempo de juego (la pausa lo detiene y congela fundidos) | Core |
| TR-prompt-014 (provisional) | prompt-de-interaccion.md | 24 | Pie solo en `exploración`; fuera se oculta y congela; pies de objeto se descartan al salir por modo de 7/`sin control`; pie `retener=verdadero` queda pendiente sin caducidad hasta otro `retener` o carga/cambio de escena; nada se persiste | UI |
| TR-prompt-015 (provisional) | prompt-de-interaccion.md | 24 | Pie: abajo-centro, márgenes seguros 5 %, ≤2 líneas a ≤60 % ancho, texto ≥ max(28·s, 24) px, panel 85 % opacidad, contraste ≥ 4,5:1 sobre blanco puro | Accessibility |
| TR-prompt-016 (provisional) | prompt-de-interaccion.md | 24 | Convivencia con 26: mientras haya bloque de subtítulos visible el pie sube sobre su borde superior + `sub_hueco_px` 12 px, nunca lo tapa (recorta el pie a 2 líneas) | UI |
| TR-prompt-017 (provisional) | prompt-de-interaccion.md | 24 | Sustitución de token `{accion:atrás}` en `UI_BOLSILLO_AYUDA` por glifo+texto de la asignación vigente; fallback al nombre «Atrás» y warning si falla `get_binding_label` | Localization |
| TR-prompt-018 (provisional) | prompt-de-interaccion.md | 24 | Escala UI F2 `s=clamp(altura_ventana/1080, 0,67, 2,0)` (720p–2160p), redondeo a entero; márgenes 5 % en 16:9, anclados al área 16:9 central en ultraancho | Rendering |
| TR-prompt-019 (provisional) | prompt-de-interaccion.md | 24 | Lee de 6 vía avisos de cambio y aplica al fotograma siguiente `reducir_movimiento` (fundidos fijos 100 ms), `icono_grande`, `etiqueta_accion_visible`; valores iniciales si 6 no está (dependencia blanda) | Accessibility |
| TR-prompt-020 (provisional) | prompt-de-interaccion.md | 24 | Sin audio propio (`SFX_CLICK_SUBTLE` lo emite 7); sin color para estados (sin rojo); sin estado persistente; espera «escena lista» antes de dibujar; datos en `assets/data/ui/prompt.json` | Data |

### Contratos 24

| Campo | Contenido |
|---|---|
| Emite | Nada (sin avisos ni audio) |
| Consume | `get_target()` (7, por fotograma); «interacción ejecutada (id, verbo, resultado)» (7); «dispositivo de entrada cambiado» (1); «pausa cerrada»; «escena lista»; contexto de Entrada (1); cambios de ajustes `reducir_movimiento`, `icono_grande`, `etiqueta_accion_visible` (6); `duracion_pie(clave) -> float \| PERSISTENTE` (7); `get_binding_label(accion, dispositivo) -> {tipo, texto, glifo_id}` (1); textos `UI_VERBO_*`, `OBJ_<id>`, `UI_BOLSILLO_AYUDA` (18); estado de bloques de 26 (convivencia) |
| API pública | `mostrar_pie(clave, duracion_s \| PERSISTENTE, retener = falso)`; `ocultar_pie()` |
| Estado que posee/persiste | Pie actual, pie retenido pendiente, último inicio de pulso; ninguno persistido. Sin bandera «una vez» (la lleva 20) |
| Nodo/autoload propuesto | Escena UI `InteractionPrompt` (CanvasLayer/Control) en el HUD, con `mostrar_pie`/`ocultar_pie` inyectada a 7 y 20 (no hace falta autoload); datos `assets/data/ui/prompt.json` |

## Sistema 25 — menu-de-pausa.md (slug `pause`)

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-pause-001 (provisional) | menu-de-pausa.md | 25 | PAUSA (ARQUITECTURA): al abrir, el tiempo de juego se detiene en el mismo fotograma (Δ_juego = 0) y se reanuda en el fotograma de salida; el mecanismo (`SceneTree.paused` / `process_mode`) NO está decidido (OQ 2, D25-28: «ADR de pausa»); el contrato es solo «pausa activa» | Core |
| TR-pause-002 (provisional) | menu-de-pausa.md | 25 | PAUSA: deben seguir en tiempo REAL con el juego pausado la UI del menú, el guardado diferido de 6, el temporizador de captura (8 s), la muestra de audio de los deslizadores (23) y los reintentos de 5; implica `process_mode` ALWAYS/WHEN_PAUSED en esos nodos; NO verificado en Godot 4.7 (la referencia no cubre pausa, `Tween` ni `AudioStreamPlayer` en pausa) | Core |
| TR-pause-003 (provisional) | menu-de-pausa.md | 25 | PAUSA: contradicción abierta entre 28 R22 y 29 R35 (suponen árbol pausable), 23 D23-25 («25 no lo pausa») y 21/22/9/7/8 (reloj de juego detenido); el ADR debe resolverla; consumidores por «pausa abierta/cerrada»: 5, 23, 26, 28 | Core |
| TR-pause-004 (provisional) | menu-de-pausa.md | 25 | Tres causas de apertura: acción `pausa` (cualquier contexto salvo carga de escena), pérdida de foco de ventana, desconexión del mando activo; Entrada decide cuándo, 25 pide contexto `menú`; si coinciden se abre un solo menú | Input |
| TR-pause-005 (provisional) | menu-de-pausa.md | 25 | Emite «pausa abierta» (`pause_opened`, sin datos) una vez por apertura efectiva, tras entrar en `menú` y marcar pausa; no si Entrada rechaza, si ya está abierto, ni en el título | Events |
| TR-pause-006 (provisional) | menu-de-pausa.md | 25 | Emite «pausa cerrada» (`pause_closed`, sin datos) una vez, DESPUÉS de restaurar contexto y reanudar tiempo; también tras «Volver al título»/«Nueva partida» solo para normalizar el reloj; sin alias | Events |
| TR-pause-007 (provisional) | menu-de-pausa.md | 25 | Al abrir, en el mismo fotograma, llamada directa a 6 para vaciar ajustes pendientes (no por bus: 6 no depende de 3) | Save/Load |
| TR-pause-008 (provisional) | menu-de-pausa.md | 25 | Un evento, un efecto: `pausa` y `ui_atrás` comparten `Esc` y el menú consume el evento; `guarda_apertura_s` 0,15 s (tiempo real) ignora la pulsación de apertura; el clic/pulsación de cierre no debe llegar al mundo hasta soltar (se pide a 1) | Input |
| TR-pause-009 (provisional) | menu-de-pausa.md | 25 | Foco dual: operable solo con teclado, solo ratón o solo mando con `ui_*` del contexto `menú`; hover mueve el foco, clic activa, deslizadores arrastrables; sin wrap; foco visible sin depender del color | UI |
| TR-pause-010 (provisional) | menu-de-pausa.md | 25 | Foco inicial «Reanudar» en cada apertura; retorno del foco a la fila/diálogo que abrió; «Volver al título» abre con foco en «Cancelar»; no se recuerda la pantalla | UI |
| TR-pause-011 (provisional) | menu-de-pausa.md | 25 | Velo con fundido 0,35 s (0,10 s con `reducir_movimiento`), rampa monótona de alfa, igual al cerrar, en tiempo real, sin parpadeo | Rendering |
| TR-pause-012 (provisional) | menu-de-pausa.md | 25 | Ajustes inmediatos: cada cambio se escribe en 6 en el acto (sin Aplicar/Cancelar), se relee el valor real y se refresca por aviso de cambio de 6 (p. ej. `modo_ventana` externo); «Restablecer» por ajuste y «todos» (18 claves de 6 R8, un aviso por ajuste) | Data |
| TR-pause-013 (provisional) | menu-de-pausa.md | 25 | Repetición al mantener `ui_izquierda/derecha`: `repeticion_inicial_s` 0,4 s, `repeticion_s` 0,12 s, tiempo real (F1) | Input |
| TR-pause-014 (provisional) | menu-de-pausa.md | 25 | Fila «Pistas» solo si 17 registra un proveedor de panel (nodo de UI con su navegación, contrato ‡); sin proveedor no aparece; 25 no recibe contadores ni escribe nada de pistas | UI |
| TR-pause-015 (provisional) | menu-de-pausa.md | 25 | Componente «Opciones» reutilizable, independiente del host (25 y título 27): interfaz `mostrar(pantalla, pestaña_inicial?)` y señal `cerrado`; no emite `pause_opened`/«pausa cerrada», no pausa ni vacía ajustes | UI |
| TR-pause-016 (provisional) | menu-de-pausa.md | 25 | Captura de reasignación: escucha solo el dispositivo de la pestaña, guarda `guarda_captura_s` 0,25 s tras soltar la entrada que abrió, cancelación a `t_captura_s` 8 s desde la apertura con texto visible, `Esc` cancela, conjuntos `mover`/`mirar` en 4 pasos | Input |
| TR-pause-017 (provisional) | menu-de-pausa.md | 25 | API de reasignación de Entrada (‡) devuelve resultados (asignada, conflicto con/sin intercambio, mínimo, `atrás` solo imprimible, conjunto, duplicada); 25 solo presenta; requiere `es_imprimible(entrada)` ‡ y lista exportada de ajustes de manejo (id, tipo, rango, paso, valor, rótulo) | Input |
| TR-pause-018 (provisional) | menu-de-pausa.md | 25 | Máquina de estados única: Cerrado, Abierto·raíz, Abierto·pantalla, Abierto·diálogo, Capturando, Panel de mando, Saliendo (descarta toda entrada; peticiones únicas ante doble clic) | Core |
| TR-pause-019 (provisional) | menu-de-pausa.md | 25 | Salir al título: orden estricto petición `quit` a 5 (síncrona, urgente) → retorno → descarga total (4 R15; «descarga total solicitada» antes) → «pausa cerrada»; «Nueva partida»: `nueva_partida()` de 5 → carga `partida_nueva` en 4 con descarte de pila de Entrada; sin guardado manual ni «cargar partida» | Scene |
| TR-pause-020 (provisional) | menu-de-pausa.md | 25 | Línea «guardado en riesgo» según avisos «guardado en riesgo»/«guardado restablecido» de 5 vía 3; variable `guardado_en_riesgo` desde el inicio de partida (+ consulta de estado de 5 ‡ opcional); el texto del diálogo de salir cambia en vivo | Save/Load |
| TR-pause-021 (provisional) | menu-de-pausa.md | 25 | Panel «Mando desconectado»: un solo botón «Reanudar» con foco, sin temporizador, reanuda con teclado/ratón; con menú ya abierto: línea fija de cabecera y cancelación de captura de mando; durante carga de escena aparece al terminar | Input |
| TR-pause-022 (provisional) | menu-de-pausa.md | 25 | Texto: rótulos como claves `UI_PAUSA_*` de 18 (fallback de emergencia de 18); mínimo 24 px, reflow sin recorte con `escala_texto_ui`, márgenes seguros 5 %, contraste ≥ 4,5:1 (bordes ≥ 3:1); datos en `assets/data/ui/pause.json` | Localization |
| TR-pause-023 (provisional) | menu-de-pausa.md | 25 | Pruebas: unitarias gdUnit4 en `tests/unit/pause/` (sin E/S ni reloj reales, tolerancia ±1 fotograma); capturas UI retenidas en `production/qa/evidence/` por pantalla | Tooling |

### Contratos 25

| Campo | Contenido |
|---|---|
| Emite | «pausa abierta» = `pause_opened` (sin datos); «pausa cerrada» = `pause_closed` (sin datos); señal del componente Opciones `cerrado`; peticiones: a 5 «salir al título» (causa `quit`) y `nueva_partida()`; a 6 «vaciar pendientes», escritura de ajustes, «restablecer» por ajuste y «restablecer todos»; a 1 entrar/salir del contexto `menú` y API de reasignación ‡; a 4 descarga total / carga `partida_nueva`; a 23 muestra de bus |
| Consume | `pausa`, `ui_arriba/abajo/izquierda/derecha/aceptar/atrás` (contexto `menú`); pérdida de foco y desconexión/reconexión de mando (1); aviso de cambio de ajustes (6); «guardado en riesgo» / «guardado restablecido» (5 vía 3); `es_imprimible(entrada)` ‡ y lista de ajustes de manejo ‡ (1); proveedor de panel de pistas registrado por 17 (`HintPanel`) |
| API pública | `mostrar(pantalla, pestaña_inicial?)` (componente Opciones ‡) + señal `cerrado`; registro de proveedor de panel de pistas (nombre/firma NO definidos en el GDD, ‡ de 17); API de reasignación de Entrada (‡, firma no definida) |
| Estado que posee/persiste | Máquina de 7 estados, `guardado_en_riesgo`, pestaña/pantalla actual, estado de captura; NO persiste nada (ajustes son de 6, `controles` va por Entrada, progreso de pistas no se guarda) |
| Nodo/autoload propuesto | `PauseMenu` (CanvasLayer/Control raíz, `process_mode` por decidir en el ADR de pausa) + `OptionsComponent` reutilizable (también en 27); gestor de pausa (autoload vs nodo de escena) por decidir en el ADR; datos `assets/data/ui/pause.json` |

## HUECOS
- ADR de pausa sin decidir (OQ 2): `SceneTree.paused` vs reloj de juego propio, `process_mode` de UI/audio/Tween y contradicción 23 D23-25 vs 28 R22/29 R35; no verificado en Godot 4.7.
- Los avisos se nombran por prosa; solo `pause_opened`/`pause_closed` tienen nombre de código. Sin firma para el proveedor de panel de pistas ni la API de reasignación (‡).
- 17: cambios requeridos en 9 (`first_action`, reaplicación, re-emisión de «puzle inactivo», `text_key`) aún no aplicados.
- 24: AC-24-07 «NOT SOURCEABLE» (filtro de daltonismo no documentado); coste del sondeo de `get_target()` por fotograma no medido.

## NO LEÍDO
- Summary, Overview y Player Fantasy de los tres GDD; Edge Cases de 25 (líneas 178–226); Decisiones tomadas (salvo D25-28), Open Questions (salvo OQ 2 de 25), Cambios requeridos, Entradas para el registro e Historial en los tres.
- 17: resto de `hints_policy.json` tras la línea 323. 24: Decisiones, Open Questions y Cambios requeridos.


---

<!-- bloque G9 -->
# Baseline TR — lote g9 (audio, subs, title)

## 1. director-de-audio.md (sistema 23, slug `audio`)

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-audio-001 (provisional) | director-de-audio | 23 | Nodo persistente bajo la raíz que sobrevive a las cargas (`get_instance_id()` idéntico en `planta`→`recepcion`, sin suscripciones colgantes), con `process_mode` siempre activo; arranca tras 3 y 6 («ajustes aplicados»). `process_mode` NO VERIFICADO en 4.7 (ADR) | Core |
| TR-audio-002 (provisional) | director-de-audio | 23 | Árbol de buses fijo creado al arrancar: `Voice`(`Voice_Vera`,`Voice_Mega`,`Voice_Guardian`), `Effects`(`Fx_Puzzle`,`Fx_World`,`Fx_Steps`), `Ambience`, `Music`; `Master` a 0 dB, sin `vol_maestro` | Audio |
| TR-audio-003 (provisional) | director-de-audio | 23 | Volumen por grupo: `Voice`←`vol_voces`, `Effects`+`Ambience`←`vol_efectos`, `Music`←`vol_musica`; `vol_db` −38…0 (`db_min` −40, `N_pasos` 20) con rampa lineal en dB `rampa_vol_s`=0,05 s; silencio = rampa a −80 dB y bus mudo, nunca −inf/`log(0)`; en «ajustes aplicados» sin rampa antes de arrancar capas | Audio |
| TR-audio-004 (provisional) | director-de-audio | 23 | Ganancia = `trim_dB + bus_db + duck_dB + sobresalto_dB + silencio_parcial_dB + pausa_dB + espacial_dB` (F1); `trim_dB` −24…+6 por sonido desde catálogo | Audio |
| TR-audio-005 (provisional) | director-de-audio | 23 | Catálogo de efectos en `audio_catalog.json` (ID, bus, trim, prioridad) y ajustes en `assets/data/audio/audio_settings.json`; todos los valores † cargados de datos, no hardcodeados | Data |
| TR-audio-006 (provisional) | director-de-audio | 23 | Contrato de respuesta: cada «línea pedida» aceptada recibe exactamente una señal entre «línea terminada»`{line_id,motivo∈fin,corte,watchdog,interrumpida}`, «línea sin audio»`{line_id,t_lectura_s}`, «línea fallida»`{line_id,t_lectura_s}`; emitida como aviso encolado ≤ 1 fotograma, nunca dentro de la entrega de la petición; «sin audio»/«fallida» al momento | Events |
| TR-audio-007 (provisional) | director-de-audio | 23 | «Línea pedida» solo acepta `line_id` de 18; un ID `SFX_*` se rechaza con registro y sin señal; los SFX van solo por «sonido pedido»; alias «sonido de llamada pedido» eliminado | Events |
| TR-audio-008 (provisional) | director-de-audio | 23 | Tres canales de voz simultáneos por prefijo (`VO_V_*`→`Voice_Vera`, `MEGA_*`→`Voice_Mega`, `VO_G_*`→`Voice_Guardian`); cola de 1 por canal con tope `t_cola_canal_s`=8,0 s (23 dueño único; 21 lo consume); duplicado de `line_id` activo/encolado se ignora | Audio |
| TR-audio-009 (provisional) | director-de-audio | 23 | Techo y corte: `techo_s = fallback_s + line_grace_s` (2,0 s, valor único compartido con 9 y 22 leído de datos); corte con fundido `t_fade_corte_s`=0,3 s y «terminada»(`corte`) en `techo_s` (±0,05 s) | Audio |
| TR-audio-010 (provisional) | director-de-audio | 23 | Watchdog: sin `finished` a `duración + t_watchdog_s`(1,0 s) o a `t_linea_audio_max_s`(20 s) se detiene el reproductor y se emite «terminada»(`watchdog`); fallo a mitad: parada en `t_interrupt_s`(0,2 s) y «fallida» (nunca ambas) | Audio |
| TR-audio-011 (provisional) | director-de-audio | 23 | `interrupt` baja el sonido en `t_interrupt_s`=0,2 s (silencio ≤0,3 s); si era línea emite «terminada»(`interrumpida`); interrumpir lo que no suena no es error | Audio |
| TR-audio-012 (provisional) | director-de-audio | 23 | Anti-duplicado: dos peticiones idénticas en `t_dedup_s`=0,05 s suenan una vez (no aplica a pasos); `sound_id` desconocido/nulo se ignora y registra; `fuente` desconocida suena 2D y se registra | Audio |
| TR-audio-012b (provisional) | director-de-audio | 23 | Marcadores de escena: nodos con `audio_id`, volúmenes `audio_room` (V,C,A,B,D,R) y etiquetas de superficie se indexan en cada «escena lista» y se descartan en «carga iniciada»; sin referencias a nodos de planta; estancia por posición del oyente (defecto `C`) | Scene |
| TR-audio-013 (provisional) | director-de-audio | 23 | Polifonía/prioridad P1–P5: `max_voces_total`=24 (20 reservadas + 4 holgura), `max_sfx_p2`=4; robo del más antiguo con fundido `t_interrupt_s`; P1 y P5 nunca robables, P2 solo por otro P2 | Audio |
| TR-audio-014 (provisional) | director-de-audio | 23 | Ducking bajo voz con audio: mínimo (no suma) de d_k por canal activo; Vera/Guardian Music−6/Amb−4/Fx_World−4, Mega −3/−2/−2; ataque 0,15 s, retención 0,3 s, liberación 0,8 s; `Voice`,`Fx_Puzzle`,`Fx_Steps` nunca; suma con silencio parcial ≥ `duck_total_min_db`(−12) | Audio |
| TR-audio-015 (provisional) | director-de-audio | 23 | Pausa propia por reproductor (`stream_paused`, NO VERIFICADO en 4.7): «pausa abierta» pausa voces y efectos puntuales en posición; lazos/drone siguen a `pausa_amb_db`=−6; la muestra de volumen no se pausa; sin pausar el `SceneTree`; relojes de línea = tiempo de juego | Audio |
| TR-audio-016 (provisional) | director-de-audio | 23 | «Carga iniciada»/«descarga total solicitada»: cancela sin señal voces en curso, pausadas y encoladas y efectos puntuales (fundido 0,3 s); `Ambience`/`Music` −18 dB en cortina; recupera en `t_entrada_capa_s`=3,0 s; salida de capas 1,5 s | Scene |
| TR-audio-017 (provisional) | director-de-audio | 23 | Capas persistentes: `MUS_DRONE` (2D constante) y lluvia sobreviven `planta`→`recepcion` sin reiniciarse; `AMB_FAN` 3D (alcance 8 m†) se detiene; lluvia por estancia (A/C 0, V/R −6, B/D −9 dB con paso bajo `lp_sala_hz`=2.500) interpolada en `t_estancia_s`=1,5 s | Audio |
| TR-audio-018 (provisional) | director-de-audio | 23 | Estado: 23 NO persiste nada; solo lee `caja_completa` y `llamada_completada` al reanudar; apagón no se infiere (21 reemite `LUCES_APAGON` duración 0 → lluvia −60 dB el mismo fotograma); nunca repite una voz | Save/Load |
| TR-audio-019 (provisional) | director-de-audio | 23 | Sin dispositivo (controlador ficticio): modo `sin_dispositivo`, toda línea → «sin audio» ≤1 fotograma, efectos no suenan; línea sin audio no hace ducking ni ocupa canal; `t_lectura_s` por F3 | Audio |
| TR-audio-020 (provisional) | director-de-audio | 23 | Pasos: señal directa `paso(superficie,intensidad)` de 2; `paso_db = db_paso_ref(−6)+20·log10(intensidad)`; `t_paso_min_s`=0,18 s; variante sin repetir la anterior, tono ±3 %; 23 no aplica `i_paso_min` | Audio |
| TR-audio-021 (provisional) | director-de-audio | 23 | Presupuesto: voces ≤24; efectos residentes ≤10 MB; audio en ejecución ≤24 MB; disco ≤40 MB; voces y lazos largos en streaming, efectos <1,0 s precargados; aviso en desarrollo al superar | Core |
| TR-audio-022 (provisional) | director-de-audio | 23 | Timbre/filtros de banda de teléfono y megafonía horneados en las grabaciones (un solo bus `Voice_Guardian`); filtro en ejecución por fuente y paso bajo (`C01`, `lp_sala_hz`) NO VERIFICADO, a decidir en ADR | Audio |
| TR-audio-023 (provisional) | director-de-audio | 23 | `reducir_sobresaltos`: −6 dB en `SFX_PHONE_BUZZ`(ataque 0,25 s), `SFX_BREATH_BROKEN`, `SFX_CHAIRS_ROLL`, `SFX_TYPING_FAR`; limitador de techo −10 dBFS en `VO_G_07` (NO VERIFICADO en 4.7); se aplica en el fotograma del aviso con rampa | Accessibility |
| TR-audio-024 (provisional) | director-de-audio | 23 | Muestra de referencia de volumen: con menú abierto y cambio de `vol_voces`/`vol_efectos`, máx. una cada `t_muestra_min_s`=0,4 s (`UI_VOL_MUESTRA` o `SFX_CLICK_SUBTLE`); no para `vol_musica` | Audio |
| TR-audio-025 (provisional) | director-de-audio | 23 | Loudness objetivo (buses 100 %): VO −18 LUFS, MEGA −21, puzle −22, mundo −26, pasos −30, lluvia −34, ventilador −38, drone −36; pico ≤ −1 dBTP | Audio |

Nota: numeración 012b = ajuste intercalado; renumerable al consolidar.

### Contratos — audio (23)

| Aspecto | Detalle (nombres exactos del GDD) |
|---|---|
| Emite | «línea terminada» `{line_id, motivo}`; «línea sin audio» `{line_id, t_lectura_s}`; «línea fallida» `{line_id, t_lectura_s}` (causa `canal_ocupado` registrada); «línea iniciada» `{line_id, duracion_s, canal}` (opcional) |
| Consume | «línea pedida» `{line_id, fuente?, fallback_s?, puzzle?}`; «feedback de puzle» `{puzzle, sound_id, text_key?, element?}`; «sonido pedido» `{sound_id, fuente?, accion∈play/stop/set/interrupt, valor?}`; «efecto de escena pedido» (`id_efecto`); «estado de objeto pedido»; «vista cercana abierta/cerrada»; «carga de escena iniciada», «escena lista», «descarga total solicitada/completada»; «estado restablecido», «estado restaurado»; «pausa abierta», «pausa cerrada»; avisos de cambio de Ajustes (`vol_voces`,`vol_efectos`,`vol_musica`,`reducir_sobresaltos`), «ajustes aplicados»; señal directa `paso(superficie, intensidad)`; lee hechos `caja_completa`, `llamada_completada` |
| API pública | No declara métodos GDScript; interfaz = bus de avisos de 3. Tampoco hay nombres de método |
| Estado | Ninguno persistido; memoria volátil: cola de 1 por canal, índice de marcadores, voces activas/pausadas, niveles de capa |
| Nodo/autoload | Nodo persistente bajo la raíz (no se nombra); `process_mode` siempre activo; esquema técnico en un ADR de audio pendiente |

## 2. subtitulos.md (sistema 26, slug `subs`)

Afirmaciones de motor NOT SOURCEABLE: ninguna marcada en las secciones leídas. Solo se cita OQ 8 (relojes propios sin pausar el `SceneTree`) y D26-2/D26-12 (degradación sin «línea iniciada»).

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-subs-001 (provisional) | subtitulos | 26 | Solo se suscribe; no emite avisos ni llama a 23 ni a 21 (AC-26-26) | Events |
| TR-subs-002 (provisional) | subtitulos | 26 | Escucha «línea pedida» (guarda `line_id`, `fallback_s`), «línea iniciada», «línea terminada», «línea sin audio», «línea fallida», «sonido pedido» (solo `SFX_*` con clave `SUB_*`), «pausa abierta/cerrada», «descarga total solicitada», «carga iniciada» y avisos de ajustes | Events |
| TR-subs-003 (provisional) | subtitulos | 26 | Con audio el bloque aparece en el mismo fotograma (±1) que «línea iniciada» y se retira `t_cola_sub_s`=0,4 s (±0,05) tras «terminada» | UI |
| TR-subs-004 (provisional) | subtitulos | 26 | Degradación sin «línea iniciada»: nace en «línea pedida» solo si no hay otra línea del mismo canal activa/pendiente; si la hay, espera su «terminada» | Events |
| TR-subs-005 (provisional) | subtitulos | 26 | Sin audio/fallida: bloque al momento (≤1 fotograma) y dura `fallback_s` (o `t_lectura_s` de 23 F3 si falta); 26 no retiene ni adelanta a 9/21/22 | UI |
| TR-subs-006 (provisional) | subtitulos | 26 | Duración visible con audio `t_visible_linea = max(duracion_audio_s + t_cola_sub_s, t_lectura_s)`; `t_lectura_s` es de 23 (no se redefine); páginas ≥ `ceil(t_visible/t_sub_max_s)`, cada una ≤8,0 s y ≥1,0 s | UI |
| TR-subs-007 (provisional) | subtitulos | 26 | Paginación y reparto F2 `t_i = (T−P)·n_i/Σn` con `P`=`pausa_segmento_s` 1,2 s; `VO_G_07` en dos segmentos (A/B) con `seg_b_inicio_s` ‡ opcional de 18 | Data |
| TR-subs-008 (provisional) | subtitulos | 26 | Relojes propios de 26 en tiempo de juego, congelados con «pausa abierta» (incluidos mínimos y `fallback_s` restante) sin depender de pausar el `SceneTree` (OQ 8) | Core |
| TR-subs-009 (provisional) | subtitulos | 26 | Con `subtitulos_activos`=falso no dibuja pero sigue contando relojes; al reactivar muestra el bloque vigente con el tiempo restante | UI |
| TR-subs-010 (provisional) | subtitulos | 26 | «Carga iniciada» y «descarga total solicitada» retiran bloques y vacían cola sin fundido aunque la pausa congele relojes; los bloques no se persisten ni se restauran en «escena lista» | Scene |
| TR-subs-011 (provisional) | subtitulos | 26 | Capa dibujada en todos los contextos de Entrada (`exploración`,`lectura`,`inspección`,`vista cercana`,`ordenador`,`llamada`,`sin control`) y sobre el velo de pausa | UI |
| TR-subs-012 (provisional) | subtitulos | 26 | Banda inferior centrada, ancho `sub_ancho_pct`=60 % del viewport (margen lateral ≥5 %), margen inferior 7 %, no se mueve con cámara | UI |
| TR-subs-013 (provisional) | subtitulos | 26 | Bloque = hablante + ≤`sub_lineas_max`(2) líneas de `sub_car_linea`(42); ≤`sub_bloques_max`(2) simultáneos, cola de 1 con descarte registrado; mínimo de cesión `min(t_lectura_s,1,0 s)` | UI |
| TR-subs-014 (provisional) | subtitulos | 26 | Tamaño de texto `alto_px = max(round(base_px·s), 24)`, `s=alto_viewport/1080`; bases pequeno/medio/grande 24/32/44 px; car/línea derivado por ancho fijo (56/42/30); recomposición en el siguiente fotograma sin reiniciar reloj | Rendering |
| TR-subs-015 (provisional) | subtitulos | 26 | Reserva de banda F4 `alto_reservado_px` (260 px medio / 320 px grande a 1080p) como tope de contenido de 22 y 24; el pie de 24 sube sobre los bloques visibles + `sub_hueco_px`=12 | UI |
| TR-subs-016 (provisional) | subtitulos | 26 | Contraste texto/fondo medido contra blanco y negro puros: 7:1 con opaco/translúcido (opacidad ≥70 %†), 4,5:1 con contorno 2 px si fondo `ninguno` | Accessibility |
| TR-subs-017 (provisional) | subtitulos | 26 | Hablante por tres canales redundantes (nombre `NOMBRE:`, estilo cursiva/comillas angulares/sin adorno, color opcional nunca único); legible en escala de grises; claves `UI_SUB_HABLANTE_*` ‡ | Accessibility |
| TR-subs-018 (provisional) | subtitulos | 26 | Fundido `t_fundido_sub_s`=0,15 s; con `reducir_movimiento` 0,10 s = `reduce_motion_fade_s` de 6 (sin valor propio); sin deslizamientos/escalas | Accessibility |
| TR-subs-019 (provisional) | subtitulos | 26 | Ajustes de 6: `subtitulos_activos` (defecto true, valor seguro si falla el fichero), `subtitulos_tamano`(`pequeno`/`medio`/`grande`), `subtitulos_fondo`(`ninguno`/`translucido`/`opaco`), `subtitulos_hablante`; aplicados en el fotograma del aviso; sin 6 «Listo» usa defectos | Save/Load |
| TR-subs-020 (provisional) | subtitulos | 26 | Subtítulos de sonido: `SUB_BREATH_BROKEN` obligatorio (4,0 s, mín `t_sub_sfx_min_s` 1,5); lazo `SFX_PHONE_BUZZ` una vez por inicio y retirada en `stop`/`interrupt`/`llamada`/3,0 s; 3 claves `SUB_*` provisionales (OQ 2); cola de sonido ≤2,0 s | Localization |
| TR-subs-021 (provisional) | subtitulos | 26 | Vista previa `UI_SUB_MUESTRA` ‡ en pantallas de 25/30 sin usar la banda de juego ni avisos de 23; solo español en el slice | UI |

### Contratos — subtitulos (26)

| Aspecto | Detalle |
|---|---|
| Emite | Nada (AC-26-26) |
| Consume | «línea pedida» `{line_id, fallback_s}`, «línea iniciada» `{line_id, duracion_s, canal}`, «línea terminada» `{line_id, motivo}`, «línea sin audio» / «línea fallida» `{line_id, t_lectura_s}`, «sonido pedido» (`SFX_*`), «pausa abierta», «pausa cerrada», «carga iniciada», «descarga total solicitada», avisos de cambio de ajustes; lectura de 18 (texto, `SUB_*`, `UI_SUB_HABLANTE_*`, `UI_SUB_MUESTRA`) |
| API pública | No declara métodos (solo suscripciones); contrato con 24/22: `alto_reservado_px` |
| Estado | Volátil: bloques visibles, cola de 1, relojes por bloque; no persiste. Ajustes en 6 |
| Nodo/autoload | No nombrado; capa UI (CanvasLayer) sobre el velo de pausa, activa en todos los contextos |

## 3. pantalla-de-titulo.md (sistema 27, slug `title`)

Afirmaciones de motor NOT SOURCEABLE / no verificadas: `SceneTree.quit()` (R14: «no verificado», `docs/engine-reference/godot/` no lo cubre; AC-15 = PV); señales de mando/desconexión (AC-26 = PV); anuncio por lector de pantalla con AccessKit (4.5+) no prometido (OQ 10).

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-title-001 (provisional) | pantalla-de-titulo | 27 | Arranque: tras la inspección de 5, muestra advertencias si `advertencias_vistas`† (6) es falso o 6 no responde; si verdadero va al menú. Se escribe verdadero solo al pulsar «Entendido» (cerrar ventana antes no lo escribe); dato no restablecible (6 D-6.7) | Save/Load |
| TR-title-002 (provisional) | pantalla-de-titulo | 27 | Advertencias: lista de 5 entradas `UI_…` de 18 + encabezado «Antes de empezar», sin cuenta atrás ni avance automático (visibles tras 60 s), siempre «Salir del juego»; releíbles desde Opciones > «Avisos de contenido» | UI |
| TR-title-003 (provisional) | pantalla-de-titulo | 27 | El menú se pinta solo con 5 en «Sin partida» y re-inspección terminada tras «descarga total completada»; lee el resultado de la última inspección (`terminada`, `con_futura`, base) cada vez que entra en el menú, sin releer disco | Core |
| TR-title-004 (provisional) | pantalla-de-titulo | 27 | Timeout `t_espera_inspeccion_s`=3,0 s† (1–10): sin respuesta de 5 → estado `desconocido` (no `ninguna`), «Nueva partida» siempre con confirmación, log de diagnóstico; refresco de la lista al llegar el resultado conservando foco y diálogo abierto | Core |
| TR-title-005 (provisional) | pantalla-de-titulo | 27 | Filas no ofrecidas no existen (nunca desactivadas); `terminada` manda sobre `irrecuperable`/`version_futura`/`con_futura` (solo «Nueva partida», sin confirmación) | UI |
| TR-title-006 (provisional) | pantalla-de-titulo | 27 | «Continuar» llama `continuar()` y «Nueva partida» `nueva_partida()` de 5; 27 NUNCA pide la carga de `planta` (la pide 5 a 4; AC-11); título solo bloquea entradas y queda inerte hasta «carga de escena terminada» o «carga de escena fallida» | Scene |
| TR-title-007 (provisional) | pantalla-de-titulo | 27 | Entradas ignoradas (no encoladas) durante fundido o carga; doble pulsación de «Continuar» ignorada | Input |
| TR-title-008 (provisional) | pantalla-de-titulo | 27 | Navegación completa con teclado (`ui_up/down/accept/cancel`), mando y ratón; `ui_cancel` en menú principal no hace nada; foco visible con borde/marca; ratón no mueve foco hasta moverse; contexto de Entrada `menú` | Input |
| TR-title-009 (provisional) | pantalla-de-titulo | 27 | Salir con `SceneTree.quit()` sin confirmación, solo PC (incl. Steam Deck). **NOT SOURCEABLE** (no verificado en engine-reference; PV AC-15) | Core |
| TR-title-010 (provisional) | pantalla-de-titulo | 27 | Opciones reutiliza como componente las pantallas de nivel 2 de 25 («Sonido y pantalla», «Accesibilidad», «Controles»), sin filas «Reanudar», «Pistas», «Nueva partida», «Volver al título», más «Avisos de contenido»; dependencia dura de 27 sobre 25 y 30, sin ciclo | UI |
| TR-title-011 (provisional) | pantalla-de-titulo | 27 | Aviso de partida dañada/versión futura/`con_futura`: línea no modal una vez por arranque (variable de sesión, no guardada); icono + palabra clave, sin color como único canal; sin audio | UI |
| TR-title-012 (provisional) | pantalla-de-titulo | 27 | Fallo de carga: panel centrado sobre la cortina negra (de 4) con texto de emergencia de 18 y fallback fijo en español si 18 falla; única acción «Volver al título» que pide a 4 la descarga total, luego re-inspección y menú con resultado intacto | Scene |
| TR-title-013 (provisional) | pantalla-de-titulo | 27 | Cierre: reacciona a «tarjeta final pedida» de 21; pinta tarjeta fija «Continuará»+título durante `t_tarjeta_s` (3,0 s, de 21) + `t_fundido`; sin salto ni entrada; 21 pide la descarga total tras la tarjeta; créditos opcionales (OQ 7, 1 página estática) | Scene |
| TR-title-014 (provisional) | pantalla-de-titulo | 27 | Fundido F1: `t_fundido_base_s`=0,8 s† (0,3–1,5); con `reducir_movimiento` o `reducir_sobresaltos` 0,1 s (`t_fundido_reducido_s`/`reduce_motion_fade_s` de 6, no es knob de 27); `t_visible_tarjeta` = 3,8 s / 3,1 s | Accessibility |
| TR-title-015 (provisional) | pantalla-de-titulo | 27 | Texto escala con `escala_texto_ui` de 6 sin bajar de `tam_min_px`=24 px lógicos; todas las pantallas caben a 1280x720 y 3840x2160 sin recorte (captura retenida en `production/qa/evidence/`) | Accessibility |
| TR-title-016 (provisional) | pantalla-de-titulo | 27 | Desconexión de mando en el título: no abre el panel «Mando desconectado» de 25; pasa a teclado/ratón conservando el foco (PV); cambio de dispositivo actualiza glifos; pérdida de foco de ventana no pausa | Input |
| TR-title-017 (provisional) | pantalla-de-titulo | 27 | Sin persistencia propia: 27 no escribe hechos; solo `advertencias_vistas` y ajustes vía 6; defectos si 6 falta/está dañado sin error al jugador; cierre durante tarjeta/créditos deja la partida sellada y al volver solo «Nueva partida» | Save/Load |
| TR-title-018 (provisional) | pantalla-de-titulo | 27 | Tests gdUnit4 en `tests/unit/title/` con dobles de 5 y reloj falso; solo español en el slice (sin cambio de idioma) | Tooling |

### Contratos — pantalla-de-titulo (27)

| Aspecto | Detalle |
|---|---|
| Emite | Ningún aviso nombrado. Peticiones: `continuar()` y `nueva_partida()` a 5; petición de descarga total a 4 tras fallo de carga; peticiones de contexto `menú` a 1; escritura de `advertencias_vistas` y de ajustes a 6 |
| Consume | «tarjeta final pedida» (21), «carga de escena terminada», «carga de escena fallida», «descarga total completada», estado «Sin partida» de 5, resultado de inspección (`terminada`, `con_futura`, `ninguna`, `valida`, `irrecuperable`, `version_futura`, `desconocido`), ajustes de 6 (`reducir_movimiento`, `reducir_sobresaltos`, `escala_texto_ui`) |
| API pública (de 5, consumida) | `continuar()`, `nueva_partida()`; 27 no declara API pública propia |
| Estado | Propio volátil: aviso mostrado en la sesión, lista de filas; persistido (vía 6): `advertencias_vistas`† |
| Nodo/autoload | No nombrado; escena de título (menú, advertencias, panel de error, tarjeta, créditos) con foco/contexto `menú`; no autoload |

## NO LEÍDO

- Todos los GDD: Overview, Player Fantasy, Edge Cases (salvo los de título), Datos, Decisiones tomadas, Open Questions, Cambios requeridos, Entradas para el registro, Historial.
- audio: Edge Cases (288-303) y Datos (391-429; contiene el catálogo/`audio_catalog.json` y tamaños de fichero).
- subs: Edge Cases (98-115), Decisiones tomadas, Open Questions (OQ 2, 8), Cambios requeridos.
- title: Overview (14-43; tabla de resultado→filas), Open Questions (OQ 1, 3, 7-10), Cambios requeridos.

## Huecos detectados

- No existe en ningún GDD un nombre exacto de nodo/autoload ni firmas GDScript; todo se deriva a ADR (audio, UI).
- Verificar en 4.7 (declarados no verificados): `process_mode` de 23, `stream_paused`, limitador de techo/filtros en bus, `SceneTree.quit()`, señales de mando; AccessKit para lector de pantalla.
- Audio del título (OQ 1 de 27 / OQ 3 de 23) sin cerrar; `seg_b_inicio_s` de 18 y «línea iniciada» pendientes de confirmar entre 18/23/26.
- Conflicto potencial a revisar: 23 declara ducking/lluvia con valores † y 26 vincula `t_lectura_s` a 23 F3 (única fuente).

---

<!-- bloque G10 -->
# Baseline TR — grupo 10 (atmos, shaders, a11y)

Leyenda: ‡ = el GDD declara la afirmación del motor sin verificar / sin cobertura en engine-reference; PV = pendiente de verificación (spike).

## 28 atmosfera-reactiva (slug `atmos`)

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-atmos-001 (provisional) | atmosfera-reactiva | 28 | Autoload `Atmosphere` (`atmosphere_director.gd`) guarda el estado volátil y escucha el bus; cada escena de planta trae un nodo `AtmosphereZone` (`atmosphere_zone.gd`) que registra luces, ventanas y espejo (6 escenas) | Core |
| TR-atmos-002 (provisional) | atmosfera-reactiva | 28 | 28 no depende de 21 ni de 29: solo se comunica por el bus; funciona sin 29 con `StandardMaterial3D`, `Light3D`, `GPUParticles3D` y un `ShaderMaterial` mínimo | Events |
| TR-atmos-003 (provisional) | atmosfera-reactiva | 28 | Solo lectura de hechos y ajustes; su estado es memoria volátil derivada de hechos y NO se guarda ni persiste; tras «Continuar» se recalcula (apagón con duración 0 si `caja_completa` ∧ ¬`llamada_completada`; `NORMAL` si `llamada_completada`) | Save/Load |
| TR-atmos-004 (provisional) | atmosfera-reactiva | 28 | Valores de luces/tiempos/umbrales en `assets/data/atmosphere/atmosphere.json` (perfil por zona, `zone_profiles`); sin números en script salvo constantes de seguridad | Data |
| TR-atmos-005 (provisional) | atmosfera-reactiva | 28 | Constantes de código con prueba: `FLASH_MAX_HZ` 2,0, `FLASH_PAUSE_MIN_S` 0,35, 3 destellos/s, `FLASH_DEPTH_FLOOR` 0,40; una errata de datos no puede violarlas | Accessibility |
| TR-atmos-006 (provisional) | atmosfera-reactiva | 28 | Limitador de destellos global, no desactivable: ≤ 2 ciclos/s, pausa ≥ 0,35 s, ≤ 3 destellos por ventana deslizante de 1 s, sin destellos de área saturada roja; fusiona caídas sobrantes con `push_warning`; prioridad apagón > parpadeo `C03` > tubo | Accessibility |
| TR-atmos-007 (provisional) | atmosfera-reactiva | 28 | Máquina `LightState` por zona (`NORMAL`, `FLICKER`, `APAGON`, `RESTAURANDO`); órdenes idempotentes ejecutadas en el fotograma de recepción; orden desconocida → `push_warning` sin bloquear | Scene |
| TR-atmos-008 (provisional) | atmosfera-reactiva | 28 | Cambios de luz con `Tween` sobre `light_energy` (sin cambiar color); apagón 0,4 s monótono (0,8 s con `reducir_sobresaltos`), restauración 2,0 s monótona; suelo de ambiente 0,06 (nunca negro puro) | Rendering |
| TR-atmos-009 (provisional) | atmosfera-reactiva | 28 | Reflejo retardado de `C02`: proxy low poly ≤ 400 tris, 1 draw call, 0 `SubViewport`, sin cámara espejada; posición reflejada por plano (F2) en cada `_process` con `Jugador.pose_con_retardo(τ)`; sin escala negativa (determinante negativo en 4.7 no verificado, OQ 4) | Rendering |
| TR-atmos-010 (provisional) | atmosfera-reactiva | 28 | Requisito sobre 2: las manos conservan luz mínima en el apagón (razón manos/entorno ≥ 1,5:1); mecanismo (máscara, segunda cámara, shader) sin decidir (spike A/B, ADR) | Rendering |
| TR-atmos-011 (provisional) | atmosfera-reactiva | 28 | Máquina del reflejo `OFF/ENTRANDO/ACTIVO/SALIENDO`, retardo 0,6 s ≤ `T_hist` (1,0 s), una sola vez por partida; salida por `giro_acumulado() ≥ 45°` en 0,5 s y ≥ 1,0 s activo, o a 3,0 s | Animation |
| TR-atmos-012 (provisional) | atmosfera-reactiva | 28 | Con `reducir_movimiento`: fundido cruzado 0,5 s/0,35 s entre dos proxies en vez de interpolar τ; valor leído en cada disparo | Accessibility |
| TR-atmos-013 (provisional) | atmosfera-reactiva | 28 | 28 posee TODO reflejo: `ReflectionProbe` de Sala de Reuniones sin retardo con intensidad ≤ `reflection_strength_max` (0,15†, publicada por 29); no toca `mat_glass_memo` ni usa `pose_con_retardo` en P2/P5 (grupo `reflejo_retardado` solo `C02`) | Rendering |
| TR-atmos-014 (provisional) | atmosfera-reactiva | 28 | Lluvia: `GPUParticles3D` por ventanal (3 ventanales B, D, R03), ≤ 200 partículas/ventanal y ≤ 500 totales, mallas de 2 tris, sin sombras, blend aditivo o alfa recortada; `lluvia_nivel` 0–1 por zona derivado de `perfil_dB` de 23 | Rendering |
| TR-atmos-015 (provisional) | atmosfera-reactiva | 28 | Shader propio `rain_glass.gdshader` (spatial, transparente, blend mix, 2 capas de ruido 512²), sin `hint_screen_texture`; sustituible por 29 vía ruta en `atmosphere.json` | Rendering |
| TR-atmos-016 (provisional) | atmosfera-reactiva | 28 | Presupuesto: ≤ 8 luces dinámicas visibles, ≤ 2 con sombra, ≤ 14 cargadas por escena, GPU de 28 ≤ 1,0 ms, CPU ≤ 0,15 ms media / 0,5 ms pico, texturas ≤ 8 MB, overdraw ≤ 3 capas, 60 fps en 99 % de fotogramas (16,6 ms). PV hasta el spike OQ 10 en hardware mínimo | Rendering |
| TR-atmos-017 (provisional) | atmosfera-reactiva | 28 | 28 posee el presupuesto total de luces y sombras; P2 (`SpotLight3D`, hasta 1 sombra) cuenta dentro; sin `LightmapGI` (art bible §9); Forward+ | Rendering |
| TR-atmos-018 (provisional) | atmosfera-reactiva | 28 | Pausa: congelar `Tween` (`TWEEN_PAUSE_STOP` ‡) y `GPUParticles3D` con «pausa abierta/cerrada», reanudar sin saltos. AC-28-16 PV | Core |
| TR-atmos-019 (provisional) | atmosfera-reactiva | 28 | Recursos de material sustituibles (`rain_glass_material`, `mirror_glass_material`, `rain_particles_material`) cargados con `load()` síncrono ≤ 1 MB, con material por defecto y `push_error` si faltan | Data |
| TR-atmos-020 (provisional) | atmosfera-reactiva | 28 | Parpadeo ambiente del Archivo determinista (`seed_archivo` 20261109, sin `randf()` sin semilla): 2 parpadeos/20 s; tubo de Recepción parpadea una vez en «escena lista» | Rendering |

Notas ‡/PV del GDD: `Tween.set_pause_mode`, pausa de `GPUParticles3D`, API de «efecto de escena pedido», `ReflectionProbe` y monitor «Objects in frame» sin cobertura en engine-reference; AC-28-16 y AC-28-19 son PV (spike OQ 10, ADR pausa OQ 12).

### Contratos 28

| Aspecto | Contenido |
|---|---|
| Emite | Nada al bus (no emite ni escribe hechos). Solo `push_warning`/`push_error` |
| Consume | «efecto de escena pedido» {`id`, `objetivo`, `duración`, `parámetros`} ‡ de 21 vía 3 con ids `LUCES_PARPADEO`, `REFLEJO_RETARDADO`, `LUCES_APAGON`, `LUCES_RESTAURAR`, `LLUVIA_REALCE`, `LLUVIA_CESA`, `LLUVIA_VUELVE`; `EV_PUZZLE_SOLVED_<ID>` (sin datos); cambio de `caja_completa`/`llamada_completada` (respaldo); «ajustes aplicados»/cambio de `reducir_sobresaltos`, `reducir_movimiento`; «pausa abierta»/«pausa cerrada» (25); «escena lista» (21/4). No consume «interacción ejecutada» |
| API pública | Del GDD solo se nombran llamadas que 28 USA: `Jugador.pose_con_retardo(τ)`, `Jugador.giro_acumulado()`. API propia sin firma nombrada (HUECO); nombres de clases: `Atmosphere`, `AtmosphereZone` |
| Estado | Volátil: `LightState` por zona, `apagon_visible`, `lluvia_nivel` por zona, estado/τ del reflejo, registro del limitador. Nada persistido |
| Nodo propuesto | Autoload `Atmosphere` (`atmosphere_director.gd`) + `AtmosphereZone` (`atmosphere_zone.gd`) por escena; datos en `atmosphere.json` |


## 29 shaders-y-efectos (slug `shaders`)

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-shaders-001 (provisional) | shaders-y-efectos | 29 | Solo presentación y determinista: 29 no escribe hechos ni avisos, no evalúa soluciones; cada efecto es una orden con parámetros | Core |
| TR-shaders-002 (provisional) | shaders-y-efectos | 29 | Tres shaders `spatial` en `assets/shaders/` (`spatial_surface_glass_memo`, `spatial_surface_mirror_photo`, `spatial_fx_outline_mask`), un shader por archivo, nombres `[type]_[category]_[name].gdshader` | Rendering |
| TR-shaders-003 (provisional) | shaders-y-efectos | 29 | Prohibido `hint_screen_texture` e `hint_depth_texture`, sin compute; coste de evitar pase completo NOT SOURCEABLE ‡ (`rendering.md` no cubre `hint_*`); Forward+ único objetivo (Compatibility/Mobile no verificado) | Rendering |
| TR-shaders-004 (provisional) | shaders-y-efectos | 29 | `mat_glass_memo`: un material, un pase, `blend_mix`, `unshaded`, `depth_draw_never`, `render_priority` 0 (NOT SOURCEABLE ‡) que compone película+fragmentos+previa+halo; ≤ 3 muestras de textura por píxel | Rendering |
| TR-shaders-005 (provisional) | shaders-y-efectos | 29 | Contorno `outline_mask`: `blend_mix`, `render_priority` 3 (‡ NOT SOURCEABLE), dilatación ≤ 4 muestras extra, o casco invertido `cull_front`; sin `discard` salvo spike | Rendering |
| TR-shaders-006 (provisional) | shaders-y-efectos | 29 | `instance uniform` solo escalares o `vec4` (nunca arrays), p. ej. `frag_alpha` vec4; comportamiento en 4.7.2 NO VERIFICADO; fallback: un `ShaderMaterial` por instancia | Rendering |
| TR-shaders-007 (provisional) | shaders-y-efectos | 29 | `#include` de `fx_common.gdshaderinc` NO VERIFICADO en 4.7.2; fallback duplicar utilidades. Shader Baker (4.5+) con `instance uniform` NO VERIFICADO; alternativa: precalentar material al abrir vista (sin tirón > 50 ms) | Rendering |
| TR-shaders-008 (provisional) | shaders-y-efectos | 29 | Spike previo en 4.7.2 Forward+ (instance uniform, `#include`, Shader Baker, precalentamiento) con resultado en un ADR en `docs/architecture/` antes de implementar | Tooling |
| TR-shaders-009 (provisional) | shaders-y-efectos | 29 | Presupuesto F29-7: GPU total ≤ 0,5 ms a 1080p (glass ≤ 0,20, mirror ≤ 0,10, todos los contornos ≤ 0,15, margen 0,05), ≤ 6 draw calls añadidos por vista, ≤ 3 texturas/píxel; TODO sin medir (†), hardware de referencia por fijar (Q9) | Rendering |
| TR-shaders-010 (provisional) | shaders-y-efectos | 29 | Legibilidad: contraste de texto C ≥ 4,5 (F29-2) con `L_film` ≤ 0,06, `L_txt` ≥ 0,80, reflejo ≤ `reflection_strength_max` 0,15; medido en captura con el `Environment` del nivel (HDR/glow 4.6–4.7 sobre `unshaded` NOT SOURCEABLE, posiblemente falso) | Accessibility |
| TR-shaders-011 (provisional) | shaders-y-efectos | 29 | Altura mínima de glifo ≥ 14 px a 1080p con fov vertical máximo 90° (`x_h_min` 0,032 m); 720p queda en 9,5 px aceptado | Accessibility |
| TR-shaders-012 (provisional) | shaders-y-efectos | 29 | Sin destellos: ningún par de transiciones opuestas > 0,25 de luminancia relativa en 333 ms ni pulso > 2 Hz; fundido único monótono de 100 ms permitido con `reducir_movimiento`; `MIRROR_PREVIEW` mantiene ≥ 333 ms | Accessibility |
| TR-shaders-013 (provisional) | shaders-y-efectos | 29 | Sin dependencia de color: halo (anillo doble), `MARK_LIT` (4 marcas de esquina), contorno doble y marcador de punta en `FLOOR_MARKS` distinguibles por forma/luminancia (AC-14: gris y 3 daltonismos) | Accessibility |
| TR-shaders-014 (provisional) | shaders-y-efectos | 29 | Solo lee `reducir_movimiento` (al construirse + señal de cambio; afecta a la siguiente orden) y `campo_vision` (60–90° vertical, defecto 70°) de 6; no lee `reducir_sobresaltos` | Accessibility |
| TR-shaders-015 (provisional) | shaders-y-efectos | 29 | Registro de objetivos: nodo `FxTarget` (`target_id`, máscara, mesh/quad) por escena; `target_id` sin `FxTarget` → `push_warning`, sin fallo | Scene |
| TR-shaders-016 (provisional) | shaders-y-efectos | 29 | Fallback en producción: si falla compilar/falta el `ShaderMaterial`, `SurfaceFx` cae a implementación provisional (`StandardMaterial3D` unshaded + quads) con un `push_error`; misma API (patrón estrategia) | Rendering |
| TR-shaders-017 (provisional) | shaders-y-efectos | 29 | Pausa: envolventes con reloj de juego y `Tween` `PROCESS_MODE_PAUSABLE`/`TWEEN_PAUSE_STOP` ‡; `TIME` en shader no se congela en pausa NOT SOURCEABLE ‡, así que no se usa salvo `film_breath` con fase por uniform. AC-21 PV | Core |
| TR-shaders-018 (provisional) | shaders-y-efectos | 29 | Registro de foto reflejada vs caja en θ\* con error ≤ 1 px a 1080p: misma textura, filtro (`filter_linear_mipmap`), UV, `texture_repeat` off; rotación UV con corrección de aspecto; sin término dependiente de θ salvo rotación; `fwidth(UV)` para el contorno NOT SOURCEABLE ‡ | Rendering |
| TR-shaders-019 (provisional) | shaders-y-efectos | 29 | Valores en `Resource` `fx_config.tres` por superficie, no en el shader; texto del cristal como textura pregenerada desde `DOC_01` (18), no `Label3D`, no traducible en tiempo real | Data |
| TR-shaders-020 (provisional) | shaders-y-efectos | 29 | `FLOOR_MARKS` sin shader: `StandardMaterial3D` con `emission_energy_multiplier` animado por `Tween` | Rendering |

### Contratos 29

| Aspecto | Contenido |
|---|---|
| Emite | Nada (no emite ni escribe hechos/avisos); `push_warning`/`push_error` |
| Consume | Órdenes de 12 (`set_fragment`, `MIRROR_PREVIEW`, `BEAM_HALO`, `FLOOR_MARKS`, `play_resolution` de P2), de 15 (`theta_deg`, `FADE`, `OUTLINE`, `restore_solved_presentation()` sin efectos), de 9 (`HIGHLIGHT`, `AFFORDANCE`, `MARK_LIT`), «señal de cambio» de `reducir_movimiento` y `campo_vision` (6). Vía señal o llamada directa (sin decidir). Constante publicada hacia 28: `reflection_strength_max` (0,15) |
| API pública (propuesta ‡, nodo `SurfaceFx`) | `set_fragment(id, visible)`, `play_mirror_preview(fragment, duration_s)`, `set_beam_halo(points)`, `play_highlight(target_id, duration_s)`, `stop_highlight(target_id)`, `set_mark_lit(target_id)`, `play_fade(duration_s)`, `play_outline(duration_s)`, `set_theta(theta_deg)`, `clear_all()` (sin tipos de retorno en el GDD) |
| Estado | Volátil: `frag_alpha` por fragmento, envolventes, θ; `MARK_LIT` NO se guarda (9/15 reemiten al abrir la vista) |
| Nodo propuesto | `SurfaceFx` por escena de vista de puzle (NO autoload, inyección de dependencias) + `FxTarget` por objeto resaltable; `fx_config.tres` |


## 30 opciones-de-accesibilidad (slug `a11y`)

| TR | GDD | Sistema | Requisito | Dominio |
|---|---|---|---|---|
| TR-a11y-001 (provisional) | opciones-de-accesibilidad | 30 | Nivel objetivo del slice «Estándar» (WCAG 2.1 AA parcial en UI; 1.4.4 solo hasta 150 %); Completo (filtros de daltonismo, alto contraste, mono, lector, 200 %) fuera; compromiso ante financiadores pendiente del usuario (OQ 8) | Accessibility |
| TR-a11y-002 (provisional) | opciones-de-accesibilidad | 30 | 30 no tiene pantalla ni claves propias: catálogo de ajustes con claves en 6 (salvo `controles` en 1), pestaña «Accesibilidad» de 25 reutilizada en título (27); orden fijo de 4 grupos (Lectura, Confort y movimiento, Ayudas de puzle, Restablecer) | UI |
| TR-a11y-003 (provisional) | opciones-de-accesibilidad | 30 | «Restablecer todos» restaura 18 claves (fijado por 6 regla 8); `advertencias_vistas` no se restablece | Save/Load |
| TR-a11y-004 (provisional) | opciones-de-accesibilidad | 30 | `escala_texto_ui` enum {`1_00`,`1_25`,`1_50`} (defecto `1_00`), aplicada en el fotograma del aviso sin reiniciar ni pausar; valor desconocido → defecto | Accessibility |
| TR-a11y-005 (provisional) | opciones-de-accesibilidad | 30 | F1: `tam_px = tam_base_px × escala_texto_ui × (alto_ventana_px/1080)`; suelo `tam_min_px` 24 px lógicos a 1080p (16 px reales a 720p), 720p mínimo soportado | UI |
| TR-a11y-006 (provisional) | opciones-de-accesibilidad | 30 | Conflicto F1 vs `content_scale_mode`/`stretch` de Godot: si la UI usa `canvas_items` base 1920x1080 F1 duplicaría el factor; escalado de UI NO decidido ni cubierto por engine-reference; ADR de UI antes de implementar | UI |
| TR-a11y-007 (provisional) | opciones-de-accesibilidad | 30 | Reflow, no recorte: con 1,50 los contenedores crecen/hacen scroll, sin solapes ni acciones fuera de pantalla; objetivos de pulsación ≥ 44 px (`objetivo_min_px`/`pick_min_px`) | UI |
| TR-a11y-008 (provisional) | opciones-de-accesibilidad | 30 | `escala_texto_ui` no escala subtítulos (`subtitulos_tamano` aparte) ni iconos (`icono_grande`) ni texto diegético fuera de la vista de enfoque | UI |
| TR-a11y-009 (provisional) | opciones-de-accesibilidad | 30 | Contraste: texto UI ≥ 4,5:1 y bordes de control/foco ≥ 3:1 (SC 1.4.3/1.4.11) medidos en captura; AC-30-04 BLOCKING | Accessibility |
| TR-a11y-010 (provisional) | opciones-de-accesibilidad | 30 | Definición única de «destello»: par de cambios opuestos ≥ 10 % del rango, estado oscuro < 0,80, área > 25 % del campo visual, ventana deslizante 1 s; tope duro siempre activo ≤ 3/s (`tope_destellos_s`) y luces de 28 ≤ 2 ciclos/s con pausas ≥ 0,35 s | Accessibility |
| TR-a11y-011 (provisional) | opciones-de-accesibilidad | 30 | Tope de destellos verificado en vídeo a 60 fps con herramienta de análisis (PEAT, disponibilidad NO verificada) sobre secuencias de 28, 29, 24, 21 (AC-30-13); script de luminancia por fotograma en `tools/` | Tooling |
| TR-a11y-012 (provisional) | opciones-de-accesibilidad | 30 | `reducir_movimiento` única clave de movimiento: fundidos fijos de 100 ms (rango único 50–150 ms; `reduce_motion_fade_s` de 6) en todos los sistemas, incl. 27 (de 0,15 s a 100 ms); `LUCES_PARPADEO` → una atenuación de 0,6 s | Accessibility |
| TR-a11y-013 (provisional) | opciones-de-accesibilidad | 30 | Lectores de `reducir_movimiento`: 9, 4, 19, 21, 28, 24 (en 6); pendiente en 6: 10; P6 no la lee (D16-3); alcance más allá del slice §14 pendiente (OQ 10) | Accessibility |
| TR-a11y-014 (provisional) | opciones-de-accesibilidad | 30 | Lectura de ajustes en el fotograma del aviso de cambio (28 lee `reducir_sobresaltos` y `reducir_movimiento`); con cualquiera activa se atenúa sin eliminar | Events |
| TR-a11y-015 (provisional) | opciones-de-accesibilidad | 30 | Lector de pantalla fuera del slice pero preparado: todo `Control` de 25/27 con nombre accesible = texto visible y orden de foco visual; AccessKit desde 4.5, `Control.accessibility_live` (4.7); nombre de propiedad y orden de foco NO VERIFICADOS (AC-30-16 PV) | Accessibility |
| TR-a11y-016 (provisional) | opciones-de-accesibilidad | 30 | Ningún puzle con temporizador de solución ni sin asistencia a la precisión: P3 radio de encaje 0,04 m / 0,10 m con `asistencia_encaje`; P5 ±3° / ±6° con `asistencia_rotacion`; dwell P5 `hold_s` 0,8 s† no suprimible (OQ 9) | Accessibility |
| TR-a11y-017 (provisional) | opciones-de-accesibilidad | 30 | Sin color como único canal en los 6 puzles y UI; sin filtros de daltonismo; P3 pendiente de que 13 declare que el contorno determina el hueco (AC-30-05 BLOCKING con simulación CVD) | Accessibility |
| TR-a11y-018 (provisional) | opciones-de-accesibilidad | 30 | Alternar en vez de mantener para `leer`, `mantener`, `agarrar`, `rotar` (en 1; BLOCKING antes de dar el slice por accesible); jugable solo teclado+ratón o solo mando, con teclado en pantalla de 19 R16 (riesgo: cursor oculto en la llamada, OQ 5) | Input |
| TR-a11y-019 (provisional) | opciones-de-accesibilidad | 30 | Equivalente visual/texto para todo sonido con función de juego (tabla «sonido → equivalente» de 23, AC-30-11) y subtítulos para toda voz | Audio |
| TR-a11y-020 (provisional) | opciones-de-accesibilidad | 30 | Textos de ayuda `UI_ACC_*` † en la tabla de 18; una línea, segunda línea si no cabe con 1,5 | Localization |

### Contratos 30

| Aspecto | Contenido |
|---|---|
| Emite | Nada (GDD de normas y verificación; sin avisos ni señales) |
| Consume | Claves de 6: `subtitulos_activos`, `subtitulos_tamano`, `subtitulos_fondo`, `subtitulos_hablante`, `vol_voces`, `vol_efectos`, `vol_musica`, `reducir_sobresaltos`, `reducir_movimiento`, `balanceo_camara` (enum, defecto `reducido`), `campo_vision` (60–90, paso 5, 70), `multiplicador_pie`, `pie_persistente`, `icono_grande`, `etiqueta_accion_visible`, `escala_texto_ui` †, `asistencia_encaje`, `asistencia_rotacion`; `controles` de 1. Avisos de cambio de ajustes (6). No se nombra un aviso exacto |
| API pública | Ninguna firma (HUECO: solo reglas; API de reasignación es de 1, de ajustes es de 6) |
| Estado | No posee ni persiste; claves viven en 6 (`escala_texto_ui` †, enum) |
| Nodo propuesto | Ninguno (sin pantalla propia; filas en pestaña de 25). Posible utilidad de cálculo F1 en UI, sin decidir |

## NO LEÍDO

Secciones fuera de alcance, no leídas en los tres GDDs: Summary, Overview, Player Fantasy, Edge Cases, Decisiones tomadas, Open Questions, Cambios requeridos, Entradas para el registro, Historial. Se citan OQ por número pero no se leyeron (atmos OQ 1, 4, 6, 8, 10, 12; shaders Q7, Q9; a11y OQ 1, 2, 5, 8, 9, 10). Sin cobertura del GDD: firma de la API propia de 28; mecanismo de las manos en el apagón; render order/`render_priority` (NOT SOURCEABLE).
