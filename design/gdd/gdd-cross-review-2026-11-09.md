# Cross-GDD Review Report

**Fecha:** 2026-11-09 · **Veredicto: FAIL** (8 bloqueantes) · **Modo:** autonomous, workflow standard

- **GDDs reviewed:** 9 of 9 present (1, 2, 3, 4, 5, 6, 7, 9, 18). Todos «Revisado (ronda 2) — pendiente de re-review».
- **Not read (completos):** none. **Leídos parcialmente:** ver «Cobertura» al final; varias secciones no se leyeron.
- **Focus:** full (consistencia + teoría de diseño + escenarios).
- **Desviación del procedimiento:** la skill pide pasar a los subagentes el contenido de los GDDs pegado. Con ~680 KB no cabe en contexto, así que cada subagente leyó por secciones (Grep + Read). Cuatro subagentes: 2a/2c/2d, 2b/2e/2f, Fase 3 y Fase 4. Tres de ellos agotaron sus 20 turnos y se reanudaron para que entregaran lo comprobado.
- **Decisiones del usuario respetadas** (no son hallazgos): P6 con dos niveles de pista; pista del P1 como resaltado; D.2 con la llamada repetible; `reducir_movimiento` en MVP; título solo «Nueva partida» tras Recepción.

---

## Consistency Issues

### Blocking

🔴 **C-B1 · 2↔7 · Quién mueve el objeto inspeccionado y quién define `t_mano_s`.**
Jugador (2) regla 24 / D-34: «7 no mueve el objeto por su cuenta… 7 ya no define `t_mano_s`». Interacción (7) regla 13: «mueve el objeto… en `t_mano_s` (0,4 s)… sigue siendo dueño de su transformada»; `t_mano_s` sigue en sus Tuning Knobs, estados y regla 15, y en el registro (`entities.yaml:860`). Cada GDD se declara fuente de verdad; los ACs de ambos son incompatibles. *(Hallado por dos subagentes.)*
Opciones: (a) 2 mueve el objeto y 7 elimina `t_mano_s`; (b) 7 conserva la transformada y 2 reescribe D-34 y la regla 24; (c) reparto: 2 sujeta, 7 anima entrada y salida. En cualquier caso, actualizar el registro.

🔴 **C-B2 · 3↔5 · «avisos descartados» no existe en Guardado.**
Estado (3) edge case del tope de cadena, regla 10 y Dependencies: se emite «para que Guardado (5) lo trate como causa de guardado». El literal aparece 6 veces en 3 y 0 en `guardado-y-carga.md`; las 10 causas de la regla 6 de 5 no lo incluyen. La garantía de «no perder una causa» no tiene contraparte.
Opciones: (a) 5 añade la causa `notices_dropped` (¿urgente?); (b) 3 retira la promesa y se apoya en `periodic`.

🔴 **C-B3 · 7↔9 · `habilitado_si` de `C05`.**
Marco (9) reglas 7 y 35: 7 admite `habilitado_si: { ninguno: [archivo_abierto] }` en `C05`. Interacción (7), fila `C05`: Disponibilidad «siempre»; su JSON de ejemplo tampoco lo lleva. Con el P1 resuelto el panel seguiría siendo objetivo.
Opciones: (a) 7 añade el `habilitado_si` a `C05`; (b) 9 admite que `C05` tiene dueño y usa `get_view_gate`.

🔴 **C-B4 · 1↔4 · `sin control` de la carga: dueño, relevo al 21 y duración tras el reinicio de la pila.**
Escena (4) regla 9: con `control_final = ninguno` «el 21 debe tomar el suyo en ese mismo fotograma» y «no abre `sin control` en una carga por su cuenta». Entrada (1) Edge Cases: pedir un contexto que ya está arriba «se ignora»; `sin control` «se sale con: el sistema que lo abrió».
- La petición del 21 se ignora, no puede cerrar el `sin control` del 4, y el 4 no lo cierra porque `ninguno` no pide nada. Sigue corriendo el tope `D_carga`+2 s (para `partida_nueva` ≈ 14,87 s). Si la escena 1 dirigida dura más, Entrada libera el control a mitad.
- La regla 9 dice que el reinicio de pila al descargar «no lo sustituye ni lo acorta»; Entrada regla 6 lo define como reinicio de pila con un solo aviso, y AC-F8 da 3 s a todo `sin control` sin duración declarada. Un `sin control` sin duración creado tras el paso 3 caduca a los 3 s mientras `T_cap` espera hasta 10 s.
- No está definido qué pasa en la primera carga desde el título (pila [`menú`]).
Opciones: (a) operación «traspasar `sin control`» (nuevo dueño y duración) en Entrada; (b) 4 pide `exploración` en `terminada` y 21 abre el suyo después, aceptando un fotograma; (c) el reinicio de pila conserva dueño y duración del vigente; (d) definir el modelo de pila para la carga desde el título.

### Warnings

⚠️ **C-W1 · 2↔7 detalle del contrato.** `HAND_REACH` es «derecha» en 2 y «ocupa las dos manos» en 7 (regla 13). Sostenibles de escena: 2 dice `V05`, `A03`, tarjetas; 7 dice que `A03` y tarjetas no lo son (las sostiene 20). 7 afirma que `sostener` no puede pedirse con un gesto bloqueante en curso; la regla 24 de 2 no lo impone. 7 no pide `HAND_HOLD_ITEM` tras `sostener` y su AC-20b no lo comprueba, pero 2 lo exige con objeto sujeto. Se decide junto con C-B1.

⚠️ **C-W2 · 3↔4.** 3 dice que 4 «no lee hechos»; 4 (reglas 6 y 13) lee `llamada_completada`. La carga útil de «carga de escena iniciada» es (destino, `motivo`, `D_carga`) en 4 y solo (destino) en 3 (regla 10); Entrada la necesita para su tope.

⚠️ **C-W3 · Dependencia 2↔4.** 4 la declara «dura en ambos sentidos» y su párrafo de índice dice que las blandas con 1 y 2 no se añaden; 2 lista a 4 como «dura» aguas arriba y «Blanda» aguas abajo.

⚠️ **C-W4 · «partida terminada» sin emisor** (también escenario S-B1).

⚠️ **C-W5 · Gancho de validación.** Marco (9) regla 29 exige validar tras cargar los catálogos de 7 y las claves de 18 y antes de configurar los puzles («datos de puzle inválidos»); 4 solo describe retenciones y el fallo de carga genérico (regla 14). Falta el orden de arranque 7 → 9 → resto.

⚠️ **C-W6 · 6↔7.** 7 pide `multiplicador_pie`, `pie_persistente` y `alternar` («ajustes ‡ para el 6»); no figuran en `ajustes-persistentes.md` (grep sensible a mayúsculas; verificar con el nombre real).

⚠️ **C-W7 · 7↔9.** La fila `D01a`–`D01d` de 7 dice «10 consulta al marco antes de abrir» y no nombra `get_view_gate`. 9 usa `MUNDO` en prosa y 7 usa `WORLD` (9 reconoce el alias).

⚠️ **C-W8 · 18 obsoleto.** Dependencies de 18 usa «2 Cámara y movimiento · 4 Guardado · 5 Transiciones de escena» (hoy 2 = Jugador, 4 = Escena, 5 = Guardado). Dice «8 claves `PISTA_*`»; 9 pide 17 (3 por puzle, 2 en P6). Puede ser que 18 solo cuente las pistas con texto y el resto sean efectos; verificar.

⚠️ **C-W9 · Listas de «cambios pendientes» obsoletas.** 2 («Siguen abiertos»), 9 regla 1, 4 (Bidireccionalidad, ítems 1–3) y 7 aún listan como pendientes cosas ya aplicadas (`CAMERA_NUDGE`→`HIGHLIGHT`, `fov_vigente`→`fov_actual`, `owner=9`, retirada de `leer` de `inspección`).

⚠️ **C-W10 · Sensor de zona.** 2 regla 4: [8,923; 8,95] (recalculado: 9,0 − 0,05 − 1,6/60 = 8,9233). 4 regla 18(c): «entre 8,92 y 9,00» (cambio M-01 sin aplicar; 9,00 no es alcanzable). Además AC-09 de 2 no está marcado PV y depende del mismo comportamiento de `Area3D`/Jolt que AC-05a/b de 4.

⚠️ **C-W11 · Cadena de `D01a` frente al tope de 3 s de Entrada.** 7 regla 19/F4 asume topes por tramo (token 1,6 s + cámara 1,0 s = 2,6 s); Entrada F8 declara un único tope de 3 s desde `interactuar()`. Con `BOX_Cn_OPEN` = 1,6 s y `t_vista_entrada_s` hasta 1,5, el peor caso es 3,1 s y Entrada libera antes de «cámara cedida».
Opciones: reiniciar el tope en el traspaso por token; acotar `t_vista_entrada_s` ≤ 1,2 en vistas encadenadas; declarar dos transiciones.

⚠️ **C-W12 · Separación de elementos de vista.** 7 regla 22 exige ≥ 2·R con R = 64 px; Entrada F5b fija R por elemento = min(max(64, tolerancia), 128). Con tolerancia 88 hacen falta 176 px, con 220, 256 px; AC-30 solo prueba 128 px.

⚠️ **C-W13 · Referencias con número o nombre erróneo.** 4 cita «Entrada reglas 7, 15 y 21» (la 15 es Reasignación); 3 cita `cola_vacía` «regla 11.1 de 5» (se define en F1); 7 cita «F-cámara» (es F9 de 2); 7 regla 10 dice que `sin control` lo pide solo el director de escenas, y la regla 6 de 1 incluye a 4. `t_vista_salida_s` sigue en el registro (`entities.yaml:499`) y en 7 F4 como alias de `t_devolver`.

*INFO:* los pares 1↔3, 1↔4, 1↔2, 1↔7, 2↔6, 3↔7, 3↔9, 4↔5, 4↔7, 5↔9 son recíprocos con los mismos nombres. Los contratos 7↔9 coinciden en nombres (`registrar_receptor`, `abrir_vista`, `cerrar_vista`, `ViewReceiver`, `PointerEvent`). Fórmulas cruzadas que cuadran: px/m 2.203 (7 F6) con Entrada F5b (88 y 220 px, R = 88 y 128); Jugador F6 N = 62 / 38; `D_carga` 11,667 s con tope 13,667 s; `t_periodico` frente a `t_intento`. 1 vs 6: 1 dice a la vez «Ajustes depende de este sistema, no al revés» y «necesita leer de Ajustes» (INFO). Un `interactuar` mantenido al abrir `lectura` (R01) no está cubierto por «ignorar hasta soltar» (Entrada F8 lo limita a transiciones).

---

## Game Design Issues

*Adaptado al género: sin combate, XP ni economía. 3d «no aplica» (comprobado): pistas con fuente ilimitada y sin sumidero por diseño (D9-37); ítems y tarjetas son llaves de un solo uso; el coste del fallo es solo tiempo.*

### Blocking

🔴 **D-B1 · Pilares 1 y 3 · Puzle 4 con «Devolver» obligatorio.** B.4 y la Matriz del marco solo aceptan «Devolver» en T4; lo demás da `REJECT` («No corresponde»). Contradice el pilar 1 («Ninguna opción es incorrecta») y el ejemplo del pilar 3, y el slice (§10.4) lo llama «primera elección de autonomía». El juego declara incorrecta la acción moral que hizo el Guardián.
Opciones: (a) T4 acepta ambas y la elección se guarda en un hecho que cambie una línea; (b) se mantiene la solución única, se quita «No corresponde» y se corrige el texto del pilar; (c) se escala a creative-director antes del GDD 14. **Necesita decisión del usuario.**

🔴 **D-B2 · Anti-pilar · `VO_G_13B` «Lo sé. Por eso lo pedí».** Slice §11.1, almacenada en 18. Pilar 1 («Violating») prohíbe «una línea que confirme la intención del Guardián»; el anti-pilar es «NOT una historia explicada». Opciones: (a) reescribirla con narrative-director; (b) aceptarla como excepción registrada; (c) suavizarla («Lo sé.»). **Necesita decisión del usuario.**

### Warnings

⚠️ **D-W1.** La fuerza bruta en P1 (T_media ≈ 61 s, T_peor ≈ 122 s) y en P4 elimina la función narrativa del puzle; el argumento de Edge Cases («el contenido llega después de resolver») es falso para P1 (ordenar la cronología) y P4 (decidir). Opciones: aceptar con medición; mostrar el correo al colocarlo (P1); sellar la ficha correcta en el acto (P4).
⚠️ **D-W2.** P2 se resuelve sin deducir (≤ 9 clics, `PARTIAL` por lámpara) pero tiene el mayor objetivo de tiempo (3–6 min).
⚠️ **D-W3.** P5: el juego resalta solo la silueta de Vera (`OUTLINE`), el criterio §19.5 mide la alineación, no la identificación, y un giro lento (< ~7,5°/s, ~12 s) lo resuelve. La escalera de pistas es un acantilado (N1/N2 vagos, N3 da la marca).
⚠️ **D-W4.** Las escaleras de pistas de P1, P3 y P4 son más cortas de lo declarado: B.1 ya pone «Ordena por hora de envío» en el pie y `I-01` ya trae «Enviado: 11:40»; P4 N1 (regla visible) y P3 N1 (siluetas) ya son base.
⚠️ **D-W5.** Pistas automáticas del P6 (10 s y 20 s, `PRESS_ONLY`): llegan en el momento más íntimo y la segunda («la carta no cambia; cambia la primera frase») adelanta el efecto que §19.6 quiere que el jugador descubra; quien elige en < 10 s decide sin saber que es definitivo.
⚠️ **D-W6.** La respuesta de la llamada se puede volver a elegir (cerrar antes de `slice_completed`), pero la carta es permanente (D-14).
⚠️ **D-W7.** El llanto contenido de la llamada no tiene subtítulo; 18 no tiene entradas de sonido no verbal.
⚠️ **D-W8.** El Player Fantasy del marco prioriza Challenge y Discovery sobre Narrative; los pilares ponen Narrative primero.

*INFO:* ningún momento supera 4 sistemas con atención simultánea (P5 en la revelación llega a 4; el contorno dura 0,8 s). «El punto» del juego es reconstruir la cronología; las pistas no compiten. `reducir_sobresaltos` y `reducir_movimiento` frente al clímax: queda por definir si afecta a la tapa del P6 (GDD 10). F7 suma 10,5–22 min solo de puzles; puede pasar de 30 min con escenas y llamada. Fantasías coherentes entre 2, 5, 7, 9.

---

## Cross-System Scenario Issues

Scenarios walked: **5 planificados (E1, E3, E4 completos; E2 y E5 parciales) + E7 sin recorrer**. E1 revelación del P5 con pausa/cierre/carga · E2 inspección/lectura con avisos concurrentes · E3 llegada a Recepción y sellado · E4 «Nueva partida», cierre durante carga y fallos · E5 ajustes en vivo · E7 vuelta al título desde Recepción (NOT ASSESSED).
Verificado sin fallo: E1 (escritura de `pendiente_revelacion` → cola vacía → `quit` urgente → carga salta la alineación y repite la secuencia; el orden de cierre es seguro) y E4 (el flujo de «Nueva partida» no borra el fichero; cierre durante la carga no escribe).

### Blockers

🔴 **S-B1 · E3 · 3, 4, 5, 22 · Nadie es dueño de emitir «partida terminada».** 3 regla 10: «4 o 22; lo fijan 5 y 22»; 4 regla 16: «lo definen 5 y 22»; 5 regla 29: «4/22 ‡». Referencia circular. Sin el aviso no se cumple D-25. Tampoco está fijado el instante (`iniciada`, `escena lista`, `terminada`): si fuera `iniciada`, un fallo de carga marcaría la partida como terminada. 22 vive en la planta, que se descarga, así que 4 es el único emisor que sobrevive.
Opciones: 4 emite en «carga de escena terminada» de `recepcion` (protege contra el fallo de carga); 22 emite al activar el ascensor; 21 al terminar la escena.

### Warnings

⚠️ **S-W1 · E3 · 5, 22 · Una partida que nace Sellada no tiene «contenido capturado».** Si el jugador cierra durante la llamada y continúa, la partida nace Sellada (5 regla 11.4) y no hay captura. Al llegar a Recepción, 5 regla 29 / AC-18b escribe «el contenido capturado de 11.1 más `completed`», que no existe; escribir el estado actual vuelca `respuesta_llamada` y `llamada_completada`, que 11.2 y AC-15 prohíben; no escribir deja «Continuar» repitiendo la llamada. Camino probable. Opciones: conservar la instantánea restaurada como contenido capturado; escribir `completed` sobre el fichero cargado; permitir el estado actual solo para `completed`.
⚠️ **S-W2 · E3 · 4, 5 · Fallo de carga de Recepción sin transición definida.** 4 regla 14 vuelve al título; la tabla de 5 solo cubre fallo desde «Cargando partida» y «salir al título» con `quit`. AC-36/38c no lo cubren.
⚠️ **S-W3 · E3/E4 · 1, 4, 27 · Contexto de entrada al fallar una carga.** Tras el reinicio a `sin control` (4 regla 15), el tope de Entrada expira y no se define quién devuelve `menú` ni cómo sale el jugador del mensaje de `Error`: riesgo de título sin contexto. **Puede ser BLOCKER** (el subagente no leyó Entrada F8 ni regla 6 en detalle; el hallazgo C-B4 sugiere que sí hay hueco).
⚠️ **S-W4 · E4 · 3, 4, 9, 18 · Tres destinos de «fallo de carga» con un solo texto.** 18 regla 21 («Reinicia la aplicación») cierra el juego; 4 regla 14 y 9 regla 29 vuelven al título, que sigue ofreciendo «Continuar» y repite el fallo.
⚠️ **S-W5 · E1 · 9, 1, 23 · Pausa y audio desincronizados** durante el paso `LINE` de 14 s: si 23 no pausa la voz con el reloj de juego, `VO_G_07` termina con el menú abierto y la imagen se pierde (contra 9 regla 19). *NOT SOURCEABLE* (`AudioStreamPlayer`/`Tween`/`SceneTree.paused`).
⚠️ **S-W6 · E1/E5 · 7, 1, 9 · ¿La pausa cierra la vista?** 7 regla 21 («pausa que cierra la vista») frente a Entrada línea 311 (se restaura con el puzle intacto) y 9 reglas 11b/15/18. Decide si la revelación de 16 s se repite entera.
⚠️ **S-W7 · E1 · 3, 9, 5 · «En silencio» sin mecanismo en 3.** 9 regla 8 / AC-41 limpia `pendiente_revelacion` «sin avisos» al cargar; 3 regla 9 emite aviso en todo cambio real y la escritura silenciosa solo existe para la consola de desarrollo. Otros suscriptores (23, 28) reciben el aviso y la línea base de `dif` queda distinta.
⚠️ **S-W8 · E2 · 7, 9, 1 · Petición de lectura aplazada sin regla al vencer.** 7 regla 27b evalúa «al llamar»; la carta del P6 (D7-32) podría descartarse.

*INFO:* cierre accidental por `atrás` en mitad de la revelación (repetirla; medir en playtest); la ventana entre la llamada y Recepción es más larga que «1 a 2 min»; «Nueva partida» fallida deja 3 restablecido pero la inspección `valida` (inocuo); `control_final` en «Nueva partida» depende de que 21 lo tome en el mismo fotograma; el aviso de Ajustes va fuera del bus (3 regla 10) sin contrato escrito.

---

## GDDs Flagged for Revision

| GDD | Motivo | Tipo | Prioridad |
|---|---|---|---|
| jugador-en-primera-persona.md (2) | C-B1 propiedad de la transformada y `t_mano_s`; C-W1 | Consistency | Blocking |
| interaccion-e-inspeccion.md (7) | C-B1, C-B3, C-W1, C-W11, C-W12 | Consistency | Blocking |
| estado-y-bus-de-eventos.md (3) | C-B2, S-B1, C-W2, S-W7 | Consistency / Scenario | Blocking |
| guardado-y-carga.md (5) | C-B2, S-B1, S-W1, S-W2 | Consistency / Scenario | Blocking |
| marco-de-puzles.md (9) | C-B3, D-B1, C-W5, S-W5/S-W6 | Consistency / Design | Blocking |
| escena-de-planta.md (4) | C-B4, S-B1, C-W2, C-W3, C-W10, S-W3 | Consistency / Scenario | Blocking |
| entrada-y-controles.md (1) | C-B4, C-W11, C-W12, S-W3 | Consistency | Blocking |
| base-de-contenido-narrativo.md (18) | D-B2 (`VO_G_13B`), C-W8, D-W7 | Design Theory | Blocking |
| ajustes-persistentes.md (6) | C-W6 | Consistency | Warning |

---

## Verdict: FAIL

8 hallazgos bloqueantes: **C-B1, C-B2, C-B3, C-B4** (consistencia), **D-B1, D-B2** (pilares) y **S-B1** (escenario), más S-W3 que puede subir a bloqueante tras leer Entrada F8 y la regla 6.

### Required actions before re-running

1. **Decidir** (usuario): D-B1 (P4 «Devolver») y D-B2 (`VO_G_13B`).
2. **Contrato 2↔7:** elegir quién mueve el objeto inspeccionado y quién define `t_mano_s`; resolver con ello `HAND_REACH`, sostenibles (A03, tarjetas) y `HAND_HOLD_ITEM` (C-B1, C-W1).
3. **3↔5:** añadir la causa `notices_dropped` en 5 o retirar la promesa en 3 (C-B2).
4. **7↔9:** `habilitado_si` de `C05` en 7 o `get_view_gate` en 9 (C-B3).
5. **1↔4:** definir el traspaso o la duración del `sin control` de carga y el modelo de pila en la carga desde el título (C-B4, S-W3).
6. **«Partida terminada»:** asignar el emisor y el instante (S-B1); recomendado: 4, en «carga de escena terminada» de `recepcion`. Resolver con ello S-W1 y S-W2.
7. Avisos de carga: ampliar el aviso «iniciada» con `D_carga` en 3 y reflejar el gancho de validación en 4 (C-W2, C-W5).

---

## Cobertura (qué no se pudo revisar)

**NOT ASSESSED** (se declara por nombre; el veredicto FAIL no depende de esto, pero una re-ejecución debe cubrirlo):
- **Fase 1:** sin carga previa por mi parte; cada subagente leyó por rangos (ver desviación arriba).
- **2f y 2b parciales:** no se leyeron las Detailed Rules ni los ACs de `base-de-contenido-narrativo.md`; del marco de puzles solo F3, F4, F6, F7 y F8 (no sus reglas de cierre, pistas ni `needs_items`, ni sus ACs); de `guardado-y-carga.md` no se leyeron Edge Cases ni ACs; de `estado-y-bus-de-eventos.md` no los ACs; de `ajustes-persistentes.md` no los ACs ni Edge Cases (6 solo por grep de claves); de `interaccion-e-inspeccion.md` no la tabla de objetos (líneas 211–251) ni Visual/Audio.
- **Valores del registro** (`t_mano_s`, `lock_max_s`, `close_view_after_s`, `D_carga`…): solo se comprobó que las claves existen.
- **IDs de decisión citados** (D-19, D-30, D-33, D7-xx, D9-xx, D-24/25/26): no verificados.
- **Anexos B y D.2 del slice** frente a los GDDs, y la cifra de 19 hechos: no comparados. `assets/data/` está vacío (sin datos reales).
- **E2 (conflicto de ranuras de manos, carrera cámara/token con lectura aplazada), E5 (reglas internas de 6) y E7 (vuelta al título desde Recepción):** no recorridos.
- **Sistemas sin GDD** (8, 10–16, 17, 19–28, 30): 22, 23, 21, 27 condicionan varios hallazgos (S-W5, S-W8, S-B1); sin ellos no se pudo valorar el ritmo de escenas, los subtítulos, la atmósfera ni la accesibilidad global.
- **NOT SOURCEABLE** (Godot 4.7, no cubierto por `docs/engine-reference/godot/`): barridos de forma con Jolt (7 F1); interpolación de física 3D y `keep_aspect` vertical; penetración de la cápsula; tipado numérico del JSON; renombrado y borrado atómicos; `AudioStreamPlayer`/`Tween`/`SceneTree.paused`; instanciación y liberación de escenas, monitores de rendimiento y nodos huérfanos.
