# Accessibility Requirements

> **Status**: Committed (nivel Estándar, sin modos de daltonismo; confirmado por el usuario el 2026-11-11, OQ 8 de 30)
> **Author**: ux-designer (`/ux-design accessibility`, modo autónomo; consolida decisiones ya tomadas, no añade requisitos)
> **Last Updated**: 2026-11-10
> **Accessibility Tier Target**: Estándar (escala del proyecto de 30 regla 1; equivale al «Standard» de la plantilla con **una exención documentada**: sin modo de daltonismo, ver Known Intentional Limitations L-1)
> **Platform(s)**: PC (Windows y Linux; slice §21). Mando compatible. Sin consolas ni móvil en el slice.
> **External Standards Targeted**:
> - WCAG 2.1 Nivel AA **parcial**, solo como referencia de criterios en las pantallas de UI (no certificación). Excepción: 1.4.4 solo hasta 150 % (30 OQ 2)
> - AbleGamers CVAA Guidelines: No (el slice no tiene chat de voz ni mensajería, así que CVAA no aplica)
> - Xbox Accessibility Guidelines (XAG): No (sin plataforma Xbox)
> - PlayStation Accessibility (Sony Guidelines): No (sin plataforma PlayStation)
> - Apple / Google Accessibility Guidelines: N/A (sin móvil)
> **Accessibility Consultant**: None engaged
> **Linked Documents**: `design/gdd/opciones-de-accesibilidad.md` (30, fuente principal), `design/gdd/ajustes-persistentes.md` (6), `design/gdd/subtitulos.md` (26), `design/gdd/prompt-de-interaccion.md` (24), `design/gdd/menu-de-pausa.md` (25), `design/gdd/entrada-y-controles.md` (1), `design/gdd/pantalla-de-titulo.md` (27), `design/slice/slice-v0.3.md` (§14, §16, §21), `design/art/art-bible.md` (§7.5, §7.6), `docs/architecture/adr-0006-…`, `adr-0007-…`, `adr-0016-…`, `design/ux/interaction-patterns.md`
> **Template**: Accessibility Requirements

> **Cómo leer este documento.** Es una **consolidación**: cada fila cita el GDD o ADR que ya decidió el requisito. Si este documento y un GDD difieren, **manda el GDD** (30 es la fuente de verdad de accesibilidad; el slice v0.3 manda sobre todos) y este documento se corrige. Lo no decidido por el usuario se marca **«decisión pendiente del usuario»** (DPU) y se resume en Open Questions. Lo que ninguna fuente verifica se marca **NO VERIFICADO**.
>
> **Etiquetas de estado de las tablas**: `Diseñado` = decidido en un GDD aprobado o revisado, sin implementar (el proyecto está en preproducción); `Parcial` = decidido con huecos; `DPU` = abierto, decide el usuario; `Fuera` = excluido del slice.

---

## Accessibility Tier Definition

### Tier Definitions

La plantilla define cuatro niveles (Basic, Standard, Comprehensive, Exemplary). 30 regla 1 define tres con nombres españoles (Básico, Estándar, Completo). Correspondencia usada aquí:

| Nivel del proyecto (30) | Plantilla | Qué incluye en este proyecto |
|---|---|---|
| **Básico** | Basic | Lo que exigen slice §14/§16: subtítulos, remapeo, tres volúmenes, `reducir_sobresaltos`, `reducir_movimiento` |
| **Estándar** (elegido) | Standard | Básico + WCAG 2.1 AA parcial en UI + información de juego en al menos dos canales + todo puzle resoluble sin color como único canal, sin reaccionar en ventanas de tiempo y con asistencia para la precisión + `escala_texto_ui` + ayudas de manejo + tope de destellos |
| **Completo** | Comprehensive | Estándar + filtros de daltonismo, alto contraste, audio mono, lector de pantalla, 200 % de texto |

### This Project's Commitment

**Target Tier**: **Estándar** (30 regla 1, D30-1). Fuera del slice: Completo (Comprehensive) y Exemplary.

**Rationale** (consolida 30 D30-1, D30-2, D30-3 y art bible §7.6):
1. El género es una aventura de puzles en primera persona a ritmo de paseo, sin combate, sin temporizadores de solución, sin sprint y con un solo botón contextual. Eso elimina de raíz las barreras motrices y de reflejos más duras; las que quedan son de **lectura** (mucho texto diegético y subtítulos), de **precisión** (arrastre en el puzle 3, giro en el puzle 5), **sensoriales** (parpadeo del pasillo y apagón) y **cognitivas** (puzles con información incompleta).
2. Básico dejaría sin cubrir texto escalable, ayudas de precisión y fotosensibilidad, que el diseño ya soporta casi sin coste adicional (30 D30-1). Completo exige filtros de daltonismo, alto contraste y lector de pantalla: la auditoría de 30 regla 12 muestra que ningún puzle depende del color y la paleta es sobria, así que los filtros costarían shaders sin beneficio; el lector y el 200 % son acabado de producto, no de vertical slice (D30-2).
3. El equipo es pequeño (indie, sin ingeniero de accesibilidad ni consultor), el objetivo es enseñar y conseguir financiación (slice §1) y no hay plataforma que obligue a XAG o a las guías de Sony. Estándar es lo máximo que el alcance permite sin un presupuesto dedicado.
4. Bajar a Básico costaría concretamente: texto no escalable en un juego lleno de documentos, ninguna ayuda de precisión en el puzle 3 ni en el 5, y ninguna garantía documentada de fotosensibilidad. Subir a Completo no está justificado por la evidencia de diseño.

**Features explicitly in scope (beyond tier baseline)**:
- `asistencia_encaje` (radio 0,10 m frente a 0,04 m) y `asistencia_rotacion` (±6° frente a ±3°): elevadas porque P3 y P5 son los únicos puzles con precisión (30 reglas 13 y 14).
- `multiplicador_pie` (1,0 a 3,0) y `pie_persistente`: lectura asistida para texto de objeto (6, 7).
- `campo_vision` (60° a 90°) y `balanceo_camara` (`completo`/`reducido`/`ninguno`): confort vestibular en primera persona (2 regla 16 y 17).
- Personalización de subtítulos (tamaño ×3, fondo ×3, nombre de hablante), por encima del mínimo de Standard (que no pide personalización completa): el slice es muy dependiente de voz (26).
- Tope de destellos de 3 por segundo **siempre activo**, no opción (30 D30-9).

**Features explicitly out of scope** (todas deben figurar en Known Intentional Limitations):
- Filtros de daltonismo y modo de alto contraste (D30-1; OQ 7).
- Lector de pantalla y 200 % de texto (D30-2; OQ 2). Se deja preparado (regla 23 de 30, ADR-0007 D8).
- Audio mono y señales direccionales (D30-3).
- Opción para suprimir la espera entre pistas (D30-8; OQ 1).
- Reposicionamiento de HUD (no hay HUD, slice §16).

---

## Visual Accessibility

> Suelo de texto, contraste y fundido son **definiciones únicas** de 30 (reglas 24 a 27); 24, 25, 26, 27, 28 y 29 las citan. Los px son **lógicos a 1080p** (ADR-0007 D7: `canvas_items` + `expand`, base 1920×1080).

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Tamaño mínimo de texto de UI | Standard | Menús (25, 27), pies y etiquetas (24), ordenador (19), prompts, créditos | Diseñado; **DPU (QQ-10)** | `tam_min_px` = **24 px lógicos** (30 regla 26). A 720p equivale a 16 px reales. Se valida en datos (CI), no con `max()` en ejecución (ADR-0007 D7.3, ADR-0016 D3). **Decisión pendiente del usuario (QQ-10):** ¿el suelo es lógico (16 px reales a 720p, lo implementado en la propuesta) o real (24 px reales a 720p, alternativa 3 del ADR-0007, que solo cambia `UiTextScale.logical_size`)? Hasta que decida rige el suelo lógico. La plantilla pide 24 px a 1080p: se cumple a 1080p |
| Tamaño de texto de subtítulos | Standard | Subtítulos (26) | Diseñado | `pequeno`/`medio`/`grande` = 24/32/44 px lógicos, defecto `medio` (32 = el mínimo que pide la plantilla). A 720p `pequeno` queda en 16 px reales: ligado a QQ-10 |
| Tamaño de texto de HUD | Standard | No aplica: no hay HUD (slice §16) | N/A | El único elemento superpuesto en juego es el anillo (icono, no texto), la etiqueta de acción y el pie, ambos ≥ 24 px lógicos (24 reglas 10 y 24; pie 28 px) |
| Escala de texto UI (`escala_texto_ui`) | Standard | Menús, pies, etiqueta, ordenador, vista de enfoque, ficha del puzle 4, créditos. **No** subtítulos, **no** iconos, **no** texto diegético fuera de la vista de enfoque | Diseñado; **DPU (QQ-08, OQ 10 de 30)** | Enum `1_00`/`1_25`/`1_50`, defecto `1_00`; se aplica en el fotograma del aviso (30 reglas 8 a 11; ADR-0007 D7.4 `UiTextScale`). Reflow, nunca recorte (`AUTOWRAP_WORD_SMART`, scroll vertical). **Decisión pendiente del usuario:** si el slice da la clave por cerrada (por defecto, sí: 18 claves). Si no, se elimina de los datos y «restablecer todos» pasa a 17 (ADR-0007 D1) |
| Contraste de texto de UI | Standard | Todo texto de UI | Diseñado | Texto ≥ **4,5:1** (WCAG 1.4.3). Es el **criterio de aceptación** (30 regla 25). El 7:1 de 25 R13 y 26 R18 es un objetivo de diseño del art bible por encima del mínimo |
| Contraste de bordes de control y foco | Standard | Todos los controles interactivos y el foco | Diseñado | ≥ **3:1** (WCAG 1.4.11). El foco se dibuja desde el cursor de `MenuList` (borde ≥ 3:1 + forma), no con el estilo de hover del motor (ADR-0016 D9) |
| Contraste de subtítulos | Standard | Subtítulos | Diseñado | Criterio de aceptación 4,5:1 (30 R25). Objetivo de diseño 7:1 contra fondos de referencia fijos (blanco y negro puros) con `opaco` y `translucido` (≥ 70 % de opacidad, a confirmar por art-director); con `ninguno`, 4,5:1 del texto contra su contorno de 2 px (26 R18). **Difiere de la plantilla** (que pide 7:1 como mínimo): se mantiene el criterio del proyecto |
| Modos de daltonismo (protanopia, deuteranopia, tritanopia) | Comprehensive | Fuera del slice | **Fuera** | D30-1. Compensado por diseño: ningún puzle ni UI depende solo del color (fila siguiente). Ver L-1 |
| Auditoría «color como único canal» | Basic | UI y los seis puzles | Diseñado; verificación AC-30-05 pendiente | Ver tabla de auditoría abajo. Todo GDD nuevo declara «sin color» en su AC (AC-30-05) |
| Escalado de UI (75 a 150 %) | Standard | Solo texto (`escala_texto_ui`) | Parcial | El proyecto escala **texto** 100/125/150 %, no la UI entera, y no baja de 100 %. El factor de ventana lo aplica el motor (`canvas_items`), nunca un script (ADR-0007 D7.1 y 6; `content_scale_factor` no se escribe en ejecución). Resolución soportada: 1280×720 a 3840×2160; por debajo de 720p no se soporta (30 F1) |
| Alto contraste | Comprehensive | Menús | **Fuera** | D30-1, OQ 7. **Discrepancia registrada:** art bible §7.6 lista «Alto contraste» como opción visual; 30 D30-1 la excluye del slice. Manda 30; el art bible debe anotarlo (ver Open Questions) |
| Brillo / gamma | Basic | Global | **NO VERIFICADO / sin fuente** | Ningún GDD consultado define un control de brillo ni de calibración. No se asume. Registrado como hueco (Open Questions); decide el usuario si entra |
| Aviso y tope de fotosensibilidad | Basic | Todo VFX y luces | Diseñado | (1) Tope duro de **3 destellos/s** siempre activo, con o sin opciones (30 regla 18, D30-9). Definición única de «destello» (30 regla 24): par de cambios de luminancia relativa ≥ 10 % del rango, con el estado oscuro < 0,80, sobre un área > 25 % del campo de visión, ventana deslizante de 1 s. (2) Parpadeo de luces de 28 ≤ 2 ciclos/s con pausas ≥ 0,35 s (constantes de código, limitador no desactivable). (3) Pantalla de advertencias de 27 («Antes de empezar»): **su contenido de §17 son avisos de contenido sensible (estrés, aislamiento, llanto…); NO incluye un aviso de fotosensibilidad específico.** Ver Open Questions (hueco) |
| Reducir sobresaltos (`reducir_sobresaltos`) | Basic | Audio (23) y luces (28) | Diseñado; **DPU (parpadeo y apagón)** | Atenúa sustos sonoros y el parpadeo del pasillo y el apagón (6; 28 regla 9 y 18: una sola atenuación, rampas de 0,30 s). **Decisión pendiente del usuario (OQ 10 de 30):** el slice §14 solo promete «reducir sobresaltos» en términos generales y fija `reducir_movimiento` para «feedback de error y cortina de carga»; extender `reducir_movimiento` a parpadeo del pasillo, reflejo retardado y lluvia (30 regla 19, 28 R9 y R17) va más allá. Hasta que decida, se mantiene lo escrito en 30/28: 28 lee **ambas** claves (D30-12) |
| Reducir movimiento (`reducir_movimiento`) | Standard | Fundidos, temblor del feedback de error, cortina de carga, 3 destellos de `LUCES_PARPADEO`, reflejo retardado, lluvia | Diseñado; alcance **DPU** (OQ 10) | Fundido fijo de **100 ms** en todos los sistemas, rango único 50–150 ms (30 reglas 19 y 27, 6 `reduce_motion_fade_s`); `LUCES_PARPADEO` → una atenuación suave de 0,6 s. Lectores: 9 (vía 13, 15, 11), 4, 19, 21, 24, 25, 26, 27, 28 (24 ya figura en 6; **10 pendiente**, OQ 16 de 6). P6 no la lee (D16-3, OQ 6). La cortina en curso termina como empezó |
| Anillo de interacción grande (`icono_grande`) | Standard | Anillo de 24 | Diseñado | 28 → 48 px, trazo 3 px, opacidad 100 %, contorno 2 px (24 regla 4). Es icono: no lo escala `escala_texto_ui` |
| Etiqueta de acción visible (`etiqueta_accion_visible`) | Standard | Etiqueta bajo el anillo | Diseñado | Defecto apagado (art bible §7.3); un glifo **nunca** va solo, siempre con texto (24 regla 12) |
| Subtítulos activados | Basic | Toda voz (`VO_V_`, `VO_G_`, `MEGA_`) | Diseñado | **Defecto ACTIVADOS** (26 regla 21, 6). **Difiere de la plantilla** (defecto OFF): el slice es una aventura narrativa con voz de la que depende el argumento; con subtítulos activados por defecto no hay pérdida de inmersión significativa y el valor seguro ante fichero dañado es «activados» |
| Subtítulos: identificación de hablante | Standard | Toda voz | Diseñado | Nombre escrito `VERA:`/`GUARDIÁN:`/`MEGAFONÍA:` (`subtitulos_hablante` defecto Sí) + estilo (cursiva, comillas angulares) + matiz opcional que **nunca** es único canal (26 reglas 16 y 17) |
| Subtítulos: personalización | Comprehensive (elevada) | Subtítulos | Diseñado | Tamaño ×3, fondo ×3 (`ninguno`/`translucido`/`opaco`), hablante. Sin posición ni color elegibles (por encima del mínimo de Standard, por debajo de Exemplary). Vista previa fija `UI_SUB_MUESTRA` (26 regla 26) |
| Subtítulos de sonidos no verbales | Comprehensive | Sonidos `SUB_*` | Parcial; **DPU (OQ 2 de 26)** | Obligatorio: `SUB_BREATH_BROKEN`. Propuesta pendiente del usuario: `SUB_CHAIRS_ROLL`, `SUB_TYPING_FAR`, `SUB_PHONE_BUZZ` (no se implementan hasta que decida). Formato `[Llanto contenido]`, neutro, sin causa ni emoción (26 reglas 2 y 3) |
| Foco visible sin color | Basic | Todos los menús | Diseñado | Corchete o subrayado + brillo; en la llamada, corchete + subrayado + posición (art bible §4.4, §7.6; 25 regla 9) |
| Modo de enfoque a pantalla completa para leer | Basic (garantía de diseño) | Texto necesario | Diseñado | Siempre activo; no es opción (30 regla 3; art bible §7.5) |

### Color-as-Only-Indicator Audit

> Resultado de 30 regla 12 (verificado contra GDDs 11–16 y 24, 25, 26, 29). La verificación humana de los seis puzles con simulación de CVD es **AC-30-05 (BLOCKING), aún no ejecutada**.

| Location | Color Signal | What It Communicates | Non-Color Backup | Status |
|----------|-------------|---------------------|-----------------|--------|
| P1 Cronología (11) | Ninguno (sin verde de acierto, 11 R35) | Referencias y huecos | Texto y posición | Resuelto en diseño |
| P2 Reflejo del memorando (12) | Luminancia del fragmento; sin rojo/verde moral | Fragmento correcto | Luminancia/forma (12 punto 20, D12) | Resuelto en diseño |
| P3 Encaje de la foto (13) | Color de la pieza **complementario** | Qué pieza va en qué hueco | Silueta y contorno de borde que solo encaja en su hueco | **Pendiente:** 13 debe declarar explícitamente «el contorno determina el hueco sin el color» (cambio requerido en 13) y AC-30-05 sobre P3 |
| P4 Tablero de tareas (14) | Ninguno | Regla y selectores | Texto «Alta/Media/Baja», «Vera/Guardián/Dirección» (P4-R4/R12) | Resuelto en diseño |
| P5 Espejo de la diferencia (15) | Ninguno | Cercanía al ángulo | Contorno por forma y luminancia (D15-11) | Resuelto en diseño |
| P6 Decisión (16) | Sin rojo/verde moral (D16-3) | Tres botones de igual peso | Texto | Resuelto en diseño |
| Anillo de interacción (24) | Ninguno | Presencia / progreso / rechazo | Anillo = presencia, relleno = progreso, pulso = rechazo, texto = contenido (24 regla 32) | Resuelto en diseño |
| Foco de menú (25, 27) | Ninguno | Elemento enfocado | Corchete o subrayado + brillo + borde ≥ 3:1 | Resuelto en diseño |
| Hablante de subtítulo (26) | Matiz opcional | Quién habla | Nombre escrito + estilo | Resuelto en diseño |
| Avisos del título y de la pausa (25, 27) | Ninguno | Guardado en riesgo, mando desconectado, partida dañada | Icono + palabra clave | Resuelto en diseño |
| Señales de 29 | Ninguno | Señales visuales de shaders | Forma (D29-7) | Resuelto en diseño (GDD 29 no leído en esta sesión; se cita 30 D29-7) |

---

## Motor Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Reasignación completa | Standard | Acciones físicas: `mover`, `mirar`, `interactuar`, `pausa`, `atrás`, `seleccionar`; teclado/ratón y mando por separado | Diseñado | Hasta 2 asignaciones por acción y dispositivo; conflictos con Intercambiar/Cancelar; mínimos garantizados (`interactuar`, `atrás`, `pausa` siempre ≥ 1; `atrás` siempre ≥ 1 no imprimible); restablecer por acción y por dispositivo (1 reglas 15 a 17; 25 reglas 19 a 26). **No se reasignan**: gestos derivados (`leer`, `agarrar`, `rotar`, `mantener`, `repasar_bolsillo`), `mover_cursor`, movimiento del ratón, `ui_*` (fijos: flechas/Enter/Esc, cruceta/A/B) |
| Cambio de método de entrada | Standard | PC | Diseñado | Teclado/ratón y mando siempre activos a la vez; el último usado fija los iconos, con histéresis (1 reglas 2 y 3, F7). Los glifos se re-resuelven sin reiniciar relojes (24 regla 14) |
| Alternar en lugar de mantener | Standard | `leer`, `mantener`, `agarrar`, `rotar` y pulsaciones del pie | Diseñado; **segunda pulsación de `leer`/`mantener` es propuesta a validar en playtest** (1 regla 14) | Ajuste de `controles` (1 regla 18). BLOCKING que exista antes de dar el slice por accesible (30 regla 15, AC-30-09) |
| Entrada de un solo botón | Basic | Mundo | Diseñado | `interactuar` es el único botón del mundo; no hay doble pulsación ni dos botones a la vez (1 regla 4) |
| Alternativas a entradas rápidas | Standard | Cualquier pulsación repetida | Diseñado (N/A por diseño) | Ninguna acción exige > 3 pulsaciones/s. Los puzles usan `seleccionar` (pulsar y soltar). Mantener `ui_izquierda/derecha` en un deslizador repite pasos a 0,12 s por paso, pero también se puede pulsar paso a paso (25 regla 12) |
| Ajustes de tiempo de entrada | Standard | Entradas con tiempo | Diseñado; excepciones aceptadas | **Ninguna solución exige reaccionar en una ventana** (30 regla 13). Esperas pasivas declaradas: bloqueo de rechazo de P1 1,5 s y de P3 0,4 s, gestos de P2 0,4–0,8 s, presentación de P6 1,9 s, **dwell de P5 `hold_s` 0,8 s†** (tiempo + precisión, **DPU OQ 9**), espera entre pistas 20/40 s (**DPU OQ 1**). Sin multiplicador de tiempo global (no hay QTE) |
| Asistencia de precisión | Standard | P3 y P5; cursor virtual | Diseñado | `asistencia_encaje` 0,10 m (frente a 0,04 m) y `asistencia_rotacion` ±6° (frente a ±3°) (13, 15, 30 regla 14). Objetivos de pulsación ≥ **44 px** (`pick_min_px`; P1, P2, P4, P6). Cursor virtual con atracción asistida activable (1 F5b). Sin arrastre en P1, P2, P4 y P6 |
| Ajustes de manejo | Standard | Mirada, sticks, cursor | Diseñado | Sensibilidad (ratón y stick por separado), inversión vertical por dispositivo, zonas muertas, velocidad del cursor virtual, atracción asistida (1 regla 18; pestaña «Manejo» de 25) |
| Un solo dispositivo suficiente | Basic | Slice completo | Diseñado; verificación AC-30-08 pendiente | Jugable solo con teclado y ratón o solo con mando (art bible §7.6, 1 reglas 3 y 9). Campo de texto del ordenador con mando: teclado en pantalla (19 R16). **Riesgo abierto (OQ 5 de 30):** cursor **oculto** en la llamada con mando (22 OQ 10); si no se resuelve, AC-30-08 se limita a las escenas sin llamada con mando |
| Modo de una mano | [Estándar: no garantizado] | WASD + ratón; stick + stick | **Fuera / no garantizado** | Ninguna fuente lo promete. La reasignación y «alternar» reducen mantener botones, pero mover y mirar a la vez requieren dos manos en ambos dispositivos. Registrado en L-6 |
| Asistencias de plataformas / travesía | — | — | N/A | No hay salto, correr ni agacharse (slice §5, A.0) |
| Reposicionamiento de HUD | Comprehensive | — | N/A | No hay HUD (slice §16) |
| Pausa y pérdida de foco / mando | Basic | Toda la partida | Diseñado | Ver Cognitive (pausa en cualquier momento). Pérdida de foco de ventana y desconexión del mando abren la pausa (1 reglas 21 y 22; 25 reglas 1 y 17) |
| Sin gesto del jugador cerrando el menú que llegue al mundo | Basic | Pausa | Diseñado | La pulsación que cierra el menú no llega al mundo hasta soltar y volver a pulsar (25 regla 6; ADR-0006 D3 change hook) |

---

## Cognitive Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Opciones de dificultad | Standard | — | N/A por diseño | No hay dificultad ni modo fácil: las ayudas mueven la barrera de manejo (tolerancia, mantener, tamaño, brusquedad), **nunca el misterio** (30 Player Fantasy; AC-30-15: sin etiquetas de dificultad, logros ni cambio de historia por usar ajustes). El parámetro de diseño fijo y su justificación son el pilar *Información incompleta* |
| Pistas por niveles | Standard | Seis puzles | Diseñado | Tres niveles por puzle (dos en P6); panel en la pausa (17 → 25). Sin contador de pistas usadas (25 regla 8 y 14) |
| Espera entre pistas 20/40 s | Standard | Sistema 17 | **DPU (OQ 1 de 30)** | Sin opción en el slice (D30-8: choca con *Tensión sin castigo* y *Autonomía*). Si el usuario lo decide: bool `pistas_sin_espera` en 6 y fila en el grupo 3 de la pestaña |
| Pausar en cualquier momento | Basic | Toda la partida | Diseñado; **una restricción documentada** | La pausa abre sobre cualquier contexto **salvo durante una carga de escena** (entre «carga iniciada» y «terminada/fallida»); en ese caso se abre al terminar la carga (1 regla 7, 21; 25 regla 1). Escenas dirigidas (`sin control`) aceptan `pausa`. El pausar detiene el tiempo de juego (25 regla 2) |
| Persistencia de ayuda | Standard | Ayuda de bolsillo y pies | Parcial | **Los pies de texto no se pueden releer** (24 regla 29, 7 regla 12) y **nunca llevan información necesaria para avanzar**: lo clave va en documentos (`LEER`). Mitigación: `pie_persistente` y `multiplicador_pie`. Los papeles y correos se releen siempre (`repasar_bolsillo`, ordenador). La ayuda de bolsillo (`UI_BOLSILLO_AYUDA`) se muestra una sola vez por sesión (20 R23), sin caducidad por tiempo (24 regla 26). Registrado en L-5 |
| Claridad de objetivo | Standard | — | **NO VERIFICADO** | Ninguna fuente consultada define un objetivo activo en pantalla ni un diario. El slice no tiene objetivos HUD; la información vive en papeles/correos releíbles. No se asume más |
| Equivalentes visuales de sonido | Standard | Sonidos con función de juego | Parcial; **AC-30-11 pendiente** | Ningún acierto depende solo del sonido (23 regla 40). Se exige a 23 la tabla «sonido → equivalente» (`SFX_BOX_*`, `SFX_PHONE_BUZZ`…) y a 26 decidir cuáles se rotulan |
| Tiempo de lectura | Standard | Texto auto-descartable | Diseñado | El pie dura según F5 de 7, multiplicable ×1,0–3,0 o persistente (valor base de F5 **no consultado en esta sesión**; el criterio de la plantilla, ≥ 5 s para información accionable, **no aplica** porque el pie nunca lleva información necesaria). Subtítulos: duración mínima `t_lectura_s`, páginas de ≤ 8 s, sincronizados con la voz (26 reglas 7 y 8). No hay timeout en menús ni diálogos |
| Sin temporizadores ni game over | Basic | Todo | Diseñado | Sin barra de salud, sin game over (slice §16), sin cuenta atrás en advertencias de 27, sin cuenta atrás de la llamada («No responder» es un botón, art bible §7.6). Única cuenta atrás: la captura de reasignación se cancela sola a 8 s para no atrapar a quien solo usa mando, con el temporizador **visible en texto** (25 regla 22) |
| Sin foco sorpresa | Standard | Menús | Diseñado | Sin wrap en listas; foco inicial en «Reanudar», nunca en una fila destructiva; el diálogo destructivo abre en «Cancelar» (25 reglas 9, 10, 28, 30). Atrás en el título no hace nada (27 regla 15) |
| Documentación de carga cognitiva por sistema | Comprehensive | — | **Fuera** | Fuera de Estándar |
| Navegación asistida | Standard | Mundo | N/A por diseño | Una planta de oficinas pequeña; sin viaje rápido ni waypoints (pilar Información incompleta). No hay fuente que los prometa |

---

## Auditory Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Subtítulos de todo diálogo hablado | Basic | `VO_V_*`, `VO_G_*`, `MEGA_*`, también sin audio y con volumen a 0 | Diseñado; AC pendientes | Cobertura 100 %, incluida la llamada; se dibujan en todos los contextos y sobre el velo de la pausa; silenciar un bus no acorta nada (26 reglas 1, 10, 22; 30 regla 17). Verificación: AC-30-10 |
| Sonidos no verbales con subtítulo | Comprehensive | `SUB_*` | Parcial; **DPU (OQ 2 de 26)** | Ver Visual |
| Volúmenes independientes | Basic | Voces / Efectos / Música | Diseñado | **Tres** deslizadores (`vol_voces`, `vol_efectos`, `vol_musica`), 20 pasos de 5 %, valor en texto, «Silencio» en 0; muestra de audio al soltar (6, 25 regla 16, slice §14). Sin bus de UI separado (**difiere** de la plantilla, que pide cuatro: el slice solo especifica tres). Persisten (6); accesibles desde la pausa y el título. Todo a 0 con subtítulos apagados está permitido, sin aviso (D30-11; DPU OQ 4 de 30, por defecto no avisar) |
| Equivalentes visuales de feedback | Standard | Todo feedback sonoro de puzles | Diseñado | Los puzles muestran feedback visual y sonoro en cada acción (slice §16); el rechazo se ve en el anillo (pulso) y no depende del sonido (24 regla 20) |
| Audio mono | Comprehensive | — | **Fuera** | D30-3: ningún sonido es direccional ni necesario para jugar |
| Indicadores direccionales de audio | Comprehensive | — | **Fuera / N/A** | D30-3 |
| Compatibilidad con audífonos (> 4 kHz) | Standard | Señales de alta frecuencia | **NO VERIFICADO** | Ninguna fuente audita el contenido en frecuencia de los sonidos con función de juego. Se resuelve mejor con la tabla de AC-30-11 (equivalente visual de cada sonido con función) que con una auditoría espectral |

### Gameplay-Critical SFX Audit

> No se enumeran sonidos nuevos: **la tabla «sonido → equivalente visual o texto» la debe producir 23 (AC-30-11, pendiente)**. Lista de partida (slice §14 y 26/30):

| Sound Effect | What It Communicates | Visual Backup | Caption Required | Status |
|-------------|---------------------|--------------|-----------------|--------|
| `SFX_CLICK_SUBTLE` | Rechazo / sin efecto | Pulso del anillo (24 regla 18) + pie `OBJ_<id>` cuando existe | No (26 regla 2) | Cubierto en 24 |
| `SFX_BOX_*` (apertura de compartimento) | Caja abierta | Animación del compartimento y vista cercana | **A decidir por 26/23** (AC-30-11) | Pendiente |
| `SFX_PHONE_BUZZ` | Teléfono vibra | Entrada en `llamada` | **Propuesta `SUB_PHONE_BUZZ` pendiente (DPU OQ 2 de 26)** | Pendiente |
| `SFX_BREATH_BROKEN` | Respiración cortada en la llamada | — | **Sí, obligatorio** `SUB_BREATH_BROKEN` | Diseñado |
| Sonidos de puzle (clics, zumbido, madera, metal; slice §14) | Feedback de acción | Feedback visual del propio puzle (slice §16) | No (26 regla 2: feedback de puzle no se subtitula) | Cubierto por diseño; verificar en AC-30-11 |

---

## Platform Accessibility API Integration

| Platform | API / Standard | Features Planned | Status | Notes |
|----------|---------------|-----------------|--------|-------|
| PC (Windows y Linux) | Entrada nativa de Godot; reasignación propia (`InputRouter`, ADR-0006) | Reasignación completa, mando con glifos por familia, `get_binding_label` | Diseñado | La detección de familia de mando (A/✕) **no está verificada en el motor** (1, OQ 19 y ADR-0006) |
| PC (lector de pantalla: Narrator / NVDA / JAWS / Orca) | AccessKit en `Control` (Godot 4.5+) | **Preparado, sin soporte prometido**: nombre accesible = texto visible, orden de foco = orden visual, `A11y.set_live` en bloques de subtítulos y líneas de aviso (ADR-0007 D8, ADR-0016 D11) | **NO VERIFICADO** (AC-30-16 pendiente) | `docs/engine-reference/godot/` confirma solo la **capacidad** (AccessKit en `Control`, 4.5) y `Control.accessibility_live` (4.7). El nombre exacto de la propiedad de nombre accesible, el orden de foco y el estado deshabilitado **no están verificados**: spike SP-4 de ADR-0007. El slice se entrega sin soporte de lector (D30-2); el hueco no bloquea |
| Steam (PC) | Steam Input / SDL | — | **NO VERIFICADO / sin fuente** | Ningún documento consultado decide el uso de Steam Input ni sus features de accesibilidad. No se asume. La reasignación en juego es suficiente para teclado/ratón |
| Xbox, PlayStation 5, Switch, iOS, Android | XAG / Sony / Apple / Google | — | N/A | Fuera de alcance del slice (slice §21: PC) |

---

## Per-Feature Accessibility Matrix

> Matriz por sistema con evidencia en los GDDs consultados. **No sustituye a una pasada completa contra `design/gdd/systems-index.md`** (no leído en esta sesión): al añadir o revisar un sistema debe añadirse su fila (ver Open Questions).

| System | Visual Concerns | Motor Concerns | Cognitive Concerns | Auditory Concerns | Addressed | Notes |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| 1 Entrada y controles | Cursor no circular, visible | Reasignación, alternar, un botón, zonas muertas | Sin gesto compuesto | — | Sí | Cursor oculto en la llamada con mando (DPU OQ 5) |
| 2 Jugador | `campo_vision`, `balanceo_camara` | — | — | — | Sí | Vestibular |
| 4 Escena de planta | Cortina de carga | — | — | — | Sí | Lee `reducir_movimiento` |
| 6 Ajustes persistentes | Valores seguros si falla el fichero | — | Sin diálogo bloqueante si el fichero está dañado | — | Sí | 18 claves de «restablecer todos» |
| 7 Interacción e inspección | Pie, anillo, vista cercana | `t_hold` y alternar | Sin pies con información necesaria | — | Sí | Sin inventario ni menú de objetos |
| P1, P2, P4, P6 (11, 12, 14, 16) | Sin color como único canal | Objetivos ≥ 44 px, sin arrastre | Pistas por niveles | Sin dependencia de sonido | Sí; AC-30-05/06 pendientes | P6 no lee `reducir_movimiento` (OQ 6) |
| P3 (13) | Contorno determina el hueco | Arrastre + `asistencia_encaje` | Pista 3 por inactividad (60 s) es ayuda | — | Parcial | 13 debe declarar «sin color» |
| P5 (15) | Contorno por forma | Giro ±3° / ±6° + dwell 0,8 s | — | — | Parcial | Dwell sin ajuste (DPU OQ 9) |
| 17 Pistas | — | — | Espera 20/40 s | — | Parcial | DPU OQ 1 |
| 19 Ordenador | Texto escalable | Teclado en pantalla con mando (R16) | — | — | Sí | PA-3 cerrado con suelo 24 px |
| 20 Papeles y bolsillo | Documentos en vista de enfoque | `repasar_bolsillo` en `atrás` | Releer siempre | — | Sí | — |
| 22 Llamada | Foco con corchete + subrayado + posición; luminancia limitada en el apagón | Cursor oculto hasta `OPCIONES` | Sin temporizador | Subtítulos de `VO_G_12*`… y `SUB_BREATH_BROKEN` | Parcial | Riesgo AC-30-08 (OQ 5) |
| 23 Director de audio | — | — | — | Tres volúmenes; tabla sonido → equivalente | Parcial | AC-30-11 pendiente |
| 24 Prompt | `icono_grande`, `etiqueta_accion_visible`, pulso ≤ 2,9/s | — | Anillo + texto | Pulso redunda el sonido | Sí | — |
| 25 Menú de pausa | Foco ≥ 3:1, reflow | Todo con un solo dispositivo; captura con salida a 8 s | Sin wrap, foco seguro | — | Sí | — |
| 26 Subtítulos | Tamaño, fondo, contraste | — | Sin historial (fuera del slice) | 100 % de voz | Sí | Sonidos no verbales DPU |
| 27 Título | Foco, avisos con icono + texto | Todo con un solo dispositivo | Advertencias sin cuenta atrás | — | Sí | Sin aviso de fotosensibilidad específico |
| 28 Atmósfera reactiva | Tope de destellos, parpadeo ≤ 2 Hz, pausas ≥ 0,35 s | — | — | — | Sí si cumple 30 regla 20 | Re-verificar tras la revisión paralela |
| 29 Shaders / 21 Director | Tope de destellos, fundido 100 ms | — | — | — | Verificación pendiente (AC-30-13) | — |

---

## Accessibility Test Plan

> Los AC de 30 son la autoridad. Aquí se fijan las herramientas. Ninguna herramienta externa se ha ejecutado ni está confirmada como disponible en el entorno del proyecto.

| Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|---------|------------|------------|--------------|-------------|--------|
| Contraste de texto y bordes (AC-30-04, BLOCKING) | Cálculo de la razón de contraste WCAG sobre los pares texto/fondo y borde/fondo de la paleta del art bible, listados en la captura de cada pantalla | Cada pantalla de 25, 27, 24, 19, vista de enfoque y subtítulos, en estado normal y enfocado | Texto ≥ 4,5:1; bordes de control y foco ≥ 3:1; todo texto ≥ 24 px lógicos. Subtítulos: 4,5:1 mínimo (objetivo 7:1) | ux-designer | Not Started. **Herramienta concreta de medición: NO VERIFICADA** (no designada en las fuentes) |
| Escala de texto 1,50 a 720p (AC-30-03) | Capturas retenidas en `production/qa/evidence/` | 25, 27, 24, 19, puzle 4 | Ningún texto recortado ni solapado; reflow y scroll | ux-designer | Not Started |
| Orden y grupos de la pestaña Accesibilidad (AC-30-02, BLOCKING) | Una captura por grupo, en 25 y en 27 | 4 grupos en el orden de 30 regla 6 | Valor en texto + ayuda de una línea por fila | ux-designer | Not Started |
| Colorblind / sin color como único canal (AC-30-05, BLOCKING) | Simulación de protanopia/deuteranopia/tritanopia sobre capturas: simulador de CVD del editor (**NO VERIFICADO en la referencia del motor**) o Coblis (URL de la plantilla; disponibilidad no verificada) | Los 6 puzles, **P3 jugado solo con contorno** | Se resuelve sin ambigüedad | ux-designer / qa-tester | Not Started |
| Sin ventana de tiempo (AC-30-06, lógica) | Revisión automática de datos de los 6 puzles | Buscar temporizador de solución | Solo esperas pasivas declaradas en 30 regla 13 | qa-tester | Not Started |
| Asistencias (AC-30-07) | Test de integración | Pieza a 0,09 m encaja y a 0,11 m no; 46,1° no resuelve y 43,5° sí | Valores de 13 y 15 | qa-tester | Not Started |
| Un solo dispositivo (AC-30-08) | Playtest completo hasta `ESC8_CIERRE` con solo teclado/ratón y otro con solo mando | Incluye campo del ordenador con teclado en pantalla y la llamada con mando | Se llega al final en ambos; si la llamada con mando falla, se limita el AC (OQ 5) | qa-tester | Not Started |
| Alternar en lugar de mantener (AC-30-09) | Playtest | `leer`, `mantener`, `agarrar`, `rotar` en los 6 puzles y en el pie de objetos | Ningún gesto exige mantener un botón | qa-tester | Not Started |
| Volumen 0 y subtítulos (AC-30-10) | Integración | Todos los `vol_*` a 0, subtítulos activos | Misma información; sin silencios sin texto | qa-tester | Not Started |
| Tabla sonido → equivalente (AC-30-11) | Revisión | Lista de 23 | Ningún sonido con función sin equivalente visual o texto | ux-designer + audio-director | Not Started |
| Reducir movimiento (AC-30-12) | Integración | Fundidos 100 ms en todos los sistemas incl. 27; `LUCES_PARPADEO` → una atenuación | Sin tres destellos | ux-designer | Not Started |
| **Fotosensibilidad (AC-30-13)** | Vídeo a 60 fps de toda secuencia de 28, 29, 24 y 21, con las opciones activas y apagadas; análisis con herramienta de destellos. **PEAT (Harding) es la herramienta mencionada por 30; su disponibilidad en el entorno NO ESTÁ VERIFICADA**: si no se puede usar, debe sustituirse por otra herramienta equivalente basada en el criterio de la regla 24 o por un cálculo propio sobre los fotogramas, y registrarlo en Audit History | Pasillo, apagón, escena de cierre, pulso del anillo | Nunca > 3 destellos en 1 s; luces ≤ 2 ciclos/s con pausas ≥ 0,35 s | accessibility-specialist / ux-designer | Not Started |
| 28 lee ambas claves (AC-30-14) | Integración | `reducir_sobresaltos` y `reducir_movimiento` en el fotograma del aviso | Atenuación sin parpadeo adicional | ux-designer | Not Started |
| Sin etiquetas de dificultad (AC-30-15) | Revisión | Todos los ajustes | Ninguna etiqueta, logro o cambio de historia | ux-designer | Not Started |
| Lector de pantalla (AC-30-16) | Manual con Narrator / Accessibility Insights tras el spike SP-4 | Todos los controles de 25 y 27 | Texto = nombre accesible; orden de foco visual | ux-designer | **Pendiente de verificar el API de Godot 4.7; no bloquea el slice** |
| Pruebas con jugadores (daltonismo, motricidad) | Playtest con participantes | Sesión completa con asistencias y alternar | Completan el contenido sin pedir aclaraciones | producer | Not Started; sin presupuesto asignado en las fuentes |

---

## Known Intentional Limitations

| Feature | Tier Required | Why Not Included | Risk / Impact | Mitigation |
|---------|--------------|-----------------|--------------|------------|
| **L-1** Modo de daltonismo y alto contraste | Standard (plantilla) / Comprehensive | D30-1: ningún puzle depende del color y la paleta es sobria | Un jugador con protanopia no tiene modo; si la auditoría AC-30-05 detectase un puzle ambiguo, el riesgo es real | Diseño sin color como único canal; AC-30-05 BLOCKING (P3 solo con contorno); OQ 7 reabre tras el slice |
| **L-2** Lector de pantalla y 200 % de texto | Comprehensive | D30-2: acabado de producto, no de slice | Jugadores ciegos o con baja visión severa no pueden jugar el menú solos | Controles con nombre accesible y orden de foco; vista de enfoque a pantalla completa; OQ 2 |
| **L-3** Audio mono y señales direccionales | Comprehensive | D30-3: ningún sonido es direccional ni necesario | Bajo | Subtítulos, equivalentes visuales |
| **L-4** Opción para suprimir la espera de pistas | Standard (cognitiva) | D30-8: choca con *Tensión sin castigo* y *Autonomía* | Un jugador con carga cognitiva puede quedarse atascado esperando | Pistas por niveles; pausa en cualquier momento. **DPU OQ 1** |
| **L-5** Pies de texto no releíbles | Standard | 24 regla 29: fuera del slice | Quien no lee a tiempo pierde un texto de ambiente | Los pies no llevan información necesaria; `pie_persistente` y `multiplicador_pie` |
| **L-6** Modo de una mano | Comprehensive | Sin fuente que lo prometa; mover y mirar requieren dos manos | Jugadores con una sola mano pueden no completar el slice | Reasignación completa, alternar en vez de mantener. Sin garantía |
| **L-7** Dwell de 0,8 s de P5 sin ajuste | Standard (tiempo) | Toca el diseño de P5 (30 regla 13) | Quien no puede sostener el ángulo 0,8 s depende de `asistencia_rotacion` y alternar | **DPU OQ 9**, por defecto aceptar la excepción |
| **L-8** Brillo / gamma, aviso específico de fotosensibilidad, subtítulos por posición/color | Basic / Standard | Ninguna fuente los define | Posible exigencia de revisores o financiadores | Registrado como hueco en Open Questions |
| **L-9** Sin escala por debajo de 100 % ni UI al 75 % | Standard | El proyecto escala texto, no UI | Bajo | — |
| **L-10** Subtítulos activados por defecto, no desactivados | — (desviación de la plantilla) | 26 regla 21: valor seguro y narrativa dependiente de la voz | Ninguno para accesibilidad | — |

---

## Audit History

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| 2026-11-10 | ux-designer (consolidación) | Revisión documental, no auditoría | GDDs 30, 6, 26, 24, 25, 1, 27; slice §14, §16, §21; ADR-0006, 0007, 0016 (reglas de Decisión); art bible §7.5 y §7.6 | Sin prueba en juego (preproducción, nada implementado). Discrepancias detectadas: (1) art bible §7.6 lista «Alto contraste» y 30 D30-1 lo excluye; (2) la pantalla de advertencias de 27 no cubre fotosensibilidad; (3) la plantilla pide subtítulos desactivados por defecto, el proyecto los activa; (4) 7:1 de subtítulos es objetivo, no criterio | Open |

---

## External Resources

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.1 | https://www.w3.org/TR/WCAG21/ | Referencia de criterios 1.4.1, 1.4.3, 1.4.4, 1.4.11, 2.1.1, 2.2.1, 2.3.1, 2.5.5 (30 regla 1) |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com | Lista de verificación de juegos |
| Coblis (simulador de CVD) | https://www.color-blindness.com/coblis-color-blindness-simulator/ | AC-30-05. URL tomada de la plantilla; disponibilidad no verificada |
| PEAT (Harding FPA) | — (sin URL en las fuentes) | AC-30-13. **Disponibilidad no verificada**; 30 la cita como ejemplo |
| `docs/engine-reference/godot/` | local | AccessKit (4.5), `Control.accessibility_live` (4.7): solo como capacidad |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| **DPU. Suelo de texto a 720p (QQ-10):** ¿suelo lógico de 24 px (16 px reales a 720p) o real (24 px reales a 720p)? Cambia `pequeno`/`medio` de subtítulos a 720p y el texto de la UI a 720p | Usuario | Antes de implementar `UiTextScale` y el tema | Por defecto rige el suelo lógico (ADR-0007 OI-1; reversible con un cambio en `UiTextScale.logical_size`) |
| **DPU. `escala_texto_ui` (QQ-08, OQ 10 de 30, OQ 15 de 6):** ¿se da por cerrada en el slice? | Usuario | Antes de cerrar el catálogo de 6 | Por defecto sí (18 claves). Si no, 17 |
| **DPU. Parpadeo y apagón (OQ 10 de 30):** ¿se extiende `reducir_movimiento` a parpadeo del pasillo, reflejo retardado y lluvia (28 R9 y R17), más allá de slice §14? ¿Y `reducir_sobresaltos` sigue leída por 28 junto a `reducir_movimiento`? | Usuario | Antes del re-review de 28 | Por defecto se mantiene lo escrito: 28 lee ambas claves |
| **DPU. Nivel Estándar (OQ 8 de 30):** ¿se acepta como compromiso ante financiadores? | Usuario | Antes de la puerta de preproducción | **Resuelta 2026-11-11: sí, Estándar sin daltonismo** |
| **DPU. Dwell de P5 (OQ 9 de 30)** | Usuario, 15 | Tras playtest | Por defecto aceptar la excepción |
| **DPU. Espera de pistas (OQ 1 de 30)** | Usuario | Tras playtest | Por defecto no |
| **DPU. Sonidos con subtítulo (OQ 2 de 26)** | Usuario | Antes de implementar 26 | Solo `SUB_BREATH_BROKEN` |
| **Riesgo. Cursor oculto en la llamada con mando (OQ 5 de 30, OQ 10 de 22)** | 22, usuario | Antes de cerrar la capa | Si no se resuelve, AC-30-08 se limita |
| **Hueco.** Aviso de fotosensibilidad al inicio: 27 no lo incluye (solo avisos de contenido, slice §17). ¿Se añade? | Usuario, 27 | Antes de la demo a financiadores | Sin decidir; el tope de 3 destellos/s ya es garantía |
| **Hueco.** Control de brillo/gamma | Usuario, art-director | Tras el slice | Sin decidir |
| **Hueco.** Art bible §7.6 menciona «Alto contraste»; D30-1 lo excluye | art-director | Próxima revisión del art bible | Manda 30 |
| **Verificar.** API de AccessKit en Godot 4.7 (SP-4); herramienta de contraste; PEAT; simulador de CVD | ux-designer, ui-programmer | Antes de ejecutar AC-30-04, -05, -13, -16 | Sin resolver |
| **Pendiente.** Ampliar la matriz por sistema contra `systems-index.md` y cerrar los lectores de `reducir_movimiento` (10 pendiente en 6) | ux-designer | Antes de la puerta de producción | Abierta |
| **Pendiente.** Plataforma: el bloque `platform` de `project.yaml` no existe; se usó `technical-preferences.md` (PC Windows/Linux, mando completo) y slice §21 | producer | Pre-producción | Abierta |
