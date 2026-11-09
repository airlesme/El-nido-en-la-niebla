# Borrador review GDD 15 (parcial)
Leido: GDD 15 entero; 9 reglas 4-30, F2, F7-F9; 13 grep; indice fila 15.
Verificado OK: F-P5-1..5 aritmetica (16,0; 7,5; 5,73; 54,8/186,8; 18,8/20,8; F9 15,10/33,36). Reglas 15,17,18,19,20,24,25,26,29 de 9 existen y dicen lo citado. ACs de 9 citados existen.
AVISO: AC-P5-04 (7,6 deg/s y 15,2 deg/s "no resuelve") flaky: 6/(7,6/60)=47,4 fotogramas -> 47 o 48 segun fase; 48 fotogramas resuelve (48/60=0,8>=0,8-eps).
AVISO: 13 SI esta redactado (13 regla 23 ya dice que su imagen final es la que reutiliza P5), 15 lo da por no redactado; 13 no lista a 15 como dependiente (reciprocidad).
AVISO: 9 regla 14b(b) solo cubre FADE; 15 extiende 100 ms a OUTLINE.
AVISO: 14b(c) dice entreabierto lo resuelve el controlador; 15 dice 10.
AVISO: AC-P5-19 (1,5-3 min incluida revelacion) contradice literal F7 ("mas ~16 s") hasta que 9 cambie (listado en Cambios).
Pendiente: 7, 6, 5, 3, 10, slice, pilares, indice reciprocidad.

---
## Informe final del revisor (respuesta de cierre)

**Veredicto: NEEDS REVISION** (0 bloqueantes, 10 avisos). Todas las referencias «regla N / AC-N de 9» comprobadas existen y dicen lo citado (15 a 20, 24 a 26, 29, 14b, F8, AC-03/05/11/20 a 22/41/45/46/52 a 54/X3/X4); sin contradicción directa con las reglas 17 a 19 ni con F8. Cifras cuadran: revelación 16,0 s, D-W3 (7,5°/s, 5,73 s), F7 (54,8 a 186,8 s), F9 (15,10 y 33,36 min; 18,8 y 20,8 s).

**Avisos**
1. AC-P5-04 inestable: a 7,6°/s caen 47 o 48 fotogramas en la ventana según la fase, y 48 ya resuelve (0,8 s); lo mismo a 15,2°/s. Usar velocidades con margen (8°/s y 16°/s) o fijar la fase.
2. La dependencia ‡ de 13 se puede quitar: 13 existe y su regla 23 deja `slot_6` vacío y «la imagen que reutiliza la secuencia del P5». Lo que 15 espera es un recurso de arte, no un contrato de lógica (blanda/contenido). 13 no lista a 15 como dependiente.
3. Reciprocidad incompleta: 10 no menciona a 15; 13 no figura entre los documentos a actualizar.
4. La regla 14b(b) de 9 solo cubre `FADE`; 15 extiende los 100 ms a `OUTLINE` sin pedirlo.
5. La regla 14b(c) de 9 dice que el entreabierto lo resuelve el controlador; 15 dice que lo resuelve 10.
6. El paso de §10.5 («solo queda visible Vera») a B.5 (superposición más contorno) no está en «Decisiones tomadas»; solo se registra la descartada «si falla, reinicia» (D15-1).
7. AC-P5-19 contradice F7 literal («más ~16 s» frente a 1,5–3 min «incluida» la revelación); queda así hasta que 9 acepte el cambio (está en Cambios).
8. `request_hint` durante `RESOLVING` no está definido en 9 (solo valida «ACTIVO»); AC-P5-12 afirma «sin efecto» sin respaldo.
9. `MARK_LIT` y `HIGHLIGHT` sobre elementos visuales no interactivos: 9 no los admite hoy (reglas 25 y 29); tampoco `on_reject: null` ni `solution.visual_elements`.
10. `T_ent` de 1,0 s ignora la animación `BOX_C3_OPEN` (13 usa 2,6 s para C1); «todas con fuente 9» es inexacto en el registro.

**INFO:** 10 se contradice (línea 95 deja C3 `ABIERTO`, líneas 63 y 72 `ENTREABIERTO`); las 7 preguntas abiertas están bien planteadas (`VO_G_07` afirma un acto del Guardián: decide el creative-director, pilares 1 y 5); `reducir_sobresaltos` bien tratado.

**No leído:** slice Anexo A y C.6, art bible, GDDs 23, 26, 29 y 17 (no existen), 2 y 3 más allá de grep, líneas largas de 7; de 5 solo la fila de `reveal_pending`.
