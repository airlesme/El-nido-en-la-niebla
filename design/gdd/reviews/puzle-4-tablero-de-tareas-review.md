# Revisión independiente GDD 14 · Puzle 4 Tablero de tareas

## VEREDICTO: NEEDS REVISION

Recálculos correctos: F1 (3·3+1 = 10; 10^4; (1/10)^3 = 0,001); F2 (peor 8·0,8+0,4 = 6,8 s; T_peor 3·(6,8+0,8) = 22,8 s; medio 4,5·(6,8/9) ≈ 3,4 s; T_medio 12,6 s; mínimo 2,4 s); F3 (nominal 2,4+5+3·(30+12)+45+0+2 = 180,4 s; mínimo 89,4 s; máximo 2,4+5+3·(60+36)+90+30+2 = 417,4 s). 7 elementos × 4 fichas = 28; 28+4+1 = 33 IDs; 28 AC. Las 8 secciones están presentes.

## BLOQUEANTE

1. P4-F4: «`p_oir` ... (lo mide 22; ver su F3)» y «para que el registro de 9 (regla 32) los calcule». La F3 de 22 es una tabla de duraciones y no mide `p_oir`; la regla 32 de 9 registra por puzle (tiempo hasta resolver, intentos/rechazos, pistas, cierres), no por ficha ni `t4_decision`. Contrato citado que no existe y no figura en «Cambios requeridos» (el punto 5 dice «sin cambio de comportamiento» para 22; el 1 no menciona la regla 32). Afecta a AC-14-26 (`r_T4`, `p_RET`) y a la mitigación de D-W10.

## AVISO

- `value_from`/`map` en `on_solved.write` NO existe en el esquema de 9 (regla 4: `on_solved` = «hechos a escribir en orden»; ejemplos `{flag, value}`). La regla 12c de 9 solo dice «es un dato de la definición». El GDD lo admite («extensión propuesta») y lo lista en Cambios 1(a): no bloqueante, pero 14 no es implementable tal cual hasta que 9 lo acepte.
- Tampoco están en la regla 4 de 9: `on_partial.stamp_text_keys`, `elements.{atraccion_desactivada, min_separation_px}`, `on_reject.{message_key, message_s, applies_to}` y el campo `name` de `AFFORDANCE`. Falta añadirlos a Cambios 1(a). (`atraccion_desactivada` sí existe en 7 regla 22 y 9 regla 29).
- El veredicto `PARTIAL` no lleva ficha ni acción en 9, pero el sello depende de ella (R10).
- `shake_s` = 0,4 s† (D14-12 y datos) no figura en Tuning Knobs; `message_s` en datos frente a knob `no_corresponde_s`.
- Asimetría en T4: «Devolver» = 1 clic y sella al instante de forma irreversible; «Asignar» = 2 clics. Riesgo de clic erróneo en un hecho de un solo sentido (Pilar 3) y empuje a devolver, que se suma a D-W10. Sin confirmación ni deshacer (P4-R5, E5).
- Sellos idénticos «ACEPTADA»/«DEVUELTA» (P4-R10, D14-3, AC-14-09): respeta Pilar 1 (solo cambia la palabra, sin color ni sonido distinto). Matiz: «DEVUELTA» solo aparece en T4, tras ver «No corresponde» ante «Devolver» en T1–T3; el propio GDD lo reconoce (sesgo de orden, P4-F4).
- AC-14-25 exige mediana 2–4 min, pero P4-F3 define alerta solo fuera de 1,5–5 min: umbrales inconsistentes.
- P4-F2 vs P4-F3: `t_fallo` suma 1,5 s de «No corresponde» aunque `lock: NONE` no bloquea la entrada (P4-R8).
- D14-13 («3 filas × 128 px por ficha no caben en dos filas de fichas en 1080 px») es débil: 2×(384+cuerpo) cabe en 1080 px.
- Sin AC para P4-R11, R14, E5, E7, E8, E10.
- Cita «F5b de 7»: F5b es de Entrada (regla 22 de 7 la cita).
- `systems-index.md` línea 277 obsoleta («14 Puzle 4 (GDD aún sin redactar)»); no está en Cambios 7. Reciprocidad: 9, 10 y 22 aún no citan a 14 (cubierto por Cambios 1(c), 3 y 5); 18 sí (fila «14 Puzle 4»).

## INFO

- D-W10: queda como Open Question 2 (decisión del usuario/narrative-director, cambia alcance de 22 y del slice) y se mide en P4-F4: tratamiento correcto, no decidido por el autor.
- «No corresponde» solo en T1–T3: coherente con slice B.4, 9 regla 12c/AC-57, 18 D18-9 y 22.
- Discrepancia §10.4 (nivel 1 = «marca de color para la urgencia», slice línea 198) frente a B.4 (línea 871, regla visible): el autor sigue B.4 (D14-9) y la registra (OQ 3, Cambios 8); verificada y correcta. Nivel 3 §10.4 («regla ejemplificada con Cliente Lima») es compatible con B.4.
- `VO_G_14_ASG` no redactado: bien (OQ 4). Orden de escritura (R13) coincide con la regla 16 de 9; reglas 11b, 13b, 14b, 21, 22, 25–27, 29, 35, 36 de 9; 7 reglas 20–22; 10 regla 17, AC-06b; 18 reglas 1/20/23, D18-9; 20 R5/R6: existen y dicen lo citado.
- Valores sin † o fuente: todos tienen † o cita del slice.

## NO LEÍDO

Detalle del Pilar 3/4 (solo cabeceras), GDD 17 y 16, GDD 5, slice D.2 completo, F6/F7 de 9 (solo línea 358 y menciones), reglas 3 y 14 de 9 por completo, GDD 20 R5/R6 solo por Grep, AC de 10/20/22 más allá de los citados.
