# Epic: Ordenador (búsqueda) e impresora

> **Layer**: Feature
> **GDD**: design/gdd/ordenador-correo-impresora.md (§ Overview l. 17, § Acceptance Criteria l. 223)
> **Architecture Module**: Capa 3 — 19 Ordenador (`Computer` V01/V08 en `planta`; overlay en `SceneUi`)
> **Status**: **BLOQUEADO por ADR-0006 y ADR-0005 (Proposed)** — 20/22 TR citan al menos uno; TR-computer-013/014 citan ADR-0007; 2 TR libres
> **Desbloqueo**: aceptación de ADR-0006 (S-0006-A…F) y de ADR-0005 (S-0005-A); escalado de UI con ADR-0007 (SP-1…6, parcial en M1)
> **Stories**: Not yet created — run `/create-stories ordenador-e-impresora` tras los desbloqueos
> **Control manifest**: v2026-11-11 — § Feature Layer Rules (vacía) + reglas transversales de Foundation
> **Engine Risk**: HIGH (`LineEdit` y teclado en pantalla con foco dual, 4.6)

## Overview

Sesión del ordenador V01 con búsqueda «transición» (resultados a 0,4 s, orden visual 3, 1, 4, 2 con
dos distractores), lectura de correos (escribe `correos_leidos`, escritor único 19) e impresora V08
(`hoja_en_bandeja`, `compose_i01()` → hoja I-01, entrada de P1). **No se recorta nunca en M1.**
Pendiente H21 (overlay del ordenador) de la cola de diseño.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0006 (**Proposed**) | Foco dual, teclado en pantalla, etiquetas | HIGH |
| ADR-0005 (**Proposed**) | Datos de correos y consulta | MEDIUM |
| ADR-0007 (**Proposed**) | Escalado de UI (TR-computer-013/014) | MEDIUM |
| ADR-0001, ADR-0002 (Accepted) | Cubren TR-computer-006 y 009 (bus/hechos; reloj de juego) | MEDIUM |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-4**: `correos_leidos` lo escribe solo 19.
- **C-M1-6**: búsqueda con teclado y con mando.
- **C-M1-7**: capturas retenidas del ordenador y de la impresión.
- **C-M1-2**: `compose_i01()` alimenta el puzle 1.

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` computer; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-computer-001 | El receptor de 19 implementa `ViewReceiver` de 7 (`registrar_receptor`, `elements()`, `handle_pointer`, `on_open()`, `on_close(motivo)`); no recibe puntero hasta `on_open()`, que 7 llama solo tras ... | ❌ No ADR (ADR-0006, ADR-0005 Proposed) |
| TR-computer-002 | `on_close(motivo ∈ {jugador, sistema})` se ejecuta antes de devolver la cámara, comportamiento idéntico en ambos motivos: saca foco, oculta teclado, llama `reposo()`, conserva consulta y lista ... | ❌ No ADR (ADR-0006, ADR-0005 Proposed) |
| TR-computer-003 | `atrás` cierra siempre el ordenador (nunca `Retroceso`/`Esc`); 19 no puede bloquearlo ni siquiera con teclado en pantalla abierto. | ❌ No ADR (ADR-0006 Proposed) |
| TR-computer-004 | Con foco en el campo de búsqueda, la UI consume teclas imprimibles, `Retroceso`, `Supr`, flechas e `Intro` antes que cualquier acción de Entrada (regla 20 de 1). | ❌ No ADR (ADR-0006 Proposed) |
| TR-computer-005 | Estado de `V01` `apagado`→`sesión abierta` solo en memoria; no es hecho ni se guarda; tras cargar partida vuelve a `apagado`. | ❌ No ADR (ADR-0006, ADR-0005 Proposed) |
| TR-computer-006 | Único hecho escrito: `correos_leidos = verdadero` (3), una vez, en el mismo fotograma del primer resultado, sin vuelta atrás; 19 es su único lector. | ADR-0001 ✅ |
| TR-computer-007 | Búsqueda por coincidencia exacta tras normalizar (minúsculas, sin tildes ni signos, recortada) contra etiquetas de 18; longitud 3 ≤ n ≤ 32; sin prefijos ni búsqueda al teclear. | ❌ No ADR (ADR-0005 Proposed) |
| TR-computer-008 | Latencia de búsqueda `t_busqueda` = 0,4 s en tiempo de juego (se detiene en pausa; `reducir_movimiento` no la altera); si se cierra antes, no hay lista ni `correos_leidos`. | ❌ No ADR (ADR-0006, ADR-0005 Proposed) |
| TR-computer-009 | Temporizadores de 19 (`t_busqueda`, `t_impresion` 1,5 s, `t_tipeo_inactivo` 1,0 s) usan tiempo de juego y se pausan con la pausa. | ADR-0002 ✅ |
| TR-computer-010 | La lista muestra 6 correos (4 si `resultados_incluyen_ruido` = falso) en el orden fijo de 18 (`MAIL_3, MAIL_X1, MAIL_1, MAIL_4, MAIL_X2, MAIL_2`), sin reordenación. | ❌ No ADR (ADR-0005 Proposed) |
| TR-computer-011 | Teclado en pantalla activo si el dispositivo activo es mando, operado con el cursor y `seleccionar` existentes (sin acciones nuevas de Entrada); teclas ≥ 56 px lógicos (≥ `pick_min_px` 44), se... | ❌ No ADR (ADR-0006 Proposed) |
| TR-computer-012 | Cambio de dispositivo (mando→teclado) conserva texto y foco y oculta el teclado en pantalla. | ❌ No ADR (ADR-0006 Proposed) |
| TR-computer-013 | UI a resolución lógica 1920×1080 escalando con viewport, sin recortes en 16:9 y 16:10 (y 1280×720 físicos mínimo); pantalla ≥ 1280 px lógicos; modo teclado cabe en 520 px ≤ 720. | ❌ No ADR (ADR-0007 Proposed) |
| TR-computer-014 | Texto ≥ 24 px lógicos (cuerpo 28), contraste ≥ 4,5:1 (7:1 en cuerpo); cada estado con atributo no cromático y el botón deshabilitado expuesto como «no disponible» al lector de pantalla. | ❌ No ADR (ADR-0007 Proposed) |
| TR-computer-015 | Fundido de encendido 0,3 s (`t_encendido`); con `reducir_movimiento` de 6, 100 ms fijos; precisión ± 1 fotograma. | ❌ No ADR (ADR-0006, ADR-0005 Proposed) |
| TR-computer-016 | `V08` es máquina de estados `sin_resultados`→`lista`⇄`imprimiendo` (1,5 s) con indicador de sesión `hoja_en_bandeja`; tras cargar con `correos_leidos` verdadero nace en `lista`, `hoja_en_band... | ❌ No ADR (ADR-0006, ADR-0005 Proposed) |
| TR-computer-017 | El trabajo de impresión enviado no se cancela al cerrar el ordenador, salir de sala, cambiar de escena ni pausar; se completa y deja la hoja en bandeja. | ❌ No ADR (ADR-0006, ADR-0005 Proposed) |
| TR-computer-018 | Dos puntos de entrada (botón «Imprimir» y verbo de `V08`) comparten una máquina de estados; el botón está habilitado ⇔ `correos_leidos` ∧ `V08` ≠ `imprimiendo`; reenvío con hoja en ban... | ❌ No ADR (ADR-0006, ADR-0005 Proposed) |
| TR-computer-019 | Entrega: 19 llama a `otorgar_sesion("I-01")` de 20 (idempotente) solo si `has_item('I-01')` es falso; `I-01` no persiste y tras cargar se reimprime. | ❌ No ADR (ADR-0006, ADR-0005 Proposed) |
| TR-computer-020 | `compose_i01() -> SheetI01` es síncrona y pura (sin estado ni escritura): 6 bloques en orden de presentación, `ts_envio` entero en minutos desde lunes 00:00 siempre presente, `hora_envio`/`pie_or... | ❌ No ADR (ADR-0005 Proposed) |
| TR-computer-021 | Todos los valores de ajuste (tiempos, tamaños, `i01_*`, `pantalla_muestra_hora`, `resultados_incluyen_ruido`) se cargan de `assets/data/`, no constantes en código. | ❌ No ADR (ADR-0005 Proposed) |
| TR-computer-022 | Durante el tecleo 19 pide `reproducir_gesto('HAND_TYPE')` (bucle) y `reposo()` tras 1,0 s de inactividad o en `on_close`; un rechazo del Jugador no impide escribir. | ❌ No ADR (ADR-0006, ADR-0005 Proposed) |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
