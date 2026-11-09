# Revisión de diseño: Jugador en primera persona (sistema 2)

- **Documento revisado:** `design/gdd/jugador-en-primera-persona.md` (65 KB, leído por rangos; 8 secciones más Game Feel, UI, Cross-References, Decisiones y Open Questions)
- **Fecha:** 2026-11-09 · **Revisor:** independiente (no autor), modo lean, sin especialistas
- **Workflow:** `standard` (sin `system_overrides` en `project.yaml`)
- **Contrastado con:** `design/slice/slice-v0.3.md` (§4, §5, §16, A.0, A.3, C.4), `systems-index.md`, `game-pillars.md`, `design/registry/entities.yaml`, `entrada-y-controles.md`, `escena-de-planta.md`, `interaccion-e-inspeccion.md`, `ajustes-persistentes.md`, `docs/engine-reference/godot/`.

## Veredicto: NEEDS REVISION

El diseño es sólido y coherente con el slice y los pilares. Las fórmulas F1, F2, F3, F5 y F7 se recalcularon a mano y cuadran con sus ejemplos y ACs. Los problemas están en tres sitios: un fallo de índice en F6, contratos con otros GDDs que no se han reconciliado, y comportamientos que dependen de Godot sin respaldo en la referencia del motor. Ninguno obliga a rediseñar.

## Completitud (workflow `standard`: 5 requeridas + Formulas, porque hay reglas numéricas)

`gdd-structure-check.sh` reporta PRESENT: Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria. Cumple 6/6 requeridas. Player Fantasy y Tuning Knobs (consultivas) también están y con contenido real. No hay secciones ausentes ni placeholders.

## Grafo de dependencias

| Dependencia declarada | GDD en disco |
|---|---|
| 1 Entrada y controles | existe (In Review) |
| 4 Escena de planta | existe (Designed) |
| 6 Ajustes persistentes | existe (In Review), **pero no contiene los dos ajustes** (ver H-03) |
| 7 Interacción e inspección | existe (Designed), **el GDD del Jugador dice «cuando se diseñe»** (ver H-02) |
| 8, 19, 20, 21, 22, 23, 28 | no existen aún (esperado) |

## Valores del registro

Búsqueda sobre el documento de los nombres y claves del registro (`player_eye_height_m`, `player_walk_speed_mps`, `player_capsule_radius_m`, `player_fov_vertical_default_deg`, `alcance_interaccion_m` y similares). Los valores 1,62 m, 1,6 m/s, 0,25 m y 70° vertical coinciden con el registro y con el slice A.0. No hay conflictos de valor.

Pendiente: el registro solo tiene 4 constantes `player_*`. La «Propuesta de registro» del GDD (líneas 483 en adelante) incluye otras que no están: `capsule_height`, `pitch_limit`, `step_length`, `pose_history_s`, `min_passage_width` y las fórmulas. Se vuelcan al cerrar el lote.

---

## Hallazgos

### Bloqueantes

**H-01 · F6 / Edge Cases / AC-35: desbordamiento de índice en la memoria de poses** · líneas 179-182, 452
`N = ceil(T_hist × f_fisica) + 1 = 61` muestras (índices 0 a 60). Para `τ = T_hist = 1,0 s`, `s = 60`, `i = 60` y `lerp(muestra[i], muestra[i+1])` lee la muestra 61, que no existe. El Edge Case «τ mayor que T_hist se limita» y el propio AC-35 (τ = 5 limitado a 1,0) ejercitan exactamente ese caso.
*Arreglo:* usar `N = ceil(T_hist × f_fisica) + 2`, o limitar `i` a `N−2` con `α = 1`. Actualizar F6, el ejemplo («N = 61») y AC-35. Añadir un test en τ = T_hist y τ = 0 (tras `colocar`).

**H-02 · Contrato con Interacción (7) sin reconciliar; el GDD sigue tratando a 7 como inexistente** · líneas 104, 277, 477; `interaccion-e-inspeccion.md` líneas 42, 74, 78, 271, 439
El GDD de 7 ya existe y declara cuatro supuestos A1-A4 sobre el Jugador, con la cláusula «si el GDD del 2 los contradice, se actualiza este documento». Hoy hay desajustes:
1. **A1 (origen del rayo):** 7 lanza el barrido «desde la posición de la cámara». El Jugador (regla 16, D-16, AC-22) exige ojos **sin balanceo**. Con balanceo `completo` el icono parpadearía.
2. **A3 (ocultar manos):** 7 espera poder ocultarlas. La regla 23 dice «siempre visibles» y no hay operación `ocultar`.
3. **A4 (devolver eje y FOV):** el Jugador no ofrece lectura del FOV vigente.
4. **Nombres:** 7 usa `ANIM_HAND_*` y el Jugador, `HAND_*`. AC-32 y la tabla de Visual/Audio usan estos últimos.
5. **Duración del regreso de cámara:** 7 define `t_vista_salida_s` (0,3-1,0 s, 0,6† por defecto, F4). El Jugador define `t_devolver` = 0,5 s y `devolver_camara(propietario)` no recibe duración. Dos fuentes para el mismo número.
6. El texto del Jugador dice «Interacción (7), cuando se diseñe…» y Open Question 4 «GDD del sistema 7».

*Arreglo:* declarar en el GDD del Jugador la interfaz definitiva con 7. Concretamente: `devolver_camara(propietario, duración)` con duración acotada a `t_transicion_max`; una operación `origen_rayo()` con ojos sin balanceo; una decisión explícita sobre `ocultar_manos` (propuesta: no existe; 7 usa `reposo()`) y sobre los nombres de gestos. Anotar la lista de cambios a 7 en Dependencies. Pasar la fila del GDD de 7 de «supuestos» a «contrato».

**H-03 · Cambios a GDDs vecinos propuestos pero no aplicados; las dependencias bidireccionales están rotas** · líneas 271-281
La regla de diseño exige dependencias bidireccionales y este GDD admite que «ninguno de los GDDs citados se ha editado». Verificado:
- `ajustes-persistentes.md` no contiene `balanceo_camara` ni `campo_vision` (cero coincidencias). La garantía «valor siempre válido» (regla 4 de 6) que el Jugador invoca no se aplica a ajustes que no existen. Las pantallas 25 y 30 no tienen quién les pida ofrecerlos.
- `entrada-y-controles.md` F8 sigue descartando la tecla mantenida al volver el control. **AC-26 (W mantenida, camina en el mismo tick) no se puede cumplir** con Entrada tal como está.
- `escena-de-planta.md`: las puertas sin colisión de hoja, la etiqueta de superficie del suelo, el sensor de zona y la cabina de 1,2 × 1,2 m no están. Ese GDD llama a 2 «blanda de este lado» (línea 190) y «Dura» en su tabla (línea 197), contradiciéndose él mismo.
- `systems-index.md`: la fila 2 sigue en «1, 4». Faltan 6 como dependencia blanda y los dependientes 19, 20, 22 y 23 no listan al 2, aunque el Jugador los declara consumidores de gestos y de `paso`.

La Open Question 8 pedía resolverlo «antes del /design-review» y no se hizo.
*Arreglo:* aplicar los cambios en una pasada (Ajustes, Entrada F8, Escena de planta, índice). Alternativa válida en modo lote: dejarlos como lista cerrada con propietario y fecha, y rebajar AC-26 y AC-19 a «se cierra cuando exista el cambio en 1 y en 6», al estilo del resto de ACs diferidos del repositorio.

### Importantes

**H-04 · Radio de cápsula contra paso mínimo** · líneas 37, 292, 246; registro `player_min_passage_width_m` = 0,60
La regla 3 fija «0,60 m = diámetro 0,50 + margen 0,10» con el diámetro **hardcodeado**. El rango seguro de `radio_capsula` llega a 0,30 m, que da diámetro 0,60 y margen 0. El Edge Case de datos solo invalida desde 0,35 (hueco entre 0,30 y 0,35). Los tres números no concuerdan.
*Arreglo:* definir `paso_min = 2 × radio_capsula + 0,10` (o fijar el 0,60 como constante y limitar el radio a ≤ 0,25), y alinear rango, validación (`≥ 0,35`) y registro.

**H-05 · Cesión de cámara incompleta** · reglas 14, 17, 18; F5; AC-20/21
- No hay fórmula de la interpolación (solo «smoothstep»). Falta: cómo se interpola la orientación (yaw por el arco corto; slerp o Euler) y cómo se garantiza `roll = 0` durante el trayecto.
- `fov_destino` no pasa por el tope `fov_h_max` de F5 (¿se limita en ultra ancho?). Tampoco se dice que el FOV vuelve al valor de `campo_vision` al devolver. AC-20 solo verifica posición y orientación.
- El destino puede exigir un pitch fuera de ±80° (mirar un marco en la mesa a 0,35 m). La regla 13 dice que el pitch «se limita en el único sitio», pero la cesión lo salta sin decirlo.
- Interacción F4 define otra curva para la misma transición (duplicidad).
*Arreglo:* añadir F9 «Interpolación de cesión» (posición lerp, orientación slerp, FOV lerp, mismo parámetro `s`), declarar que las poses cedidas están exentas del límite de pitch y del `roll = 0` de la regla 13, y extender AC-20 al FOV.

**H-06 · Detección de atasco no implementable tal como está escrita** · Edge Cases línea 211; AC-40
«El motor reporta penetración sin resolver durante 0,5 s» presupone una señal que `CharacterBody3D` con Jolt no entrega como tal. `docs/engine-reference/godot/modules/physics.md` solo cubre el uso básico de `move_and_slide()`. **NOT SOURCEABLE:** la referencia no documenta qué informa el motor sobre penetraciones.
*Arreglo:* definir el criterio en términos observables (por ejemplo: posición sin cambio mayor que ε durante `t_atasco` con `|v_obj| > 0` y una consulta de solape de la cápsula positiva), marcar el mecanismo como pendiente del ADR y de verificación contra el motor. El AC-40 con colisión falsa debe probar el criterio, no una señal del motor.

**H-07 · Sensor de zona: contradicción entre regla, rango de knob y AC-09** · regla 4, línea 295, AC-09
La regla 4 dice que la zona se activa cuando el **centro** cruza la línea. Un sensor esférico de radio 0,05 m toca el volumen cuando su centro está a 8,95 m, no a 9,0. A 1,6 m/s el paso de física avanza además 0,027 m. El AC-09 pide «X = 9,0 ± 0,05» y está en el borde de la tolerancia. El rango del knob llega a 0,15 m y rompe la promesa.
*Arreglo:* reducir el rango a 0,02-0,05, o detectar por posición puntual (el volumen compara el punto del sensor y no una esfera), y fijar la tolerancia de AC-09 en ±0,08 m (radio + un paso).

**H-08 · Catálogo de gestos incompleto frente al slice** · líneas 70, 322-340, AC-32; slice §5
El slice §5 y la regla 24 hablan de «encajar piezas». AC-32 exige capturas de «encajar una pieza (puzle 3)», pero el catálogo no tiene ningún gesto para ello (¿`HAND_POINT` más arrastre? ¿`HAND_REACH`?). Tampoco cubre pulsar un botón/tecla del ascensor ni dejar el objeto. AC-32 no es ejecutable.
*Arreglo:* añadir `HAND_PLACE` (o aclarar que el encaje usa `apuntar` + `HAND_HOLD_ITEM`) y su duración, y reconciliar con los verbos `ANIM_HAND_*` de 7 (H-02).

**H-09 · Estados: tres incoherencias que afectan a la implementación** · States and Transitions; reglas 22, 94; AC-24/26/27
1. La tabla pone `menú` en **Congelado** con «frena con `t_freno`», pero pausa detiene el tiempo (AC-27). El cuerpo conservaría su velocidad hasta reanudar. Definir: en pausa no hay tick, y al reanudar sigue el frenado.
2. «Sin escena → Libre (por `colocar`, en estado Congelado hasta que Entrada devuelva `exploración`)»: ¿Libre o Congelado? La fila dice las dos cosas.
3. Tras `devolver_camara` el Jugador queda 0,5 s en Cámara cedida descartando `mover`/`mirar`, pero Entrada ya devolvió `exploración`. Entrada (regla 8) bloquea acciones durante transiciones **solo** si alguien las declara. Nadie lo hace para el regreso. Hay que decidir quién mantiene el contexto (propuesta: 7 mantiene el contexto bloqueante hasta el aviso «cámara devuelta» del Jugador). AC-26 («camina en el mismo tick») solo vale tras `inspección`, no tras una vista cercana.

**H-10 · D-06: justificación factual sin respaldo y propiedad de cámara sin especificar** · línea 391; regla 17
«70° es el valor por defecto de `Camera3D`» no figura en `docs/engine-reference/godot/` (que no tiene módulo de cámara). Según mi conocimiento, el valor por defecto de `Camera3D.fov` es 75° vertical. No lo afirmo como hecho: **NOT SOURCEABLE** desde el repo. Cualquiera de los dos casos hace que la frase no pueda sostener la decisión. Además la regla 17 no fija que el FOV de Godot es vertical con `keep_aspect` en altura, que es la base de F5.
*Arreglo:* quitar esa frase de D-06 (el motivo de «vertical» es el túnel horizontal de 43°, ya expuesto) y añadir a la regla 17 «`keep_aspect` = mantener altura» como requisito, verificándolo contra la documentación del motor en el ADR.

**H-11 · Riesgos de motor que el GDD pospone sin acotar** · reglas 11, 25; Open Questions 2 y 3
- El dibujo de manos «sobre el mundo con su propio FOV» (regla 25, D-07) condiciona AC-31 y AC-33. La Open Question 2 admite que `PROJECTION_MATRIX` en 4.7 «no está verificado», y `docs/engine-reference/godot/modules/rendering.md` no lo cubre. **NOT SOURCEABLE.** Es un riesgo de factibilidad, no un detalle.
- La presentación interpolada a > 60 fps (regla 11) convive con la mirada aplicada por fotograma (regla 13), el sensor y el rayo de 7 en el paso de física. No se dice cuál es la transformada fuente de cada uno ni si la interpolación de física de 3D está disponible y es fiable en 4.7 (tampoco sourceable aquí).
*Arreglo:* exigir un spike de ADR antes de las épicas con criterio de salida medible (las manos no atraviesan un muro con `radio_capsula` 0,25 m en las tres capturas de AC-31/33) y una alternativa nombrada. Declarar en Core Rules qué transformada usa cada servicio (rayo y sensor: estado de física; cámara: interpolada).

### Menores

**H-12 · Valores sin fórmula y knobs incoherentes**
- La intensidad del paso (`i_paso_min` 0,4 a 1,0 «según la velocidad») no tiene fórmula. Proponer `i = lerp(i_paso_min, 1, r)`. AC-38 solo comprueba `≥ i_paso_min`.
- `t_item_dentro/fuera` (0,3 s) aparece en Tuning Knobs, pero ninguna regla ni fórmula lo usa. 7 ya define `t_mano_s` para lo mismo. Eliminar o asignar.
- `g_completo` (0,5-1,5) y `g_reducido` (0,2-0,8) se solapan: `reducido` podría superar a `completo`. Imponer `g_reducido < g_completo`.
- «4 cm de recorrido total a g = 1» (línea 305): son 2 × 0,015 = 3 cm verticales y 2 cm laterales.
- `near` y `fov_manos` son knobs sin fórmula ni regla que los consuma más allá de la tabla.

**H-13 · Ambigüedad de F2 en inversiones de dirección** · F2, Edge Cases línea 209
`a` se elige comparando `|v_obj|` con `|v|`. De W (1,6) a S (−1,28), `|v_obj| < |v|`, así que se aplica `a_freno` durante toda la inversión (0,27 s). El Edge Case habla de «`t_freno` y `t_acel`». De lateral a avance con igual módulo se usa `a_acel`. No hay AC que fije ninguno de los dos.
*Arreglo:* declarar qué aceleración rige y añadir un AC con valores numéricos.

**H-14 · Criterios de aceptación débilmente testables**
- AC-04, AC-36 y AC-39 («no existe ninguna acción/operación») prueban una ausencia. Reformular como «la API pública del Jugador es exactamente la lista X» (comparación con lista fija).
- AC-13 («una secuencia cualquiera de entradas») es no acotada. Fijar una semilla/fixture determinista y un número de pasos.
- AC-34 («legibles con la luz del teléfono») es subjetivo. Fijar un contraste de luminancia mínimo o aprobación explícita del art director.
- AC-31 («tamaño y forma idénticos») necesita una tolerancia de diferencia de imagen.
- AC-42 mezcla «no reportan mareo» con una cláusula ilegible («incluye "lento"… sin "lento" como queja única»). Sin instrumento de medida de mareo en N = 5. Reescribir con un cuestionario fijo y umbral.

**H-15 · Detalles de consistencia**
- Puertas sin colisión de hoja desde el inicio de la apertura (línea 210): visualmente la hoja atraviesa al jugador que está en el umbral. Valorar bloquear el movimiento o aceptar el artefacto de forma explícita.
- Player Fantasy cita «pilar 4» para «el susto es sonido, luz y silencio». El pilar que lo dice es el 2 (*El espacio expresa la emoción*); el 4 es *Tensión sin castigo*.
- Reglas 19 y Cross-References atribuyen «no existe retícula permanente» al slice §16. §16 solo dice «icono discreto cuando el objeto es interactuable»; lo de la retícula es inferencia del GDD, no texto del slice.

---

## Implementabilidad y consistencia (resumen)

- **Slice:** sin contradicciones. Ojos 1,62 m, FOV 70° (interpretado vertical con la salvedad de H-10), sin sprint/salto/agacharse, manos visibles, reflejo 0,6 s y zonas T-PAS-1/2 son coherentes. Slice §5 menciona «encajar piezas» y el catálogo no lo cubre (H-08).
- **Pilares:** cumple *Tensión sin castigo* (roll = 0, sin sacudidas, balanceo opcional) y *Autonomía*. La decisión de que `reducir_sobresaltos` no afecte a nada del Jugador (AC-14) es coherente con el catálogo de Ajustes.
- **Aritmética verificada:** F2 (0,173 m y 0,107 m, 15,1 s en el pasillo), F3 (pasos en 0,375 m, cadencia 2,13/s), F5 (102,4°, 117,0°, 136,2° → 51,9°, 88,5°), F7 (−0,012 / −0,024 / tope −0,03) y el ejemplo de F6 (0,96 m) son correctos.
- **Rendimiento:** no hay presupuesto, deliberadamente (slice §21 sin equipo de referencia). Aceptable, ya declarado.
- **Alcance (señal):** M-L. 8 fórmulas, 7 dependencias directas, un ADR del Jugador y otro del dibujo de manos (probable).

## Recomendación

Corregir H-01 a H-03 en una sola pasada junto con los GDDs vecinos, y H-04 a H-11 en el propio documento. Los menores pueden entrar en el mismo commit. Una segunda revisión debería confirmar H-01 (con el test de τ = `T_hist`) y que la interfaz con 7 es única.

---

## Cambios requeridos en otros GDDs (añadido al aplicar la revisión, 2026-11-09)

El GDD del Jugador (2) es la fuente de verdad del contrato 2↔7. Estado: **Revisado, pendiente de re-review**. AC-19 y AC-26 del Jugador quedan diferidos hasta que existan los cambios de Ajustes y Entrada.

**Entrada y controles (1)**
- F8: la regla de «tecla mantenida durante una transición» se aplica a las acciones disparadoras, no al eje continuo `mover`. Si el jugador mantiene W al volver `exploración`, el Jugador camina en ese tick.
- Regla 8: el bloqueo de transición lo mantiene 7 desde `interact()` hasta `camara_devuelta` / `gesto_terminado` (tope 3 s). Corregir el texto «al sentarse al ordenador» (V01 solo acerca la cámara).

**Ajustes persistentes (6)**
- Regla 1: añadir `balanceo_camara` (enum `completo`/`reducido`/`ninguno`, inicial `reducido`†) y `campo_vision` (float 60–90, paso 5, inicial 70†), lector «2 Jugador», y a «restablecer todos». Las pantallas 25 y 30 los ofrecen junto a «reducir sobresaltos».

**Escena de planta (4)**
- Las puertas desactivan la colisión de su hoja al empezar a abrirse (D-19; preferir que abran hacia el lado contrario al paso habitual).
- Los volúmenes `T-…` detectan el sensor esférico del Jugador (radio 0,02–0,05); activación con el centro entre X = 8,92 y 9,00 para `T-PAS-1`.
- El suelo lleva etiqueta de superficie (`default` si falta).
- La cabina del ascensor mide al menos 1,2 × 1,2 m.
- Corregir la contradicción interna: líneas ~190 («blanda de este lado») y ~197 («Dura») sobre la colisión del Jugador.
- Paso mínimo transitable = 0,60 m (constante `player_min_passage_width_m`); `radio_capsula` fijo en 0,25 m.

**Interacción e inspección (7)** (lo edita otro agente; esto es lo que el contrato exige)
- `t_vista_salida_s` pasa a 0,5 s (o se elimina); F4 de 7 se retira: la curva es F9 del Jugador. AC-31 de 7 pasa a 0,5 s.
- Origen del rayo = `rayo_vision()` (ojos sin balanceo). Quitar «ocultar/mostrar manos»; usar `reposo()`.
- Nombres de gesto `HAND_*` (equivalencias en la tabla de Visual/Audio del Jugador). `t_mano_s` se sustituye por `t_item_dentro`/`t_item_fuera`.
- Propietarios de cámara: `interaccion:vista` y `interaccion:ordenador`; `fov_actual()` para F6; no ceder mientras no llegue `camara_devuelta`.
- Mantener el contexto bloqueante hasta `camara_devuelta`; `bloquea_s` solo como tope (≤ 3 s). Declarar qué objetos son sostenibles (`V05`, `A03`, tarjetas).
- Cierre con pila (`lectura` sobre vista): primero la lectura, luego `devolver_camara`.

**Marco de puzles (9)**
- Encajar una pieza (P3) usa `sostener(pieza, derecha)` + `apuntar` + `HAND_PLACE`; la `cancelación` llama a `reposo()` y no deja pieza en el aire.

**Índice de sistemas**
- Fila 2: depende de 1 y 4 (duras) y 6 (blanda); dependientes 7, 19, 20, 22, 23 y 28. Estado: Revisado.

**Registro (`design/registry/entities.yaml`)**, al cerrar el lote: `player_capsule_radius_m` fijo 0,25; `player_pose_delayed` con `+2`; volcar las constantes de la «Propuesta de registro» del GDD.
