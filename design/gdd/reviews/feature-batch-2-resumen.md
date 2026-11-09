# Revisión independiente del lote Feature 2 (GDD 22) y de la tabla de dependencias — resumen

**Fecha:** 2026-11-09 · **Revisores:** uno para el GDD 22 y otro para las dependencias de los 15 GDDs, ambos sin el contexto de los autores (solo Grep y Read).
Informes completos: [llamada-telefonica-review.md](llamada-telefonica-review.md) · [dependencias-r7-review.md](dependencias-r7-review.md).

## GDD 22 «Llamada telefónica»: NEEDS REVISION (1 bloqueante, 12 avisos, 5 info)

**Bloqueante B-1.** El efecto `ESC7_APAGON` de 21 pone `V02` en `vibrando` a los 60 s «si no lo está ya», sin la guarda `¬llamada_iniciada`. Con la llamada en curso `V02` está `en_llamada`, así que 21 puede reiniciar el timbre en plena llamada si el jugador tarda en elegir. 22 no lo cubre en Edge Cases, ACs ni «Cambios requeridos». Arreglo: guarda en 21 y un Edge Case y un AC en 22.

**Avisos principales**
- A-1: dueño del estado de `V02` ambiguo: 21 R15 lo devuelve a `reposo` en «llamada iniciada» y 22 lo pone en `en_llamada`; falta el orden entre los dos escritores y quién ejecuta los «estado de objeto pedido».
- A-2: R30 (reanudación) pone `V02` en `vibrando` pero no pide `SFX_PHONE_BUZZ`: vibra en silencio.
- Estado final: `COMPLETADA` frente a `INACTIVA` (R19, R2 y el encabezado de reglas).
- Dependencias: la cita del índice es falsa (índice: duras 3, 5, 7, 18 y blandas 1, 2; 22: duras 1, 3, 5, 7, 18 y blanda 2). La referencia «cambio nº 8» de 1 no existe.
- F5: «20,4–48,8 s seguiría dentro» de 24–60 s es falso, y «cinco ramas» son cuatro.
- El cambio nº 3(a) a 9 da por cerrado el 10,8 s, que depende de la ambigüedad «+4,0» que 22 deja abierta en OQ nº 1.
- Contradicciones internas: R15 frente al Edge de 9,0 s si 23 no puede interrumpir; AC-22-16 («ninguna otra escritura o aviso») choca con «línea pedida»; R3 y R24 no coinciden en cuándo empieza `HAND_PHONE_HOLD`.
- D22-9 (no colgar) y D22-10 (cursor oculto hasta las opciones) afectan a tono y accesibilidad y no figuran como pregunta abierta.

**Lo que cuadra:** aritmética de F1–F3 (4,8 / 10,8 / 16,4–44,8 s); contratos con 3, 5 y 7; pilares y anti-pilares; sin afirmaciones de Godot ni valores sin † o fuente.

## Dependencias de los 15 GDDs: 0 bloqueantes (85 pares, 13 discrepancias)

Ninguna dependencia dura apunta a algo inexistente y no hay ciclo duro sin declarar. 9↔19 no es circular; 9↔10 y 2↔4 están registradas; 8→20, 19↔21 indirecta, 4↔20, 7↔6 y 5↔9 coinciden.
- A1: 22 declara Dura con 1; 1 y el índice lo anotan Blanda. Por la regla común manda 22 (es el dependiente): 1 y el índice pasan a Dura.
- A3: 6 lista a 1 como «Dura (su lado)» mientras 1 dice «ninguna dura» (leído literalmente, un ciclo duro).
- A4: 22 llama a 7 «dura circular aceptable» pero 7 no depende de 22 (mismo patrón de delegación que 8, 10 y 20, que no se declara circular).
- A5–A7: 2 no lista a 9 ni a 10; 9 no lista a 22; la fila 21 del índice omite a 10.
- A8: la fila 20 del índice se contradice (9 como dependencia y como dependiente).
- A9, A12, A14: citas de «22 sin GDD / pendiente» en 1, 3, 5, 7, 8 y 18; 10 dice «1 no lista a 10»; 6 dice que el índice no lista a 7.

## Decisiones que necesitan al usuario
1. **Repetir/cambiar la respuesta de la llamada.** El slice (D.2, §11.1) no prevé cambiarla; el autor la deja definitiva (guarda de 0,6 s†) y pregunta si «D.2 con la llamada repetible» (decisión de la primera revisión) significaba repetir la llamada tras cargar (lo que hace 22) o poder cambiar la respuesta.
2. **D22-9 no colgar y D22-10 cursor oculto hasta las opciones** (tono y accesibilidad).
3. **Fila «+4,0» de C.7** (línea a 4,8 s frente a 8,8 s que supone 9).
4. Textos pendientes del writer: respiración inicial, `SUB_BREATH_BROKEN`, `VO_G_14_ASG`.
