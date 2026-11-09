# Review F2 - reciprocidad de dependencias (R6-1) - FINAL

Leido: seccion Dependencies de 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 18, 19, 20, 21, 22 + tabla del indice (filas 1-30), Dependency Map y Circular Dependencies.
Convencion: A->B = A depende de B. Dureza "dependiente / proveedor". OK = coincide en GDD dependiente, GDD proveedor e indice.

## Tabla de pares (85 pares con relacion declarada)

| Par | Direccion | Dureza declarada | Estado |
|---|---|---|---|
| 1-2 | 2->1 | Dura / Dura (1) | OK |
| 1-3 | 1->3 | Blanda / Blanda | OK |
| 1-4 | 1<->4 | Blanda cada uno (cada uno declara la suya) | OK |
| 1-6 | 6->1 | 6: Dura (contrato); 1 lista 6 Dura aguas abajo. Pero 6 lista a 1 como dependiente "Dura (su lado)" y 1 dice "ninguna dura" y "Ajustes depende de este sistema y no al reves"; indice 1: "(blandas 3,4,18)" | AVISO (A3) |
| 1-7 | 7->1 | Dura / Dura | OK |
| 1-10 | 10->1 | Indirecta / Indirecta (1 l.404) | OK (10 l.201 dice "1 no lista a 10": obsoleto, A9) |
| 1-18 | 1->18 | Blanda / Blanda | OK |
| 1-19 | 19->1 | Dura / Dura | OK |
| 1-20 | 20->1 | Blanda / Blanda | OK |
| 1-21 | 21->1 | Dura / Dura | OK |
| 1-22 | 22->1 | 22: Dura; 1: Blanda; indice: blanda ("provisional") | AVISO (A1) |
| 2-4 | 2<->4 | Dura / Dura | OK, declarada en indice |
| 2-6 | 2->6 | Blanda / Blanda | OK |
| 2-7 | 7->2 | Dura / Dura | OK |
| 2-8 | 8->2 | Blanda / Blanda | OK |
| 2-9 | 9->2 (via 7) | 9: Blanda; 2 no lista a 9; indice 9 lista blanda 2 | AVISO (A5) |
| 2-10 | 10->2 | 10: Indirecta; 2 no lista a 10 (10 l.202 lo admite); indice 10 lista indirecta 2 | AVISO (A5) |
| 2-18 | 2->18 | Blanda / Blanda | OK |
| 2-19 | 19->2 | Blanda / Blanda | OK |
| 2-20 | 20->2 | Blanda / Blanda | OK |
| 2-21 | 21->2 | Indirecta / Indirecta | OK |
| 2-22 | 22->2 | Blanda / Blanda | OK |
| 3-4 | 4->3 | Dura / Dura | OK |
| 3-5 | 5->3 | Dura / Dura | OK |
| 3-6 | ninguna | Ninguna / Ninguna | OK |
| 3-7 | 7->3 | Blanda / Blanda | OK |
| 3-8 | 8->3 | Dura / Dura | OK |
| 3-9 | 9->3 | Dura / Dura | OK |
| 3-10 | 10->3 | Dura / Dura | OK |
| 3-18 | ninguna | 18 l.206/225 dice que 3 "ya lista" a 18; 3 no tiene fila de 18 (solo "2 y 18 no usan el bus") | INFO (A11) |
| 3-19 | 19->3 | Dura / Dura | OK |
| 3-20 | 20->3 | Dura / Dura | OK |
| 3-21 | 21->3 | Dura / Dura | OK |
| 3-22 | 22->3 | Dura / Dura | OK (3 l.189 aun lista 22 como "pendiente de redactarse": obsoleto, A12; hechos/avisos leidos difieren, A16) |
| 4-5 | 5->4 | Dura / Dura | OK |
| 4-6 | 4->6 | Blanda / Blanda | OK |
| 4-7 | 7->4 | Dura / Dura | OK |
| 4-8 | 8->4 | Dura / Dura | OK |
| 4-9 | 9->4 | Dura / Dura | OK |
| 4-10 | 10->4 | Dura / Dura | OK |
| 4-18 | 4->18 | Blanda / Blanda | OK |
| 4-19 | 19->4 | Dura / Dura | OK |
| 4-20 | 20->4 | Dura / Dura | OK |
| 4-21 | 21->4 | Dura / Dura | OK |
| 5-8 | 8->5 | Blanda / Blanda | OK |
| 5-9 | 9->5 | Blanda (la declara 9) / Blanda; 5 no depende de 9 | OK |
| 5-10 | 10->5 | Blanda / Blanda | OK |
| 5-18 | 5->18 | Blanda / Blanda | OK |
| 5-20 | 20->5 | Indirecta / Indirecta | OK |
| 5-21 | 21->5 | Blanda / Blanda | OK |
| 5-22 | 22->5 | Dura (contrato) / Dura | OK |
| 6-7 | 7->6 | Blanda / Blanda | OK (6 l.232 dice que indice 7 "aun no lo lista": obsoleto, indice ya lo lista, A14) |
| 6-9 | 9->6 | Blanda / Blanda | OK |
| 6-18 | 6->18 | Blanda / Blanda | OK |
| 6-19 | 19->6 | Blanda / Blanda | OK |
| 6-21 | 21->6 | Blanda / Blanda | OK |
| 7-8 | 8->7 | Dura / Dura | OK |
| 7-9 | 9->7 | Dura / Dura | OK |
| 7-10 | 10->7 | Dura / Dura | OK |
| 7-18 | 7->18 | Dura / Dura | OK |
| 7-19 | 19->7 | Dura / Dura | OK |
| 7-20 | 20->7 | Dura / Dura | OK |
| 7-21 | 21->7 | Blanda / Blanda | OK |
| 7-22 | 22->7 | Dura / Dura; 22 l.187 la llama "dura circular" pero 7 no depende de 22 ni el indice la registra | AVISO (A4) |
| 8-9 | 8->9 | Blanda / Blanda (9 l.476) | OK |
| 8-18 | 8->18 | Dura / Dura | OK |
| 8-20 | 8->20 | Dura / Dura; indice lo dice | OK |
| 8-21 | 8<->21 | Blanda cada uno (bus) | OK, declarado |
| 8-22 | 8->22 | Blanda / Blanda | OK |
| 9-10 | 9<->10 | Dura / Dura circular | OK, declarada (9, 10, indice) |
| 9-18 | 9->18 | Dura en validacion / idem | OK |
| 9-19 | 9->19 (unidireccional) | Dura / Dura; 19 NO depende de 9 -> no es circular | OK (INFO: no hay ciclo 9-19, A20) |
| 9-20 | 9->20 | Blanda / Blanda; indice fila 20 lista 9 como dependencia de 20 (contradice) | AVISO (A8) |
| 9-21 | 21->9 | Indirecta / Indirecta | OK |
| 9-22 | 22->9 (bus) | 22: Indirecta; 9 no lista a 22; indice 22 no lista 9 | AVISO (A6) |
| 10-20 | 20->10 (segun 20) / indice dice 10->20 | Blanda / Blanda; direccion contradictoria (10 no consulta a 20) | AVISO (A8) |
| 10-21 | 21->10 (21) / 10->21 (10 e indice 10) | Indirecta / Indirecta; indice fila 21 omite 10 | AVISO (A7) |
| 18-19 | 19->18 | Dura / Dura | OK |
| 18-20 | 20->18 | Dura / Dura | OK |
| 18-21 | 21->18 | Dura / Dura | OK |
| 18-22 | 22->18 | Dura / Dura | OK (18 l.206/225 aun trata 22 como "sin GDD", A12) |
| 19-20 | 19->20 | Dura / Dura | OK |
| 19-21 | indirecta via 7 | Indirecta / Indirecta; sin API | OK |
| 20-21 | 21->20 | Indirecta / Indirecta; indice fila 20 lo lista tambien como dependencia de 20 | INFO (A8) |
| 21-22 | ninguna | Sin dependencia / Sin dependencia | OK |

Pares sin relacion, confirmados en ambos lados: 1-5, 1-8, 1-9, 2-3, 2-5, 5-6, 5-7, 6-8, 6-10, 6-20, 6-22, 4-22, 8-10, 8-19, 10-19, 20-22.

## Ciclos duros
Registrados y coherentes: 2<->4, 9<->10. Sin ciclo: 9->19->20, 8->20, 9->19 (19 no depende de 9), 22->5->{3,4}. Soft mutuos (1<->4, 8<->21) declarados o inocuos.
Sin ciclo duro no declarado confirmado. Candidatos dudosos: 22<->7 (A4) y 1<->6 (A3), ambos desmentidos por el texto del otro GDD.

## Discrepancias

BLOQUEANTE: ninguna. Todas las dependencias duras apuntan a GDDs existentes (22 -> 1,3,5,7,18 existen); las citas a 23, 26, 24, 25, 27, 28, 30, 17 son sistemas planificados del indice, no referencias a algo inexistente.

AVISO
- A1 22<->1. 22 l.173 Dura ("22 ... 1 la anota Blanda"); 1 l.396 "22 Llamada | Blanda"; indice fila 22 y Map l.123 "blandas 1, 2". Por R6-1 manda 22 (dependiente): corregir 1 y el indice a Dura. Ademas 22 l.169 cita el indice como "duras 1,3,5,7,18; blanda 2" y eso es falso hoy (A2). 1 l.407 enumera 19,21,20,10 pero no 22.
- A2 Indice fila 22 y Map l.123: "provisional: su seccion Dependencies esta pendiente" obsoleto (22 ya la tiene). Ademas 22 lista 9 (indirecta), 8, 21 (sin dep.), 23, 26 que el indice no refleja (8 y 9 ver A6).
- A3 1<->6. 6 l.228 lista 1 como dependiente de 6 "Dura (su lado)" junto a 6 l.209 (6->1 dura de contrato); 1 l.383 dice "Ajustes depende de este sistema y no al reves" y "ninguna dura" aguas arriba; indice 1 sin 6. Leido literal seria ciclo duro 1<->6. Aclarar: quitar la fila 1 de la tabla aguas abajo de 6 o redactarla como "contrato, no dependencia de 1".
- A4 22<->7. 22 l.187: "dura circular aceptable (7 delega en 22 el verbo)". 7 no lista a 22 aguas arriba (solo como dependiente, 7 l.430) y el indice (Circular Dependencies) no la registra. Mismo patron en 7<->8, 7<->10, 7<->20 (manejadores delegados) que no se declaran circulares. Quitar "circular" de 22 o registrar el patron una vez en el indice.
- A5 2 no lista a 9 ni a 10 aguas abajo (2 l.292-302), pese a que 9 (Blanda via 7, l.458) y 10 (Indirecta, l.202) declaran dependencia de 2 y el indice 9 e indice 10 las listan. 10 l.202 ya lo reconoce.
- A6 9<->22. 22 l.181 declara 9 "Indirecta (por el bus)" y cita "9, tiempos (llamada), regla 20"; 9 Dependencies (aguas arriba/abajo) no lista a 22; el indice fila 22 tampoco lista 9.
- A7 21<->10. 21 l.201 y 10 l.200 declaran Indirecta ambos; indice fila 21 "indirectas 2, 9, 20" omite 10; indice fila 10 lista "indirectas 1, 2, 21". Direccion contradictoria entre filas (21 dice 21->10 leyendo caja_completa; 10 dice 10->21).
- A8 Indice fila 20 inconsistente consigo misma: "blandas 1, 2, 9, 10" y "dependen de 20: 8 y 19, 9, 17 y 24" (9 en ambos lados); Circular Dependencies dice "9<->20 blanda en un solo sentido declarado por 9". 20 l.211 confirma 9->20. Fila 20 tambien lista 10 y 21 como dependencias de 20 mientras la fila 10 lista 20 como dependencia de 10 (10 l.197 "la caja no consulta has_item": 10 no consume 20) y la fila 21 lista 20: bidireccionales en el indice sin estar en Circular Dependencies.
- A9 10 l.201 "1 no lista a 10": obsoleto (1 l.404 la lista como Indirecta).
- A12 Textos "sin GDD / pendiente" obsoletos respecto a 22: 1 l.411; 3 l.189; 5 l.337 (ademas "regla 10 del GDD del 3 ... pendiente" ya resuelto en 5 l.335); 7 l.435; 8 l.202; 18 l.206 y l.225.
- A14 6 l.232: "7 declara a Ajustes como blanda pero su fila del indice aun no lo lista": el indice ya dice "(blandas: 3, 6)".

INFO
- A10 Indice: Map l.128 28 = "2, 3, 21" vs tabla fila 28 = "2, 3, 6, 21" (6 l.220 y 9 l.478 lo listan como dependiente de 28/29).
- A11 18 dice que 3 lo lista; 3 no tiene fila de 18.
- A13 21 l.181 "Dependencias del indice: 1,3,4,18 y 5 ... propone reflejarlo (7)": obsoleto, indice ya tiene blandas 5,6,7,8 (falta 10 indirecta, A7).
- A15 8 l.195 y l.202 citan "9 L459" para la dureza de 8 en 9; esa fila esta en 9 l.476 (l.459 es 18).
- A16 3 l.179 fila 22: "lee carta_variante; emite llamada iniciada/completada"; 22 l.175 dice que ademas lee t4_decision, caja_completa, llamada_completada y emite "linea pedida". Hechos/avisos no coinciden entre filas (dureza si coincide).
- A17 5 l.330 agrupa "9 a 16" como Blanda; 3 dice 11-16 Indirecta via 9; 9 dice 11-16 Dura (aguas abajo de 9). Tres lecturas para 11-16 (no hay GDD 11-16 aun).
- A18 Sistemas sin GDD citados por GDDs pero ausentes de la fila del indice: 25<-3 (3 l.181), 24<-6, 24<-20, 28<-6, 28<-9, 23<-22, 23<-9, 23<-10, 26<-9, 26<-22, 17<-20, 11-16<-5. Se resolvera al redactar cada GDD.
- A19 Circular Dependencies no menciona soft mutuos 1<->4, 10<->20 ni indirectos 10<->21, 20<->21 (ver A8).
- A20 9<->19: no es circular (19 no depende de 9; 19 l.184 "9->19"); el indice lo dice bien ("9 depende de 19, dura").

## NO LEIDO
- Secciones fuera de Dependencies (Interactions, Cambios requeridos, Open Questions) de todos los GDD; reglas/AC citados (5 reglas 10-12/28/29 y AC-34, 22 reglas 6/7, 7 regla 3, 21 reglas 4/14/15/17, 18 regla 22...) no verificados.
- GDDs 11-17 y 23-30 (no existen). design/registry/entities.yaml. Resto de lineas del indice (cabecera, notas de revision, Progress Tracker salvo l.206-216).
- 3 (Dependencies) leido solo l.160-189; no comprobado si otra seccion de 3 lista a 18.
