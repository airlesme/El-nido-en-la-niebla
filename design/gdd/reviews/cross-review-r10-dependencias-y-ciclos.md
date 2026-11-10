# R14-B (perímetro 2a dependencias) — FINAL

Método: leí Dependencies completas de 17, 23, 24, 25, 26, 27, 28, 29, 30 y 2 (aguas abajo); para el resto, solo las filas de esas tablas que nombran 17 y 23-30 (Grep). ≈110 filas/pares contrastadas, no la tabla completa de 30x30.

## BLOQUEANTE
- B1. Ciclo duro 27 <-> 30 no declarado. 27 (pantalla-de-titulo L136): «30 Accesibilidad | Dura | Pantalla de accesibilidad». 30 (L151): «25 Menú de pausa / 27 Título | **Dura** (30 no tiene pantalla propia: sin 25 no se muestra ningún ajuste)». El índice «Circular Dependencies» (L183-190) no lo recoge. Acción: declarar el ciclo (de ejecución, no de construcción) o degradar uno (p. ej. 27->30 Blanda).
  (Ningún otro ciclo duro en 23/26/28/29/30 ni en 24/25/27: 23 no depende de 26/28/29/30; 26->23 Blanda; 28->29 Opcional; 29->28 Blanda; 25 no depende de 27/30; 24 no depende de 25.)

## AVISO — dureza o dirección discrepante
- 17<->25: 17 (L214) «Blanda ‡»; 25 (L234) «**Dura de 17 sobre 25**». Manda el dependiente (17): 25 debe repetir Blanda. Índice fila 17 «3, 9, 18» omite 25 y 7 (17 los propone).
- 25<->27: 27 (L135) 25 «Dura»; 25 (L241) «Blanda (de 27 sobre 25)».
- 25<->30: 30 (L151) 25 «Dura»; 25 (L242) 30 «Blanda… 30 no revisado en esta ronda» (obsoleto).
- 23<->26: 23 (L314) afirma que `subtitulos.md` declara a 23 «Dura»; 26 (L122) declara 23 «**Blanda** (avisos)». Corregir 23.
- 23<->30: 30 (L149) 23 «Dura para AC-30-11»; 23 no tiene fila hacia 30 (30 mismo lo admite). Falta reciprocidad.
- 28<->21: 28 (L223) «Sin dependencia directa»; 21 (L193) idem; pero índice fila 28 lista 21 en «Depende de» y 28 mismo pide «corregir».
- 28<->29: 28 (L227) «29 Opcional (28 no depende de 29)»; 29 (L170) «29 es Opcional para 28; 28 Blanda para 29» — dirección contradictoria. Índice fila 15 dice «dependen de 15: 29 (blanda)»; 29 (L167) declara a 15 **Dura**; ídem 12.
- 29<->30: 30 no cita a 29 pese a AC-30-12/13 (fundidos 100 ms, tope de destellos «28, 29, 24, 21»); 29 no cita a 30.
- 27 vs proveedores: 27 declara 3 Dura (3 L182: Blanda), 4 Dura (4 L234: Blanda), 1 Blanda en 1 pero 27 no ... — en concreto 1 (L398) lista a 27 Blanda y 27 declara 1 Dura; 27 declara 21 Dura (21 L195: «Sin dependencia directa»); 27 declara 6 Blanda (6 L219 Blanda, OK).
- 17 vs 3/20/19/30: 3 (L185) 17 «Dura» lee `formulario_leido` y `memo_leido`; 17 (L210) los declara «sin uso» (D17-10). 20 (L221) declara 17 Blanda por `formulario_leido`; 17 (L220) «Ninguna». 19 (L186) declara 17 Blanda; 17 no lista a 19. 30 (L155) 17 Blanda; 17 (L219) 30 «Ninguna».
- 26<->24: 26 (L127) «24 debe nombrar a 26»; 24 Dependencies no lo hace. 26 no menciona 24 como proveedor de pie... (convivencia no reflejada en 24).
- 18: 25 declara 18 Blanda (L225), 24 Dura, 29 «Datos», 28 ?; 18 solo lista como dependientes 17, 23, 26, 27 (L229-236). Faltan 24, 25 (y 29, 30). Índice fila 25 pone 18 sin «blanda».
- 4<->25: 25 (L228) 4 «Blanda: descarga total al salir al título»; 4 no lista a 25. 2<->25: 25 (L237) dice que 2 recibe `campo_vision`; 2 (L283+) no lista a 25.
- 3: Dependencies de 3 (L180-185) no incluye 26 ni 24/30; 26 declara 3 Dura. Índice fila 26 «6, 18, 23» omite 3 (26 L123: «Añadir 3»).
- Índice filas vs GDD: 27 omite 4, 21, 25, 30 (declaradas Duras) y marca 6 sin «blanda»; 30 omite 25, 27 (Duras), 28, 19, 17, 24; 24 «1, 7, 18» omite que 1 es Blanda y 6 Blanda; 23 correcto («3, 6, 18; blanda 2») pero 23 también declara 9/21/22 Blandas (avisos).
- 28: 6 (L90) solo lista `reducir_sobresaltos` y 28 usa también `reducir_movimiento`; 29 lee `reducir_movimiento` de 6 y 6 no lista a 29 (29 L169 lo admite).

## AVISO — citas obsoletas
- Índice fila 22: «23 y 26 (sin GDD): contrato ‡ fuera de dependencias».
- llamada-telefonica L193 «…; sin GDD» (23) y L194 «sin GDD» (26).
- sistema-de-pistas L214 «25 Menú de pausa (sin GDD)».
- ajustes-persistentes L229 «24 … Blanda (sin GDD aún)… al redactarse»; L375 «Menú de pausa (25), sin GDD».
- documentos-y-bolsillo L221 «17 Pistas (sin GDD)», L334 «17 Pistas (futuro)».
- puzle-6-decision L138 «17 Sistema de pistas (sin GDD)»; puzle-1 L317 «(futuro)»; puzle-4 L173 «(cuando exista)»; marco-de-puzles L530 «Dura (cuando exista)».
- director-de-escenas L339 «25 Menú (por redactar)».
- base-de-contenido-narrativo L242 «Los que aún no existen (11–17 y 23–27)».
- control-de-acceso L321 «23 Audio (al redactarse)»; caja-y-compartimentos L198 columna «Pendiente».
- entrada-y-controles L401 «Pendiente… sin definir hasta el GDD del 25».
- atmosfera-reactiva fila «23 (fila previa)… 23 debe añadir fila» (23 ya la tiene); shaders-y-efectos L175 «9 y 28 deben citarlo» (28 ya cita a 29).

## INFO
- Índice «Progress Tracker» (L211-216): «Design docs started 15», «Vertical Slice 0/7» obsoletos.
- 24 declara a 28 «Indirecta vía 7» y 28 no lista a 24/7.
- 25 L234 cita «l. 212» de 17 para `HintPanel`; esa línea de 17 es la fila de 18.

## NO LEÍDO
Dependencies completas de 11, 12, 13 (solo filas 17/23/28), 14, 15 (solo filas), 16; 1, 3, 4, 5, 6, 7, 8, 9, 10, 18, 19, 20, 21, 22 (solo filas que nombran 17 y 23-30, no sus filas entre 1-22); pares 1-22 entre sí no contrastados; sección «Dependency Map» del índice (L97-182).

---
## Informe final del revisor (respuesta de cierre) — unos 110 pares contrastados, no la tabla completa de 30×30 (los pares entre 1 y 22 no se comprobaron)

**1 bloqueante:** ciclo duro 27↔30 sin declarar: 27 declara a 30 «Dura» (`pantalla-de-titulo.md` L136) y 30 declara a 27 «Dura» (`opciones-de-accesibilidad.md` L151); la sección «Circular Dependencies» del índice no lo recoge.
Sin otros ciclos duros: ninguno entre 23/26/28/29/30 ni entre 24/25/27.

**Dureza discrepante (≈14 discrepancias de dureza, dirección o reciprocidad):** 17↔25 (17 Blanda, 25 Dura); 25↔27 (27 Dura, 25 Blanda); 25↔30 (30 Dura, 25 Blanda); 23↔26 (23 afirma que 26 lo declara Dura, 26 lo declara Blanda); 27 vs 3, 4 y 1 (27 declara Dura y esos tres lo declaran Blanda); 29 declara a 15 como Dura pero el índice (fila 15) dice que 29 es blanda.
**Dirección y reciprocidad:** 28 y 21 dicen «sin dependencia» pero el índice lista 21 en la fila 28; 28 y 29 se contradicen (28 dice que no depende de 29 y 29 dice que 28 es Blanda para 29); 23 no tiene fila hacia 30 aunque 30 lo declara Dura para AC-30-11; 24 no nombra a 26, ni 18 a 24/25; 3 no lista a 26; 17 dice que `formulario_leido` y `memo_leido` están «sin uso» pero 3 y 20 los declaran como lectura.
**Citas obsoletas (≈14):** «sin GDD»/«por redactar» sobre 17, 23, 24, 25 y 26 en filas del índice y en los GDD 6, 20, 21, 22, 16 y 18; «cuando exista»/«futuro» sobre 17 en los GDD 1, 4, 9, 10 y 11.
**Índice, columna «Depende de»:** las filas 17, 24, 26, 27 y 30 omiten dependencias que sus GDD declaran; la fila 28 lista a 21 sin que 28 lo declare; la fila 25 no marca como blanda su dependencia de 18.
