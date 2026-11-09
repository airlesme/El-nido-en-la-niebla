# Re-review independiente: Estado del juego y bus de eventos (sistema 3)

> **Fecha:** 2026-11-09 · **Modo:** lean, revisor independiente (no autor) · **Workflow:** `standard` (`modes.rigor: standard`)
> **Documento:** `design/gdd/estado-y-bus-de-eventos.md` (35 KB, última edición 2026-11-09, «lote 2/5/7/9»)
> **Revisión previa:** 2026-11-08, NEEDS REVISION, arreglos aplicados (ver `estado-y-bus-de-eventos-review-log.md`).
> **Contrastado con:** `design/slice/slice-v0.3.md` (D.2, D.3, B.6), `systems-index.md`, `game-pillars.md`, `design/registry/entities.yaml` y los GDDs 1, 2, 4, 5, 6, 7, 9 y 18.
> **El GDD no se ha modificado. Sin commit.**

## Veredicto: NEEDS REVISION

El núcleo de diseño (catálogo cerrado, un dueño por hecho, valor inmediato y aviso encolado, restauración síncrona) es sólido y coherente con el slice y con los pilares. Lo que falla es la propagación del lote 2/5/7/9 y de los GDDs 4, 6 y 9: el contrato de avisos (regla 10) y la tabla de lectores están desfasados respecto a lo que los dependientes ya emiten y leen, y hay una contradicción semántica abierta sobre `pendiente_revelacion`. Ningún hallazgo cuestiona los pilares; todos se arreglan editando este GDD.

## Completeness (tier `standard`)

| Sección | Estado |
|---|---|
| Overview | Presente |
| Detailed Rules (`## Detailed Design`) | Presente |
| Edge Cases | Presente |
| Dependencies | Presente (desfasada, ver H-05) |
| Acceptance Criteria | Presente (31 CA con evidencia L/I) |
| Formulas | No requerida: el sistema no define reglas numéricas (solo el tope `max_chained_notices`, que es un knob) |
| Player Fantasy | Ausente. Advisory a este tier; el Overview cubre la intención. No bloquea |
| Tuning Knobs | Presente (1 knob, con rango y efecto) |

Grafo de dependencias: todos los GDD existentes citados existen (1, 4, 5, 7, 9). Los sistemas 8, 10, 17, 19 a 23, 27 y 28 no tienen GDD aún; es esperable.

## Hallazgos

### H-01 (bloqueante) Regla 10 no incluye los avisos que ya emiten Escena de planta (4), Audio (23) y Menú de pausa (25)

- **Dónde:** regla 10; tabla «Otras interacciones»; CA-11.
- **Evidencia:** el GDD 4 (reglas 5 y 15, tabla de interacciones, «Cambios requeridos» nº 1) declara «carga de escena iniciada», «escena lista», «carga de escena terminada» y «zona activada» y pide añadirlos a la regla 10. El GDD 9 (regla 8) depende de «escena lista» y recibe «línea terminada», «línea sin audio» y «línea fallida» de Audio (23, regla 20). El GDD 5 usa `pause_opened` (emisor 25). Ninguno aparece en la regla 10. Es el mismo defecto que la revisión anterior marcó para el sistema 1 y que se corrigió solo para 1, 5, 7 y 9.
- **Efecto:** la regla 10 se presenta como el contrato de avisos con nombre, y deja fuera tres emisores. CA-11 no los prueba.
- **Arreglo:** añadir a la regla 10, al cuadro de Dependencies y a CA-11 los avisos de 4 (cuatro), de 23 (tres respuestas de línea) y de 25 (`pause_opened`). Cambiar la redacción de la fila 4 («lee hechos al cargar la escena»): según el GDD 4 (regla 6) la lectura la hacen los elementos de la escena, no el sistema 4; el GDD 4 ya pide ese cambio.

### H-02 (bloqueante) `pendiente_revelacion` contradice al GDD 9 y a la letra del slice

- **Dónde:** regla 5 («verdadero mientras la revelación del puzle 5 está interrumpida, falso al completarse»); tabla de hechos; States and Transitions.
- **Evidencia:** el GDD 9 (regla 19 y Cross-References) escribe `pendiente_revelacion = verdadero` **al iniciar** la secuencia, no al interrumpirla, y lo declara «desvío puntual de D.2». El slice D.2 dice «Puzle 5 (si se interrumpe)». El GDD 3 sigue el slice; el 9 no.
- **Efecto relacionado:** el GDD 9 (regla 19 y edge case) admite el estado `caja_c3 = verdadero` con `pendiente_revelacion = verdadero` entre dos escrituras, y puede acabar en una instantánea. El Edge Cases del GDD 3 solo cita combinaciones incoherentes de la llamada y no cubre esta.
- **Arreglo:** decidir la semántica (ver Pregunta 1). Alinear regla 5, tabla y CA-05. Añadir a Edge Cases de restauración la combinación `caja_c3 ∧ pendiente_revelacion`: se restaura tal cual y, por contrato, el marco (9) limpia el hecho.

### H-03 (importante) La tabla de lectores está incompleta frente a los dependientes ya redactados

- **Dónde:** tabla de hechos («Lee») y fila 21 de Dependencies.
- **Evidencia:**
  - `llamada_iniciada`: el GDD 5 (regla 28 y fila 21) hace que el director de escenas (21) decida la reanudación con `caja_completa ∧ ¬llamada_iniciada`. La tabla lista solo 22 y 5 como lectores, y la fila 21 no lo incluye.
  - El GDD 7 (reglas 8 y 29, Dependencies) lee hechos arbitrarios en `habilitado_si` por paso de física. La columna «Lee» no menciona a 7 en ningún hecho, aunque la fila 7 de Dependencies sí le asigna lectura.
  - El GDD 5 reinterpreta `llamada_iniciada` como marca de sellado (regla 12, «reinterpreta D.2») y fija una restricción de emisión que ahora debe cumplir el GDD 22. El historial de cambios lo menciona pero la regla 3 de Detailed Design y la tabla siguen con la semántica de D.2.
- **Arreglo:** añadir 21 (y 7 como lector genérico mediante `habilitado_si`) a «Lee»; añadir `llamada_iniciada` a la fila 21; anotar en la fila de `llamada_iniciada` la lectura de sellado de 5 y su restricción de momento de emisión.

### H-04 (importante) Contratos de interfaz que los dependientes necesitan y el GDD no define

- **Dónde:** reglas 9, 11, 13; Edge Cases «Guardado y pruebas»; CA-25.
- **Evidencia y huecos:**
  1. **Cola vacía.** El GDD 5 (regla 5 y variable `cola_vacía`) necesita saber que la cola del 3 está vacía antes de capturar. El GDD 3 dice «el guardado espera», pero no expone ninguna consulta ni señal de «cola vacía» ni dice quién espera ni si la petición de instantánea es síncrona o diferida. Dos implementadores pueden resolverlo de formas incompatibles.
  2. **Granularidad de suscripción.** El GDD 9 se suscribe a los cambios de los hechos de `requires.all`; la regla 9 no dice si se puede suscribir por hecho o solo a todos los cambios, ni si los avisos con nombre se filtran por nombre.
  3. **Tipos en la restauración.** La regla 6 rechaza un `float` en un `int` «sin conversiones». La instantánea llega del GDD 5 desde JSON, y no se define si los valores `int` leídos de un fichero se tratan como `int` o se rechazan. En Godot 4.7 no se puede afirmar cómo el analizador JSON tipa los números: **NOT SOURCEABLE** (`docs/engine-reference/godot/` no cubre JSON ni tipado de `Variant`). Tampoco se dice qué hace la restauración con un `pos_*` recibido como `2.0`.
- **Arreglo:** (1) añadir una consulta de solo lectura `cola_vacía` y fijar que la instantánea la sirve el sistema 3 de forma síncrona y con la cola vacía, o que 5 espera por esa consulta; (2) fijar en la regla 9 que se admite suscribirse a un hecho concreto y a todos; (3) en la regla 13, definir la regla de tipos para valores restaurados (propuesta: un `int` representado como número entero exacto se acepta) y delegar la verificación del comportamiento JSON del motor a un ADR/prueba de ida y vuelta (el GDD 5 ya tiene AC-30c).

### H-05 (importante) Cross-References, bidireccionalidad y Open Questions están obsoletas

- **Dónde:** Cross-References (primera línea); párrafo «Bidireccionalidad»; fila 17 de Dependencies; Open Questions 1, 4 y 6; cabecera (`Status`, `Last Updated`).
- **Evidencia:**
  - «Ningún otro GDD existe todavía» y «del resto de sistemas dependientes ninguno tiene GDD aún» son falsos: existen 1, 2, 4, 5, 6, 7, 9 y 18. Además, 4, 5, 7 y 9 listan al 3 y esperan que el 3 los liste a ellos con nombres concretos. Faltan en Cross-References todos esos GDD.
  - La fila 17 dice «(**no está en el índice**)» y el párrafo siguiente dice que la fila 17 del índice ya lista el 3. Se contradicen; el índice sí tiene la fila 17 con `3, 9, 18`.
  - Open Question 1 (identificadores `P1`…`P6`) está resuelta por el GDD 9 (D9-13, que lo confirma). La 6 (¿`memo_leido` lo lee 21?) no tiene respuesta en ningún GDD y el slice D.2 dice «Pistas, recompensa de B»; la tabla y Dependencies siguen asignando `memo_leido` al 21.
  - Dependencies no menciona el sistema 6 (Ajustes), que declara un mecanismo propio de avisos «con las mismas reglas que el bus, sin depender de él», con su propio tope de cadena. Eso duplica el contrato; conviene decir en este GDD que no pasa por el bus, y que el ADR del bus debería ser el mismo para ambos.
  - Estado: el documento dice `In Design` y el índice `In Review`.
- **Arreglo:** reescribir Cross-References y Bidireccionalidad con los GDD reales; corregir la fila 17; cerrar la Open Question 1; resolver o reasignar la 6 (el slice solo sustenta pistas y recompensa de B); añadir 6 y 25/26 como no-lectores; unificar el estado con el índice.

### H-06 (importante) El tope de avisos encadenados puede perder avisos que son causas de guardado

- **Dónde:** Edge Cases «Escrituras y orden» (tope), Tuning Knobs, regla 8.
- **Evidencia:** en la build final, al alcanzar el tope «se descarta el resto de la cola». El GDD 5 (regla 6 y tabla de causas) usa como causas de autoguardado avisos de cambio y de puzle (`puzzle_solved:<ID>`, `compartment_done`, `reveal_pending`, apertura de puerta). El GDD 3 dice que los sistemas deducen el estado de los hechos y no de los avisos (regla 8), pero un guardado disparado por un aviso descartado se pierde hasta la siguiente causa.
- **Arreglo:** que el descarte de cola emita siempre un aviso de sistema («cola truncada», registrado) para que Guardado (5) pida un guardado, o que se documente que el tope jamás se alcanza con el flujo previsto (la cadena más larga, `carta_variante → caja_c4 → caja_completa → …`, es corta frente a 64) y se añada un CA que lo compruebe con el recorrido completo del slice.

### H-07 (importante) El registro de entidades no contiene nada de este sistema

- **Dónde:** `design/registry/entities.yaml`.
- **Evidencia:** el único vínculo es `save_fail_warn_count` (referenciado por el 3). Los 19 hechos con tipo y valor inicial, `snapshot_version = 1`, y el tope por defecto (propuesta 64) cruzan fronteras de sistema (5, 7, 9, 21, 22) y no están registrados. Los GDDs dependientes usan los nombres sin una fuente que los fije.
- **Arreglo:** registrar los 19 hechos (o al menos los de valor inicial no trivial: `pos_*` = 2, enums sin fijar), `snapshot_version` y los avisos con nombre, con `source: design/gdd/estado-y-bus-de-eventos.md`.

### H-08 (menor) Criterios de aceptación y notas finales

- CA-11, CA-17, CA-25, CA-26, CA-28, CA-29 y CA-31 son de tipo I y dependen de sistemas sin escribir (CA-11 y CA-31 lo reconocen; los demás no). Conviene marcar cuáles son testeables hoy con un emisor de prueba.
- CA-23 pide a un «doble de prueba» ejecutar código dentro de la restauración, lo que el propio GDD declara imposible; la redacción es válida como prueba negativa, pero debería decir que el doble se invoca desde el propio código de restauración mediante un gancho de pruebas.
- No hay nota de rendimiento: el GDD 7 lee hechos cada paso de física para 35 objetos; basta una línea que exija que la lectura sea de coste constante y sin asignaciones.
- Las referencias a gdUnit4 se apoyan en `CLAUDE.md` del proyecto, no en `docs/engine-reference/godot/` (no figura allí): **NOT SOURCEABLE** como afirmación del motor, aceptable como decisión de proyecto.

## Consistencia con el slice y con los pilares

- **D.2:** los 19 hechos, tipos y valores iniciales coinciden (6 + 3 pos + 4 caja + `pendiente_revelacion` + `caja_completa` + `carta_variante` + 3 de llamada = 19). Desvíos legítimos: `caja_completa` derivado (equivalente a B.6) y `pendiente_revelacion` (H-02).
- **P6 con dos niveles de pista (decisión del usuario, 2026-11-09):** el GDD 3 no fija el número de niveles ni crea hechos por nivel, solo lista «pista aplicada» como aviso del marco. No hay conflicto. El sistema 17 sigue leyendo solo `formulario_leido` y `memo_leido`; no hace falta ningún hecho nuevo para el nivel que falta.
- **D.3 (guardado):** el comportamiento de sellado de la llamada del GDD 5 es compatible con las reglas 4 y 13, y con CA-22.
- **Pilares:** «Tensión sin castigo» y «Información incompleta» servidos; sin contradicciones.

## Preguntas para el usuario

1. **`pendiente_revelacion`: ¿se confirma el desvío del GDD 9 sobre el slice D.2?** El slice dice que se activa «si se interrumpe»; el marco de puzles lo escribe al iniciar la revelación y lo limpia al terminar. La segunda opción hace el estado más robusto ante cierres forzados, pero cambia el texto de D.2 (ya tiene tu aprobación para tocar el slice en este lote). Recomendación: confirmar el desvío y actualizar D.2 y el GDD 3.

No hay más preguntas que cambien pilares, tono o alcance.

## Alcance estimado

Rough scope signal: M (el sistema es pequeño; el trabajo es de propagación y de contratos). Un ADR sigue pendiente para el formato de avisos, el mecanismo de `owner` y la instantánea (Open Questions 2, 3, 7), y debería cubrir también el mecanismo de avisos del GDD 6.

## Cambios requeridos en otros GDDs

Ronda 2 (2026-11-09). El GDD 3 ya está corregido; esto debe hacerse fuera de él.

1. **`design/slice/slice-v0.3.md` D.2:** `pendiente_revelacion` se escribe al iniciar la revelación del puzle 5 y se limpia al terminar (no «si se interrumpe»); `llamada_iniciada` no evita repetir la llamada, marca el sellado del guardado (GDD 5).
2. **GDD 5 (Guardado):** adoptar el contrato de instantánea (GDD 3, regla 13): `cola_vacía()` de solo lectura y petición síncrona que devuelve «no disponible» con la cola no vacía, sin esperar; tratar «avisos descartados» como causa de guardado; confirmar que su causa `pause_opened` la emite 25.
3. **GDD 22 (Llamada, sin redactar):** escribir `llamada_iniciada` inmediatamente antes de emitir «llamada iniciada»; listar al 3 con los nombres de la tabla.
4. **GDD 21 (Director de escenas):** leer `llamada_iniciada` (reanudación `caja_completa ∧ ¬llamada_iniciada`); confirmar o retirar la lectura opcional de `memo_leido` en Recepción.
5. **GDD 8, 10, 19, 20, 23, 25, 26, 27, 28 (sin redactar):** listar al 3 como dependencia; 8 emite «puerta abierta»; 23 emite «línea terminada/sin audio/fallida»; 25 emite `pause_opened`.
6. **GDD 6 (Ajustes) y ADR de avisos:** unificar el mecanismo de aviso de cambio con el del bus (mismo ADR, mismo tope de cadena).
7. **`design/registry/entities.yaml` (H-07):** registrar los 19 hechos (tipo, valor inicial, `owner`), `snapshot_version = 1`, `max_chained_notices` y los avisos con nombre, con `source: design/gdd/estado-y-bus-de-eventos.md`.
8. **`design/gdd/systems-index.md`:** estado de la fila 3 a «Revisado (ronda 2)».
9. **GDD 9 (Marco de puzles):** ninguno; este GDD asume su regla 19 y que limpia `pendiente_revelacion` en silencio al restaurar `caja_c3 ∧ pendiente_revelacion`.
