# R14-F borrador

## 1. ACs incompatibles / mal tipados (leídos: ACs completos de 23, 24, 25 (hasta AC-25-31), 26, 27, 28, 29, 30)
- BLOQUEANTE? 27 AC-18 «con reducir_movimiento o reducir_sobresaltos, los fundidos duran t_atenuacion_s (0,15 s†)» vs 30 AC-30-12 «reducir_movimiento activa → fundidos duran 100 ms», 25 AC-25-08 (0,10 s), 26 AC-26-20 (0,10 s), 24 AC-24-16 (100 ms), 29 AC-1 (100 ms). 27 usa 0,15 s y además añade reducir_sobresaltos; no pueden pasar a la vez (30 es AC global que incluye pantallas de 27). 27 AC-17 «3,15 s con reducir_movimiento» depende de 0,15.
- AVISO: 30 AC-30-02 dice que «sustituye al orden de 25 AC-25-23 y AC-25-12», pero AC-25-23 sigue listando 8 claves en «Accesibilidad» sin icono_grande/etiqueta_accion_visible/escala_texto_ui, y AC-25-27 «las 12 claves» vs AC-30-01 «18 claves». AC-30-01 está BLOQUEADO; hasta aplicar cambios en 25 y 6 son incompatibles.
- AVISO: 30 D30-7 mete subtitulos_tamano/fondo/hablante en «Sonido y pantalla»; AC-25-23 lista ahí solo subtitulos_activos (y «no hay claves de pistas»).
- AVISO: nombre del aviso de pausa: 25 AC-25-50 «pausa cerrada» y 28 R22 «pausa cerrada»; 23 AC-23-18/AC-23-32 `pause_closed`. Dos nombres para el mismo aviso.
- AVISO: umbrales de destello distintos: 29 AC-15 (par > 0,25 de luminancia en 333 ms), 30 AC-30-13 (≥ 10 % relativo, área > 25 %), 28 AC-28-21 («≤ 3 cruces de ±10 %/s») vs AC-28-02 («≤ 3 destellos/ventana»; cruce ≠ destello). Metrica sin unificar.
- AVISO tipado: 27 y 29 no tipan ningún AC (sin L/I/PV); leyendas distintas: 23 L/I/V/P, 24 L/V, 25 L/I/UI, 26 L/I/V, 28 U/I/V/P, 30 L/UI/H/I. 28 AC-28-17 «29 no existe» es condicional pero exige AC-28-16 cuya cierre depende de un spike (AC-28-16/19 pendiente) → AC no cerrable hasta spike.
- AVISO no testeable: 30 AC-30-13 «PEAT no verificada»; 27 AC-14 «un cambio de volumen persiste» sin tipo; 27 AC-22 («nunca») no acotado; 29 AC-5 playtest 3/3 sin tipo.
- INFO: 27 ACs desordenados (AC-23..26 antes de AC-19..22). 24 AC-24-21 antes de AC-24-19. 28 AC-28-22 al final.
- INFO: 24 pie ≥ 20 px (AC-24-14) vs 25 AC-25-18 ≥ 24 px a 1080p y 19 PA-3 «mínimo 24 px» (citado en D30-4): pie de 24 es más pequeño que el mínimo de 30 (D30-4). AVISO.
- 28 GPU ≤1,0 ms (AC-28-19) + 29 ≤0,5 ms (AC-18): suma 1,5 ms sin presupuesto global. INFO.

## 3. Textos obsoletos (hallazgos, todos AVISO salvo nota)
- 25-30 min: CLAUDE.md:9 y README.md:4 dicen «25–30 min» (slice-v0.3 L6 dice ~15–30 y «no se afirma 25–30»). AVISO (CLAUDE.md es del usuario; README editable).
- ajustes-persistentes L229: «24 Pie de texto ... Blanda (sin GDD aún)» (24 existe y es Prompt de interacción; el pie es de 26). AVISO.
- ajustes-persistentes L375: «Menú de pausa (25), sin GDD» (existe). AVISO.
- director-de-escenas L339: «23 Audio · 28 · 27 · 25 (por redactar)» — los 4 existen. AVISO.
- documentos-y-bolsillo L221: «17 Pistas (sin GDD)». AVISO.
- puzle-1 L490: «17 Sistema de pistas (sin GDD)». puzle-6 L138: idem. AVISO.
- puzle-5 L396: «Responsable: 23 (aún sin GDD)». AVISO.
- sistema-de-pistas L214 y L386: «25 Menú de pausa (sin GDD)» / «dependen de 25 (sin GDD)». AVISO.
- llamada-telefonica L9, L193, L194, L288, L323: «23 y 26 (sin GDD)». AVISO.
- base-de-contenido-narrativo L242: «Los que aún no existen (11–17 y 23–27)». AVISO.
- estado-y-bus L88 y L298: «aún no tiene GDD (17, 23 a 28)». AVISO.
- systems-index L239, L250, L273: secciones «sistemas sin GDD todavía» (revisar contenido). L22 fila: «23 y 26 (sin GDD)» (índice L46).
- interaccion-e-inspeccion L31, escena-de-planta L27: «aún sin redactar» genérico en leyenda ‡. INFO.
- BOX_Cn_OPEN: solo como «sustituida» en ajustes-persistentes; caja L128 notación genérica explícita. OK.
- «19 hechos»: solo históricos en reviews. OK. «repasar bolsillo»: solo en decisiones (D18-26, D-44). OK.
- «no existe» sobre 23-30: solo AC-28-17 (condicional «29 no existe en el árbol», es prueba, OK).
- Residuos históricos en reviews/ y gdd-cross-review-*.md (r2–r8): no se cuentan (son informes fechados).
- marco-de-puzles L520: «23 Director de audio | Blanda (‡)» — 23 existe; la ‡ de «propuesta» sigue puesta. AVISO bajo.
- 27/25/26: el índice (systems-index L22 fila 22 «23 y 26 (sin GDD)») y L239/L250/L273 («sistemas sin GDD todavía»): no leí el contenido de esas secciones; probable obsoleto para 17, 23–30. NO CONFIRMADO.

## 2. Referencias muestreadas (SOLO 21 verificadas; NO se llegó a 80)
OK (destino existe y dice lo citado):
1. 25 AC-25-09 → 6 AC-14d (temporizador de guardado en tiempo real).
2. 25 AC-25-09 → 22 AC-22-11 (12 s de espera, señal 8 s de juego después).
3. 25 AC-25-03 → 6 AC-14c (escribe al abrir menú).
4. 25 AC-25-04 → 5 AC-09 (`cause` = `pause_opened`).
5. 25 AC-25-24 → 6 AC-18b (ordenador 100 ms + LUCES_PARPADEO atenuación única).
6. 25 AC-25-25 → 6 AC-18 (23, 26, 28 reaccionan el mismo fotograma).
7. 27 → 5 OQ 10 (CERRADA D-25: partida terminada, solo «Nueva partida»).
8. 27 AC-16 → 21 AC-21-28 (≤ 3,0 s, pila [`menú`]).
9. 27 → 4 OQ 8 (escena-de-planta L421: mensaje de error de carga, GDD 27).
10. 27 → 23 OQ 3 (director-de-audio L466: drone en título/menú).
11. 24 → 1 regla 3 (dispositivo activo = último usado).
12. 24 → 7 regla 11 (respuesta inmediata, `SFX_CLICK_SUBTLE`).
13. 24 → 7 regla 3 (contrato del dueño).
14. 24 → 7 F5 (duración del pie).
15. 24 → 7 F2 (progreso de pulsación prolongada).
16. 24 AC-24-13 → 7 AC-15 (30 car. con multiplicador 2,0 = 5,29 s).
17. 17 AC-17-14 → 9 AC-31 (P6 10 s/20 s, cursor no reinicia, clic en vacío sí).
18. 17 AC-17-11 → 9 AC-66 (P5 `RESOLVING`: `request_hint` false).
19. 23 AC-23-08 → 9 AC-23 (P5 termina a 18,0 s; coherente con 23 AC-23-04 corte a 16,0 s).
20. 26 AC-26-04 / 9 AC-23 (14,0 s fallback): coherente.
21. 28 AC-28-12 ↔ 23 AC-23-16 (apagón lluvia 0,4 s, VUELVE 2,0 s, CESA 6,0 s): coherentes.
ERROR / DISCREPANCIA de referencia:
- 25 AC-25-50 «23 reanuda voces y efectos con ella (AC-23-18)»: AC-23-18 y AC-23-32 (director-de-audio L371, L385) usan `pause_closed`; 25 emite «pausa cerrada» (y 28 R22/L119 «pausa cerrada» ‡). Mismo aviso con dos nombres. AVISO.
- 28 AC-28-17 exige pasar AC-28-16 y AC-28-19 que a su vez dependen de un spike pendiente (OQ 10): AC no cerrable. AVISO.
NO verificadas (citadas pero no comprobadas): 26 «regla 20/25 de 22», «OQ 5 de 22», «F3 de 23», «OQ 9 de 23», «AC-09 de 18», «regla 1 de 6»; 25 «regla 20 de 1» (entrada L98 es línea larga, no leída); 28 «AC-34 de 2»; 30 «21 DT-12», «AC-10a de 19», «15 AC-P5-03»; 23 «AC-22-19»; 24 «7 regla 7»; referencias de los antiguos hacia los nuevos (0 de 40 % muestreadas).

## 4. Cobertura pendiente de r8: NO cerrada
Solo localicé encabezados de 1: reglas 13–16 y 20 (L80–L98, líneas largas), regla 23 (L107), F1–F4 (L165 zona muerta, L182 ratón, L200 stick, L218 rotar). No leí su contenido. Sin leer: 9 reglas 7, 9, 12, 14b y Tuning Knobs; 7 D01a–D01d; 4 regla 9 y F1/F2; 5 reglas 7a y 11; ACs de 8, 10, 18, 19, 20, 21 (de 10 solo leí AC-05/AC-08 de grep; 21 solo AC-21-28). Lo que sí se vio incidentalmente: 10 L216–L219 BOX_C1..C4_OPEN 1,6/1,4/1,4/1,6 s coherentes con slice L785/L832 y registro.

## RESUMEN
BLOQUEANTE (1, a confirmar por el autor): 27 AC-18 (fundidos 0,15 s con reducir_movimiento o reducir_sobresaltos) vs 30 AC-30-12 / 25 AC-25-08 / 26 AC-26-20 / 24 AC-24-16 / 29 AC-1 (100 ms o 0,10 s con reducir_movimiento); 27 AC-17 (3,15 s) depende de 0,15 s.
AVISO: AC-25-23/AC-25-27 vs AC-30-01/-02 y D30-7; `pause_closed` vs «pausa cerrada»; umbrales de destello (29 AC-15 0,25 vs 30 AC-30-13 10 % vs 28 AC-28-21); 27 y 29 sin tipos de AC y leyendas L/U/V/UI/H/P distintas; AC-17-17 «auto_apply falso» ambiguo frente a AC-17-14/-15 (flag de 9 `idle_hints_auto_apply` vs flag propio de 17); 24 pie ≥ 20 px (AC-24-14) vs ≥ 24 px (25 AC-25-18, D30-4); 12 textos obsoletos de la sección 3; CLAUDE.md:9 y README.md:4 «25–30 min».
INFO: orden de ACs en 24, 27, 28; GPU 28 ≤ 1,0 ms + 29 ≤ 0,5 ms sin presupuesto global.

## NO LEÍDO
ACs de 1, 7, 8, 9, 10, 18, 19, 20, 21, 22 (salvo los citados arriba), 5 y 6 salvo AC puntuales; Detailed Rules de los nueve nuevos; Tuning Knobs de todos; catálogos D01a–D01d de 7; reglas 7/9/12/14b de 9; regla 9 y F1/F2 de 4; reglas 7a/11 de 5; reglas 13–16/20 y F1–F4 de 1; systems-index L239–L312; game-concept.md; entities.yaml (solo grep de ‡/BOX); ≈ 59 referencias del objetivo de 80 sin muestrear (todas las de antiguos → nuevos).
