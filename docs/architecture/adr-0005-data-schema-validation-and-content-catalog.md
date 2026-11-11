# ADR-0005: Data Schema, Validation Pipeline and Content Catalog

## Status

Accepted (2026-11-11) — S-0005-A run on 4.7.2 (A7, A9, A10 also run in a release export). Findings to implement: duplicate JSON keys are undetectable after parsing, BOM must be checked on bytes before decoding, trailing commas are tolerated unless pre-checked

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing this ADR stay `Blocked` while it is `Proposed`.
> Acceptance additionally requires spike **S-0005-A** (§ Validation Criteria)
> to have run on Godot 4.7.2 and its results to be recorded in this file.

## Date

2026-11-10

## Last Verified

2026-11-10 — against `docs/engine-reference/godot/` (pin 4.7.2),
`docs/architecture/architecture.md` v1, ADR-0001/0002/0003/0009 (all
`Proposed`), `design/gdd/marco-de-puzles.md` rule 4b and rule 29,
`design/gdd/base-de-contenido-narrativo.md` (Core Rules 1–23, Edge Cases,
Open Questions) and `docs/architecture/tr-baseline-provisional.md`.

## Decision Makers

technical-director (author, autonomous mode per `project.yaml`
`modes.automation: autonomous`); user approval pending at batch close.

## Summary

Every tunable value, solution, text and scene of the slice lives in JSON under
`assets/data/`, but nothing yet fixes where each file goes, how it is typed,
when it is validated, or how the narrative catalog (18) serves text by
(id, language). This ADR fixes the `assets/data/<domain>/<snake_case>.json`
convention and a canonical file registry (closes QQ-21), one shared
`DataReader` that parses JSON and normalises it against a **GDScript-declared
schema** (explicit `int` coercion, closed enums, unknown-field rejection), a
three-tier validation pipeline — per-file at load in every build, whole-corpus
cross-reference at boot in debug only, and the same validator plus the
content verifier headless in CI (closes QQ-14) — the `ContentDB` load-once,
immutable-snapshot cache with its own language layer instead of the engine's
`tr()`, and the stable-ID policy (retired IDs kept in place).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable) |
| **Domain** | Core (file I/O, JSON parsing, data loading) · Tooling (headless CI script) |
| **Layer** | Foundation |
| **Knowledge Risk** | MEDIUM — the pattern (read text, parse JSON, walk `Dictionary`/`Array`) is pre-cutoff, but **none** of the engine calls it relies on is covered by `docs/engine-reference/godot/`; their 4.7.2 behaviour is confirmed only by spike S-0005-A |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `breaking-changes.md` § 4.3→4.4 (`FileAccess.store_*` return `bool`); `current-best-practices.md` § Command Line — Tests and Parse Check (`--headless`, `--path`, `-s`, `--export-debug`, the framework parse-check script that ends with `quit(code)` and is observed to exit 1/0); `modules/ui.md` § Localization-Ready UI (`tr("KEY")` as best practice, nothing more); `.claude/scripts/godot-parse-check.gd` (uses `quit(1 if failed > 0 else 0)`); ADR-0001 NS-3 (same JSON integer question, left open there) |
| **Post-Cutoff APIs Used** | `@abstract` on `DataSchema` (4.5; sourced in `current-best-practices.md` § GDScript, as in ADR-0009). No post-cutoff engine API: the decision uses only long-standing Core APIs and wraps each one behind a project class so a 4.7 behaviour difference changes one file |
| **Verification Required** | Spike **S-0005-A** (§ Validation Criteria): JSON number typing, error reporting, duplicate keys, non-standard syntax, UTF-8 and BOM, root types; `FileAccess` read and open-error reporting on `res://`; `.json` files present and readable in an exported build; parse time of a 200 KB file |

### Engine API sourcing

Every engine call this ADR depends on, and whether the reference covers it.
Anything marked NOT SOURCEABLE is used only behind the wrapper named in the
third column, and its observed 4.7.2 behaviour is written back here by S-0005-A.

| API / behaviour | Status | Wrapper · spike case |
|---|---|---|
| `JSON.new()` + `JSON.parse(text) -> Error`, `get_data()`, `get_error_line()`, `get_error_message()` | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** (no Core/JSON module) | `JsonText.parse()` · A1, A2 |
| `JSON.parse_string(text) -> Variant` (returns `null` on error) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`**; **not used**: it cannot tell a parse error from a literal `null` root and gives no line number | — |
| Type of an integral JSON number after parsing (`2` → `int` or `float`) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** (same as ADR-0001 NS-3; GDD 9 OQ 4 and TR-puzzles-006 assume `float`) | `DataReader` coercion (D4) · A1 |
| Duplicate keys inside one JSON object (`{"a":1,"a":2}`): error, first wins or last wins | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** | Rule D5.3 (IDs in arrays) · A3 |
| Comments, trailing commas, `NaN`/`Infinity`, UTF-8 BOM, non-ASCII (« » — ñ á) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** | `JsonText.parse()` · A4, A5 |
| `FileAccess.get_file_as_string(path)` / `FileAccess.open(path, READ)` + `get_as_text()`; `FileAccess.get_open_error()` on a missing file | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** (the reference only records the 4.4 `store_*` return-type change, which this ADR does not use: game data is never written) | `FileStore` of ADR-0009 · A6 |
| `res://assets/data/**/*.json` included in an exported `.pck` with the default export filters, and readable with `FileAccess` there | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** | Export preset rule G-14 · A7 |
| `DirAccess` listing of `res://` inside an export | **NOT SOURCEABLE**; **not used**: every file is named in the registry (D1), never discovered by listing | — |
| `Object.tr()`, `TranslationServer`, `Control` auto-translation | `tr("KEY")` named as best practice in `modules/ui.md`; its fallback, pluralisation and auto-translate behaviour on 4.7 **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`**; **not used** for player text (D7) | Rule G-9 · A8 |
| `OS.is_debug_build()` (debug-only validation and hot reload) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`**; already relied on by ADR-0009 D8 | `BuildFlavor` injected (D6) · A9 |
| SceneTree script run with `godot --headless --path . -s <script> -- <args>` and exit code via `quit(code)` | Sourced: `current-best-practices.md` § Command Line (flags; framework parse check exits 1/0 through `quit()`) | `tools/data_check/data_check.gd` |
| `OS.get_cmdline_user_args()` (arguments after `--`) | **NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`** | `data_check.gd` argument parsing · A10 |
| Project autoloads being present when a script runs with `-s` | **NOT SOURCEABLE**; the verifier does **not** depend on it (it builds its own `DataValidator` and `FileStore`, D8) | — |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0009 (service composition: `ContentDB` is autoload #1 and read-only; `Boot` step 1 loads 18, step 4 runs `DataValidator` "debug and CI only"; `FileStore`, `LogSink`, `FatalErrorHandler` and its codes `CATALOGO_INVALIDO`, `DATOS_ESCENA_INVALIDOS`, `CONTENIDO_INVALIDO`). ADR-0001 (`flags.json` semantics: `owner` as system number, enum values as `String`/`null`, `max_chained_notices` 8–256; snapshot restore tolerance of rule 13 / NS-3). ADR-0002 (`assets/data/core/clock.json` path, owned here only as a path). ADR-0003 (`load_transitions.json` validation at `SceneLoader.setup`, scene-load failure path used by `puzzles.json` in release). All four are `Proposed`; this ADR does not change any API they define |
| **Enables** | ADR-0004 (save: `save_config.json` schema slot), ADR-0006 (input: `default_bindings.json`), ADR-0007 (settings: `defaults.json`), ADR-0008 (audio: `audio_catalog.json` schema, line `audio` field), ADR-0010 (puzzle framework: `PuzzleDataRules` plugs into the pipeline defined here), ADR-0011 (interaction: `interactables.json` schema replaces `interactables.schema.json`), ADR-0014 (atmosphere), ADR-0016 (UI: `ContentDB` text API, `{accion:<id>}` token), ADR-0017 (director/call: `scenes.json`, `call.json`) |
| **Blocks** | Every story that loads a data file; Epic for system 18; the CI "data gate" story; S0 stories for 3 (flags), 4 (load transitions), 2 (player) |
| **Ordering Note** | `architecture.md` § Required ADRs lists ADR-0005 in "Must have before coding". Field-level schemas of files owned by later ADRs are **slots**: this ADR fixes path, root shape, `schema_version`, failure policy and the coercion rules; the owning ADR fills the field list without re-deciding them |

## Context

### Problem Statement

Principle 3 of `architecture.md` ("Datos, no código… validados al arrancar y
en CI") and `.claude/docs/coding-standards.md` ("Gameplay values must be
data-driven") put ~25 JSON files on the critical path of every system, and
the GDDs already cite them by path. Without one decision before the first
loader is written, each system will (a) pick its own file name and folder
(QQ-21 already records four outliers), (b) cast JSON numbers to `int` its own
way — or not at all, so `sequence: [2,1,3,4]` compares `float` to `int`
(TR-puzzles-006), (c) decide alone whether a bad value is fatal, a warning or
a clamp, and (d) leave cross-file references (a puzzle's `solved_flag`, a
`PISTA_*` key, an item ID) checked by nobody. System 18 additionally needs a
language layer, a name-marker substitution, variant groups and a CI verifier
against `design/slice/slice-v0.3.md` §12 — its GDD defers the file format,
the retired-ID storage and the names table to this ADR (OQ 1, 5, 6, 7).

### Current State

No code and no data: `assets/data/narrative/`, `assets/data/puzzles/` and
`assets/data/state/` hold only `.gitkeep`; `tools/` holds only the pinned
editor binaries under `tools/godot/`. The documented state:

- 22 distinct paths under `assets/data/` are cited across the GDDs (inventory
  of 2026-11-10), with mixed separators (`save-config.json`,
  `scene-config.json`), one file at the root (`hints_policy.json`), one stray
  reference to `assets/data/flags.json`, a near-collision of folders `scene/`
  (4) and `scenes/` (21), and CI-only reference files (`cobertura_anexo_a.json`)
  mixed with shipped data.
- `architecture.md` § Data Flow 4 step 2c lists a `DataValidator` "(debug y
  CI)" over 12 files and records the clash with GDD 9 (validation at `planta`
  configuration, failure = scene-load failure) as QQ-14.
- GDD 7 proposes a formal schema file `interactables.schema.json`; no other
  GDD proposes a schema mechanism.
- `architecture.md` § Module Ownership row 18: "sin `tr()` del motor
  obligatorio: capa propia de idioma (decisión ADR-0005)".

### Constraints

- **Engine:** no JSON-Schema validator ships with Godot (none is listed in the
  reference); any schema mechanism is project code. The JSON number typing,
  duplicate-key behaviour and export inclusion are NOT SOURCEABLE (§ Engine
  API sourcing) — the design must be correct under both possible outcomes.
- **Engine:** `--check-only -s` fails on code that names an autoload
  (`current-best-practices.md`); the CI verifier must not name autoloads.
- **Design:** failure semantics are already signed per GDD and differ on
  purpose — fatal (3 CA-26, 2 TR-player-002, 4 TR-scene-022, 5 TR-save-021),
  scene-load failure (9 R29), drop-one-record (21 TR-director-004), clamp and
  warn in the demo (10 TR-box-008, D9-53). One pipeline must carry all of them
  without flattening them.
- **Design:** 18 is read-only at runtime, loads once, never reads game state
  (TR-content-004/-012); hot reload exists only in development and is atomic.
- **Design:** IDs from the slice are kept verbatim and case-sensitive
  (`VO_G_12A`, `I-06a`, `caja_c1`); CLAUDE.md keeps document IDs as-is.
- **Team:** solo/indie; one validator, one place to add a file, no plugin.
- **Composition:** ADR-0009 — `ContentDB` and `DataValidator` receive
  `FileStore`, `LogSink`, `FatalErrorHandler` by injection; nothing names an
  autoload outside `Boot`.

### Requirements

- Every data file is found from one registry; a file not in it is not loaded.
- Integer fields arrive as `int`, always, whatever the parser returns
  (TR-puzzles-006, TR-state-015, TR-computer-020 `ts_envio`).
- A packaging defect never reaches a player: CI fails on any data error
  (AC-47 of 9, TR-content-013, TR-access-001).
- Release builds keep each GDD's own failure behaviour; debug builds stop at
  boot on the first run with all errors listed, not just the first.
- 18 serves text by (id, language), falls back to `es` with a log, returns
  «no encontrado» for missing and retired IDs, substitutes 4 name markers,
  reads files once (AC-21: counted with a `FileStore` double).
- Unit-testable without disk: every loader and validator takes the parsed or
  raw text through an injected `FileStore` (`MemoryFileStore` in tests).
- No per-frame cost: all parsing and validation happen at boot or at scene
  load; runtime reads are dictionary lookups.

## Decision

Ten numbered decisions. Mandates use **must / must never** so
`/create-control-manifest` can extract them. ‡ marks a name this ADR proposes
(no GDD fixes it).

### D1. File convention and the canonical registry (closes QQ-21)

**Convention (must).**

1. Shipped game data **must** live at `assets/data/<domain>/<file>.json`,
   exactly one folder level. `<domain>` is the owner system's folder from the
   registry below (the domain nouns already used by the GDDs, not the TR
   slugs: `narrative`, not `content`). Nothing lives at the root of
   `assets/data/`.
2. `<file>` **must** be `snake_case`, ASCII, `[a-z0-9_]+`. No kebab-case, no
   accents, no upper case. Folder names follow the same rule.
3. One folder has exactly one owner system; only the owner's loader reads
   the file at runtime. Other systems receive its content through the owner's
   API or, for validation only, through `DataValidator` (D3).
4. Every file **must** be a JSON object with a top-level
   `"schema_version": <int>`. A version the loader does not support is a
   validation error (generalises GDD 9 rule 4b to every file).
5. CI-only reference data (fixtures copied from the slice, coverage tables)
   **must never** live under `assets/data/`; it goes to
   `tests/fixtures/<domain>/` (not exported). This moves
   `cobertura_anexo_a.json` (7), `floor_layout.json` and `element_ids.json`
   (4) out of the shipped tree.
6. A file is loaded **only** if it has a row in `DataCatalog` ‡
   (`src/core/data/data_catalog.gd`), which mirrors the table below. No
   runtime directory listing (§ Engine API sourcing: `DirAccess` in exports
   not sourced). Adding a file = one table row here + one `DataCatalog` entry
   + its schema.
7. Data field names are **kept as the owning GDD writes them** (Spanish or
   English, e.g. `linea_de_tiempo`, `solved_flag`), but **must** be
   `snake_case` ASCII. They are document identifiers in the sense of
   CLAUDE.md; the code identifiers that wrap them are English.

**Canonical registry.** "Release policy" = what the **release** build does
when the file fails its tier-L validation (D3). Debug always stops (D3).
"Renamed" rows are QQ-21 resolutions and require a path edit in the GDD named.

| Path (`assets/data/…`) | Owner | `schema_version` | Field list owned by | Release policy on failure | Change vs sources |
|---|---|---|---|---|---|
| `state/flags.json` | 3 | 1 | ADR-0001 D7/D8 + § D2.5 | Fatal `CATALOGO_INVALIDO` → error panel, no game (CA-26 of 3) | the `assets/data/flags.json` cited in `reviews/cross-review-r9-esquema-v2.md` is wrong |
| `narrative/*.json` (10 files, § D2.3) | 18 | 1 | § D2.3 | Fatal `CONTENIDO_INVALIDO` → load-failure message, no game (TR-content-011) | file names fixed here (GDD 18 OQ 1); the plan's `lines.json` is one of them |
| `core/clock.json` | GameClock | 1 | ADR-0002 § Tuning | Fatal `CATALOGO_INVALIDO` | — |
| `input/default_bindings.json` | 1 | 1 | ADR-0006 | Fatal `CATALOGO_INVALIDO` | — |
| `settings/defaults.json` | 6 | 1 | ADR-0007 | Fatal `CATALOGO_INVALIDO` (TR-settings-019) | — |
| `audio/audio_catalog.json` | 23 | 1 | ADR-0008 (fields: GDD 23 § audio_catalog) | Record dropped + log; requesting it behaves as "sin audio" ‡ ADR-0008 | — |
| `audio/audio_settings.json` | 23 | 1 | ADR-0008 | Fatal `CATALOGO_INVALIDO` | — |
| `save/save_config.json` | 5 | 1 | ADR-0004 (keys: TR-save-021) | Fatal `CATALOGO_INVALIDO` with the parameter name (TR-save-021) | **Renamed** from `save-config.json` (GDD 5) |
| `scene/load_transitions.json` | 4 | 1 | ADR-0003 (ranges: TR-scene-022) | Fatal `DATOS_ESCENA_INVALIDOS` (TR-scene-022) | — |
| `director/scenes.json` | 21 | 1 | ADR-0017 (fields: TR-director-003) | Invalid **scene record** dropped + one log line; the rest runs (TR-director-004) | **Renamed** from `scenes/scenes.json` (GDD 21): `scene/` and `scenes/` as siblings with different owners is a trap |
| `director/director_config.json` | 21 | 1 | ADR-0017 | Fatal `CATALOGO_INVALIDO` | **Renamed** from `scenes/scene-config.json` (GDD 21) |
| `player/player.json` | 2 | 1 | ADR-0012 (ranges: TR-player-002) | Fatal `CATALOGO_INVALIDO` with parameter name; missing optional `radio_sensor_zona` allowed (TR-player-002) | — |
| `interaction/interactables.json` | 7 | 1 | ADR-0011 | Scene-load failure of 4 ‡ ADR-0011 (loaded in `planta` configuration) | `interactables.schema.json` (GDD 7) **replaced** by a GDScript schema (§ D2.1) |
| `puzzles/puzzles.json` | 9 | **2** | ADR-0010 + GDD 9 rule 4b (§ D2.4) | Scene-load failure of 4, never an inactive puzzle (GDD 9 R29, TR-puzzles-005) | — |
| `puzzles/p1_view.json` ‡ | 9 (layout for 11) | 1 | ADR-0010 | Scene-load failure of 4 | path proposed by GDD 11 ‡, kept |
| `access/access.json` | 8 | 1 | ADR-0011 (`doors[]`/`readers[]`/`drawers[]`/`elevator`, TR-access-001) | Scene-load failure of 4 | — |
| `box/box.json` | 10 | 1 | ADR-0010 (TR-box-008) | Out-of-range `BOX_C1_OPEN`…`BOX_C4_OPEN` **clamped** to 1,6 s + warning; any other error = scene-load failure (TR-box-008, D9-53) | — |
| `items/items.json` | 20 | 1 | ADR-0011 (closed catalog of 7, TR-pocket-001) | Scene-load failure of 4 | — |
| `items/inventory_config.json` | 20 | 1 | ADR-0011 | Scene-load failure of 4 | — |
| `computer/computer.json` ‡ | 19 | 1 | ADR-0011 (TR-computer-021: `i01_*`, times, sizes) | Scene-load failure of 4; at runtime a bad `I-01` block is still omitted with «—» and logged (TR-computer-020) | **Named here**: GDD 19 only says "`assets/data/`" |
| `call/call.json` | 22 | 1 | ADR-0017 (QQ-20; times: TR-call-022) | Scene-load failure of 4 | path fixed here (`call.json` was ‡ in GDD 22) |
| `hints/hints_policy.json` | 17 | 1 | ADR-0010 (keys: TR-hints-019) | Scene-load failure of 4 | **Moved** from `assets/data/hints_policy.json` (GDD 17) |
| `ui/prompt.json` | 24 | 1 | ADR-0016 | Fatal `CATALOGO_INVALIDO` (Shell UI, loaded at boot) | — |
| `ui/pause.json` | 25 | 1 | ADR-0016 | Fatal `CATALOGO_INVALIDO` | — |
| `atmosphere/atmosphere.json` | 28 | 1 | ADR-0014 (TR-atmos-004) | Scene-load failure of 4 ‡ ADR-0014 may soften to "default profile + log" | — |

**Default release policy (must).** A file whose GDD states no failure
behaviour uses the policy of its load point: loaded at boot → fatal
`CATALOGO_INVALIDO`; loaded during a scene's configuration → scene-load
failure of 4 (ADR-0003). The reasoning is GDD 9 R29's: a read-only packaged
file cannot be made invalid by the player, so an error is a packaging defect
and must be loud; tier C (D3) keeps it from shipping. A GDD that wants a
softer policy (drop, clamp) states it and the registry row records it.

### D2. Schema catalog: schemas are GDScript declarations

**D2.1 Mechanism (must).** Each registered file has exactly one schema: a
GDScript class extending `DataSchema` ‡ that builds a tree of `FieldSpec`
nodes (§ Key Interfaces). The schema is code, reviewed with the loader, and
the **same object** is used by the runtime loader (tier L), the boot
validator (tier B) and the CI verifier (tier C). Schemas live next to their
owner (`src/<area>/data/<file>_schema.gd`, e.g.
`src/puzzles/data/puzzles_schema.gd`, `src/narrative/data/lines_schema.gd`);
`DataCatalog` references them. JSON-Schema documents (`*.schema.json`)
**must never** be added: no engine validator runs them, and a hand-written
one would be a second dialect to maintain (§ Alternatives 2).

**D2.2 What a schema expresses.** Types `BOOL`; `INT` (with `min`/`max`);
`FLOAT` (with `min`/`max`); `STRING` (non-empty unless `allow_empty`);
`ID` (pattern-checked `String` → `StringName`); `ENUM` (closed list →
`StringName`); `NULLABLE(x)`; `ARRAY(x)` (with `min_len`/`max_len`,
`unique_by`); `OBJECT` (required/optional keys; **unknown key = error**
unless declared `open_with_warning`, as GDD 9 asks for extra `on_solved`
keys); `MAP(key_pattern, x)` (free keys: `stamp_text_keys`, `map`);
`ONE_OF(discriminator, {…})` (`effects[].type`, `write[]`); `LANG_TEXT`
(language map, D7). Per-file semantic rules a tree cannot express (cycles in
`requires.all`, injective `solution.map`, non-decreasing `t_rel`) go into an
optional `FileRules` ‡ object for the same file, run after normalisation.
Cross-file references are declared on a field as `ref(kind)` (`&"fact"`,
`&"fact_value"`, `&"content_key"`, `&"item"`, `&"interactable"`, `&"view"`,
`&"sound"`) and resolved in tier B and C only (D3).

**D2.3 Narrative catalog files (18).** Closes GDD 18 OQ 1, 6 and 7. All in
`assets/data/narrative/`, each `{ "schema_version": 1, "<collection>": [ … ] }`.
Every record has `id` (pattern per prefix, D9) and `status`
(`"active"` | `"retired"`, default `"active"`). Text-bearing fields are
`LANG_TEXT` maps `{ "es": "…" }` (D7). `pending: true` is the "marcador de
pendiente" of rules 22–23 (a field, not a text convention).

| File | Collection | Record keys | 18 rule 1 type |
|---|---|---|---|
| `lines.json` | `lines` | `id` (`VO_V_*`, `VO_G_*`, `MEGA_*`), `speaker` (ENUM `vera`/`guardian`/`megafonia`/`interior`), `scene` (INT 1–8), `segments: [{ text: LANG_TEXT, pause_before_s: FLOAT? }]` (≥ 1), `audio` (STRING `res://` path or `null`), `source` (ENUM `slice_§12`/`propuesta_D-B1` or `null`), `pending` | Línea |
| `nonverbal.json` | `nonverbal` | `id` (`SUB_<EVENTO>`), `scene`, `text: LANG_TEXT` (form `[…]`), `audio` (or `null`), `pending` | Sonido no verbal con subtítulo |
| `documents.json` | `documents` | `id` (`DOC_*`, `NOTA_*`, `CARTA_*`, `FORM_*` ‡, `LIBRO_*` ‡, `DOC_I01`), `doc_type` (ENUM), `fragments: [{ id: "F1", text: LANG_TEXT }]` (≥ 1, ordered), `style` (ENUM `impreso`/`manuscrito_vera`/`manuscrito_guardian`/`cristal_espejo`/`pantalla`/`libro`), `item` (`I-01`…`I-07` or `null`), `source`, `pending` | Documento (incl. the 7 §12 entries `DOC_01`, `NOTA_*`, `CARTA_*`) |
| `mails.json` | `mails` + `presentation_order` | `id` (`MAIL_1`…`MAIL_4`, `MAIL_X1`, `MAIL_X2`), `ref` (INT 1–4 or `null`), `sender`, `subject: LANG_TEXT`, `body: LANG_TEXT`, `day` (ENUM), `sent_min` (INT, minutes from Monday 00:00), `tags: { lang: [STRING] }`; `presentation_order` = array of mail IDs (TR-content-009) | Correo |
| `tasks.json` | `tasks` | `id` (`T1`…`T4`), `title`, `description` (LANG_TEXT), `edits: [{ struck, replacement }]` | Ficha de tarea |
| `hints.json` | `hints` | `id` (`PISTA_P<n>_N<k>`), `puzzle` (`P1`…`P6`), `level` (INT 1–3), `text` | Pista (closed set of 8) |
| `ui.json` | `ui` | `id` (`UI_*`), `text`, `pending` | Interfaz / mensaje del sistema |
| `objects.json` | `objects` | `id` (`OBJ_<id>`), `text`, `pending` | Texto de objeto |
| `names.json` | `names` | exactly `vera` and `guardian`, each `{ name: LANG_TEXT, initial: LANG_TEXT }` | Tabla de nombres (OQ 7: its own file) |
| `groups.json` | `groups` | `prefix` (`CARTA_`, `VO_G_12`, `VO_G_13`, `VO_G_14`, `VO_V_12`), `suffixes` (array: `"A"`… or `"_RET"`, `"_ASG"`; full ID = `prefix + suffix`) | Grupos de variantes (TR-content-004) |

**Retired IDs (OQ 6) stay in place** with `"status": "retired"` in the file
of their type — there is no `retired.json`. Keeping the record where it was
lets the duplicate check see it (so it is never reused), keeps its history in
`git blame`, and lets the verifier report any reference to it.

**D2.4 `puzzles/puzzles.json` v2.** Root `{ "schema_version": 2, "puzzles":
[ <PuzzleDef> ×6 ] }`, records keyed by `id` (`P1`…`P6`). `PuzzlesSchema`
encodes rule 4 and the rule-4b table field by field: `write[]` as `ONE_OF`
(exactly one of `value`/`value_from`, optional `map` only with
`value_from`); `on_reject` as `NULLABLE(OBJECT)` with `message_key`,
`message_s` (FLOAT 1,0–3,0), `applies_to`; `commit_on`, `idle_reset`,
`AFFORDANCE.affordance`, `presentation[].call`, `resolution.steps[].kind`,
`availability`, `condition` as closed `ENUM`s (TR-puzzles-004); integers
`sequence[]`, `pos_*`, `level`, `compartment` (1–4), `idle_move_px` (≥ 16),
`min_separation_px`, `tolerance_px` as `INT` (TR-puzzles-006); `on_solved`
as `open_with_warning`. Everything in rule 29 that crosses fields or files —
`id`/`solved_flag` unique and declared in `flags.json`, `requires.all`
acyclic and with a writer, `on_reject` non-null under `DELAYED_AFTER_CHANGE`
and `PER_ELEMENT`, `message_s` present with `message_key`, `value_from`
values valid for the fact's enum after `map`, `TEXT` effects pointing to an
existing `PISTA_*` (TR-content-016), `targets` in 7 or `decor`/
`visual_elements`, initial state not satisfying the solution, P3 `map`
injective, element separation (**error** at normal tolerance, **warning** at
assisted tolerance), `request_reading.doc` in `rewards` — is
`PuzzleDataRules` ‡, specified by ADR-0010 and executed in tier L (in
`planta`) and tier B (at boot, debug).

**D2.5 Other schemas fixed here (root and typing; fields per owner ADR).**

| File | Root | Typing fixed here |
|---|---|---|
| `state/flags.json` | `{ schema_version: 1, max_chained_notices: INT 8–256, facts: [ { name, type, initial, owner, range?, values?, derive? } ] }`, exactly 20 facts | `name` ID `^[a-z][a-z0-9_]*$`; `type` ENUM `bool`/`int`/`enum`; `owner` INT (system number, ADR-0001 D7); `initial` typed by `type` (enum: `String` or `null` = "sin fijar"); `range` `[INT, INT]`; `values` ARRAY(STRING) unique |
| `director/scenes.json` | `{ schema_version: 1, scenes: [ { id, tipo, disparador, condiciones, linea_de_tiempo, al_disparar?, cadena?, t_fin?, duracion_declarada? } ] }` (cue fields per ADR-0017 D1) | `tipo` ENUM `momento`/`dirigida`; `linea_de_tiempo[].t_rel` FLOAT ≥ 0; `orden` ENUM (catalog ‡ ADR-0017); `condiciones` ref `fact`/`fact_value`. **Record isolation**: errors inside a scene record drop that record only (TR-director-004) |
| `audio/audio_catalog.json` | `{ schema_version: 1, sounds: [ { id, bus, prioridad, archivos, lazo, fuente_defecto, perfil_fuente, trim_db, sobresalto, pedido_por } ] }` | `id` pattern `SFX_*`/`AMB_*`/`MUS_*`; `bus` ENUM (names ‡ ADR-0008); `archivos` ARRAY(STRING) ≥ 1; `prioridad` INT; lines are **not** here (they are 18's `audio`). **Record isolation** as in the registry |
| `call/call.json` | `{ schema_version: 1, times: { t_sil_s, t_resp_s, t_ante_s, t_guarda_opciones_s, t_espera_s, t_cierre_s, line_grace_s, t_pick_s, t_breath_s, t_putdown_s }, keys: { … } }` | times FLOAT ≥ 0 (ranges ADR-0017 D7); no `fallback_s` (per line from 18) and no `t_corte_senal_s` (ADR-0017 A5/C1/C2); `keys` ref `content_key` and group prefixes |
| `hints/hints_policy.json` | `{ schema_version: 1, defaults: { … }, puzzles: { P1: { label_key, discover_if, gap_s, reapply_text_on_reopen }, … } }` | `puzzles` MAP `^P[1-6]$` (puzzle IDs are a closed set, so a map is safe here, D5.3); `label_key` ref `content_key` (TR-hints-019); `gap_s` FLOAT ≥ 0; `reapply_text_on_reopen` BOOL |
| `scene/load_transitions.json` | `{ schema_version: 1, d, t_cap, n_gap, delta_max }` | `d` FLOAT ≤ 5; `t_cap` FLOAT 3–30; `n_gap` INT 0–10; `delta_max` FLOAT 0,05–0,1 (TR-scene-022; `T_cap`, `N_gap`, `Δ_max` lowered to ASCII snake_case by D1.7) |
| `save/save_config.json` | `{ schema_version: 1, t_agrupar, t_periodico, t_reintento_base, t_reintento_max, n_fallos_aviso, max_bytes_lectura, causas_activas }` | times FLOAT; `n_fallos_aviso`, `max_bytes_lectura` INT; `causas_activas` ARRAY(ENUM) (causes ‡ ADR-0004) |

### D3. Validation pipeline: three tiers, one validator (closes QQ-14)

| Tier | When | Builds | Scope | On error |
|---|---|---|---|---|
| **L — load** | When the owner loads its file: at boot (`setup(ctx)`, ADR-0009 D2) or in a scene's `configurar()` (ADR-0003) | **All** (debug and release) | One file: parse + schema normalisation + its `FileRules`, plus references to catalogs the owner already holds (9 checks `flags.json` through `GameState`, keys through `ContentDB`, 7's catalog through `InteractionSystem`, as GDD 9 R29 orders) | Debug: `ctx.fatal` (stops). Release: the registry's policy (D1) |
| **B — boot sweep** | `Boot` step 4 (ADR-0009 D2), after `ContentDB` and `GameState` are ready | **Debug only** (`BuildFlavor.is_debug()`) | **Every** registered file, including those normally loaded later by `planta` (`puzzles.json`, `interactables.json`, `call.json`…), plus every cross-file `ref()` against a `RefIndex` built from all normalised files | Collect **all** issues, `push_error` each one, then one `ctx.fatal.raise_fatal(&"CATALOGO_INVALIDO", {count, first})`; warnings are logged and never stop |
| **C — CI** | Every push to `main` (`.claude/docs/coding-standards.md` § CI/CD) and as the packaging gate (GDD 9 AC-47) | Headless, no game scene | Tier B's sweep **plus** the content verifier (§12 comparison, TR-content-013/-014) and the static literal scan (TR-content-006) | Exit code ≠ 0 blocks the merge and the export |

Rules:

1. **One implementation (must).** Tiers L, B and C call the same
   `DataReader.read_file(entry)` and the same `FileRules`; tier B and C only
   add the `RefIndex` pass. A check that exists only in CI is allowed (§12
   comparison, literal scan); a check that exists only at runtime is not.
2. **QQ-14 resolution.** `puzzles.json` is validated in **both** places: in
   `planta` configuration in every build, with GDD 9's release behaviour
   (scene-load failure, never an inactive puzzle), and at boot in debug and
   CI only, so a developer sees a broken puzzle on the title screen instead
   of after walking into `planta`. The boot sweep does **not** run in release:
   release behaviour stays exactly GDD 9's (`architecture.md` § Data Flow 4
   note kept).
3. **Collect, then fail (must).** Inside one tier the validator never stops
   at the first issue; every `DataIssue` carries
   `{severity, file, json_path, rule, message}` (`json_path` like
   `puzzles[2].on_solved.write[0].value_from`) so one run lists everything.
   The single fatal call comes at the end with the count and the first error.
4. **Severities.** `ERROR` blocks (tier L policy, tier B fatal, tier C exit 1).
   `WARNING` is logged, exit code stays 0 (GDD 18 rule 16; GDD 9 R29
   separation advisory; unknown keys in `open_with_warning` objects; missing
   audio file). `--hito=calidad` promotes the warnings tagged `quality`
   (pending marker, missing audio) to errors (TR-content-013).
5. **Record isolation.** Files whose registry row says "record dropped"
   (`director/scenes.json`, `audio/audio_catalog.json`) are validated per
   record in release: a failing record is removed from the normalised output
   with one log line, the rest loads. In debug and CI it is still an `ERROR`.
6. **Clamp policy.** `box.json` declares its `BOX_Cn_OPEN` fields with
   `on_out_of_range = CLAMP` in its schema; in release the reader clamps and
   emits a `WARNING`; in debug and CI it is an `ERROR` (TR-box-008, D9-53).
   No other file may declare `CLAMP` without a registry row saying so.
7. **Boot order unchanged.** This ADR keeps ADR-0009 D2: `ContentDB.setup`
   (step 1) and `GameState.setup` (step 2) run tier L on their own files;
   `DataValidator.run(ctx)` (step 4) is tier B. Systems loaded at steps 5–11
   still run their own tier L (in debug that re-reads a file tier B already
   checked; accepted cost, see § Performance).

### D4. Explicit numeric conversion

The type of an integral JSON number after parsing is **NOT SOURCEABLE** for
4.7 (§ Engine API sourcing). The decision is correct under both outcomes:

1. Every field the schema declares `INT` goes through
   `DataReader.to_int(value, path, issues) -> int`: accepts an `int`, or a
   `float` whose fractional part is exactly 0 and whose magnitude is
   ≤ 2^53 (`9007199254740992`); converts and range-checks. Rejects `2.5`,
   `true`, `"2"`, `null` with an `ERROR` naming the path.
2. Every `FLOAT` field accepts an `int` or a `float` and stores `float`.
3. System code **must never** cast raw parsed values (`int(x)`, `x as int`,
   `floori(x)`) — `int(2.7)` truncates silently. It reads only the
   normalised output of `DataReader`, whose `int` fields are already `int`.
4. Arrays of integers (`sequence`, `pos_*`) are returned as `Array[int]`
   (typed), so `==` against a controller's `Array[int]` is well defined.
5. Snapshot restore (ADR-0001 rule 13) and settings files (ADR-0007) use the
   same `to_int`, so "2.0 → 2 accepted, 2.5 → initial with log" is one
   function (TR-state-015).
6. Spike case A1 records the actual behaviour. If integers arrive as `int`,
   nothing changes (rule 1 accepts both); if they arrive as `float`, rule 1 is
   what makes the game work.

### D5. Reading files

1. **Single entry point (must).** All game data is read through
   `DataReader.read_file(entry: DataCatalog.Entry) -> DataResult`, which uses
   the injected `FileStore` (ADR-0009) for the text and `JsonText.parse()` for
   the parse. No system calls `FileAccess` or `JSON` directly for game data.
2. **Parse with the instance API.** `JsonText.parse()` wraps
   `JSON.new().parse(text)` (not `JSON.parse_string`) so a parse error is an
   `Error` with line and message, distinct from a literal `null` root. Strict
   JSON only: no comments, no trailing commas; whatever the 4.7.2 parser
   tolerates beyond strict JSON (A4) is still rejected by the authoring rule
   and, where detectable, by the verifier.
3. **IDs live in arrays, never as object keys (must).** A collection of
   records keyed by an open ID set is an array of objects with an `id` field
   (`"puzzles": [ { "id": "P1", … } ]`), never `{ "P1": { … } }`, because
   duplicate object keys are NOT SOURCEABLE (A3) and may be silently merged by
   the parser; a duplicate `id` in an array is always detectable. Exception:
   maps keyed by a **closed** set that the schema enumerates (`hints_policy`
   `P1`…`P6`, `names` `vera`/`guardian`, `stamp_text_keys` actions), where a
   missing key is caught by the schema even if a duplicate is merged.
4. **Encoding.** Files are UTF-8 without BOM, LF line endings. Non-ASCII text
   (« » — ñ á) is data and must round-trip byte-exact (A5; GDD 18 edge case
   "tipografía no ASCII se conserva").
5. **Normalised output.** `DataResult.value` is a tree of `Dictionary`/typed
   `Array` where `ID`/`ENUM` values are `StringName`, `INT` are `int`,
   `FLOAT` are `float`, optional keys absent from the file are filled with the
   schema default or omitted (per field), and the root `schema_version` is
   removed. Owners build their own typed records from it once; the raw parse
   tree is discarded.
6. **Read-only.** Normalised data handed to a system **must** be treated as
   immutable; `ContentDB` and other catalog owners call `make_read_only()` on
   the dictionaries and arrays they keep (`Dictionary.make_read_only()` /
   `Array.make_read_only()`: **NOT SOURCEABLE — not covered by
   `docs/engine-reference/godot/`**, case A11; if absent or partial, the rule
   stays and is enforced by review and by not exposing the containers).

### D6. `ContentDB` (18): load once, immutable snapshot, own language layer

1. **Lifecycle.** `ContentDB` (autoload #1, `ContentDBAutoload`, ADR-0009)
   follows GDD 18's states `UNLOADED → LOADING → READY | ERROR`. `setup(ctx)`
   is the only loader: reads the 10 narrative files once through
   `ctx.files`, normalises them, runs `ContentRules` ‡ (duplicates across
   files, names table complete with the 4 markers, unknown markers, group
   members exist, closed set of 8 `PISTA_*`), and on success publishes one
   `ContentSnapshot` ‡ and enters `READY`. Any `ERROR` → `ERROR` state +
   `ctx.fatal.raise_fatal(&"CONTENIDO_INVALIDO", {file, json_path, rule})`;
   the game is not entered (TR-content-011).
2. **Snapshot.** `ContentSnapshot` is a `RefCounted` holding, per type, a
   `Dictionary[StringName, Record]` of **active** records, the set of
   **retired** IDs, the names table, the groups, the mail order and the
   active language. It is never mutated after construction.
3. **Read path.** A read looks up the record (O(1)), picks the language
   (D7), substitutes the 4 name markers and returns the rendered text.
   Rendered strings are **memoised per `(id, lang)`** inside the snapshot (the
   names table cannot change at runtime, so the cache never goes stale; a new
   snapshot starts with an empty cache). No file I/O after `READY` (AC-21,
   observed by `MemoryFileStore.read_count`).
4. **Not found.** Unknown or retired ID → returns the emergency text «…»
   (GDD 18 rule 21) with `found == false` and one log line per ID per
   snapshot (deduplicated). In debug, a request in `UNLOADED`/`LOADING` is
   `push_error` + `assert` (visible error); in release, «…» + log (AC-E1).
5. **Duplicates.** A duplicate ID across files is an `ERROR` in tier L
   (debug: stop) and in tier C; in release the **first loaded** wins and is
   logged (TR-content-015). Load order = the fixed order of § D2.3's table.
6. **No state, no writes.** `ContentDB` exposes no write method, receives no
   `GameState`, and never builds a variant ID from game state: consumers
   build it with `variant_id(prefix, suffix)` from the value they read
   (TR-content-004/-012).
7. **Hot reload (debug only).** `dev_reload() -> bool` exists only when
   `BuildFlavor.is_debug()`; it builds a candidate snapshot on the side with
   the same pipeline, and on success swaps the reference in one assignment
   (atomic from GDScript's single-threaded point of view; no request sees
   `LOADING`); on failure keeps the old snapshot, logs every issue and shows
   the error through `ctx.logger` (TR-content-012, AC-E6). Consumers that
   cached a rendered string keep it; their next read of a removed ID is «no
   encontrado» (AC-E3). Trigger: a debug-only input action ‡ owned by ADR-0006;
   the release export compiles the method but `is_debug()` is false and it
   returns `false` without reading files (the demo "no la tiene", AC-21).
8. **`ContentDB` does not validate other systems' files.** It answers
   `has_key(id)`, `key_kind(id)` and `group_suffixes(prefix)` so 9, 17, 19,
   22 and `DataValidator` can check references; the checks belong to them.

### D7. Language layer: own layer, not the engine's `tr()`

1. Every text field is a `LANG_TEXT` map `{ "<lang>": "<text>" }`; the slice
   ships `es` only, and `es` is **required** in every map (schema error
   otherwise). Adding a language = adding a key per map; no code change
   (GDD 18 rule 7, D-10).
2. `ContentSnapshot.lang` is fixed at `setup` from `Settings` ‡ (ADR-0007) or
   `&"es"`; it does not change during a run (GDD 18 § States).
3. Lookup: `text[lang]` → else `text["es"]` + log once per `(id, lang)` →
   else «no encontrado» (TR-content-005, AC-07).
4. The engine's `tr()`/`TranslationServer` **must not** be used for player
   text, and no `Translation` resource is registered in the project, so any
   accidental `tr(key)` returns the key unchanged and the literal scan
   (D8) flags it. Reasons: GDD 18 needs segments, document fragments, name
   markers, variant groups, a logged `es` fallback and a §12 verifier that all
   operate on the same records; `tr()` maps a flat key to a flat string and
   its 4.7 fallback/auto-translate behaviour is NOT SOURCEABLE (A8).
5. UI nodes receive already-rendered strings from their system (24, 25, 26,
   27 through `ContentDB`); they never hold a key in their `text` property in
   a `.tscn`. Control auto-translation is therefore irrelevant; A8 records
   whether 4.7 auto-translates a `Label.text` that happens to equal a key
   (it cannot, with no `Translation` registered — to confirm).
6. The `{accion:<id>}` token (TR-content-017) is **not** a language-layer
   marker: `ContentDB` leaves it intact; 24 substitutes it with
   `get_binding_label` (ADR-0016). The verifier accepts `{accion:<id>}` in
   `UI_*` texts only and checks `<id>` against `input/default_bindings.json`.

### D8. Verifier in `tools/` (TR-content-013/-014, -006; GDD 18 OQ 1 and 5)

1. **Location and run.** `tools/data_check/data_check.gd` ‡, a `SceneTree`
   script, run headless from the repo root:
   `godot --headless --path . -s res://tools/data_check/data_check.gd -- [--hito=calidad] [--only=<domain>]`.
   It **must not** name any autoload (`current-best-practices.md`
   § Command Line: autoload names break script-mode checks); it constructs
   `RealFileStore`, `StdoutLog`, `DataValidator`, `ContentVerifier` and
   `LiteralScanner` itself.
2. **Exit codes.** `0` = no `ERROR` (warnings allowed); `1` = at least one
   `ERROR`; `2` = the tool itself failed (bad arguments, unreadable slice
   file, internal assert). Output: one line per issue,
   `SEVERITY file json_path rule: message`, then a summary line. Closes GDD
   18 OQ 1 with its proposed codes.
3. **What it runs.** (a) The tier-B sweep over every `DataCatalog` entry
   with the `RefIndex` pass. (b) `ContentVerifier`: every GDD 18 rule-16
   check — duplicate IDs, references exist and are not retired, audible lines
   have text, groups complete, markers known and no literal current name or
   initial (from `names.json`) inside any text, exactly the 8 `PISTA_*`,
   `SUB_<EVENTO>` format (`^SUB_[A-Z0-9_]+$`), `pending` on provisional
   entries (warning; error with `--hito=calidad`), missing audio (warning;
   error with `--hito=calidad`); and the §12 comparison: parse the §12 table
   of `design/slice/slice-v0.3.md` (path from `tools/data_check/config.json`
   ‡, so a v0.4 slice is a config change), and for each record with
   `source: "slice_§12"` compare segment by segment (`[pausa]` splits
   segments), fragments joined with one space, markers substituted, whitespace
   and line breaks normalised; fail if the row is missing or the text
   differs, naming the ID (AC-15, AC-16). (c) `LiteralScanner` (D8.4).
4. **Literal scan (closes GDD 18 OQ 5).** A "visible literal" is a non-empty
   string literal that is (a) assigned to `text`, `placeholder_text`,
   `tooltip_text` or `title` of a node in a `.tscn` (`text = "…"` lines of
   a node whose type is a `Control` subclass), or (b) passed in a `.gd` file
   to a property assignment `.text =`, `.tooltip_text =`, or to
   `set_text(`, `add_item(` or any other display call listed in
   `tools/data_check/literal_scan.json` ‡. Arguments of `push_error`,
   `push_warning`, `print*` and `LogSink` calls never count. Empty strings, numbers, strings
   containing only punctuation or whitespace, and literals in `src/core/composition/fatal_messages.gd`
   (ADR-0009 D8) and in `tools/`/`tests/` are excluded. The exception list
   lives in `tools/data_check/literal_exceptions.json` ‡ and contains,
   for player text, only the two emergency texts of GDD 18 rule 21 («…» and
   the load-failure message).
5. **CI wiring.** The CI job runs, in order: `--import` (fresh clone,
   `current-best-practices.md`), the parse check, `data_check.gd`, then the
   gdUnit4 suite. The export job runs `data_check.gd --hito=calidad` only
   when building the funding demo ‡ (the quality milestone); ordinary pushes
   run it without the flag.

### D9. Stable-ID policy

1. **Case-sensitive, verbatim.** IDs from the slice and the GDDs are kept
   exactly (`VO_G_12A`, `I-06a`, `caja_c1`, `D01a`). After loading they are
   `StringName`; comparisons are exact. No normalisation of case, ever.
2. **Never reuse, never rename.** An ID, once merged to `main` in a data
   file, **must never** be deleted or given to another record. Retiring sets
   `"status": "retired"` in place (D2.3); renaming = retire the old + add the
   new + update every reference in the same commit (GDD 18 rule 4). This
   applies to every catalog (facts, items, puzzles, sounds, scenes), not only
   to 18. Facts are also bound by ADR-0001's snapshot contract.
3. **Retired = not found.** At runtime a retired ID behaves exactly as an
   unknown one (AC-04). In tiers B/C, a reference to a retired ID is an
   `ERROR`.
4. **Patterns.** Each `ID` field declares its pattern in the schema; the
   content prefixes are those of GDD 18 rule 3 (`VO_`, `MEGA_`, `DOC_`,
   `NOTA_`, `CARTA_`, `MAIL_`, `T1`–`T4`, `PISTA_P<n>_N<k>`, `UI_`, `OBJ_`,
   `SUB_`); `key_kind(id)` derives the type from the prefix, so a `TEXT`
   hint effect can be checked to be `PISTA_*` (TR-content-016) and
   `message_key` to be not `PISTA_*` (GDD 9 rule 4b).
5. **Git is the ID ledger.** The verifier compares the set of IDs on the
   branch against `git show origin/main:<file>` ‡ when run in CI with
   `--against=<ref>` ‡: an ID present on `main` and absent on the branch is an
   `ERROR` ("deleted instead of retired"). Without `--against`, the check is
   skipped (local runs).

### D10. Ownership of the pieces

| Piece | Path ‡ | Layer (ADR-0009) | Owner story |
|---|---|---|---|
| `DataSchema`, `FieldSpec`, `DataReader`, `JsonText`, `DataIssue`, `DataResult`, `RefIndex`, `DataCatalog`, `BuildFlavor` | `src/core/data/` | 0 Platform | S0 "data pipeline" |
| `DataValidator` | `src/core/data/data_validator.gd` | 0 Platform (created by `Boot`, ADR-0009 D1) | S0 "data pipeline" |
| `ContentDB`, `ContentSnapshot`, `ContentRules`, narrative schemas | `src/narrative/` | 1 Foundation | Epic 18 |
| Per-file schema + `FileRules` | `src/<area>/data/` of the owner | owner's layer | each owner's first story |
| `data_check.gd`, `ContentVerifier`, `LiteralScanner`, config and exception lists | `tools/data_check/` | tooling | S0 "CI data gate" |

### Architecture Diagram

```text
 assets/data/<domain>/<file>.json          design/slice/slice-v0.3.md §12
            │  (UTF-8 text)                              │ (CI only)
            ▼                                            │
   FileStore (ADR-0009)  ── tests: MemoryFileStore       │
            │                                            │
            ▼                                            │
   JsonText.parse ──► raw Variant tree                   │
            │                                            │
            ▼                                            │
   DataReader.normalise(schema)  ── to_int / ENUM→StringName / unknown keys
            │   + FileRules (per file)                   │
            ▼                                            │
   DataResult {value (normalised, read-only), issues[]}  │
      │                     │                            │
      │ tier L (all builds) │ tier B (debug) / C (CI)    │
      ▼                     ▼                            ▼
  owner system         DataValidator.sweep ─► RefIndex ─► ContentVerifier
  (ContentDB, GameState,   (all DataCatalog entries,      LiteralScanner
   PuzzleFramework …)       cross-file refs)                    │
      │                     │                                   ▼
      │ release policy      │ debug: push_error ×N,      data_check.gd
      │ (D1 registry)       │ then ctx.fatal once        exit 0 / 1 / 2
      ▼                     ▼
  FatalErrorHandler · scene-load failure of 4 · record drop · clamp+warning

 ContentDB (18) after READY:
   get_text(id) ─► ContentSnapshot.records[id] ─► LANG_TEXT[lang] → [es] → «…»
                    └─► NameMarkers.substitute ─► memo[(id, lang)] ─► String
```

### Key Interfaces

Signatures are **proposed** (‡ for every name this ADR introduces). Typed
GDScript; bodies are reference pseudocode. Doc comments on public API are
mandatory per `.claude/docs/coding-standards.md`.

```gdscript
# ─── src/core/data/data_issue.gd ─────────────────────────────────────────
## One finding of the pipeline. Never thrown: always collected.
class_name DataIssue extends RefCounted

enum Severity { WARNING, ERROR }

var severity: Severity
var file: String          # "puzzles/puzzles.json" (relative to assets/data/)
var json_path: String     # "puzzles[2].on_solved.write[0].value_from"
var rule: StringName      # &"type", &"range", &"unknown_key", &"ref", &"dup_id", …
var message: String       # English, developer-facing (log only, never shown to the player)
var tags: PackedStringArray = PackedStringArray()   # e.g. ["quality"] → promoted by --hito=calidad

func _init(p_sev: Severity, p_file: String, p_path: String,
		p_rule: StringName, p_msg: String) -> void:
	severity = p_sev; file = p_file; json_path = p_path; rule = p_rule; message = p_msg

## "ERROR puzzles/puzzles.json puzzles[2].id dup_id: duplicate id P3"
func format() -> String:
	return "%s %s %s %s: %s" % [Severity.keys()[severity], file, json_path, rule, message]
```

```gdscript
# ─── src/core/data/data_result.gd ────────────────────────────────────────
## Normalised value of one file plus every issue found reading it.
class_name DataResult extends RefCounted

var value: Variant = null                     # null when the file could not be parsed
var issues: Array[DataIssue] = []

func has_errors() -> bool:
	for i in issues:
		if i.severity == DataIssue.Severity.ERROR:
			return true
	return false

func first_error() -> DataIssue:
	for i in issues:
		if i.severity == DataIssue.Severity.ERROR:
			return i
	return null
```

```gdscript
# ─── src/core/data/json_text.gd ──────────────────────────────────────────
## Thin wrapper over the engine parser. The ONLY place that touches JSON.
## Every engine behaviour used here is NOT SOURCEABLE until S-0005-A (A1–A5).
class_name JsonText extends RefCounted

## Returns the raw tree or null, appending a parse issue with line and message.
static func parse(text: String, file: String, issues: Array[DataIssue]) -> Variant:
	if text.begins_with("﻿"):                       # D5.4: BOM forbidden (A5)
		issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, "$", &"bom",
				"UTF-8 BOM is not allowed"))
		text = text.substr(1)
	var json := JSON.new()
	var err: Error = json.parse(text)                    # A2: instance API, not parse_string
	if err != OK:
		issues.append(DataIssue.new(DataIssue.Severity.ERROR, file,
				"line %d" % json.get_error_line(), &"parse", json.get_error_message()))
		return null
	return json.get_data()
```

```gdscript
# ─── src/core/data/field_spec.gd ─────────────────────────────────────────
## Node of a schema tree. Built only through the DataSchema static helpers.
class_name FieldSpec extends RefCounted

enum Kind { BOOL, INT, FLOAT, STRING, ID, ENUM, NULLABLE, ARRAY, OBJECT, MAP, ONE_OF, LANG_TEXT }
enum OutOfRange { ERROR, CLAMP }                     # CLAMP only where D1 says so (box.json)

var kind: Kind
var min_value: float = -INF
var max_value: float = INF
var out_of_range: OutOfRange = OutOfRange.ERROR
var pattern: RegEx = null                            # ID
var allowed: Array[StringName] = []                  # ENUM
var item: FieldSpec = null                           # ARRAY / MAP / NULLABLE element
var min_len: int = 0
var max_len: int = -1
var unique_by: StringName = &""                      # ARRAY of OBJECT: key that must be unique
var required: Dictionary = {}                        # OBJECT: String -> FieldSpec
var optional: Dictionary = {}                        # OBJECT: String -> FieldSpec
var open_with_warning: bool = false                  # OBJECT: unknown keys → WARNING
var discriminator: String = ""                       # ONE_OF
var variants: Dictionary = {}                        # ONE_OF: String -> FieldSpec
var ref_kind: StringName = &""                       # cross-file reference, resolved in tier B/C
var record_isolated: bool = false                    # ARRAY: a failing element is dropped in release
var tags: PackedStringArray = PackedStringArray()
```

```gdscript
# ─── src/core/data/data_schema.gd ────────────────────────────────────────
## Base of every per-file schema. Subclasses implement root() and may add rules().
@abstract class_name DataSchema extends RefCounted

## Highest schema_version this code accepts. puzzles.json = 2, others = 1.
@abstract func version() -> int
## Tree for the root object (schema_version is checked and stripped by DataReader).
@abstract func root() -> FieldSpec
## Optional semantic checks after normalisation. Default: none.
func rules() -> FileRules:
	return null

# --- builders (static, return new FieldSpec) -------------------------------
static func int_(lo: int, hi: int) -> FieldSpec:
	var f := FieldSpec.new(); f.kind = FieldSpec.Kind.INT
	f.min_value = lo; f.max_value = hi
	return f

static func float_(lo: float, hi: float) -> FieldSpec:
	var f := FieldSpec.new(); f.kind = FieldSpec.Kind.FLOAT
	f.min_value = lo; f.max_value = hi
	return f

static func id_(regex: String, ref: StringName = &"") -> FieldSpec:
	var f := FieldSpec.new(); f.kind = FieldSpec.Kind.ID
	f.pattern = RegEx.create_from_string(regex)    # 4.4 added optional show_error (breaking-changes.md)
	f.ref_kind = ref
	return f

static func enum_(values: Array[StringName]) -> FieldSpec:
	var f := FieldSpec.new(); f.kind = FieldSpec.Kind.ENUM; f.allowed = values
	return f

static func array_(of: FieldSpec, lo: int = 0, unique_key: StringName = &"") -> FieldSpec:
	var f := FieldSpec.new(); f.kind = FieldSpec.Kind.ARRAY
	f.item = of; f.min_len = lo; f.unique_by = unique_key
	return f

static func object_(req: Dictionary, opt: Dictionary = {}) -> FieldSpec:
	var f := FieldSpec.new(); f.kind = FieldSpec.Kind.OBJECT
	f.required = req; f.optional = opt
	return f

static func nullable(of: FieldSpec) -> FieldSpec:
	var f := FieldSpec.new(); f.kind = FieldSpec.Kind.NULLABLE; f.item = of
	return f

static func lang_text() -> FieldSpec:
	var f := FieldSpec.new(); f.kind = FieldSpec.Kind.LANG_TEXT   # {"es": non-empty, …}
	return f
# bool_(), string_(), map_(), one_of_() follow the same shape.
```

```gdscript
# ─── src/core/data/data_reader.gd ────────────────────────────────────────
## Reads one registered file and normalises it against its schema.
## Stateless apart from injected collaborators; the same code serves tiers L, B, C.
class_name DataReader extends RefCounted

const MAX_SAFE_INT: float = 9007199254740992.0     # 2^53

var _files: FileStore
var _flavor: BuildFlavor

func _init(files: FileStore, flavor: BuildFlavor) -> void:
	_files = files; _flavor = flavor

## Parse + schema + FileRules. Never raises; the caller applies the release policy.
func read_file(entry: DataCatalog.Entry) -> DataResult:
	var r := DataResult.new()
	var path := "res://assets/data/" + entry.rel_path
	if not _files.exists(path):
		r.issues.append(DataIssue.new(DataIssue.Severity.ERROR, entry.rel_path, "$",
				&"missing", "file not found"))
		return r
	var raw: Variant = JsonText.parse(_files.read_text(path), entry.rel_path, r.issues)
	if raw == null:
		return r
	if typeof(raw) != TYPE_DICTIONARY:
		r.issues.append(DataIssue.new(DataIssue.Severity.ERROR, entry.rel_path, "$",
				&"root", "root must be an object"))
		return r
	var root: Dictionary = raw
	var v: Variant = root.get("schema_version")
	var ver := to_int(v, entry.rel_path, "schema_version", r.issues)
	if ver != entry.schema.version():
		r.issues.append(DataIssue.new(DataIssue.Severity.ERROR, entry.rel_path,
				"schema_version", &"version", "expected %d" % entry.schema.version()))
		return r
	root.erase("schema_version")
	r.value = normalise(root, entry.schema.root(), entry.rel_path, "$", r.issues)
	var extra := entry.schema.rules()
	if extra != null and not r.has_errors():
		extra.check(r.value, entry.rel_path, r.issues)
	return r

## D4.1 — the only sanctioned int conversion in the project.
static func to_int(v: Variant, file: String, path: String, issues: Array[DataIssue]) -> int:
	match typeof(v):
		TYPE_INT:
			return v
		TYPE_FLOAT:
			var f: float = v
			if is_finite(f) and absf(f) <= MAX_SAFE_INT and f == floorf(f):
				return int(f)                         # exact: integral and in safe range
	issues.append(DataIssue.new(DataIssue.Severity.ERROR, file, path, &"type",
			"expected integer, got %s" % type_string(typeof(v))))
	return 0

## Recursive walk. Returns the normalised value (StringName ids/enums, int, float,
## typed arrays where the element kind allows it). Sketch of the main branches:
func normalise(v: Variant, spec: FieldSpec, file: String, path: String,
		issues: Array[DataIssue]) -> Variant:
	match spec.kind:
		FieldSpec.Kind.INT:
			var n := to_int(v, file, path, issues)
			return _range_int(n, spec, file, path, issues)
		FieldSpec.Kind.FLOAT:
			if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
				issues.append(_err(file, path, &"type", "expected number")); return 0.0
			return _range_float(float(v), spec, file, path, issues)
		FieldSpec.Kind.ENUM:
			var s := StringName(str(v)) if typeof(v) == TYPE_STRING else &""
			if s == &"" or not spec.allowed.has(s):
				issues.append(_err(file, path, &"enum", "not in %s" % [spec.allowed]))
			return s
		FieldSpec.Kind.OBJECT:
			return _normalise_object(v, spec, file, path, issues)   # required / optional / unknown keys
		FieldSpec.Kind.ARRAY:
			return _normalise_array(v, spec, file, path, issues)    # min_len, unique_by, record isolation
		_:
			return _normalise_other(v, spec, file, path, issues)    # BOOL, STRING, ID, NULLABLE, MAP, ONE_OF, LANG_TEXT

func _range_int(n: int, spec: FieldSpec, file: String, path: String,
		issues: Array[DataIssue]) -> int:
	if n >= spec.min_value and n <= spec.max_value:
		return n
	if spec.out_of_range == FieldSpec.OutOfRange.CLAMP and not _flavor.is_debug():
		issues.append(DataIssue.new(DataIssue.Severity.WARNING, file, path, &"clamped",
				"%d clamped to [%d, %d]" % [n, spec.min_value, spec.max_value]))
		return clampi(n, int(spec.min_value), int(spec.max_value))
	issues.append(_err(file, path, &"range", "%d outside [%d, %d]" % [n, spec.min_value, spec.max_value]))
	return n
# _range_float mirrors _range_int; _err builds an ERROR DataIssue.
```

```gdscript
# ─── src/core/data/data_catalog.gd ───────────────────────────────────────
## Mirror of the D1 registry. The only list of loadable files.
class_name DataCatalog extends RefCounted

enum LoadPoint { BOOT, SCENE }
enum ReleasePolicy { FATAL, SCENE_LOAD_FAILURE, DROP_RECORD, CLAMP_WARN }

class Entry extends RefCounted:
	var rel_path: String               # "puzzles/puzzles.json"
	var owner: int                     # GDD system number
	var schema: DataSchema
	var load_point: LoadPoint
	var policy: ReleasePolicy
	var fatal_code: StringName         # &"CATALOGO_INVALIDO" | &"DATOS_ESCENA_INVALIDOS" | &"CONTENIDO_INVALIDO"

## All entries, in the fixed order used by tier B/C and by ContentDB (§ D2.3 order).
static func entries() -> Array[Entry]:
	return []                          # filled by the data-pipeline story, one line per registry row
```

```gdscript
# ─── src/core/data/ref_index.gd ──────────────────────────────────────────
## Cross-file reference index built by DataValidator from normalised results.
class_name RefIndex extends RefCounted

var _sets: Dictionary = {}            # StringName kind -> Dictionary[StringName, bool]
var _fact_values: Dictionary = {}     # StringName fact -> Array[StringName] (enum values)
var _retired: Dictionary = {}         # StringName id -> true

func add(kind: StringName, id: StringName) -> void: pass
func add_retired(id: StringName) -> void: pass
func has(kind: StringName, id: StringName) -> bool: return false
func is_retired(id: StringName) -> bool: return false
func fact_accepts(fact: StringName, value: StringName) -> bool: return false
```

```gdscript
# ─── src/core/data/data_validator.gd ─────────────────────────────────────
## Tier B (boot, debug) and tier C (CI) sweep. Created by Boot (ADR-0009 D1).
class_name DataValidator extends RefCounted

var _reader: DataReader
var _log: LogSink

func _init(reader: DataReader, log_sink: LogSink) -> void:
	_reader = reader; _log = log_sink

## Reads every catalog entry, builds the RefIndex, resolves every ref().
## Returns all issues; never stops early (D3.3).
func sweep(entries: Array[DataCatalog.Entry]) -> Array[DataIssue]:
	var all: Array[DataIssue] = []
	var results: Dictionary = {}                       # rel_path -> DataResult
	for e in entries:
		var r := _reader.read_file(e)
		results[e.rel_path] = r
		all.append_array(r.issues)
	var index := RefIndexBuilder.build(results)         # facts, enum values, content keys, items, …
	for e in entries:
		var r: DataResult = results[e.rel_path]
		if r.value != null:
			RefChecker.check(r.value, e.schema.root(), index, e.rel_path, "$", all)
	return all

## Boot step 4 entry point. Debug only: Boot does not call it in release.
func run(ctx: ServiceContext) -> void:
	var issues := sweep(DataCatalog.entries())
	var errors := 0
	for i in issues:
		if i.severity == DataIssue.Severity.ERROR:
			errors += 1
			_log.line(&"error", i.format())    # LogSink API of ADR-0001
		else:
			_log.line(&"warn", i.format())
	if errors > 0:
		var first: DataIssue = issues.filter(func(x: DataIssue) -> bool:
				return x.severity == DataIssue.Severity.ERROR)[0]
		ctx.fatal.raise_fatal(&"CATALOGO_INVALIDO",
				{"count": errors, "file": first.file, "param": first.json_path, "rule": first.rule})
```

```gdscript
# ─── src/narrative/content_db.gd ─────────────────────────────────────────
## System 18. Read-only catalog of everything the player reads or hears.
## Registered as ContentDBAutoload (ADR-0009 D1); named only by Boot.
class_name ContentDB extends Node

enum Status { UNLOADED, LOADING, READY, ERROR }
const NOT_FOUND_TEXT: String = "…"                   # GDD 18 rule 21 emergency text (literal exception)

var _status: Status = Status.UNLOADED
var _snapshot: ContentSnapshot = null
var _reader: DataReader
var _log: LogSink
var _fatal: FatalErrorHandler
var _flavor: BuildFlavor

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS             # ADR-0009 D2 / ADR-0002 table

## Boot step 1. Reads the 10 narrative files once. Error → CONTENIDO_INVALIDO.
func setup(ctx: ServiceContext) -> void:
	_reader = DataReader.new(ctx.files, ctx.flavor)
	_log = ctx.logger; _fatal = ctx.fatal; _flavor = ctx.flavor
	_status = Status.LOADING
	var built := ContentSnapshotBuilder.build(_reader, NarrativeFiles.entries(), _lang_from(ctx))
	if built.has_errors():
		_status = Status.ERROR
		var e := built.first_error()
		_fatal.raise_fatal(&"CONTENIDO_INVALIDO", {"file": e.file, "param": e.json_path, "rule": e.rule})
		return
	_snapshot = built.snapshot
	_status = Status.READY

func get_status() -> Status:
	return _status

## Plain text of UI_*, OBJ_*, PISTA_*, SUB_* (and of a line/document joined). «…» if not found.
func get_text(id: StringName) -> String:
	if not _ready_or_report(id):
		return NOT_FOUND_TEXT
	return _snapshot.render(id)

## A line with its segments rendered; found == false if unknown or retired.
func get_line(id: StringName) -> ContentLine: return null        # {found, speaker, scene, segments[{text, pause_before_s}], audio}
## ADR-0008 OI-9: 23's `LineTextSource` is an adapter over get_line() only —
## has_line = found; char_count / pause_count from segments; audio_path = audio.
func get_document(id: StringName) -> ContentDocument: return null  # {found, style, item, fragments[{id, text}]}
func get_fragment(doc_id: StringName, fragment_id: StringName) -> String: return NOT_FOUND_TEXT
func get_mail(id: StringName) -> ContentMail: return null        # {found, ref, sender, subject, body, day, sent_min, tags}
func get_mail_order() -> Array[StringName]: return []             # presentation order (TR-content-009)
func get_task(id: StringName) -> ContentTask: return null

## Variant groups (TR-content-004). Consumers pass the suffix they read from GameState.
func variant_id(prefix: StringName, suffix: String) -> StringName: return &""   # &"" if not a member
func group_suffixes(prefix: StringName) -> PackedStringArray: return PackedStringArray()

## For validators (9, 17, 19, 22, DataValidator). Retired → false.
func has_key(id: StringName) -> bool: return false
func key_kind(id: StringName) -> StringName: return &""          # &"line" | &"document" | &"hint" | &"ui" | …
func get_language() -> StringName: return _snapshot.lang if _snapshot != null else &"es"

## Debug only (D6.7). Atomic swap; returns false and keeps the old snapshot on any error.
func dev_reload() -> bool:
	if not _flavor.is_debug() or _status != Status.READY:
		return false
	var built := ContentSnapshotBuilder.build(_reader, NarrativeFiles.entries(), _snapshot.lang)
	if built.has_errors():
		for i in built.issues:
			_log.line(&"error", i.format())
		return false
	_snapshot = built.snapshot                            # single assignment: no LOADING window
	return true

func _ready_or_report(id: StringName) -> bool:
	if _status == Status.READY:
		return true
	if _flavor.is_debug():
		push_error("ContentDB: '%s' requested in status %s" % [id, Status.keys()[_status]])
		assert(false, "content requested before READY")
	else:
		_log.line(&"warn", "ContentDB: '%s' requested before READY" % id)
	return false
```

```gdscript
# ─── src/narrative/content_snapshot.gd (read path only) ──────────────────
## Immutable result of one successful load. Memoises rendered text per (id, lang).
class_name ContentSnapshot extends RefCounted

var lang: StringName = &"es"
var _texts: Dictionary = {}           # StringName id -> Dictionary lang->String (simple records)
var _retired: Dictionary = {}         # StringName id -> true
var _names: Dictionary = {}           # "{vera}" -> "Vera", "{vera_inicial}" -> "V", …
var _memo: Dictionary = {}            # StringName id -> String (for `lang`)
var _logged_missing: Dictionary = {}  # dedup of not-found / fallback logs
var _log: LogSink

func render(id: StringName) -> String:
	if _memo.has(id):
		return _memo[id]
	if _retired.has(id) or not _texts.has(id):
		_log_once(id, "not found")
		return ContentDB.NOT_FOUND_TEXT
	var by_lang: Dictionary = _texts[id]
	var raw: String
	if by_lang.has(lang):
		raw = by_lang[lang]
	else:
		raw = by_lang["es"]                              # schema guarantees "es"
		_log_once(id, "fallback to es from %s" % lang)
	var out := _substitute(raw)
	_memo[id] = out
	return out

func _substitute(s: String) -> String:
	for marker: String in _names:                        # exactly 4, validated at load
		s = s.replace(marker, _names[marker])
	return s                                             # {accion:<id>} left for 24 (D7.6)
```

```gdscript
# ─── src/core/data/build_flavor.gd ───────────────────────────────────────
## Injected so tests can run "release" behaviour in the editor. A9: is_debug_build NOT SOURCEABLE.
class_name BuildFlavor extends RefCounted
var _debug: bool
func _init(debug: bool) -> void: _debug = debug
func is_debug() -> bool: return _debug
## Boot: BuildFlavor.new(OS.is_debug_build()). Tests: BuildFlavor.new(false) for release paths.
```

`ServiceContext` (ADR-0009 D3) gains one platform field, `flavor:
BuildFlavor`, set by `Boot` in step 0 next to `files`, `logger` and `fatal`.
This is an **amendment request** to ADR-0009 (§ Open Items O2), not a change
of its rules.

### Implementation Guidelines

- **G-1** Game data **must** be read only through `DataReader.read_file()`;
  `FileAccess` and `JSON` **must never** appear in system code outside
  `JsonText`, `RealFileStore` and the save/settings writers of ADR-0004/0007.
- **G-2** Every data file **must** have a `DataCatalog` entry and a schema
  before its first loader merges; a file without one **must not** be read.
- **G-3** Paths **must** follow D1 (`assets/data/<domain>/<snake_case>.json`,
  one level, no root files); CI-only fixtures **must** live in
  `tests/fixtures/<domain>/`.
- **G-4** Every file **must** start with an integer `schema_version`; a
  loader **must** reject any version it does not implement.
- **G-5** Integers **must** be converted only by `DataReader.to_int()`;
  `int(x)`, `x as int` and `floori(x)` on parsed data **must never** be used.
- **G-6** Collections keyed by open ID sets **must** be arrays of records
  with `id`, never JSON objects keyed by ID (D5.3).
- **G-7** Unknown keys **must** be errors unless the schema declares the
  object `open_with_warning`; adding a field means updating the schema in the
  same commit.
- **G-8** A loader **must** apply its registry release policy and nothing
  else; a softer policy (drop, clamp) requires a registry row change in this
  ADR.
- **G-9** Player-visible text **must** come from `ContentDB`; `tr()`,
  `TranslationServer` and `Translation` resources **must never** be used for
  it. The only literals allowed are those in the literal-exception list.
- **G-10** `ContentDB` **must** read files only in `setup()` and
  `dev_reload()`; any read after `READY` is a defect (AC-21 test).
- **G-11** Consumers **must** build variant IDs with
  `ContentDB.variant_id(prefix, suffix)`; string concatenation of IDs in
  system code **must never** be used (keeps group membership checked).
- **G-12** IDs **must never** be deleted or reused once on `main`; retire in
  place with `"status": "retired"` (D9).
- **G-13** Validators **must** collect all issues and report each with file
  and `json_path`; the single fatal call carries the first error's parameter
  (TR-settings-019 "con el parámetro").
- **G-14** The export presets **must** include `assets/data/*` (S-0005-A
  case A7 decides whether this needs an explicit "non-resource files" filter
  ‡) and **must** exclude `tests/`, `tools/` and `prototypes/`.
- **G-15** `tools/data_check/data_check.gd` **must not** name any autoload
  and **must** exit through `quit(code)` with 0/1/2 as in D8.2.
- **G-16** Data files **must** be UTF-8 without BOM, LF, strict JSON (no
  comments, no trailing commas).

## Alternatives Considered

### Alternative 1: Godot `Resource` files (`.tres`) instead of JSON

- **Description**: each catalog is a custom `Resource` with `@export` typed
  fields, edited in the inspector and loaded with `load()`.
- **Pros**: typed fields (no `int`/`float` ambiguity), inspector editing,
  resource import guarantees export inclusion.
- **Cons**: every GDD, the verifier against the slice and the plan already
  assume JSON (`puzzles.json` v2 is specified as JSON); `.tres` diffs are
  noisy and hostile to text review; the CI verifier would need the resource
  loader and class cache; resource loading on 4.7 is NOT SOURCEABLE
  (ADR-0003 § Engine API sourcing) — it moves the risk, it does not remove
  it; nested optional structures (`ONE_OF`, nullable `on_reject`) map poorly
  to `@export`.
- **Estimated Effort**: higher (one `Resource` class per record type plus
  inspector tooling) and a GDD-wide format change.
- **Rejection Reason**: contradicts every signed GDD for a type-safety gain
  that D4 gets in one function.

### Alternative 2: JSON Schema files (`*.schema.json`) + a GDScript validator

- **Description**: as GDD 7 proposes for `interactables.schema.json`, write
  standard JSON-Schema documents and validate against them.
- **Pros**: language-neutral, editor tooling (VS Code) gives authors live
  validation.
- **Cons**: Godot ships no JSON-Schema validator; implementing even the
  subset we need (`oneOf`, `$ref`, patterns) is larger than `DataSchema`;
  cross-file references and rule-29 semantics would still be GDScript, so
  there would be two schema languages; JSON-Schema cannot express "integral
  float accepted as int" without a custom keyword.
- **Estimated Effort**: higher (validator + schemas + the GDScript semantic
  layer anyway).
- **Rejection Reason**: two dialects for one job. Retained idea: a
  `tools/data_check/export_schemas.gd` ‡ may later *generate* JSON-Schema
  from `DataSchema` for editor hints only (not a gate).

### Alternative 3: Engine `tr()` + CSV/PO translations for 18

- **Description**: register `Translation` resources, key every text, use
  `tr()` everywhere, including auto-translated `Control.text`.
- **Pros**: standard Godot workflow; translators know PO; free
  auto-translation of UI nodes.
- **Cons**: GDD 18 needs structured records (segments with pauses, document
  fragments, mail fields, variant groups, name markers) and a verifier that
  compares those structures to §12 — a flat key→string table loses the
  structure or forces composite keys (`VO_G_07#1`); `es` fallback with a log
  line, «no encontrado» for retired IDs and memoised marker substitution
  would be reimplemented around `tr()` anyway; 4.7 fallback and
  auto-translation behaviour is NOT SOURCEABLE.
- **Estimated Effort**: similar to build, higher to verify.
- **Rejection Reason**: the slice ships one language; the own layer is
  smaller, fully testable with a `MemoryFileStore`, and a future
  `tools/` exporter ‡ can emit PO files from `LANG_TEXT` maps if a translator
  needs them. Revisit if more than two languages are funded.

### Alternative 4: Validate everything at boot in release too

- **Description**: run tier B in every build, failing at boot for any file.
- **Pros**: one behaviour; errors surface on the title, not mid-load.
- **Cons**: contradicts GDD 9 R29 and TR-scene-011 (release behaviour =
  scene-load failure of 4, back to title) and TR-director-004 / TR-box-008
  (drop / clamp); adds boot time in release for a check CI already made
  mandatory.
- **Estimated Effort**: lower.
- **Rejection Reason**: QQ-14's recommended resolution (`architecture.md`)
  is "ambos, el de arranque solo en debug/CI", which this ADR implements;
  CI makes the release-boot check redundant.

### Alternative 5: Per-language files (`narrative/es/*.json`) instead of inline maps

- **Description**: structural records in one tree, texts in
  `narrative/<lang>/<file>.json` keyed by ID.
- **Pros**: a translator gets one file per language; diffs per language.
- **Cons**: "un dato, un registro" (TR-content-009) splits each mail across
  two files; every §12 comparison and duplicate check joins two trees;
  a missing translation key is invisible until runtime.
- **Estimated Effort**: slightly higher.
- **Rejection Reason**: with one language, inline maps are simpler and the
  loader hides the layout; switching later is a data migration plus one
  loader change (reversible).

### Alternative 6: Rename the data folders to the TR slugs (`content/`, `interact/`, `atmos/`)

- **Pros**: one naming system across TRs, tests and data.
- **Cons**: churn in ~15 GDD paths for no behaviour change.
- **Rejection Reason**: D1 fixes only the four real outliers of QQ-21 plus
  the `scene/`/`scenes/` trap.

## Consequences

### Positive

- One registry answers "where is X and who owns it"; QQ-21 closed.
- `int`/`float` ambiguity is impossible to leak into gameplay code: a
  single function, tested against both parser behaviours.
- Every data error in the repository is caught on push by the same code the
  game runs; release builds keep each GDD's tolerance.
- A developer sees *all* data errors in one boot, with file and JSON path.
- 18 is fully unit-testable without disk and without the engine's
  translation server; hot reload reuses the production pipeline.
- Schemas are code: refactors that rename a field fail tests immediately.

### Negative

- In debug, files are read twice (tier B, then the owner's tier L). Accepted:
  boot-only, small files (§ Performance).
- `DataSchema` is project code to maintain (~400–600 lines ‡ estimate) and
  every file needs a schema before use; authoring a new tunable is one step
  longer.
- Four GDD path edits (5, 17, 21, 7) and two fixture moves (4, 7) are
  required (§ Open Items).
- No inspector editing of data; authors edit JSON by hand (mitigated by the
  CI and by optional generated JSON-Schema hints, Alternative 2).

### Neutral

- Field names stay in the GDDs' language (mixed Spanish/English); only the
  case and ASCII rule is enforced.
- The verifier's §12 parser depends on the slice's Markdown table format; a
  table format change in the slice is a verifier change.

## Risks

| ID | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 | 4.7.2 JSON parser silently merges duplicate object keys | High (assumed) | D5.3: IDs only in arrays; closed-key maps are schema-checked; A3 records the behaviour |
| R2 | The parser accepts non-strict JSON (comments, trailing commas) so authors start relying on it | Medium | G-16; if A4 shows tolerance, `JsonText` adds a cheap pre-check for `//` and `,]`/`,}` outside strings ‡, and CI fails on them |
| R3 | `.json` files under `res://` are not packed by the default export filters | Medium | A7 runs an `--export-debug` and reads every registry file from the `.pck`; G-14 adds the filter if needed; a release smoke test reads `DataCatalog.entries()` |
| R4 | Integers above 2^53 or `-0.0` | Low (no such data in the slice) | `to_int` rejects beyond 2^53; A1 checks `-0` |
| R5 | `DataSchema` grows into a framework | Medium | Scope fixed by D2.2; any new `Kind` requires amending this ADR |
| R6 | Boot time in debug grows with data size | Low | S-0005-A measures a 200 KB parse; tier B can be skipped with a debug-only command-line flag `--skip-data-sweep` ‡ for local iteration (never in CI) |
| R7 | The §12 Markdown table changes format (slice v0.4) | Medium | Table path and column names in `tools/data_check/config.json` ‡; parser has its own unit tests on a fixture copy |
| R8 | `make_read_only()` missing or partial on 4.7 | Low | A11; rule D5.6 holds by review and by never exposing containers |

## GDD Requirements Addressed

TR IDs are from `docs/architecture/tr-baseline-provisional.md` (all
provisional). "Fixed here" = this ADR decides it; "slot" = this ADR fixes
path, root, typing and failure policy and the named ADR fills the fields.

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| base-de-contenido-narrativo.md (18) | **TR-content-001…003**: 8 content types with mandatory non-empty fields under `assets/data/narrative/`; initial slice content counts; stable case-sensitive IDs, never reused, retired = not found | D2.3 (10 files, record keys per type, `STRING` non-empty), D8.3 counts (AC-02), D9 |
| base-de-contenido-narrativo.md (18) | **TR-content-004**: variant groups in data, consumer builds the ID, catalog never reads state | `groups.json` (D2.3), `variant_id()` / `group_suffixes()`, G-11, D6.6 |
| base-de-contenido-narrativo.md (18) | **TR-content-005**: language layer, `es` fallback with log, not found | D7 |
| base-de-contenido-narrativo.md (18) | **TR-content-006**: no player text in scripts/scenes, static literal scan with exception list | D8.4 (definition, exception file), G-9 |
| base-de-contenido-narrativo.md (18) | **TR-content-007**: 4 name markers from a names table; unknown marker invalid; incomplete table → Error | `names.json`, `ContentRules`, `_substitute()`, D8.3 |
| base-de-contenido-narrativo.md (18) | **TR-content-008…010**: segments with optional pause; document fragments; one record per mail with explicit presentation order; `audio` path or null → "sin audio" | D2.3 record shapes; `audio` nullable; missing audio = `quality` warning |
| base-de-contenido-narrativo.md (18) | **TR-content-011…012**: lifecycle, read once, request before READY = dev error / «…»; read-only; atomic dev-only hot reload absent from the demo | D6.1–D6.7, `dev_reload()`, `BuildFlavor` |
| base-de-contenido-narrativo.md (18) | **TR-content-013…014**: verifier in `tools/` with exit 0/≠0 and `--hito=calidad`; comparison against slice §12 | D8.1–D8.3 |
| base-de-contenido-narrativo.md (18) | **TR-content-015**: duplicates across files: dev stops, release first-loaded wins + log; reload removing an ID in use | D6.5, D6.7 |
| base-de-contenido-narrativo.md (18) | **TR-content-016**: `TEXT` hint effect always a `PISTA_*` key; `puzzles.json` load fails otherwise | D2.4 (`PuzzleDataRules`), D9.4 `key_kind()` |
| base-de-contenido-narrativo.md (18) | **TR-content-017**: `{accion:<id>}` token substituted by 24 | D7.6 (left intact by 18; verifier checks `<id>`) |
| marco-de-puzles.md (9) | **TR-puzzles-001…002**: `puzzles.json` with `schema_version` 2, other version fails; definition schema incl. rule-4b fields | D1 registry, D2.4 `PuzzlesSchema`, G-4 |
| marco-de-puzles.md (9) | **TR-puzzles-003**: `write[]` `{flag,value}` XOR `{flag,value_from,map?}`, values valid for the fact's enum | D2.4 `ONE_OF` + `ref(fact_value)` resolved by `RefIndex.fact_accepts()` |
| marco-de-puzles.md (9) | **TR-puzzles-004**: closed catalogs (`commit_on`, `idle_reset`, `affordance`, `presentation[].call`, `resolution.steps[].kind`) | `ENUM` specs (D2.2, D2.4) |
| marco-de-puzles.md (9) | **TR-puzzles-005**: validation in load sequence after 7's catalogs and 18's keys; release failure = scene-load failure; CI packaging gate | D3 tiers L/B/C, QQ-14 resolution (D3.2), D8.5 |
| marco-de-puzles.md (9) | **TR-puzzles-006**: explicit `int` conversion of integer fields | D4, G-5 |
| escena-de-planta.md (4) | **TR-scene-022**: `load_transitions.json` validated at boot with ranges; invalid → `DATOS_ESCENA_INVALIDOS` | D1 registry, D2.5 ranges, D3 tier L at `SceneLoader.setup` (ADR-0009 step 8) |
| guardado-y-carga.md (5) | **TR-save-021**: `save_config.json` keys; invalid → `CATALOGO_INVALIDO` with parameter | D1 (renamed path), D2.5, G-13 |
| jugador-en-primera-persona.md (2) | **TR-player-002, TR-player-021**: boot validation of `player.json` with parameter name; all feel parameters in data | D1 registry (fatal with param), schema slot for ADR-0012 |
| control-de-acceso.md (8) | **TR-access-001…002**: `access.json` schema validated at load and in CI; fixed reader→fact map, unknown anchor/fact invalid | D1 registry, `ref(fact)` / `ref(interactable)` in tier B/C |
| caja-y-compartimentos.md (10) | **TR-box-007…008**: `BOX_Cn_OPEN` ≤ 1,6 s validated; dev error, demo clamp + warning | D3.6 `CLAMP` policy, `_range_*` |
| sistema-de-pistas.md (17) | **TR-hints-019** (and the data shape behind TR-hints-002/-003/-007, which stay runtime state of 17/9): `hints_policy.json` with `schema_version` 1, `label_key` checked against 18 | D1 (moved path), D2.5, `ref(content_key)` |
| ordenador-correo-impresora.md (19) | **TR-computer-007, -010, -020, -021**: search tags and fixed mail order from 18; `ts_envio` integer minutes; all tuning in `assets/data/` | `mails.json` (`tags`, `sent_min` INT, `presentation_order`), `computer/computer.json` named |
| documentos-y-bolsillo.md (20) | **TR-pocket-001, TR-pocket-010**: closed item catalog in `items.json`; document style and item→document mapping from data; `I-07` built from `CARTA_<variante>` + `CARTA_CUERPO` | D1 registry, `documents.json` `style`/`item`, `variant_id()` |
| director-de-escenas.md (21) | **TR-director-003…004**: scenes defined by data with validation that drops an invalid scene only | D1 (renamed `director/`), D2.5 record isolation, D3.5 |
| llamada-telefonica.md (22) | **TR-call-022…023**: all call times in `call.json`; unset variant facts handled | D1 path fixed, D2.5 root; TR-call-023 is runtime behaviour of 22 (ADR-0017), enabled by `variant_id()` returning `&""` |
| prompt-de-interaccion.md (24) | **TR-prompt-020**: data in `assets/data/ui/prompt.json` | D1 registry |
| atmosfera-reactiva (28) | **TR-atmos-004** (values in `atmosphere.json`); **TR-atmos-019** (material resources, not JSON — out of scope here, ADR-0014) | D1 registry slot |
| estado-y-bus-de-eventos.md (3) | **TR-state-001** (closed catalog of 20 facts in `flags.json`, absent/corrupt → no game), **TR-state-015** (integral-float tolerance on restore) | D1, D2.5, D4.5 (`to_int` shared with ADR-0001 restore) |
| ajustes-persistentes.md (6) | **TR-settings-019**: catalog fatal error through the injected handler with the parameter | G-13, `DataValidator.run()` detail `{param}` |

## Performance Implications

- **CPU (runtime)**: none per frame. `ContentDB` reads are one dictionary
  lookup plus, on first read of an ID, 4 `String.replace` calls; memoised
  afterwards.
- **CPU (boot)**: release reads each boot-time file once (tier L). Debug adds
  tier B (every file read and normalised once more). Data size today is
  estimated below 300 KB in total ‡ (no file exists yet); S-0005-A measures
  the parse of a synthetic 200 KB file and records it. **Provisional budget**
  (record, not gate, until QQ-04 fixes reference hardware): tier L for all
  boot files ≤ 50 ms and tier B ≤ 150 ms on the developer machine.
- **Memory**: normalised trees of all catalogs plus the content snapshot and
  its memo — estimated ≤ 2 MB ‡; raw parse trees are dropped after
  normalisation.
- **Load Time**: `planta` configuration adds tier L of `puzzles.json`,
  `interactables.json` and the other scene-loaded files (synchronous, inside
  ADR-0003's load sequence; counts towards its S-0003-C hitch measurement).
- **Network**: none.

## Migration Plan

No code or data exists. Order of work:

1. S-0005-A spike (below); write results into § Engine API sourcing.
2. S0 "data pipeline" story: `src/core/data/*`, `BuildFlavor`,
   `MemoryFileStore` double, unit tests T-D1…T-D12.
3. Epic 18 first story: narrative schemas, `ContentDB`, `ContentSnapshot`,
   tests T-C1…T-C12; seed `assets/data/narrative/` with the slice content.
4. S0 "CI data gate": `tools/data_check/`, CI job wiring (D8.5).
5. Each owner's first story adds its schema and registry entry (G-2).
6. GDD path edits listed in § Open Items O1 go through
   `/propagate-design-change`.

**Rollback plan**: everything is behind `DataReader` and `ContentDB`'s
public API. Replacing JSON by `.tres` (Alternative 1) or adopting `tr()`
(Alternative 3) changes those two classes and the data files, not their
consumers. If `DataSchema` proves too heavy, schemas can be replaced by
hand-written per-file validators that emit the same `DataIssue`s; the
pipeline and the CI contract stay.

## Validation Criteria

### Spike S-0005-A — JSON parser and data files on Godot 4.7.2 (short, ≤ 0,5 day; must run before `Accepted`)

Setup: `prototypes/spike_0005_json/` (outside the code root), one SceneTree
script `spike_json.gd` run as
`godot --headless --path . -s res://prototypes/spike_0005_json/spike_json.gd`,
plus fixture files in the same folder. It prints one line per case and
writes nothing else. Record every observed result in the table of § Engine
API sourcing (replace "NOT SOURCEABLE" by "Observed 4.7.2, 2026-MM-DD: …").

| Case | Input / action | Observe | Decision it feeds |
|---|---|---|---|
| A1 | `{"a": 2, "b": 2.0, "c": -0, "d": 1e3, "e": 9007199254740993, "f": [2,1,3,4]}` via `JSON.new().parse()` and via `JSON.parse_string()` | `typeof()` of each value; exact value of `e`; element types of `f` | D4 (both outcomes already handled; record which) and ADR-0001 NS-3 |
| A2 | Malformed text (missing `}` at line 7) | return `Error`, `get_error_line()`, `get_error_message()`; `parse_string` result | D5.2, `DataIssue` line reporting |
| A3 | `{"id": 1, "id": 2}` | error / first / last value | D5.3 (rule stays either way; record) |
| A4 | `// comment`, `/* */`, trailing comma in array and object, `NaN`, `Infinity`, single quotes | accepted or error each | R2, G-16 (pre-check needed?) |
| A5 | UTF-8 file with BOM; text `«Sigo aquí.» — ñ` | parse result; byte-exact round trip of the string; BOM handling | D5.4, `JsonText` BOM check |
| A6 | `FileAccess.get_file_as_string()` and `open()+get_as_text()` on an existing and a missing `res://` path | returned text; `FileAccess.get_open_error()` value; any engine error printed | `RealFileStore` (ADR-0009) |
| A7 | Export keeps `assets/data/*.json` readable | **PASS** (run by the lead, 2026-11-11) | Probe project outside the repo (`C:/Users/airlesme/tools/export-json-probe`), Windows release export with templates 4.7.2: `FileAccess.file_exists("res://data/probe.json")` = true and the text reads back **both with an empty `include_filter` and with `data/*.json`** (`export_filter="all_resources"`). Non-resource JSON files are packed in this configuration | G-14 include filter not needed in `all_resources` mode; keep `data/*.json` in the preset anyway as documentation. Re-check if the preset moves to `selected_resources` |
| A8 | Project with **no** `Translation` registered: `tr("UI_X")` and a `Label` whose `text` is `"UI_X"` | returned text; label shows `UI_X` unchanged | D7.4–D7.5 |
| A9 | `OS.is_debug_build()` | **PASS** | Editor/script run = `true`; exported **release** probe prints `debug_build=false` (also seen in ADR-0001 V-ENG-4 and the S0 `[boot] flavor=` line from `demo-windows`) | `BuildFlavor` stays injected (tests use `BuildFlavor.new(false)`) |
| A10 | `OS.get_cmdline_user_args()`, exit code | **PASS** | Exported release probe run with `-- --x`: `OS.get_cmdline_user_args()` = `["--x"]`; `get_tree().quit(0)` ends the process; also used by `Boot` (`--boot-report`, exit 0) in `playtest-windows`/`demo-windows` | — |
| A11 | `Dictionary.make_read_only()` / `Array.make_read_only()` then write | error or silent | D5.6 |
| A12 | Parse a synthetic 200 KB `puzzles.json`-like file ×10 | median ms (record only; developer machine named) | § Performance budget |

**Pass**: every case produces a recorded observation (the spike cannot
"fail" a case; it can only change a rule). **Re-open this ADR** if A7 shows
JSON files cannot be shipped without an import step, or A2 shows no line
information is available (then `DataIssue` reports byte offset or "unknown").

### Test Plan

gdUnit4, `tests/unit/data/` and `tests/unit/content/` (Logic, BLOCKING);
`tests/integration/data/` (Integration). All unit tests use
`MemoryFileStore`, `RecordingLog`, `RecordingFatalHandler` and an explicit
`BuildFlavor` (ADR-0009 D9); no disk, no autoload.

| ID | Suite | Given / When / Then | Covers |
|---|---|---|---|
| T-D1 | `test_to_int.gd` | `2`, `2.0`, `-0.0`, `9007199254740992.0` → int; `2.5`, `true`, `"2"`, `null`, `INF`, `9007199254740994.0` → ERROR with path | D4, TR-puzzles-006, TR-state-015 |
| T-D2 | `test_data_reader.gd` | missing file, non-object root, missing/wrong `schema_version` → one ERROR each, `value == null` | D1.4, G-4 |
| T-D3 | `test_data_reader.gd` | unknown key → ERROR; same in `open_with_warning` object → WARNING | D2.2, G-7 |
| T-D4 | `test_data_reader.gd` | ENUM outside list; ID failing pattern; empty STRING → ERROR; outputs are `StringName` | D2.2 |
| T-D5 | `test_data_reader.gd` | ARRAY `unique_by: id` with a duplicate → ERROR naming both indices | D5.3, TR-content-003 |
| T-D6 | `test_data_reader.gd` | record-isolated array, 1 bad of 3, flavor release → 2 records + WARNING; flavor debug → ERROR | D3.5, TR-director-004 |
| T-D7 | `test_data_reader.gd` | `CLAMP` field 2,0 with max 1,6: release → 1,6 + WARNING; debug → ERROR | D3.6, TR-box-008 |
| T-D8 | `test_data_reader.gd` | `ONE_OF` `write[]` with both `value` and `value_from` → ERROR; `map` without `value_from` → ERROR | TR-puzzles-003 |
| T-D9 | `test_data_validator.gd` | 3 files, 2 errors in different files → `sweep` returns both; `run` logs both and calls `fatal` **once** with `count = 2` and first `param` | D3.3, G-13, TR-settings-019 |
| T-D10 | `test_ref_index.gd` | `ref(fact)` unknown → ERROR; `ref(fact_value)` outside enum → ERROR; ref to retired ID → ERROR | D9.3, TR-puzzles-003 |
| T-D11 | `test_json_text.gd` | BOM → ERROR; malformed → ERROR with a line number (per A2) | D5.2, D5.4 |
| T-D12 | `test_data_catalog.gd` | every `DataCatalog.entries()` path matches `^[a-z0-9_]+/[a-z0-9_]+\.json$` and is unique | D1.1–D1.2, QQ-21 |
| T-C1 | `test_content_db.gd` | valid fixture → `READY`; `MemoryFileStore.read_count` = 10 after 100 reads | TR-content-011, AC-21 |
| T-C2 | `test_content_db.gd` | read in `UNLOADED`: debug flavor → error (assert captured by test double ‡), release → «…» + log | AC-E1 |
| T-C3 | `test_content_db.gd` | corrupt `lines.json` → `ERROR` status + `fatal` with `CONTENIDO_INVALIDO` and file | TR-content-011 |
| T-C4 | `test_content_db.gd` | duplicate ID across `ui.json` and `objects.json`: debug → fatal; release → first wins + log | TR-content-015, AC-E5 |
| T-C5 | `test_content_lang.gd` | lang `xx` missing a key → `es` text + one log; missing in `es` too → «…» | TR-content-005, AC-07 |
| T-C6 | `test_content_names.gd` | `VO_V_12E` with initial «V» → «La V no me convence»; names table missing `guardian_inicial` → `ERROR` | TR-content-007, AC-08 |
| T-C7 | `test_content_groups.gd` | `variant_id(&"VO_G_14", "_RET")` → `&"VO_G_14_RET"`; `(&"VO_G_12", "D")` → `&""`; `CARTA_CUERPO` not in any group | TR-content-004, AC-05 |
| T-C8 | `test_content_retired.gd` | retired ID → «…», `has_key` false | TR-content-003, AC-04 |
| T-C9 | `test_content_reload.gd` | debug: valid reload swaps text; invalid reload keeps old + logs; release flavor: `dev_reload()` false, `read_count` unchanged | TR-content-012, AC-E6, AC-21 |
| T-C10 | `test_content_reload.gd` | reload removing an ID: next read «…» | AC-E3 |
| T-C11 | `test_content_db.gd` | `get_line(&"VO_G_07")` has 2 segments with `pause_before_s` on the second; `get_document(&"DOC_01")` fragments F1–F3 in order | TR-content-008 |
| T-C12 | `test_content_db.gd` | `{accion:interactuar}` left intact in `get_text` | TR-content-017 |
| T-V1 | `tests/unit/tools/test_content_verifier.gd` | §12 fixture vs data: identical → 0 errors; one letter changed → ERROR naming ID; whitespace only → 0 | AC-15, AC-16 |
| T-V2 | same | missing audio → WARNING; with `calidad` → ERROR; `sub_llanto` → ERROR; 7 `PISTA_*` → ERROR | AC-17, AC-18, AC-03a |
| T-V3 | `test_literal_scanner.gd` | `.tscn` `Label` with `text = "Hola"` → ERROR; `"…"` in exception list → pass; `push_error("x")` → pass | TR-content-006 |
| I-D1 | `tests/integration/data/test_boot_sweep.gd` | real `assets/data/` through `DataValidator.sweep` → 0 errors (this is the CI gate as a test) | TR-puzzles-005, AC-47 |
| I-D2 | CI job | `data_check.gd` exits 0 on `main`; a deliberately broken fixture branch exits 1 | D8.2 |

### We will know this was right if

- No story after S0 adds a data file without a registry row (audit by T-D12
  and the `/architecture-review` pass).
- No defect of type "int compared to float" or "wrong path" is filed during
  M1–M4.
- Every data error found in the slice is found by CI before a playtest build
  (zero data-caused load failures in playtests).
- Adding a test language `xx` to one file requires no code change (T-C5).

## Spike Results (2026-11-11)

Godot 4.7.2.stable, headless. Test: `tests/unit/engine_facts/adr0005_json_parser_test.gd` (11 tests, all run).
A1 (number typing) is **not repeated**: it is V-ENG-3 of ADR-0001 (`adr0001_json_roundtrip_test.gd`; all numbers parse as float,
integers beyond 2^53 lose precision). Status stays `Proposed` until the developer accepts it. A7, A9 and A10 were run on 2026-11-11 in a Windows release export (templates 4.7.2 are now installed).

| S-n | Claim | Result | Figures observed | Fallback / note |
|---|---|---|---|---|
| A1 | Number typing | See ADR-0001 V-ENG-3 | — | D4 handles both outcomes |
| A2 | Malformed JSON gives line + message | PASS | `JSON.new().parse()` = `ERR_PARSE_ERROR` (43), `get_error_line()` = 7, message `Expected '}' or ','`; `parse_string` returns `null` and prints an engine `ERROR: Parse JSON failed` | Reopen-condition (no line info) not triggered. On single-line text the line is 0 |
| A3 | Duplicate key `{"id":1,"id":2}` | Silent, **last wins** | `err` = OK, one key, `id` = 2.0 | D5.3 duplicate-ID rule applies to array items only; a duplicate object key cannot be detected after parsing (pre-check of the text, or accept) |
| A4 | Non-standard syntax | MIXED | Rejected: `//` and `/* */` comments, `NaN`, `Infinity`, single quotes, hex. **Accepted silently:** trailing comma in array and in object, leading zero (`01` → 1.0) | R2/G-16: if trailing commas must be errors, `JsonText` needs a text pre-check; otherwise tolerated. `stringify(NAN)` writes `null`, `stringify(INF)` writes `1e99999` (reparses as `inf`): reader must reject non-finite per D4.1 |
| A5 | UTF-8 and BOM | PASS with caveat | `«Sigo aquí.» — ñ` round-trips byte-exact. A BOM is **silently stripped** by `get_string_from_utf8` and by `FileAccess.get_file_as_string` (first code point `{`, no error) | The `JsonText` BOM check (D5.4) cannot work on the `String`: it must inspect bytes (`FileAccess.get_file_as_bytes`) before decoding, else the check never fires |
| A6 | `FileAccess` on `res://` | PASS (editor/script run) | `get_file_as_string("res://project.godot")` = 881 chars, error `OK`; `open()+get_as_text()` identical. Missing path: `get_file_as_string` = `""`, `open()` = `null`, `get_open_error()` = 7 (`ERR_FILE_NOT_FOUND`, "File not found") for both | Note `get_file_as_string("")` of a missing file is indistinguishable from an empty file unless `get_open_error()` is read right after. Export (`.pck`) behaviour: NEEDS_MANUAL (A7) |
| A7 | Export keeps `assets/data/*.json` readable | NEEDS_MANUAL | Not run (no export templates installed; nothing downloaded) | Steps: install export templates, `godot --headless --path . --export-debug "<preset>" <out>`, run a script that reads every fixture under `res://assets/data/`; if missing, add `*.json` to the preset include filter (G-14) |
| A8 | No `Translation`: `tr("UI_X")` and `Label` | PASS | `tr("UI_X")` = `UI_X`, `Label.text` = `UI_X`, `TranslationServer.get_loaded_locales()` = `[]` | — |
| A9 | `OS.is_debug_build()` | PARTIAL | Editor/script run = `true`. `--export-debug` / `--export-release`: NEEDS_MANUAL | `BuildFlavor` stays injected (tests use `BuildFlavor.new(false)`) |
| A10 | `OS.get_cmdline_user_args()`, exit code | NEEDS_MANUAL | Needs a separate process | — |
| A11 | `make_read_only()` | PARTIAL | `is_read_only()` = true for `Dictionary` and `Array`; reads unchanged. The write itself raises an engine error (not exercised: gdUnit counts it as a failure) | Re-check with a standalone script when D5.6 is implemented |
| A12 | Parse of a ~200 KB file | PASS | Synthetic 317 KB (1 200 puzzle-like records), 10 runs: median **12,3 ms**, min 11,0, max 16,5 (developer machine, headless, 4.7.2) | R6 not an issue at the estimated size (< 300 KB total) |

## Open Items

| ID | Item | Owner / route |
|---|---|---|
| O1 | **GDD path edits** required by D1: GDD 5 `save-config.json` → `save/save_config.json`; GDD 21 `scenes/scenes.json` → `director/scenes.json`, `scene-config.json` → `director/director_config.json`; GDD 17 `hints_policy.json` → `hints/hints_policy.json`; GDD 7 `interactables.schema.json` → GDScript schema, `cobertura_anexo_a.json` → `tests/fixtures/interaction/`; GDD 4 fixtures `floor_layout.json`, `element_ids.json` → `tests/fixtures/scene/`; GDD 19 names `computer/computer.json`; GDD 22 `call.json` loses ‡; GDD 4/TR-scene-022 keys `T_cap`, `N_gap`, `Δ_max` → `t_cap`, `n_gap`, `delta_max`; ADR-0009 D2 step 9 text | `/propagate-design-change` |
| O2 | **Resolved 2026-11-10 (applied in ADR-0009 D3, Boot step 0).** **ADR-0009 amendment**: add `flavor: BuildFlavor` to `ServiceContext` (platform part, step 0) | ADR-0009 (update, not supersede) |
| O3 | Run S-0005-A and write observations into § Engine API sourcing | Implementation, S0 |
| O4 | ~~`LogSink` method names~~ Resolved 2026-11-10: pseudocode uses ADR-0001's `LogSink.line(level, msg)` | ADR-0001 |
| O5 | Field lists of the slot files (registry column "Field list owned by") | ADR-0004, -0006, -0007, -0008, -0010, -0011, -0012, -0014, -0016, -0017 |
| O6 | Debug input action that triggers `ContentDB.dev_reload()` | ADR-0006 |
| O7 | Source of the active language at boot (`Settings` key or constant `es`) | ADR-0007 (slice: `es` fixed) |
| O8 | `--against=<ref>` deleted-ID check needs `git` on the CI runner; confirm the runner image | devops-engineer, S0 CI story |
| O9 | `tools/godot/` holds the editor binaries inside the Godot project root; add `tools/godot/.gdignore` so the editor does not scan them (no source covers whether it would) | devops-engineer, S0 |
| O10 | GDScript built-ins in the pseudocode (`type_string`, `is_finite`, `clampi`, `RegEx.create_from_string`, `String.replace`, `Array.filter` with a typed lambda) are pre-cutoff and not covered by the reference; the S0 parse check is their verification | Implementation, S0 |

### Contradictions detected (for `/architecture-review`)

1. **GDD 7 `interactables.schema.json` vs D2.1**: GDD 7 proposes a formal
   JSON-Schema file; this ADR forbids `*.schema.json` and uses a GDScript
   schema. Behaviour asked by GDD 7 (validated at load and in CI, unknown
   field = error) is kept. GDD 7 needs the path change (O1).
2. **QQ-21 paths in GDDs 5, 17, 21**: kebab-case and root-level files
   contradict D1; resolved in favour of D1 (O1). TR-director-003 and
   TR-save-021 text must follow.
3. **`architecture.md` § Data Flow 4 step 2c** lists 12 files for the
   `DataValidator`; D3 tier B sweeps **every** registry entry (25 rows).
   Superset, not conflict; the list in § Data Flow 4 should point to D1.
4. **GDD 9 rule 29 "al arrancar"** means "in 4's load sequence" (its own
   text); `architecture.md` QQ-14 reads it as boot. D3.2 keeps both readings:
   tier L in `planta` (all builds) and tier B at boot (debug/CI).
5. **GDD 4 / TR-scene-022 key names with upper case and `Δ`** (`T_cap`,
   `N_gap`, `Δ_max`) contradict D1.7 (ASCII snake_case); the data keys are
   lowered, the GDD symbols stay in formulas.
6. **`modules/ui.md` recommends `tr()` for all visible strings**; D7 forbids
   it for player text. The reference states a general best practice; GDD 18
   and `architecture.md` row 18 already decided an own layer. Not an engine
   constraint.
7. **`reviews/cross-review-r9-esquema-v2.md` cites `assets/data/flags.json`**;
   the path is `assets/data/state/flags.json` (`architecture.md`, TR-state-001).

## Related

- ADR-0001 Event bus and fact contract (depends on: `flags.json` semantics, NS-3 shared with D4)
- ADR-0002 Pause and game time (`core/clock.json` path)
- ADR-0003 Scene loading (scene-load failure path used by tier L of scene-loaded files; `load_transitions.json`)
- ADR-0009 Service composition (depends on: `ContentDB` autoload #1, Boot steps 1/4, `FileStore`, `FatalErrorHandler`; amendment O2)
- ADR-0004, -0006, -0007, -0008, -0010, -0011, -0012, -0014, -0016, -0017 (enabled: fill their schema slots)
- `docs/architecture/architecture.md` § Module Ownership (row 18), § Data Flow 4, § Required ADRs (ADR-0005 row), QQ-14, QQ-21, Principle 3
- `docs/architecture/tr-baseline-provisional.md` (TRs in § GDD Requirements Addressed)
- `design/gdd/base-de-contenido-narrativo.md` (rules 1–23, Edge Cases, OQ 1, 5, 6, 7)
- `design/gdd/marco-de-puzles.md` (rules 4, 4b, 29; AC-35, AC-47, AC-60…67)
- `design/slice/slice-v0.3.md` §12 (verifier source of truth)
- `.claude/docs/coding-standards.md` (data-driven values, DI, CI rules)

