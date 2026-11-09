# Re-review de diseño: Escena de planta y carga de Recepción (sistema 4)

- **Documento:** `design/gdd/escena-de-planta.md` (~320 líneas, estado «In Design»; el índice dice «Designed»)
- **Fecha:** 2026-11-09 · **Revisor:** independiente (sin contexto del autor) · **Modo:** lean (sin especialistas)
- **Workflow resuelto:** `standard` (`modes.rigor: standard`, sin `modes.workflow` explícito, sin `system_overrides`)
- **Secciones requeridas (standard):** Overview, Detailed Design (= Detailed Rules), Edge Cases, Dependencies, Acceptance Criteria y Formulas (el sistema define números): todas presentes. **Player Fantasy** y **Tuning Knobs** no existen como sección: consultivo en `standard`, no bloquea (ver hallazgo 12).
- **Contrastado con:** slice v0.3 (A.0 a A.7, C.1, C.8, D.3, P6 con dos niveles de pista), systems-index, game-pillars, registro de entidades y los GDDs de 1, 2, 3, 5, 7 y 9.
- **Revisión previa:** no existe log de revisión de este GDD; se trata como primera revisión formal del sistema 4 (el historial marca «pendiente de re-review» desde el 2026-11-09).

## Veredicto: NEEDS REVISION

El diseño es sólido y bien probado en lo propio (fórmulas F1 a F3 coherentes, ACs con dobles inyectables). Pero el contrato con Entrada (1) y con el bus (3) no está aplicado en esos GDD, hay una ambigüedad de temporización en la secuencia de arranque que rompe el invariante de F3, y el sistema se contradice sobre si lee hechos. Nada de esto cambia pilares ni alcance.

**Sobre el P6 con dos niveles de pista (decisión del usuario):** el GDD no menciona pistas ni niveles y no tiene que hacerlo; no hay conflicto con el slice. Sin hallazgo.

## Hallazgos

### Bloqueantes

**1. (bloqueante) Orden de «carga de escena iniciada» frente al oscurecido: tres lecturas incompatibles.**
Regla 9: el paso 1 es el oscurecido (d_out) y el paso 2 emite «iniciada», es decir, «iniciada» sale con la cortina opaca. Pero la regla 12 y F2 cuentan `t_espera` desde «iniciada», y F3/AC-F3 afirman que el fallo se detecta «a d_out + T_cap», lo que solo vale si el contador arranca al empezar el oscurecido. Además, la regla 9 dice que la pausa queda bloqueada «de iniciada a terminada», y `D_carga` incluye d_out, lo que supone que Entrada empieza a contar antes del oscurecido. Si «iniciada» sale tras el oscurecido, durante los 0,8 s de d_out el jugador puede abrir la pausa y no hay `sin control`; si sale antes, la regla 9 está mal ordenada y AC-09 también.
Arreglo: decidir uno. Propuesta: «iniciada» se emite al empezar el oscurecido (paso 1, antes de la cortina), `t_espera` arranca ahí con T_cap total desde ese instante (el fallo cae en T_cap y no en d_out + T_cap, o se redefine T_cap como espera tras la cortina y se dice), y corregir regla 9, regla 12, F2, F3, AC-09 y AC-F3 en consecuencia.

**2. (bloqueante) El invariante de F3 («un fallo se detecta antes de que Entrada libere el control») es falso con foco perdido o con Δ_max.**
La regla 12 y F2 congelan `t_espera` sin foco. El tope de Entrada (F8: `D_carga` + 2 s†) solo se detiene con el menú de pausa abierto, y la pausa no se puede abrir durante la carga (regla 7 de Entrada). Con la ventana sin foco 20 s (caso que el propio AC-F2 prueba), Entrada libera el control con la escena aún en negro, justo lo que F3 dice evitar. Lo mismo ocurre con Δ_max: un tirón alarga los fundidos en tiempo real por encima de d_out y d_in nominales.
Arreglo: o bien el tope de Entrada también se detiene sin foco durante la carga (cambio en Entrada, F8), o `t_espera` no se detiene sin foco, o `D_carga` se declara como duración en tiempo de juego y Entrada la mide igual. Añadir un AC de integración (AC-X1) con pérdida de foco.

**3. (bloqueante) El contrato con Entrada (1) y con el bus (3) no está aplicado en esos GDD.**
- `entrada-y-controles.md` no menciona a este sistema (ni «Escena de planta» ni «sistema 4») en sus tablas de interacción y dependencias. F8 (línea 273) solo prevé `sin control` pedido por el director de escenas (21) con duración declarada «por cada escena en su GDD»; no acepta `D_carga` declarada por el 4. Además la regla 15 de este GDD resetea la pila a `sin control` al descargar y a la vez «declara» `D_carga`: no está definido quién abre ese `sin control`, ni qué pila hay al arrancar `partida_nueva` desde el título (OQ 6 sin cerrar).
- `estado-y-bus-de-eventos.md`: la regla 10 enumera los emisores añadidos (5, 9, 7) pero no «carga de escena iniciada», «escena lista», «carga de escena terminada» ni «zona activada» (el GDD de este sistema los marca ‡). Las líneas 98 y 141 siguen diciendo que el 4 «lee hechos al cargar la escena para dejarla en su estado», contradicción directa con la regla 6 de este GDD.
- `design/registry/entities.yaml`: `scene_load_max_duration` conserva el comentario «cambio pendiente en ese GDD».
Arreglo: aplicar los tres cambios (Dependencies, punto «Bidireccionalidad» 1 y 2, y OQ 7) antes de aprobar; definir en Entrada quién abre el `sin control` de una carga (propuesta: lo abre el 4 con `D_carga`, y 21 solo cuando `control_final` = `ninguno`).

### Importantes

**4. (importante) Contradicción interna sobre si el sistema lee hechos.**
Reglas 6, tabla de interacciones («ningún hecho escrito») y Dependencies («Los hechos no los lee este sistema») frente a la regla 13, Edge Cases y AC-14, donde el sistema comprueba `llamada_completada` para rechazar `recepcion`. Es una lectura directa de un hecho.
Arreglo: decir explícitamente que el sistema lee solo `llamada_completada` (y por qué) y que no lee ningún otro; reflejarlo en la tabla de interacciones y en Dependencies (3, lectura).

**5. (importante) Entrada de «zona activada» al aparecer: ambigüedad con la regla 5.**
La regla 5 dice «cada entrada» y Edge Cases/AC-05b dicen que el aviso de aparición sale después de «terminada». Pero ante `reanudar` el jugador siempre aparece en `spawn_office` y nunca dentro de `T-…` (están en el pasillo), así que la regla es inalcanzable salvo por fixtures; por el contrario no se dice qué pasa si la zona se atraviesa durante el aclarado (control aún no devuelto, no puede ocurrir). Menor carga, pero el AC-05b («aparece dentro de una zona») prueba un caso que el diseño excluye.
Arreglo: dejarlo como defensa explícita («solo por datos de prueba») o retirarlo.

**6. (importante) `spawn_office` (−3,0; 0,0) no cumple su descripción.**
Regla 10: «a unos 3 m del escritorio y mirando hacia el ordenador (V01)». V01 está en (−4,4; −2,1) (A.2): la distancia desde (−3,0; 0,0) es ≈ 2,5 m, y V-MOB-1/2 están en Z −2,05 / −1,25. Queda marcado ‡† y en OQ 3, pero el dato propuesto y el texto no coinciden.
Arreglo: corregir a «≈ 2,5 m» o mover el ancla a (−2,6; 0,6) para 3 m; fijar el yaw con la dirección hacia V01 calculada.

**7. (importante) Ancla del ascensor de la planta y de la cabina sin dueño.**
La regla 3 ofrece `door_slot_a/b/d` pero no para C08 (ascensor, X 1,4 a 2,6; muro norte), y el slice dice «Cabina externa». No se dice qué contenedor aloja C08 (el prefijo `C` va a `corridor`, correcto) ni quién pone la puerta/disparador del ascensor (8 o 21). La regla 18(e) fija la cabina de Recepción ≥ 1,2 × 1,2 m, pero el hueco del ascensor de A.1 mide 1,2 m de ancho (X 1,4 a 2,6): sin margen para la cápsula más puerta.
Arreglo: añadir `door_slot_elevator` o declarar que 8 lo define; reconciliar la cabina con la anchura del hueco.

**8. (importante) Registro de entidades incompleto (OQ 13 ya lo reconoce).**
Están `scene_fade_duration` = 0,8 y `scene_load_timeout` = 10, pero falta el fundido de 2,0 s (slice C.1), `N_gap`, `Δ_max` y `Δ_ref`, que aparecen en F1 a F3 y en `scene_load_max_duration.variables`. El rango de `scene_load_max_duration` ([3; 40,4]) no coincide exactamente con F3: el máximo con d_out = d_in = 5, T_cap = 30, N_gap = 10, Δ_ref = 1/30 es 40,33.
Arreglo: registrar las constantes que faltan; alinear el rango (40,34 o decir «≈ 40,4»).

**9. (importante) Afirmaciones de API de Godot sin respaldo en `docs/engine-reference/godot/` — NOT SOURCEABLE.**
Los ACs dependen de `Performance.get_monitor(Performance.OBJECT_NODE_COUNT)` (AC-16c), `Node.print_orphan_nodes()` (AC-16c), `get_instance_id()` (AC-01, AC-08), el runner de gdUnit4, y de la carga/instanciación/liberación de escenas como mecanismo. Nada de esto está cubierto: el único dominio con referencia que se acerca es `physics.md`, y no hay `core.md` (el GDD lo reconoce en OQ 1). Tampoco está sourceado el comportamiento de un sensor esférico de 0,02 a 0,05 m con `Area3D` bajo Jolt (4.6+ lo hace por defecto; `physics.md` solo habla de solapamientos con `SoftBody3D`). Por eso estas afirmaciones se marcan **NOT SOURCEABLE** y esta revisión **no puede dar APPROVED** hasta que lo confirme el ADR de carga de escenas (OQ 1) o una verificación en el editor 4.7.
Arreglo: etiquetar cada AC con la API como «a verificar en el editor 4.7» y mantener OQ 1 como bloqueante del ADR.

### Menores

**10. (menor) Cabecera desactualizada.** `Last Updated: 2026-11-08` mientras el historial registra cambios del 2026-11-09 («Cambia reglas»), y el estado «In Design» frente a «Designed» en el índice. Alinear.

**11. (menor) Texto de Dependencies, línea del Jugador (2), difícil de leer.** «blanda de este lado, dura desde el lado del 2… y por el contrato geométrico» mezcla tres cosas; la Quick reference dice «blandas» mientras la tabla aguas abajo dice «Dura» y el GDD 2 también «dura». Unificar en «dura» con la nota de que 4 solo invoca `colocar`.

**12. (menor) Falta de sección Tuning Knobs.** Aunque es consultivo en `standard`, los valores † (Δ_max, T_cap, N_gap, d_out/d_in de `partida_nueva` y `reanudar`) viven repartidos en F1 a F3 y OQ 12. Una tabla de una página con rango seguro y efecto en el juego evitaría desfases con `load_transitions.json`.

**13. (menor) AC-F3 y el margen de 2 s†.** El margen de Entrada se cita como constante propia («un margen fijo de 2 s†») pero no se referencia al registro ni a F8; si cambia en Entrada, el AC pasa a ser falso. Citar la clave del registro.

**14. (menor) Slice A.0 dice que Recepción se carga «tras la escena 7»; C.8/§8 la sitúan tras la llamada completada (escena 8).** El GDD usa «tras la llamada»; no hay conflicto de reglas, pero conviene citar C.8 y la numeración correcta en Cross-References.

## Comprobaciones de bidireccionalidad

| Sistema | ¿Cita al 4? | Estado |
|---|---|---|
| 2 Jugador | Sí (reglas 20 y 21, tabla, dependencia dura) | OK; contrato geométrico de regla 18 recogido |
| 5 Guardado | Sí (petición `planta` con `reanudar` y `partida_nueva`) | OK |
| 7 Interacción | Sí (retención de arranque, IDs, anclajes) | OK |
| 9 Marco de puzles | Sí (regla 9.6 y fallo de carga) | OK |
| 3 Estado y bus | Parcial | Falta: avisos nuevos en regla 10; redacción de líneas 98 y 141 (hallazgo 3) |
| 1 Entrada | No | Falta: emisor de avisos de carga y `D_carga` en F8 (hallazgo 3) |
| 8, 10, 20, 21, 23, 27, 28 | Sin GDD | Pendiente, ya anotado en el propio GDD |

## Preguntas para el usuario

Ninguna que cambie pilares, tono o alcance. Una decisión de diseño menor que conviene confirmar por si afecta a la sensación de cierre del slice: si el fundido de 0,8 s de A.0 son 0,8 s en cada sentido (la interpretación del GDD, OQ 4) o 0,8 s en total. Hasta que se confirme, se mantiene la interpretación actual.

## Cambios requeridos en otros GDDs

Derivados de la ronda 2 de `escena-de-planta.md` (2026-11-09). Este GDD ya está aplicado; falta lo siguiente fuera de él.

- **GDD 1 (Entrada y controles):** (a) listar al sistema 4 como emisor de «carga de escena iniciada / terminada»; (b) F8: aceptar que el 4 abra el `sin control` de una carga al recibir «iniciada» con `D_carga` como duración declarada (hoy solo la declara el director de escenas); (c) el tope de ese `sin control` no se detiene durante la carga (la pausa no se puede abrir) y se mide desde «iniciada»; (d) con `control_final` = `ninguno` el `sin control` se mantiene en «terminada» hasta que 21 toma el suyo; (e) definir la pila al arrancar `partida_nueva` desde el título.
- **GDD 3 (Estado y bus):** añadir a la regla 10 los avisos «carga de escena iniciada» (con destino, `motivo`, `D_carga`), «escena lista», «carga de escena terminada» y «zona activada»; reescribir las líneas ~98 y ~141 («el 4 lee hechos al cargar»): el 4 lee solo `llamada_completada` (regla 13 del GDD 4) y los elementos leen el resto.
- **GDD 6 (Ajustes):** incluir la clave booleana `reducir_movimiento`, que consume la cortina (regla 11 del GDD 4).
- **GDD 5 y 22:** definir quién sella la partida al llegar a Recepción y en qué aviso (propuesto: «carga de escena terminada» de `recepcion`), de modo que un fallo de carga antes de eso siga reanudando en el despacho (regla 16).
- **GDD 21:** tomar el `sin control` en el mismo fotograma de «terminada» cuando `control_final` = `ninguno`; decidir qué responde el ascensor (`door_slot_elevator`).
- **Registro de entidades (`design/registry/entities.yaml`):** registrar el fundido de 2,0 s (C.1), `N_gap`, `Δ_max`, `Δ_ref` y los 0,1 s de `reducir_movimiento`; `scene_load_max_duration`: `output_range` a [3; 40,34] y retirar el comentario «cambio pendiente»; la variable `scene_load_timeout` (T_cap) pasa a contarse desde cortina opaca.
- **Índice de sistemas:** estado del sistema 4 a «Revisado (ronda 2) — pendiente de re-review» (hoy «Designed»).
- **Slice (A.0):** decir «tras la llamada completada (escena 8)» en lugar de «escena 7».
