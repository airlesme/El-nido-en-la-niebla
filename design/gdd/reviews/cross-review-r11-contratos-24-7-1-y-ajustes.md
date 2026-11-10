# Revisión R15-2 (final)
VEREDICTO: R9-B4 PARCIAL; R9-B5 CERRADO; R9-B6 CERRADO.

BLOQUEANTE: ninguno.

R9-B4
- OK: 7 tiene anillo_visible (D7-73, AC-36c), duracion_pie (D7-75, AC-15b), resultado ampliado (D7-74), mostrar_pie (24 r22); 1 tiene get_binding_label(accion, dispositivo)->{tipo,texto,glifo_id} (r24, AC-E19, D34). Firmas idénticas en 24/1/7.
- AVISO: 23 (director-de-audio.md) y 28 (atmosfera-reactiva.md) no contienen «interacción ejecutada» ni `HECHO` (Grep); 7 fila 706 sigue pidiendo «solo HECHO» a 21/23/28. El filtro no está escrito en 23 ni 28.
- AVISO: 21: solo el changelog (l.371) dice «filtro HECHO»; AC-21-15 (l.249) y ESC1_MENSAJE (l.43) no lo dicen (l.71/73 largas no leídas).
- AVISO: 24 conserva ‡ sin motivo: icono_grande/etiqueta_accion_visible (l.29, 39, 78 «pendientes de alta en 6», 131, 158-159, 251-252) aunque 6 y el registro ya los tienen; cabecera l.8 dice «abiertos solo de 6 y 18». 30 l.153/157 aún «escala_texto_ui †, subtítulos ‡». 25 l.427 «hoy solo desde Sin partida ‡» pero 5 ya lo aplica (l.146, 160, D-54).
- INFO: 7 l.437 «24 Dura» está en «Aguas abajo» (24 depende de 7); índice fila 7 no lista 24: sin ciclo 7↔24.

R9-B5
- 27 l.138 Dura a 30; 30 l.158 y D30-17 Blanda a 25/27; índice filas 27 y 30 coinciden; 25 l.250-251 coherente (27 Dura declarada por 27, 30 Blanda). 25→27/30, 17↔25 (17 declara Blanda a 25; 25 no depende de 17), 23↔26, 28↔29 (28 no depende de 29), 29→15 (dura, la declara 29): coinciden con el índice. Sin ciclo duro en 23-30/17.
- INFO: 30 declara a 26 Dura y 23 Dura para AC-30-11; 23/26 no dependen de 30: sin ciclo.

R9-B6
- Sin 0,15 s para el fundido reducido. Los 0,15 restantes son otros conceptos (parpadeo de 28, ataque de ducking 23, t_freno 2, guarda_apertura_s 25, tope reflejo 29, fundido normal de 26/24 de 150 ms). 27 F1 l.102 = 0,1 s; t_atenuacion_s retirada (D27-22); AC-17 = 3,8/3,1 s correcto; AC-18 = 100 ms.
- INFO: rango de fade_reducido_ms en 24 = 50-150 (l.148) frente a 50-200 de 15/30 (l.174): informativo, no contradice el valor.

Ajustes
- Registro l.3537: 18 claves listadas (3 vol + 4 subt + 2 + 2 asist + balanceo + FOV + 2 pie + 3 nuevas = 18); 6 AC-01 = 20. 25 D25-24/l.233, 30 AC-30-01, 6 l.106 citan 18. «12 claves» solo en historia (6 l.407, decisión ronda 5; reviews antiguas): INFO.
- Orden de Accesibilidad de 25 AC-25-23 = 30 regla 6 (lectura, confort, ayudas). OK.

«Continuar/Reanudar» y «Nueva partida»
- 25 r30/r31, AC-25-58 y 27 (tabla l.32-39, `desconocido` = confirmación siempre, regla 11) coherentes; 5 acepta nueva_partida() desde «En partida».
- AVISO: 1 (l.65-67) y 21/4 aún dicen «pausa → Nueva partida o Continuar»; 25 r31 lo reinterpreta como carga ajena, pero 1/4/21 no se han editado (25 l.430 lo registra como cambio pendiente).

NO LEÍDO: líneas largas omitidas de 21 (71, 73, 262-263, 305-335), 27 (l.10, 63, 67, 75, 110), 25 (l.10, 47, 89, 121, 309, 316), 24 (l.31, 66-71, 206), 6 (l.3, 67, 329, 418), 1 (l.51-54, 514-520, 584-596); cuerpos completos de 23 y 28 (solo Grep); reviews/ antiguos.
