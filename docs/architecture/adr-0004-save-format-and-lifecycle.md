# ADR-0004: Save Format and Lifecycle

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Precondition for `Accepted`: spike S-0004 (§ Spike) has run on 4.7.2 on
> Windows **and** Linux, its results are recorded in § Spike Results, and
> AC-42 of GDD 5 has passed (it is blocking at the architecture phase).

## Date

2026-11-10

## Last Verified

2026-11-10 — against `design/gdd/guardado-y-carga.md` (revision round 10),
ADR-0001/-0002/-0003/-0009 (all `Proposed`) and `docs/engine-reference/godot/`
(pin 4.7.2). No engine claim has been verified in an editor yet.

## Decision Makers

technical-director (autonomous mode, `modes.automation: autonomous`; decisions
taken with the TD recommendation and recorded here). User approval pending at
the end of the batch.

## Summary

System 5 (`SaveService`, autoload #7) needs a concrete file format, an atomic
write sequence that never renames onto an existing file, a hash, a canonical
form for `dif`, a migration mechanism, the Sellando/Sellada lifecycle and a
signed `request_save`. This ADR fixes: `user://saves/autosave.json` with a
`v1\n<sha256-hex>\n<canonical JSON body>` envelope, a project-owned canonical
JSON encoder used both for the body and for `dif`, a `FileStore`-based
delete-then-rename sequence, a pure-function migration chain, an explicit
`SaveState` machine, cause routing from bus notices, a RealClock-driven
retry scheduler, and the spike S-0004 that must confirm rename/delete, SHA-256
and JSON integer behaviour on 4.7.2 before acceptance.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2) |
| **Domain** | Core (file I/O, persistence) |
| **Layer** | Core (system 5 is Core, sub-layer C3 in ADR-0009 D4) |
| **Knowledge Risk** | HIGH — every file-system, hash and JSON API used is NOT SOURCEABLE in the reference (see table below) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md` (4.4 row: `FileAccess.store_*` return `bool`), `deprecated-apis.md` (`Time.get_ticks_msec()`), `current-best-practices.md` (lambdas, typed GDScript) |
| **Post-Cutoff APIs Used** | `FileAccess.store_buffer() -> bool` (4.4, sourced). Nothing from 4.5–4.7 |
| **Verification Required** | Spike S-0004 (§ Spike): rename/delete semantics and error reporting on Windows NTFS and Linux ext4, `user://` resolution, write truncation and `close()` before rename, SHA-256 over bytes with known vectors, JSON integer typing, `NOTIFICATION_WM_CLOSE_REQUEST` path; AC-42 kill test on both platforms |

### Engine claims and their sources

Rule (CLAUDE.md, `docs/CLAUDE.md`): no engine API is cited from memory. Every
API below that is not in `docs/engine-reference/godot/` is marked and is used
**only** inside `FileStore`, `Sha256Hasher`, `JsonReader` or `Boot`, so the
spike result changes one class, not the design.

| # | API / behaviour relied on | Source | Confined to | Spike step |
|---|---|---|---|---|
| NS-1 | `FileAccess.store_buffer(bytes)` returns `bool` | **Sourced**: `breaking-changes.md` (4.4, Core row) | `FileStore` | A3 (observe on full disk) |
| NS-2 | `FileAccess.open(path, FileAccess.WRITE)` creates/truncates; `FileAccess.open(path, FileAccess.READ)`; `get_length()`, `get_buffer(n)`, `close()`, `FileAccess.get_open_error()` | NOT SOURCEABLE — `FileAccess` open/read/close not covered by `docs/engine-reference/godot/` | `FileStore` | A2, A3 |
| NS-3 | `FileAccess.flush()` and whether it reaches the device (fsync) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | `FileStore` | A4 (power-cut, best effort) |
| NS-4 | `FileAccess.file_exists(path)` | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | `FileStore` | A2 |
| NS-5 | `DirAccess.rename_absolute(from, to)` success/`Error` on Windows and Linux, onto a **missing** target; behaviour onto an existing target (observed only, never relied on) | NOT SOURCEABLE — `DirAccess` not covered by `docs/engine-reference/godot/` | `FileStore` | A5, A6 |
| NS-6 | `DirAccess.remove_absolute(path)` and its `Error` with a read-only file or a foreign open handle | NOT SOURCEABLE — `DirAccess` not covered by `docs/engine-reference/godot/` | `FileStore` | A6 |
| NS-7 | `DirAccess.make_dir_recursive_absolute(path)` | NOT SOURCEABLE — `DirAccess` not covered by `docs/engine-reference/godot/` | `FileStore` | A1 |
| NS-8 | `user://` physical location on Windows/Linux, `ProjectSettings.globalize_path()`, `application/config/use_custom_user_dir` | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | `FileStore`, project settings (ADR-0018) | A1 |
| NS-9 | `HashingContext` with `HASH_SHA256` (`start`, `update`, `finish`) over a `PackedByteArray`; `PackedByteArray.hex_encode()` lowercase | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | `Sha256Hasher` | B1–B3 |
| NS-10 | `JSON.new().parse(text)` / `get_data()` / `get_error_line()`; numeric type returned for `17` (`int` or `float`); handling of trailing data, duplicate keys, BOM, `\uXXXX` | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` (same gap as ADR-0001 NS-3) | `JsonReader` | C1–C6 |
| NS-11 | `String.to_utf8_buffer()`, `PackedByteArray.get_string_from_utf8()`, `PackedByteArray.slice()`, `String.unicode_at()`, `String.num_int64()` | NOT SOURCEABLE — core `String`/`PackedByteArray` methods not covered by `docs/engine-reference/godot/` (long-standing; confirmed by the unit suite on 4.7.2) | `SaveCodec`, `CanonicalJson` | C7 (unit suite) |
| NS-12 | `Time.get_ticks_msec()` | **Sourced**: `deprecated-apis.md` (via ADR-0002 `RealClock`) | `RealClock` (ADR-0002) | — |
| NS-13 | `Time.get_datetime_string_from_system(true)` for `saved_at_utc` | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | injected `utc_now: Callable` in `Boot` | C8 |
| NS-14 | `NOTIFICATION_WM_CLOSE_REQUEST` + `SceneTree.set_auto_accept_quit(false)` so the `quit` save runs before exit | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | `Boot`/`Shell` (ADR-0009) | E1 |
| NS-15 | `OS.is_debug_build()` to exclude dev tools | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` | ADR-0018 | — |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (snapshot `{snapshot_version, facts}`, `is_queue_empty()`, `request_snapshot()`, `restore()`, `reset_new_game()`, `state_restored`/`state_reset`, notice registry incl. `notices_dropped`, `save_at_risk`, `save_recovered`; **needs one addition**, OI-1 below). ADR-0002 (`RealClock.now_ms()`, `SaveService` `PROCESS_MODE_ALWAYS`). ADR-0003 (`SceneLoader.request_load(Destination, Reason, FinalControl)`, `scene_load_finished`, `scene_load_failed`, `full_unload_completed`, `game_finished` sole emitter). ADR-0009 (autoload #7, boot step 10, `ServiceContext` fields `state`, `scenes`, `files`, `real_clock`, `log`, `fatal`; `FileStore`/`MemoryFileStore`). All must be `Accepted` before implementation |
| **Enables** | ADR-0007 (Settings reuses `FileStore` and the same delete-then-rename helper), ADR-0005 (`save-config.json` schema row), ADR-0018 (dev tools «borrar partida guardada», «guardar ahora»; custom user dir) |
| **Blocks** | Epic «Guardado y carga (5)»; stories of 22 (sealing integration, AC-34), 25 (exit to title, `nueva_partida()` from pause), 27 (title: inspection result, Continuar/Nueva partida) |
| **Ordering Note** | S-0004 can run in parallel with ADR-0002's pause spike. `FileStore` (layer 0) is specified here because ADR-0009 names it without an interface; ADR-0007 must reuse it, not redefine it |

## Context

### Problem Statement

GDD 5 fixes the visible behaviour (one slot, automatic saves, sealing of the
call, read-only inspection, corruption fallback) and leaves to an ADR (GDD 5
OQ 1; architecture.md § Required ADRs row ADR-0004; QQ-11; QQ-17): the path,
the envelope, the hash, how the replace is made safe on Windows and Linux, the
canonical form used for `dif`, the migration mechanism, the technical shape of
the Sellando/Sellada lifecycle and the signature of `request_save`. Systems 22,
25 and 27 cannot be implemented until the call surface and lifecycle exist.

### Current State

No code. `architecture.md` § API Boundaries «Guardado (5)» lists four
signatures marked ‡; § Data Flow 3 sketches the pipeline. ADR-0009 names a
`FileStore` platform object and a `MemoryFileStore` double "that can inject
read/rename failures (ADR-0004 tests)" but does not define its methods.

### Constraints

- Engine knowledge risk HIGH for all file APIs (table above); the design must
  not depend on rename-over-existing, on fsync, or on the JSON parser's numeric
  type (GDD 5 rules 13, 19; F3).
- Synchronous I/O on the main thread in the slice (TR-save-006); body ≈ 1 KB.
- Real-time scheduling only through injected `RealClock` (ADR-0002 G-2).
- No singletons in logic: everything injected through `ServiceContext`
  (ADR-0009 D3); unit tests do no file I/O (`MemoryFileStore`).
- Identifiers in English and ASCII (ADR-0001 NS-6); GDD names kept in comments.
- Windows and Linux are the slice platforms (GDD 5 rule 13, AC-42).

### Requirements

- TR-save-001…022 and TR-state-013…016, TR-call-003/-004 (§ GDD Requirements
  Addressed).
- At least one valid candidate survives a process kill between any two steps
  (AC-42); power loss is best effort, measured and documented.
- `dif` must be stable across memory and parsed files (`1` vs `1.0`, key order).
- Every public method unit-testable with fakes (`MemoryFileStore`,
  `FakeRealClock`, a fake `GameState`, `FakeSceneLoader`).

## Decision

### D1. Location and file set

`SaveService` owns the directory `user://saves/` (constant `SAVE_DIR`) and
exactly five names (GDD 5 rule 13):

| Constant | Path | Role |
|---|---|---|
| `MAIN` | `user://saves/autosave.json` | current |
| `PREV` | `user://saves/autosave.prev.json` | one previous generation |
| `TMP` | `user://saves/autosave.tmp` | write staging; also a load candidate (rule 23) |
| `CORRUPT` | `user://saves/autosave.corrupt` | copy (≤ `max_bytes_lectura`) of an invalid main |
| `INCOMPATIBLE` | `user://saves/autosave.incompatible` | copy (≤ `max_bytes_lectura`) of a future-version main |

`user://` is kept as the logical root. Its physical folder (and whether to set
`use_custom_user_dir`, so Settings and saves share a readable folder name) is
an export/project-settings question for ADR-0018, informed by S-0004 A1 (NS-8).
Nothing in this ADR depends on the physical path. The directory is created on
first write (`ensure_dir`); failure is a write failure (GDD 5 Edge Cases).

### D2. Envelope `v<N>` + checksum + body

```text
byte layout (v1):
  "v1" 0x0A
  <64 lowercase hex chars = SHA-256(body_bytes)> 0x0A
  <body_bytes = CanonicalJson.encode(body), UTF-8, no BOM, no trailing newline>
```

- Line separator is exactly `0x0A`. A `0x0D` before it makes the line invalid
  (`v1\r` is not `v<N>`): files are never edited by hand in normal use, and
  accepting CRLF would make the checksum region ambiguous.
- `FORMAT_VERSION: int = 1` is a code constant (GDD 5 rule 26), not data.
- The **header layout of line 1 is frozen forever** (rule 19). Line 2 and the
  body are owned by version N; a future version may change both.
- Body keys (rule 2): `seq` (int ≥ 1), `saved_at_utc` (String), `build`
  (String), `cause` (String), `snapshot` (ADR-0001 object, verbatim),
  `completed` (bool, written only when `true`). Extra keys are ignored on read.

Example body (one line on disk, wrapped here):

```json
{"build":"0.3.0-dev","cause":"door_opened:A","saved_at_utc":"2026-11-10T21:04:11",
 "seq":18,"snapshot":{"facts":{"archivo_abierto":true,"caja_c1":false,…,"t4_decision":null},
 "snapshot_version":1}}
```

### D3. Hash: SHA-256 over the exact body bytes

**SHA-256** (64 hex chars), computed on the bytes written and on the bytes read
(F3); never on a re-serialisation. Purpose: detect truncation and corruption,
not tampering (single-player, nothing to protect). Production implementation
`Sha256Hasher` wraps `HashingContext` `HASH_SHA256` (NS-9). **Fallback** if
S-0004 B fails: a pure-GDScript SHA-256 (`Sha256Pure`, ~120 lines, FIPS 180-4)
behind the same interface; the file format does not change. With a 1 KB body
and a 64 KB read cap, the pure version is acceptable (measured in B3).

Rejected: CRC32 (no engine source either, and weaker for no benefit), MD5
(no gain over SHA-256 if `HashingContext` works), no checksum (rule 2 requires
it).

### D4. Canonical JSON: one encoder for the body and for `dif`

`CanonicalJson.encode(value) -> PackedByteArray` is **project code**, not
`JSON.stringify`. It accepts only the JSON-native value set ADR-0001 promises
(`Dictionary` with `String`/`StringName` keys, `Array`, `bool`, `int`,
`String`/`StringName`, `null`) plus `float` **with zero fractional part**
(normalised to `int`, so `1.0` → `1`). Rules:

1. Objects: keys sorted by Unicode code point (ordinal compare implemented in
   the encoder, not `Array.sort()` on `String`, so the order is ours); no
   whitespace anywhere; `,` and `:` only.
2. Integers: decimal, no `+`, no leading zeros, `-` for negatives; range
   |v| ≤ 2^53 (beyond it the encoder fails: no fact comes near).
3. Strings: `"` and `\` escaped as `\"` `\\`; U+0000–U+001F as `\u00XX`
   (lowercase hex); everything else raw UTF-8. No `\/`.
4. `null`, `true`, `false` literal.
5. A non-integral `float`, `NaN`, `INF`, an `Object`, a `Vector*` or a
   non-string key: `encode` returns an empty buffer and an error code; the
   caller treats it as a write failure and reports through `ErrorPolicy.fail`
   (dev halt) — it is a programming error, not a disk error.

Because the body *is* canonical, any file written by the game re-encodes to
the same bytes after a parse with integer normalisation (AC-30c). The **`dif`
key** is `CanonicalJson.encode({"completed": c, "format": FORMAT_VERSION,
"snapshot": s})` — without `seq`, `saved_at_utc`, `build`, `cause` (F3). Two
contents are equal iff their `dif` buffers are byte-equal.

Rejected: `JSON.stringify(v, "", true)` — its float formatting and key-sort
semantics are NOT SOURCEABLE (NS-10) and the output would differ between a
snapshot in memory (`int`) and one parsed from disk (possibly `float`).

### D5. Reading and validation (two phases, rule 19)

`SaveCodec.decode(bytes, known_snapshot_version) -> DecodeResult` (pure):

1. **Pre-version** (frozen): `0 < size ≤ max_bytes_lectura`; first `0x0A`
   within the first 16 bytes; line 1 matches `v` + ASCII digits, no sign, no
   leading zero unless the number is `0`, value parsed as int.
2. **Version**: `N > FORMAT_VERSION` → `FUTURE` (stop; nothing else is read).
   `N < FORMAT_VERSION` → needs a migration chain `N → … → FORMAT_VERSION`
   (D6); no chain → `DAMAGED`. With the production table empty, `v0` is
   `DAMAGED` (AC-33c) and a test table can make it migratable (AC-33b).
3. **v1 decoder**: line 2 = 64 chars `[0-9a-f]`, then `0x0A`; body = the rest;
   `Sha256(body) == line2` (compare as ASCII); body is valid UTF-8; `JsonReader`
   parses it with nothing after the root; root is `Dictionary`; keys and types
   per D2 where "int" means `int`, or `float` with zero fraction and |v| ≤ 2^53
   (NS-10 unknown, so both are accepted; `17.5` is `DAMAGED`); `seq ≥ 1`;
   `snapshot` is a `Dictionary` whose `snapshot_version` is integral.
4. `snapshot_version > known_snapshot_version` → `FUTURE` (rule 20).
5. Output on success: `VALID` with the body **after** integer normalisation of
   `seq` and of every integral float inside `snapshot` (so `restore` and `dif`
   see `int`; ADR-0001 restore rules stay as a second safety net).

The checksum is verified **before** parsing JSON: a hash mismatch never reaches
the parser. The facts' semantics are not judged (rule 19; 3 does it on restore).

### D6. Migrations

```gdscript
# src/save/save_migrations.gd
class_name SaveMigrations extends RefCounted
## from_version (int) -> Callable(body: Dictionary) -> Variant (Dictionary on success, null on failure).
## Pure: no I/O, no clock, no globals. Empty in the slice (FORMAT_VERSION = 1).
var steps: Dictionary = {}
```

- Each step migrates a **whole decoded body** `N → N+1` and is a pure function
  with its own test (`save_migration_v<N>_test.gd`). Steps run in order during
  inspection; the result is re-validated with the current-version body rules
  (D5 step 3, without the checksum, which belongs to the old bytes).
- A missing link, a `null` result or a failed re-validation → candidate
  `DAMAGED` before the result is decided (rule 21).
- Decoding an old file needs the old version's line-2/body decoder: **when
  `FORMAT_VERSION` is bumped, the previous decoder is kept** as
  `SaveCodecV<N>` for as long as its migration step exists.
- Snapshot changes ride on the file version: whoever changes
  `GameState.SNAPSHOT_VERSION` must bump `FORMAT_VERSION` and add the step. A
  lower `snapshot_version` inside a current-version file can only come from an
  edit and goes to `restore` as is (ADR-0001 best effort).
- The file on disk is never rewritten by a migration; the next normal save
  writes the current format and rotates the old file to `PREV` (rule 21).

### D7. Atomic write sequence (delete-then-rename, never rename onto an existing name)

`SaveWriter.write(content) -> WriteOutcome` runs GDD 5 rule 13 against
`FileStore` only:

```text
 0  ensure_dir(SAVE_DIR)                                     fail → FAILED
 1  bytes := envelope(content); if exists(TMP): remove(TMP)  fail → FAILED
    write_bytes(TMP, bytes)                                  fail → FAILED
 2  back := read(TMP); back.bytes == bytes AND decode(back) == VALID     else → FAILED
 3  if exists(MAIN):
      m := decode(read(MAIN))
      if m == VALID:
         ok := (not exists(PREV)) or remove(PREV) == OK
         ok := ok and rename(MAIN, PREV) == OK              (target is now absent)
         if not ok: log; if remove(MAIN) != OK → FAILED      (main untouched, tmp valid)
      else (DAMAGED or FUTURE or unreadable):
         copy_prefix(MAIN → CORRUPT or INCOMPATIBLE, max_bytes_lectura)  fail → log only
         if remove(MAIN) != OK → FAILED                      (PREV untouched)
 4  rename(TMP, MAIN)                                        fail → FAILED (PREV + TMP valid)
    → WRITTEN
```

- `copy_prefix` = `remove(dest)` if present, then `write_bytes(dest,
  first max_bytes_lectura bytes)`; truncation is logged.
- `FileStore.rename(from, to)` **checks `exists(to)` first and returns
  `ERR_ALREADY_EXISTS` without calling the engine** — the "never rename onto
  an existing file" invariant is enforced in one place and is testable with
  `MemoryFileStore`.
- `FileStore.write_bytes` opens, `store_buffer`, `flush()`, `close()` and only
  then returns; Windows refuses to rename a file with an open handle, so the
  handle must be closed before step 4 (verified by S-0004 A5).
- Process-kill guarantee (AC-42): between any two lines above at least one of
  `MAIN`, `TMP`, `PREV` is valid and F4 picks the newest (GDD 5 Edge Cases). A
  retry after a step-4 failure deletes the valid `TMP` in step 1; a kill during
  that retry's step 1 leaves `PREV` (one save older) — accepted, within the
  "one generation" promise.
- Power loss: best effort (rule 13). The re-read in step 2 may be served by
  the OS cache; whether `flush()` reaches the device is NS-3. S-0004 A4
  measures and records it; no fsync work-around is added in the slice.

### D8. `SaveService` state machine

```gdscript
enum SaveState { UNINSPECTED, NO_GAME, LOADING, IN_GAME, SEALING, SEALED }
```

`SEALING` is GDD 5's sub-state of «En partida»; `is_in_game()` is true for
`IN_GAME` and `SEALING`. Transitions (GDD 5 § States and Transitions):

| From | Event | To | Effect |
|---|---|---|---|
| UNINSPECTED | `setup()` → `inspect()` | NO_GAME | result kept for 27 |
| NO_GAME | `continuar()` (result `VALIDA`, not `terminada`) | LOADING | `state.restore(migrated)` |
| NO_GAME / IN_GAME | `nueva_partida()` | LOADING | from IN_GAME: cancel pending, retries, periodic; no write; `state.reset_new_game()` |
| LOADING | `state_restored` / `state_reset` (then after-drain) | LOADING | baseline := `request_snapshot()`; `next_seq`; sealed flag; `scenes.request_load(...)` |
| LOADING | `scene_load_finished` | IN_GAME or SEALED | `t_ref := now`; SEALED if restored `llamada_iniciada` or `completed` |
| LOADING | `scene_load_failed` or `request_load` returned `false` | NO_GAME | no write; inspection result unchanged |
| IN_GAME | `call_started` | SEALING | capture after drain (D9) |
| SEALING | seal write `WRITTEN` (or `dif` false) | SEALED | — |
| SEALED | `game_finished` | SEALING | captured += `completed: true` |
| IN_GAME / SEALING / SEALED | `full_unload_completed` | NO_GAME | `inspect()` (the single re-inspection) |

`scene_load_failed` with `destino = recepcion` while IN_GAME/SEALING/SEALED
runs the `quit` semantics (one attempt in SEALING, nothing in SEALED) and waits
for `full_unload_completed` (rule 29, GDD 4 rule 14). If `full_unload_completed`
never arrives after a `quit` (a defect of 4 or 27), `get_last_inspection()`
finds `_inspection_stale` set, logs the omission and inspects then — exactly
one re-inspection per exit, as GDD 5 § Re-inspection requires.

### D9. Causes: routing, urgency, grouping

Causes are **internal**: `SaveService` subscribes to the bus in `setup()` and
maps notices 1:1 to causes (ADR-0001 § Notice Name Registry). Callers never
pass notice causes to `request_save`.

| Cause (`cause` string) | Source (ADR-0001 constant) | Urgent | Disableable |
|---|---|---|---|
| `door_opened:<puerta>` | `&"door_opened"` payload `puerta` ‡ | no | no |
| `compartment_done:<n>` | `&"compartment_completed"` payload `n` | no | no |
| `call_started` | `&"call_started"` | **yes** (seal) | no |
| `card_acquired:<B/D>` | fact `tarjeta_B` / `tarjeta_D` → `true` | no | yes |
| `slice_completed` | `&"game_finished"` | **yes** | no |
| `notices_dropped` | `&"notices_dropped"` | no | no |
| `puzzle_solved:<P1…P6>` | `&"EV_PUZZLE_SOLVED_P1"` … `_P6` | no | yes |
| `reveal_pending` | fact `pendiente_revelacion`, either direction | no | yes |
| `pause_opened` | `&"pause_opened"` | no | yes |
| `quit` | `request_save(&"quit")` (25, `Shell` close handler) | **yes**, ignores `t_intento` once | yes |
| `periodic` | `_process`, `t − t_ref ≥ t_periodico` | evaluated without grouping, respects `t_intento` | yes (`t_periodico = 0`) |
| `dev` | `request_save(&"dev")`, dev builds only | **yes** | not in `causas_activas` |

- Pending requests are a set; `t_prim` is the first unattended request since
  the last write. On write, `cause` = the **first** pending cause in arrival
  order (F1 example: `compartment_done:4` absorbs `puzzle_solved:P6`).
- In `LOADING`, `NO_GAME`, `UNINSPECTED`: every cause is dropped, not queued
  (rule 8). In `SEALED`: everything except `game_finished` is dropped. In
  `SEALING`: only the captured content may be written; `quit` makes one
  attempt; all other causes are dropped.
- `notices_dropped` is a normal non-urgent cause; it never seals and never
  infers lost causes (rule 6).
- **Sealing capture (rule 11.1)**: on `call_started` in `IN_GAME`, state →
  `SEALING` and `state.run_after_drain(_capture_seal)` is scheduled. The job
  runs when the current synchronous drain ends — same logical frame, before
  any further input — and takes `request_snapshot()`. If it returns `{}` (only
  possible if the job is entered while 3 is not `READY`), it reschedules
  itself after the next drain and, at the latest, in the next `_process`. With
  the capture, an urgent write of the captured content is evaluated at once.
  This needs **one addition to ADR-0001**: `GameState.run_after_drain(job)`, a
  thin wrapper over `NoticeChannel.run_after_drain` (OI-1).
- **`puzzle_solved:P6` and QQ-11** (P6 OQ 12, D16-16): the P6 choice reaches
  disk at the first write after it — `t_agrupar` (0.1 s†) later, or at once on
  `quit`. The only ways to lose it are a forced kill inside that window or a
  failing disk. This ADR keeps it **non-urgent** (GDD 5 rule 6 unchanged) and
  makes urgency a code table (`URGENT_CAUSE_PREFIXES`), so if the user resolves
  P6 OQ 12 as "the choice must survive a crash", adding `puzzle_solved:P6` to
  that table shrinks the window to the same frame. It **cannot** reach zero
  (kill in the same frame, disk failure): no technical option makes the choice
  absolutely permanent, and P6 OQ 12 should be decided knowing that.

### D10. Scheduler: F1 and F2 in integer milliseconds

Evaluated in `_process` (`PROCESS_MODE_ALWAYS`, ADR-0002) and immediately for
urgent causes. `t` = `RealClock.now_ms()`. F1 is implemented literally:

```gdscript
func _should_write(now: int, is_quit: bool) -> bool:
	if not is_in_game() or _state == SaveState.SEALED:
		return false
	if _state == SaveState.SEALING:
		return _captured.size() > 0 and (is_quit or now >= _t_retry_ms)
	if not _game_state.is_queue_empty():
		return false
	if is_quit:
		return true
	if now < _t_retry_ms:
		return false
	var grouped: bool = _has_request and now - _t_first_ms >= _cfg.group_window_ms
	var periodic: bool = _cfg.periodic_ms > 0 and now - _t_ref_ms >= _cfg.periodic_ms
	return grouped or _has_urgent or periodic
```

`dif` is checked after `_should_write` returns true: if false, pending
requests are cleared and nothing is written (no `seq`, no rotation); in
`SEALING` a false `dif` moves to `SEALED` (the file already holds it).

F2: `_t_retry_ms = t_fail + min(base_ms << (k − 1), max_ms)`, with `k > 30`
→ `max_ms` directly (no overflow; AC-F2). `save_at_risk` is emitted once when
`k` reaches `n_fallos_aviso`; on the next `WRITTEN`, `k := 0` and
`save_recovered` is emitted **only if** `save_at_risk` had been emitted (no UI
noise after a single failure; AC-23 is phrased under that condition).

### D11. Public API (resolves QQ-17 for system 5)

```gdscript
# src/save/save_service.gd — autoload #7 (`SaveServiceAutoload`, ADR-0009 D1)
class_name SaveService extends Node

enum Inspection { NINGUNA, VALIDA, IRRECUPERABLE, VERSION_FUTURA }
enum SaveResult { WRITTEN, NOTHING_TO_WRITE, FAILED, REJECTED, DEFERRED }

## Boot step 10 (ADR-0009 D2). Loads and validates save-config.json
## (fatal CATALOGO_INVALIDO on error), subscribes to the bus, runs inspect().
func setup(ctx: ServiceContext, config_path: String = "res://assets/data/save/save-config.json") -> void

## Result of the LAST inspection. Read-only; never touches disk unless the
## re-inspection after an exit was missed (D8, logged).
## {result: Inspection, con_futura: bool, terminada: bool}
func get_last_inspection() -> Dictionary

## «Continuar». false if not NO_GAME, result != VALIDA, terminada, or a load is running.
func continuar() -> bool

## «Nueva partida». From NO_GAME (27) or IN_GAME (25, confirmed by 25).
## false in LOADING, SEALING, SEALED. Never deletes the file.
func nueva_partida() -> bool

## External causes only: &"quit" (25 «salir al título», Shell close handler)
## and &"dev" (dev builds). Any other cause → REJECTED + log (notice causes are internal).
## quit is synchronous: returns after the single attempt. Called inside a bus drain
## it returns DEFERRED and runs after the drain; exit flows must not call it from a callback.
func request_save(cause: StringName) -> SaveResult

func get_state() -> SaveState                 # tests, debug overlay
```

`22` does **not** call `request_save`: the seal is triggered by the
`call_started` notice (GDD 5 rule 11, GDD 22 rule 3). This narrows ADR-0009
D4's row "22 (F5) → 5 (`request_save`)" (OI-2).

### D12. Decisions on GDD gaps (autonomous mode, recorded)

| # | Decision | Discarded alternative | Reason |
|---|---|---|---|
| DD-1 | `game_finished` in `IN_GAME` (reachable only with the dev console: Reception without a call) writes the **current** snapshot + `completed`, urgent, then `SEALED`; logs a warning | Ignore it | GDD 5 defines it only in Sellada; ignoring would offer «Continuar» after a finished slice. No `respuesta_llamada` exists without a call |
| DD-2 | `save_recovered` only after a `save_at_risk` | Emit on every success after a failure | AC-23 is conditioned on «guardado en riesgo»; a recovered notice with no visible warning is noise for 25 |
| DD-3 | Missing `full_unload_completed` fallback = lazy re-inspection in `get_last_inspection()` | Re-inspect inside the `quit` handling | One re-inspection per exit, never before the unload; same outcome |
| DD-4 | Version line accepts `v0` syntactically; valid only with a migration chain from 0 | Reject `N < 1` in the pre-version phase | Reconciles AC-33c (`v0` damaged in production) with AC-33b (test chain `0 → 1`) |
| DD-5 | Written `cause` = first pending cause in arrival order | Last cause / list | Matches the F1 example (`compartment_done:4`) |
| DD-6 | `completed` written only when `true` | Always write it | Rule 2: optional, absent = false; `dif` key unaffected |

### Architecture Diagram

```text
            bus (ADR-0001)                          callers
 door_opened · compartment_completed ·        25 «salir al título» ─┐
 EV_PUZZLE_SOLVED_P1..6 · call_started ·      Shell close handler ──┼─► request_save(&"quit" | &"dev")
 game_finished · notices_dropped ·            27 title ─────────────┼─► continuar() / nueva_partida()
 pause_opened · facts tarjeta_B/D,            25 pause ─────────────┘   get_last_inspection()
 pendiente_revelacion · state_restored ·
 state_reset · scene_load_finished/failed · full_unload_completed
        │
        ▼
 ┌──────────────────── SaveService (5, autoload #7, PROCESS_MODE_ALWAYS) ────────────────────┐
 │ SaveState (D8) ─► cause routing (D9) ─► scheduler F1/F2 (D10, RealClock ms) ─► dif (D4)    │
 │      │ inspect()                                         │                                  │
 │ SaveInspector (F4) ◄─ SaveCodec.decode (D5) ◄── SaveWriter.write (D7) ─► SaveCodec.encode   │
 │                         ▲ SaveMigrations (D6)            │        Sha256Hasher · JsonReader │
 └──────┼──────────────────┼────────────────────────────────┼──────────────────────────────────┘
        │ GameState: request_snapshot · restore ·            │ FileStore (layer 0, ADR-0009):
        │ reset_new_game · is_queue_empty · run_after_drain  │ exists · read · write_bytes ·
        │ SceneLoader.request_load(PLANTA, REANUDAR |        │ rename (refuses existing target) ·
        ▼   PARTIDA_NUEVA, EXPLORACION | NINGUNO)            ▼ remove · ensure_dir
                                  user://saves/autosave.{json, prev.json, tmp, corrupt, incompatible}
```

### Key Interfaces

```gdscript
# src/core/platform/file_store.gd — layer 0 (ADR-0009). Shared with Settings (ADR-0007).
class_name FileStore extends RefCounted
## Only class that calls FileAccess/DirAccess (NS-2…NS-8). Never throws.

class ReadResult extends RefCounted:
	var status: Error = OK          # OK, ERR_FILE_NOT_FOUND, ERR_FILE_CANT_READ
	var bytes: PackedByteArray      # at most max_bytes
	var total_size: int = -1        # real size; > bytes.size() means truncated

func ensure_dir(path: String) -> Error: return OK
func exists(path: String) -> bool: return false
func read(path: String, max_bytes: int) -> ReadResult: return ReadResult.new()
## Create/truncate, store_buffer (bool, NS-1), flush, close. Any false → error.
func write_bytes(path: String, bytes: PackedByteArray) -> Error: return OK
## Returns ERR_ALREADY_EXISTS WITHOUT calling the engine if `to` exists (D7, G-2).
func rename(from: String, to: String) -> Error: return OK
func remove(path: String) -> Error: return OK

## Text helpers shared with Settings (ADR-0007 OI-3; reconciliation 2026-11-10).
## Composed only of the primitives above; no extra engine calls.
enum ReadStatus { OK, MISSING, ERROR }
func read_text(path: String) -> FileRead: return null    # read() + UTF-8 decode; ERR_FILE_NOT_FOUND → MISSING
## remove(tmp) if present → write_bytes(tmp = path + ".tmp") → remove(path) if present
## → rename(tmp, path). Same delete-then-rename rule as D7 (no backup, no read-back).
func write_atomic(path: String, text: String) -> bool: return false

# tests/support/memory_file_store.gd (ADR-0009 D9): Dictionary path → bytes, plus
#   fail_next(op: StringName, path: String, err: Error)  # op ∈ write|read|rename|remove|ensure_dir
#   corrupt(path, offset, byte) · truncate(path, n) · calls: Array[String]  (ordered op log)
```

```gdscript
# src/save/sha256_hasher.gd
class_name Sha256Hasher extends RefCounted
## Lowercase hex SHA-256 (64 chars). HashingContext (NS-9) or Sha256Pure fallback.
func hex_digest(bytes: PackedByteArray) -> String: return ""

# src/save/canonical_json.gd
class_name CanonicalJson extends RefCounted
enum EncodeError { OK, UNSUPPORTED_TYPE, NON_INTEGRAL_FLOAT, NON_STRING_KEY, INT_OUT_OF_RANGE }
## Empty buffer on error; see last_error().
static func encode(value: Variant) -> PackedByteArray: return PackedByteArray()
static func last_error() -> EncodeError: return EncodeError.OK
## Deep copy with every integral float (|v| ≤ 2^53) converted to int. Used after parsing.
static func normalize_ints(value: Variant) -> Variant: return value

# src/save/json_reader.gd — the only class that calls the engine JSON parser (NS-10)
class_name JsonReader extends RefCounted
## null on any error, including data after the root value (S-0004 C2).
func parse_object(text: String) -> Variant: return null

# src/save/save_codec.gd
class_name SaveCodec extends RefCounted
const FORMAT_VERSION: int = 1
enum Verdict { VALID, DAMAGED, FUTURE }
class DecodeResult extends RefCounted:
	var verdict: Verdict = Verdict.DAMAGED
	var version: int = -1
	var body: Dictionary = {}       # migrated + int-normalised when VALID
	var reason: String = ""         # one log line
func _init(hasher: Sha256Hasher, json: JsonReader, migrations: SaveMigrations) -> void: pass
func encode(body: Dictionary) -> PackedByteArray: return PackedByteArray()   # envelope D2
func decode(bytes: PackedByteArray, total_size: int, max_bytes: int,
		known_snapshot_version: int) -> DecodeResult: return DecodeResult.new()
static func dif_key(snapshot: Dictionary, completed: bool) -> PackedByteArray: return PackedByteArray()

# src/save/save_inspector.gd — read-only (D-27): calls only FileStore.exists/read (G-5)
class_name SaveInspector extends RefCounted
class InspectionReport extends RefCounted:
	var result: int                  # SaveService.Inspection
	var con_futura: bool = false
	var terminada: bool = false
	var chosen_body: Dictionary = {} # migrated, validated
	var max_valid_seq: int = 0       # over ALL valid candidates (rule 18)
func inspect(files: FileStore, codec: SaveCodec, max_bytes: int,
		known_snapshot_version: int, log: LogSink) -> InspectionReport: return InspectionReport.new()

# src/save/save_writer.gd — D7
class_name SaveWriter extends RefCounted
enum WriteOutcome { WRITTEN, FAILED }
func _init(files: FileStore, codec: SaveCodec, cfg: SaveConfig, log: LogSink) -> void: pass
func write(body: Dictionary) -> WriteOutcome: return WriteOutcome.FAILED

# src/save/save_config.gd — save-config.json converted to integer ms
class_name SaveConfig extends RefCounted
var group_window_ms: int          # save_group_window_s      0–1.0 s, 0.1†
var periodic_ms: int              # save_periodic_interval_s 0 or 30–600 s, 120†
var retry_base_ms: int            # save_retry_base_s        1–10 s, 2†
var retry_max_ms: int             # save_retry_max_s         10–300 s, ≥ base, 30†
var fail_warn_count: int          # save_fail_warn_count     1–10, 3†
var max_read_bytes: int           # save_max_read_bytes      16 384–1 048 576, 65 536†
var active_causes: PackedStringArray   # key `causas_activas` in save/save_config.json (ADR-0005 D1; OI-7)
## "" if valid, else the offending parameter name (→ fatal CATALOGO_INVALIDO, AC-27).
static func from_dict(d: Dictionary, out: SaveConfig) -> String: return ""
```

#### Lifecycle pseudocode (typed GDScript, abridged)

```gdscript
# inside SaveService
const URGENT_CAUSE_PREFIXES: PackedStringArray = ["call_started", "slice_completed", "quit", "dev"]
const MANDATORY_CAUSES: PackedStringArray = ["door_opened", "compartment_done", "call_started",
		"slice_completed", "notices_dropped"]

var _state: SaveState = SaveState.UNINSPECTED
var _report: SaveInspector.InspectionReport
var _baseline: PackedByteArray            # dif key of base_dif
var _next_seq: int = 1
var _born_sealed: bool = false
var _captured: Dictionary = {}            # seal content (snapshot)
var _captured_completed: bool = false
var _pending: Array[String] = []          # causes, arrival order
var _has_request: bool = false
var _has_urgent: bool = false
var _t_first_ms: int = 0
var _t_ref_ms: int = 0
var _t_retry_ms: int = 0
var _fail_k: int = 0
var _at_risk: bool = false
var _inspection_stale: bool = false

func _on_call_started(_p: Dictionary) -> void:
	if _state != SaveState.IN_GAME:
		return                                     # SEALING / SEALED / LOADING: ignored
	_state = SaveState.SEALING
	_captured = {}
	_game_state.run_after_drain(_capture_seal)     # OI-1

func _capture_seal() -> void:
	var snap: Dictionary = _game_state.request_snapshot()
	if snap.is_empty():
		_game_state.run_after_drain(_capture_seal) # _process also retries next frame
		return
	_captured = snap                               # llamada_iniciada true, no answer (rule 11.1)
	_captured_completed = false
	_try_write(&"call_started", false)

func _on_game_finished(_p: Dictionary) -> void:
	match _state:
		SaveState.SEALED:                          # 29a/29b: _captured = seal capture or restored snapshot
			_state = SaveState.SEALING
			_captured_completed = true
			_try_write(&"slice_completed", false)
		SaveState.SEALING:                         # 29c: the pending seal now carries completed
			_captured_completed = true
		SaveState.IN_GAME:                         # DD-1
			_log.line(&"warn", "game_finished without seal")
			_captured = _game_state.request_snapshot()
			_captured_completed = true
			_state = SaveState.SEALING
			_try_write(&"slice_completed", false)

func request_save(cause: StringName) -> SaveResult:
	if _state == SaveState.UNINSPECTED:
		_policy.fail("request_save before inspection")       # AC-46 (release: log + reject)
		return SaveResult.REJECTED
	if cause != &"quit" and not (cause == &"dev" and _dev_tools_enabled):
		_log.line(&"error", "request_save: cause not allowed: %s" % cause)
		return SaveResult.REJECTED
	if _game_state.is_draining():                            # G-11 violated: recover, do not lose it
		_game_state.run_after_drain(func() -> void: request_save(cause))
		return SaveResult.DEFERRED
	if cause == &"quit":
		_inspection_stale = is_in_game() or _state == SaveState.SEALED
		return _try_write(&"quit", true)
	_note_request("dev", true)
	return _try_write(&"dev", false)

func _try_write(cause: StringName, is_quit: bool) -> SaveResult:
	var now: int = _clock.now_ms()
	if not _should_write(now, is_quit):                      # D10 (F1)
		return SaveResult.NOTHING_TO_WRITE
	var sealing: bool = _state == SaveState.SEALING
	var snap: Dictionary = _captured if sealing else _game_state.request_snapshot()
	var completed: bool = _captured_completed if sealing else false
	var key: PackedByteArray = SaveCodec.dif_key(snap, completed)
	if key == _baseline:                                     # rule 7: nothing changed
		_clear_requests()
		if sealing:
			_state = SaveState.SEALED
		return SaveResult.NOTHING_TO_WRITE
	var body: Dictionary = {"seq": _next_seq, "saved_at_utc": _utc_now.call(), "build": _build,
			"cause": _first_pending_or(String(cause)), "snapshot": snap}
	if completed:
		body["completed"] = true
	if _writer.write(body) == SaveWriter.WriteOutcome.WRITTEN:
		_next_seq += 1
		_baseline = key
		_t_ref_ms = now
		_fail_k = 0
		_t_retry_ms = 0
		_clear_requests()
		if _at_risk:                                         # DD-2
			_at_risk = false
			_game_state.notify(NoticeIds.SAVE_RECOVERED)
		if sealing:
			_state = SaveState.SEALED
		return SaveResult.WRITTEN
	if not is_quit:                                          # quit never retries (AC-26)
		_fail_k += 1
		var wait: int = _cfg.retry_max_ms if _fail_k > 30 \
				else mini(_cfg.retry_base_ms << (_fail_k - 1), _cfg.retry_max_ms)
		_t_retry_ms = now + wait                             # F2; base ≤ 10 000 ms << 29 fits int64
		if _fail_k == _cfg.fail_warn_count and not _at_risk:
			_at_risk = true
			_game_state.notify(NoticeIds.SAVE_AT_RISK)
	return SaveResult.FAILED

func continuar() -> bool:
	if _state != SaveState.NO_GAME or _report.result != Inspection.VALIDA or _report.terminada:
		return false
	_state = SaveState.LOADING
	_pending_op = &"continue"
	_game_state.restore(_report.chosen_body["snapshot"])     # sync; state_restored follows
	return true

func _on_state_restored(_p: Dictionary) -> void:
	if _state == SaveState.LOADING and _pending_op == &"continue":
		_game_state.run_after_drain(_after_restored)

func _after_restored() -> void:
	var snap: Dictionary = _game_state.request_snapshot()   # baseline = what 3 returns (rule 7a)
	_baseline = SaveCodec.dif_key(snap, false)
	_next_seq = _report.max_valid_seq + 1
	var facts: Dictionary = snap.get("facts", {})
	_born_sealed = bool(facts.get("llamada_iniciada", false)) or _report.terminada
	_captured = snap if _born_sealed else {}                 # rule 29b
	_captured_completed = false
	if not _scenes.request_load(SceneLoader.Destination.PLANTA, SceneLoader.Reason.REANUDAR,
			SceneLoader.FinalControl.EXPLORACION):
		_state = SaveState.NO_GAME                          # file untouched (rule 18)

func _on_scene_load_finished(_p: Dictionary) -> void:
	if _state != SaveState.LOADING:
		return
	_t_ref_ms = _clock.now_ms()
	_state = SaveState.SEALED if _born_sealed else SaveState.IN_GAME

func _on_full_unload_completed(_p: Dictionary) -> void:
	if _state in [SaveState.IN_GAME, SaveState.SEALING, SaveState.SEALED, SaveState.NO_GAME]:
		_state = SaveState.NO_GAME
		_inspection_stale = false
		_report = _inspector.inspect(_files, _codec, _cfg.max_read_bytes,
				_game_state.get_snapshot_version(), _log)
```

`nueva_partida()` mirrors `continuar()` with `reset_new_game()`,
`state_reset`, baseline = reset state (rule 7c), `_born_sealed = false`, and
`request_load(PLANTA, PARTIDA_NUEVA, NINGUNO)`. From `IN_GAME` it first clears
`_pending`, `_t_retry_ms`, `_fail_k` and does **not** call `_try_write` (D-54).

### Implementation Guidelines

- **G-1** All save file access **must** go through `FileStore`; no
  `FileAccess`/`DirAccess` call may appear outside `src/core/platform/`.
- **G-2** `FileStore.rename` **must** refuse an existing target itself;
  `SaveWriter` **must never** rely on overwrite-by-rename.
- **G-3** The checksum **must** be computed on the exact bytes written and
  verified on the exact bytes read; a parsed object **must never** be
  re-serialised to validate.
- **G-4** The body **must** be produced by `CanonicalJson.encode`;
  `JSON.stringify` **must never** be used for save data or for `dif`.
- **G-5** `SaveInspector` **must** call only `FileStore.exists`/`read`
  (unit test asserts the op log).
- **G-6** `seq` decides recency; `saved_at_utc` **must never** take part in a
  decision.
- **G-7** Every timer in system 5 **must** read the injected `RealClock`
  (`now_ms()`, integer ms); `GameClock` **must never** be used here.
- **G-8** A snapshot **must** be requested only with `is_queue_empty()` true;
  the seal capture **must** run via `run_after_drain`.
- **G-9** In `SEALING`, only `_captured` **may** be written; the current
  state **must never** be written there (rule 11.2).
- **G-10** Migrations **must** be pure `Callable(Dictionary) -> Variant`, one
  test file each; bumping `GameState.SNAPSHOT_VERSION` **must** bump
  `SaveCodec.FORMAT_VERSION` in the same change.
- **G-11** Notice causes are internal; external code **must** call
  `request_save` only with `&"quit"` or `&"dev"`, and exit flows **must not**
  call it from inside a bus callback.
- **G-12** Dev tools («borrar partida guardada» removes the five names;
  «guardar ahora» = `request_save(&"dev")`) **must** be excluded from the demo
  build (ADR-0018, AC-44).
- **G-13** Identifiers are ASCII English; GDD names (`dif`, `t_agrupar`,
  «Sellando») appear only in comments and in the D9/D11 mapping.

## Spike S-0004

Run on **4.7.2 stable**, Windows 11 (NTFS, local SSD) **and** Linux (ext4).
Throwaway project in `prototypes/save-spike/`; kill harness in
`tools/save-spike/`. Each step records: API, returned value/`Error`,
observation, verdict, fallback taken.

| Step | What | Pass criterion | Fallback if it fails |
|---|---|---|---|
| A1 | `user://` physical path (`ProjectSettings.globalize_path`) with/without `use_custom_user_dir`; `make_dir_recursive_absolute("user://saves")` twice | Path recorded per OS; second call `OK` | Record; ADR-0018 decides the setting |
| A2 | `FileAccess.open` WRITE truncates an existing file; READ `get_length`/`get_buffer`; `file_exists` | Byte-exact round trip of 1 KB and 64 KB | `FileStore` removes before write (already done for `TMP`) |
| A3 | `store_buffer` on a full volume (Linux tmpfs `size=64k`; Windows 1 MB VHD) and in a read-only folder | `false` returned or `open` fails — never silent success | Compare `get_length()` after `close()` with the expected size |
| A4 | Power loss, best effort: VM hard power-off during a write loop, 20 trials per OS | Outcomes recorded; no requirement | Documented as known limit (rule 13) |
| A5 | `rename_absolute(a, b)`, `b` absent → `OK`; `a` still open (no `close()`) → observe; `b` present → **observe only** | Absent target `OK` on both OS; closed-handle requirement confirmed | If unreliable: copy (`write_bytes` + verify) + `remove`, documented as non-atomic |
| A6 | `rename`/`remove` while another process holds the file (Windows: PowerShell `[IO.File]::Open(p,'Open','Read','None')`; Linux: read-only dir) | Non-`OK` `Error`, no crash; succeeds after release | Already the design: any non-`OK` = failure + F2 |
| B1 | `HashingContext` SHA-256 of `"abc"` and of the empty buffer; `hex_encode()` | `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad` / `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `Sha256Pure` with the same vectors |
| B2 | SHA-256 of a written 64 KB file vs `sha256sum` / `Get-FileHash` | Equal | `Sha256Pure` |
| B3 | Time of B2 (and of `Sha256Pure` if used) for 1 KB | ≤ 2 ms on the dev machine | Accept if ≤ 5 ms (one hash per write path) |
| C1 | Type returned for `17`, `-3`, `0`, `9007199254740992` | Recorded; D5 accepts `int` and integral `float` | None needed |
| C2 | Trailing data `{"a":1} x`, two roots, UTF-8 BOM | Rejected, or detected by `JsonReader` | `JsonReader` pre-check: no BOM, last non-space byte is `}` |
| C3 | Duplicate key `{"a":1,"a":2}` | Recorded | Accept either (only reachable by edit, after checksum) |
| C4 | `é`, raw `é`, `\u0001` round trip | Same string | Encoder emits raw UTF-8 (already) |
| C5 | Invalid UTF-8 body | Behaviour of `get_string_from_utf8` recorded | `SaveCodec` validates UTF-8 itself before parsing |
| C6 | Truncated body | Non-`OK`, no crash | — |
| C7 | `CanonicalJson`/`SaveCodec` unit suites green on 4.7.2 (NS-11) | Green | Fix code |
| C8 | `Time.get_datetime_string_from_system(true)` format | Recorded | Any `String` (informational field) |
| D1 | **AC-42**: dev build with a `SaveWriter` hook sleeping 500 ms after each D7 step 0–4; external `taskkill /F` / `kill -9` during each sleep; 50 runs per step per OS; then normal boot | 100 % reach «Sin partida» with `VALIDA`, no dialog, `seq` ∈ {n, n+1} | **Blocks `Accepted`** |
| E1 | Window close with `set_auto_accept_quit(false)` + `NOTIFICATION_WM_CLOSE_REQUEST` (NS-14): the `quit` write completes before exit | Change present after a normal close | Escalate; loss then bounded by `t_periodico` (rule 14) |

### Spike Results

*Not run yet.* One row per step: OS, result, verdict, fallback.

## Alternatives Considered

### Alternative 1: `store_var` / `ConfigFile` binary or INI

- **Description**: Persist the snapshot with engine serialisation.
- **Pros**: Types preserved; no JSON parser.
- **Cons**: Byte format and its stability across versions NOT SOURCEABLE; not
  readable by QA; GDD 5 rule 2 mandates a JSON body.
- **Estimated Effort**: Lower.
- **Rejection Reason**: Contradicts rule 2; makes the format engine-owned.

### Alternative 2: Classic rename-over-existing (`tmp → main`)

- **Description**: Write `tmp`, rename it onto `main` in one call.
- **Pros**: One fewer step; atomic replace on POSIX.
- **Cons**: Overwrite semantics of `DirAccess.rename` on Windows unknown
  (NS-5); GDD 5 rule 13 forbids depending on it.
- **Estimated Effort**: Slightly lower.
- **Rejection Reason**: Unsourceable dependency; the chosen sequence gives the
  same process-kill guarantee without it.

### Alternative 3: `JSON.stringify` (sorted keys) for body and `dif`

- **Description**: Engine serializer; compare strings.
- **Pros**: No custom encoder.
- **Cons**: Float formatting (`17` vs `17.0`) and sort semantics NOT
  SOURCEABLE; a parsed snapshot and an in-memory one could differ and cause
  spurious writes (breaks AC-30c, AC-38).
- **Estimated Effort**: ~1 day less.
- **Rejection Reason**: `dif` correctness would hang on unverified behaviour;
  the encoder is ~80 lines and fully unit-testable.

### Alternative 4: Write on a worker thread

- **Description**: Run `SaveWriter.write` off the main thread.
- **Pros**: No main-thread hitch.
- **Cons**: Breaks the synchronous `quit` and rule 16; threading APIs NOT
  SOURCEABLE; a 1 KB write is not expected to hitch.
- **Estimated Effort**: Higher.
- **Rejection Reason**: Deferred to GDD 5 OQ 6 (measure first).

### Alternative 5: CRC32 instead of SHA-256

- **Description**: 8-hex checksum.
- **Pros**: Shorter, trivial pure implementation.
- **Cons**: Weaker; no engine source either; GDD 5 proposes SHA-256.
- **Estimated Effort**: Same.
- **Rejection Reason**: No benefit; SHA-256 has a pure fallback too.

## Consequences

### Positive

- Format, `dif` and checksum are independent of the engine's JSON typing and
  serializer.
- All NOT SOURCEABLE file behaviour lives in one class (`FileStore`); the whole
  write sequence is testable with `MemoryFileStore` fault injection.
- Settings (ADR-0007) inherits the same safe-replace primitive.
- QQ-17 closed for system 5: `request_save`, `get_last_inspection`,
  `continuar`, `nueva_partida` signed.

### Negative

- Project-owned canonical encoder (and possibly a pure SHA-256) to maintain.
- Requires an ADR-0001 amendment (`run_after_drain`, `is_draining` on
  `GameState`).
- Two re-reads per write (tmp verify, main validate): trivial at 1 KB.
- Power-loss durability remains best effort.

### Neutral

- `cause` stays `"prefix:arg"` text in the file; code routes by prefix.
- Old-format decoders accumulate as `FORMAT_VERSION` grows.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| R1 Windows sharing violations (antivirus/indexer) on rename/remove | Medium | Any non-`OK` = write failure + F2; S-0004 A6 |
| R2 `HashingContext` absent or wrong on 4.7.2 | Low | `Sha256Pure`, same vectors (B1) |
| R3 JSON parser accepts trailing data or mistypes integers | Low | Checksum before parse; D5 tolerant typing; `JsonReader` end check (C2) |
| R4 Window close does not reach the `quit` save (E1) | Medium | Escalate in S-0004; worst case loss bounded by `t_periodico` |
| R5 OI-1 not accepted into ADR-0001 | Low | Fallback: capture in next `_process`; "before any input" then depends on NOT SOURCEABLE frame order — hence OI-1 is required |
| R6 Kill during a retry's step 1 after a step-4 failure | Low | Leaves `PREV` (one save older); accepted, documented in D7 |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| guardado-y-carga.md | TR-save-001 one slot in `user://saves/` | D1 |
| guardado-y-carga.md | TR-save-002…003 envelope, checksum on exact bytes, `17.0` tolerated | D2, D3, D5 |
| guardado-y-carga.md | TR-save-004…005 atomic write, one generation, five files, never rename onto existing; kill guarantee, power best effort | D7, G-2, S-0004 A, D1 |
| guardado-y-carga.md | TR-save-006 synchronous I/O, single `quit` attempt | D10, D11, Alt. 4 |
| guardado-y-carga.md | TR-save-007 snapshot only with empty queue | D9, G-8 |
| guardado-y-carga.md | TR-save-008…010 grouping, urgency, F2 backoff, real-time clock, `seq` decides | D9, D10, G-6, G-7 |
| guardado-y-carga.md | TR-save-011 canonical `dif` | D4 |
| guardado-y-carga.md | TR-save-012 causes incl. `notices_dropped`, `puzzle_solved:<ID>` | D9 (+ QQ-11 analysis, OI-4) |
| guardado-y-carga.md | TR-save-013…014 state machine, sealing capture, Sellada | D8, D9, lifecycle pseudocode, G-9 |
| guardado-y-carga.md | TR-save-015 only the snapshot persists | D2 |
| guardado-y-carga.md | TR-save-016…018 read-only inspection, two-phase validation, migrations | D5, D6, `SaveInspector`, G-5, G-10 |
| guardado-y-carga.md | TR-save-019…020 `continuar()` / `nueva_partida()` | D8, D11, pseudocode |
| guardado-y-carga.md | TR-save-021 `save-config.json`, `CATALOGO_INVALIDO` | `SaveConfig.from_dict`, `setup()` |
| guardado-y-carga.md | TR-save-022 dev tools out of the demo | G-12 (check in ADR-0018) |
| estado-y-bus-de-eventos.md | TR-state-013…016 snapshot shape, atomic restore, JSON tolerance, snapshot never waits | D2, D5 step 5, D8 (`state_restored` → after drain), G-8 |
| llamada-telefonica.md | TR-call-003…004 single seal point; resumed call never re-seals; answer never on disk | D9 capture, D8 born-sealed, G-9, D11 (22 does not call `request_save`) |

## Performance Implications

- **CPU**: per write ≈ encode 1 KB + 2 SHA-256 + 2 parses; expected < 2 ms
  (S-0004 B3 measures). Per frame: `_should_write` integer compares only.
- **Memory**: < 200 KB peak (three candidates capped by `max_bytes_lectura`).
- **Load Time**: ≤ 3 reads of ≤ 64 KB at boot and on return to title.
- **Network**: none.

## Migration Plan

No existing code. Order: `FileStore` + `MemoryFileStore` → `CanonicalJson` →
`Sha256Hasher` → `SaveCodec` + `SaveMigrations` → `SaveInspector` →
`SaveWriter` → `SaveConfig` → `SaveService`.

**Rollback plan**: the envelope is versioned; changing encoder or hash means
`FORMAT_VERSION = 2` plus a `1 → 2` step reading v1 through the kept
`SaveCodecV1`.

## Validation Criteria

gdUnit4. `tests/unit/save/` uses only doubles (`MemoryFileStore`,
`FakeRealClock`, `FakeGameState`, `FakeSceneLoader`, `RecordingLog`,
`RecordingFatalHandler`); `tests/integration/save/` uses the real `FileStore`
in a temporary `user://` subfolder. Naming `[system]_[feature]_test.gd`,
`test_[scenario]_[expected]`.

| File | Covers | Representative tests |
|---|---|---|
| `save_canonical_json_test.gd` | D4, AC-F3, AC-30c | `test_key_order_irrelevant_same_bytes`, `test_integral_float_encodes_as_int`, `test_fractional_float_fails_encode`, `test_control_chars_escaped`, `test_dif_ignores_seq_time_build_cause` |
| `save_codec_test.gd` | D2, D3, D5, AC-30 (a–h, parametrised), AC-30b, AC-33, AC-33c | `test_roundtrip_valid`, `test_body_byte_flip_damaged`, `test_checksum_char_flip_damaged`, `test_seq_float_17_accepted`, `test_seq_17_5_damaged`, `test_future_version_skips_rest`, `test_crlf_version_line_damaged`, `test_oversize_not_parsed` |
| `save_sha256_test.gd` | D3, S-0004 B1 | `test_abc_vector_matches`, `test_empty_vector_matches` (both implementations) |
| `save_migration_test.gd` | D6, AC-33b | `test_chain_0_to_1_runs_in_inspection`, `test_missing_link_damaged`, `test_failed_step_uses_prev` |
| `save_inspector_test.gd` | F4, AC-28, AC-29, AC-31, AC-32, AC-33, G-5 | `test_empty_dir_ninguna_no_errors`, `test_tmp_newer_than_prev_chosen`, `test_tie_order_main_tmp_prev`, `test_future_main_with_prev_con_futura`, `test_op_log_read_only`, `test_max_valid_seq_over_all_candidates` |
| `save_writer_test.gd` | D7, AC-24, AC-24b, AC-26c, AC-30 (copy), AC-31, AC-33 (incompatible) | parametrised fault at every D7 op → op log, files left, and `SaveInspector` = `VALIDA` with expected `seq`; `test_rename_onto_existing_refused` |
| `save_scheduler_test.gd` | F1, F2, AC-F1, AC-F2, AC-22, AC-22b, AC-23, AC-25 | `test_f1_example_writes_at_100_10`, `test_backoff_2_4_8_16_30_30`, `test_k31_saturates`, `test_at_risk_on_third_failure`, `test_recovered_only_after_at_risk`, `test_periodic_respects_retry_wait` |
| `save_lifecycle_test.gd` | D8, D9, DD-1…DD-6, AC-26, AC-26b, AC-35, AC-35b, AC-36, AC-36b, AC-36c, AC-37, AC-38 (param.), AC-38b, AC-38c, AC-39, AC-40, AC-45, AC-46 | `test_seal_captured_after_drain_without_answer`, `test_quit_in_sealing_writes_captured_once`, `test_sealed_ignores_all_but_game_finished`, `test_born_sealed_writes_restored_plus_completed`, `test_new_game_without_change_never_writes`, `test_new_game_from_pause_discards_without_write`, `test_notice_cause_via_request_save_rejected`, `test_quit_inside_drain_deferred`, `test_single_reinspection_per_exit` |
| `save_config_test.gd` | TR-save-021, AC-27 | parametrised invalid values → fatal `CATALOGO_INVALIDO` with the parameter name |
| `tests/integration/save/save_disk_roundtrip_test.gd` | real `FileStore`, NS-2…NS-7 | write / inspect / continue on disk; read-only folder → `FAILED` + F2 |
| S-0004 D1 harness | AC-42 | kill at each D7 step on both OS — **blocking for `Accepted`** |

AC-34, AC-41, AC-41b, AC-43, AC-48 stay integration/playtest evidence owned by
the GDD 5 epic. We will know this decision was right if the D1 harness gives
100 % `VALIDA` on both platforms, every written `cause` in playtest logs
carries a real `dif`, and no story of 22, 25 or 27 needs a new `SaveService`
method.

## Open Items

| # | Item | Owner | Resolve before |
|---|---|---|---|
| OI-1 | **Resolved 2026-11-10 (applied in ADR-0001 § Key Interfaces).** **ADR-0001 amendment**: add `GameState.run_after_drain(job: Callable) -> void` and `GameState.is_draining() -> bool` (wrappers over `NoticeChannel`); the seal capture and `request_save` deferral depend on them | technical-director (ADR-0001) | ADR-0001 `Accepted` |
| OI-2 | **Resolved 2026-11-10 (ADR-0009 D4 row 22 amended).** **ADR-0009 contradiction**: D4 row "22 (F5) → 5 (`request_save`)". Per GDD 5 rule 11 and GDD 22 rule 3 the seal is notice-driven; 22 never calls 5. Allowed `request_save` callers are 25 and `Shell` (close handler) | technical-director (ADR-0009) | ADR-0009 `Accepted` |
| OI-3 | **Resolved: `RealClock` (ADR-0002).** **Naming divergence**: ADR-0009 `ServiceContext.real_clock: MonotonicClock` vs ADR-0002 `RealClock`. This ADR uses `RealClock` (ADR-0002 owns the type) | technical-director (ADR-0009) | ADR-0009 `Accepted` |
| OI-4 | **QQ-11 / P6 OQ 12** (user decision, pillar/tone): permanence of the P6 choice. Technical input (D9): exposure today = forced kill within `t_agrupar` (0.1 s†) or a failing disk; making `puzzle_solved:P6` urgent narrows it to the same frame, never to zero | user (via game-designer, GDD 16) | M2 (P6) |
| OI-5 | **GDD 5 inconsistency**: Edge Case «Nueva partida desde una partida Sellada: se levanta el sellado» vs rule 24 (rejected in Sellando/Sellada). Read as "from the title after a sealed session"; rejected in-session (D11) | game-designer (GDD 5) | GDD 5 re-review |
| OI-6 | **GDD 5 interpretation**: `save_recovered` only after `save_at_risk` (DD-2); `v0` syntactically accepted (DD-4) | game-designer (GDD 5) | GDD 5 re-review |
| OI-7 | **Resolved 2026-11-10: ADR-0005 registry key `causas_activas` adopted.** Config key for `causas_activas`: proposed `save_active_causes` ‡ | ADR-0005 / entity registry | ADR-0005 |
| OI-8 | `architecture.md` § API Boundaries «Guardado (5)»: replace the ‡ lines with D11 (`request_save` returns `SaveResult`) | technical-director | `/architecture-review` |
| OI-9 | Run S-0004 on both OS; fill § Spike Results incl. power-loss outcome | lead-programmer | `Accepted` |
| OI-10 | Physical save folder / `use_custom_user_dir` (NS-8) | ADR-0018 | First export build |

## Related

- ADR-0001 (depends on; amendment OI-1), ADR-0002 (depends on; `RealClock`,
  `ALWAYS`), ADR-0003 (depends on; load/unload notices, `game_finished`),
  ADR-0009 (depends on; autoload #7, `FileStore`; corrections OI-2, OI-3);
  ADR-0007 (will reuse `FileStore`), ADR-0005 (config schema), ADR-0018 (dev
  tools, user dir).
- `design/gdd/guardado-y-carga.md` (rules 1–29, F1–F4, Edge Cases,
  AC-01…AC-48, OQ 1, OQ 6); `design/gdd/estado-y-bus-de-eventos.md`;
  `design/gdd/llamada-telefonica.md` (rules 3, 27–30);
  `design/gdd/puzle-6-decision.md` (rule 8, OQ 12, D16-16).
- `docs/architecture/architecture.md` § Data Flow 3, § API Boundaries
  «Guardado (5)», § Required ADRs, QQ-11, QQ-17;
  `docs/architecture/tr-baseline-provisional.md`.
- Code (once implemented): `src/core/platform/file_store.gd`,
  `src/save/save_service.gd`, `save_codec.gd`, `canonical_json.gd`,
  `json_reader.gd`, `sha256_hasher.gd`, `save_inspector.gd`,
  `save_writer.gd`, `save_migrations.gd`, `save_config.gd`;
  `assets/data/save/save-config.json`.
