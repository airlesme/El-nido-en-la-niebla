# Revisión independiente: Pantalla de título, advertencias y cierre (sistema 27)

> Documento revisado: `design/gdd/pantalla-de-titulo.md` (borrador, 2026-11-09)
> Revisor: independiente (no autor). Fuentes contrastadas: slice v0.3 (§17, §18, D-06, líneas 291, 356, 1028, 1080), `guardado-y-carga.md` (5), `menu-de-pausa.md` (25), `director-de-escenas.md` (21), `ajustes-persistentes.md` (6), `director-de-audio.md` (23), `systems-index.md`.
> Limitación: por presupuesto de lectura no se abrieron `base-de-contenido-narrativo.md` (18), `escena-de-planta.md` (4, solo se cita lo que 5, 21 y 25 dicen de ella), `estado-y-bus-de-eventos.md` (3), `game-pillars.md` ni `entities.yaml`. Los puntos que dependen de ellos están marcados «sin verificar».

## Veredicto: NEEDS REVISION

Estructura completa y bien razonada, con buena coherencia con 5 en la lógica de inspección y confirmaciones. Pero el flujo de cierre (quién dispara y quién pinta la tarjeta, dónde caben los créditos) se contradice con 21 y con el slice, y hay una fórmula y un contrato de reutilización de 25 sin sostén. Ninguno exige rediseño: son 5 bloqueantes corregibles en una pasada.

## 1. Completitud

Modo standard: Overview, Detailed Rules, Edge Cases, Dependencies, Acceptance Criteria y Formulas (hay números): todas presentes. Extras del proyecto presentes: Player Fantasy, Tuning Knobs, Decisiones tomadas, Open Questions, Cambios requeridos, Entradas para el registro, Historial. Sin secciones faltantes.

## 2. BLOQUEANTES

| ID | Ubicación | Problema | Arreglo propuesto |
|---|---|---|---|
| B-1 | Overview (flujo, línea «En partida -> "partida terminada" (4) -> Tarjeta»); regla 23; Dependencies fila 4 | Disparador del cierre mal atribuido. «Partida terminada» la emite 4 **al terminar la carga de Recepción** (5 regla 29; slice L356/L1080: la partida se sella al llegar a Recepción, t=0). La tarjeta aparece ~25 s después (21: `D_cierre`, slice L1028 «+2,0 fundido a negro, título, Continuará»). Decir que «el cierre empieza con "partida terminada"» es falso; el disparador real es «tarjeta final pedida» ‡ de 21, que 27 no lista en ninguna dependencia. | Sustituir el gatillo por «tarjeta final pedida» (21). Mantener «partida terminada» solo como causa del resultado `terminada` en 5. Añadir «tarjeta final pedida» a la tabla de Dependencies y a Cambios requeridos de 3/21. |
| B-2 | Summary y Overview L16 («21 pinta aquí la tarjeta final»); regla 23 («21 pinta la tarjeta final»); regla 24 (27 la muestra); 21 DT-4 | Contradicción interna y con 21: DT-4 de 21 dice que **la pinta 27** y 21 solo la pide. | Unificar: 27 pinta la tarjeta (con `t_tarjeta_s` de 21); corregir Summary, Overview y regla 23. |
| B-3 | Reglas 23–26 vs 21 reglas 22 (paso 8) y AC-21-28 | Secuencia tarjeta/créditos/descarga indefinida. 21 pide la descarga total **inmediatamente tras** la tarjeta y la pila queda en [`menú`] (≤3,0 s); 27 intercala «Créditos» después, sin decir si se muestran sobre la cortina con 4 en «Sin escena», ni quién repone `menú` primero, ni si la re-inspección de 5 (disparada por «descarga total completada») ya ocurrió cuando se llega al menú. La regla 23 además dice que, si 27 no está activo, 21 «pide a 4 la descarga total y la vuelta al título», lo que saltaría los créditos. | Definir la secuencia: tarjeta (27) -> descarga total (4) -> créditos (27, ya con `menú` y 4 en «Sin escena») -> menú. Pedir a 21 que confirme que su «vuelta al título» termina en 27, no en el menú directo (ya está en Cambios requeridos, pero la regla 23 lo contradice). Añadir AC de integración. |
| B-4 | F1 (`k_mov` = 0 -> `t_fundido` = 0) y reglas 5, AC-18 | La fórmula da 0 s, pero el texto dice «corte con atenuación de 0,15 s†»: el ejemplo contradice la fórmula y 0,15 s no es parámetro (no está en Tuning Knobs ni en el registro). | Reescribir: `t_fundido = t_fundido_base_s` si movimiento normal, `t_atenuacion_s` (0,15†) si `reducir_movimiento` o `reducir_sobresaltos`; añadir `t_atenuacion_s` a Tuning Knobs y registro. |
| B-5 | Regla 13, Dependencies fila 25, Cambios requeridos fila 25 | 27 reutiliza «tal cual» pantallas de 25 («Sonido y pantalla», «Accesibilidad», «Controles»), pero `menu-de-pausa.md` no define un componente reutilizable (grep sin resultados de «reutiliz») y lista sus pantallas como «pistas, sonido, accesibilidad, controles»; los rótulos «Sonido y pantalla» no coinciden verificablemente. Además la dependencia es **Blanda** en ambos lados aunque Opciones (y AC-14) no funcionan sin ese componente, y 25 no cita a 27 como consumidor del componente (solo «recibe al jugador tras Salir al título»). Recíproca incompleta (regla de bidireccionalidad). Además 25 es el dueño de la pantalla de accesibilidad solo en parte: el sistema 30 (Opciones de accesibilidad, con GDD `opciones-de-accesibilidad.md`) también escribe ajustes. | Alinear nombres con 25/30; endurecer a **Dura** (25 y 30) o declarar que 27 trae un fallback; añadir en 25 la fila «27 usa mis pantallas de nivel 2» y la exposición del componente. |

## 3. AVISOS

| ID | Ubicación | Problema | Arreglo propuesto |
|---|---|---|---|
| W-1 | Dependencies fila 6 (Dura) vs 6 fila 219 (27 = Blanda) | Dureza discordante. 6 dice que 27 es Blanda con él. | Alinear. Propuesta: Blanda en ambos (27 funciona con valores por defecto, ver Edge Cases «Ajustes ausentes»), contradiciendo la regla 1 solo en que las advertencias se tratan como no vistas. |
| W-2 | Dependencies fila 4 (Blanda) | 5 trata el vínculo con 4 como contrato duro (eventos «carga de escena fallida/terminada», «descarga total completada»). Regla 20 y AC-12 no funcionan sin ellos. | Subir a Dura, o explicar por qué es blanda. |
| W-3 | Índice `systems-index.md` L51 | El índice lista deps de 27 como «1, 3, 5, 6, 18» y omite 4, 21, 23, 25, 30 (blandas del GDD). 21 declara «sin dependencia» de 27 y 23 deriva el silencio de 27 por defecto. | Actualizar el índice con las blandas y la nota de ciclos. |
| W-4 | Reglas 20–21 y 25 L203 | 25 dice «4 repone `menú` con el mensaje de error y "Volver al título" (4 regla 14)»; 27 dice que 27 presenta el panel y 4 repone `menú` tras la descarga. Reparto del mensaje de error ambiguo (4 vs 27). | Una sola frase en ambos: 27 presenta; 4 solo repone `menú`. Verificar contra 4 (sin verificar: no leído). |
| W-5 | Reglas 9 y 18; AC-09 | El aviso `con_futura` de 5 (UI Requirements) incluye que **el siguiente guardado reemplaza la más nueva** (queda copia en `autosave.incompatible`). 27 lo reduce a «Continuar usa la última copia compatible». Se pierde información que afecta a la pérdida de datos. | Incluir la advertencia de reemplazo en el texto o justificar el recorte. |
| W-6 | Tabla de estados (Overview) | No cubre combinaciones: `terminada` con `irrecuperable`/`version_futura` (edge case solo trata `terminada`+`con_futura`); `irrecuperable`+`con_futura`. | Añadir fila o regla de precedencia general (`terminada` manda sobre el resto). |
| W-7 | Regla 9 vs 5 | «Lee el resultado cada vez que entra al menú» pero 5 re-inspecciona al llegar «descarga total completada»; no está definido si 27 puede leer antes (resultado viejo). El edge case «27 solo muestra el menú cuando 5 está en Sin partida» es un buen candado pero no figura en las reglas ni en un AC. | Pasarlo a regla (R9) y añadir AC: no se pinta el menú hasta que 5 esté en «Sin partida» con re-inspección terminada. |
| W-8 | Regla 24 + F2 + AC-17 | Dos modelos: «no exige pulsar para empezar y no se puede saltar en 1,5 s» pero 21 DT-4 espera `t_tarjeta_s` sin salto; F2 define `t_saltable` con un nombre que no cuadra con su ejemplo («ve la tarjeta entre 3,0 y 3,8 s»). Falta AC positivo (saltar tras 1,5 s). Y un salto desde la tarjeta es una funcionalidad no pedida por el slice. | Decidir: tarjeta fija de 3,0 s sin salto (como el slice, L291/L1028) o salto con AC propio; limpiar F2. |
| W-9 | Reglas 25/27, Tuning `creditos_paginas`, AC-16 | Los créditos de 1–3 páginas y su contenido («equipo, herramientas, declaración de IA») no tienen entradas concretas en 18; sin verificar el catálogo. Faltan AC para la navegación de páginas y para «Volver al título». | Añadir AC y la lista de claves `UI_TITLE_CREDITS_*` a Cambios requeridos de 18 (ya parcialmente). |
| W-10 | Regla 19 | «Se anuncia por la capa de accesibilidad de pantalla (si el motor la ofrece)». AccessKit entró en Godot 4.5 según `docs/engine-reference/godot/VERSION.md`; en 4.7 el soporte real en `Control` no está verificado aquí. Afirmación no verificada. | Citar la sección concreta de `docs/engine-reference/godot/` o convertirlo en OQ de implementación; no prometer anuncio. |
| W-11 | Regla 14 y OQ 6 | «Llamando a `quit`»: ambiguo (en 5 `quit` es una *causa de guardado*); la llamada de Godot es `get_tree().quit()` (API estándar, estable en 4.x, pero no verificada en esta referencia). Además la regla dice «solo en PC» y la OQ 6 pregunta por consolas/Steam Deck (Steam Deck es PC; consolas fuera de alcance). | Reescribir: «cierra el árbol de escenas (`SceneTree.quit()`)». Descartar consolas de la OQ 6. |
| W-12 | Regla 30 | «Al desconectarse el mando en el título, no hay panel de pausa»: 25 define el panel «Mando desconectado»; que no salga en el título debe estar reflejado en 25 (solo `pause_opened` en el título queda dicho) y en Entrada (1). | Añadir la excepción en 25 y 1. |
| W-13 | Entradas para el registro | `t_fundido_base_s` (0,8 s†) duplica el fundido propio de 21 (0,8 s†); `t_espera_inspeccion_s` figura en Tuning y registro pero la regla del edge case dice «se registra» sin definir qué. `entities.yaml` no revisado: comprobar duplicados y que `UI_TITLE_*` no choque con claves existentes. | Reutilizar la constante de 21 o documentar la independencia; verificar registro. |

## 4. Advertencias y contenido sensible (slice §17, D-06, pilares)

- Las cinco advertencias coinciden literalmente con §17 (estrés laboral, aislamiento, decepción afectiva, llanto contenido, dinámicas de control y de desigualdad en una relación de trabajo). Correcto.
- Línea de cierre «El juego no tiene violencia gráfica ni referencias a autolesiones»: refleja las reglas de contenido de §17, pero §17 es una lista de **reglas internas** para el equipo, no un texto al jugador. Convertirla en promesa pública es una decisión de tono/legal (si el slice se modifica y aparece algo, se incumple) y de clasificación (D-06 sigue abierta). No está en OQ. Elevar a Open Question o quitarla.
- Falta además cualquier mención a «ningún personaje da instrucciones explícitas sobre cómo sentirse»: no hace falta mostrarla.
- «Salir del juego» en las advertencias y la ausencia de bloqueo: bien alineado con autonomía y con «tensión sin castigo».
- D-06: «no se muestra etiqueta» como valor por defecto es coherente. OK.
- La pantalla se muestra «solo la primera vez» y se reabre en Opciones: razonable. Pero si se actualizan las advertencias entre versiones, `advertencias_vistas` booleano no reactiva su muestra. Considerar versionarlo (`advertencias_version_vista`) o fijar que el slice no cambia.

## 5. Decisiones que rozan pilares/tono/alcance sin elevar a OQ

1. **Créditos de 1–3 páginas con equipo, herramientas y declaración de IA** (reglas 25, `creditos_paginas`, OQ 4): el slice solo prevé «Título (3 s). Rótulo "Continuará"» (L291, L1028). Los créditos son alcance nuevo; OQ 4 solo pregunta por la declaración de IA, no por la existencia de la pantalla. Elevar.
2. **Fila «Avisos de contenido» en Opciones y pantalla de lectura** (reglas 13/17): alcance y decisión de producto; menor, pero no figura en OQ.
3. **Promesa de contenido** («sin violencia gráfica ni autolesiones»): tono/legal (ver sección 4).
4. **Tarjeta saltable** (regla 24): decisión de feel de un cierre que el slice define como corte fijo.
5. **Rótulo de versión de compilación** (regla 7): no está en el slice; menor.
6. **Silencio total del título**: bien elevado en OQ 1 con valor por defecto; la propia 23 (R27) arranca capas en «escena lista», consistente. Verificado.

Pilares: la decisión de que Continuar no tenga confirmación y que Nueva partida con partida activa la tenga (foco en Cancelar), y el panel de error sin rojo y con una sola acción, respetan «Tensión sin castigo» y «Autonomía». No se ve contradicción de pilares (`game-pillars.md` no leído; basado en el encabezado del GDD y en 23/25).

## 6. Afirmaciones sobre Godot 4.7

- Regla 19: capa de accesibilidad de pantalla (AccessKit, 4.5+): no verificada para 4.7 (W-10).
- Regla 14: `quit`: no verificado (W-11).
- Regla 30: desconexión del mando (`Input.joy_connection_changed`, API estable): no se nombra; no hay afirmación errónea.
- 4K/720p y escalado de interfaz: no se afirma nada de motor. Sin otras afirmaciones sobre 4.7.

## Verificado correcto

- Estados del menú frente a 5 (UI Requirements, reglas 25 y 29): `ninguna`, `valida`, `terminada`, `irrecuperable`, `version_futura`, `con_futura` y las confirmaciones (solo `valida` sin `terminada` y `version_futura`; `terminada` sin confirmación) coinciden con 5 y con slice L356.
- Nombres y APIs de 5 usados: `continuar()`, `nueva_partida()`, «Cargando partida», «Sin partida», fallo de carga con resultado inalterado, re-inspección tras «descarga total completada». Coinciden.
- 27 no pide `planta` (solo 5; AC-18f de 5 lo prueba) y AC-11 es coherente.
- «Partida terminada» emitida solo por 4 (5 regla 29): 27 solo la consume (aunque la usa mal, B-1).
- Avisos de `irrecuperable`/`version_futura` no modales, una vez por arranque: coincide con 5. `Continuar` ausente (no desactivado): permitido por 5 («lo decide el diseño UX»).
- 25 no emite `pause_opened` en el título y no tiene «Salir del juego»: coherente con reglas 13 y 14 de 27.
- 23: drone en «escena lista» (R27 de 23), silencio en el título es compatible; cerrar OQ 3 de 23 es válido (falta confirmar en 23 que no está ya cerrada de otro modo, sin verificar la OQ).
- `t_tarjeta_s` = 3,0 s (21) y rótulo «Continuará» (18, 21) coinciden con el slice.
- Las cinco advertencias del slice §17 se reproducen literalmente.

## Acciones sugeridas antes de aprobar

1. Corregir B-1, B-2 y B-3 (flujo de cierre) con 21 y 4 en la misma pasada.
2. Corregir B-4 (F1) y B-5 (reutilización 25/30, reciprocidad).
3. Resolver W-1, W-2, W-3, W-4, W-5 y W-8 (consistencia de dependencias, textos y tarjeta).
4. Elevar a Open Questions: créditos (alcance), promesa de contenido, versionado de advertencias.
5. Pasada final de nombres con 18 y `entities.yaml` (no hecha por falta de presupuesto de lectura).
