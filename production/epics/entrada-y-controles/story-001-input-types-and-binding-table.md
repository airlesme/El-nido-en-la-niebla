# Story 001: `InputTypes`, `BindingTable` y `default_bindings.json`

> **Epic**: Entrada y controles
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M (≈ 1,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/entrada-y-controles.md` § Detailed Design › Core Rules, reglas 1 (acciones lógicas), 4 (sin combinaciones) y 19 (asignaciones en datos); § Formulas › Valores por defecto y rangos seguros
**Requirement**: `TR-input-001`, `TR-input-016` (solo la carga de `default_bindings.json`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input abstraction, contexts and binding labels (D1, D11 `InputBinding`) · ADR-0005 (D1 fila `input/default_bindings.json`, D2)
**ADR Decision Summary**: `InputRouter` es una capa *junto* al Input Map: posee una `BindingTable` cargada de `assets/data/input/default_bindings.json` y empareja `RawInput` contra ella; el resto del juego solo conoce acciones lógicas. Asignaciones como `InputBinding` (`kind`, `code`, `axis_dir?`), nunca `InputEvent`.
**ADR Version**: ADR-0006 2026-11-10 · ADR-0005 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: no se usa el Input Map para el juego (D1). Nota de dependencia: ADR-0006 `depends_on` ADR-0007 (Proposed) solo por `settings_applied`/`controles`; esta historia no toca esa interfaz (la superposición del bloque `controles` queda diferida).

**Control Manifest Rules (this layer)**:
- Required: F-R42 (todo nombre de acción, asignación, umbral y etiqueta sale de `default_bindings.json`), F-R49–F-R52 (lectura por `DataReader`), F-R36
- Forbidden: `Input.is_action_*`/`InputMap` en código de juego (CI grep `Input\.`)
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/entrada-y-controles.md`, scoped to this story:*

- [ ] **AC-01**: el mapa cargado contiene solo las acciones físicas de la regla 1; `leer`, `agarrar`, `rotar`, `mantener` no son acciones (gestos derivados); no existen `correr`, `agacharse` ni `saltar`.
- [ ] **AC-04 (parte L)**: ninguna asignación de `default_bindings.json` combina dos botones, doble pulsación ni temporizador de reacción; las únicas esperas son `t_hold` y el arrastre.
- [ ] **AC-19 (1.ª mitad)**: cambiar `default_bindings.json` se refleja al arrancar sin tocar código (test con fixture en `MemoryFileStore`).
- [ ] Fichero ausente o inválido → `ctx.fatal` con el parámetro culpable.

---

## Implementation Notes

- Tipos de ADR-0006 § Key Interfaces: `class_name InputTypes` con `Context`, `Device`, `PadFamily`, `RawInput`, `InputBinding` (`equals()`), `ActionEvent`, `RebindResult` (solo declarado). Copiar literalmente.
- Valores por defecto (†) y rangos de § Valores por defecto y rangos seguros del GDD van al JSON; esquema en `src/input/data/default_bindings_schema.gd` (ADR-0005 D10).

---

## Out of Scope

- Superposición del bloque `controles` y reasignación (ADR-0007).

---

## Files

- `src/input/input_types.gd`, `src/input/binding_table.gd`, `src/input/data/default_bindings_schema.gd`
- `assets/data/input/default_bindings.json`
- `tests/unit/input/binding_table_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/binding_table_test.gd` — must exist and pass.
**Status**: [x] Created and passing (see `## Evidencia`)

---

## Dependencies

- Depends on: `production/epics/estado-y-bus/story-001-platform-seams.md`, `production/epics/contenido-y-datos/story-002-schema-and-data-reader.md`, `production/epics/contenido-y-datos/story-003-data-catalog-and-validator.md`
- Unlocks: `production/epics/entrada-y-controles/story-002-engine-input-adapter.md`, `production/epics/entrada-y-controles/story-013-binding-labels.md`

---

## Evidencia

- Suite propia: `tests/unit/input/binding_table_test.gd`, 38 casos, 0 fallos, 0 huerfanos (Godot 4.7.2, headless).
- Suite completa (`-a res://tests`): 349 casos, 41 suites, 0 errores, 0 fallos, 0 huerfanos; sin `ObjectDB instances were leaked` ni `resources still in use`. (El `SCRIPT ERROR ... nonexistent_method` del log es de un test de hechos del motor preexistente.)
- `--import` sin errores.
- AC-01: 13 acciones fisicas cerradas por enum en el esquema; `leer/agarrar/rotar/mantener/repasar_bolsillo/correr/agacharse/saltar` rechazadas (fatal en `actions[n].name`) y ausentes de la tabla.
- AC-04 (L): objetos cerrados; `chord_with`, `double_tap`, `reaction_window_s`, `combo`, `timer`, `modifier` son fatales; solo `t_hold_s` y `d_drag_px` en `tuning`.
- AC-19 (1.a mitad): fixture en `MemoryFileStore` con otro `code`/`t_hold_s` se refleja sin tocar codigo.
- Fichero ausente / JSON corrupto / version / rango: `ctx.fatal` CATALOGO_INVALIDO con `param` culpable.
- Decisiones fallback (`TODO(ADR-0006)` en el esquema): orden de las 4 teclas de `mover` (arriba, abajo, izq., der.) y un binding por eje de stick para `mover`/`mirar`; claves de `tuning`/`toggles` propias.
- Cambio a fichero compartido: solo la fila/esquema de `input/default_bindings.json` en `data_catalog.gd`.
