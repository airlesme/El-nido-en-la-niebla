# Epic: Director de escenas 1–3 (versión mínima)

> **Layer**: Feature (sistema F5 alojado como autoload)
> **GDD**: design/gdd/director-de-escenas.md (§ Overview l. 15, § Acceptance Criteria l. 230)
> **Architecture Module**: Capa 3 — 21 Director (`SceneDirector`, autoload n.º 9)
> **Status**: **BLOQUEADO por ADR-0017 (Proposed)** — 26/27 TR lo citan; 1 libre (TR-director-002)
> **Desbloqueo**: aceptación de ADR-0017 sin spike (C3, enmienda en ADR-0008; H20, H23, H24 de la cola); TR-director-009/026 además ADR-0008; 003/004 además ADR-0005
> **Stories**: Not yet created — run `/create-stories director-escenas-1-3` tras aceptar ADR-0017
> **Control manifest**: v2026-11-11 — § Feature Layer Rules (vacía) + reglas transversales de Foundation
> **Engine Risk**: HIGH (`process_mode` NS; sin otra API específica — riesgo de VERSION.md para 4.7)

## Overview

Líneas de tiempo con reloj `t_rel`, órdenes solo por el bus («línea pedida», «estado de objeto
pedido»…). **Alcance M1, escenas 1–3:** C.1 (fundido, ventilador, `VO_V_01`, `MEGA_01`, vibración de
V02, «¿Jugamos esta noche?» → «Ahora no» → «Este número ya no está disponible»), C.2 y C.3 (`VO_V_04`,
lluvia que se intensifica). Escenas 4–8, apagón y llamada fuera. Recorte 8 (escena 1 como secuencia
fija, C.1 a 14 s) es el último recurso.

**Dependencia abierta (índice A3):** el audio provisional plano de C.1/C.3 no tiene épico propio
(GDD 23, ADR-0008 Proposed). Requiere decisión antes de las historias de C.1.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0017: Scene director timeline and call data (**Proposed**) | Línea de tiempo, datos de escena | MEDIUM |
| ADR-0003, ADR-0009 (Accepted) | Autoload persistente; traspaso de `sin control` | HIGH |
| ADR-0001 (Accepted) | Órdenes y hechos por el bus | MEDIUM |
| ADR-0005, ADR-0008 (Proposed) | `scenes/scenes.json`; audio | — |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-5**: tiempos de C.1 y C.3 dentro de ±1 fotograma del dato (test de timeline con reloj falso).
- **C-M1-1**: las escenas 1–3 se encadenan sin consola de depuración.
- **C-M1-8**: el recorrido escena 1→3 se cronometra (informativo).

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` director; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-director-001 | El director es un sistema persistente (no pertenece a `planta` ni `recepcion`): se suscribe al bus al arrancar y no se da de baja; sobrevive a los cambios de escena. | ADR-0003, ADR-0009 ✅ (+ ADR-0017 Proposed) |
| TR-director-002 | Estado «inactivo» desde la petición de descarga total hasta «descarga total completada» (≤ 3,0 s†): ni escucha (salvo esa señal) ni emite, reloj parado; conserva el estado volátil y lo b... | ADR-0003 ✅ |
| TR-director-003 | Escenas definidas por datos en `assets/data/scenes/scenes.json` (`id`, `tipo` momento\\ | ❌ No ADR (ADR-0005, ADR-0017 Proposed) |
| TR-director-004 | Validación al arrancar: ID repetido, orden desconocida o `t_rel` decreciente descartan esa escena (error visible en desarrollo; en build, descarte + una línea de log); el resto funciona. | ❌ No ADR (ADR-0005, ADR-0017 Proposed) |
| TR-director-005 | Reloj de línea de tiempo `t_rel(n)=t_rel(n−1)+Δ_juego`, con tiempo de juego escalado; vale 0 con pausa, sin foco o sin mando; las órdenes vencidas en un mismo fotograma salen todas, en orden d... | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-006 | Las líneas de tiempo de `ESC1_LLEGADA` y `ESC8_ASCENSOR` se miden desde «escena lista» (no desde el fin del aclarado); precisión de ±1 fotograma. | ADR-0001 ✅ (+ ADR-0017 Proposed) |
| TR-director-007 | El director lee hechos (`formulario_leido`, `caja_completa`, `llamada_iniciada`, `llamada_completada`, `respuesta_llamada`) y nunca escribe ninguno; reacciona al aviso de cambio, no al valor al car... | ADR-0001 ✅ (+ ADR-0017 Proposed) |
| TR-director-008 | Órdenes emitidas por el bus sin esperar al ejecutor (salvo cierre de modos y líneas del cierre): «línea pedida», «efecto de escena pedido», «estado de objeto pedido», «tarjeta final pedid... | ADR-0001 ✅ (+ ADR-0017 Proposed) |
| TR-director-009 | Dos canales de voz independientes (`VO_V_*` y `MEGA_*`, deducidos del prefijo del ID); dentro de un canal la nueva línea se aplaza hasta «línea terminada» con tope `t_cola_canal_s` (8,0†, due... | ❌ No ADR (ADR-0008, ADR-0017 Proposed) |
| TR-director-010 | Traspaso de `sin control` en el mismo fotograma de «carga de escena terminada» con `control_final` = `ninguno`; si `t_rel` ≥ `t_fin`, pide `exploración` en ese fotograma; nunca hay fotograma s... | ADR-0003 ✅ (+ ADR-0017 Proposed) |
| TR-director-011 | Duración declarada `duracion_declarada = t_fin + h_decl_s` (1,0†); tope de Entrada = + `margen_E` (2,0†) medido desde traspaso/apertura; toda escena dirigida debe declararla. | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-012 | Traspaso o petición de `exploración` rechazados (`sin control` ya no es suyo): el director no recupera control, degrada la escena a momento y registra; nunca reintenta. | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-013 | Al terminar escena pide `exploración` (nunca «cerrar»); solo el cierre de la escena 8 abre un `sin control` propio, con 25,8 s declarados. | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-014 | Cancelación sin órdenes ni hechos ante «carga de escena fallida», «carga de escena iniciada» no pedida y «`sin control` absorbido» (dueño 21); estado volátil borrado y arma de nuevo escen... | ADR-0001 ✅ (+ ADR-0017 Proposed) |
| TR-director-015 | Estado volátil de sesión (no hechos, no guardado): `esc4_mega_hecha`, `esc4_reflejo_hecho`, `apagon_activo`, `mensaje_telefono_pendiente`, `cierre_iniciado`; se borra en descarga total, «estado ... | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-016 | Reanudación (`motivo` = `reanudar`): con `caja_completa` ∧ ¬`llamada_completada` aplica apagón reducido (`LUCES_APAGON` duración 0) y, al volver `exploración` con ¬`llamada_iniciada`, ejecu... | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-017 | Cada zona del pasillo (`T-PAS-1`, `T-PAS-2`) dispara su momento una vez por carga de `planta`, solo con ¬`caja_completa`; `T-D-OUT` dispara el apagón una vez (`apagon_activo`). | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-018 | `ESC7_APAGON` y `ESC7_TIMBRE` no toman `sin control` ni piden `cerrar_modos()`; el temporizador de 60,0† s hasta `TELEFONO_SUENA` corre en tiempo de juego y solo si ¬`llamada_iniciada`. | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-019 | 21 es el único emisor de «estado de objeto pedido»; `V02` en `vibrando` solo por `ESC7_TIMBRE` o a los 60,0 s†; devuelve a `reposo` con el primer «interacción ejecutada» `resultado` = `HECH... | ADR-0001 ✅ (+ ADR-0017 Proposed) |
| TR-director-020 | «ascensor llamado» (de 8) → petición a 4 de `recepcion` con `control_final` = `ninguno`; si 4 la rechaza emite «ascensor rechazado» (sin datos) sin reintento; arma `ESC8_ASCENSOR` (`t_fin` =... | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-021 | `cerrar_modos()` + espera «modos cerrados» con tope `t_modos_max_s` = 2,0† (si no llega abre igualmente y registra); único uso: antes de `ESC8_CIERRE`. | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-022 | Cadena de cierre `ESC8_CIERRE`: línea de 12A–12D según `respuesta_llamada`, +3,0 s, `VO_V_12E`, +2,0 s, fundido 0,8†, tarjeta 3,0 s, descarga total; esperas = min(evento, `t_linea_max_s` 8,0�... | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-023 | `ESC8_CIERRE` se arma en «carga de escena terminada» de `recepcion` y se dispara con el primer «lectura completada» de `R01`; `cierre_iniciado` ignora los siguientes; espera `g_post_lectura_s` ... | ADR-0001 ✅ (+ ADR-0017 Proposed) |
| TR-director-024 | Con `reducir_movimiento` (leído en cada disparo, no al arrancar) sustituye `LUCES_PARPADEO` por una atenuación de 0,6 s† y pide aparición gradual en `REFLEJO_RETARDADO`; fundido propio de 0,1 s. | ❌ No ADR (ADR-0017 Proposed) |
| TR-director-025 | Traspaso viable si `M_traspaso = (D_carga + margen_E) − t_terminada ≥ 0` (nominal ≈ 12,0 s); si es < 0 se rechaza y aplica la degradación a momento. | ADR-0003 ✅ (+ ADR-0017 Proposed) |
| TR-director-026 | Líneas `fallida`/`sin audio` no se reintentan; la línea de tiempo continúa con subtítulo; el director no genera texto propio (solo IDs del catálogo de 18). | ❌ No ADR (ADR-0008, ADR-0017 Proposed) |
| TR-director-027 | Pruebas con reloj de test y dobles de 4 y Entrada reales (AC-21-23b/c): avance manual de fotogramas, `D_carga` reducido; tests en `tests/unit/director_de_escenas/` y `tests/integration/director_de_... | ❌ No ADR (ADR-0017 Proposed) |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
