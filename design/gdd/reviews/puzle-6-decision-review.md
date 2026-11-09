# Review GDD 16 Puzle 6 Decision (lote Feature 3)
VEREDICTO: NEEDS REVISION (0 bloqueantes encontrados; 6 avisos; revision parcial, ver NO LEIDO)

## BLOQUEANTES
Ninguno hallado. Todas las referencias comprobadas existen y dicen lo citado (9: reglas 4,7,12,16,24-27,35, F3-F9, AC-03/04/11/17/25/30/31/50/51/59, D9-14/23/54/57/63; 10: reglas 11,13,16,20, AC-08/AC-13, Edge 13, D10-2; 7: reglas 20-23, 27a-c, D7-32; 18: regla 20, AC-03, AC-05, fila 16 de Dependencies). No hallada contradiccion directa con una regla vigente de un vecino no listada en Cambios requeridos (ver AVISO 2 y 4 como casi-contradicciones).

## Formulas (checklist 1) - OK
F2: 0,3+1,6 = 1,9 s; rango 1,5-1,9. F3: minimo 1,0+2,0+1,9+6,0+0,5 = 11,4 s; tipico 1+15+1,9+10+0,5 = 28,4 s (dice ~28); techo 120-(1+1,9+12+0,5) = 104,6 s. F7 minimo 30 s - 11,4 = 18,6 s = 0,31 min: correcto. Ejemplos de F1 (pausa 107-137 -> idle 7 s, nivel 1 a +3 s) y F2 (t_atras 1,0 -> 1,5 s; 1,8 -> 2,3 s, espera 0,4 s) correctos. Pistas 10/20 s caen antes de 30 s: cierto.

## AVISOS
1. Sintaxis (checklist 3): el esquema de 9 (regla 4, `on_solved`: "hechos a escribir en orden, compartment, sonido, duracion, recompensas, close_view_after_s"; ejemplos P1/P5 solo con `"value": true`) NO tiene `value_from`, `commit_on`, `presentation`, `request_reading` ni `idle_reset` como campo de datos (F3 de 9 solo dice "cada puzle declara que cuenta (`idle_reset`)", sin campo en regla 4). GDD16 lo reconoce (Datos del puzle, nota ‡; Cambios requeridos (9) a-b). Aviso, no bloqueante: es propuesta marcada; 9 debe aceptarla antes de implementar. Existe ademas precedente sin resolver: D9-41 (`t4_decision`).
2. Contrato con 7 (regla 5 / D16-2 / Edge 3 / AC-16-04): 7 regla 20 (tabla) entrega `seleccionar` con `inicio` y `fin` "en el mismo fotograma, al soltar"; `elemento` = el de al pulsar; el `elemento_bajo` de `seleccionar` no esta especificado en la tabla. GDD16 trata el evento unico como hipotesis ("Si 7 entregara...") y en Cambios (7) pide "confirmar" algo que 7 ya fija. Consecuencia: "inicio en A y fin en B" (AC-16-04, primera mitad; Edge Case 3) no puede ocurrir (pulsar y mover >8 px es `agarrar`, no `seleccionar`); el `inicio` tampoco ocurre "al pulsar". Pedir a 7 que defina `elemento_bajo` en `seleccionar` y simplificar regla 5 / AC-16-04. El slice B.6 dice "PULSAR"; la aceptacion al soltar es coherente con 7 pero es cambio respecto a la letra del slice (registrado en D16-2: OK).
3. Pilar 1 / CARTA_A: la lectura A=mentira, B=verdad esta capturada como Open Question 2 (con tono y pilares). Correcto. Detalle: slice §12 `CARTA_A` = "Estoy bien. Es lo que escribiria si no fuera verdad" y boton B "La verdad" (slice B.6): el riesgo es real y es decision del usuario; GDD16 no lo toca. D-W5 esta en OQ 1 con opciones (a)/(b)/(c) y medicion (AC-16-22). Pistas a 10/20 s frente a pausa: regla 19 y D16-5. Bien.
4. Edge Case 4 vs F1 / regla 18 / regla 26 de 9: Edge 4 dice que tras reabrir "el texto se vuelve a aplicar por umbral" aun con `hint_level_reached` en memoria; F1 (ejemplo) y D16-11 dicen que pedir el nivel 2 hace que el 1 "no" salga despues por monotonia. Sin regla clara de si, tras cerrar y reabrir la vista, un nivel ya alcanzado se reaplica. 9 regla 26 ("monotono") y F3 ("una vez por compromiso, se rearma al volver a comprometerse") son ambiguas; precisar (OQ 8 lo cubre solo a medias).
5. Edge Case 6 / regla 8: "elegir otra opcion tras cierre antes de guardar" contradice en la practica "la respuesta es definitiva" (D-14) en el momento mas intimo; esta declarado (regla 8, D16-10) pero conviene elevarlo explicitamente a Open Question (hoy no lo esta; OQ 3 solo trata la confirmacion de D-14 en el slice).
6. Calibracion (F3): `t_lectura` 6-12 s "21-25 palabras entre primera frase y CARTA_CUERPO" no esta verificado contra 18 (la cifra de palabras no sale de una fuente; marcado † y "no cifra de 18": aceptable, pero sin dagger en el numero 21-25).

## INFO
- F2 "Output Range": "la espera maxima de la lectura es t_salida (<= 3 s)" contradice la linea anterior (espera <= 0,5 s); redaccion confusa, valor correcto.
- Regla 11 renumera los pasos de 9 regla 16 (inserta "caja_completa" como paso 3); orden efectivo coincide.
- 23 ACs: tipos L/I/PV coherentes; AC-16-22 y AC-16-23 son PV con evidencia. AC-16-20 cita regla 30 de 9 (existe).
- Dependencies: 16 -> 9, 10, 18 como duras, coincide con la fila 16 (a falta de verificar el indice) y con la fila 16 de 18. 9 y 10 ya listan "11 a 16"/"13 a 16" (10: fila "13-16 ... Pendiente").
- 11 preguntas abiertas: 1, 2, 7, 10 son de tono/pilares (correctas); 3, 4 confirman decisiones del slice; 5, 6, 8, 9, 11 son tecnicas/de contrato. Sin decisiones de tono tomadas en silencio salvo AVISO 5.
- Valores sin fuente: los numericos llevan dagger o fuente (slice B.6, 10 D10-2, 7 27b). Sin NOT SOURCEABLE.

## NO LEIDO
llamada-telefonica (22: reglas 7 y 21, D22-12, AC-22-05), documentos-y-bolsillo (20: R2, R5, R13, R18, R22, AC-02/12/13), ajustes-persistentes (6: tabla de consumidores), systems-index fila 16, game-pillars, game-concept, `design/registry/entities.yaml`; 18 regla 5 (leida solo via AC-05); 10 regla 8/15 (solo citas indirectas); AC-42 de 9 (linea omitida). Las citas a estos documentos no estan verificadas.
