# review-R12-3 · Fase 3 (tiempos, pilares, fuerza bruta, atención, †) · informe

## 1. TIEMPOS (OK salvo lo marcado)
- F7 de 9 suma: mín 2+3+1,5+2+1,5+0,5 = 10,5; máx 4+6+3+4+3+2 = 22. OK.
- F9: mín 10,5+0,563+2,0+0,273+1,0+0,1+0,4 = 14,83; máx 22+0,847+5,0+0,747+3,0+1,0+0,5 = 33,09. OK. Escenas 15+7+11,8 = 33,8 s y 15+7+28,8 = 50,8 s. OK.
- Recalculo por puzle (todas las sumas internas cuadran):
  - P1 F4: 95,8 / 177,5 / 272,8 s (1,6 / 2,96 / 4,55 min). OK. F2: t_fallo 8·0,4+0,6+1,5 = 5,3; 23·5,3 = 121,9. OK.
  - P2 F4: 66,6 / 122,4 / 270,6 s (1,11 / 2,04 / 4,51 min). OK.
  - P3 F3: 65,4 / 100,6 / 149,5 s. OK.
  - P4 P4-F3: 89,4 / 176,8 / 406,6 s (1,5 / 2,9 / 6,8 min). OK.
  - P5 F-P5-5: 56,2 / 188,2 s (0,94 / 3,14 min). OK.
  - P6 F3: 11,4 s mín plausible, 28 s típico. OK.

### AVISO
- A1. Cifra desfasada en el marco. `marco-de-puzles.md` F7, fila P2: «el modelo de 12 da 1,1–4,4 min» (y D9-76: «1,1–4,4 de 12»). `puzle-2` F4 da 1,11–4,51 min, o sea 4,5.
- A2. La revelación de P5 en F9 no está escrita. `marco-de-puzles.md` F7 dice «P5 Espejo | 1,5–3 (más ~16 s de revelación)» y F9 suma 1,5 y 3 sin añadirla. `puzle-5` D15-7 la interpreta como incluida y pide a 9 que lo escriba, pero 9 no lo recoge.
  - Con el literal («más»), F9 subiría 0,27 min (15,10 / 33,36).
  - Hoy F9 cuenta la revelación como mucho una vez, pero la lectura depende de una nota que no existe.
  - `puzle-5-...-review.md` aún cita F9 15,10 / 33,36 (obsoleto).
- A3. El «mínimo» de F9 (14,8) no es un mínimo plausible. Usa los anclajes de F7, no los mínimos de los modelos.
  - Mínimos de modelo: P1 1,6; P2 1,1; P3 1,1; P4 1,5; P5 0,94; P6 0,19. Suman ≈ 6,4 min frente a 10,5.
  - Suelo real ≈ 10,7 min. Un jugador rápido puede quedar bajo el «~15 min» del criterio 1 (slice §19). Ya queda «a medir» con AC-X5.
  - P6 lo reconoce (OQ 9, ≈ 0,31 min de sobreestimación). P2 y P5 no lo trasladan a 9.
- A4. Slice §22 «cada puzle entre ~1 y ~6 min».
  - P4 máx 6,8 min > 6 (cola: 3 fallos por ficha + 90 s en T4 + 30 s de pistas; nominal 2,9).
  - Por debajo de ~1 min: P2 1,1 (apenas), P5 0,94, P6 0,19. El propio §22 lista P6 como 0,5–2.
  - Nominales y típicos: ninguno fuera de rango.

### INFO
- I1. Llamada, máximo 44,8 s = 10,8+29,0+5,0 omite el +1,0 s de `SFX_PHONE_END` que el mínimo sí incluye (16,4 = 10,8+0,6+4,0+1,0). Debería ser 45,8 s (+0,017 min en F9). Suma las duraciones de `SFX_BREATH_BROKEN` y `VO_G_14` en secuencia; el slice C.7 no lo dice.
- I2. `t_clic` 0,4 s (P1, P4, F6 de 9) frente a 0,8 s (P2). P2 lo justifica, pero F6 de 9 no lo reconcilia.

## 2. PILARES / ANTI-PILARES
Bloqueantes: ninguno.
- **Tensión sin castigo:** ningún puzle queda sin salida ni castiga.
  - P1: R25/R39. P5: reglas 12 y 19 (θ se conserva, sin reset). P6: regla 7 «No hay fallo» y regla 23.
  - La revelación de P5 no se puede saltar (≤ 18 s por reapertura; regla 20) y solo se interrumpe con `atrás`. INFO.
- **Pilar 1 «Ninguna opción es incorrecta»:**
  - P4 T4: sellos y sonido idénticos (P4-R10); el sesgo hacia «Devolver» se mide en P4-F4 (OQ 2).
  - P6: tres botones del mismo peso (regla 4, D16-12).
- **Riesgo real, ya elevado como pregunta abierta (OK):** P6 OQ 2. `CARTA_A` («Estoy bien. Es lo que escribiría si no fuera verdad») junto al botón «La verdad» puede leerse como A = mentira, B = verdad. Roza el pilar 1 y el pilar 5.
- **«NOT una historia explicada»:**
  - P5 regla 16: sin texto, nombre ni comentario; solo contorno. OK.
  - P6 regla 12: la carta no explica. OK.
  - P3 `slot_6`: OQ 2 «¿Las siluetas dicen demasiado?». Abierta, pero la silueta ya está en regla 18 N1 y en AC-25. Es un defecto declarado, no una decisión disfrazada.
- **Decisiones por defecto sobre tono, con pregunta abierta paralela** (cumple CLAUDE.md porque se registran y se elevan):
  - P6 D16-1 / OQ 1 (aviso de permanencia): defecto (a).
  - P6 D16-10 / D16-16 / OQ 12: la elección es rehacible si el juego se cierra antes de guardar. Roza D-14.
  - P6 OQ 3: el slice §20 aún marca D-14 como «Pendiente», aunque el GDD lo trata como firme. Hay que cerrarlo en el slice.
- **Desvíos de la letra del slice, todos registrados:**
  - P5 D15-1: descarta «Si falla: el marco vuelve a su posición inicial» (§10.5); B.5 manda.
  - P6 D16-2: aceptar al soltar, no al pulsar (B.6).
  - P2: el halo N3 marca el punto actual (B.2), no «su fragmento» (§10.2).
- **«No hay menú de inventario»:** OK.
  - `repasar_bolsillo` es un documento por pulsación, sin menú (18 D18-21, 20 D20-8).
  - Orden I-07, I-05, I-06a, I-04 (P4-R16). P6 regla 15 coherente. P2 R22 no da ítem (Q12-7 abierta, defecto no).
  - Conflicto potencial resuelto: `atrás` durante la presentación de P6 lo consume la vista (D9-63).

## 3. FUERZA BRUTA y D-W (según los textos de los seis GDDs)
- D-W1 vigente y medida.
  - P1: 24 permutaciones, 65 s de media sin repetir (64,8) y 125,7 s de peor caso (F2). Umbral de revisión: mediana de rechazos ≥ 6. Mitigación D11-6 (sellos) sigue siendo propuesta no confirmada (OQ-4).
  - P4 T1–T3: 2,4–22,8 s, media ≈ 12,6–13 s. T4 no es forzable. D14-4.
  - P3: ≤ 30 s (T_media 18 s). Aceptada.
- D-W2 (P2): ≤ 9 pulsaciones (F2; 6 reales desde (2,2,2)). Condición: el jugador se detiene a observar; el peor práctico es 21 pulsaciones / 75,6 s. Abierta (Q12-1).
- D-W3 (P5): giro < 7,5°/s resuelve en 5,73 s sin comprender (F-P5-2/3). Aceptada en D15-6; OQ 1 pide cambiar cómo se mide el criterio 5 del slice.
- D-W4 (P1): N2 y N3 no añaden información sobre el día. Vigente, aceptada (OQ-1).
- D-W5 (P6): elegir antes de 10 s sin saber que es definitiva. Vigente (OQ 1).
- D-W9 y D-W10 (P4): `VO_G_14_ASG` casi responde «quién firmó» (pilar 5). T4 apenas se percibe como elección. Vigentes (P4 OQ 2 y OQ 4).
- D-W11 (tiempos): reconciliado vía F7/§22 y F9, salvo A1–A4.
- D-W6: cerrado (cross-review r2).
- D-W7: en 18.
- D-W8: no aparece en los seis GDDs (no verificado).

## 4. ATENCIÓN (más de 4 sistemas con acción simultánea)
No aplica tras comprobar las reglas de P5 y P6.
- P5 revelación: la entrada queda bloqueada salvo `atrás`; el jugador solo escucha (vídeo, voz y subtítulo, sin acción).
- P6: una pulsación más tapa, carta y SFX, con pistas solo de texto.
- P2, P3 y P4: un gesto más una pista como máximo.
- La escena 7 (llamada) no es de mi perímetro de puzle y no se verificó.

## 5. VALORES † SIN FUENTE NI MARCADOR
- AVISO: `puzle-1` F4, celdas de la tabla (`T_leer` 45/65/90; trayectos 8/11/15, 4/6/8, 12/18/25; deducir 20/40/60; repensar 10; desvío 20/45). No llevan † ni fuente; solo OQ-7 dice que son hipótesis.
- INFO: `puzle-4` Tuning Knobs, fila `t_clic` 0,4 s sin † (F2 sí lo marca †). `puzle-6` F3, 21–25 palabras de la carta †, sin fuente (declarado, D16-15). `puzle-3` F3 y `puzle-5` F-P5-5: todo marcado †.

## NO LEÍDO
- `puzle-1`: R1–R50, Edge Cases, AC, Datos del puzle.
- `puzle-2`: R1–R32 salvo R17/R22/R22b; Edge Cases; AC.
- `puzle-3`: reglas 24+, AC (salvo AC-06/07/11/16/19/21/25); Decisiones salvo las citadas.
- `puzle-4`: reglas P4-R1–R15 y AC (salvo P4-R16 y AC-14-17); Open Questions 1, 3 y 5–7.
- `puzle-5`: Edge Cases, AC y OQ 2+.
- `puzle-6`: Edge Cases, AC (salvo referencias).
- Slice: §10 solo hasta 10.6, §19 y §22 completos, B.5, B.6, C.7. No leídos: B.1–B.4 y §12–§17.
- Marco: Core Rules, Edge Cases y AC.
- Escena 7 (llamada) y la clave D-W8.
