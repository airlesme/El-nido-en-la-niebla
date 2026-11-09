# Re-review independiente: Ajustes persistentes (sistema 6)

Fecha: 2026-11-09 · Revisor: independiente (no autor) · GDD: `design/gdd/ajustes-persistentes.md`
Contexto: `modes.rigor: standard` (no hay `modes.workflow` explícito, se hereda `standard`): requeridas Overview, Detailed Rules, Edge Cases, Dependencies, Acceptance Criteria + Formulas (el sistema define cifras). Todas presentes. Player Fantasy y Tuning Knobs no son obligatorias en este nivel (ver hallazgo 11).

## Veredicto: NEEDS REVISION

Diseño sólido y mucho mejor que en la revisión del 2026-11-08: el bloqueante anterior (orden «Listo» / «ajustes aplicados») está resuelto y coherente entre regla 10, tabla de estados y AC-12. F1, F2 y F3 se recalcularon y los ejemplos son correctos (n = 10 para 0,512; −38 dB / 0,0126 en n = 1; −47,5 dB / 0,0042 con db_min = −50; tercera escritura del arrastre en t = 12,5). Quedan incoherencias de contrato con vecinos, una laguna de validación en el ajuste nuevo `campo_vision` y trabajo de registro pendiente. Ninguno es de diseño profundo; todos se arreglan en una pasada.

El P6 con dos niveles de pista no afecta a este sistema: las pistas son estado de partida (3, marco 9 reglas 25 a 27, menú 25), no ajustes. Tampoco figura ningún ajuste de pistas en el catálogo, lo cual es correcto (ver hallazgo 10).

## Hallazgos

### Importantes

1. **[importante] Dependencias: el sistema 2 falta en Dependencies y Cross-References.** La regla 1 y la tabla de interacciones lo incluyen como lector de `balanceo_camara` y `campo_vision` (con GDD 2 reglas 16 y 17 y su sección de dependencias que lista a Ajustes como blanda), pero la tabla «Aguas abajo» (líneas 202 a 212) y la fila de Cross-References «dependientes 5, 23, 25, 26, 27, 28, 30, 13 y 15» (línea 254) no lo nombran. Tampoco aparece el marco de puzles (9), que es quien realmente lee `asistencia_*` (su tabla lo lista como blanda). Arreglo: añadir filas «2 Jugador · Blanda» y «9 Marco de puzles · Blanda» y actualizar la fila del índice en Cross-References.

2. **[importante] Entrada (1) no recibe «ajustes aplicados» en su GDD.** El GDD 6 (línea 82) dice que Entrada recibe ese aviso al arrancar; `entrada-y-controles.md` no contiene la cadena «ajustes aplicados» y su tabla (línea 118) solo dice «Bloque guardado, al arrancar». La bidireccionalidad afirmada («par cerrado», línea 216) es cierta para la dependencia, pero no para el contrato de señales. Arreglo: o bien registrar en Entrada que importa el bloque al recibir «ajustes aplicados» (nota de propagación, no se edita aquí), o bien definir en el GDD 6 que Entrada lee `controles` en su propia inicialización (pull) tras Listo. Decidir uno y que ambos coincidan.

3. **[importante] `campo_vision` (paso 5) no tiene regla de cuantización/validación.** La regla 6 y la regla 10 cuantizan solo los volúmenes (F1). Para `campo_vision` (float 60 a 90, paso 5) no se dice qué ocurre con 72 (escritura o fichero), ni si «cambio real» se decide por paso (regla 7, que hoy compara valores). Un fichero con 72 o un deslizador con paso distinto produciría avisos y marcas de pendiente espurios. Arreglo: generalizar F1 («los `float` con paso se redondean a su rejilla antes de comparar») o declarar `campo_vision` como `enum` de 7 valores; añadir AC (72 → 70; 90,0 → 90; fuera de rango → límite) a AC-05/AC-09.

4. **[importante] El bloque `controles` no encaja en las reglas de aviso, escritura y tipo.** El catálogo admite tipos `bool`/`float`/`enum`, pero `controles` es «bloque opaco» (regla 2). No se define: (a) si su cambio emite aviso (regla 7 pide clave, anterior, nuevo: tres datos con un bloque entero dentro); (b) qué es «cambio real» sin interpretar el contenido (¿igualdad profunda?); (c) qué valida la regla 6 (un bloque con tipo incorrecto). Y AC-04a/AC-04b solo cubren guardar/recargar. Arreglo: fijar que `controles` no emite aviso de cambio salvo marca de pendiente por igualdad profunda, o que sí lo emite sin cargar valores; añadir una línea al catálogo («tipo: bloque, validación delegada»).

5. **[importante] Dependencia con Guardado y carga (5) obsoleta.** El GDD 6 sigue con «A confirmar» (línea 212), «pendiente» (línea 214) y Open Question 6(b), pero `guardado-y-carga.md` ya la retiró (regla 4; D-12; línea 302) y el índice (línea 109) ya no la lista. Arreglo: cerrar OQ 6(b) como «retirada», dejar la fila 5 como «Ninguna (ficheros independientes)» y quitar 5 de la lista de Cross-References. Comprobar que `systems-index.md` línea 240 (re-review pendiente de 6) se actualiza al cerrar la revisión.

6. **[importante] «Reducir movimiento» (MVP) sin clave en el catálogo.** El art bible §7.4 la define como opción (fundido fijo de 100 ms, cambio estático en lugar de temblor) y afecta al feedback de error de los puzles, que es MVP; `escena-de-planta.md` (línea 307) la cita y remite a «OQ 9 del GDD 6». Hoy está solo en una Open Question genérica, sin clave, tipo ni lector, de modo que ni el marco (9) ni el menú (25) pueden diseñarse contra ella. El slice no la menciona (§5, §14, §16 listan subtítulos, remapeo, volúmenes y reducir sobresaltos), así que añadirla es decisión de alcance: ver «Preguntas para el usuario». Si se acepta: `reducir_movimiento` bool · falso, lectores 9 (puzles) y 21/27 (cortina).

7. **[importante] Registro de entidades sin los valores del sistema.** `design/registry/entities.yaml` no contiene `N_pasos`, `db_min`, `t_guardado`, `t_guardado_max`, la curva de volumen ni las claves de ajuste con rango (solo `asistencia_encaje` 0,10 m, línea 532). La Open Question 13 lo reconoce («al cerrar el GDD») y la revisión de 2026-11-08 ya lo pidió. `asistencia_rotacion` ±6° y la tolerancia normal de 3° del marco (tabla de la línea 295) tampoco figuran. Arreglo: registrar F2 (`volume_curve_db`), `volume_steps`, `volume_db_min`, `settings_save_debounce_s`, `settings_save_max_wait_s`, los ocho defaults de la regla 1 y las claves como constantes entre sistemas (consumen 2, 9, 23, 25, 30).

### Menores

8. **[menor] Valor «seguro» antes de Listo contradice el catálogo.** Edge Cases línea 173 y AC-17b fijan `modo_ventana` = `ventana` como valor seguro, mientras que el inicial del catálogo es `pantalla_completa`. Puede ser intencional (no tocar el monitor antes de saber), pero no se justifica. Arreglo: una frase de motivo, o unificar.

9. **[menor] Escena de planta (4) trata a Ajustes como nodo persistente y el GDD 6 no menciona esa condición.** `escena-de-planta.md` regla 1 y su AC-01 requieren que el nodo de Ajustes sobreviva a los cambios de escena (mismo `get_instance_id()`). El GDD 6 no lista al 4 en Dependencies ni en la Open Question 3 (orden de arranque). Arreglo: añadir una línea «sobrevive a los cambios de escena (4, regla 1)» y la fila 4 en Dependencies (bidireccionalidad según `design-docs.md`).

10. **[menor] Aclarar que las pistas no son ajustes.** Con el P6 en dos niveles y la discrepancia ya declarada en marco regla 27, conviene una frase en el GDD 6 («los niveles de pista y su uso son hechos de partida, no ajustes») para evitar que 25 o 30 los coloquen aquí. Arreglo: una línea en regla 3.

11. **[menor] Faltan las secciones Player Fantasy y Tuning Knobs.** No son obligatorias en `standard`, y la revisión previa ya lo señaló como NICE. El Overview cubre la fantasía; los rangos están dispersos en F1 a F3. Arreglo opcional: tabla única de Tuning Knobs con `N_pasos`, `db_min`, `t_guardado`, `t_guardado_max` y rangos seguros.

12. **[menor] Redondeo en el límite.** F1 usa `round(v_ui × N_pasos)`; en 0,025 × 20 = 0,5 el resultado depende de la convención de redondeo. AC-F1 evita el caso (0,026 y 0,024). Arreglo: declarar «redondeo de la mitad hacia arriba» o aceptar la ambigüedad.

13. **[menor] Aviso de cambio del texto UI.** UI Requirements fija «restablecer todos» con confirmación y `ui_izquierda`/`ui_derecha` (Entrada regla 15). Verificado contra el GDD 1; sin discrepancia. Nota: los rótulos `UI_…` de ajustes siguen sin anticiparse en el GDD 18 (OQ 11), pendiente.

## Contraste con el motor (Godot 4.7)

- Respaldado: `FileAccess.store_*` devuelven `bool` desde 4.4 (`docs/engine-reference/godot/breaking-changes.md`, línea 91). Es la única afirmación de motor que usa el GDD y es correcta.
- **NOT SOURCEABLE** en `docs/engine-reference/godot/`: ruta de datos de usuario y escritura atómica (renombrado de temporal, `DirAccess`), detección del fallo del renombrado (AC-10c, AC-15a), cambio de modo de ventana y su rechazo por el sistema operativo (`DisplayServer`; regla 12, OQ 4), conversión de volumen a bus (`AudioServer`; hay `modules/audio.md`, no revisado a fondo en esta pasada) y representación de NaN en JSON. El GDD ya remite todo esto a un ADR (OQ 1 a 4); no añade afirmaciones sin respaldo. Sugerencia: ampliar OQ 4 para decir que `DisplayServer` tampoco tiene referencia local.

## Consistencia verificada sin discrepancia

- Catálogo (diez claves con valor + `controles`) coincide con AC-01, con «restablecer todos» (regla 8) y con los GDD 2 (nombres de enum `completo`/`reducido`/`ninguno`, inicial `reducido`, FOV 60 a 90, inicial 70) y 9 (`asistencia_encaje` 0,10 m; `asistencia_rotacion` ±6°).
- Los ajustes quedan fuera de la instantánea y del guardado: coherente con el GDD 3 (regla 14), el GDD 5 (regla 4, AC-02) y el índice.
- `systems-index.md` fila 6: dependencia solo del 1, correcta.
- Pilares (*Tensión sin castigo*, *Autonomía como progresión*): sin deriva.
- Slice: los tres volúmenes (§14), reducir sobresaltos, remapeo, subtítulos y «asistencia de encaje» (B.3) cubiertos; `asistencia_rotacion` es una extrapolación de B.5 ya marcada como provisional (OQ 5).

## Preguntas para el usuario

1. **¿Entra «Reducir movimiento» (art bible §7.4) en el catálogo MVP del slice?** El slice v0.3 solo exige subtítulos, remapeo, tres volúmenes y reducir sobresaltos. Añadirlo amplía el alcance de accesibilidad (afecta al feedback de error de los puzles y a la cortina de escena) pero el art bible ya lo da por hecho. Mi recomendación, si no hay objeción: sí, como `reducir_movimiento` bool.

## Cambios requeridos en otros GDDs

Aplicada la ronda 2 al GDD 6 el 2026-11-09 (hallazgos 1 a 12; el 13 sin acción). Pendiente fuera de este GDD:

- **GDD 1 Entrada y controles:** registrar que importa el bloque `controles` al recibir «ajustes aplicados» (GDD 6, interacciones) y que el aviso de cambio de `controles` lleva solo la clave. Añadir «ajustes aplicados» a su tabla (línea ~118).
- **GDD 2 Jugador:** sin cambios de contrato; `campo_vision` se cuantiza a paso 5 (72 pasa a 70); confirmar que usa `fov_actual()`.
- **GDD 4 Escena de planta:** listar al 6 como dependencia (lector de `reducir_movimiento`; nodo persistente, su regla 1); cerrar su remisión «OQ 9 del GDD 6» (ahora clave `reducir_movimiento`).
- **GDD 9 Marco de puzles:** leer `reducir_movimiento` (feedback de error: fundido fijo de 100 ms, cambio estático en vez de temblor); mantener `asistencia_*` como blandas.
- **GDD 25, 27, 30:** ofrecer `reducir_movimiento` como conmutador; las pistas no se colocan en ajustes.
- **Slice v0.3 (§5, §14, §16):** añadir «reducir movimiento» a las opciones de accesibilidad.
- **Art bible §7.4:** referenciar la clave `reducir_movimiento`.
- **`systems-index.md`:** fila 6 con dependientes 2, 4, 9 (no 5); actualizar la línea del estado de la re-review (~240).
- **`design/registry/entities.yaml`:** registrar `volume_steps` = 20 (`N_pasos`, 10–40), `volume_db_min` = −40 (−60 a −30), `volume_curve_db` (F2: `db_min × (1 − v)`, silencio si n = 0), `settings_save_debounce_s` = 0,5 (0,2–2,0), `settings_save_max_wait_s` = 5,0 (2,0–30,0; ≥ 2×), `fov_step` = 5 con rango 60–90 y defecto 70, `asistencia_rotacion` = ±6° (provisional) y la tolerancia normal de 3° del marco, y los defaults de las once claves de la regla 1 (consumen 2, 4, 9, 23, 25, 30).
