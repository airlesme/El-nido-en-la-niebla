# Revisión independiente · Director de audio (sistema 23)

**Documento:** `design/gdd/director-de-audio.md` (54 KB, leído por rangos) · **Revisor:** independiente, sin contexto del autor · **Fecha:** 2026-11-09

## Veredicto: NEEDS REVISION

El GDD es completo y muy trabajado: tiene las 8 secciones más Datos, Decisiones, Open Questions, Cambios requeridos y Entradas para el registro. Las fórmulas y los ejemplos numéricos cuadran. Hay 4 bloqueantes, todos de contrato con los vecinos o de reglas que no pueden cumplirse tal como están escritas, y 11 avisos. Ninguno cambia pilares ni alcance.

## BLOQUEANTES

| ID | Ubicación | Problema | Arreglo propuesto |
|---|---|---|---|
| B-1 | R41, R5 (fila 25), Dependencies, «Cambios requeridos» | **Los nombres de los avisos de pausa no coinciden entre 3, 25, 26 y 23.** 3 (l. 55) y 25 (R3, AC-25-02) solo emiten `pause_opened`. 25 no define ningún aviso de cierre. 26 (R25) usa «Pausa abierta» y «pausa cerrada». 23 usa `pause_opened` ‡ y «pausa cerrada» ‡. El fallback «al dejar el árbol de estar pausado» (R41) supone una pausa del `SceneTree`, pero 25 solo detiene el «tiempo de juego» (Δ_juego = 0) y no dice que pause el árbol. Si el árbol no se pausa, 23 nunca reanuda. | Fijar un único par (`pause_opened` / `pause_closed`) en 3 y 25 antes de aprobar. Quitar el fallback del árbol, o exigir que 25 lo declare. 26 debe usar los mismos nombres. |
| B-2 | R5 (fila «sonido pedido»), D23-4, Dependencies | **Aviso nuevo sin dueño ni contrato.** «Sonido pedido» ‡ y «sonido de llamada pedido» ‡ no existen en 3. La tabla de 3 (l. 54, 122, 180) solo lista tres señales para 23, y no lista «línea iniciada» ni «sonido pedido». 22 (l. 193) además dice que pide los `SFX_*` por «línea pedida». Con R7 eso daría «fallida» por no tener texto en 18 (edge case «Sin texto en 18»). 22 y 23 no coinciden en el canal de los SFX. Depende de la OQ 7 y no hay decisión. | Antes de cerrar el lote, resolver la OQ 7 en 3. Fijar en 22 que sus SFX van por «sonido pedido». Añadir a R7 que «línea pedida» solo acepta IDs de 18 y que un ID `SFX_*` no es una línea. |
| B-3 | R43, AC-23-20, F8 | **La reanudación deriva el apagón de hechos que no lo definen.** El apagón lo gobierna `apagon_activo` (21, regla 13). Ese hecho no está en 3 (0 apariciones). 23 usa `caja_completa ∧ ¬llamada_completada`. Entre `caja_completa` y el disparo de `T-D-OUT` (21, `ESC7_APAGON`) todavía no hay apagón. Cargar en esa ventana pone la lluvia a −60 dB sin haber habido apagón. Contradice «Lluvia por estancia» y deja a 28 desincronizada, porque 28 no está en silencio. | Derivar de `apagon_activo` (21) o de un hecho de 3. Si ese hecho no existe, añadirlo a «Cambios requeridos» o aceptar el desfase como edge case documentado con AC. |
| B-4 | R33, R2, R30, Pilares (tabla) | **Contradicción interna sobre efectos en la voz.** `SPK_D01C` lleva «saturación suave». R33 afirma que «23 no aplica *pitch* ni distorsión», y R2 y la tabla de pilares prometen «voces sin efectos de carácter». La saturación es distorsión sobre la voz del Guardián. Eso roza el pilar *Ambivalencia* (la voz no debe sonar amenazante). Además, `Voice_Guardian` es un solo bus pero sirve a dos fuentes con filtros distintos (`SPK_D01C` 250–5.000 Hz y `SPK_V02` 300–3.400 Hz). R3 declara el árbol «fijo» y no hay bus por fuente. | Quitar la saturación, o registrarlo como decisión elevada a OQ. Aclarar cómo se aplica cada perfil: por bus hijo adicional, por reproductor 3D, o horneado en la grabación. Si no se resuelve, el árbol de R3 no es implementable. |

## AVISOS

| ID | Ubicación | Problema | Arreglo propuesto |
|---|---|---|---|
| W-1 | R23 vs F6 vs AC-23-21 | P2 es «robable solo por otro P2 si hay más de `max_sfx_p2`» (R23). F6 y AC dicen «un P1 o P2 nunca se descarta» y «un feedback P2 no se roba nunca». | Unificar: P2 se protege hasta `max_sfx_p2`; por encima, el más antiguo. Cambiar el texto de F6 y el del AC. |
| W-2 | R23 (reservas) | Las reservas suman 6 + 4 + 8 + 2 = 20 = `max_voces_total`, sin holgura. Con 21 voces y varios P2 a la vez (bucle de teléfono, respiración y feedback), el cálculo no tiene margen. `SFX_PHONE_BUZZ` y `SFX_FRAME_TURN` son lazos P2 y además cuentan como «6 lazos» reservados P5. | Subir `max_voces_total` o reducir reservas. Aclarar que P5 incluye a los lazos P2. |
| W-3 | F3 | La tabla dice «`t_max_lect_s`: tope de la parte proporcional», pero el `clamp` se aplica a `t_min + n/cps`. Con 300 caracteres da 14 s, no 15,5 s. Los ejemplos AC-23-02 no lo ejercitan. | Corregir la descripción o la fórmula. Añadir un AC con una línea larga. |
| W-4 | R37 / D23-2 vs R42, R47 | «Sin audio» exige el mismo tiempo que quien oye. Pero 26 usa `max(duración + t_cola_sub_s, t_lectura_s)` con audio y `fallback_s` sin él. Los tiempos de subtítulo no son idénticos y la afirmación de AC-23-12 solo vale para las señales de 23. | Matizar la frase: idénticas las señales y los tiempos de 9/22/21, no el subtítulo. |
| W-5 | Dependencies (fila 26), Quick reference | 23 lista a 26 como «Blanda · ‡ (sin GDD)». `subtitulos.md` ya existe y declara a 23 **Dura** (l. 119). La reciprocidad no tiene la misma dureza. 26 también espera «línea iniciada» (R15) y su AC-26-02 depende de ella, aunque 23 la declara «opcional». | Alinear la dureza. Decidir si «línea iniciada» es obligatoria. Actualizar la tabla de 26. |
| W-6 | R25, R41 | Con el menú abierto «voces y efectos puntuales se pausan», pero la muestra de volumen (`UI_VOL_MUESTRA`, `SFX_CLICK_SUBTLE`) debe sonar en esa misma pausa. No hay excepción escrita. Tampoco se dice que 23 deba tener `process_mode` siempre activo. | Añadir la excepción y la nota del nodo persistente, y un AC (AC-23-26 solo prueba la cadencia). |
| W-7 | AC-23-31 vs «Formatos y objetivos» | AC: «voces −18 LUFS ±2». La tabla de formatos fija megafonía a −21 LUFS (fuera de ±2). Los efectos de mundo (−26) y los pasos (−30) no están en el AC. | Separar megafonía en el AC y completar las categorías. |
| W-8 | AC-23-24, AC-23-30 | «`MEGA_02` se entiende en las salas cerradas con ≤ 12 dB» y «5 de 5 testers no pueden deducir…» no son verificables objetivamente. Falta un umbral medible (SNR o nivel) y un protocolo. | Medir la atenuación (dB) y dar un criterio de inteligibilidad. Dar un protocolo de playtest. |
| W-9 | F5 vs 2 (regla 31, F3) | 2 ya envía `intensidad = lerp(i_paso_min, 1, r)`. F5 de 23 repite «`intensidad = lerp(i_paso_min,1,r)`» como si lo calculara 23. Riesgo de aplicarlo dos veces. Los AC usan `paso(moqueta, 0,4)`, que supone el valor ya calculado. 2 también declara superficie `default` y no confirma `moqueta`/`baldosa`. | Decir que 23 recibe `intensidad` ya calculada. Mantener `i_paso_min` solo en 2. |
| W-10 | Afirmaciones de motor (R19, R25, R36, R38–R41, R50) | No se citan APIs de Godot 4.7. `docs/engine-reference/godot/modules/audio.md` solo cubre `AudioStreamPlayer`, `AudioStreamPlayer3D`, `AudioServer.set_bus_volume_db` y `set_bus_mute`. No verificadas: rampa en dB, limitador de techo por línea, pasabanda por fuente, `finished` como único evento de fin, pausa por posición (`stream_paused`), y `AudioListener3D` en la cámara. El AC-23-14 mide dBFS con un limitador sin nombre. | Marcar estas piezas como pendientes de ADR/prototipo y registrar en la sección Datos que se validan contra `modules/audio.md`. |
| W-11 | R5, R28 y OQ 1/3 | R22/D23-13 (lluvia a −60 en el apagón) y «el drone se detiene al volver al título» (OQ 3) son **por defecto** y ya están en OQ. Pero R29 («silencio parcial» en cualquier vista cercana, D23-19) también toca el pilar del silencio, y el slice §14 lo limita a puzles. No está elevada. | Añadir una OQ o aclarar en D23-19 que 21/7 pueden filtrar por tipo de vista. |

## Verificado correcto

- Estructura: las 8 secciones del modo standard más Datos, Decisiones tomadas (21), Open Questions (9), Cambios requeridos y Entradas para el registro.
- Aritmética:
  - F1: paso 15 de 20 da −10 dB, coherente con la fórmula de 6 (`db_min × (1 − v)`, −38 dB en el paso 1).
  - F2: 6 dB / 0,15 s = 40 dB/s; liberación 7,5 dB/s; 0 dB a 7,1 s.
  - F3: 1,83 / 5,70 / 2,77 s.
  - F4: `techo_s` 16,0 s, secuencia de 18,0 s y 15,2 s, consistentes con el AC-20 y el AC-23 de 9.
  - F5: −13,96 / −9,10 / −6 dB.
  - F7: 3.880.800 B ≈ 3,7 MB.
- Contrato de respuesta única (R7): «terminada» / «sin audio» / «fallida» con el mismo `line_id`. Es coherente con 9 (R20, R37, F8), 21 (reglas 7 y 9; DT-15) y 22 (R25, AC-22-19). Nunca bloquea, y `fallback_s + line_grace_s` (2,0 s) coincide con 9 y 22.
- Los IDs `SFX_*` de B.7 del slice están todos en el catálogo (`SFX_SLIDE_OK` … `SFX_CLICK_SUBTLE`, `SFX_PHONE_BUZZ`, `SFX_PHONE_END`, `SFX_BREATH_BROKEN`). `MEGA_01`–`MEGA_03` (28 líneas, 21 audibles), `SPK_D01C` (10, regla 17/22), `SFX_CARD_OK`, `SFX_DOOR_SWING` y `SFX_DRAWER_OPEN` (registro) existen con el mismo nombre.
- Volúmenes de 6: nombres `vol_voces`, `vol_efectos`, `vol_musica` y `reducir_sobresaltos`. Cadena de silencio y `N_pasos`. Coherente con 6.
- Efectos de escena: `LLUVIA_REALCE/CESA/VUELVE` y los visuales ignorados coinciden con 21 y 28; 28 remite a la OQ 1 de 23 para el cese en el apagón. `TELEFONO_PULSOS` / `TELEFONO_SUENA` y `V02` (`vibrando`, `reposo`, `en_llamada`) coinciden con 21 y 22.
- Pilares: los cinco nombres citados coinciden con `game-pillars.md`. R30 y D23-15 (sin *stingers*) respetan *Ambivalencia* e *Información incompleta*. Los sustos atenuables respetan *Tensión sin castigo*.
- Slice §14: lluvia por estancia, drone constante, silencio parcial, pasos, sillas, tecleo y la puerta dentro de `VO_G_07` están recogidos. `SFX_BREATH_BROKEN` y su subtítulo `SUB_BREATH_BROKEN` coinciden con 22 y 18.
- `systems-index.md` fila 23: dependencias «3, 6, 18 (blanda: 2)», coherentes con el GDD.
