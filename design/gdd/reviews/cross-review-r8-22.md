# Borrador review F2b GDD 22 (turno ~12)
VEREDICTO: NEEDS REVISION (menor; 0 bloqueantes)
B-1 CERRADO (21 l.48, AC-21-14b, D21-28 = 22 R34, Edge l.164, AC-22-27). Caso paso a paso: sin reinicio.
A-1/A-2 coherentes en 22/21/3/7/1/registro, salvo AVISO-1.
AVISO-1: 21 R15 "21 no emite nada de V02 con llamada_iniciada verdadero" vs "devuelve V02 a reposo en llamada iniciada" (22 R3a escribe hecho antes del aviso; 22 R33/D22-22 dependen de que 21 emita reposo).
AVISO-2: 22 Dependencies fila 8 "Blanda (la declara 8 en el índice)" e índice fila 22 "8 (blanda, la declara 8)" vs 8 l.198 "Indirecta (vía 3)".
AVISO-3: slice 0.4.2 (l.1104) "D-15 sigue pendiente de confirmar" y l.472 "Confirmar" vs 22 cambio nº 10 / OQ3 "D-15 confirmado".
AVISO-4: índice fila 22 lista blandas ‡ 23, 26 vs D22-25 y cambio nº 9 "no se listan".
AVISO-5: 5 l.262 "disparador de la llamada sigue siendo salir de D" vs 21 R14 (timbre al volver exploración / T-OFI-IN).
INFO: R19 "vuelve a INACTIVA al descargarse" vs "hasta la siguiente escena lista" (AC-34 dos disparadores); F9 suma con cifras redondeadas da 14,87 (14,83 con sin redondear; ok); 22 cabecera cita slice v0.4.1; edge rechazo de contexto no repide buzz; reposo() de 2 no citado en R19.
F9 verificada: mín 14,83, máx 33,09, 0,27/0,75 ok. F3/F5 aritmética ok.
