# Re-review: Jugador en primera persona (sistema 2)

- **Documento revisado:** `design/gdd/jugador-en-primera-persona.md` (84 KB, leído entero por rangos de encabezado).
- **Revisión previa:** `design/gdd/reviews/jugador-en-primera-persona-review.md` (NEEDS REVISION, H-01 a H-15).
- **Fecha:** 2026-11-09 · **Revisor:** independiente (no autor), modo lean, sin especialistas.
- **Workflow:** `modes.workflow` **no está definido** en `project.yaml` (solo existe `modes.automation`). Se aplica `standard` como la revisión anterior, pero se comprobaron las 8 secciones.
- **Contrastado con:** `design/slice/slice-v0.3.md` (§5, línea 118 y B.6: P6 con **dos** niveles de pista; P1 nivel 1 «gesto de cámara»), `systems-index.md`, `game-pillars.md`, `design/registry/entities.yaml`, y los GDDs 1, 4, 6, 7 y 9. Motor: `docs/engine-reference/godot/` (físico y rendering).

## Veredicto: NEEDS REVISION

Los arreglos de la primera revisión son correctos en su mayoría. H-01 (búfer de poses, `N = 62`, `min(i, N−2)`), H-04 (radio fijo 0,25 m), H-05 (F9 y `pitch_cesion_max`), H-07 (sensor), H-08 (`HAND_PLACE`), H-10 y H-12 están bien cerrados y su aritmética se recalculó. El contrato 2↔7 está casi cerrado en el texto del Jugador. Hay **un fallo de fórmula introducido por el arreglo de H-13**, **una operación de cámara que el Marco de puzles (9) exige y el Jugador prohíbe**, y desajustes residuales de nombres y propiedad entre 2, 7 y el registro. Ninguno obliga a rediseñar; sí exigen otra pasada.

## Completitud

`gdd-structure-check.sh`: PRESENT Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria. Sin ausentes ni placeholders. 8/8 (6 requeridas a `standard`).

## Grafo de dependencias

| Dependencia | GDD en disco | Bidireccional |
|---|---|---|
| 1 Entrada | existe | Sí (F8 y regla 8 ya aplicadas, ver M-01) |
| 4 Escena de planta | existe | Sí (regla 18 recoge sensor, etiqueta, cabina, puertas) |
| 6 Ajustes | existe | Sí (`balanceo_camara` y `campo_vision` ya en la regla 1 y en «restablecer todos») |
| 7 Interacción | existe | Parcial (I-03, I-04) |
| 9 Marco de puzles | existe | **No** (I-01: `CAMERA_NUDGE`) |
| 19, 20, 22, 23 | no existen | El índice no lista al 2 en sus filas (M-02) |
| 28 | no existe | Sí (fila del índice) |
| 8 | no existe | n/a |

## Valores del registro

Búsqueda de `eye_height`, `walk_speed`, `capsule`, `fov`, `passage`, `pose`, `bob` y los números clave en el GDD. Coinciden: 1,62 m, 1,6 m/s, 0,25 m, 70°, 0,60 m, `N = ceil(T_hist·f)+2`. Una discrepancia de nombre en el registro (I-03: `fov_vigente()` frente a `fov_actual()`). Las constantes de la «Propuesta de registro» siguen pendientes de volcarse al cerrar el lote (ya anotado en el GDD).

---

## Hallazgos

### Bloqueantes

**B-01 · F2 / Edge Cases / AC-45 / D-29: la inversión de dirección no dura lo que dice la fórmula** · líneas 140, 222, 495
F2 elige `a` en **cada tick**: `a_acel` si `|v_obj| ≥ |v| − 0,001`, `a_freno` en otro caso. En W a S (`v` = 1,6; `v_obj` = −1,28) rige `a_freno` solo mientras `|v| > 1,28`, es decir, 2 pasos. Al caer `|v|` a 1,244 se cumple `|v_obj| ≥ |v|` y pasa a `a_acel` (8,0 m/s²). Simulado paso a paso: `v` cruza 0 en el paso **12** y llega a −1,28 en el paso **21**. El texto («rige a_freno durante toda la inversión», 9 y 17 pasos), el Edge Case y **AC-45** afirman 9 y 17, así que AC-45 falla contra la fórmula tal como está escrita. El caso lateral a avance (17 pasos con `a_acel`) sí es correcto.
*Arreglo:* elegir la aceleración por el **signo del producto escalar** (`v · v_obj`): si `v · v_obj < 0` o `|v_obj| < |v|` con la misma dirección, `a_freno`; y dentro de una inversión mantener `a_freno` hasta que `v` cruce 0 (histéresis por fase). O bien aceptar la fórmula actual y reescribir los números (12 y 21) y AC-45. Añadir a AC-45 la simulación de referencia completa, no solo los dos puntos.

**B-02 · Contrato 2↔7↔9 incompleto: `CAMERA_NUDGE` del Marco no tiene dueño ni cabe en el Jugador** · Marco líneas 74, 181, 259, 424, 475; Jugador reglas 14, 18, 33, D-04, AC-13/14
El slice (P1 nivel 1, líneas 136 y 724) pide un «gesto de cámara hacia la impresión, 3 s». El Marco lo implementa como efecto `CAMERA_NUDGE` (`target: I-01`, 3,0 s) y lo lista como dependencia **dura del Jugador vía 7**. Pero: (a) el Jugador declara que ningún evento mueve su cámara (regla 14) y su API es una **lista cerrada** (regla 33, comprobada por igualdad en AC-04); (b) el único mecanismo de movimiento es `ceder_camara`, con `propietarios_camara` cerrada a `interaccion:vista` e `interaccion:ordenador`; (c) 7 no define ni recibe `CAMERA_NUDGE` (cero coincidencias). Hoy nadie lo implementa y, si se implementa, rompe AC-13.
*Arreglo (el GDD debe elegir una):* (1) tratarlo como `ceder_camara` con un tercer propietario `marco:pista` pedido por 7, con la regla de que **solo lo origina una petición explícita del jugador** (menú de pausa) y que la devolución es `t_devolver`; (2) convertirlo en `HIGHLIGHT` del objeto sin mover la cámara. La opción 1 cambia el alcance de la regla 14 (ver Preguntas). En ambos casos: actualizar la lista de propietarios, la regla 33 si hay operación nueva, AC-13/14/21 y la fila del Marco en Dependencies.

### Importantes

**I-01 · `sostener` frente a «no se piden `sostener`»: dos contratos distintos para `V05`** · Jugador reglas 24, líneas 106, 299; 7 líneas 66, 189, AC-20b
El Jugador dice que `sostener` admite objetos de escena sostenibles (`V05`, `A03`, tarjetas) y que «7 declara cuáles». 7 dice que **no pide** `sostener`: mueve él el objeto y pide `reproducir_gesto(HAND_REACH)` y luego `HAND_HOLD_ITEM` «sin ítem» (solicitud ‡ aún no aceptada por el Jugador). Resultado: `HAND_HOLD_ITEM` está definido como gesto que sostiene un modelo aportado por `sostener`, y 7 lo pide sin modelo. Nadie ha decidido quién sostiene `V05`.
*Arreglo:* decidir en el Jugador: o `HAND_HOLD_ITEM` es válido sin objeto (las manos adoptan la postura y el objeto lo mueve 7), o 7 llama a `sostener`. Reflejar la respuesta en la regla 24, la fila 299, AC-29/AC-32 y la solicitud ‡ de 7.

**I-02 · Ranuras de manos: `HAND_PLACE` y `ANIM_PAGE_TURN` son «bloqueantes» pero la ranura que necesitan está ocupada** · regla 24, líneas 70, 372, 378, D-25/D-26, AC-46
La regla 24 dice: un gesto bloqueante ocupa las dos manos, y una petición que pida una ranura ocupada se rechaza. Pero la secuencia de D-25 es `sostener(pieza, derecha)` + `apuntar` (`HAND_POINT`, derecha) → `HAND_PLACE` (bloqueante). La derecha está ocupada por la pieza y el apuntado, así que `HAND_PLACE` se rechazaría por la propia regla. Mismo patrón con `ANIM_PAGE_TURN` (bloqueante, 1,0 s) mientras `HAND_READ` ocupa la izquierda. AC-46 solo prueba `HAND_POINT` + `HAND_READ`.
*Arreglo:* definir la regla de sustitución: un gesto puede **reemplazar** a los gestos de bucle no bloqueantes de su propia mano (`HAND_POINT`, `HAND_READ`, `HAND_HOLD_ITEM`) y devolverlos al terminar; o marcar `HAND_PLACE` y `ANIM_PAGE_TURN` como «compatibles con su mano». Añadir un AC con ambos casos.

**I-03 · Nombre de la lectura del FOV: `fov_actual()` (2) frente a `fov_vigente()` (7 y registro)** · Jugador reglas 19, 33, línea 298; 7 líneas 189, 340; registro `player_effective_fov` (nota)
Una misma operación con dos nombres en tres documentos. La regla 33 cierra la API del Jugador con `fov_actual`, así que 7 llamaría a algo que no existe (y AC-04 lo impediría).
*Arreglo:* elegir uno (propuesta: `fov_actual`, ya en la lista cerrada) y corregirlo en 7 y en la nota del registro. El Jugador no necesita cambiar.

**I-04 · Duración de la entrada/salida del objeto en inspección: 7 sigue definiendo `t_mano_s`** · Jugador línea 354 («7 no define duración propia»), cambios requeridos; 7 líneas 66, 68, 153, 382
7 conserva `t_mano_s` = 0,4 s (rango 0,2–0,8) para coger y devolver el objeto, y el Jugador define `t_item_dentro/fuera` = 0,3 s con la misma función («fundido de `sostener`/`soltar`»). Dos números para un gesto, la misma duplicidad que ya se resolvió con `t_devolver`. Depende de I-01: si 7 mueve el objeto, `t_item_dentro/fuera` solo aplica a ítems del bolsillo (20).
*Arreglo:* declarar en la tabla de Tuning Knobs que `t_item_dentro/fuera` es solo para ítems del bolsillo y que `t_mano_s` es de 7 para objetos de escena; quitar la frase «7 no define duración propia».

**I-05 · Estado del GDD desactualizado: cambios «requeridos» ya aplicados y ACs diferidos sin motivo** · líneas 3, 302-314, AC-19, AC-26, Open Question 8
Verificado en disco: Ajustes (regla 1 y «restablecer todos») contiene `balanceo_camara` y `campo_vision`; Entrada F8 y regla 8 ya excluyen el eje `mover` y asignan el bloqueo a 7; Escena de planta regla 18 recoge puertas, sensor, etiqueta de superficie y cabina de 1,2 × 1,2 m y corrige la contradicción «blanda»/«Dura». El Jugador sigue diciendo «lista cerrada, pendiente», difiere AC-19 y AC-26 y mantiene abierta la Open Question 8. Un programador lo leería como trabajo por hacer.
*Arreglo:* marcar los cambios como aplicados (con fecha), quitar «DIFERIDO» de AC-19 y AC-26 y dejar en la lista solo lo que sigue abierto (I-01, I-03, I-04, B-02, M-02).

### Menores

**M-01 · AC-09 y regla 4: el rango superior del sensor no cuadra con «toca»** · regla 4, AC-09, Escena regla 18(c)
La zona se activa cuando el sensor **toca** el volumen. El contacto ocurre con el centro a X ≤ 9,0 − 0,05 = 8,95, y el paso de física aporta como mucho 0,027 más, así que el primer tick detectado cae entre 8,923 y 8,95. Decir «entre X = 8,92 y 9,00» es válido como tolerancia, pero el límite 9,00 solo se alcanzaría con radio 0; el criterio de aceptación admite activaciones erróneas entre 8,95 y 9,00.
*Arreglo:* AC-09: «entre 8,92 y 8,95» para radio 0,05 (o la expresión `9,0 − radio − [0, v·dt]`). Igual en Escena 18(c).

**M-02 · Índice de sistemas: las filas de 19, 20, 22 y 23 no listan al 2** · `systems-index.md` líneas 43, 44, 46, 47 (la nota de la línea 60 sí los cita)
El Jugador los declara consumidores (gestos y `paso`) y la nota de dependientes también, pero las filas de la tabla y los datos de «depends on» no incluyen el 2.
*Arreglo:* añadir 2 como dependencia blanda en esas filas al diseñarlas (o ya, si el índice se mantiene como fuente).

**M-03 · Tabla de estados: la salida de Cámara cedida por `colocar`** · States and Transitions, AC-23
AC-23 exige que `colocar` cancele una cesión y deje al jugador sin cesión, pero la columna «Sale hacia» de Cámara cedida solo lista Libre/Congelado (al emitir `camara_devuelta`) y Sin escena. Añadir «Congelado (por `colocar`)».

**M-04 · Open Question 3 y la referencia del motor** · regla 11, Open Question 3
La frase «no sourceable» sobre la interpolación de física 3D es demasiado fuerte: `docs/engine-reference/godot/modules/physics.md` (línea 25) y `breaking-changes.md` (línea 77) documentan que la interpolación de física 3D existe y que se reestructuró en 4.5 (movida a `SceneTree`, API sin cambios). Lo que **no** está respaldado es su fiabilidad con `CharacterBody3D` en 4.7. Citar la referencia y limitar la verificación pendiente a eso.

---

## Engine claims (Godot 4.7)

Respaldado por `docs/engine-reference/godot/`: Jolt es el motor 3D por defecto desde 4.6; la interpolación de física 3D existe desde su reestructuración en 4.5; `CharacterBody3D` con `move_and_slide()` es el patrón base.

**NOT SOURCEABLE** (el GDD ya los marca como pendientes, y siguen sin respaldo en el repositorio): valor por defecto y propiedad `keep_aspect` de `Camera3D.fov`; escritura de `PROJECTION_MATRIX` en 4.7 (`rendering.md` no la cubre); consulta de penetración de una cápsula con Jolt (`physics.md` solo documenta el uso básico); `SubViewport` de segunda cámara para las manos; fiabilidad de la interpolación con `CharacterBody3D`. La redacción del GDD (D-06, regla 17, Open Questions 2 y 3, D-23, D-28) es correcta: afirma lo mínimo y difiere al ADR. Estos huecos impiden dar el spike de manos por cerrado, pero no bloquean el GDD.

## Dos niveles de pista del P6

El cambio del usuario (P6 con dos niveles, slice línea 118 y B.6) **no toca al Jugador**: ninguna pista de P6 mueve la cámara ni pide gestos. La única pista con efecto sobre el Jugador es la de P1 nivel 1 (B-02).

## Aritmética re-verificada

F1, F3, F5, F6 (N = 62, τ = 1,0 sin salir del búfer, 0,96 m), F7, F8 y F9 (smoothstep, FOV 65° a 0,5 s, yaw 170→−170 por el arco corto) cuadran con sus ejemplos y ACs. F2 cuadra en reposo→marcha, marcha→parada y lateral→avance; **no** en la inversión (B-01).

## Señal de alcance

M-L (9 fórmulas, 7 dependencias directas, ADR del Jugador y spike de manos).

## Recomendación

Corregir B-01 y B-02 en este GDD y en el Marco. Resolver I-01 a I-05 en una pasada junto con las ediciones de 7 y del registro. Los menores pueden ir en el mismo commit. Tras eso, el GDD debería poder pasar a APPROVED sin otra revisión completa, comprobando solo B-01 (simulación de referencia de AC-45) y la decisión de B-02.

## Preguntas para el usuario

1. **Pista de nivel 1 del P1 («gesto de cámara», slice líneas 136 y 724):** ¿puede el juego mover la cámara del jugador durante 3 s cuando **el propio jugador pide la pista** desde el menú de pausa? Esto contradice la regla 14 del Jugador («ningún evento mueve la cámara») y el espíritu del pilar *Autonomía como progresión*. Opciones: (a) sí, solo bajo petición explícita y con la cámara devuelta por el Jugador a su pose; (b) no, la pista se hace con un resaltado (`HIGHLIGHT`) y el «gesto de cámara» del slice se reinterpreta. Recomendación: (b), por coherencia con los pilares y porque no añade una operación a la API del Jugador. Cambia el slice si se elige (b).

## Cambios requeridos en otros GDDs

Derivados de la ronda 2 del GDD 2 (2026-11-09). El GDD 2 es la fuente de verdad del contrato 2↔7 (D-30 a D-34).

- **Interacción (7):** (1) para objetos de escena (V05, A03, tarjetas) pedir `reproducir_gesto(HAND_REACH)` y, al `gesto_terminado`, llamar a `sostener(obj_id, izquierda)` y luego `reproducir_gesto(HAND_HOLD_ITEM)` (que exige objeto sujeto); 7 no mueve el objeto. (2) Eliminar `t_mano_s` y la solicitud ‡ (la duración del fundido es `t_item_dentro/fuera`, 0,3 s). (3) `fov_vigente()` pasa a `fov_actual()`. (4) Sin `CAMERA_NUDGE`; AC-20b y la fila de dependencias se ajustan. (5) Puede pedir `ANIM_PAGE_TURN` con `HAND_READ` activo y `HAND_PLACE` con `HAND_POINT` y pieza sostenida (regla 24, D-33).
- **Marco de puzles (9):** el efecto `CAMERA_NUDGE` (target I-01, 3,0 s) se sustituye por `HIGHLIGHT`; quitar la dependencia dura del Jugador «vía 7» para ese efecto.
- **Slice (`design/slice/slice-v0.3.md`, líneas ~136 y ~724):** reinterpretar el «gesto de cámara» de P1 nivel 1 como resaltado de la impresión (sin mover la cámara).
- **Escena de planta (4), regla 18(c):** el sensor activa la zona con el centro entre X = 9,0 − radio − [0, 0,027] (8,923 a 8,95 con radio 0,05), no hasta 9,00.
- **Índice de sistemas:** añadir el 2 como dependencia blanda en las filas de 19, 20, 22 y 23.
- **Registro (`design/registry/entities.yaml`):** corregir la nota de `player_effective_fov` a `fov_actual()`; volcar las constantes de la «Propuesta de registro» del GDD 2 al cerrar el lote.
- **Ajustes (6) / Escena de planta (4):** `reducir_movimiento` no lo lee el Jugador (D-32); sin cambio en 2.
