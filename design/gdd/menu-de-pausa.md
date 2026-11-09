# Menú de pausa (sistema 25)

> **Status**: Revisado (ronda de corrección 1) — pendiente de re-review
> **Author**: UX Designer (lote autónomo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Tensión sin castigo (pausa siempre disponible, sin pérdida, sin contador de pistas ni de fallos; remapeo y accesibilidad a un paso) · Autonomía como progresión (el jugador ajusta su experiencia y pide ayuda cuando quiere) · El espacio expresa la emoción (refugio funcional: el mundo queda quieto y se lee sin prisa)

## Summary

El menú de pausa es la única pantalla que el jugador abre durante la partida. Detiene el tiempo de juego y ofrece, en un solo nivel de profundidad: **Continuar**, **Pistas** (la fila la enchufa el sistema 17), **Sonido y pantalla** (tres volúmenes, subtítulos, modo de ventana), **Accesibilidad** (reducir sobresaltos y movimiento, balanceo, campo de visión, pie de texto, asistencias de puzle, «restablecer todos»), **Controles** (reasignación de teclas y botones, ajustes de manejo) y **Salir al título**. También lo abren solos la pérdida de foco de la ventana y la desconexión del mando, con un mensaje propio («Mando desconectado»). No tiene lógica de partida: lee y escribe ajustes (6), usa la API de reasignación de Entrada (1), muestra textos de la base de contenido (18), emite `pause_opened` y «pausa cerrada» ‡ y pide a Guardado (5) que guarde al salir. Sus tres pantallas de ajustes son además un **componente reutilizable** que usa la pantalla de título (27, regla 15).

> **Quick reference** — Layer: `Presentation` (categoría `UI`) · Priority: `MVP` · Key deps: `1 Entrada y controles`, `6 Ajustes persistentes`, `18 Base de contenido narrativo` · Blandas: `3 Estado y bus`, `4 Escena de planta`, `5 Guardado y carga` · Escribe hechos: nada · Escribe ajustes: sí (los de las pantallas de abajo)

## Overview

El slice (§16) exige que el menú de pausa incluya pistas, subtítulos, controles y opciones de accesibilidad (incluida «reducir movimiento»). Este GDD define esa pantalla: su jerarquía, quién la abre, qué hace con el tiempo, cómo se navega con teclado, ratón y mando, qué ajustes ofrece y cómo se reasignan los controles con las salvaguardas que pide Entrada (1, reglas 15 a 17 y 20).

**Estructura (un solo nivel de submenú).** La raíz es una lista vertical de cinco o seis filas; cada fila (salvo Continuar y Salir) abre una pantalla de segundo nivel y nunca hay un tercero: el selector de ranura de la reasignación, la captura y las confirmaciones son diálogos modales dentro de su pantalla, no niveles. Es el requisito de 2 («no dentro de un submenú de más de un nivel»).

| Raíz | Pantalla | Contenido |
|---|---|---|
| **Continuar** | — | Reanuda el juego |
| **Pistas** | La pone 17 | Solo aparece si 17 registró su panel (regla 14) |
| **Sonido y pantalla** | Nivel 2 | `vol_voces`, `vol_efectos`, `vol_musica`, `subtitulos_activos`, `modo_ventana` |
| **Accesibilidad** | Nivel 2 | `reducir_sobresaltos`, `reducir_movimiento`, `balanceo_camara`, `campo_vision`, `multiplicador_pie`, `pie_persistente`, `asistencia_encaje`, `asistencia_rotacion`, «Restablecer todos» |
| **Controles** | Nivel 2, tres pestañas | «Teclado y ratón», «Mando», «Manejo» (ajustes de manejo de 1, regla 18) |
| **Salir al título** | Diálogo de confirmación | Pide a 5 el guardado `quit` y vuelve al título |

El sistema tiene dos presentaciones especiales: el **panel «Mando desconectado»** (regla 17) y la **línea «guardado en riesgo»** (regla 27). No hay botón «Guardar partida» (el guardado es automático, slice D.3), no hay «Salir del juego» (se sale desde el título) y no hay contador de pistas ni indicador de rendimiento (art bible §7, «lo que no existe»).

## Player Fantasy

Vera deja el bolígrafo en la mesa: el edificio se queda quieto y el jugador respira. La pausa es un **refugio funcional** (art bible, 2.7): velo azul noche, texto claro, nada se mueve, nadie apremia. Nada de lo que se hace aquí puede salir mal: cambiar un volumen se oye al instante, reasignar una tecla nunca deja al jugador sin forma de volver, pedir una pista no cuesta nada ni se anota, y salir al título es seguro porque el juego lo guarda. El jugador siente que **el juego está de su lado**: cuando algo le estorba (un susto, un temblor de cámara, una tecla incómoda) puede arreglarlo en dos o tres pulsaciones, con el mando o con el teclado, y volver exactamente donde estaba.

Aesthetics del MDA: **Submission** (descanso sin presión) y **Expression** (adaptar la experiencia). Necesidad SDT: **Autonomía** y **Competencia** (control sin castigo). Tests de pilar: si dudamos entre un aviso que bloquee («¿seguro?») y uno que informe y deje deshacer, elegimos el que informa y deja deshacer, salvo si hay pérdida real (salir con el guardado en riesgo; regla 20) (*Tensión sin castigo*); si dudamos entre mostrar cuántas pistas se han usado o no mostrar nada, no mostramos nada (art bible §7, *Información incompleta*); si dudamos entre un menú vistoso y uno plano y legible, el plano (art bible 2.7: «la legibilidad prima sobre la atmósfera»).

## Detailed Rules

### A. Apertura, cierre y tiempo

1. **Quién lo abre.** Hay tres causas de apertura, siempre durante una partida (en el título la base de la pila es el menú del título de 27 y este menú no existe, 1 regla 7): (a) el jugador pulsa `pausa` (1 regla 7: sobre cualquier contexto salvo durante una carga de escena); (b) pérdida de foco de la ventana (1 regla 21); (c) desconexión del mando activo (1 regla 22). Entrada decide **cuándo** se puede abrir (incluida la espera hasta el fin de una carga de escena); 25 solo presenta el menú cuando Entrada le concede el contexto `menú`. Si coinciden (b) y (c), se abre **un** menú, con el panel de mando (regla 17).
2. **Contexto y tiempo.** Al abrirse, 25 pide a Entrada entrar en `menú` y marca la **pausa activa**: el tiempo de juego se detiene en el mismo fotograma (Δ_juego = 0; 21 regla 9, 9 regla 36, 22 regla 26; 7, tope de las peticiones aplazadas). Siguen con reloj de **tiempo real**: la propia interfaz, el guardado diferido de Ajustes (6 F3), el temporizador de captura (F2), la muestra de audio de los deslizadores (23) y los reintentos de Guardado (5). Quién detiene físicamente el árbol de escena lo fija el ADR; el contrato es el de esta regla (Open Questions 2).
3. **`pause_opened` y «pausa cerrada».** En cada apertura efectiva (por cualquiera de las tres causas, incluido el panel de mando) 25 emite **una vez** `pause_opened` (sin datos) por el bus (3), tras entrar en `menú` y marcar la pausa. No se emite si Entrada rechaza el contexto, si el menú ya estaba abierto (nada que reabrir) ni en el menú del título (salvo el componente de Opciones, regla 15, que no emite nada). Al cerrar (regla 5) 25 emite **una vez** «pausa cerrada» ‡ (sin datos), **después** de restaurar el contexto de entrada y reanudar el tiempo; un solo cierre, una sola emisión (Decisión D25-19). Los **consumidores** son 5 (`pause_opened` como causa de guardado no urgente, 5 regla 6) y 23 (`pause_opened` pausa voces y efectos; «pausa cerrada» los reanuda; 23 regla 41); 28 y 21/22 usan el reloj de juego detenido (regla 2), no la señal. 25 no espera respuesta. «Pausa cerrada» es nueva en el bus: alta pedida a 3 y al registro (Cambios requeridos).
4. **Vaciado de ajustes.** En el mismo fotograma, 25 pide a Ajustes vaciar lo pendiente (6 regla 13 y F3: «al abrir el menú de pausa» se escribe lo pendiente). 25 llama directamente a 6 (no por el bus: 6 no depende de 3). Si no hay nada pendiente no se escribe nada.
5. **Cierre.** Reanudar es: «Continuar», `pausa` o `ui_atrás` desde la raíz. En un nivel 2 o en un diálogo, `ui_atrás` y `pausa` **suben un nivel** (cierran el diálogo o vuelven a la raíz) y solo desde la raíz reanudan (Decisión D25-2). Al reanudar: 25 pide salir de `menú` (Entrada restaura el contexto anterior con el cursor donde estaba, 1 regla 6); el tiempo de juego se reanuda en el fotograma de la salida; el ratón se recaptura si el contexto lo requiere (1 regla 7); la pantalla de ajustes ya está escrita (los cambios se aplican al instante, regla 11); y, en último lugar, emite «pausa cerrada» (regla 3).
6. **Un evento, un efecto.** `pausa` y `ui_atrás` comparten `Esc` (1 regla 16): una pulsación produce un solo efecto (subir un nivel), porque el menú consume el evento. La pulsación que **abre** el menú no cuenta como cierre: se ignoran las acciones de menú durante `guarda_apertura_s` (0,15 s† de tiempo real, F4). La pulsación o el clic que **cierra** el menú (p. ej. el clic en «Continuar» o `ui_aceptar` sobre ella) **no debe llegar al mundo** como `interactuar`, `seleccionar` ni `atrás`/`repasar_bolsillo` hasta soltarse y volver a pulsar (se pide a 1; mismo criterio que su edge case de `seleccionar` al entrar en vista cercana).
7. **Velo.** El mundo queda atrás con velo azul noche y ligera desaturación (art bible 2.7). Fundido de apertura de **350 ms** (art bible, tabla de feedback); con `reducir_movimiento` verdadero, **100 ms** (art bible 7.4). El fundido es solo visual: el menú acepta entradas y el tiempo de juego ya está detenido desde el primer fotograma. El velo no parpadea ni cambia de brillo después del fundido (sin destellos). La estética exacta es de art-director.
8. **Qué no hace la pausa.** No muestra el tiempo jugado, el número de pistas usadas, intentos fallidos ni progreso (art bible §7). No cambia ningún hecho del estado (3).

### B. Navegación (teclado, ratón, mando)

9. **Un foco, tres dispositivos.** Todo es operable solo con teclado, solo con ratón o solo con mando, usando únicamente las acciones del contexto `menú`: `ui_arriba`/`ui_abajo` mueven el foco por filas, `ui_izquierda`/`ui_derecha` cambian pestañas y mueven un paso los deslizadores y selectores, `ui_aceptar` activa, `ui_atrás` sube un nivel (1, tabla de contextos). Ningún control exige gesto compuesto, doble pulsación ni tiempo (1 regla 4). Con ratón: pasar el cursor mueve el foco, el clic activa y los deslizadores se arrastran; el foco visible nunca depende solo del color (corchete o subrayado más brillo, art bible 4.4/7.2). La lista no hace «wrap» ni salta con `ui_arriba` en la primera fila (el foco se detiene; no hay efecto sorpresa).
10. **Foco inicial y retorno.** Al abrir, el foco está en «Continuar» (nunca en «Salir al título» ni en una fila destructiva). Al volver de una pantalla de nivel 2 a la raíz, el foco queda en la fila que se abrió. Al cerrar un diálogo vuelve a la fila que lo abrió. En «Salir al título» el diálogo abre con el foco en «Cancelar». Al reabrir el menú otra vez, vuelve a «Continuar» (no se recuerda la pantalla).
11. **Ajustes inmediatos.** Cada cambio en una pantalla de ajustes se escribe en 6 **en el acto** (6 regla 5): no existe «Aplicar» ni «Cancelar cambios». Cada fila muestra el valor actual (leído de 6 al abrir y al recibir su aviso de cambio, de modo que una escritura externa —p. ej. `Alt+Intro` que cambia `modo_ventana`— la refresca), un botón «Restablecer» por ajuste y, para los deslizadores, el valor con texto (no solo posición). Un valor rechazado o ajustado por 6 se **relee** y se muestra el valor real; no hay mensaje de error al jugador (6 regla 6).
12. **Repetición al mantener.** Mantener `ui_izquierda`/`ui_derecha` sobre un deslizador repite pasos tras `repeticion_inicial_s` (0,4 s†) a `repeticion_s` (0,12 s†) por paso (F1); al soltar se detiene. Con el ajuste de Entrada «alternar en lugar de mantener» activo no cambia nada aquí: la repetición es de navegación y no es un gesto de puzle.
13. **Texto.** Todos los rótulos y mensajes son entradas `UI_PAUSA_*` de la base de contenido (18); no hay literales en código. Tamaños del art bible 7.2: título de pantalla 44 px, encabezado 32 px, cuerpo y opciones 28 px, secundario 24 px; **ningún texto baja de 24 px**. Los paneles se reordenan (reflow) y no se recortan al aplicar la escala de texto de UI (Open Questions 5); todo queda dentro de los márgenes seguros de 5 % por lado (art bible §7). Atkinson Hyperlegible Next (art bible 7.2). El gris lluvia solo en texto secundario ≥ 24 px y nunca en una opción necesaria. **Contraste:** texto de cuerpo y opciones ≥ 7:1 sobre el velo (propuesta de este GDD, D25-22; la cifra y su sección del art bible quedan **no verificadas** hasta que art-director las confirme, Open Questions 14).

### C. Raíz y pistas

14. **Fila «Pistas».** El sistema 17 registra en 25 un **proveedor de panel de pistas** (un nodo de interfaz con su propia navegación; contrato ‡ de 17). Sin proveedor registrado, la fila **no aparece** y el menú funciona igual (25 no depende de 17). Con proveedor, la fila abre su panel en el nivel 2 con las mismas reglas de foco y retorno; el contenido, los niveles (tres por puzle, dos en el 6), la elección de qué puzle y las llamadas a `request_hint` (9 regla 26) son de 17. 25 solo garantiza: el tiempo de juego detenido mientras el panel está abierto, `ui_atrás` que sube a la raíz y que el panel no recibe ningún contador de pistas. **Las pistas no son ajustes** (6 regla 3): 25 no escribe nada de ellas en Ajustes ni en ningún otro sitio, y el progreso de pistas no se guarda (9 regla 26).
15. **Pantallas reutilizables (componente «Opciones»).** Las pantallas de nivel 2 «Sonido y pantalla», «Accesibilidad» y «Controles» (reglas 16 a 26) se definen como un **componente de interfaz independiente de la raíz de la pausa**: no leen el estado de la pausa, no emiten `pause_opened` ni «pausa cerrada», no pausan el tiempo y no llaman a «vaciar pendientes» (regla 4, que pertenece a la apertura de la pausa; en el título no hay partida y Ajustes no tiene nada que vaciar). Interfaz ‡ del componente: `mostrar(pantalla, pestaña_inicial?)` y la señal `cerrado` (al pulsar `ui_atrás`/`pausa` o «Volver» en el nivel 2, devuelve el control al anfitrión). La **pestaña por defecto** de «Controles» es el dispositivo activo (regla 19) salvo que el anfitrión pase `pestaña_inicial`. El anfitrión aporta el contexto de entrada `menú` y el velo; el componente solo dibuja, navega (regla 9) y escribe ajustes (regla 11). Anfitriones: la raíz de la pausa (25) y «Opciones» de la pantalla de título (27, que omite «Continuar», «Pistas» y «Salir al título» y añade «Avisos de contenido»). La dependencia de 27 sobre 25 es **blanda** y de interfaz (Decisión D25-20). La línea de guardado en riesgo es la regla 27.

### D. Pantallas de ajustes

16. **Contenido y controles de cada ajuste.** Los ajustes son los de 6 (regla 1); la tabla fija control, rango y detalle de presentación. 25 no inventa ajustes ni valores iniciales.

   | Ajuste | Control | Detalle |
   |---|---|---|
   | `vol_voces`, `vol_efectos`, `vol_musica` | Deslizador de `N_pasos` pasos (6 F1: 20† pasos de 5 %) | Valor en texto «0 %» a «100 %»; en el paso 0 muestra «Silencio» en texto (6 UI Requirements). Tras soltar o cambiar de paso, pide a 23 una muestra corta del bus regulado (6, Visual/Audio) con 25 sin temporizadores propios |
   | `subtitulos_activos` | Conmutador | «Sí» / «No» en texto |
   | `modo_ventana` | Selector de dos valores | «Pantalla completa» / «Ventana»; 6 lo aplica sin reiniciar y lo sincroniza si cambia fuera del juego |
   | `reducir_sobresaltos` | Conmutador | Texto de ayuda corto |
   | `reducir_movimiento` | Conmutador | Texto de ayuda: «Fundidos fijos y sin temblor». Cierra AC-18b de 6 |
   | `balanceo_camara` | Selector de tres valores | `completo`, `reducido`, `ninguno` (2 regla 16) |
   | `campo_vision` | Deslizador de 60° a 90° en pasos de 5° | Valor «70°»; «Restablecer» a 70° (2 UI Requirements) |
   | `multiplicador_pie` | Deslizador de 1,0 a 3,0 en pasos de 0,25 | Valor «1,25×» (6 regla 1) |
   | `pie_persistente` | Conmutador | — |
   | `asistencia_encaje`, `asistencia_rotacion` | Conmutadores | Textos de ayuda del puzle 3 y 5; nombre de `asistencia_rotacion` provisional (6 OQ 5) |

   Los conmutadores y selectores muestran siempre el valor actual en texto y se activan con `ui_aceptar` o los cambian `ui_izquierda`/`ui_derecha`. Los controles de 2 (balanceo y campo de visión) van **en la misma pantalla que `reducir_sobresaltos`**, tal como pide 2.
17. **Panel «Mando desconectado».** Cuando se abre por la causa (c) de la regla 1, el menú muestra en lugar de la raíz un panel modal con el título «Mando desconectado», una línea de ayuda («Conéctalo de nuevo, o sigue con teclado y ratón») y **un solo botón «Continuar»** con el foco. «Continuar» (o `ui_aceptar`, `ui_atrás` o `pausa`) **reanuda** el juego directamente: teclado y ratón valen para reanudar sin que haya mando (1 regla 22) y el dispositivo activo pasa al que lo pulse. Al **reconectarse** el mando con el panel abierto, el título pasa a «Mando conectado» y el foco vuelve a «Continuar» (el botón nunca desaparece ni se desactiva). El panel no tiene cuenta atrás y no se cierra solo. Si el menú **ya estaba abierto** cuando el mando se desconecta (el jugador estaba en un ajuste), no se abre ningún panel modal: aparece una **línea fija** «Mando desconectado» en la cabecera del menú, que cambia a «Mando conectado» al reconectar y desaparece al cerrar el menú (sin temporizador); y si estaba capturando una asignación de mando (regla 22) la captura se cancela sin cambios. Si la desconexión llega durante una carga de escena, el panel aparece al terminar la carga (1 regla 22).
18. **Accesibilidad y «Restablecer todos».** Al final de la pantalla Accesibilidad hay «Restablecer todos» (con diálogo de confirmación, foco en «Cancelar»; 6 UI Requirements). Restablece las **12 claves** de 6 regla 8, también las de «Sonido y pantalla» (el texto del diálogo lo dice: «Restablece sonido, subtítulos y accesibilidad. No cambia el modo de ventana ni los controles»), y llama a «restablecer todos» de 6: un solo aviso por ajuste cambiado. Descartada la alternativa de ponerlo en la raíz: la raíz queda corta y sin acciones masivas (D25-7).

### E. Controles y reasignación

19. **Pestañas.** «Teclado y ratón» y «Mando» listan las **acciones físicas reasignables** (1 regla 15): `mover` (conjunto), `mirar` (conjunto), `interactuar`, `pausa`, `atrás`, `seleccionar`. La pestaña abierta por defecto es la del **dispositivo activo** (1 regla 3). «Manejo» muestra los ajustes de manejo que Entrada declare (1 regla 18: sensibilidad de mirada de ratón y de stick, invertir eje vertical por dispositivo, zonas muertas, velocidad del cursor virtual, atracción asistida y «alternar en lugar de mantener»), dibujados de la lista que Entrada exporta (id, tipo, rango, paso, valor, rótulo) sin que 25 conozca los rangos ni los iniciales; se escriben a Entrada (que los entrega a 6 en el bloque `controles`) y llevan «Restablecer» por ajuste.
20. **Qué filas NO existen.** La pantalla **no** muestra filas para los gestos derivados `leer`, `agarrar`, `rotar` ni `mantener` (siguen a `interactuar` y `seleccionar`; 1 regla 15, AC-15), ni para `repasar_bolsillo` (sigue a `atrás`), `mover_cursor`, los movimientos del ratón ni las acciones `ui_*` (fijas). Para que el jugador sepa que existen, bajo `interactuar` y `seleccionar` hay una **leyenda de texto no enfocable** («Mantener este botón sirve para leer»; «Arrastrar, girar y mantener usan este botón») y bajo `atrás` otra («En la planta, revisa los papeles»). No son filas, no se pueden reasignar por separado y se pueden omitir si no caben en la escala de texto elegida (nunca recortadas: pasan a una segunda línea).
21. **Filas y ranuras.** Cada acción tiene **dos ranuras** por dispositivo (1 regla 15), una fila con: nombre de la acción, ranura 1, ranura 2 y «Restablecer» (la acción). Una ranura vacía muestra «Sin asignar» en texto. Activar una ranura abre un **diálogo de ranura** de tres opciones: «Cambiar», «Quitar», «Cancelar». Existen además «Restablecer teclado y ratón» / «Restablecer mando» (por dispositivo, con confirmación; 1 regla 17: «restablecer» por acción y para todo el dispositivo). Restablecer una acción no pide confirmación (se puede volver a cambiar); restablecer un dispositivo, sí.
22. **Captura.** «Cambiar» abre el estado **Capturando** (diálogo modal con el texto «Pulsa la nueva tecla o botón» y la acción afectada). Reglas: (a) la captura **solo escucha el dispositivo de la pestaña** (en «Teclado y ratón»: teclas y **botones** del ratón, no su movimiento; en «Mando»: botones y, para conjuntos, el stick o la cruceta; un stick que roza su zona muerta no cuenta); (b) empieza a escuchar `guarda_captura_s` (0,25 s†) de tiempo real **después de soltar** la entrada que la abrió (o a los 0,25 s de la apertura si ya estaba suelta), para que la pulsación que la activó (`Enter`, clic, botón sur) no se capture a sí misma, aunque se mantenga pulsada más de 0,25 s (F2); (c) **`Esc` cancela** sin cambios en teclado y ratón (1, edge case de captura); por eso `Esc` solo se recupera con «Restablecer» y no se puede reasignar a ninguna otra acción en captura (nota en el diálogo del restablecer, Open Questions 6); (d) se cancela sola a los `t_captura_s` (8 s†, contados **desde la apertura** de la captura, F2; si el temporizador resulta corto para entradas alternativas, Open Questions 11), con el temporizador visible como texto («Se cancela en 5 s»), de modo que un jugador solo con mando nunca queda atrapado; (e) `ui_atrás` no cancela en la pestaña «Mando» (el botón de atrás es un valor legítimo); lo hace el temporizador, `Esc` del teclado o una desconexión; (f) **un único valor por captura**, y el resultado va a la regla 23.
23. **Resultado de una asignación.** 25 envía la entrada capturada a la API de reasignación de Entrada (‡, Open Questions 4) y muestra el resultado, sin decidir validaciones propias salvo la presentación:

   | Resultado de Entrada | Qué muestra 25 |
   |---|---|
   | **Asignada** | Vuelve a la fila con el valor nuevo (anuncia el cambio en texto) |
   | **Conflicto** con otra acción del mismo contexto (1 regla 16) | Diálogo «“{entrada}” ya se usa para “{acción}”» con **Intercambiar** y **Cancelar** (foco en Cancelar); «Intercambiar» deja a la otra acción con la entrada que tenía esta |
   | **Conflicto sin intercambio posible** (`pausa` sobre una entrada de una acción `ui_*` fija: flechas, `Enter`, cruceta, botón sur; 1 regla 16) | El mismo mensaje de conflicto **solo con «Aceptar»** (no ofrece Intercambiar) |
   | **Rechazo por mínimo** al quitar o sustituir la última asignación de `interactuar`, `atrás` o `pausa` en ese dispositivo (1 regla 17) | Mensaje «“{acción}” necesita al menos una asignación» con «Aceptar»; no cambia nada |
   | **Rechazo de `atrás` solo imprimible** (regla 24) | Mensaje con «Aceptar»; no cambia nada |
   | **Conflicto con un conjunto** (la entrada capturada pertenece a `mover` o `mirar` y la captura es de un único valor, o al revés) | El mensaje de conflicto **solo con «Aceptar»** (sin Intercambiar): un conjunto no se parte; solo se intercambia entre acciones simples (Decisión D25-21) |
   | **Misma entrada en las dos ranuras de la misma acción** | Mensaje «“{entrada}” ya está asignada a esta acción» con «Aceptar»; no cambia nada (no se fusiona) |
   | **Tercera asignación** (ya hay dos) | La ranura que se capturó era una de las dos; no existe la tercera: el diálogo de ranura solo permite cambiar una de las dos |

24. **Teclas imprimibles y `atrás`.** Entrada decide si una entrada es **imprimible** (1 regla 20, API `es_imprimible(entrada)` ‡). Dos comportamientos distintos:
    - **Aviso (no bloquea).** Si el jugador asigna **`atrás`**, **`interactuar`** o **`pausa`** (teclado y ratón) a una tecla imprimible, la asignación **se aplica** y la fila muestra una **línea de aviso fija** con icono y texto: «Esta tecla escribe en el buscador del ordenador; con él enfocado puede no responder.» Solo para **`atrás`** se añade «La otra asignación sigue valiendo.», y únicamente si la otra ranura es no imprimible (única garantía de 1 regla 17); para `interactuar` y `pausa` no se afirma nada sobre la otra ranura (1 regla 20; el index pide el aviso para `atrás`; se extiende a las otras dos porque la regla 20 de 1 cita `interactuar` y `pausa` queda igual de muda con el campo enfocado: Open Questions 3). El aviso permanece mientras haya una asignación imprimible en esa acción y no depende del color.
    - **Rechazo.** Se rechaza cualquier cambio —asignar una tecla imprimible a la ranura que tiene la **única** asignación no imprimible de `atrás`, o «Quitar» esa asignación— que deje **`atrás` en teclado y ratón con solo teclas imprimibles** (1 regla 17: `atrás` conserva siempre al menos una asignación no imprimible). Mensaje: «Atrás necesita una tecla que no escriba (por ejemplo Esc o el clic derecho)». El rechazo se **decide en Entrada** y 25 solo lo presenta; para no ofrecer lo imposible, 25 desactiva el comando «Quitar» (con «Sin efecto» en texto) en la ranura que sea esa única asignación no imprimible. En «Mando» no hay teclas imprimibles y no aplica.
25. **Mando desconectado en la pestaña «Mando».** Con el mando ausente la pestaña sigue visible y editable (muestra las asignaciones guardadas); la captura no puede completarse (se cancela por temporizador, o ya con la línea de la regla 17). No se bloquean otras pestañas.
26. **Conjuntos `mover` y `mirar`.** Se reasignan como conjunto (1 regla 15): la ranura muestra el conjunto como un texto único (p. ej. «W A S D», «Flechas», «Stick izquierdo»). En teclado, «Cambiar» pide **cuatro direcciones en orden** (arriba, abajo, izquierda, derecha) con un indicador de «1 de 4» en texto; `Esc` cancela todo el conjunto sin cambios. En mando se elige el stick de una lista (stick izquierdo, stick derecho) y, para `mover`, también la cruceta. `mirar` con el ratón no se reasigna por teclado (movimiento del ratón no reasignable). Decisión propia, depende de la API de 1 (Open Questions 4).

### F. Guardado, salir y avisos

27. **Línea «guardado en riesgo».** 25 se suscribe a los avisos de Guardado «guardado en riesgo» y «guardado restablecido» (5, vía 3; el art bible dice que la pausa indica el estado con texto) y mantiene una variable `guardado_en_riesgo` desde que empieza la partida. Mientras sea verdadera, la raíz muestra bajo el título una línea fija con icono y texto «No se puede guardar la partida. Seguimos intentándolo.» (no depende del color). Al recibir «guardado restablecido» desaparece en el acto, también con el menú abierto. Si 5 ofrece una consulta de estado (‡), 25 la lee al abrir; si no, usa lo acumulado. No hay otro indicador de guardado en la pausa (no hay «guardado correcto» ni icono de disco). Sin el sistema 5 (blanda), la línea no existe.
28. **Salir al título.** La fila abre un diálogo de confirmación con «Cancelar» (foco) y «Salir al título». Texto normal: «Se guardará tu progreso.» Con `guardado_en_riesgo` verdadero: «No se ha podido guardar la partida. Si sales ahora, puedes perder el progreso reciente.» (el único caso con aviso grave, porque hay pérdida real; Tensión sin castigo). Al confirmar, en este orden: (1) 25 pasa a **Saliendo** y descarta toda entrada del menú (un doble clic o doble `ui_aceptar` no repite la petición); (2) pide a 5 «salir al título» (causa `quit`, urgente, E/S síncrona; 5 reglas 6 y 17), que escribe una vez y no reintenta si falla; (3) cuando 5 devuelve el control, 25 pide la **descarga total** de la escena (4 regla 15) y, con ella, Entrada repone `menú` con el menú del título como base (1 regla 6); (4) 25 emite «pausa cerrada» (regla 3, para que 23 reanude y el título suene normal) y se cierra. Si falla la escritura de `quit`, se sale igualmente (5 edge case: «Continuar» ofrece el último guardado anterior). 25 no decide qué ofrece el título tras salir: lo hace 27 con la re-inspección de 5 (Open Questions 1).
29. **No hay guardado manual ni «salir del juego».** Descartados en D25-3 y D25-5.

### G. Estados

El sistema tiene los estados siguientes; solo hay uno activo.

| Estado | Qué ocurre | Sale hacia |
|---|---|---|
| **Cerrado** | La partida corre; 25 solo escucha `pausa`, foco, mando y los avisos de 5 | Abierto (regla 1) |
| **Abierto · raíz** | Lista de la raíz, con foco | Abierto · pantalla, Abierto · diálogo, Saliendo, Cerrado |
| **Abierto · pantalla** | Una pantalla de nivel 2 (pistas, sonido, accesibilidad, controles) | Raíz (`ui_atrás`, «Volver»); Diálogo; Cerrado nunca directo |
| **Abierto · diálogo** | Confirmación, diálogo de ranura, conflicto, mensaje | La pantalla que lo abrió; Capturando |
| **Capturando** | Diálogo modal de captura (regla 22) | Resultado (regla 23) o cancelación |
| **Panel de mando** | Panel «Mando desconectado» (regla 17) | Cerrado |
| **Saliendo** | Petición de salir al título en curso; entradas descartadas | (el título; 25 se descarta con la partida) |

## Formulas

Valores † propuestos, a validar en playtest. Los de datos viven en `assets/data/ui/pause.json`.

### F1 · Repetición al mantener una dirección

`pasos(t) = (t < t_ini) ? 0 : 1 + floor((t − t_ini) / t_rep)` con `t` = tiempo real mantenido tras el primer paso inmediato.

| Variable | Tipo | Rango | Origen | Descripción |
|---|---|---|---|---|
| t | float (s) | ≥ 0 | calculado | Tiempo mantenido desde la primera pulsación |
| t_ini (`repeticion_inicial_s`) | float (s) | 0,2–1,0 | datos, 0,4† | Espera antes de repetir |
| t_rep (`repeticion_s`) | float (s) | 0,05–0,30 | datos, 0,12† | Intervalo de repetición |

La pulsación inicial da un paso inmediato (no cuenta en `pasos`). Ejemplo (instante no frontera): mantenida 1,03 s → 1 + floor(0,63 / 0,12) = 1 + 5 = 6 repeticiones tras el primer paso inmediato (≈ 35 % del deslizador de 20 pasos). Un volumen recorre sus 20 pasos (1 inmediato + 19 repeticiones) en 0,4 + 18 × 0,12 = **≈ 2,56 s** (≈ 2,6 s) de mantener. Los instantes exactos de frontera (p. ej. 1,0 s) dependen del redondeo en coma flotante y no se prueban; la tolerancia es ±1 repetición. El valor nunca sale del rango: el tope lo aplica 6 (F1 de 6).

### F2 · Captura de una asignación

`t_escucha = max(t_soltar, 0) + guarda_captura_s`; `activa ⇔ (t ≥ t_escucha) ∧ (t < t_captura_s)`; `restante = ceil(t_captura_s − t)`. `t` y `t_soltar` cuentan desde la apertura del estado Capturando; **`t_captura_s` también cuenta desde la apertura** (no desde que empieza a escuchar), por lo que la escucha efectiva dura `t_captura_s − t_escucha`.

| Variable | Tipo | Rango | Origen | Descripción |
|---|---|---|---|---|
| t | float (s) | ≥ 0 | calculado | Tiempo real desde que se abre el estado Capturando |
| guarda_captura_s | float (s) | 0,1–0,5 | datos, 0,25† | Ignora entradas justo tras abrir |
| t_captura_s | float (s) | 4–20 | datos, 8† | Cancelación automática (≥ 4 s: tiempo para pulsar con una mano torpe) |
| t_soltar | float (s) | ≥ 0 | calculado | Instante (desde la apertura) en que se suelta la entrada que abrió la captura; 0 si ya estaba suelta. Mientras siga pulsada, `t_escucha` no está definida y no se escucha |
| t_escucha | float (s) | ≥ `guarda_captura_s` | calculado | Instante en que empieza a escuchar |

Un temporizador de cancelación visible en texto no es un tiempo límite sobre una acción del jugador: cancelar no pierde nada (puede reabrir). Ejemplos: (1) `Enter` pulsado en t = 0 y soltado en t_soltar = 0,10 → `t_escucha` = 0,35 s; a t = 8 s se cancela (escucha efectiva 7,65 s). (2) Entrada mantenida hasta t_soltar = 0,60 → `t_escucha` = 0,85 s (en t = 0,25 sigue pulsada y no se escucha). (3) Captura abierta con una entrada ya suelta (t_soltar = 0) → `t_escucha` = 0,25 s.

### F3 · Fundido del velo

`alfa(t) = min(t / t_velo, 1)`, `t_velo = t_velo_s` (0,35 s, art bible) o `t_velo_reducido_s` (0,10 s) con `reducir_movimiento` verdadero.

Variables: `t` (s, tiempo real, desde la apertura; 0–`t_velo`), `t_velo_s` (0,35 s, art bible, rango 0,2–0,6), `t_velo_reducido_s` (0,10 s, art bible 7.4, rango 0,05–0,2). Ejemplo: en t = 0,175 s el velo está al 50 %. El cierre usa la misma duración.

### F4 · Guarda de apertura

`ignorar_menú ⇔ (t < guarda_apertura_s)`, con `guarda_apertura_s` 0,15 s† (rango 0–0,3, tiempo real). Evita que la pulsación que abre cierre el menú (regla 6) o active «Continuar» por rebote.

## Edge Cases

**Apertura**
- **If se pulsa `pausa` durante una carga de escena**: Entrada la descarta (1 regla 7); 25 no se abre. Foco y mando pendientes: se abre al terminar la carga (1 reglas 21 y 22).
- **If se pierde el foco con una acción mantenida** (`leer`, `agarrar`): Entrada la cancela y se abre el menú (1 edge case); 25 no cambia nada del puzle.
- **If se pierde el foco y se desconecta el mando a la vez**: un menú, panel de mando (regla 1).
- **If el menú ya está abierto y se pierde el foco o vuelve**: no se reabre, no se reemite `pause_opened` y no cambia nada; el jugador reanuda cuando quiere (1 edge case).
- **If `pausa` llega durante una transición bloqueante, una escena dirigida o la llamada**: se abre; el tiempo de juego, incluida la cuenta de 20 s de la llamada y su guarda de 0,6 s (22 reglas 13, 26 y AC-22-32), se detiene; al cerrar sigue donde estaba (1 edge case).
- **If el menú se abre durante `sin control`**: el tope de seguridad de la transición también se detiene (1 edge case); 25 no lo pide.
- **If Entrada rechaza el contexto `menú`**: 25 no se abre, no emite `pause_opened` y no marca la pausa (el tiempo sigue). Se registra.
- **If la partida termina («partida terminada», 4) con el menú abierto**: el menú sigue abierto; «Salir al título» se resuelve con 5 (que decide si hay guardado o no, 5 regla 29). 25 no cierra el menú por otras señales.

**Ajustes**
- **If un ajuste cambia por otra vía mientras el menú está abierto** (`Alt+Intro` en `modo_ventana`, consola de desarrollo): la fila se refresca con el aviso de cambio de 6.
- **If 6 devuelve un valor distinto del escrito** (ajustado al límite o a la rejilla): la fila muestra el valor devuelto, sin mensaje.
- **If el sistema operativo rechaza `modo_ventana`**: el selector vuelve al valor real por el aviso de 6; no se muestra mensaje.
- **If el jugador arrastra un deslizador fuera de su pista**: se queda en el extremo (6 ajusta al límite); soltar fuera cuenta como soltar dentro.
- **If se cambia un volumen y se reanuda sin soltar**: el último valor leído queda escrito (cada paso ya se escribió).
- **If se pide una muestra de audio y el bus está en silencio (paso 0)**: no suena; el texto «Silencio» confirma el estado (23 decide el resto).
- **If se cambia `campo_vision` o `balanceo_camara`**: al reanudar se aplica en el mismo fotograma (2 AC-19; el mundo está pausado).
- **If se cambia `reducir_movimiento` con el menú abierto**: el velo de esta apertura ya terminó; el siguiente usa el valor nuevo; las escenas en curso terminan como se emitieron (6 AC-18b).
- **If 6 no está «Listo»** (no ocurre en la práctica: se garantiza por orden de arranque, 6 OQ 3): en desarrollo, error visible; en la build final las filas muestran los iniciales y las escrituras se descartan, con línea en el log. El menú no se bloquea.

**Controles**
- **If dos entradas capturadas llegan en el mismo fotograma**: gana la primera; se ignora la otra.
- **If se captura una entrada que pertenece a un conjunto (`mover`, `mirar`) para una acción simple, o al revés**: conflicto sin intercambio, solo «Aceptar» (regla 23).
- **If se captura la misma entrada para las dos ranuras de la misma acción**: mensaje «ya está asignada a esta acción» y nada cambia (regla 23).
- **If el jugador abre «Opciones» desde el título**: se usa el componente de la regla 15; no hay pausa, `pause_opened` ni «pausa cerrada».
- **If se pulsa una tecla no asignable en captura**: Entrada la rechaza (p. ej. tecla de sistema) con un mensaje corto y vuelve a Capturando sin consumir el tiempo.
- **If se asigna `pausa` a una tecla que ya es una acción `ui_*`** (`Enter`, flechas, `Esc` no cuenta: es par permitido): rechazo sin intercambio (regla 23).
- **If se reasigna `atrás` y es la acción que cierra este menú**: el cambio vale **desde la siguiente pulsación**; la que se acaba de usar en la captura no cierra nada (la captura la consumió).
- **If el jugador reasigna `pausa` a otra entrada y el menú está abierto**: se aplica en el acto; `Esc` sigue siendo `ui_atrás` (fija); el menú se puede cerrar con la nueva entrada o con `ui_atrás`.
- **If se importa un bloque de controles dañado al arrancar**: Entrada usa los valores por defecto (1); la pantalla muestra los valores por defecto sin avisar (6 regla 11).
- **If un mando distinto se conecta**: sin cambios; los mandos son un solo «mando» (1 edge case).
- **If el jugador cambia de pestaña con la captura abierta**: no puede (modal); solo cancela o completa.
- **If el dispositivo activo cambia mientras se mira la pestaña**: la pestaña no se cambia sola (no hay parpadeo de pantallas); solo cambia el icono de los glifos.

**Salir y guardado**
- **If hay un guardado en curso o `Sellando` al salir**: lo resuelve 5 (regla 11.2: escribe el contenido capturado; si falla, no reintenta). 25 solo muestra el diálogo con el texto de riesgo si lo hay.
- **If 5 no existe o no responde**: la salida procede igualmente (dependencia blanda) con el texto normal del diálogo.
- **If la descarga total falla** (4: error de carga): 4 repone `menú` con el mensaje de error y «Volver al título» (4 regla 14); 25 no interviene.
- **If el jugador pulsa «Salir al título» y a los pocos instantes se pierde el foco**: Entrada abre el menú por foco; con 25 en Saliendo se ignora y no se vuelve a abrir.
- **If se recibe «guardado en riesgo» con el diálogo de salida abierto**: el texto del diálogo cambia al de riesgo sin mover el foco ni cerrarlo.

**Presentación y accesibilidad**
- **If la escala de texto de interfaz sube a 125 o 150 %** (Open Questions 5): los paneles se reordenan; si una pantalla no cabe en la altura, se desplaza con el foco (la fila enfocada siempre visible) y con `ui_arriba`/`ui_abajo`; nunca se recorta.
- **If no hay textos de 18** (catálogo ausente): se usa el texto de emergencia de 18 (la clave visible); el menú sigue operable.
- **If 1 no existe**: el menú no puede abrirse (dependencia dura, 1 regla 7).

## Dependencies

**Aguas arriba (de qué depende)**
| Sistema | Tipo | Qué usa |
|---|---|---|
| 1 Entrada y controles | **Dura** | `pausa`, `ui_*`, `atrás`; contexto `menú`; avisos de foco y mando; API de reasignación (‡); lista de ajustes de manejo (‡); `es_imprimible` (‡) |
| 6 Ajustes persistentes | **Dura** | Lectura y escritura de los 13 ajustes del catálogo (excepto `controles`, que va por Entrada), «restablecer» por ajuste y «todos», aviso de cambio, «vaciar pendientes» al abrir |
| 18 Base de contenido narrativo | **Blanda** (rótulos; texto de emergencia de 18) | Entradas `UI_PAUSA_*` |
| 5 Guardado y carga | **Blanda** | «guardado en riesgo» / «restablecido»; petición «salir al título» (causa `quit`); recibe `pause_opened` como causa |
| 3 Estado y bus de eventos | **Blanda** | Emite `pause_opened` y «pausa cerrada» ‡; recibe los avisos de 5 |
| 4 Escena de planta | **Blanda** | Descarga total al salir al título |

**Aguas abajo (quién depende de 25)**
| Sistema | Tipo | Interfaz |
|---|---|---|
| 5 Guardado y carga | Blanda | Recibe `pause_opened` como causa no urgente; recibe la petición «salir al título» |
| 17 Sistema de pistas | **Dura de 17 sobre 25** (25 no depende de 17); GDD existente: `sistema-de-pistas.md` | 17 aporta `HintPanel` (nombre verificado en 17, regla 1 y l. 212) que 25 aloja en la fila «Pistas» (regla 14); 17 es el único punto de petición. 25 no lo conoce hasta que se registra |
| 9 Marco de puzles | Blanda | Pausa del reloj de juego; origen de `request_hint` (a través de 17) |
| 6 Ajustes persistentes | Dura | Escribe los ajustes del jugador; cierra AC-18b |
| 2 Jugador en primera persona | Blanda | Ofrece `campo_vision` y `balanceo_camara` junto a `reducir_sobresaltos` |
| 7, 22, 21, 8 | Blanda | Todos sus temporizadores de juego se detienen con la pausa (7 aplazadas, 22 regla 26, 21 regla 9, 8 regla 20) |
| 23 Audio | Blanda | **Consume `pause_opened` y «pausa cerrada»** (23 regla 41, AC-23-18): pausa y reanuda voces y efectos; da la muestra de referencia de los deslizadores |
| 28 Atmósfera | Blanda | Se pausa con el reloj de juego detenido (regla 2) |
| 27 Pantalla de título | Blanda (de 27 sobre 25) | **Reutiliza el componente «Opciones»** (regla 15: interfaz `mostrar(pantalla, pestaña_inicial?)` y señal `cerrado`); recibe al jugador tras «Salir al título» |
| 30 Accesibilidad | Blanda | Si ofrece las mismas pantallas, las dos escriben las mismas claves de 6 (30 no revisado en esta ronda) |

**Bidireccionalidad.** Entrada ya lista a 25 como dependiente (tabla de Dependencies, fila «Pendiente» para el panel de mando; este GDD la cierra). 5, 3, 6, 9, 7, 22, 21, 2, 17, 23 y 27 ya citan a 25 (ver «Cambios requeridos»); 28 y 30 deben listar a 25 al revisarse.

## Tuning Knobs

| Parámetro | Valor † | Rango seguro | Qué afecta |
|---|---|---|---|
| `t_velo_s` | 0,35 s (art bible) | 0,2–0,6 s | Duración del fundido del velo |
| `t_velo_reducido_s` | 0,10 s (art bible 7.4) | 0,05–0,2 s | Fundido con `reducir_movimiento` |
| `guarda_apertura_s` | 0,15 s† | 0–0,3 s | Rebote al abrir (F4) |
| `repeticion_inicial_s` | 0,4 s† | 0,2–1,0 s | Espera antes de repetir (F1) |
| `repeticion_s` | 0,12 s† | 0,05–0,30 s | Velocidad de repetición (F1) |
| `guarda_captura_s` | 0,25 s† | 0,1–0,5 s | Evita capturar la pulsación que abre la captura (F2) |
| `t_captura_s` | 8 s† | 4–20 s | Cancelación automática de la captura (F2) |
| Tamaños de texto | art bible 7.2 | ≥ 24 px | Legibilidad; los fija el art bible, no 25 |
| `mostrar_leyendas_gestos` | verdadero | bool | Muestra las leyendas bajo `interactuar`, `seleccionar` y `atrás` (regla 20) |

`N_pasos`, `db_min`, rangos de ajustes y valores iniciales **no** son de 25: son de 6.

## Acceptance Criteria

Evidencia: **L** = test unitario (gdUnit4, `tests/unit/pause/`, sin E/S real ni reloj real); **I** = integración o playtest documentado; **UI** = captura retenida en `production/qa/evidence/` por pantalla tocada (obligatoria, ver coding-standards). Tolerancia de tiempo ±1 fotograma.

**Apertura, cierre y tiempo (reglas 1 a 8)**
- **AC-25-01 (R1, R2, I):** **GIVEN** `exploración`, **WHEN** llega `pausa`, **THEN** el contexto es `menú`, Δ_juego vale 0 desde ese fotograma, el foco está en «Continuar» y el ratón está liberado; **WHEN** se reanuda, **THEN** el contexto anterior se restaura con el cursor en su sitio y el tiempo corre en ese fotograma.
- **AC-25-02 (R3, L):** **GIVEN** el bus, **WHEN** se abre el menú por `pausa`, foco o mando, **THEN** `pause_opened` se emite **una vez** por apertura; con el menú ya abierto no se reemite; si Entrada rechaza el contexto no se emite; en el título no se emite.
- **AC-25-50 (R3, R5, L):** **GIVEN** el menú abierto, **WHEN** se reanuda (por `pausa`, `ui_atrás` desde la raíz o «Continuar»), **THEN** «pausa cerrada» se emite **una vez**, después de restaurar el contexto y de reanudar el tiempo; subir un nivel o cerrar un diálogo no la emite; 23 reanuda voces y efectos con ella (AC-23-18).
- **AC-25-03 (R4, I):** **GIVEN** Ajustes con cambios pendientes, **WHEN** se abre el menú, **THEN** se escribe en el acto (6 AC-14c); sin pendientes no escribe.
- **AC-25-04 (R3, I):** **GIVEN** cambios de partida pendientes y 5 activo, **WHEN** se abre el menú, **THEN** 5 recibe `pause_opened` y escribe con `cause` = `pause_opened` (5 AC-09).
- **AC-25-05 (R5, R6, L):** **GIVEN** `Esc` asignado a `pausa` y `ui_atrás`, **WHEN** se pulsa en una pantalla de nivel 2, **THEN** vuelve a la raíz (un solo efecto); **WHEN** se pulsa en la raíz, **THEN** reanuda; en un diálogo cierra el diálogo.
- **AC-25-06 (R6, F4, L):** **GIVEN** `guarda_apertura_s` = 0,15 s, **WHEN** la entrada que abrió el menú llega de nuevo a t = 0,10 s, **THEN** se ignora; a t = 0,20 s se atiende.
- **AC-25-07 (R6, I):** **GIVEN** «Continuar» activado con un clic en un puzle de `vista cercana`, **WHEN** se reanuda, **THEN** el mundo no recibe `seleccionar` de ese clic (ni `interactuar`/`atrás` con teclado o mando) hasta soltarse y pulsar otra vez. *(Se cierra con el cambio pedido a 1.)*
- **AC-25-08 (R7, F3, UI):** **GIVEN** `reducir_movimiento` falso, **THEN** el velo llega al 100 % en 0,35 s; con verdadero, 0,10 s; **AND** el fundido es una sola rampa monótona de alfa, sin cambios de luminancia posteriores (verificable con captura de fotogramas del fundido). Captura retenida de la raíz.
- **AC-25-09 (R2, I):** **GIVEN** una llamada con 12 s de espera, **WHEN** el menú está abierto 30 s, **THEN** la cuenta de 20 s sigue en 12 s al reanudar; el guardado diferido de 6 sigue avanzando en tiempo real (AC-22-11 de 22; 6 AC-14d).
- **AC-25-10 (R8, I):** **WHEN** se inspecciona la pantalla, **THEN** no hay contador de pistas, intentos, tiempo ni progreso, y no se escribe ningún hecho en 3.

**Navegación y accesibilidad (reglas 9 a 13)**
- **AC-25-11 (R9, I):** **GIVEN** solo teclado, **THEN** se alcanzan y activan todas las filas, ranuras, diálogos y «Restablecer» con `ui_*`; lo mismo con solo mando y con solo ratón.
- **AC-25-12 (R9, UI):** **THEN** el foco se distingue sin color (corchete o subrayado) en todas las pantallas; capturas retenidas de raíz, Sonido y pantalla, Accesibilidad, Controles (3 pestañas), diálogo de confirmación y panel de mando.
- **AC-25-13 (R10, L):** **WHEN** se abre el menú, **THEN** el foco está en «Continuar»; **WHEN** se vuelve de una pantalla a la raíz, **THEN** el foco está en su fila; **WHEN** se abre el diálogo «Salir al título», **THEN** el foco está en «Cancelar».
- **AC-25-14 (R11, L):** **GIVEN** `vol_musica` = 1,0, **WHEN** el jugador mueve un paso a la izquierda, **THEN** 6 recibe 0,95 en el mismo fotograma y la fila muestra «95 %»; con el paso 0, la fila muestra «Silencio».
- **AC-25-15 (R11, L):** **GIVEN** `campo_vision` = 70, **WHEN** el jugador arrastra el deslizador a 72, **THEN** la fila muestra «70°» (el valor devuelto por 6); fuera de rango se queda en el extremo.
- **AC-25-16 (R11, I):** **WHEN** `modo_ventana` cambia por una escritura externa a la pantalla (el atajo `Alt+Intro` **no es nativo de Godot**: lo implementa Ajustes o Entrada, por decidir, Open Questions 12), **THEN** la fila abierta cambia a «Ventana» sin pulsar nada.
- **AC-25-17 (R12, F1, L):** **GIVEN** un deslizador de 20 pasos, **WHEN** se mantiene `ui_derecha` 1,0 s, **THEN** hay 1 paso inmediato y 6 repeticiones (F1; 1,03 s es un instante no frontera: 1 + floor(0,63 / 0,12) = 6); a 0,39 s no hay ninguna; soltar detiene.
- **AC-25-18 (R13, UI):** **THEN** el texto mínimo es ≥ 24 px a 1080p, el contraste de cuerpo ≥ 7:1 (regla 13), y todo queda dentro del 5 % de margen. *(La comprobación con la escala de texto UI en 150 % queda **diferida** hasta que exista el ajuste, Open Questions 5.)*
- **AC-25-19 (R13, L):** **GIVEN** 18 sin una clave `UI_PAUSA_*`, **THEN** se muestra el texto de emergencia de 18 y el menú sigue operable.

**Pistas y raíz (reglas 14, 27)**
- **AC-25-20 (R14, L):** **GIVEN** que 17 no registró panel, **THEN** la raíz tiene cinco filas sin «Pistas»; **GIVEN** panel registrado, **THEN** «Pistas» aparece entre «Continuar» y «Sonido y pantalla», abre su panel y `ui_atrás` vuelve a la raíz.
- **AC-25-21 (R14, L):** **WHEN** se piden y se cierran pistas, **THEN** 25 no escribe nada en 6 ni en 3 ni guarda ningún contador.
- **AC-25-22 (R27, L):** **GIVEN** «guardado en riesgo» recibido con el menú cerrado, **WHEN** se abre, **THEN** la raíz muestra la línea con icono y texto; **WHEN** llega «guardado restablecido», **THEN** desaparece en ese fotograma.

**Ajustes (reglas 16 y 18)**
- **AC-25-23 (R16, UI):** **THEN** «Sonido y pantalla» ofrece `vol_voces`, `vol_efectos`, `vol_musica`, `subtitulos_activos`, `modo_ventana`; «Accesibilidad» ofrece `reducir_sobresaltos`, `reducir_movimiento`, `balanceo_camara`, `campo_vision`, `multiplicador_pie`, `pie_persistente`, `asistencia_encaje`, `asistencia_rotacion`; **THEN** `balanceo_camara` y `campo_vision` están en la misma pantalla que `reducir_sobresaltos`; no hay claves de pistas.
- **AC-25-24 (R16, I):** **GIVEN** 19 y 21, **WHEN** se cambia `reducir_movimiento` en el menú, **THEN** la siguiente apertura de la pantalla del ordenador dura 100 ms y el siguiente `LUCES_PARPADEO` es una atenuación única (cierra 6 AC-18b).
- **AC-25-25 (R16, I):** **GIVEN** 23, 26 y 28, **WHEN** se cambian `vol_*`, `subtitulos_activos` o `reducir_sobresaltos`, **THEN** cada uno reacciona en el mismo fotograma del aviso (6 AC-18); tras soltar un deslizador de volumen se oye la muestra del bus.
- **AC-25-26 (R16, L):** **GIVEN** `multiplicador_pie` = 1,0, **WHEN** se mueve a 1,3 con el ratón, **THEN** la fila muestra «1,25×»; 3,5 se queda en «3,0×».
- **AC-25-27 (R18, L):** **GIVEN** `vol_voces` = 0,5, `reducir_movimiento` verdadero y `modo_ventana` = `ventana`, **WHEN** se confirma «Restablecer todos», **THEN** las 12 claves valen su inicial, hay un aviso por clave cambiada, `modo_ventana` y `controles` no cambian; con «Cancelar» no cambia nada.
- **AC-25-28 (R18, UI):** **THEN** el diálogo de «Restablecer todos» dice que no cambia el modo de ventana ni los controles; foco en «Cancelar».

**Controles (reglas 19 a 26)**
- **AC-25-29 (R19, R20, L):** **GIVEN** la pestaña «Teclado y ratón» y «Mando», **THEN** las filas son exactamente `mover`, `mirar`, `interactuar`, `pausa`, `atrás`, `seleccionar`; **THEN** no existen filas de `leer`, `agarrar`, `rotar`, `mantener`, `repasar_bolsillo`, `mover_cursor` ni `ui_*`; las leyendas no son enfocables.
- **AC-25-30 (R19, L):** **GIVEN** «Manejo», **THEN** las filas son las que exporta Entrada; con una lista distinta, la pantalla cambia sin tocar 25.
- **AC-25-31 (R21, L):** **GIVEN** una ranura asignada, **WHEN** se activa, **THEN** el diálogo ofrece «Cambiar», «Quitar», «Cancelar»; una ranura vacía solo «Cambiar» y «Cancelar»; «Restablecer» por acción no pide confirmación; «Restablecer teclado y ratón» sí.
- **AC-25-32 (R22, F2, L):** **GIVEN** el jugador activa «Cambiar» con `Enter`, **THEN** el `Enter` no se captura a sí mismo (la captura escucha desde `t_escucha` = soltar + 0,25 s: soltado en 0,10 s, escucha desde 0,35 s; **mantenido hasta 0,60 s**, desde 0,85 s y una pulsación a 0,50 s no se captura); **WHEN** pasan 8 s desde la apertura sin entrada, **THEN** la captura se cancela sin cambios; **WHEN** se pulsa `Esc`, **THEN** se cancela sin cambios; **WHEN** el mando se desconecta durante la captura de mando, **THEN** se cancela.
- **AC-25-33 (R22, L):** **GIVEN** la pestaña «Mando», **THEN** la captura ignora teclas y ratón, y un stick por debajo de su zona muerta no se captura.
- **AC-25-34 (R23, L):** **GIVEN** `interactuar` = `E` y se captura `Q` ya asignada a otra acción del mismo contexto, **THEN** aparece el conflicto con «Intercambiar» y «Cancelar»; con «Intercambiar» las dos se cruzan; con «Cancelar» nada cambia.
- **AC-25-35 (R23, L):** **GIVEN** `pausa` y una entrada que es una acción `ui_*` fija, **THEN** el diálogo solo tiene «Aceptar» y nada cambia.
- **AC-25-36 (R23, L):** **GIVEN** `interactuar` con una sola asignación en el mando, **WHEN** se intenta «Quitar» o dejarla vacía, **THEN** se rechaza con el mensaje de mínimo y no cambia nada (1 AC de regla 17).
- **AC-25-37 (R24, L):** **GIVEN** `atrás` con `Esc` y clic derecho, **WHEN** se asigna `Q` (imprimible) a la ranura de `Esc`, **THEN** la asignación se aplica (queda el clic derecho) y la fila muestra el aviso con icono y texto; **WHEN** se pone un valor no imprimible, **THEN** el aviso desaparece.
- **AC-25-38 (R24, L):** **GIVEN** `atrás` con `Esc` y `Q`, **WHEN** se intenta asignar `W` a la ranura de `Esc` o «Quitar» la de `Esc`, **THEN** se rechaza con el mensaje de «Atrás necesita una tecla que no escriba» y nada cambia; el comando «Quitar» de esa ranura está desactivado.
- **AC-25-39 (R24, L):** **GIVEN** `interactuar` o `pausa` asignada a una tecla imprimible, **THEN** se aplica y muestra el aviso (sin rechazo).
- **AC-25-40 (R26, L):** **GIVEN** `mover` en teclado, **WHEN** se elige «Cambiar», **THEN** pide cuatro direcciones con «1 de 4» a «4 de 4»; `Esc` en la tercera cancela el conjunto entero sin cambios.

**Mando desconectado (regla 17)**
- **AC-25-41 (R17, I):** **GIVEN** el mando era el dispositivo activo en `exploración`, **WHEN** se desconecta, **THEN** se abre el menú en el acto con el panel «Mando desconectado» y un solo botón «Continuar» con foco; el tiempo está detenido; `pause_opened` se emite una vez.
- **AC-25-42 (R17, I):** **GIVEN** el panel abierto, **WHEN** el jugador pulsa `Esc` o hace clic en «Continuar» con teclado y ratón, **THEN** el juego se reanuda y el dispositivo activo pasa a teclado y ratón; **WHEN** en lugar de eso se reconecta el mando, **THEN** el título pasa a «Mando conectado» y «Continuar» sigue con foco; **THEN** el panel no tiene temporizador.
- **AC-25-43 (R17, I):** **GIVEN** una desconexión durante `ANIM_PHONE_PICKUP`, **THEN** el panel se abre en el acto y la animación se detiene; durante una carga de escena, al terminar la carga.
- **AC-25-44 (R17, I):** **GIVEN** el menú ya abierto en «Accesibilidad», **WHEN** el mando se desconecta, **THEN** no se abre ningún panel modal, aparece la línea «Mando desconectado» en la cabecera y el foco no se mueve; al cerrar el menú desaparece.

**Salir al título (regla 28)**
- **AC-25-45 (R28, I):** **GIVEN** el guardado normal, **WHEN** se confirma «Salir al título», **THEN** 5 recibe `quit` y escribe una vez, se pide la descarga total, la pila queda en [`menú`] y se muestra el título; **GIVEN** el diálogo recién abierto, **WHEN** se pulsa `ui_aceptar`, **THEN** cancela (el foco está en «Cancelar»).
- **AC-25-46 (R28, L):** **GIVEN** «guardado en riesgo», **THEN** el diálogo muestra el texto de riesgo; **WHEN** se cancela, **THEN** el juego sigue en pausa y nada se pidió a 5.
- **AC-25-47 (R28, L):** **GIVEN** un doble clic en «Salir al título» confirmado, **THEN** la petición a 5 se hace una sola vez.
- **AC-25-48 (R28, I):** **GIVEN** la escritura de `quit` falla, **THEN** se sale igualmente y el título ofrece «Continuar» con el guardado anterior (5, edge case).
- **AC-25-49 (R29, I):** **THEN** no existen «Guardar partida» ni «Salir del juego» en el menú.

**Cobertura añadida en la ronda de corrección 1**
- **AC-25-51 (R15, I):** **GIVEN** el menú del título, **WHEN** se abre «Opciones», **THEN** se muestran «Sonido y pantalla», «Accesibilidad» y «Controles» sin «Continuar», «Pistas» ni «Salir al título»; un cambio de volumen se escribe en 6 en el acto; no se emite `pause_opened` ni «pausa cerrada» y el tiempo no se detiene; `ui_atrás` emite `cerrado`.
- **AC-25-52 (R10, L):** **GIVEN** el menú cerrado tras estar en «Accesibilidad», **WHEN** se reabre, **THEN** el foco está en «Continuar».
- **AC-25-53 (R19, L):** **GIVEN** el último dispositivo activo es el mando, **WHEN** se abre «Controles», **THEN** la pestaña abierta es «Mando»; con teclado, «Teclado y ratón»; con `pestaña_inicial` del anfitrión, la indicada.
- **AC-25-54 (R20, L):** **GIVEN** una escala de texto en la que no caben las leyendas, **THEN** pasan a una segunda línea o se omiten, nunca se recortan; con `mostrar_leyendas_gestos` falso no aparecen.
- **AC-25-55 (R25, L):** **GIVEN** el mando ausente, **THEN** la pestaña «Mando» muestra las asignaciones guardadas, es editable y una captura se cancela por temporizador.
- **AC-25-56 (R26, L):** **GIVEN** la pestaña «Mando», **THEN** `mover` ofrece stick izquierdo, stick derecho y cruceta, `mirar` ofrece los sticks, y `mirar` con el ratón no tiene ranura reasignable.
- **AC-25-57 (F3, L):** **THEN** el cierre del velo dura lo mismo que la apertura (0,35 s o 0,10 s con `reducir_movimiento`).
- **AC-25-58 (R28, G, L):** **GIVEN** el diálogo de «Salir al título» abierto, **WHEN** llega «guardado en riesgo», **THEN** el texto cambia al de riesgo sin mover el foco; **WHEN** se confirma, **THEN** el estado es Saliendo, las entradas del menú se descartan y el orden es: petición a 5, retorno de 5, descarga total, «pausa cerrada».
- **AC-25-59 (R23, L):** **GIVEN** `mover` (conjunto) y una captura de una tecla ya usada por `interactuar`, **THEN** el conflicto solo ofrece «Aceptar» y nada cambia; asignar la misma entrada a las dos ranuras de una acción se rechaza con «Aceptar».
- **AC-25-60 (R24, L):** **GIVEN** `interactuar` con dos ranuras imprimibles, **THEN** el aviso no afirma que «la otra asignación sigue valiendo»; para `atrás` con la otra ranura no imprimible, sí.

**Resumen de capturas UI retenidas** (`production/qa/evidence/`): raíz con y sin línea de riesgo, Sonido y pantalla, Accesibilidad, Controles (3 pestañas), diálogo de ranura, captura, conflicto, aviso de imprimible, panel de mando, diálogo de salir, «Restablecer todos».

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D25-1 | Raíz con un solo nivel de submenú (4 pantallas) | Lista plana única con todos los ajustes | 2 pide «no más de un nivel»; la lista plana tiene ~25 filas y empeora la navegación con mando (pocos pasos hasta cada ajuste, divulgación progresiva) |
| D25-2 | `pausa` y `ui_atrás` suben un nivel; solo desde la raíz reanudan | `pausa` siempre reanuda desde cualquier nivel | `Esc` es las dos cosas (1 regla 16); subir un nivel es el modelo mental habitual y evita perder el sitio por un toque accidental. Requiere precisar 1 regla 7 |
| D25-3 | Sin «Guardar partida» | Botón de guardado manual | El slice D.3 fija guardado automático y 5 no ofrece guardado manual; un botón sugiere que no guardar tiene riesgo |
| D25-4 | «Salir al título» con confirmación (foco en «Cancelar») y texto grave solo con guardado en riesgo | Sin confirmación / confirmación siempre grave | Evita salir por accidente (un toque lleva a la descarga total); pero el texto normal tranquiliza («Se guardará tu progreso») por el pilar de tensión sin castigo |
| D25-5 | Sin «Salir del juego» en la pausa | Añadirlo (PC) | Alcance: el título ya tiene salir (27) y `quit` cubre el cierre; una fila extra con otra confirmación no aporta al slice (ver Open Questions 7) |
| D25-6 | Los ajustes se escriben en el acto, sin «Aplicar» | «Aplicar/Cancelar» | 6 regla 5 los aplica al instante; el jugador ve y oye el efecto (muestra de audio) y no hay estado intermedio que perder |
| D25-7 | «Restablecer todos» al final de Accesibilidad (con confirmación) | En la raíz, o en una pestaña propia | Evita acciones masivas en la raíz; el texto del diálogo aclara el alcance (12 claves) |
| D25-8 | La fila «Pistas» solo existe si 17 registra panel | Fila siempre visible con panel vacío / depender de 17 | El índice dice que 25 no depende de 17; una fila vacía confunde |
| D25-9 | «Mando desconectado» = panel modal con un botón «Continuar» que reanuda (también con `Esc` y clic); línea no modal si el menú ya estaba abierto | Menú normal con una línea; botón «Continuar» solo al reconectar | 1 regla 22 pide mensaje con «continuar»; mantenerlo siempre disponible evita bloquear a quien sigue con teclado y ratón; sin temporizadores (accesibilidad) |
| D25-10 | Aviso de imprimible **no bloqueante**; rechazo solo para `atrás` si queda sin tecla no imprimible; aviso extendido a `interactuar` y `pausa` | Bloquear siempre las teclas imprimibles | Autonomía: el jugador puede querer `E`; la salvaguarda real (1 regla 17) basta; la regla 20 de 1 cita ya `interactuar` |
| D25-11 | `Esc` cancela la captura; temporizador de 8 s† visible; guarda de 0,25 s† | Aceptar `Esc` como entrada; captura sin límite | 1 lo fija para `Esc`; el temporizador evita atrapar a quien usa solo mando; la guarda impide capturar la pulsación que abrió |
| D25-12 | Conjuntos `mover`/`mirar`: cuatro pasos en teclado, lista de sticks en mando | Un único campo libre | Un conjunto no cabe en una sola pulsación; pasos numerados son legibles y cancelables |
| D25-13 | Leyendas no enfocables bajo `interactuar`/`seleccionar`/`atrás` en lugar de filas de gestos | Mostrar filas deshabilitadas de `leer`, etc. | El index prohíbe esas filas; las leyendas informan sin crear controles que no existen |
| D25-14 | `modo_ventana` en «Sonido y pantalla» | En «Accesibilidad» | No es accesibilidad; aparece junto a lo que el jugador espera |
| D25-15 | Velo de 350 ms (100 ms con `reducir_movimiento`), solo visual | Fundido que bloquea el menú | Art bible; la entrada y el tiempo detenido no esperan al fundido |
| D25-16 | 25 llama directamente a 6 para vaciar pendientes y emite `pause_opened` en el bus | Que 6 se suscriba al bus | 6 declara que no depende del bus (3); un contrato directo mantiene eso |
| D25-17 | 25 muestra el estado de guardado en riesgo con una línea de texto; sin indicador de «guardado correcto» | Icono de disco permanente | Art bible: no hay indicador de autoguardado; solo informa cuando importa |
| D25-18 | Restablecer por acción sin confirmar; por dispositivo y «todos» con confirmación | Confirmar siempre / nunca | Cambios reversibles sin fricción; los masivos con una confirmación |
| D25-19 | 25 emite `pause_opened` **y** «pausa cerrada» ‡ (sin datos, tras restaurar contexto y tiempo; también al salir al título); consumidores 5 y 23 | Que 23 escuche «contexto de entrada cambiado» de Entrada; solo `pause_opened` | 23 (regla 41, AC-23-18) ya consume las dos señales de 25; una señal propia desacopla a 23 de los nombres de contexto de 1 y es simétrica |
| D25-20 | Las tres pantallas de ajustes son un componente reutilizable sin dependencia de la raíz (regla 15), con `mostrar(pantalla, pestaña_inicial?)` y `cerrado` | Que 27 duplique las pantallas; que 27 abra la pausa en el título | 27 (regla 13, D27-5) pide una sola implementación; abrir la pausa en el título contradiría 1 regla 7 |
| D25-21 | Intercambio solo entre acciones simples; conflictos con conjuntos y duplicado en la misma acción se rechazan con «Aceptar» | Partir el conjunto / fusionar duplicados | Partir un conjunto deja `mover` o `mirar` incoherentes; fusionar oculta un error del jugador |
| D25-22 | Contraste de cuerpo ≥ 7:1 enunciado en la regla 13; cifra pendiente de confirmar con art-director | Dejarlo solo en el AC | Un AC debe tener regla de origen |
| D25-23 | Aviso de imprimible veraz: la cláusula «la otra asignación sigue valiendo» solo para `atrás` con la otra ranura no imprimible | Texto fijo para las tres acciones | Solo `atrás` tiene garantía de 1 (regla 17); para `interactuar` y `pausa` sería falso |

## Open Questions

| # | Pregunta | Decisión por defecto | Propietario |
|---|---|---|---|
| 1 | **Quién pide la descarga total tras `quit`** (4 regla 15 dice que la pide 27 desde el título; aquí la pide 25 al salir): ¿5 la encadena tras escribir o la pide 25? | 25 pide a 5 «salir al título»; cuando 5 devuelve el control, 25 pide la descarga total a 4. 27 solo muestra el título | 5, 4, 27 |
| 2 | **Quién detiene el árbol de escena** (Entrada regla 7 dice que `pausa` detiene el tiempo; 25 abre el menú). **No verificado** para Godot 4.7 (`docs/engine-reference/godot/` no cubre pausa del árbol, `process_mode`, `Tween` ni `AudioStreamPlayer` en pausa): hay que confirmar que la interfaz, los temporizadores de captura y la muestra de audio funcionan en tiempo real con el árbol pausado y registrarlo en esa carpeta | 25 marca «pausa activa»; 23 usa `pause_opened` / «pausa cerrada» (D25-19) y 28 el reloj de juego detenido | ADR / 1 / 23 |
| 3 | **`pausa` con teclas imprimibles:** 1 garantiza una asignación no imprimible solo para `atrás`; con el buscador enfocado, `pausa` en una tecla imprimible no se oye | Aviso (sin rechazo) en 25; proponer a 1 la misma garantía para `pausa` | 1 |
| 4 | **Nombres de la API de Entrada:** captura, asignación, intercambio, quitar, restablecer acción/dispositivo, `es_imprimible`, lista de ajustes de manejo, captura de conjuntos | 25 usa nombres descriptivos ‡ hasta que 1 los fije | 1 |
| 5 | **Escala de texto UI** (6 OQ 15, art bible 7.6: 100/125/150 %): no es ajuste aún | Los paneles se diseñan para reflow; la fila se añade a «Accesibilidad» si se aprueba | usuario, 30 |
| 6 | **`Esc` no se puede reasignar en captura** (cancela): ¿hace falta una vía? | Solo «Restablecer» la devuelve | 1, accessibility-specialist |
| 7 | **«Salir del juego» en la pausa** (alcance: PC) | No; se sale desde el título | usuario |
| 8 | **Textos `UI_PAUSA_*` definitivos** | Provisionales con marcador de pendiente | writer |
| 9 | **Muestra de referencia de volumen** (6 OQ 8) | 25 la pide a 23 al cambiar de paso o soltar | 23 |
| 10 | **Estado de «guardado en riesgo»** como consulta de 5 | 25 acumula los avisos desde el inicio de partida | 5 |
| 11 | **Temporizador de captura de 8 s†** (W-3): corto para entradas alternativas o manos torpes (pilares 3 y 4) | 8 s†, cancelar no pierde nada; propuesta: 15 s o reinicio del contador con cualquier pulsación no capturable | accessibility-specialist |
| 12 | **Quién implementa `Alt+Intro`** (`modo_ventana`): no es atajo nativo de Godot (no verificado en 4.7) | Ajustes (6) aplica `modo_ventana`; Entrada captura el atajo | 1, 6 |
| 13 | **Alcance de la reasignación** (conjuntos de cuatro pasos, listas de sticks, intercambio, restablecer por acción/dispositivo): amplio para un slice de 25 a 30 min. Mínimo viable posible: «restablecer» + esquema predefinido. **Decide el usuario** | Se mantiene el flujo completo (exigido por 1 regla 15) | usuario |
| 14 | **Cifra de contraste ≥ 7:1** y su sección del art bible (W-7) | 7:1 como propuesta | art-director |

Ninguna cambia pilares, tono ni alcance del slice salvo la 7 y la 13 (**decide el usuario**), que se resuelven por defecto sin ampliar el alcance.

## Cambios requeridos en otros GDDs

| GDD | Cambio |
|---|---|
| **1 Entrada y controles** | (a) Regla 7: precisar que, con el menú abierto, `atrás` y `pausa` **suben un nivel** y solo desde la raíz lo cierran (D25-2); (b) pulsación que cierra el menú no llega al mundo hasta soltarse (regla 6 de 25); (c) fijar la API de reasignación y los métodos citados (OQ 4), `es_imprimible` y la lista de ajustes de manejo; (d) cerrar la fila «Pendiente» de Dependencies de 25 (panel de mando) con este GDD; (e) evaluar la garantía de entrada no imprimible para `pausa` (OQ 3) |
| **3 Estado y bus** | Mantener `pause_opened` en la tabla de avisos de 25 (ya existe, sin datos); **dar de alta «pausa cerrada» ‡ (sin datos; emisor 25; consumidor 23)** y listar a 23 como consumidor de ambos; listar a 25 como suscriptor de «guardado en riesgo» / «restablecido» (de 5) |
| **5 Guardado y carga** | Confirmar `salir al título` (causa `quit`) desde 25 y la consulta opcional de «guardado en riesgo»; confirmar que 25 espera el retorno antes de la descarga total (OQ 1) |
| **6 Ajustes** | Punto de entrada «vaciar pendientes» que llama 25 (regla 13/F3); cerrar OQ 14 y AC-18b/AC-18 con 25; indicar que «Restablecer todos» vive en «Accesibilidad» de 25 |
| **18 Base de contenido** | Dar de alta las claves `UI_PAUSA_*` (ver registro) con marcador de pendiente, sin cambiar los recuentos (D18-16, D18-29) |
| **2 Jugador** | Cerrar AC-19 con 25; confirmar que `campo_vision` y `balanceo_camara` van en «Accesibilidad» junto a `reducir_sobresaltos` |
| **4 Escena de planta** | Regla 15: hoy dice que solo 21 y 27 piden la descarga total; añadir «y 25 al salir al título desde la pausa» (o, alternativa de OQ 1, que 5 la encadene y 25 no llame a 4) |
| **17 Sistema de pistas** | Existe: verificado `HintPanel` (reglas 1 y fila 25 de Dependencies); registrarlo en la fila «Pistas» (regla 14); no escribir en ajustes; sin contadores. Índice: añadir `25` a las dependencias de la fila 17 como ‡ de 17 sobre 25 |
| **23 Audio** | Ya consume `pause_opened` y «pausa cerrada» (regla 41): sustituir las ‡ por el contrato de 25 (regla 3); muestra de referencia de los deslizadores; seguir sonando el bus de la interfaz en pausa |
| **27 Pantalla de título** | Regla 13, D27-5, AC-14: referenciar el componente «Opciones» de 25 (regla 15: `mostrar(pantalla, pestaña_inicial?)`, señal `cerrado`) como dependencia blanda de 27 sobre 25; tabla l. 128 y regla de descarga total: «solo 21/27» pasa a «21, 27 y 25 (salir al título)» o se sigue la alternativa de OQ 1; recibir al jugador tras «Salir al título» |
| **30 Accesibilidad** | Compartir las claves de 6 sin duplicar las pantallas de 25 (si 30 repite controles, mismas reglas 19 a 26) |
| **Índice de sistemas** | Fila 25: dependencias `1, 6, 18` (blandas `3`, `4`, `5`); estado «Revisado (ronda de corrección 1)»; fila 17: añadir `25`; fila 27: blanda `25` (componente Opciones) |

## Entradas para el registro

Valores nuevos con † (propuestas). `pause_opened` ya está en el vocabulario de causas de guardado (registro, línea 949); 25 lo emite.

| Clave | Valor | Fuente |
|---|---|---|
| `pausa_t_velo_s` | 0,35 s (art bible) | F3, regla 7 |
| `pausa_t_velo_reducido_s` | 0,10 s (art bible 7.4) | F3, regla 7 |
| `pausa_guarda_apertura_s` | 0,15 s† | F4, regla 6 |
| `pausa_repeticion_inicial_s` | 0,4 s† | F1, regla 12 |
| `pausa_repeticion_s` | 0,12 s† | F1, regla 12 |
| `pausa_guarda_captura_s` | 0,25 s† | F2, regla 22 |
| `pausa_t_captura_s` | 8 s† | F2, regla 22 |
| `pausa_mostrar_leyendas_gestos` | verdadero | Tuning Knobs, regla 20 |
| Aviso «pausa cerrada» ‡ | sin datos; emisor 25; consumidor 23 | Regla 3, D25-19 |
| Componente «Opciones» ‡ | `mostrar(pantalla, pestaña_inicial?)`, señal `cerrado` | Regla 15 |
| Claves `UI_PAUSA_AJ_<CLAVE>` | una por ajuste de la regla 16: `VOL_VOCES`, `VOL_EFECTOS`, `VOL_MUSICA`, `SUBTITULOS_ACTIVOS`, `MODO_VENTANA`, `REDUCIR_SOBRESALTOS`, `REDUCIR_MOVIMIENTO`, `BALANCEO_CAMARA`, `CAMPO_VISION`, `MULTIPLICADOR_PIE`, `PIE_PERSISTENTE`, `ASISTENCIA_ENCAJE`, `ASISTENCIA_ROTACION` | Regla 16 |
| Estados del menú | cerrado, abierto·raíz, abierto·pantalla, abierto·diálogo, capturando, panel de mando, saliendo | Estados |
| Claves de interfaz `UI_PAUSA_*` (provisionales, tipo Interfaz, pedidor 25) | Raíz y navegación: `UI_PAUSA_TITULO` «Pausa», `UI_PAUSA_CONTINUAR`, `UI_PAUSA_PISTAS`, `UI_PAUSA_SONIDO` «Sonido y pantalla», `UI_PAUSA_ACCESIBILIDAD`, `UI_PAUSA_CONTROLES`, `UI_PAUSA_SALIR`, `UI_PAUSA_VOLVER`, `UI_PAUSA_RIESGO`. Salir: `UI_PAUSA_SALIR_TEXTO`, `UI_PAUSA_SALIR_RIESGO_TEXTO`, `UI_PAUSA_CANCELAR`, `UI_PAUSA_ACEPTAR`. Mando: `UI_PAUSA_MANDO_DESC`, `UI_PAUSA_MANDO_AYUDA`, `UI_PAUSA_MANDO_OK`. Ajustes: `UI_PAUSA_AJ_<CLAVE>` (13 rótulos), valores (`UI_PAUSA_VAL_SI`, `_NO`, `_SILENCIO`, balanceo ×3, ventana ×2), `UI_PAUSA_RESTABLECER`, `UI_PAUSA_RESTABLECER_TODOS`, `UI_PAUSA_RESTABLECER_TODOS_TEXTO`. Controles: pestañas ×3, acciones ×6 (`UI_PAUSA_ACC_*`), `UI_PAUSA_SIN_ASIGNAR`, `UI_PAUSA_CAMBIAR`, `UI_PAUSA_QUITAR`, `UI_PAUSA_CAPTURA`, `UI_PAUSA_CAPTURA_CANCELA`, `UI_PAUSA_CONFLICTO`, `UI_PAUSA_INTERCAMBIAR`, `UI_PAUSA_MINIMO`, `UI_PAUSA_ATRAS_IMPRIMIBLE`, `UI_PAUSA_AVISO_IMPRIMIBLE`, `UI_PAUSA_LEY_*` ×3, `UI_PAUSA_RESTABLECER_DISP` | Reglas 13 a 28 |

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Primer borrador (lote autónomo), por el UX Designer: 29 reglas (A a G), 4 fórmulas (F1 a F4), 33 edge cases, dependencias bidireccionales (25 → 1, 6, 18; blandas 3, 4, 5), 9 knobs, 49 AC, 18 decisiones (D25-1 a D25-18), 10 preguntas abiertas. Sin cambios en ningún otro archivo. Estado: Borrador (lote autónomo) — pendiente de review. |
| 2026-11-09 | Ronda de corrección 1 (informe `reviews/menu-de-pausa-review.md`, NEEDS REVISION, 4 B + 10 W). B-1: «pausa cerrada» ‡ definida y consumidores 5 y 23 (regla 3, D25-19, AC-25-50). B-2: F2 reescrita con `t_soltar`/`t_escucha`, `t_captura_s` desde la apertura. B-3: regla 15 = componente «Opciones» para 27 (D25-20, AC-25-51). B-4: referencias internas corregidas (27, 22, 11) y regla 15 rellenada. W-1, W-2 (D25-23), W-4, W-5 (D25-21), W-6, W-7 (D25-22), W-8 (AC-25-52 a 60), W-9, W-10 aplicados; W-3 como OQ 11. Nuevas OQ 11 a 14 (la 13, **decide el usuario**). Ahora 29 reglas, 4 fórmulas, 36 edge cases, 60 AC, 23 decisiones, 14 OQ. Estado: Revisado (ronda de corrección 1) — pendiente de re-review. Sin cambios en otros archivos. |
