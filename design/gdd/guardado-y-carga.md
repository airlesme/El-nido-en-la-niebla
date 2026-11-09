# Guardado y carga

> **Status**: Designed (pendiente de design-review)
> **Author**: Álvaro + agentes
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Tensión sin castigo (cerrar y volver nunca pierde ni repite progreso, y no hay softlock) · Autonomía como progresión (el progreso es de los hechos del jugador, no de un menú de guardado)

## Summary

Es la memoria de la partida entre sesiones: guarda de forma automática, en momentos fijos del slice, los 19 hechos del juego en un único fichero y los restaura al pulsar «Continuar». No hay guardado manual ni varias ranuras; el jugador solo ve «Continuar» y «Nueva partida». Protege el progreso con escritura atómica, una generación anterior de respaldo y una suma de comprobación, de modo que un fichero dañado nunca impide jugar ni deja la historia sin salida. Existe para sostener *Tensión sin castigo* en lo técnico: cerrar el juego en cualquier momento, incluso durante la llamada, y volver nunca deja al jugador atrapado.

> **Quick reference** — Layer: `Core` (categoría `Persistence`) · Priority: `MVP` · Key deps: `3 Estado y bus de eventos` (dura) · `4 Escena de planta y carga de Recepción` (dura)

## Overview

Guardado y carga convierte el estado del juego (sistema 3) en un fichero y de vuelta. El slice (§13.2 y Anexo D.3) fija el comportamiento visible: guardado **automático** al abrir cualquier puerta, al completar cada compartimento de la caja y al iniciar la llamada; **sin guardado manual**; si el jugador cierra durante la llamada, vuelve al despacho con la llamada pendiente; si cierra durante la revelación del puzle 5, vuelve con `pendiente_revelacion` verdadero. Este sistema implementa eso y añade lo que el slice no dice pero necesita para ser fiable: qué contiene el fichero, cómo se escribe sin riesgo, cómo se detecta y se sortea un fichero dañado, cómo se versiona y cómo se garantiza que cualquier guardado producido por las reglas es continuable.

Lo que se guarda son **hechos, no escena**: los 19 hechos del Anexo D.2 (a través de la instantánea del sistema 3) y unos pocos metadatos. No se guarda la posición del jugador, ni temporizadores, ni el estado interno de los elementos de la escena. Reanudar siempre reconstruye la planta desde los hechos y coloca al jugador en `spawn_office` (GDD de Escena de planta, regla 10). Eso es lo que hace al sistema simple y robusto, y lo que obliga a que cada elemento sea reconstruible desde sus hechos.

El jugador no opera el sistema: solo ve «Continuar» (activo si hay partida), «Nueva partida» (con confirmación si va a sustituir una partida) y, en el caso poco frecuente de que el guardado falle de forma persistente o no se pueda recuperar, un aviso discreto y no bloqueante. Los ajustes (volumen, subtítulos, controles) **no** forman parte de la partida: viven en su propio fichero (GDD de Ajustes persistentes, regla 3). Este sistema reutiliza sus estrategias (escritura atómica, copia del fichero dañado, número de versión de formato) para ser coherente, pero no depende de él.

## Detailed Design

### Core Rules

‡ = propuesta que debe confirmar el GDD del sistema afectado. † = valor propuesto, a validar en playtest. Los nombres de ficheros, claves y avisos son identificadores de código (inglés).

**Qué se guarda**

1. **Una sola partida, una sola ranura.** No hay guardado manual, ni selección de ranura, ni varias partidas (slice §13.2). El fichero es `autosave.json` en la carpeta de datos del usuario (`user://saves/` en Godot; ruta definitiva en un ADR, Open Questions 1).
2. **Contenido del fichero** (la «envoltura», versión de formato `format_version`):

   | Clave | Tipo | Qué es |
   |---|---|---|
   | `format_version` | int | Versión de formato de la envoltura. Vale `1` en el slice. Constante de código, no un dato configurable |
   | `seq` | int ≥ 1 | Contador de guardado, creciente. Decide cuál es la partida más reciente (F4); no depende del reloj del sistema |
   | `saved_at_utc` | texto ISO 8601 | Solo informativo (registro, y la pantalla de título si lo quiere mostrar). Nunca decide nada |
   | `build` | texto | Versión de la build que escribió el fichero. Solo para el registro |
   | `cause` | texto | Causa del guardado (tabla de la regla 6, p. ej. `door_opened:D`). Solo para el registro y las pruebas |
   | `snapshot` | objeto | La instantánea del sistema 3 (mapa nombre → valor con su propia `snapshot_version`), tal cual |
   | `checksum` | texto hex | Suma de comprobación del resto del fichero (F3) |

3. **Qué no se guarda:** posición ni orientación del jugador, temporizadores, estado de la llamada más allá de sus hechos, estado interno de los puzles que no sea un hecho (p. ej. dónde está la ficha de «Carta a Dirección» sobre la mesa, el estado de un encaje a medias), ajustes, y cualquier cosa del sistema de audio o de atmósfera. Al reanudar, esos elementos nacen en su estado inicial (esto es compatible con el slice §13.3: la ficha vuelve a la mesa sin decidir y el compartimento sigue sin resolver).
4. **Los ajustes quedan fuera.** Este sistema no lee ni escribe los ajustes (6); un fichero de partida no contiene ninguna clave de ajustes y cambiar de partida no toca los ajustes.

**Cuándo se guarda**

5. **Un guardado se pide, no se hace al instante.** Cada causa de la regla 6 *pide* un guardado. La petición espera a que la cola de avisos del sistema 3 esté vacía (GDD del 3, casos límite de guardado), de modo que la instantánea nunca contiene un cambio a medias (p. ej. `caja_c4` sin su derivado `caja_completa`). Varias peticiones dentro de la ventana `t_agrupar` se funden en una sola escritura (F1).
6. **Causas de guardado.** Las tres primeras son las del slice (Anexo D.3) y son obligatorias; el resto amplía la cobertura sin contradecir el slice y se pueden desactivar en datos (Tuning Knobs).

   | Causa (`cause`) | Origen | Urgente | Motivo |
   |---|---|---|---|
   | `door_opened:<ID>` | Aviso «puerta abierta» (cualquier puerta) | No | Slice D.3 |
   | `compartment_done:<n>` | Aviso «compartimento completado» (1 a 4) | No | Slice D.3 |
   | `call_started` | Aviso «llamada iniciada» | Sí (guardado de sellado, regla 11) | Slice D.3 |
   | `puzzle_solved:<ID>` | Cualquier `EV_PUZZLE_SOLVED_*` | No | Sin esta causa, resolver el puzle 1 o el 2 se perdería hasta la siguiente puerta (el puzle 1 entrega las tarjetas; el 2 fija `memo_leido`) |
   | `reveal_pending` | Cambio de `pendiente_revelacion` en cualquier sentido | No | Slice D.3: cerrar durante la revelación del puzle 5 reanuda con `pendiente_revelacion` verdadero; debe estar guardado |
   | `pause_opened` | Apertura del menú de pausa (25) | No | Misma razón que en Ajustes (regla 13): el jugador que se va suele pausar antes |
   | `quit` | Cierre normal del juego, o «salir al título» | Sí | Cubre lo hecho desde el último guardado (lámparas del puzle 2, `correos_leidos`, `formulario_leido`) |
   | `periodic` | Cada `t_periodico` de tiempo real en partida, si cambió algo | No | Limita la pérdida ante un cierre forzado (regla 14) |

7. **Solo se escribe si algo cambió.** Antes de escribir se compara el contenido de la instantánea (F3, sin `seq` ni `saved_at_utc`) con el último escrito o cargado; si es igual, no se escribe (no se gasta `seq` ni se rota el respaldo). Es lo que hace inocuas las causas repetidas, `pause_opened` y `periodic`.
8. **Qué momentos no guardan.**
   - **Durante «Cargando partida»** (desde que se pide continuar hasta «carga de escena terminada», GDD de Escena de planta, regla 9): se ignoran todas las causas, no se encolan. Los elementos al configurarse pueden emitir avisos (p. ej. una puerta ya abierta) y no deben provocar una reescritura de lo que acaba de cargarse.
   - **Fuera de partida** (en el título, antes de «Nueva partida» o «Continuar»): no hay nada que guardar.
   - **Con la partida sellada** (regla 11): nada.
9. **Escenas temporizadas.** El guardado guarda hechos, y los hechos son siempre coherentes entre sí tras vaciar la cola (regla 5), así que es válido guardar en mitad de cualquier escena, incluido el apagón. Un temporizador en curso no se guarda: al reanudar, la escena se rehace desde los hechos (reglas 3 y 18). Los tiempos que cada escena necesite (los 60 s del teléfono, los 20 s de la llamada) empiezan de cero.

**La llamada y el sellado**

10. **La llamada es atómica.** O se juega entera en una sesión o se repite entera al volver. El slice (D.3) lo exige a medias («al cerrar durante la llamada, se reanuda en el despacho con la llamada pendiente») y el GDD de Escena de planta (regla 16) añade que entrar en Recepción no cambia el último guardado.
11. **Sellado.** Al llegar «llamada iniciada»:
    1. En el momento del aviso se **captura** la instantánea (con `llamada_iniciada` verdadero, `llamada_completada` falso, `respuesta_llamada` sin fijar) y se pide un guardado urgente (`call_started`).
    2. Esa escritura (y sus reintentos, que escriben **ese mismo contenido capturado**, no uno nuevo) es la última de la sesión. Cuando tiene éxito, la partida pasa a «Sellada».
    3. En «Sellada» se rechazan todas las causas, incluidos `quit` y `periodic`: el fichero queda como está, aunque el jugador responda, termine la llamada y llegue a Recepción.
    4. Si el fichero guardado ya tiene `llamada_iniciada` verdadero (se reanudó una partida sellada), la partida **nace Sellada**: no se escribe nada en toda la sesión.
    5. «Sellada» se levanta solo con «Nueva partida». Un fichero antiguo sellado de una partida anterior no bloquea la partida nueva (el sellado es un estado de la sesión, derivado del hecho cargado, no una marca del fichero).

    **Consecuencia aceptada:** un jugador que complete la llamada y cierre antes de Recepción, o durante ella, vuelve a vivir la llamada (1 a 2 minutos). A cambio, `respuesta_llamada` y `llamada_completada` no se guardan nunca, no puede reanudarse una llamada a medias con una respuesta ya fijada (el hecho `respuesta_llamada` es de un solo sentido, GDD del 3, regla 4), y no hay que definir una reanudación de la llamada a mitad.
12. **Contrato con la llamada (22) ‡.** Cuando al restaurar `llamada_iniciada` es verdadero y `llamada_completada` falso, el sistema 22 debe volver a ofrecer la llamada desde su principio (teléfono sonando al entrar en el despacho, que es donde aparece el jugador). Si no lo hiciera, sería el único softlock posible del guardado: por eso es un requisito de ese GDD y un criterio de integración aquí (AC-34).

**Escritura**

13. **Escritura atómica con respaldo de una generación.** Nombres: `autosave.json` (principal), `autosave.prev.json` (generación anterior), `autosave.tmp` (temporal), `autosave.corrupt` (copia de un fichero dañado) y `autosave.incompatible` (copia de uno de versión futura). Secuencia:
    1. Serializar la envoltura (F3) y escribirla entera en `autosave.tmp`, comprobando que cada `store_*` devuelve éxito.
    2. **Releer** `autosave.tmp` y validarlo (F3). Si falla, es un fallo de escritura.
    3. Si existe `autosave.json`: borrar `autosave.prev.json` y renombrar `autosave.json` a `autosave.prev.json`.
    4. Renombrar `autosave.tmp` a `autosave.json`.

    La secuencia no depende de que renombrar sobre un fichero existente lo sobrescriba (se desconoce en cada plataforma; Open Questions 1). Un corte entre cualquier par de pasos deja siempre al menos un fichero válido (casos en Edge Cases y F4). Solo se conserva **una** generación anterior.
14. **Pérdida máxima.** Ante un cierre forzado se pierde, como mucho, lo ocurrido desde la última causa que escribió. El valor práctico lo acota `t_periodico` (120 s†) para los hechos que cambian en mitad de un puzle (`pos_L/C/R`, `correos_leidos`, `formulario_leido`); los hechos que condicionan el avance (tarjetas, compartimentos, `archivo_abierto`) se guardan en el acto por las causas de la regla 6.
15. **Fallo de escritura.** Disco lleno, sin permisos, carpeta de solo lectura o renombrado denegado (p. ej. un antivirus): el juego continúa, el contenido sigue pendiente, se registra una línea y se reintenta con espera creciente (F2). Nunca bloquea ni interrumpe una escena. Tras `n_fallos_aviso` fallos consecutivos se emite «guardado en riesgo» y la interfaz muestra un aviso discreto no bloqueante; al volver a escribir con éxito, «guardado restablecido» lo retira. Un fallo del respaldo (paso 3) no impide el paso 4 si el principal puede sustituirse; se registra.
16. **Una sola escritura a la vez.** Una petición con una escritura en curso espera a que termine y se vuelve a evaluar con la instantánea nueva (no se pierde ni se duplica).

**Carga**

17. **Inspección al arrancar.** Antes de mostrar «Continuar», el sistema inspecciona los tres ficheros candidatos (`autosave.json`, `autosave.tmp`, `autosave.prev.json`), valida cada uno (regla 19) y elige el válido de mayor `seq` (F4). El resultado es uno de: `ninguna` (no hay ficheros), `valida` (hay una partida continuable), `irrecuperable` (existen ficheros pero ninguno es válido) o `version_futura` (el más reciente válido pertenece a una versión mayor). La pantalla de título (27) consulta el resultado; no vuelve a leer disco.
18. **Continuar.** Con resultado `valida`, «Continuar» hace, en este orden: (1) migrar la envoltura si su versión es menor (regla 21); (2) entregar la instantánea al sistema 3 para restaurarla (GDD del 3, regla 13) y esperar «estado restaurado»; (3) fijar `seq` y el último contenido escrito y calcular si la partida nace Sellada (regla 11.4); (4) pedir a Escena de planta la carga de `planta` con motivo `reanudar` y `control_final` = `exploracion`; (5) pasar a «En partida» al llegar «carga de escena terminada». Si el paso (4) falla (fallo de carga, GDD de Escena de planta, regla 14), se vuelve al título, el fichero **no** se toca y «Continuar» sigue disponible.
19. **Validación de un candidato.** Un fichero es válido si cumple, en este orden: tamaño ≤ `max_bytes_lectura`; es JSON analizable; tiene todas las claves de la regla 2 con el tipo correcto; `seq` ≥ 1; `format_version` es un entero; `checksum` coincide con F3; y `snapshot` es un objeto con `snapshot_version` entera. Una clave extra se ignora. **La validez semántica de los hechos no la juzga este sistema**: nombres desconocidos, hechos ausentes o fuera de rango y combinaciones incoherentes los resuelve el sistema 3 al restaurar (GDD del 3, casos límite de restauración: valor inicial, registro y restauración tal cual, sin corregir en silencio).
20. **Versión mayor.** Si `format_version` es mayor que el conocido, o `snapshot_version` mayor que la que declara el sistema 3 ‡, el fichero es de una versión futura: no es candidato a cargar, se conserva una copia en `autosave.incompatible` (una sola; la nueva sustituye a la anterior) y **no se toca el original** hasta que una partida nueva lo rote en su primer guardado. Resultado `version_futura` si no hay otro candidato válido.
21. **Versión menor: migración.** Si `format_version` es menor que el actual, se aplican en orden las migraciones `v → v+1` hasta el formato actual. Cada migración es una función pura (objeto → objeto) con su propio test. En el slice solo existe el formato `1`, así que la tabla de migraciones está vacía; el mecanismo es obligatorio para que la primera versión posterior no rompa partidas existentes. Si una migración falla o su resultado no supera la validación de la regla 19, el fichero se trata como dañado (regla 22). La migración se hace en memoria; el fichero no se reescribe hasta el siguiente guardado, que además deja el original (formato antiguo) como respaldo.
22. **Fichero dañado.** Cuando un candidato falla la validación o la migración: se registra una línea, se conserva una copia del contenido original en `autosave.corrupt` (una sola; la nueva sustituye a la anterior; si el renombrado o la copia falla, se registra y se sigue) y se prueba con el siguiente candidato. **Si hay otro candidato válido (típicamente `autosave.prev.json`), se usa sin avisar al jugador**: pierde como máximo un guardado. Si no queda ninguno, el resultado es `irrecuperable`: «Continuar» no se ofrece, el título muestra un aviso no bloqueante una vez, y «Nueva partida» funciona. Nunca se borra un fichero dañado: solo lo sustituye el flujo de la regla 13.
23. **Un temporal huérfano** (`autosave.tmp`) se considera un candidato más: si es válido y su `seq` supera al principal (corte entre los pasos 2 y 3 de la regla 13) se usa; si no, se descarta y se elimina.
24. **Nueva partida.** «Nueva partida» pide al sistema 3 restablecer el estado (GDD del 3, regla 12), pone la partida en «En partida» sin sellar y deja la petición de `planta` con motivo `partida_nueva` a la pantalla de título (GDD de Escena de planta, regla 7). **No borra el fichero existente**: este sigue siendo continuable hasta que la partida nueva escriba su primer guardado. Así, abandonar una partida nueva antes de la primera puerta no destruye la anterior. El primer guardado de la partida nueva usa `seq` = (mayor `seq` visto) + 1 y rota el principal anterior a `autosave.prev.json`.
25. **Confirmación.** Si el resultado de la inspección es `valida` (o `version_futura`), la pantalla de título pide confirmación antes de «Nueva partida» (UI Requirements).
26. **Datos, no código.** Los tiempos y límites viven en `assets/data/save/save-config.json` (Tuning Knobs). La versión de formato y la tabla de migraciones son código, porque deben ir juntas.
27. **Herramientas de desarrollo (solo builds de desarrollo).** Existe «borrar partida guardada» (borra los cuatro ficheros) y «guardar ahora» (pide una causa `dev` urgente, que respeta el sellado). No existen en la build de la demo; la comprobación de builds de entrega las incluye junto a la consola del sistema 3.

**No softlock: argumento**

28. Todo fichero que producen las reglas anteriores es continuable porque: (a) se instantánea con la cola de avisos vacía, así que los hechos son un estado alcanzable en juego normal; (b) el slice §13.3 garantiza que desde cualquier estado de hechos alcanzable hay salida (las salas B y D son accesibles en cualquier momento y los compartimentos no se bloquean entre sí); (c) la escena se reconstruye desde los hechos y el jugador siempre aparece en `spawn_office`, accesible; (d) el único estado con una dependencia de comportamiento, `llamada_iniciada` ∧ ¬`llamada_completada`, tiene un contrato explícito (regla 12). El estado `caja_completa` ∧ ¬`llamada_iniciada` (guardado al completar el compartimento 4 o al abrir una puerta tras ello) también es válido: el jugador reaparece en el despacho y el disparador de la llamada (salir de D con `caja_completa`, slice §8.5) sigue disponible volviendo a D; qué hace el director de escenas (21) al reanudar en ese estado lo decide su GDD (Open Questions 5).

### States and Transitions

| Estado | Qué ocurre | Sale hacia |
|---|---|---|
| **Sin inspeccionar** | Antes de arrancar. Consultar el resultado, pedir un guardado o continuar es un error. | Sin partida |
| **Sin partida** | Inspección hecha (resultado conocido: `ninguna`, `valida`, `irrecuperable`, `version_futura`). No hay sesión activa: no se guarda nada. Se está en el título. | Cargando partida (continuar) · En partida (nueva partida) |
| **Cargando partida** | Migra, restaura el estado y espera la carga de `planta` (regla 18). Las causas de guardado se ignoran (regla 8). | En partida (carga terminada; **Sellada** si el hecho cargado lo exige) · Sin partida (fallo de carga) |
| **En partida** | Las causas piden guardados; se escribe según F1. | Sellada (guardado de sellado con éxito) · Sin partida (salida al título, tras un guardado `quit`; o cierre del juego) |
| **Sellada** | No se escribe nada hasta la siguiente partida nueva (regla 11). Las lecturas del resultado de inspección siguen siendo las del arranque. | Sin partida (salida al título) |

*Sellando* (entre el aviso «llamada iniciada» y el éxito de la escritura de sellado) es un subestado de «En partida»: solo se permite el guardado de sellado capturado y sus reintentos (regla 11.2).

### Interactions with Other Systems

| Sistema | Qué recibe de este | Qué entrega a este |
|---|---|---|
| 3 Estado y bus de eventos | Petición de instantánea; petición de restaurar; petición de restablecer (partida nueva); avisos propios «guardado en riesgo» y «guardado restablecido» ‡ | Instantánea (con la cola vacía); «estado restaurado»/«estado restablecido»; los avisos de causa (puerta, compartimento, puzle resuelto, llamada iniciada, cambio de `pendiente_revelacion`); la `snapshot_version` conocida ‡ |
| 4 Escena de planta | Petición de `planta` con `reanudar` tras restaurar (regla 18) | «Carga de escena terminada» (fin de «Cargando partida»); aviso de fallo de carga |
| 27 Pantalla de título | El resultado de inspección; `continuar()` y `nueva_partida()` | Peticiones de continuar, de nueva partida y de salida al título |
| 25 Menú de pausa | Aviso `pause_opened` (lo emite 25) y «guardado en riesgo» para su indicador | La petición «salir al título» (causa `quit`) |
| 8 Control de acceso · 9 a 16 Puzles y caja · 22 Llamada | — | Los avisos de causa (reglas 6 y 11); 22 se obliga a reiniciar la llamada al restaurar (regla 12) |
| 21 Director de escenas | — | Decide la reanudación con `caja_completa` ∧ ¬`llamada_iniciada` (regla 28) |
| 6 Ajustes persistentes | Nada | Nada. Fichero, ruta y fallos independientes (regla 4) |
| 18 Base de contenido | — | Los rótulos `UI_…` de los avisos (UI Requirements) |

## Formulas

Propuestas por `systems-designer`. † = valor propuesto, a validar en playtest; «data file» = se lee de `assets/data/save/save-config.json`. El sistema no define presupuesto de rendimiento y no se inventa uno (Open Questions 6).

### F1 · Cuándo se escribe

`escribir ⇔ en_partida ∧ ¬sellada ∧ cola_vacía ∧ dif ∧ ( urgente ∨ ( solicitud ∧ t − t_prim ≥ t_agrupar ∧ t ≥ t_intento ) ∨ ( t_periodico > 0 ∧ t − t_ref ≥ t_periodico ) )`

El guardado de sellado (regla 11) es urgente y se exime de `¬sellada` por ser el que sella; escribe el contenido capturado, para el cual `dif` se evalúa contra el último escrito.

| Symbol | Type | Range | Source | Description |
|---|---|---|---|---|
| en_partida | bool | {sí, no} | calculated | Estado «En partida» o subestado «Sellando» |
| sellada | bool | {sí, no} | calculated | Estado «Sellada» (regla 11) |
| cola_vacía | bool | {sí, no} | calculated | La cola de avisos del sistema 3 está vacía (regla 5) |
| dif | bool | {sí, no} | calculated | El contenido de la instantánea difiere del último escrito o cargado (regla 7) |
| urgente | bool | {sí, no} | calculated | Causa `call_started` o `quit` |
| solicitud | bool | {sí, no} | calculated | Hay una petición de causa no urgente sin atender |
| t | float (s) | ≥ 0 | calculated | Reloj monotónico de tiempo real (no lo afecta la pausa ni la escala de tiempo del juego, igual que en Ajustes F3) |
| t_prim | float (s) | ≤ t | calculated | Instante de la primera petición sin atender desde la última escritura |
| t_agrupar | float (s) | 0–1,0 | data file, 0,1† | Ventana para fundir peticiones cercanas en una sola escritura |
| t_intento | float (s) | ≥ 0 | calculated | Instante más temprano del siguiente intento (0 si no hay fallos; F2 si los hay) |
| t_periodico | float (s) | 0, o 30–600 | data file, 120† | Periodo del guardado periódico; 0 lo desactiva |
| t_ref | float (s) | ≤ t | calculated | Instante de la última escritura con éxito, o de la carga |

**Output Range:** booleano. En régimen normal (sin fallos) hay como máximo una escritura por ráfaga de peticiones y nunca más de una cada `t_agrupar`; la cota inferior de escrituras entre dos escrituras consecutivas es `t_agrupar` salvo las urgentes. Con `dif` falso no hay escritura nunca, así que el periodo máximo de escrituras por `periodic` es `t_periodico` y solo si cambió algo. Pérdida máxima ante cierre forzado: ver regla 14.
**Example:** el jugador completa el compartimento 4 en t = 100,00 s, lo que produce también «puzle resuelto» en 100,00 s y, al salir de D, «puerta abierta» en 104,00 s. La primera petición fija `t_prim` = 100,00; en t = 100,10 (y cola vacía) se escribe una sola vez con `cause` = `compartment_done:4`; la petición de «puzle resuelto» se funde con ella. En t = 104,10 se escribe de nuevo por la puerta (el contenido cambió: `caja_completa` ya estaba, pero hay `pos_*` o similar; si fuese idéntico, `dif` evitaría la escritura).

### F2 · Espera entre reintentos tras un fallo

`t_intento = t_fallo + min( t_reintento_base × 2^(k − 1), t_reintento_max )`

| Symbol | Type | Range | Source | Description |
|---|---|---|---|---|
| k | int | 1–∞ | calculated | Fallos consecutivos de escritura (se pone a 0 con un éxito) |
| t_fallo | float (s) | ≤ t | calculated | Instante del último fallo |
| t_reintento_base | float (s) | 1–10 | data file, 2† | Espera tras el primer fallo |
| t_reintento_max | float (s) | 10–300 y ≥ t_reintento_base | data file, 30† | Techo de la espera |
| n_fallos_aviso | int | 1–10 | data file, 3† | `k` desde el que se emite «guardado en riesgo» |

**Output Range:** de `t_reintento_base` a `t_reintento_max`; el exponente se calcula con saturación (con `k` > 30 se usa directamente `t_reintento_max`) para no desbordar. Restricción de datos: `t_reintento_max ≥ t_reintento_base`.
**Example** (base 2, máx. 30): k = 1 → 2 s; k = 2 → 4; k = 3 → 8 (y se emite «guardado en riesgo»); k = 4 → 16; k = 5 → 32 → 30; k = 6 → 30. Un éxito pone `k` a 0 y emite «guardado restablecido». Con esos valores el aviso aparece unos 14 s después del primer fallo (2 + 4 + 8).
Una causa urgente (`quit`) intenta una vez aunque `t < t_intento` y, si falla, no reintenta (el proceso termina).

### F3 · Integridad del fichero

`checksum = hash( canónico( envoltura sin checksum ) )`

| Symbol | Type | Range | Source | Description |
|---|---|---|---|---|
| envoltura sin checksum | objeto | las claves de la regla 2, menos `checksum` | calculated | Contenido a proteger |
| canónico(·) | bytes | UTF-8 | calculated | Serialización JSON con claves ordenadas alfabéticamente y sin espacios, para que el mismo contenido dé siempre los mismos bytes |
| hash(·) | texto hex | 64 caracteres (con SHA-256†) | calculated | Resumen del contenido. Algoritmo en un ADR (propuesta SHA-256, disponible en el motor); detecta truncados y corrupción, no manipulación intencionada: el juego es de un jugador y no hay nada que proteger frente a quien edite su propia partida |
| contenido a comparar (regla 7) | objeto | `snapshot` + `format_version` | calculated | Misma serialización, **sin** `seq`, `saved_at_utc`, `build` ni `cause`, para decidir `dif` |

**Output Range:** exacto; un bit distinto en la envoltura cambia el resumen. Un `checksum` que no coincide, ausente o con otro formato invalida el candidato. Un fichero con `checksum` correcto pero hechos absurdos es válido para este sistema (regla 19).
**Example:** un fichero de 1,0 KB cortado a la mitad por un fallo de disco falla el análisis JSON; si el corte cae justo en una llave válida, falla el resumen. En ambos casos el candidato se descarta y se prueba con `autosave.prev.json`.

### F4 · Qué candidato se carga

`elegida = candidato válido con seq máximo, de { autosave.json, autosave.tmp, autosave.prev.json }`  (empate: el orden principal, temporal, previo)

| Symbol | Type | Range | Source | Description |
|---|---|---|---|---|
| candidato | fichero | hasta 3 | calculated | Los ficheros de la regla 17 que existen |
| válido(c) | bool | {sí, no} | calculated | Supera la regla 19 y, si su versión es menor, la migración (regla 21) |
| seq | int | ≥ 1 | file | Contador de guardado de la envoltura |

**Output Range:** un candidato, o ninguno (resultado `ninguna` si no existía ningún fichero, `irrecuperable` si existía alguno y ninguno es válido, `version_futura` si el de mayor `seq` es de versión mayor y no hay un válido anterior). Un candidato de versión futura no puede ser elegido, pero se ve: si un `autosave.json` futuro convive con un `autosave.prev.json` válido, se usa el previo y se informa `version_futura` solo si no hay ninguno.
**Example:** corte de luz entre los pasos 3 y 4 de la regla 13: no existe `autosave.json`; `autosave.tmp` válido con `seq` = 18 y `autosave.prev.json` válido con `seq` = 17 → se elige el temporal (18) y se pierde nada. Corte durante el paso 1: `autosave.json` (17) válido, `autosave.tmp` truncado → se elige el principal.

## Edge Cases

**Cierre y cortes**
- **If el proceso se corta durante la escritura del temporal (paso 1)**: el principal y el previo quedan intactos; el temporal truncado se descarta y se elimina al arrancar.
- **If se corta entre los pasos 2 y 3**: principal válido (seq n) y temporal válido (n + 1); F4 elige el temporal. No se pierde nada.
- **If se corta entre los pasos 3 y 4**: no hay principal; existen el previo (n) y el temporal (n + 1); F4 elige el temporal (regla 23).
- **If se corta después del paso 4**: caso normal.
- **If el jugador cierra con cambios pendientes dentro de `t_agrupar`**: `quit` es urgente: escribe en el acto (F1).
- **If el cierre es forzado (proceso terminado)**: se pierde lo posterior a la última escritura, como mucho `t_periodico` para los hechos de puzle; ver regla 14.
- **If la escritura de `quit` falla**: no se reintenta ni se bloquea el cierre; se registra.

**Llamada y sellado**
- **If el jugador cierra durante la llamada, tras el guardado de sellado**: el fichero tiene `llamada_iniciada` verdadero; al continuar, la partida nace Sellada y 22 vuelve a ofrecer la llamada (reglas 11 y 12).
- **If el jugador cierra durante la llamada, pero el guardado de sellado aún no se ha completado** (fallo de escritura): el fichero conserva el guardado anterior con `llamada_iniciada` falso y `caja_completa` verdadero; al continuar, aparece en el despacho y el disparador de la llamada sigue siendo salir de D (regla 28). No hay softlock.
- **If el guardado de sellado falla y el jugador sigue jugando la llamada**: los reintentos escriben el contenido capturado en el aviso, no el actual, de modo que nunca llega a disco una `respuesta_llamada` o una `llamada_completada` (regla 11.2).
- **If una partida nueva empieza con un fichero antiguo sellado**: no se hereda el sellado (regla 11.5); el primer guardado de la partida nueva lo rota a `autosave.prev.json`.
- **If «llamada iniciada» llega dos veces** (22 la repite al reanudar): el hecho es de un solo sentido y no cambia, no hay aviso de cambio; si 22 emite igualmente un aviso con nombre, la partida ya está Sellada y se ignora.
- **If el jugador cierra en Recepción**: el último guardado es el de sellado (o anterior); reanuda en el despacho con la llamada pendiente, tal como dice el GDD de Escena de planta (regla 16).
- **If se guarda en pleno apagón antes de que suene el teléfono** (`caja_completa` ∧ ¬`llamada_iniciada`): válido (regla 9); la reanudación la decide 21.

**Ficheros dañados y versiones**
- **If `autosave.json` está dañado y `autosave.prev.json` es válido**: se usa el previo sin avisar al jugador (regla 22); se pierde, como mucho, el último guardado. Se conserva una copia del dañado.
- **If todos los candidatos están dañados**: resultado `irrecuperable`; el título muestra un aviso una sola vez, «Continuar» no se ofrece, «Nueva partida» no pide confirmación y funciona. Las copias dañadas se conservan para diagnóstico.
- **If el fichero está vacío (0 bytes), supera `max_bytes_lectura` o no es texto UTF-8**: dañado, sin intentar analizarlo cuando supera el tope.
- **If falta alguna clave de la envoltura o tiene tipo erróneo**: dañado (regla 19).
- **If el fichero declara una `format_version` mayor que la conocida**: regla 20; no se toca el original.
- **If declara una menor** y existe migración: se migra en memoria (regla 21). **If falta un eslabón de la cadena de migraciones o la migración falla**: dañado (copia + siguiente candidato).
- **If `format_version` falta, es negativa, cero o no es entera**: dañado.
- **If la instantánea contiene hechos desconocidos, ausentes, fuera de rango o incoherentes entre sí**: lo resuelve el sistema 3 al restaurar (valor inicial + registro, o restauración tal cual con advertencia); este sistema no corrige, para no deshacer progreso real.
- **If la instantánea trae `llamada_completada` verdadero** (edición manual o consola de desarrollo): se restaura tal cual; el ascensor queda activo y no hay softlock.
- **If no se puede crear la copia del fichero dañado**: se registra y se sigue; el dañado queda en su sitio hasta que el flujo de escritura lo rote.

**Escritura y disco**
- **If la carpeta de guardado no existe**: se crea; si no se puede, es un fallo de escritura (regla 15).
- **If el disco está lleno o la carpeta es de solo lectura**: reintentos de F2; tras `n_fallos_aviso` fallos, aviso discreto. El progreso sigue en memoria, y se pierde al cerrar.
- **If falla el borrado del respaldo o su renombrado (paso 3), pero el principal puede sustituirse**: se sustituye igualmente (el progreso nuevo prima sobre el respaldo) y se registra.
- **If falla el paso 4 después del 3**: no hay principal; el previo y el temporal son válidos, y F4 elige el temporal. Se reintenta con F2.
- **If el relectura de verificación (paso 2) falla**: es un fallo de escritura; el principal anterior no se ha tocado.
- **If un antivirus bloquea momentáneamente el renombrado**: es un fallo de escritura corriente; el reintento lo resuelve.
- **If hay dos instancias del juego abiertas**: gana la última en escribir; cada una incrementa `seq` desde lo que leyó. Puede perderse el progreso de una; fuera del alcance del slice (igual que en Ajustes). F4 siempre produce un candidato válido.
- **If el usuario borra o sustituye `autosave.json` con el juego en marcha**: el siguiente guardado crea uno nuevo; el reloj no interviene en ninguna decisión.
- **If cambia la hora del sistema**: no afecta; `seq` es un contador y `t` es un reloj monotónico.
- **If el sistema 3 no está en «Listo»** (por ejemplo, durante una restauración) al pedir una instantánea: la petición espera; si llega a pedirse desde dentro de una restauración, se rechaza y se registra (en desarrollo, error visible que detiene la ejecución).
- **If un suscriptor provoca cambios al recibir el aviso de causa**: la instantánea espera a que la cola esté vacía (regla 5); un bucle lo corta el tope del sistema 3.

**Flujos**
- **If el jugador pulsa «Continuar» con una carga en curso** (doble pulsación): se rechaza (la petición a Escena de planta lo rechaza igual, regla 7 de ese GDD).
- **If falla la carga de la escena tras restaurar**: se vuelve al título; el fichero no se modifica; el estado del sistema 3 se restablece al empezar la siguiente partida. «Continuar» sigue disponible.
- **If se pulsa «Nueva partida» y luego se cierra antes del primer guardado**: la partida anterior sigue en disco y continuable (regla 24).
- **If se pide «Nueva partida» desde una partida Sellada**: se levanta el sellado y el primer guardado sustituye al fichero.
- **If se cierra el juego en «Cargando partida»**: no hay nada que escribir; el fichero queda como estaba.
- **If el cierre normal llega con la partida sin cambios desde el último guardado**: `dif` falso, no se escribe.
- **If se fuerza un hecho desde la consola de desarrollo y se guarda**: se guarda lo que haya (regla 19 y GDD del 3, regla 15). Para una prueba limpia se usa «borrar partida guardada» (regla 27).

## Dependencies

**Aguas arriba (de qué depende):**
- **3 Estado y bus de eventos — dura.** Proporciona la instantánea, la restauración, el restablecimiento y los avisos de causa. Sin él no hay qué guardar. La interfaz ya está declarada por su GDD (reglas 12 y 13; casos límite de guardado).
- **4 Escena de planta y carga de Recepción — dura.** Reanudar es cargar la escena desde los hechos; la partida solo pasa a «En partida» cuando la escena termina de cargar.
- Capacidad del motor de leer y escribir ficheros en la carpeta de datos del usuario, y un fichero de configuración `assets/data/save/save-config.json` (definido por este GDD).

**Retirada de la dependencia del sistema 6.** El índice de sistemas lista el 6 (Ajustes) como dependencia del 5. **No lo es**: los ajustes quedan fuera de la partida (Ajustes, regla 3), viven en otro fichero y no se influyen. Solo se reutilizan convenciones de diseño. Se propone al dueño del índice que la fila 5 pase a depender de 3 y 4 (cierra la Open Question 6b de Ajustes).

**Aguas abajo (quién depende de este sistema).** Dura = no puede funcionar sin él; blanda = mejora con él.

| Sistema | Tipo | Interfaz |
|---|---|---|
| 27 Pantalla de título | Dura | Resultado de inspección; `continuar()` y `nueva_partida()` |
| 25 Menú de pausa | Blanda | Emite `pause_opened`; muestra el aviso «guardado en riesgo»; «salir al título» pide el guardado `quit` |
| 22 Llamada | Dura (contrato) | Debe reanudarse desde cero cuando `llamada_iniciada` ∧ ¬`llamada_completada` al restaurar (regla 12) |
| 21 Director de escenas | Blanda | Decide la reanudación con `caja_completa` ∧ ¬`llamada_iniciada` |
| 8 Control de acceso · 9 a 16 · 20 | Blanda | Emiten los avisos de causa; sus elementos deben ser reconstruibles desde sus hechos |

**Bidireccionalidad.** El GDD del 3 ya cita a Guardado en su regla 13, en su tabla de interacciones y en sus casos límite de guardado. El GDD de Escena de planta lo cita en la regla 16 y en su tabla (petición de `planta` con `reanudar`). Pendientes: 27, 25, 22, 21 y la regla 10 del GDD del 3 (añadir «guardado en riesgo» y «guardado restablecido»), cuando se redacten o revisen (ver Cross-References y Open Questions).

## Tuning Knobs

Todos viven en `assets/data/save/save-config.json`. Un valor fuera de rango o una restricción incumplida es un fichero inválido: el juego no entra en partida y muestra un mensaje de error claro con el código `CATALOGO_INVALIDO` y el nombre del parámetro (igual que Ajustes y Estado). † = a validar en playtest.

| Knob | Valor † | Rango seguro | Qué afecta |
|---|---|---|---|
| `t_agrupar` | 0,1 s | 0–1,0 | Fusión de peticiones cercanas en una escritura. 0 escribe cada petición en su fotograma; más de 1 s alarga la ventana en que un cierre forzado pierde una puerta recién abierta |
| `t_periodico` | 120 s | 0 (apagado) o 30–600 | Pérdida máxima ante cierre forzado para hechos de puzle sin causa propia (lámparas, correos). Bajar aumenta las escrituras (limitadas por `dif`) |
| `t_reintento_base` | 2 s | 1–10 | Rapidez del primer reintento tras un fallo |
| `t_reintento_max` | 30 s | 10–300 (≥ `t_reintento_base`) | Techo de la espera entre reintentos |
| `n_fallos_aviso` | 3 | 1–10 | Cuántos fallos seguidos hacen visible el aviso. 1 avisa por un fallo puntual (ruido); más de 5 deja al jugador sin saber que no se guarda durante más de un minuto |
| `max_bytes_lectura` | 65 536 B | 16 384–1 048 576 | Tamaño máximo aceptado al leer. La envoltura real pesa alrededor de 1 KB, por lo que el tope es 60 veces mayor; protege de leer basura |
| `causas_activas` | las 8 de la regla 6 | `door_opened`, `compartment_done` y `call_started` **no desactivables** | Qué causas piden guardado. Desactivar una obligatoria invalida el fichero |

Valores por cambiar con el contenido, no por balance: el catálogo de hechos (`assets/data/state/flags.json`, sistema 3) y las causas con nombre dependen de los avisos de los demás GDD. Si un tercer sistema añade hechos, se guardan sin tocar este GDD (la instantánea es un mapa).

## Visual/Audio Requirements

*(Sección opcional para la categoría Persistence; en modo `lean` no se consulta a `art-director` ni a `audio-director`.)*

Guardar es silencioso y sin imagen: sin sonido, sin icono, sin barra, sin pausa (el slice no incluye indicador de autoguardado y §16 prohíbe elementos de interfaz que rompan el tono). Las dos únicas apariciones son un aviso de texto discreto y no bloqueante cuando el guardado falla de forma persistente (UI Requirements) y el aviso del título cuando una partida no se puede recuperar. Escribir a disco no debe interrumpir la reproducción de voces ni de ambiente.

## Game Feel

El jugador no opera el sistema. Lo exigible es que **no se note**: una escritura no debe congelar la imagen ni cortar el audio de forma perceptible en mitad de una escena, sobre todo en la llamada y el apagón (el momento en que el sellado escribe coincide con una escena de tensión). El umbral de «perceptible» y la medición se fijan en la primera prueba sobre el equipo de referencia (Open Questions 6), porque el slice no lo define (§21: equipo «a definir»). El tiempo de reanudación (clic en «Continuar» hasta tener control) lo marca el GDD de Escena de planta (F2, F3); este sistema solo añade la restauración, que es instantánea (un fichero de ~1 KB).

## UI Requirements

El sistema no tiene pantalla propia. Requisitos fijados a las pantallas de otros sistemas:
- **Título (27):** «Continuar» solo se ofrece con resultado `valida`; con `ninguna`, `irrecuperable` o `version_futura` no aparece (o aparece desactivado, lo decide el diseño UX). «Nueva partida» pide confirmación (texto: se sustituirá la partida actual cuando se guarde la nueva) si el resultado es `valida` o `version_futura`; en los demás casos no hay confirmación.
- **Aviso de partida no recuperable:** con `irrecuperable` o `version_futura`, una línea de texto no bloqueante, una sola vez por arranque, sin botón de acción obligatoria, con causa distinguible (dañada / de una versión más nueva). Nunca un cuadro modal.
- **Aviso de guardado en riesgo:** texto discreto (en el menú de pausa y, mientras dura el fallo, una línea breve no modal en pantalla) que desaparece con «guardado restablecido». No se muestra en la llamada ni en el apagón (si coincide, espera al fin de la escena).
- **Sin menú de guardado manual**, sin ranuras y sin «Cargar» distinto de «Continuar» (slice §13.2).
- **Textos:** todos los rótulos son entradas `UI_…` de la base de contenido (18).

**UX Flag — Guardado y carga**: las pantallas afectadas son el título (27) y el menú de pausa (25). Ejecutar `/ux-design` para esos dos antes de escribir las épicas.

## Cross-References

| Documento | Elemento | Naturaleza |
|---|---|---|
| `design/slice/slice-v0.3.md` · §13.2, Anexo D.3 | Autoguardado en puertas, compartimentos y llamada; sin guardado manual; reanudar con la llamada pendiente y con `pendiente_revelacion` | Define las causas obligatorias (regla 6) y el sellado (regla 11) |
| `design/slice/slice-v0.3.md` · §13.3 | Casos límite sin softlock | Base del argumento de la regla 28 |
| `design/slice/slice-v0.3.md` · §8, §9 y Anexo C.7 | Único disparador de la llamada; apagón y llamada con tiempos | Regla 9 (escenas temporizadas), regla 28 |
| `design/slice/slice-v0.3.md` · §16, §21 | Sin elementos de interfaz intrusivos; PC (Windows y Linux), equipo de referencia sin definir | Visual/Audio; Open Questions 6 |
| `design/slice/slice-v0.3.md` · Anexo D.2 | Los 19 hechos | Contenido de `snapshot` |
| `design/gdd/estado-y-bus-de-eventos.md` · reglas 4, 12, 13, 15 y casos límite de restauración y de guardado | Hechos de un solo sentido; partida nueva; instantánea y restauración; consola; cola vacía antes de la instantánea | Interfaz con el sistema 3 |
| `design/gdd/escena-de-planta.md` · reglas 7, 9, 10, 14, 16 y 17 | Petición de carga; secuencia; `spawn_office`; fallo de carga; el guardado no cambia en Recepción; escena obsoleta | Reglas 3, 8, 10, 18 y 24 |
| `design/gdd/ajustes-persistentes.md` · reglas 3, 9 a 13 y F3 | Ajustes fuera de la partida; fichero propio; escritura atómica; copia del dañado; versión de formato | Patrones reutilizados (reglas 4, 13, 20, 22). Cierra Open Questions 6b de ese GDD |
| `design/gdd/systems-index.md` · fila 5 | Dependencias 3, 4 y 6 | Debe pasar a 3 y 4 (Dependencies) |
| `design/gdd/game-pillars.md` | *Tensión sin castigo*, *Autonomía como progresión* | Pilares que sirve |

## Acceptance Criteria

Revisados por `qa-lead`. **Evidencia:** **L** = test unitario automático (gdUnit4, `tests/unit/save/`), bloqueante; **I** = test de integración o playtest documentado (`tests/integration/save/`), bloqueante. Los tests L **no hacen E/S real**: usan un almacenamiento falso que registra la secuencia de operaciones y permite inyectar fallos en cada una, un reloj inyectado (ticks enteros), un doble del sistema 3 que devuelve instantáneas y registra restauraciones, y un manejador de errores y un destino de log sustituibles; cada caso carga su propia fixture de `save-config.json`. Solo los criterios I tocan el disco. Tolerancia de tiempo ±1 tick. «Se cierra cuando exista X» marca un criterio que depende de un sistema sin GDD. El sistema no define presupuesto de rendimiento y no se inventa uno.

**Contenido y alcance (reglas 1 a 4)**
- **AC-01 (R1-2, L)**: **GIVEN** una partida en curso, **WHEN** se guarda, **THEN** el fichero tiene exactamente las claves `format_version`, `seq`, `saved_at_utc`, `build`, `cause`, `snapshot` y `checksum`; `format_version` vale 1; `seq` vale 1 en el primer guardado de una carpeta vacía; y `snapshot` es el que entregó el doble del 3.
- **AC-02 (R3-4, L)**: **GIVEN** un guardado, **THEN** el fichero no contiene posición del jugador, temporizadores ni claves de ajustes (`vol_voces`, `controles`…).
- **AC-03 (R4, I)**: **GIVEN** un guardado y un ajuste cambiado, **THEN** el hash del fichero de partida no cambia al cambiar el ajuste y el de ajustes no cambia al guardar. *(Se cierra con el GDD del 6 ya existente.)*

**Causas y momento (reglas 5 a 9, F1)**
- **AC-04 (R6, L)**: **GIVEN** la partida en curso, **WHEN** se emite «puerta abierta» con la ID A, B o D, «compartimento completado» 1 a 4, `EV_PUZZLE_SOLVED_P1`, un cambio de `pendiente_revelacion` o «llamada iniciada» (con `dif` verdadero), **THEN** cada uno produce una escritura con `cause` igual a `door_opened:<ID>`, `compartment_done:<n>`, `puzzle_solved:<ID>`, `reveal_pending` o `call_started`.
- **AC-05 (R5, L)**: **GIVEN** un aviso de causa cuyo suscriptor provoca otro cambio de hecho, **WHEN** se pide el guardado, **THEN** la instantánea se toma tras vaciar la cola y contiene ambos cambios (p. ej. `caja_c4` y `caja_completa` juntos).
- **AC-06 (F1, L)**: **GIVEN** `t_agrupar` = 0,1 s, **WHEN** llegan tres causas no urgentes en t = 100,00; 100,03 y 100,08, **THEN** hay una sola escritura en t = 100,10 con la `cause` de la primera.
- **AC-07 (R7, L)**: **GIVEN** que no ha cambiado ningún hecho desde el último guardado, **WHEN** se abre la pausa, vence `t_periodico` o se cierra, **THEN** no se escribe, `seq` no avanza y el respaldo no rota.
- **AC-08 (R6, F1, L)**: **GIVEN** `t_periodico` = 120 s y un hecho que cambió en t = 10 s sin causa propia, **THEN** se escribe en t = 120 s (si `t_ref` = 0) con `cause` = `periodic`; con `t_periodico` = 0 no se escribe; el reloj de tiempo real sigue avanzando con el juego en pausa.
- **AC-09 (R6, L)**: **GIVEN** cambios pendientes, **WHEN** se abre la pausa, **THEN** se escribe con `cause` = `pause_opened`; **WHEN** se cierra el juego o se sale al título, **THEN** se escribe de inmediato con `cause` = `quit`, sin esperar a `t_agrupar`.
- **AC-10 (R8, L)**: **GIVEN** el estado «Cargando partida», **WHEN** llegan avisos de causa (p. ej. «puerta abierta» de una puerta ya abierta), **THEN** no se escribe nada y no quedan peticiones pendientes tras «carga de escena terminada».
- **AC-11 (R8, L)**: **GIVEN** el estado «Sin partida» (título), **WHEN** llega cualquier causa, **THEN** no se escribe nada.
- **AC-12 (R9, I)**: **GIVEN** el apagón en curso (`caja_completa` verdadero, sin llamada), **WHEN** se abre una puerta o se sale, **THEN** se guarda y, al continuar, el jugador aparece en el despacho, la planta se rehace desde los hechos y el juego no muestra error.

**Sellado (reglas 10 a 12)**
- **AC-13 (R11, L)**: **GIVEN** «llamada iniciada», **THEN** se captura la instantánea con `llamada_iniciada` verdadero, `llamada_completada` falso y `respuesta_llamada` sin fijar, y se escribe de forma urgente sin esperar `t_agrupar`; **WHEN** tiene éxito, **THEN** el estado es «Sellada».
- **AC-14 (R11, L)**: **GIVEN** «Sellada», **WHEN** cambian `respuesta_llamada` y `llamada_completada` y llegan las causas `quit`, `pause_opened`, `periodic` y «puerta abierta», **THEN** no se escribe nada.
- **AC-15 (R11.2, L)**: **GIVEN** que la escritura de sellado falla y que, mientras se reintenta, `respuesta_llamada` pasa a A y `llamada_completada` a verdadero, **WHEN** un reintento tiene éxito, **THEN** el contenido escrito es el capturado en el aviso (sin respuesta ni completada).
- **AC-16 (R11.4, L)**: **GIVEN** un fichero con `llamada_iniciada` verdadero, **WHEN** se continúa, **THEN** la partida nace «Sellada» y tras llegar «carga de escena terminada» ninguna causa escribe.
- **AC-17 (R11.5, L)**: **GIVEN** un fichero sellado en disco, **WHEN** se elige «Nueva partida» y se abre la primera puerta, **THEN** se escribe (no sellada), `seq` = anterior + 1 y el antiguo queda en `autosave.prev.json`.
- **AC-18 (R11, L)**: **GIVEN** que «llamada iniciada» llega por segunda vez con la partida ya Sellada, **THEN** se ignora y no se escribe.

**Escritura atómica y fallos (reglas 13 a 16, F2)**
- **AC-19 (R13, L)**: **GIVEN** un principal existente, **WHEN** se guarda, **THEN** el almacenamiento falso registra exactamente: escribir `autosave.tmp`; releerlo y validarlo; borrar `autosave.prev.json` si existe; renombrar `autosave.json` a `autosave.prev.json`; renombrar `autosave.tmp` a `autosave.json`; y el resultado tiene `autosave.prev.json` con el `seq` anterior.
- **AC-20 (R13, L)**: **GIVEN** un fallo inyectado tras cada paso (1, 2, 3 y 4 por separado), **WHEN** se reinicia la inspección, **THEN** hay siempre un candidato válido elegido por F4 y ninguna pérdida salvo la del guardado en curso en el caso del paso 1.
- **AC-21 (R13, L)**: **GIVEN** un almacenamiento donde renombrar sobre un fichero existente falla, **WHEN** se guarda, **THEN** el resultado es el mismo que en AC-19 (la secuencia no depende de la sobrescritura).
- **AC-22 (R15, F2, L)**: **GIVEN** `t_reintento_base` = 2 y `t_reintento_max` = 30 y un almacenamiento que siempre falla, **THEN** los reintentos ocurren a +2, +4, +8, +16, +30 y +30 s tras cada fallo; «guardado en riesgo» se emite en el tercer fallo y una sola vez; no se lanza ningún error ni se bloquea el juego.
- **AC-23 (R15, L)**: **GIVEN** «guardado en riesgo» emitido, **WHEN** el almacenamiento vuelve a funcionar y un reintento tiene éxito, **THEN** se emite «guardado restablecido», `k` vuelve a 0 y el contenido escrito es el estado actual.
- **AC-24 (R15, L)**: **GIVEN** un fallo del respaldo (paso 3) con el principal sustituible, **THEN** el principal se sustituye, se registra una línea y no cuenta como fallo de escritura.
- **AC-25 (R16, L)**: **GIVEN** una escritura en curso, **WHEN** llega otra causa con un hecho nuevo, **THEN** se escribe después, con la instantánea nueva, sin pérdida ni duplicación.
- **AC-26 (R13, L)**: **GIVEN** que `quit` falla, **THEN** no se reintenta, se registra una línea y el cierre no se bloquea.
- **AC-27 (F2, L)**: **GIVEN** `t_reintento_max` < `t_reintento_base`, `max_bytes_lectura` fuera de rango, `n_fallos_aviso` = 0, una causa obligatoria desactivada o `save-config.json` ausente o corrupto, **WHEN** arranca, **THEN** no se carga la escena de partida y se invoca el manejador de error fatal inyectado con el código `CATALOGO_INVALIDO` y el nombre del parámetro o fichero culpable.

**Carga, validación y selección (reglas 17 a 23, F3 y F4)**
- **AC-28 (R17, F4, L)**: **GIVEN** que no existe ningún fichero, **THEN** el resultado es `ninguna`, el log no contiene errores y no se abre ningún diálogo; **GIVEN** un solo fichero válido, **THEN** `valida`.
- **AC-29 (F4, L)**: **GIVEN** un `autosave.tmp` válido con `seq` 18, un `autosave.prev.json` válido con `seq` 17 y sin principal, **THEN** se elige el temporal; **GIVEN** un principal válido con `seq` 17 y un temporal truncado, **THEN** se elige el principal y el temporal se elimina.
- **AC-30 (R19, F3, L)**: **GIVEN** un fichero vacío, uno que supera `max_bytes_lectura`, uno con JSON truncado, uno sin una de las claves, uno con `seq` = 0, uno con `checksum` alterado en un carácter y uno con `format_version` = "uno", **THEN** cada uno es inválido, se registra una línea y la copia `autosave.corrupt` contiene el contenido original byte a byte.
- **AC-31 (R22, L)**: **GIVEN** un principal dañado y un previo válido, **WHEN** se inspecciona, **THEN** el resultado es `valida` con el previo, no hay diálogo ni aviso, y existe una copia del dañado; **GIVEN** que ya existe una copia de un fallo anterior, **THEN** queda una sola con el contenido de la última.
- **AC-32 (R22, L)**: **GIVEN** un principal y un previo dañados, **THEN** el resultado es `irrecuperable`, «Continuar» no se ofrece, se emite el aviso de título una sola vez, «Nueva partida» no pide confirmación y funciona; **GIVEN** que la copia falla, **THEN** se registra y se continúa.
- **AC-33 (R20, L)**: **GIVEN** `format_version` mayor que el conocido (o `snapshot_version` mayor que la del 3), y sin otro candidato válido, **THEN** el resultado es `version_futura`, existe `autosave.incompatible` con el contenido original y el original no se modifica; **GIVEN** un previo válido, **THEN** se usa el previo.
- **AC-33b (R21, L)**: **GIVEN** una tabla de migraciones de prueba con un eslabón `0 → 1` (renombra una clave) y un fichero `format_version` 0, **WHEN** se continúa, **THEN** el sistema 3 recibe la instantánea migrada, el fichero en disco no cambia hasta el siguiente guardado, y ese guardado deja el original en `autosave.prev.json`; **GIVEN** una migración que falla o cuyo resultado no valida, **THEN** se trata como dañado (AC-30); **GIVEN** un eslabón ausente en la cadena, **THEN** igual.

**Continuar y partida nueva (reglas 18, 24 y 25)**
- **AC-34 (R12, I)**: **GIVEN** un guardado de sellado, **WHEN** se continúa, **THEN** el jugador aparece en `spawn_office`, la llamada vuelve a ofrecerse desde su principio (teléfono sonando al entrar en el despacho) y puede completarse hasta Recepción. *(Se cierra cuando exista el sistema 22.)*
- **AC-35 (R18, L)**: **GIVEN** un fichero válido, **WHEN** se pulsa «Continuar», **THEN** el orden de llamadas es: migración (si procede), restauración en el 3, espera de «estado restaurado», cálculo del sellado, petición de `planta` con `reanudar` y `control_final` = `exploracion`; el estado pasa a «En partida» al llegar «carga de escena terminada».
- **AC-36 (R18, L)**: **GIVEN** un fallo de carga de escena tras restaurar, **THEN** el estado vuelve a «Sin partida», el fichero no cambia y «Continuar» sigue disponible.
- **AC-37 (R18, L)**: **GIVEN** una carga en curso, **WHEN** se pulsa «Continuar» de nuevo, **THEN** se rechaza y no hay segunda restauración.
- **AC-38 (R24, L)**: **GIVEN** un fichero válido, **WHEN** se elige «Nueva partida» y se cierra antes de cualquier causa, **THEN** el fichero existente no se ha modificado y sigue siendo continuable; **WHEN** se abre la primera puerta, **THEN** se escribe con `seq` = anterior + 1 y el anterior pasa a `autosave.prev.json`.
- **AC-39 (R25, L)**: **GIVEN** el resultado `valida`, **THEN** «Nueva partida» exige confirmación; con `ninguna` o `irrecuperable` no.
- **AC-40 (R19, L)**: **GIVEN** una instantánea válida para este sistema con un hecho desconocido, otro ausente y un `enum` con valor no permitido, **WHEN** se continúa, **THEN** este sistema la entrega al 3 sin modificarla y el comportamiento es el del GDD del 3 (valores iniciales y registro).

**Reanudación sin pérdida (integración)**
- **AC-41 (R6, R14, I)**: **GIVEN** una partida jugada hasta resolver cada uno de los siguientes puntos y cerrada de forma normal justo después (puzle 1 resuelto; puerta A abierta; puzle 2 con las lámparas movidas; compartimentos 1, 2, 3 y 4; revelación del puzle 5 interrumpida), **WHEN** se continúa, **THEN** los hechos de cada punto valen lo que valían al cerrar y el juego es terminable en cada caso, incluido `pendiente_revelacion` verdadero en la interrupción.
- **AC-42 (R13, I)**: **GIVEN** un corte real del proceso durante la escritura (opcional, sobre disco real), **THEN** el siguiente arranque llega a «Sin partida» con un resultado `valida` y sin diálogos.
- **AC-43 (R28, I)**: **GIVEN** cada estado de hechos que producen las causas de la regla 6 a lo largo de una partida completa (se guarda tras cada causa en un recorrido de referencia), **WHEN** se continúa desde cada guardado, **THEN** se puede llegar a Recepción sin usar la consola de desarrollo. *(Se cierra cuando existan 8, 9 a 16, 21 y 22.)*

**Desarrollo**
- **AC-44 (R27, I)**: **GIVEN** la build de la demo, **THEN** no existen «borrar partida guardada» ni «guardar ahora».
- **AC-45 (R27, L)**: **GIVEN** una build de desarrollo, **WHEN** se usa «guardar ahora» con la partida Sellada, **THEN** no se escribe; **WHEN** se usa «borrar partida guardada», **THEN** los cuatro ficheros desaparecen y el resultado de la siguiente inspección es `ninguna`.

**Estados y orden**
- **AC-46 (States, L)**: **GIVEN** «Sin inspeccionar», **WHEN** se consulta el resultado o se pide un guardado, **THEN** en desarrollo hay un error visible y en la build final se rechaza y se registra una línea.

**Fórmulas (tolerancia de tiempo ±1 tick)**
- **AC-F1 (L)**: cubierto por AC-06, AC-08 y AC-07.
- **AC-F2 (L)**: cubierto por AC-22; con `k` = 31 la espera es `t_reintento_max` sin desbordar.
- **AC-F3 (L)**: **GIVEN** dos instantáneas con las mismas claves en distinto orden, **THEN** su serialización canónica y su resumen coinciden; **GIVEN** que difieren solo en `seq`, `saved_at_utc`, `build` o `cause`, **THEN** `dif` es falso.
- **AC-F4 (L)**: cubierto por AC-29; con `seq` empatados, el orden es principal, temporal, previo.

Sin criterio hasta que exista el ADR: el algoritmo del resumen, la ruta definitiva y cómo se detecta el fallo del renombrado.

## Open Questions

Solo se registran puntos que dependen de otro documento o de una medición. Las decisiones de diseño tomadas están en «Decisiones tomadas».

| # | Pregunta | Propietario | Resolver antes de |
|---|---|---|---|
| 1 | **Ruta, formato, algoritmo del resumen y reemplazo atómico.** Ruta definitiva en la carpeta de datos del usuario; si en Windows y en Linux renombrar sobre un fichero existente lo sobrescribe (la regla 13 no lo necesita, pero el ADR debe confirmarlo); cómo se detecta el fallo del renombrado y del borrado; algoritmo de hash. No hay referencia de motor para el dominio Core (`docs/engine-reference/godot/modules/` no tiene `core.md`): verificar contra la documentación de 4.7. Dato conocido: desde 4.4 `FileAccess.store_*` devuelven `bool`. | `/architecture-decision` | Fase de arquitectura |
| 2 | **`snapshot_version` y avisos nuevos en el GDD del 3:** exponer la versión de instantánea conocida y añadir «guardado en riesgo» y «guardado restablecido» a la regla 10. | GDD del sistema 3 (revisión) | Revisión del GDD del 3 |
| 3 | **Índice de sistemas:** la fila 5 debe depender de 3 y 4, no de 6 (Dependencies). | Dueño del índice | Antes del siguiente `/review-all-gdds` |
| 4 | **Contrato de reanudación de la llamada (regla 12):** 22 debe volver a ofrecer la llamada desde cero cuando `llamada_iniciada` ∧ ¬`llamada_completada` al restaurar. | GDD del sistema 22 | GDD del sistema 22 |
| 5 | **Reanudación con `caja_completa` ∧ ¬`llamada_iniciada`:** el disparador de la llamada es salir de D (slice §8.5); al reanudar en el despacho el jugador debe volver a D y salir. Decidir si 21 deja la llamada disponible de otro modo (sin tocar el slice) o lo mantiene así. | GDD del sistema 21 | GDD del sistema 21 |
| 6 | **Coste de la escritura:** ¿se nota en el equipo de referencia al guardar en el apagón y la llamada? Medir y, si hace falta, mover la escritura a un hilo. Depende de que el slice defina el equipo de referencia (§21). | Primera prueba de rendimiento | Primer playtest |
| 7 | **Valores † de las Tuning Knobs** (`t_agrupar`, `t_periodico`, reintentos, `n_fallos_aviso`) y si el jugador echa en falta una confirmación visual de que se ha guardado (el slice no la prevé; el diseño actual no la tiene). | Playtest (slice §23.4) | Primer playtest |
| 8 | **Rótulos `UI_…`** de los avisos (partida no recuperable, de una versión más nueva, guardado en riesgo, confirmación de «Nueva partida»): dar de alta y contar. | GDD de los sistemas 18, 25 y 27 | Esos GDD |
| 9 | **Registro de entidades:** registrar las entradas de «Propuesta de registro». | `/design-system` (al cerrar el GDD) | Aprobación del GDD |

## Decisiones tomadas

| # | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D-1 | Una sola ranura de autoguardado, sin guardado manual. | Varias ranuras o guardado manual. | El slice lo fija (§13.2) y el jugador no gestiona nada (*Tensión sin castigo*). Las ranuras son alcance sin valor en 25 a 30 minutos. |
| D-2 | Se guardan solo los 19 hechos (instantánea del 3) más metadatos; la escena se reconstruye y el jugador aparece en `spawn_office`. | Guardar posición, estado de cada elemento y temporizadores. | Reduce los estados posibles a los alcanzables en juego normal y hace imposible un guardado «a medias». Coherente con Escena de planta (reglas 8 y 10). Coste: la ficha de la mesa y los encajes a medias se reinician. |
| D-3 | Las tres causas del slice son obligatorias; se añaden `puzzle_solved`, `reveal_pending`, `pause_opened`, `quit` y `periodic`. | Guardar solo en las tres causas del slice. | Sin las extra, resolver el puzle 1 o 2, mover las lámparas o interrumpir la revelación del puzle 5 se perdería, y el slice (D.3) exige que `pendiente_revelacion` se conserve. Son un superconjunto y se pueden apagar en datos. |
| D-4 | La llamada es atómica: el guardado de sellado la protege y no se guarda nada más en la sesión. | Guardar `llamada_completada` y `respuesta_llamada`; o guardar a mitad de la llamada. | Evita reanudar a mitad con un `enum` ya fijado, es coherente con la regla 16 de Escena de planta y no obliga a 22 a definir reanudaciones intermedias. Coste aceptado: repetir 1 a 2 min de llamada si se cierra tras ella. |
| D-5 | El sellado es un estado de la sesión derivado del hecho cargado, con el contenido capturado en el aviso. | Una marca de «sellado» en el fichero. | Una marca en el fichero bloquearía la partida nueva y los reintentos escribirían una respuesta ya fijada. |
| D-6 | Escritura atómica con una generación de respaldo, `seq` y suma de comprobación; ganador por `seq` máximo. | Solo escritura atómica sin respaldo (como Ajustes). | Perder un fichero de ajustes cuesta un valor; perder la partida cuesta el progreso. El respaldo hace que un fichero dañado normalmente no se note. Se mantienen las convenciones de Ajustes (temporal, copia del dañado). |
| D-7 | Los hechos se validan semánticamente en el sistema 3, no aquí. | Este sistema rechaza guardados con hechos incoherentes. | El 3 ya decide restaurar tal cual para no deshacer progreso real. Un doble validador acabaría rechazando partidas jugables. |
| D-8 | «Nueva partida» no borra el fichero; lo sustituye el primer guardado de la partida nueva, tras confirmación. | Borrar al pulsar «Nueva partida». | Abandonar una partida nueva antes de la primera puerta no destruye la anterior. |
| D-9 | Fichero dañado: se usa el respaldo sin avisar; si no hay ninguno, un aviso de título no bloqueante y «Nueva partida». | Mensaje modal; o arrancar silenciosamente una partida nueva. | Un modal castiga (*Tensión sin castigo*); el silencio engañaría sobre una partida perdida. |
| D-10 | Fallo de escritura persistente: aviso discreto tras `n_fallos_aviso` fallos y reintentos con espera creciente. | Silencio total (como Ajustes) o aviso en el primer fallo. | El jugador de una partida debe poder saber que no se guarda, y un fallo puntual no debe alarmarle. |
| D-11 | Versión mayor: no se carga, se copia y el original no se toca. Versión menor: migración en memoria con cadena de funciones puras. | Tratar la mayor como dañada y rotar; migrar en disco al leer. | Una partida de una build más nueva no está dañada y no se destruye al abrir con una anterior. No reescribir al leer mantiene el original como respaldo. |
| D-12 | No depende del sistema 6; se propone retirar esa dependencia del índice. | Mantener la dependencia. | No hay ajuste que gobierne el guardado y los ficheros son independientes. |
| D-13 | `seq` (contador) decide la partida más reciente, no la hora del sistema. | Usar `saved_at_utc`. | El reloj del sistema puede retroceder o ser incorrecto; un contador es determinista y comprobable. |

## Propuesta de registro

Entradas que se proponen para `design/registry/entities.yaml` (no editado por este agente). Son hechos compartidos entre sistemas.

| Tipo | Nombre | Valor / definición | Quién lo consume |
|---|---|---|---|
| Constante | `save_format_version` | `1` (formato de la envoltura del fichero de partida) | 5, herramientas de QA |
| Constante | `save_files` | `autosave.json`, `autosave.prev.json`, `autosave.tmp`, `autosave.corrupt`, `autosave.incompatible` (carpeta definitiva en el ADR) | 5, herramientas de desarrollo, QA |
| Constante | `save_config_path` | `assets/data/save/save-config.json` | 5 |
| Parámetros | `t_agrupar` 0,1 s · `t_periodico` 120 s · `t_reintento_base` 2 s · `t_reintento_max` 30 s · `n_fallos_aviso` 3 · `max_bytes_lectura` 65 536 B | Valores † de Tuning Knobs | 5 |
| Fórmula | Cuándo se escribe (F1), Espera entre reintentos (F2), Integridad (F3), Candidato cargado (F4) | Ver Formulas | 5 |
| Vocabulario | Causas de guardado: `door_opened`, `compartment_done`, `call_started`, `puzzle_solved`, `reveal_pending`, `pause_opened`, `quit`, `periodic` | Regla 6 | 5, 8, 9 a 16, 22, 25, QA |
| Vocabulario | Resultados de inspección: `ninguna`, `valida`, `irrecuperable`, `version_futura` | Regla 17 | 5, 27 |
| Avisos | «guardado en riesgo», «guardado restablecido» | Sin datos; propuestos para la regla 10 del GDD del 3 | 5, 25 |
| Regla entre sistemas | «Partida sellada»: tras «llamada iniciada» el guardado queda cerrado hasta una partida nueva | Reglas 10 y 11 | 5, 22, 4 (regla 16 de Escena de planta), 21 |
| Regla entre sistemas | La llamada se reanuda desde su principio cuando `llamada_iniciada` ∧ ¬`llamada_completada` al restaurar | Regla 12 | 5, 22 |
