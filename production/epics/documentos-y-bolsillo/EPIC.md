# Epic: Documentos y bolsillo

> **Layer**: Feature
> **GDD**: design/gdd/documentos-y-bolsillo.md (§ Overview l. 15, § Acceptance Criteria l. 248)
> **Architecture Module**: Capa 3 — 20 Bolsillo (`Pocket` en `planta`; `ReadingScreen` en `HUD`)
> **Status**: **BLOQUEADO (parcial) por ADR-0005 (Proposed)** — 14/18 TR co-citan ADR-0005; 4 libres
> **Desbloqueo**: aceptación de ADR-0005 (spike S-0005-A, C5, O1 de ADR-0018)
> **Stories**: Not yet created — run `/create-stories documentos-y-bolsillo` (hoy, solo los 4 TR libres)
> **Control manifest**: v2026-11-11 — § Feature Layer Rules (vacía) + reglas transversales de Foundation
> **Engine Risk**: MEDIUM (`Control`/`RichTextLabel`, cambios 4.7 de imágenes)

## Overview

Conjunto de sesión, `otorgar`, `has_item`, pantalla de lectura y repaso del bolsillo; escritor
único de `formulario_leido`, `tarjeta_B` y `tarjeta_D`. En M1: formulario A04 (`formulario_leido`)
y tarjetas I-02 / I-03 del cajón A05 (`tarjeta_B`, `tarjeta_D`). Rotación en mano fuera (recorte 6).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0009: Service composition (Accepted) | Inyección (sin singleton); cubre la mayoría de TR | LOW |
| ADR-0001 (Accepted) | Escritura de hechos con `owner = 20` | MEDIUM |
| ADR-0005 (**Proposed**) | `items/items.json`, `inventory_config.json` | MEDIUM |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-1**: `tarjeta_B` y `tarjeta_D` en verdadero al final de la escena 3.
- **C-M1-4**: los 3 flags los escribe solo 20.
- **C-M1-7**: captura retenida de la pantalla de lectura del formulario (vista de Archivo).

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` pocket; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-pocket-001 | Catálogo cerrado de 7 ítems (`I-01`,`I-02`,`I-03`,`I-04`,`I-05`,`I-06a`,`I-07`) en `assets/data/items/items.json`; ninguno se crea en ejecución; ID fuera de catálogo → `has_item` falso + log ... | ❌ No ADR (ADR-0005 Proposed) |
| TR-pocket-002 | El bolsillo no tiene almacenamiento propio: `has_item(id)` se deriva del hecho (`tarjeta_B/D`, `formulario_leido`, `caja_c1/c2/c4`) o del conjunto de sesión; guardar/cargar/reiniciar no requieren ... | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-003 | `I-01` es el único ítem de sesión: en memoria, no persistido, se vacía al descargar planta, nueva partida y carga (`otorgar_sesion("I-01")`) | ADR-0009 ✅ |
| TR-pocket-004 | 20 es dueño y escritor de `formulario_leido`, `tarjeta_B`, `tarjeta_D` (monótonos, solo falso→verdadero); `otorgar("A05")` escribe B y luego D, idempotente | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-005 | Hecho primero, presentación después: toda adquisición escribe el hecho antes de mostrar nada; cancelar/rechazar la presentación no afecta hecho, avance ni guardado | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-006 | Presentación de tarjetas en serie por tarjeta (`t_item_dentro` 0,3 + `t_mostrar_item_s` 0,7 + `t_item_fuera` 0,3 = 1,3 s; 2,6 s con dos), sin bloquear contexto; se aborta ante `reposo()`, lectura,... | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-007 | `sostener(id, izquierda)`/`soltar()` al Jugador solo tras `gesto_terminado`; si rechaza, no reintenta; espera `objeto_sujeto`/`objeto_soltado`; detecta aborto externo por `objeto_soltado` no propio | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-008 | `sostener_item(id)` devuelve `ACEPTADA` o `RECHAZADA(motivo)` (incl. `presentacion_en_curso`); `HAND_HOLD_ITEM` (izq.) y `HAND_CARD_SWIPE` (der.) nunca coexisten | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-009 | Las tarjetas no se consumen; `guardar_item()` no cambia ningún hecho; no existe API para tirar/soltar/combinar/consumir | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-010 | Documentos = entradas de 18 (clave, fragmentos ordenados, estilo ∈ `impreso`,`manuscrito_vera`,`manuscrito_guardian`,`cristal_espejo`,`pantalla`,`libro`); estilo y correspondencia ítem→documen... | ❌ No ADR (ADR-0005 Proposed) |
| TR-pocket-011 | Dibuja la pantalla de `lectura` para cualquier documento que 7 entregue (clave+estilo); sin estado de página propio (7 indica la página); texto idéntico al de 18 sin marcas | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-012 | `formulario_leido` se escribe al recibir «lectura completada» de `A04` (≥ `lectura_min_s` 2 s, de 7); lectura <2 s no lo escribe | ADR-0001 ✅ |
| TR-pocket-013 | `repasar_bolsillo()` (acción derivada de `atrás` en `exploración`, de 1) llama `abrir_lectura(item_id)` de 7 con resultado `ACEPTADA`/`APLAZADA`/`RECHAZADA(motivo)` | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-014 | Cursor de repaso de sesión (no guardado) sobre lista fija `I-07,I-05,I-06a,I-04` filtrada por `has_item`; `i_siguiente = (pos+1) mod m` con `repaso_cerrar_ciclo`; `repaso_pendiente` evita avanzar ... | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-015 | Suscripción a «lectura abierta(ID)», «lectura cerrada», «lectura descartada», «lectura completada» (7); petición aplazada descartada a los 3 s por 7 | ADR-0001 ✅ |
| TR-pocket-016 | `A03` (DELEGAR a 20): estados `cerrada`/`abierta` no guardados; se reconstruye `abierta` si `formulario_leido`; tapa anima `t_tapa_s` 0,6 s sin bloquear; `A04` habilitado solo con `A03` abierta | ADR-0009 ✅ (+ ADR-0005 Proposed) |
| TR-pocket-017 | Al descargar la escena: cancelar presentación, cerrar lectura sin avisos al bus y vaciar el conjunto de sesión | ADR-0009 ✅ |
| TR-pocket-018 | Pista `UI_BOLSILLO_AYUDA` una vez por sesión (indicador no persistido) vía pie de 7/24; sin HUD ni icono de «obtenido» y sin audio de recompensa; `items.json` + `inventory_config.json` con `t_m... | ADR-0009 ✅ (+ ADR-0005 Proposed) |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
