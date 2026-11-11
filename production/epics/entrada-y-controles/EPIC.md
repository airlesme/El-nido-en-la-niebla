# Epic: Entrada y controles

> **Layer**: Foundation
> **GDD**: design/gdd/entrada-y-controles.md (§ Overview l. 15, § Acceptance Criteria l. 460)
> **Architecture Module**: Capa 1 — 1 Entrada (`InputRouter`, autoload n.º 4); `architecture.md` § API Boundaries «Entrada (1) — ADR-0006»
> **Status**: **LISTO** — 19/19 TR libres; comprobaciones de mando físico (familia, hot-plug, zona muerta real, foco) NEEDS_MANUAL en el prototipo jugable
> **Actualizado 2026-11-11**: desbloqueado por ADR-0006 (S-0006 automatizado; C1 medido: el bus no debe contar con entrega en el mismo fotograma a un suscriptor de física)
> **Stories**: Not yet created — run `/create-stories entrada-y-controles` (tras regenerar el manifiesto, índice Q2)
> **Control manifest**: v2026-11-11 — § Foundation Layer Rules (sin reglas propias de Entrada: ADR-0006 excluido)
> **Engine Risk**: HIGH (`DEVICE_ID_MOUSE/KEYBOARD` en 4.7, SDL3, foco dual)

## Overview

Pila de contextos de entrada, dueño/duración/tope de `sin control`, dispositivo activo,
asignaciones por defecto (`input/default_bindings.json`) y etiquetas de glifos (`get_binding_label`).
En M1: teclado **y** mando completan el recorrido de las escenas 1–3. Reasignación y bloque
`controles` de ajustes van con el recorte 7. Toda historia jugable de M1 depende de este épico.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0006: Input abstraction, contexts and binding labels (Accepted) | Contextos, `sin control`, etiquetas de asignación | HIGH |
| ADR-0001, ADR-0002, ADR-0003 (Accepted) | Co-cubren TR-input-003…006 y 008 | MEDIUM |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-6**: mando y teclado completan el recorrido (sesión manual registrada).
- **C-M1-1**: recorrido sin consola de depuración en `playtest-windows` y `playtest-linux`.
- **C-M1-9**: 0 errores en consola.

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` input; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-input-001 | El resto del juego solo conoce acciones lógicas (nunca teclas/botones): acciones físicas (`mover`, `mirar`, `interactuar`, `pausa`, `atrás`, `mover_cursor`, `seleccionar`, `ui_arriba/abajo/izqui... | ADR-0006 ✅ |
| TR-input-002 | Teclado/ratón y mando activos a la vez; dispositivo activo = último usado, solo para iconos; inicial teclado/ratón; «dispositivo de entrada cambiado» una sola vez por cambio, con histéresis F... | ADR-0006 ✅ |
| TR-input-003 | Pila de contextos (`exploración`, `inspección`, `lectura`, `vista cercana`, `ordenador`, `llamada`, `menú`, `sin control`): solo la cima recibe acciones; salir restaura el contexto inferior con ... | ADR-0003, ADR-0006 ✅ |
| TR-input-004 | `sin control` con dueño y duración declarada; operaciones abrir / cerrar (solo dueño) / traspasar (sin salir ni emitir aviso, renueva tope) / pedir `exploración` (dueño) / reponer `menú` / de... | ADR-0003, ADR-0006 ✅ |
| TR-input-005 | Tope de seguridad de contextos bloqueantes: 3 s† en transiciones de cámara/animación (cubre `BOX_OPEN_MAX` 1,6 s + `t_vista_entrada_s` ≤1,2 s = 2,8 s) y duración declarada + margen 2 s† en... | ADR-0002, ADR-0006 ✅ |
| TR-input-006 | Estado interno `carga_en_curso` derivado de «carga de escena iniciada»/«terminada»/«fallida» (de 4) que bloquea la pausa; sin esos avisos nunca se bloquea; la pausa por pérdida de foco o man... | ADR-0001, ADR-0003, ADR-0006 ✅ |
| TR-input-007 | En transiciones bloqueantes solo se acepta `pausa`; el resto se descarta sin guardarse (excepción `repasar_bolsillo`, entregada a 20 sin cola); una tecla mantenida durante la transición no dispar... | ADR-0006 ✅ |
| TR-input-008 | Pausa: el menú consume el evento (`Esc` compartido `pausa`/`ui_atrás` produce un solo cierre), el tiempo de juego se detiene, el ratón se libera/recaptura; pérdida de foco de ventana y desconex... | ADR-0002, ADR-0006 ✅ |
| TR-input-009 | Mirada con ratón por píxeles relativos sin delta: Δθ = px·0,10°/px†·s_m·inv, tope ±45°/fotograma, idéntica a 30 y a 144 fps; mirada con stick: ω_max 120°/s†·r^1,5·s_s con delta l... | ADR-0006 ✅ |
| TR-input-010 | Zona muerta radial reescalada F1 (dz_in 0,15†, dz_out 0,05†, mínimo dz_in 0,05) evaluada en radial sobre ejes crudos (sin la zona muerta del motor) | ADR-0006 ✅ |
| TR-input-011 | Cursor virtual de mando en viewport lógico 1920x1080 (modo de estiramiento a confirmar en ADR): v_c = 900 px/s†·r²·s_c (máx. 2.400 px/s), limitado a la ventana; atracción F5b (R 64 px†, t... | ADR-0006 ✅ |
| TR-input-012 | Reconocedor de gestos de puntero por pulsación de `seleccionar`: decide la primera señal (`t_hold` 0,5 s en tiempo real vs `d_arrastre` 8 px†); `gestos_aceptados` ⊆ {`agarrar`,`rotar`,`manten... | ADR-0006 ✅ |
| TR-input-013 | `interactuar`: verbo corto al pulsar si el objeto no tiene `verbo_largo` (7 informa); con `verbo_largo` decide al soltar o a `t_hold` (`leer`) y exige indicador de progreso; la pulsación se cancel... | ADR-0006 ✅ |
| TR-input-014 | `repasar_bolsillo`: derivada de `atrás` solo si la pulsación empieza en `exploración`, en el flanco de pulsación, ignorando auto-repetición del teclado; entregada a 20 (`repasar_bolsillo()`) a... | ADR-0006 ✅ |
| TR-input-015 | Reasignación por dispositivo (hasta 2 asignaciones por acción), validador de conflictos por contexto con lista de pares permitidos (`pausa`/`ui_atrás` en `Esc`), mínimos garantizados (`interact... | ADR-0006 ✅ |
| TR-input-016 | Asignaciones y valores iniciales en `assets/data/input/default_bindings.json` (recargable sin tocar código); exportar/importar el bloque de asignaciones y ajustes de manejo para persistirlo en Aju... | ADR-0006 ✅ |
| TR-input-017 | Campo de texto enfocado en `ordenador` consume antes que cualquier acción las teclas imprimibles, Retroceso, Supr, flechas y Enter; `Esc` y clic derecho siguen siendo `pausa`/`atrás`; `Retroceso`... | ADR-0006 ✅ |
| TR-input-018 | `get_binding_label(accion, dispositivo) -> {tipo, texto, glifo_id} \\ | ADR-0006 ✅ |
| TR-input-019 | Ajuste «alternar en lugar de mantener» (`leer`, `mantener`, `agarrar`, `rotar`: una pulsación empieza, otra termina; cancelación con `atrás` o cambio de contexto) y `t_hold` hasta 1,5 s en mod... | ADR-0006 ✅ |

## Requisitos bloqueados (al 2026-11-11)

Ninguno: todos los TR citan solo ADR `Accepted`.

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
