# Pantalla de título, advertencias y cierre (sistema 27)

> **Status**: Borrador (lote autónomo)
> **Author**: UX Designer (lote autónomo)
> **Last Updated**: 2026-11-09
> **Implements Pillar**: Tensión sin castigo (el título nunca castiga: sin confirmaciones innecesarias, sin pérdida de partida por error) · Autonomía como progresión (el jugador decide cuándo continuar, ajustar o salir; las advertencias informan, no bloquean) · El espacio expresa la emoción (el título es la primera habitación del juego: quieta, en penumbra, sin música que dirija)

## Summary

La pantalla de título es lo primero y lo último que ve el jugador. Muestra, por este orden: las **advertencias de contenido** (slice §17) la primera vez que se arranca el juego, el **menú principal** (Continuar, Nueva partida, Opciones, Salir del juego), el **mensaje de fallo de carga** (escena de planta, regla 14) y la **tarjeta de cierre** («Continuará» y créditos) al terminar el slice. No tiene lógica de partida: consulta el resultado de la **última** inspección de Guardado (5), llama a `continuar()` y `nueva_partida()`, reutiliza las pantallas de ajustes del menú de pausa (25) leyendo y escribiendo ajustes (6), lee textos de la base de contenido (18) y no pide jamás la carga de `planta`.

> **Quick reference** — Layer: `Presentation` (UI) · Priority: `Vertical Slice` · Key deps: `1 Entrada`, `3 Estado y bus`, `5 Guardado`, `6 Ajustes`, `18 Contenido` · Blanda: `4 Escena de planta`, `21 Director de escenas`, `23 Audio`, `25 Pausa` · Escribe hechos: nada · Escribe ajustes: sí (los de Opciones y `advertencias_vistas`†)

## Overview

El slice (§17) exige mostrar las advertencias de contenido «en la pantalla de inicio»; Guardado (5, UI Requirements) exige que el título ofrezca «Continuar» y «Nueva partida» según el resultado de inspección; Escena de planta (4, regla 14) deja a este GDD la presentación del mensaje de fallo de carga; Director de escenas (21, regla 22) pinta aquí la tarjeta final. Este documento cierra esos contratos.

**Flujo general.**

```
Arranque -> [Advertencias (solo si no vistas)] -> Menú principal
Menú principal -> Continuar / Nueva partida -> (5: "Cargando partida") -> En partida
En partida -> Salir al título (25) -> Menú principal
En partida -> "partida terminada" (4) -> Tarjeta de cierre (21) -> Créditos -> Menú principal (solo "Nueva partida")
Fallo de carga (4) -> Mensaje de error -> Aceptar -> Menú principal
```

**Estados del menú principal según la última inspección de 5.**

| Resultado (5) | Filas | Aviso | Confirmación en «Nueva partida» |
|---|---|---|---|
| `ninguna` | Nueva partida · Opciones · Salir | — | No |
| `valida`, `terminada` falso | **Continuar** (foco) · Nueva partida · Opciones · Salir | — | **Sí** |
| `valida`, `terminada` verdadero | **Nueva partida** (foco) · Opciones · Salir | — | **No** (decidido por el usuario) |
| `irrecuperable` | Nueva partida · Opciones · Salir | «La partida guardada está dañada» (una vez por arranque) | No |
| `version_futura` | Nueva partida · Opciones · Salir | «La partida es de una versión más nueva del juego» (una vez por arranque) | **Sí** |
| `valida` con `con_futura` | Como `valida` | «Hay una copia de una versión más nueva; se carga la última compatible» | Según `terminada` |

## Player Fantasy

El jugador llega a un lugar tranquilo antes de empezar su turno de noche. Nada le apremia: la pantalla le dice con honestidad qué va a encontrar (estrés, aislamiento, decepción) y le deja elegir. Al terminar, el cierre es un respiro, no un «has ganado»: una tarjeta quieta, «Continuará», y la puerta abierta para volver a empezar. Si algo falla, se lo dice con calma y sin culparle.

## Detailed Rules

### A. Arranque y advertencias

1. **Secuencia de arranque.** Al arrancar el juego, tras la inspección de 5 (que decide el resultado), el sistema muestra las advertencias si el ajuste `advertencias_vistas`† (6) es falso; si es verdadero, va directo al menú principal. Si 6 no responde o el ajuste falta, se tratan como no vistas.
2. **Contenido de las advertencias (slice §17).** Una lista de cinco entradas, cada una una entrada `UI_…` de 18: estrés laboral · aislamiento · decepción afectiva · llanto contenido · dinámicas de control y de desigualdad en una relación de trabajo. Encabezado neutro («Antes de empezar») y una línea de cierre: «El juego no tiene violencia gráfica ni referencias a autolesiones.» La línea de cierre refleja las reglas de contenido de §17 y tiene su propia entrada.
3. **No bloqueante por tiempo.** No hay cuenta atrás ni salto automático: la pantalla espera a que el jugador pulse «Entendido» (`ui_accept`). Un segundo botón «Salir del juego» está siempre presente (quien no quiera jugar no debe tener que pasar por ello).
4. **Una sola vez.** Al pulsar «Entendido» se escribe `advertencias_vistas`† = verdadero. Las advertencias se pueden releer siempre desde Opciones > «Avisos de contenido» (regla 17).
5. **Sin efectos.** Sin flashes ni sacudidas; la entrada es un fundido (F1) que respeta `reducir_movimiento` y `reducir_sobresaltos` (6).
6. **Clasificación pendiente (D-06).** No se muestra ninguna etiqueta de clasificación hasta que D-06 esté cerrada (Open Questions 3).

### B. Menú principal

7. **Estructura.** Lista vertical de filas (título del juego encima, rótulo de versión de compilación abajo a un lado). Las filas visibles dependen del resultado (tabla de Overview). Las filas no ofrecidas **no existen** (no se muestran desactivadas): decide el diseño UX lo que 5 deja abierto (UI Requirements de 5) por la regla de que no hay opción muerta que explicar.
8. **Foco inicial.** En la fila «Continuar» si existe; si no, en «Nueva partida». El foco se muestra siempre (con teclado, mando y ratón), con borde y marca y no solo color.
9. **Consulta del resultado.** El sistema lee el resultado de la **última** inspección de 5 cada vez que entra en el menú principal (también al volver de una partida): `terminada`, `con_futura` y el resultado base. No relee disco ni caduca: si 5 actualiza el resultado al salir de la partida (contrato de 5), el menú lo refleja.
10. **Continuar.** Llama a `continuar()` de 5 y pasa a «Cargando» (regla 12). Sin confirmación.
11. **Nueva partida.** Con la confirmación que marca la tabla: diálogo modal «Se sustituirá tu partida actual cuando se guarde la nueva» con «Empezar de nuevo» y «Cancelar» (foco en **Cancelar**). Sin confirmación en los demás casos. Llama a `nueva_partida()` de 5.
12. **Carga: el título no pide `planta`.** Tras `continuar()` o `nueva_partida()`, 5 entra en «Cargando partida» y es 5 quien pide la carga de `planta` a 4. El título se limita a (a) bloquear las entradas del menú, (b) mostrar la cortina negra que gestiona 4 y (c) quedar inerte hasta recibir «carga de escena terminada» o «carga de escena fallida». No muestra barra de progreso (la carga cabe en `D_carga`, GDD 4).
13. **Opciones.** Abre las mismas pantallas de nivel 2 del menú de pausa (25): «Sonido y pantalla», «Accesibilidad» y «Controles», **reutilizadas tal cual** (mismo componente, mismos ajustes, mismas salvaguardas de reasignación). Se omiten «Continuar», «Pistas» y «Salir al título». Se añade una fila «Avisos de contenido» (regla 4). Escribir un ajuste desde aquí es igual que desde la pausa (6, regla 5).
14. **Salir del juego.** Cierra la aplicación sin confirmación (no hay nada sin guardar en el título) llamando a `quit`. Solo en PC; en plataformas donde no proceda, la fila no existe.
15. **Navegación.** Teclado (`ui_up/down/accept/cancel`), mando (D-pad, A, B) y ratón; el ratón no cambia el foco al reaparecer el cursor hasta moverse. `ui_cancel` en el menú principal no hace nada (no salir por accidente). Todas las acciones son alcanzables con solo teclado y con solo mando.
16. **Sin entrada durante transiciones.** Mientras dura un fundido o una carga, las entradas se ignoran (no se encolan).
17. **Avisos de contenido.** Desde Opciones, abre las mismas cinco entradas de la regla 2 en una pantalla de lectura, con «Volver».

### C. Avisos de partida

18. **Aviso de partida dañada o de versión más nueva.** Una línea de texto no bloqueante bajo el menú (rol «estado», nunca modal), una vez por arranque (variable de sesión, no se guarda). Con `irrecuperable` dice la causa «dañada»; con `version_futura`, «versión más nueva» y, solo en este caso, «Nueva partida» pide confirmación. Con `con_futura` y partida cargable, la línea informa de que hay datos de una versión más nueva y que «Continuar» usa la última copia compatible.
19. **Distinguible sin color.** Cada aviso lleva un icono y una palabra clave; no depende del color. Se anuncia por la capa de accesibilidad de pantalla (si el motor la ofrece) y con subtítulo si lleva audio (no lo lleva).

### D. Fallo de carga

20. **Mensaje de error de carga.** Al recibir «carga de escena fallida» (4, regla 14), con la cortina en negro, el título se presenta **sobre la cortina** (cierra la OQ 8 de 4): un panel centrado con el texto de emergencia de 18 (regla 21), sin rojo ni signos de alarma, una sola acción «Volver al título» y el foco en ella. El texto es: «No se ha podido cargar la planta. Vuelve a intentarlo desde el título.» (ajuste pendiente de 18).
21. **Aceptar.** «Volver al título» pide a 4 la descarga total (queda en «Sin escena»), 4 repone `menú` en la pila de entrada y el sistema pasa al menú principal con el resultado de 5 intacto («el resultado de inspección no cambia» tras fallo de carga, 5). Si el fallo ocurrió en «Continuar», sigue disponible para reintentar.
22. **Texto fijo si falla 18.** Si el contenido no se puede cargar, el panel usa una cadena fija en el propio sistema (la misma de la regla 20), en español.

### E. Cierre del slice

23. **Gatillo.** El cierre empieza con «partida terminada» (emitido por 4, regla 16). 27 no decide cuándo termina el slice: reacciona. Si 27 no está activo (en partida), 21 pinta la tarjeta final y, al terminar, **pide a 4** la descarga total y la vuelta al título (21, regla 22).
24. **Tarjeta de cierre.** Fondo negro, el rótulo «Continuará» (18) y el título del juego, durante `t_tarjeta_s` de 21 (3,0 s†) más el fundido. Sin música ni voz nuevas (23 decide el silencio). No exige pulsar nada para empezar y no se puede saltar en los primeros `t_tarjeta_min_s`† para no cortar por un doble toque.
25. **Créditos.** Tras la tarjeta, una pantalla de créditos estática de una o dos páginas (equipo, herramientas, declaración de uso de IA según slice §18), navegable con `ui_accept` y `ui_cancel`; sin desplazamiento automático (accesibilidad, sin movimiento). «Volver al título» termina el cierre.
26. **Tras el cierre.** El menú principal se muestra con el resultado `terminada`: solo «Nueva partida» (sin «Continuar», sin confirmación). El texto de la fila no cambia.
27. **Cierre abandonado.** Si el jugador cierra la aplicación durante la tarjeta o los créditos, la partida ya está sellada; al volver, el título ofrece solo «Nueva partida» (21, edge case de cierre).

### F. Accesibilidad

28. **Texto y escala.** Todo el texto es de los tamaños mínimos del proyecto y escala con el ajuste de tamaño de interfaz de 6; todas las pantallas caben a 1280x720 y a 3840x2160 sin recorte.
29. **Sin color como único canal.** Foco, avisos y botones se distinguen por forma y texto.
30. **Mando.** Sin ratón se puede hacer todo. Al desconectarse el mando en el título, no hay panel de pausa; el menú pasa a teclado y ratón sin perder el foco.

## Formulas

### F1 · Fundido de entrada y salida del título

`t_fundido = t_fundido_base_s × k_mov`, con `t_fundido_base_s` = 0,8 s†, `k_mov` = 0 si `reducir_movimiento` o `reducir_sobresaltos` (corte directo con atenuación de 0,15 s†) y 1 en otro caso. Rango válido de `t_fundido_base_s`: 0,3 a 1,5 s. Ejemplo: base 0,8 con movimiento normal: 0,8 s; con `reducir_movimiento`: corte con atenuación de 0,15 s.

### F2 · Mínimo de la tarjeta de cierre

`t_saltable = t_tarjeta_s + t_fundido` y la tarjeta no admite salto antes de `t_tarjeta_min_s` (1,5 s†). Con `t_tarjeta_s` = 3,0 s: el jugador ve la tarjeta entre 3,0 s y 3,8 s y puede pasar a los créditos a partir de 1,5 s. Rango de `t_tarjeta_min_s`: 0 a `t_tarjeta_s`.

## Edge Cases

- **Inspección aún sin resultado al llegar al título** (5 lenta): el menú no se muestra; la cortina permanece en negro con el título del juego. Si pasan `t_espera_inspeccion_s`† sin resultado, se asume `ninguna` y se registra.
- **Resultado cambia mientras el menú está abierto** (por ejemplo, 5 actualiza): se refresca la lista conservando el foco en la misma fila si aún existe; si no, en la primera.
- **`terminada` y `con_futura` a la vez:** `terminada` manda; solo «Nueva partida», sin confirmación; el aviso de `con_futura` se muestra igual.
- **Doble pulsación de «Continuar»:** la segunda se ignora (regla 16).
- **Fallo de carga tras «Nueva partida»:** el título vuelve con el resultado previo; la partida anterior no se ha tocado (5 no sobrescribe hasta el primer guardado).
- **Fallo de carga repetido:** el mensaje se muestra cada vez; no hay límite de reintentos ni bloqueo.
- **Ajustes ausentes o dañados (6):** se usan los valores por defecto; no se muestra un error al jugador.
- **Salida al título desde la pausa mientras se escribe el guardado:** 25 espera a 5 (regla de 25); 27 solo muestra el menú cuando 5 está en «Sin partida».
- **Cambio de dispositivo en el título:** el foco se mantiene; los glifos de las filas se actualizan.
- **Cambio de idioma:** no existe en el slice (solo español).
- **Cierre de ventana en las advertencias:** `advertencias_vistas`† no se escribe; se muestran otra vez al reabrir.
- **Pérdida de foco de la ventana en el título:** no hay pausa; el menú sigue igual.
- **Resultado `valida` sin `terminada` pero con hecho `slice_completed` presente:** manda `terminada` (5 lo calcula); 27 no lee hechos propios.

## Dependencies

| Sistema | Tipo | Qué usa 27 | Qué da 27 |
|---|---|---|---|
| 1 Entrada y controles | Dura | `ui_*`, cursor, contexto `menú`, reasignación (vía Opciones de 25) | Peticiones de contexto `menú` |
| 3 Estado y bus | Dura | Suscripción a «partida terminada» (de 4), «carga de escena fallida/terminada» | — (no escribe hechos) |
| 5 Guardado y carga | Dura | Resultado de la **última** inspección (`terminada`, `con_futura`), `continuar()`, `nueva_partida()`, estado «Sin partida» | Peticiones de continuar y nueva partida |
| 6 Ajustes persistentes | Dura | Lectura y escritura de ajustes, `advertencias_vistas`† | Escrituras desde Opciones |
| 18 Base de contenido | Dura | Título, advertencias (§17), «Continuará», textos de avisos y del error | — |
| 4 Escena de planta | Blanda | «Partida terminada», «carga de escena fallida» | Petición de descarga total (solo 21/27) |
| 21 Director de escenas | Blanda | Tarjeta final pedida | Fin del cierre |
| 23 Audio | Blanda | Audio del título (OQ 1) | — |
| 25 Menú de pausa | Blanda | Pantallas de Opciones reutilizadas | Recibe al jugador tras «Salir al título» |
| 30 Accesibilidad | Blanda | Pantalla de accesibilidad reutilizada | — |

## Tuning Knobs

| Parámetro | Valor | Rango seguro | Afecta a |
|---|---|---|---|
| `t_fundido_base_s` | 0,8 s† | 0,3 a 1,5 | Suavidad de entrada y salida |
| `t_tarjeta_min_s` | 1,5 s† | 0 a `t_tarjeta_s` | Evitar saltar por doble toque |
| `t_espera_inspeccion_s` | 3,0 s† | 1 a 10 | Tolerancia ante 5 lenta |
| `t_aviso_s` | sin límite | — | El aviso dura toda la visita al menú |
| `advertencias_vistas` | falso | falso/verdadero | Mostrar advertencias al arrancar |
| `creditos_paginas` | 2† | 1 a 3 | Longitud del cierre |

(† = valor propuesto; `t_tarjeta_s` es de 21.)

## Acceptance Criteria

- **AC-01** Con `advertencias_vistas` falso, al arrancar aparece la lista de cinco advertencias del slice §17 antes del menú; con verdadero, no aparece.
- **AC-02** Las advertencias no avanzan solas: tras 60 s sin pulsar, siguen visibles.
- **AC-03** «Entendido» escribe `advertencias_vistas` verdadero y solo entonces; cerrar la ventana antes no lo escribe.
- **AC-04** Con resultado `ninguna`, el menú muestra Nueva partida, Opciones y Salir, y no Continuar; «Nueva partida» no pide confirmación.
- **AC-05** Con `valida` sin `terminada`, el foco inicial está en «Continuar» y «Nueva partida» pide confirmación con foco en «Cancelar».
- **AC-06** Con `terminada`, el menú ofrece solo «Nueva partida» (sin «Continuar») y esta no pide confirmación.
- **AC-07** Con `irrecuperable`, se muestra una sola vez por arranque el aviso «dañada»; al volver de una partida al título, no se repite.
- **AC-08** Con `version_futura`, se muestra el aviso de versión más nueva, sin «Continuar», y «Nueva partida» pide confirmación.
- **AC-09** Con `con_futura` y partida cargable, se muestra el aviso y «Continuar» está disponible.
- **AC-10** Tras salir al título desde una partida terminada o no, el menú refleja el resultado **actual** de 5, no el del arranque.
- **AC-11** Al pulsar «Continuar» o «Nueva partida», 27 no emite ninguna petición de carga de `planta` (verificable: solo 5 la emite).
- **AC-12** Con «carga de escena fallida», el panel de error aparece sobre la cortina en negro con una sola acción; al aceptarla se llega al menú con el mismo resultado de inspección.
- **AC-13** Con 18 no disponible, el panel de error usa el texto fijo y no falla.
- **AC-14** «Opciones» abre las pantallas de 25 sin «Continuar», «Pistas» ni «Salir al título», y un cambio de volumen persiste al empezar la partida.
- **AC-15** «Salir del juego» cierra la aplicación sin diálogo.
- **AC-16** Con «partida terminada», aparece la tarjeta «Continuará», luego los créditos y por último el menú con solo «Nueva partida».
- **AC-17** La tarjeta no se puede saltar antes de `t_tarjeta_min_s`.
- **AC-18** Con `reducir_movimiento`, los fundidos son cortes con atenuación breve y los créditos no se desplazan.
- **AC-19** Todo el menú, las advertencias, los avisos y los créditos se completan solo con teclado y solo con mando.
- **AC-20** El foco es visible sin depender del color; el texto cabe a 1280x720 y 3840x2160 (captura retenida en `production/qa/evidence/`).
- **AC-21** Durante una carga, pulsar cualquier entrada no produce ninguna acción (no se encola).
- **AC-22** Nunca aparece «Continuar» desactivado: o existe o no se muestra.

## Decisiones tomadas

| Id | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| D27-1 | Con `terminada`, solo «Nueva partida» sin confirmación | Ofrecer también «Continuar» | Decidido por el usuario (OQ 10 de 5); la partida está sellada |
| D27-2 | Las filas no ofrecidas no se muestran | Mostrarlas desactivadas | Una fila muerta obliga a explicar por qué; menos carga cognitiva |
| D27-3 | Advertencias solo la primera vez, releíbles desde Opciones | Mostrarlas siempre | Evita fricción en cada arranque sin ocultar el aviso; accesible siempre |
| D27-4 | Las advertencias requieren pulsar «Entendido» (sin temporizador) | Pantalla con cuenta atrás | Autonomía y accesibilidad: nadie debe perder tiempo de lectura |
| D27-5 | Reutilizar las pantallas de Opciones de 25 | Pantalla de opciones propia | Una sola implementación y coherencia entre título y pausa |
| D27-6 | El aviso de partida dañada o futura es una línea, no un modal | Diálogo modal | Lo exige 5 (UI Requirements): nunca bloquea |
| D27-7 | El error de carga se presenta sobre la cortina negra con una sola acción | Volver automáticamente al título | El jugador debe saber qué pasó y decidir cuándo |
| D27-8 | Créditos estáticos, sin scroll | Créditos con scroll automático | `reducir_movimiento` y lectura a ritmo propio |
| D27-9 | «Salir del juego» sin confirmación | Con confirmación | No hay nada sin guardar en el título |
| D27-10 | `ui_cancel` no hace nada en el menú principal | Salir con cancelar | Evita salir por accidente con el mando |

## Open Questions

| # | Pregunta | Propietario | Valor por defecto |
|---|---|---|---|
| 1 | ¿Suena el drone en el título? (OQ 3 de 23) | Usuario / 23 | **Silencio en el título y en los créditos**; el drone arranca en «escena lista» |
| 2 | ¿Se oculta por completo el título del juego en la tarjeta de cierre? | Usuario / art-director | Se muestra junto a «Continuará» |
| 3 | Clasificación por edades pendiente (D-06): ¿se muestra etiqueta en las advertencias? | Usuario | No se muestra |
| 4 | ¿Incluye los créditos la declaración de IA (slice §18) o solo la ficha de la tienda? | Usuario | Se incluye un resumen de una línea |
| 5 | ¿Debe «Nueva partida» tras `terminada` ofrecer un rótulo diferente, como «Volver a empezar»? | Usuario / 18 | Mismo rótulo «Nueva partida» |
| 6 | ¿Hay botón de «Salir del juego» en consolas o Steam Deck? | Usuario | Sí, en toda plataforma de escritorio |

## Cambios requeridos en otros GDDs

| GDD | Cambio |
|---|---|
| 6 Ajustes persistentes | Añadir `advertencias_vistas`† (booleano, falso por defecto) escrito por 27 |
| 18 Base de contenido | Añadir entradas `UI_` para el título, el encabezado y las cinco advertencias, la línea de reglas de contenido, «Entendido», los avisos de partida dañada y de versión más nueva, «Avisos de contenido», los créditos y el ajuste del texto de error de carga (OQ 8 de 4) |
| 5 Guardado y carga | Confirmar que el resultado de la última inspección se actualiza al salir de la partida y que `con_futura` y `terminada` se exponen como lectura |
| 4 Escena de planta | Cerrar la OQ 8 (presentación del error sobre la cortina: aquí); aceptar que el título pide la descarga total |
| 21 Director de escenas | Confirmar que, tras la tarjeta, la vuelta al título pasa por 27 (créditos) y no directamente |
| 23 Director de audio | Cerrar la OQ 3 (silencio en el título por defecto) |
| 25 Menú de pausa | Exponer las pantallas de nivel 2 como componente reutilizable por 27 |

## Entradas para el registro

| Entrada | Tipo | Valor |
|---|---|---|
| `advertencias_vistas`† | ajuste (6) | booleano, falso |
| `t_fundido_base_s`† | constante | 0,8 s |
| `t_tarjeta_min_s`† | constante | 1,5 s |
| `t_espera_inspeccion_s`† | constante | 3,0 s |
| `creditos_paginas`† | constante | 2 |
| `UI_TITLE_*`† | grupo de entradas de 18 | título, advertencias, avisos, créditos |

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Primer borrador (lote autónomo) |
