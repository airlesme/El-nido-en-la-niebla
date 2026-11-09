# R6-3 informe final
## F9 aritmética (marco-de-puzles.md L365-380)
- Mín: 10,5+0,8+2,0+0,4+1,0+0,1+0,2 = 15,0 OK. Máx: 22+0,8+5+1+3+1+0,4 = 33,2 OK. Escenas 15,0+7,0+25,8 = 47,8 s OK (25,8 = 8+3+8+2+0,8+3+1, 21 F3).
- ERROR menor: "13,5 min solo con puzles, escenas y ~2 min" = 10,5+0,8+2,0 = 13,3 (L378, L380, OQ10 L745, D9-61 L729). 13,5 viene de r5 (que sumaba ~1 min de lectura).
- AVISO: cargas mín 0,2 min (12 s) < su fuente (11,7 s + traspaso 12 s = 23,7 s ≈ 0,4); mín incoherente.
- AVISO: escenas "fijas" falso: 25,8 s de ESC8_CIERRE usa t_linea_max_s 8,0 s (tope) y h_decl 1,0 s; las duraciones declaradas incluyen margen. Real C.8 ≈ 3+3+2+0,8+3 + voz. Mín sobreestimado ≈ 0,3 min, no cambia el veredicto.
- Componentes: no olvidados graves; faltan (INFO) animaciones de puerta 1,2 s x3, VO_V_08 6 s y D01c VO_G_07 (esta en F7 P5), regreso al ordenador/impresora (en P1). "Exploración 2-5 min†" y "lecturas 1-3 min†" son lo que decide el total y no tienen fuente: marcados †.
## Compatibilidad con textos 25-30 min
- slice L6 "Alcance 25 a 30 minutos", §19.1 L448, game-concept L24 y L110: afirman 25-30; F9 los marca no demostrados (mín 15, techo 33). Hay que escalarlo: OQ10 lo recoge (a/b/c, decide usuario) pero NO dice que incluso el máximo de puzles + mínimo del resto (≈15) queda ~10 min bajo 25 ni que la mediana esperable (~24) roza el límite inferior; ni propone dato por defecto. AVISO (casi BLOQ para presentar el slice).
- BLOQUEANTE-menor/AVISO: slice §22 L495 "Ninguno requiere más de dos minutos" contradice F7 (P1 2-4, P2 3-6, P3 1,5-3, P4 2-4). F9 no lo señala.
- Slice §23 L509 playtest de cinco personas vs AC-X5 ≥6 testers.
## AC-X5 (L662)
- Verificable a medias: mide total + 7 componentes, ≥6 testers, mediana, umbral 25-30 solo para el total. Faltan: método de cronometraje (log de eventos del bus, hitos concretos de inicio/fin por componente), qué es "mediana por componente" vs rangos †, regla de exclusión (guía externa, pausas), qué hacer si 1-2 caen fuera. Con n=6 la mediana es poco robusta. AVISO.
- Otros ACs de tiempo: no hallé AC en 21/10/19/8 que fije duración total del slice; AC de 8 AC-09/10 (2,0 s) y 10 AC-21 (T_cadena 2,8 s) son locales y no chocan. Marco F7 vs slice §22: sí choca (arriba).
## Diseño / pilares
- Tensión sin castigo: EN_USO 20 s† (control-de-acceso L215) sin icono ni feedback: solo ocurre si 21/4 fallan; si ocurre, 20 s de "puerta muerta" sin pie; AVISO bajo, pedir pie/ruido de ascensor ocupado. MEGA_03: sin castigo, cooldown 8 s†, silenciada en apagón/llamada (D8-18) OK. Presentación de tarjeta ≈1,3 s por tarjeta (n≤2 ⇒ ≤2,6 s, T_bloqueo ≤1,6 s†): sin control breve, no castiga; OK.
- NOT historia explicada: VO_G_13B "Lo sé" (D18-10) cumple. MEGA_03 / UI_BOLSILLO_AYUDA / asuntos de MAIL_1-4 / VO_G_14_ASG provisionales con marcador de pendiente: OK mientras el verificador (18 regla 16) bloquee en --hito=calidad. INFO.
- T4 acepta devolver o asignar (18 L161, D-B1) sin "No corresponde": pilar autonomía OK.
- D-W (r5 L46): vigentes D-W1 (P1, T1-T3), D-W4 (más fuerte con B.1 literal; slice L738 lo confirma: pistas 2-3 vacías, P1 solo distinguible por día, A-C1), D-W5, D-W8, D-W9, D-W10, D-W11; cerrado D-W6; D-W7 parcial; D-W2/D-W3 no reverificables. No vi cambio desde r5; D-W4 sigue sin mitigación de diseño: riesgo de frustración en P1 (el primer puzle) y de bajar la tasa de sin-pista, sube tiempo P1 por encima de 4 min†.
## Valores sin fuente ni †
- documentos-y-bolsillo.md L331-332 (registro): t_mostrar_item_s 0,7 s, t_tapa_s 0,6 s sin † (en Tuning L230-231 sí lo llevan).
- control-de-acceso.md L329, L333, L334: card_read_delay_s 0,5, drawer_a05_open_s 1,0 ("propuesta" sin †), door_open_angle_deg 90; L331-332 elevator_deny_line_cooldown_s 8 y elevator_in_use_timeout_s 20,0 sin † en la tabla de registro (en L214-215 sí).
- ordenador: t_busqueda 0,4 (slice C.2) y t_impresion 1,5 (slice V08): fuente OK.
- F9: duración de respuesta de El Guardián "≈ 4 s†" ok; 60 s† ok.
- No inspeccionados a fondo: 10 caja (Tuning Knobs), 19 Tuning completo, 20 R12.
## NO LEÍDO
caja-y-compartimentos.md (solo AC-21), ordenador-correo-impresora.md (Tuning, solo L200-201), documentos-y-bolsillo.md (solo L162-163, 230, 318-347), director-de-escenas.md reglas completas (solo F3 y constantes), gdd-cross-review r4, reviews/cross-review-r5-C.md, slice §11/§13, systems-index.md, game-pillars.md.
