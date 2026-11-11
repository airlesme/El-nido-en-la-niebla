# Story 001: Catálogo `interactables.json`, esquema y configuración de 7

> **Epic**: Interacción y prompt (mitad Interacción)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M — 1 día (0,5–1,5), confianza BAJA
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/interaccion-e-inspeccion.md` — § Detailed Design › Core Rules, reglas 2, 6, 31; § Tuning Knobs
**Requirement**: `TR-interact-001`, `TR-interact-004` (validación de máscaras)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (D1, D2, D7 campos `distancia_m`/`centro_m`); ADR-0005 (D1, D2, D3, D5, G-1…G-7, G-16)
**ADR Decision Summary**: el catálogo de 7 y `interaction_config.json` se leen por `DataReader` y se validan con un esquema GDScript del `DataCatalog`; las máscaras `mascara_interactuable`/`mascara_geometria` se validan contra la tabla de capas de D1 (bit 3 / bit 1; otro valor = error de datos).
**ADR Version**: ADR-0011 2026-11-10 · ADR-0005 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (lectura JSON, NOT SOURCEABLE medido en S-0005-A)
**Engine Notes**: S-0005-A: claves duplicadas en un objeto → **gana la última, en silencio** (no detectable tras parsear: los IDs van en arrays y el duplicado de `id` se detecta en el array); **coma final aceptada en silencio** (si debe ser error, la precomprobación de texto la hace `JsonText`, épico contenido-y-datos); **BOM eliminado en silencio** por `get_string_from_utf8`/`get_file_as_string`: el chequeo de BOM se hace sobre los **bytes** antes de decodificar (lo hace `DataReader`, no esta historia).

**Control Manifest Rules (this layer)**:
- Required: F-R05/F-X03 vía Foundation; ADR-0005 G-1 (solo `DataReader.read_file()`), G-4 (`schema_version` entero), G-6 (colecciones de ID abiertos = arrays de registros), G-7 (clave desconocida = error).
- Forbidden: FE-X03 (no codificar 1080/1920/70°); leer JSON fuera de `DataReader`.
- Guardrail: registro < 1 ms al construir (FE-G01).

---

## Acceptance Criteria

*From GDD `design/gdd/interaccion-e-inspeccion.md`, scoped to this story:*

- [ ] **AC-37**: los IDs del catálogo son exactamente las filas `interactuable: true` de `assets/data/interaction/cobertura_anexo_a.json`; toda fila `interactuable: false` lleva `motivo` y no está en el catálogo (la prueba no deriva nada de una columna del slice).
- [ ] **AC-38**: los ejemplos de la regla 31 (`V02`, `V05`, `A02a`, `A04`, `C05`, `D01a`, `V01`) validan; una entrada con campo de duración de bloqueo, `requiere_ítem`, campo desconocido, `sostenible` fuera de `INSPECCION_MANO`, `INSPECCION_MANO` con `radio_m` > `r_max_inspeccion_m` o bloque `vista` en efecto distinto de `DELEGAR` se rechaza.
- [ ] **AC-15 (parte de datos)**: un `texto` de 120 caracteres se rechaza (excede `texto_max_caracteres`); **AC-26b (parte de datos)**: `t_vista_entrada_s` > 1,2 s en `D01a`–`D01c` y `BOX_Cn_OPEN` > `BOX_OPEN_MAX` se rechazan.
- [ ] Máscaras distintas de bit 3 / bit 1 en `interaction_config.json` → error de datos (ADR-0011 D1).

---

## Implementation Notes

*Derived from ADR-0011 D1/D2 and ADR-0005 D2/D5:*

- Esquemas como declaraciones GDScript en el `DataCatalog` (ADR-0005 D2); dos ficheros: `assets/data/interaction/interactables.json` (array de registros con `id`) e `interaction_config.json` (umbrales de Tuning Knobs: `radio_apuntado_m` 0,06, `alcance_interaccion_m`, `desempate_prof_m` 0,03, `t_gracia_foco_s` 0,12, `radio_pegajoso_m` 0,15, `t_enfriamiento_s` 0,25, `t_anillo_inicio_s` 0,12, `latencia_feedback_ms` 100, `max_contactos_por_paso` 8, `pick_min_px` 44, máscaras…). Ningún valor de juego en código.
- `vista`/`modo` incluyen `distancia_m` (obligatorio en vistas) y `centro_m` (opcional, (0,0)) (ADR-0011 OI-2).
- El catálogo M1 contiene las 35 filas del Anexo A aunque las salas B/D no se jueguen (AC-37 lo exige); solo las de escenas 1–3 tendrán pick en la escena.
- Firma de la API de lectura del catálogo para 7: si ni ADR-0011 «Key Interfaces» ni ADR-0005 la fijan, **tarea de esta historia**: proponerla y registrarla como ADR-fallback (nota en § Decisiones del GDD o enmienda de ADR-0011), no inventarla en silencio.

---

## Out of Scope

- Story 002: construcción del `PickRegistry` a partir del catálogo y la escena.
- Épico contenido-y-datos: `DataReader`, `JsonText` (BOM en bytes, coma final), verificador de `tools/`.

---

## Files

- `assets/data/interaction/interactables.json`, `assets/data/interaction/interaction_config.json`, `assets/data/interaction/cobertura_anexo_a.json`
- `src/interaction/interaction_catalog.gd` (esquemas en el `DataCatalog` según ADR-0005 D2)
- `tests/unit/interaction/catalogo_interactuables_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/interaction/catalogo_interactuables_test.gd` — must exist and pass (gdUnit4).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/EPIC.md` (historias de `DataReader`/`DataCatalog`; aún sin crear)
- Unlocks: `production/epics/interaccion-y-prompt/story-002-pick-registry-y-pickmath.md`
