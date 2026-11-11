# Epic: Carga de planta (despacho, pasillo, Archivo)

> **Layer**: Core
> **GDD**: design/gdd/escena-de-planta.md (§ Overview l. 15, § Acceptance Criteria l. 302)
> **Architecture Module**: Capa 2 — 4 Escena (`SceneLoader`, autoload n.º 8; `WorldSlot` en `Shell`); `architecture.md` § API Boundaries «Escena (4) — ADR-0003»
> **Status**: Ready — 21/23 TR libres; TR-scene-009 co-cita ADR-0008 y TR-scene-022 co-cita ADR-0005
> **Stories**: Not yet created — run `/create-stories carga-de-planta` (antes: índice A1)
> **Control manifest**: v2026-11-11 — § Core Layer Rules **vacía: no incluye ADR-0003** (índice A1) + reglas transversales de Foundation
> **Engine Risk**: HIGH (`Area3D` bajo Jolt; sensor de zona en (8,95; 8,977])

## Overview

Carga de `planta` en `WorldSlot` (nunca reutiliza la instancia), cortina, estados Sin escena /
Cargando / Lista / Error y traspaso de `sin control` en el fotograma de «carga terminada». En M1:
geometría gris de despacho (A.2), pasillo (A.3, el de S0b si existe) y Archivo (A.4), y sus
zonas. Entra aquí S-0003-C (tirón de carga síncrona), diferido por ADR-0003 hasta que exista la
`planta` gris.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0003: Scene loading and sin-control handoff (Accepted) | Carga en `WorldSlot`, cortina, traspaso de `sin control`; S-0003-A/B pasados | HIGH |
| ADR-0009: Service composition (Accepted) | `SceneLoader` autoload; inyección vía `configurar(ctx)` | LOW |
| ADR-0001 (Accepted) | Avisos de carga por el bus | MEDIUM |
| ADR-0005, ADR-0008 (Proposed) | Co-citados en TR-scene-022 y TR-scene-009 | — |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-1**: partida nueva carga `planta` y llega a escena 3 en ambos exports.
- **C-M1-3**: ningún fallo de carga deja la partida sin salida (estado Error con panel).
- **C-M1-7**: captura retenida del Archivo.
- **C-M1-10**: S-0003-C medido sobre la `planta` gris (informativo).

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` scene; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-scene-001 | Exactamente una escena de juego activa a la vez (`planta` o `recepcion`, nunca ambas); la planta es una escena continua sin cargas entre despachos, pasillo, A, B, D y hueco de ascensor. | ADR-0003 ✅ |
| TR-scene-002 | Los sistemas 1 Entrada, 3 Estado, 6 Ajustes, 21 Director de escenas y 23 Audio son nodos persistentes fuera de las escenas de juego: sobreviven a cambios de escena con el mismo `get_instance_id()`;... | ADR-0003, ADR-0009 ✅ |
| TR-scene-003 | Contenedores con nombre (`office`, `corridor`, `archive`, `meeting_room`, `guardian_office`, `reception`) y IDs del slice como nombre de nodo con prefijo fijo (V→office, A→archive, B→meeting_... | ADR-0003 ✅ |
| TR-scene-004 | Convención espacial fija: metros, X oeste→este, Z sur→norte, Y arriba, origen en el centro del umbral del Despacho de Vera; techo 2,70 m (Recepción 3,20 m); huecos de puerta 1,00×2,10 m; tol... | ADR-0003 ✅ |
| TR-scene-005 | Anclas obligatorias: `door_slot_a`, `door_slot_b`, `door_slot_d`, `door_slot_elevator` (X 1,4–2,6, 1,2 m), `drawer_slot_a05` (animable por 8), `spawn_office` (propuesto (−3,0; 0,0), yaw hacia V... | ADR-0003 ✅ |
| TR-scene-006 | Zonas disparadoras `T-…` como detectores puros (sin lógica ni lectura de hechos) que detectan el sensor esférico del Jugador (radio 0,02–0,05 m, Area3D bajo Jolt) y emiten «zona activada» c... | ADR-0003 ✅ |
| TR-scene-007 | Contrato geométrico con Jugador: paso mínimo 0,60 m (`player_min_passage_width_m`), cápsula fija 0,25 m (`player_capsule_radius_m`), las hojas de puerta desactivan colisión al empezar a abrir, ... | ADR-0003, ADR-0012 ✅ |
| TR-scene-008 | Petición de carga con 3 datos: `destino` (`planta`/`recepcion`), `motivo` (`partida_nueva`/`reanudar`/`recepcion`), `control_final` (`exploracion`/`ninguno`); precondición: estado (3) «Listo», ... | ADR-0003 ✅ |
| TR-scene-009 | Recarga completa: cada petición de `planta` descarta la instancia anterior y crea otra nueva (nunca se reutiliza); los nodos huérfanos y suscriptores del bus deben volver al valor de arranque tra... | ADR-0009 ✅ (+ ADR-0008 Proposed) |
| TR-scene-010 | Secuencia de arranque ordenada de 9 pasos: «iniciada» → cortina opaca → descarga → instanciación → colocar jugador → configurar elementos (síncrono, mismo fotograma, con retenciones) ... | ADR-0003 ✅ |
| TR-scene-011 | Orden de configuración en `planta`: 7 Interacción (catálogo, retención) → 9 valida datos de puzle y configura → resto (8, 10, 20…); validación fallida = fallo de carga inmediato sin espe... | ADR-0003, ADR-0009 ✅ |
| TR-scene-012 | Mecanismo de retención (n_ret) con identificador propio e idempotente (doble liberación no baja de 0); «escena lista» ⇔ n_ret = 0; retención tomada tras «escena lista» se ignora. | ADR-0003 ✅ |
| TR-scene-013 | Tope total de espera en negro `T_cap` = 10 s (3–30) en tiempo real sin escalar (Δ_real sin recortar), corre aunque la ventana pierda el foco; no se acumula por retención; el fallo se registra c... | ADR-0003 ✅ |
| TR-scene-014 | Cortina como capa negra opaca a pantalla completa por encima del mundo y la interfaz de juego (solo el mensaje de error está por encima), propiedad del sistema 4: `α_out = α_0+(1−α_0)·S(t/d)... | ADR-0003 ✅ |
| TR-scene-015 | Duraciones de fundido por `motivo` en `assets/data/scene/load_transitions.json` (0,8 s; partida_nueva d_in 2,0 s; `cierre` solo oscurece); con `reducir_movimiento` de 6 todas pasan a 0,1 s, leído ... | ADR-0003 ✅ |
| TR-scene-016 | `D_carga = d_out + T_cap + N_gap·Δ_ref + d_in` (≈11,67 s para recepcion) declarado a Entrada como duración de `sin control` en «iniciada»; N_gap = 2 fotogramas de gracia entre «escena lista... | ADR-0003 ✅ |
| TR-scene-017 | Modelo de pila de contextos de Entrada durante la carga: abrir `sin control`(4) en «iniciada», reiniciar a [`sin control`] al descargar conservando dueño y duración, operación «traspasar `sin... | ADR-0003 ✅ |
| TR-scene-018 | Máquina de 4 estados (Sin escena, Cargando, Lista, Error); Cargando rechaza nuevas peticiones y la pausa; en Error de build final la cortina queda en negro con mensaje y una sola acción «Volver ... | ADR-0003 ✅ |
| TR-scene-019 | Descarga total (volver al título): emite «descarga total solicitada», descarga, repone `menú` y emite «descarga total completada»; duración declarada ≤ 3,0 s (`t_descarga_total_max_s`, 1�... | ADR-0003 ✅ |
| TR-scene-020 | 4 es el único emisor de «partida terminada» (en el mismo fotograma, tras «carga de escena terminada» de `recepcion`; nunca en fallo); 4 no escribe hechos y solo lee `llamada_completada` (regla... | ADR-0001, ADR-0003 ✅ |
| TR-scene-021 | Escena obsoleta: «estado restablecido»/«estado restaurado» con escena cargada y sin recarga pedida = advertencia (error visible en dev), sin parchear elementos. | ADR-0001, ADR-0003 ✅ |
| TR-scene-022 | Validación de `load_transitions.json` al arrancar (`d` ≤5 s, `T_cap` 3–30, `N_gap` 0–10, `Δ_max` 0,05–0,1); inválido/ausente = no se entra en partida, manejador fatal con código `DATOS_... | ADR-0003 ✅ (+ ADR-0005 Proposed) |
| TR-scene-023 | Testabilidad con dobles inyectados (cargador de escenas falso, cortina doble, jugador espía, elemento espía con `configurar()`, estado falso, bus falso, reloj de ticks enteros); varios AC marcado... | ADR-0003 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
