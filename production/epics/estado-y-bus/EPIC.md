# Epic: Estado y bus de eventos

> **Layer**: Foundation
> **GDD**: design/gdd/estado-y-bus-de-eventos.md (§ Overview l. 15, § Acceptance Criteria l. 239)
> **Architecture Module**: Capa 1 — 3 Estado y bus (`GameState`, autoload n.º 2); `architecture.md` § Module Ownership y § API Boundaries «Bus y estado (3) — ADR-0001»
> **Status**: **LISTO** — 14/18 TR libres; TR-state-013…016 (instantánea/restaurar) esperan a ADR-0004 con el guardado diferido (recorte 4)
> **Actualizado 2026-11-11**: desbloqueado por ADR-0005 (TR-state-001)
> **Stories**: 15 historias (15 Ready, 0 Blocked) — índice con estimaciones y diferidos en `stories.md` (2026-11-11, manifiesto 2026-11-11b)
> **Control manifest**: v2026-11-11 — § Foundation Layer Rules (cubre ADR-0001, 0002, 0009)
> **Engine Risk**: MEDIUM (parser JSON enteros→`float`, TR-state-015)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Costuras de plataforma (`LogSink`, `ErrorPolicy`, `FatalErrorHandler`, `TestContexts`) | Logic | Ready | ADR-0009, ADR-0001 |
| 002 | `NoticeChannel`: suscripción, FIFO, drenaje sin reentrada | Logic | Ready | ADR-0001 |
| 003 | `NoticeChannel`: tope, callables inválidos, `run_after_drain`, tap | Logic | Ready | ADR-0001 |
| 004 | Registro `NoticeIds` y validación de payload | Logic | Ready | ADR-0001 |
| 005 | Esquema de `flags.json` y `load_catalog` | Logic | Ready | ADR-0005, ADR-0001 |
| 006 | Datos `flags.json` (20 hechos) | Config/Data | Ready | ADR-0005, ADR-0001 |
| 007 | Lecturas O(1) y valor neutro | Logic | Ready | ADR-0001 |
| 008 | Escritura validada y `FactWriter` | Logic | Ready | ADR-0001 |
| 009 | Hechos de un solo sentido y reversibles | Logic | Ready | ADR-0001 |
| 010 | Hechos derivados | Logic | Ready | ADR-0001 |
| 011 | Partida nueva (`reset_new_game`) | Logic | Ready | ADR-0001 |
| 012 | `write_silent` y ventana de carga | Logic | Ready | ADR-0001 |
| 013 | Gancho `dev_force` | Logic | Ready | ADR-0001 |
| 014 | Composición en `Boot` | Integration | Ready | ADR-0009, ADR-0001 |
| 015 | Test de estado de M1 | Integration | Ready | ADR-0001, ADR-0009 |

Diferido por ADR-0004 (TR-state-013…016), ADR-0018 (CA-29) y ADR-0007 (canal de Ajustes): ver `stories.md` § Diferido.

## Overview

Catálogo cerrado de hechos (`assets/data/state/flags.json`), lectura O(1), escritura validada con
escritor único (`owner`), cola de avisos y suscripciones. En M1 entran **5 de los 20 hechos**
(`correos_leidos`, `archivo_abierto`, `formulario_leido`, `tarjeta_B`, `tarjeta_D`) y el test de
estado que prueba que ningún estado alcanzable impide terminar la escena 3. Instantánea y
restauración para el guardado (ADR-0004) quedan fuera de M1 con el recorte 4.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0001: Event bus and fact contract (Accepted) | Bus único y contrato de hechos con escritor único; C1/NS-7 diferida a S-0006 | MEDIUM |
| ADR-0002: Pause and game time (Accepted) | `GameClock` único dueño de pausa y Δ_juego | HIGH (`process_mode`) |
| ADR-0009: Service composition (Accepted) | `Boot` única raíz de composición; inyección | LOW |
| ADR-0005 (Accepted) · ADR-0004 (Proposed) | ADR-0005 en TR-state-001/015; ADR-0004 en TR-state-013–016 | — |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-4**: los 5 flags los escribe solo su dueño (19 `correos_leidos`; 9 `archivo_abierto`;
  20 `formulario_leido`, `tarjeta_B`, `tarjeta_D`) y aparecen en el test de estado.
- **C-M1-3**: test de estado sin estados terminales en escenas 1–3.
- **C-M1-9**: suite en verde en CI.

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` state; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-state-001 | Catálogo cerrado de exactamente 20 hechos cargado de `assets/data/state/flags.json` (nombre, tipo `bool`/`int` con rango/`enum`, inicial, `owner`, regla de derivación opcional); fichero ausente o... | ADR-0001, ADR-0005 ✅ |
| TR-state-002 | Lectura del valor de un hecho en coste constante y sin asignaciones (lo lee el 7 en cada paso de física para ~35 objetos con `habilitado_si`) | ADR-0001 ✅ |
| TR-state-003 | Una escritura válida se aplica en el acto (y recalcula derivados) aunque ocurra durante una entrega de avisos; solo el aviso puede diferirse; lectura posterior devuelve el valor nuevo | ADR-0001 ✅ |
| TR-state-004 | Validación estricta de escritura sin conversiones de tipo (float en int, int en bool inválidos), rango, hecho no declarado, derivado, y cambio de hecho de un solo sentido; en dev detiene la ejecu... | ADR-0001 ✅ |
| TR-state-005 | Comprobación de `owner` por escritor solo en builds de desarrollo (no en la final); el `owner` de los hechos de puzle es el 9 | ADR-0001 ✅ |
| TR-state-006 | Hechos de un solo sentido (bool/enum salvo `pendiente_revelacion`); solo `pos_L/C/R` (int 1-4, inicial 2) y `pendiente_revelacion` son reversibles | ADR-0001 ✅ |
| TR-state-007 | Hecho derivado declarado en datos como combinación de otros (`caja_completa` = `caja_c1`∧`caja_c2`∧`caja_c3`∧`caja_c4`), recalculado automáticamente tras cada cambio de entrada y no escribi... | ADR-0001 ✅ |
| TR-state-008 | Aviso automático de cambio (nombre, valor anterior, valor nuevo) solo si el valor cambia realmente; suscripción por hecho concreto, a todos los cambios o por aviso con nombre (filtrado en el bus) | ADR-0001 ✅ |
| TR-state-009 | Avisos no persistentes (se pierden si nadie escucha); entrega en orden de ocurrencia y de suscripción, sin reentrada: los avisos provocados durante una entrega se encolan hasta terminar la actual | ADR-0001 ✅ |
| TR-state-010 | Baja de suscripción durante una entrega surte efecto al terminar esa entrega; suscriptores liberados con su escena no deben producir errores en el siguiente cambio (CA-17) | ADR-0001 ✅ |
| TR-state-011 | Tope `max_chained_notices` (propuesta 64, rango 8-256, en datos junto al catálogo): al superarse se descarta la cola, se registra (dev: detiene) y se emite «avisos descartados» | ADR-0001 ✅ |
| TR-state-012 | Un único mecanismo de avisos debe cubrir también el aviso propio de Ajustes (6); el formato técnico (señales/cadenas) y el de la instantánea los fija un ADR | ADR-0001 ✅ |
| TR-state-013 | Instantánea = mapa nombre→valor con `snapshot_version` (inicial 1, consultable); solo los 20 hechos, sin ajustes de volumen/subtítulos/controles | ADR-0001 ✅ (+ ADR-0004 Proposed) |
| TR-state-014 | Restauración síncrona y atómica dentro de una sola llamada (estado «Restaurando»: rechaza lecturas/escrituras/restauraciones reentrantes), descarta la cola, emite un único «estado restaurado... | ADR-0001 ✅ (+ ADR-0004 Proposed) |
| TR-state-015 | Tolerancia de tipos al restaurar desde JSON: número con fracción nula se acepta como `int` (2.0→2), con fracción o fuera de rango→inicial con log; hecho ausente→inicial; no declarado→ign... | ADR-0001, ADR-0005 ✅ (+ ADR-0004 Proposed) |
| TR-state-016 | Petición de instantánea síncrona que nunca espera: devuelve «no disponible» si la cola no está vacía (consulta `cola_vacía()`); Guardado reintenta | ADR-0001 ✅ (+ ADR-0004 Proposed) |
| TR-state-017 | `escribir_silencioso(hecho, valor)`: solo `owner` (9), solo hechos reversibles, solo en la ventana entre «carga de escena iniciada» y «escena lista» (el 3 se suscribe a ambos), valida como norm... | ADR-0001 ✅ |
| TR-state-018 | Consola de pruebas solo en builds de desarrollo (fuerza valores saltando reglas 4 y 6, emite aviso normal y deja log); ausente de la demo, verificado por script CI en `tools/ci/`; logs a destino su... | ADR-0001 ✅ |

## Requisitos bloqueados (al 2026-11-11)

| TR-ID | Bloqueado por | Motivo / salida |
|-------|---------------|-----------------|
| TR-state-013 | ADR-0004 (Proposed) | guardado, recorte 4 |
| TR-state-014 | ADR-0004 (Proposed) | guardado, recorte 4 |
| TR-state-015 | ADR-0004 (Proposed) | guardado, recorte 4 |
| TR-state-016 | ADR-0004 (Proposed) | guardado, recorte 4 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
