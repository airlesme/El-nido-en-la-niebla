# Epic: Interacción y prompt

> **Layer**: Feature (7) + Presentation (24)
> **GDD**: design/gdd/interaccion-e-inspeccion.md (§ Overview l. 15, § Acceptance Criteria l. 518); design/gdd/prompt-de-interaccion.md (§ Overview l. 14, § Acceptance Criteria l. 161)
> **Architecture Module**: Capa 3 — 7 Interacción (`InteractionSystem` en `planta`); Capa 4 — 24 Prompt (`InteractionPrompt` en `HUD`); `architecture.md` § API Boundaries «Interacción (7) — ADR-0011»
> **Status**: **LISTO con 1 bloqueo de diseño** — Interacción (7) **LISTO** (22/22 TR libres); Prompt (24) **LISTO** salvo la parte de escala/suelo de texto de TR-prompt-015 y TR-prompt-018 (historia 025 Blocked: el GDD 24 contradice ADR-0007 D7 / ADR-0016; QQ-10 sin confirmar)
> **Actualizado 2026-11-12**: ADR-0016 **Accepted** (2026-11-11) y ADR-0007 Accepted → el prompt deja de estar bloqueado por ADR; historias 014–025 escritas
> **Stories**: 25 stories (001–013 Interacción · 014–025 Prompt) — ver `stories.md`; 24 Ready, 1 Blocked (025)
> **Control manifest**: v2026-11-11b — anterior a la aceptación de ADR-0016 (§ Presentation lo da por `Proposed`; aplica ADR-0016 G-1…G-11 hasta regenerarlo). § Feature sin ADR-0011 corregida en 2026-11-11b
> **Engine Risk**: HIGH (consulta de forma esférica / `ShapeCast3D` con Jolt; escala de UI del prompt)

## Overview

Foco sobre interactuables (consulta de forma de ADR-0011, con el fallback de raycast simple de
PLAN § 2.2 si hiciera falta, R-M1-5), retención de foco, pila de modos, vistas (`abrir_vista`,
`ViewReceiver`, `PointerEvent`), lectura por pulsación larga y aviso «interacción ejecutada»; el
prompt muestra el pie y el pulso de aceptación. **Fuera de M1:** rotación en inspección (recorte 6,
solo lectura). Entra el viewport lógico bajo `canvas_items`/`expand` (NEEDS_WINDOWED) diferido por
ADR-0011. Decisión de usuario n.º 4 de `gdd-cross-review-2026-11-10-r2.md` (filtro de
«interacción ejecutada», opción por defecto aplicada) y pendientes H8, H9 de la cola: aplicar antes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0011: Interaction focus query and view picking (Accepted) | Consulta de foco y picking de vistas; S-0011-A/B/C pasados | HIGH |
| ADR-0001 (Accepted) | Avisos por el bus (co-cubre TR-prompt-005/006) | MEDIUM |
| ADR-0016 (**Accepted**, 2026-11-11) | Texto de UI, capas, área segura y prompt (D1–D6) | HIGH |
| ADR-0007 (**Accepted**) · ADR-0005 (Accepted) | Escalado de UI (TR-prompt-018); datos (TR-prompt-020) | — |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-6**: foco, lectura e interacción con mando y teclado.
- **C-M1-7**: captura retenida del prompt de interacción (ADR-0016 aceptado; historia 024).
- **C-M1-3**: cancelar o salir de una vista nunca deja el modo bloqueado.

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` interact prompt; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-interact-001 | Catálogo de interactuables en datos `assets/data/interaction/interactables.json` validado contra `interactables.schema.json` en carga y CI; campo desconocido = error de datos; prohibidos campos de... | ADR-0011 ✅ |
| TR-interact-002 | Barrido de foco en cada paso de física (60 Hz) solo en contexto `exploración`, con `rayo_vision()` del Jugador (ojos sin balanceo, estado de física sin interpolar) (regla 5, F1) | ADR-0011 ✅ |
| TR-interact-003 | F1 exige recoger TODOS los contactos de una esfera `radio_apuntado_m` 0,06 m (consulta de forma o `ShapeCast3D` con Jolt); no cubierto por engine-reference; el respaldo de 7 rayos `intersect_ray` n... | ADR-0011 ✅ |
| TR-interact-004 | Máscaras de colisión separadas `mascara_interactuable` y `mascara_geometria`; cuerpo del Jugador en capa propia excluida; oclusión con tolerancia `desempate_prof_m` 0,03 m | ADR-0011 ✅ |
| TR-interact-005 | Retención de foco medida en pasos de física: `t_gracia_foco_s` 0,12 s = 7 pasos a 60 Hz, `radio_pegajoso_m` 0,15 m; un candidato nuevo válido sustituye siempre | ADR-0011 ✅ |
| TR-interact-006 | `can_interact(verbo)` pura y barata: se llama por paso de física solo para candidatos que pasan `habilitado_si` y para el objetivo retenido; `habilitado_si` por lectura directa de hechos del 3, si... | ADR-0011 ✅ |
| TR-interact-007 | Contrato de manejador por ID (`registrar_manejador`): `can_interact`->{SI,NO,SIN_EFECTO}, `etiqueta(verbo)->clave\\ | ADR-0011 ✅ |
| TR-interact-008 | Orden al pulsar: 7 reserva el gesto del Jugador (`gesto_hecho` o `HAND_REACH`) ANTES de `interact()`; si el Jugador rechaza, no se llama a `interact()` | ADR-0011 ✅ |
| TR-interact-009 | Bloqueo de contexto por transición de Entrada hasta `gesto_terminado(id, motivo)`; tope único 3 s de tiempo de juego (la pausa lo detiene); `bloquear_contexto(razon)->token\\ | ADR-0011 ✅ |
| TR-interact-010 | Pulsación: corta se decide al soltar si hay `verbo_largo`; `t_hold` 0,5 s de Entrada; anillo a `t_anillo_inicio_s` 0,12 s; `t_enfriamiento_s` 0,25 s; F2 `p=clamp((t-t_pulsado)/t_hold,0,1)` con tie... | ADR-0011 ✅ |
| TR-interact-011 | Respuesta audible/visible a toda pulsación procesada ≤ `latencia_feedback_ms` 100 ms (50–200) | ADR-0011 ✅ |
| TR-interact-012 | Pila de modos (`exploración`, `inspección`, `lectura`, `vista cercana`, `ordenador`); `atrás` cierra solo el superior; `cerrar_modos()` cierra todos y emite una vez «modos cerrados»; la descar... | ADR-0011 ✅ |
| TR-interact-013 | Vista cercana: cámara cedida al Jugador vía `ceder_camara(propietario "interaccion:vista", pose, fov_destino, duración)`/`devolver_camara` con señales `camara_cedida`/`camara_devuelta`; red de ... | ADR-0011 ✅ |
| TR-interact-014 | Cadena de apertura D01a–D01c con un solo bloqueo transferido por token (`abrir_vista(id, desde_token)`); `BOX_Cn_OPEN` ≤ `BOX_OPEN_MAX` 1,6 s + `t_vista_entrada_s` ≤ 1,2 s => T_cadena ≤ 2,8... | ADR-0011 ✅ |
| TR-interact-015 | Picking 2D aritmético contra formas de `ViewReceiver.elements()` (rect/círculo/polígono en metros locales, `z_orden`, `atraccion`), sin colliders 3D; conversión F6 `ppm=(H_px/2)/(d·tan(FOV_v/2... | ADR-0011 ✅ |
| TR-interact-016 | `PointerEvent = {gesto, fase, elemento, elemento_bajo, pos_px, pos_vista, delta_px, delta_grados}`; fases inicio/actualización/fin/cancelación; elemento fijado al pulsar y capturado; `seleccionar... | ADR-0011 ✅ |
| TR-interact-017 | `gestos_aceptados` por elemento ⊆ {seleccionar, agarrar, rotar, mantener}; relectura en el siguiente fotograma tras `elements_changed`; un gesto en curso no cambia de elegibilidad | ADR-0011 ✅ |
| TR-interact-018 | Elementos señalables ≥ `pick_min_px` 44 px de lado (hit-test ampliado) y separación ≥ R1+R2 con R=min(max(64 px, tol),128 px); `atraccion_desactivada` por vista/zona en `puzzles.json`; valida... | ADR-0011 ✅ |
| TR-interact-019 | Inspección: objeto `sostenible:true` (solo V05) con radio ≤ `r_max_inspeccion_m` 0,20 m; `d_ins=clamp(r/tan(θ_fill/2),0,25–0,60 m)`, giro libre por cuaternión; objeto a ≥0,15 m de cámara ... | ADR-0011 ✅ |
| TR-interact-020 | `abrir_lectura(doc_id)->{ACEPTADA,APLAZADA,RECHAZADA(motivo)}` según tabla de estado; una única petición aplazada con tope 3 s de tiempo de juego; `cerrar_vista(resuelto)` se aplaza si hay lectu... | ADR-0011 ✅ |
| TR-interact-021 | Sin estado propio ni persistencia: al cargar escena objetivo vacío y ningún modo abierto; el estado de objetos lo reconstruyen los dueños desde hechos | ADR-0011 ✅ |
| TR-interact-022 | El objetivo no viaja por el bus: 24 consulta `get_target()` cada fotograma; pie vía `mostrar_pie(clave, duracion_pie(clave), retener)`; F5 `t_pie=clamp(0,5+n/14,2,8)·multiplicador_pie`, `texto_ma... | ADR-0011 ✅ |
| TR-prompt-001 | Sondea `get_target()` de 7 en cada fotograma de render (sin aviso de cambio de objetivo) y no recalcula objetivo, verbo ni `p`; entrada `{id, etiqueta, largo, p, anillo_visible} \\ | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-002 | Anillo/etiqueta dibujados solo con contexto de Entrada `exploración` y objetivo ≠ nulo; ocultos en menú, lectura, inspección, vista cercana, ordenador, llamada, sin control; sin punto de mira ... | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-003 | Anillo fijo en el centro de pantalla; 28 px a 1080p (48 px con `icono_grande`), opacidad 80 %; fundidos 250 ms in / 150 ms out; cambio directo de objeto sin parpadeo (cruzado 120 ms) | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-004 | Relleno del anillo `360·p` grados horario desde las 12 h (p de 7); vaciado 100 ms al soltar; permanece en modo «alternar» | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-005 | Pulso de aceptación (80→100 % en 120 ms) y de rechazo (80→40 % en 120 ms) disparados solo por el aviso «interacción ejecutada (id, verbo, resultado)» de 7; inicio ≤ `latencia_feedback_ms`... | ADR-0001 ✅ (+ ADR-0016 Proposed) |
| TR-prompt-006 | Dominio de `resultado` ampliado a `HECHO`, `SIN_EFECTO`, `GESTO_RECHAZADO`, `TOQUE_CORTO` (aplicado en 7); un gesto = un aviso = un pulso | ADR-0001 ✅ (+ ADR-0016 Proposed) |
| TR-prompt-007 | Tope de fotosensibilidad: ignorar pulso nuevo si el anterior empezó hace < `pulso_min_intervalo_ms` 340 ms (≤ 2,9/s, nunca bajar de 334); sin cola de pulsos | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-008 | Etiqueta `[glifo] + texto` apagada por defecto (`etiqueta_accion_visible`=falso); glifo siempre acompañado de texto, en línea; clave 18 ausente → no dibujar etiqueta y log de dev, nunca mostrar... | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-009 | Glifo desde `get_binding_label(accion, dispositivo) -> {tipo, texto, glifo_id}` de 1 (asignación vigente, orden determinista); sin teclas hardcodeadas (ni «Retroceso»/«Backspace» en código/da... | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-010 | Re-resolver glifos solo al cambiar dispositivo («dispositivo de entrada cambiado») o al recibir «pausa cerrada»; una consulta por cambio, no por fotograma; sin reiniciar el reloj de pies | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-011 | API `mostrar_pie(clave, duracion_s \\ | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-012 | Un solo hueco de pie, sustitución con fundido cruzado 150 ms (100 con `reducir_movimiento`), sin cola; dos pies en el mismo fotograma: gana el último | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-013 | Duración la calcula el llamador (`duracion_pie(clave)` de 7, F5); `PERSISTENTE` dura hasta cambiar `get_target().id` respecto del del instante de dibujo o hasta otro pie; el reloj es de tiempo de ... | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-014 | Pie solo en `exploración`; fuera se oculta y congela; pies de objeto se descartan al salir por modo de 7/`sin control`; pie `retener=verdadero` queda pendiente sin caducidad hasta otro `retener` o... | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-015 | Pie: abajo-centro, márgenes seguros 5 %, ≤2 líneas a ≤60 % ancho, texto ≥ max(28·s, 24) px, panel 85 % opacidad, contraste ≥ 4,5:1 sobre blanco puro | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-016 | Convivencia con 26: mientras haya bloque de subtítulos visible el pie sube sobre su borde superior + `sub_hueco_px` 12 px, nunca lo tapa (recorta el pie a 2 líneas) | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-017 | Sustitución de token `{accion:atrás}` en `UI_BOLSILLO_AYUDA` por glifo+texto de la asignación vigente; fallback al nombre «Atrás» y warning si falla `get_binding_label` | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-018 | Escala UI F2 `s=clamp(altura_ventana/1080, 0,67, 2,0)` (720p–2160p), redondeo a entero; márgenes 5 % en 16:9, anclados al área 16:9 central en ultraancho | ❌ Bloqueado (ADR-0007, ADR-0016 Proposed) |
| TR-prompt-019 | Lee de 6 vía avisos de cambio y aplica al fotograma siguiente `reducir_movimiento` (fundidos fijos 100 ms), `icono_grande`, `etiqueta_accion_visible`; valores iniciales si 6 no está (dependencia ... | ❌ Bloqueado (ADR-0016 Proposed) |
| TR-prompt-020 | Sin audio propio (`SFX_CLICK_SUBTLE` lo emite 7); sin color para estados (sin rojo); sin estado persistente; espera «escena lista» antes de dibujar; datos en `assets/data/ui/prompt.json` | ADR-0005 ✅ (+ ADR-0016 Proposed) |

## Requisitos bloqueados (al 2026-11-12)

Ya no hay bloqueo por ADR: ADR-0016 y ADR-0007 están Accepted y los 20 TR del prompt tienen historia. Queda un bloqueo de **diseño** que afecta a dos TR en parte:

| TR-ID | Bloqueado por | Motivo / salida |
|-------|---------------|-----------------|
| TR-prompt-015 (cláusula «texto ≥ max(28·s, 24) px») | Decisión de diseño | GDD 24 (F2, R24, AC-24-14: 24 px **físicos**) frente a ADR-0007 D7.3 / ADR-0016 G-4 (24 px **lógicos**, sin factor de ventana); ADR-0016 C1/OI-5; QQ-10 sin confirmar. Historia 025. `TODO(ui-owner)` |
| TR-prompt-018 (F2 `s`, redondeo, rango 720p–2160p) | Decisión de diseño | idem. La parte de márgenes 5 % y ultraancho **no** está bloqueada (historia 015) |

Los demás 18 TR-prompt y la parte restante de 015 y 018 están en historias Ready (014–024).

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla). ADR-0008 (`Proposed`) es `depends_on` de ADR-0016 pero ninguna historia del prompt usa su superficie (ver `stories.md` § Decisiones tomadas)
