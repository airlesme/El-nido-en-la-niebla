# ADR-0018: Build, export, CI and dev-only tooling

## Status

Proposed

> Moves to `Accepted` only by the user, or `technical-director` on the user's
> explicit confirmation (template rule). This ADR was drafted in autonomous mode
> (`project.yaml` `modes.automation: autonomous`): every decision below is the
> author's recommendation, recorded with its rejected alternative, not an
> approved decision. **Nothing in the export half of this ADR has been run.**

## Date

2026-11-10

## Last Verified

2026-11-10 against: the repository state on that date (read, not executed, except
the three directory listings named in "Verified facts"), `docs/engine-reference/godot/`,
ADR-0001, -0002, -0004, -0005, -0010, -0013 and `architecture.md`.

## Decision Makers

`devops-engineer` (author, recommendation) · pending: `technical-director`
(approval, and approval of the amendments listed in Open Items O1–O6) · consulted
by reference: `qa-lead` (test gates), `lead-programmer` (dev-tool layout rule D3).

## Summary

The project has a green CI test job and a committed gdUnit4, but no export preset,
no verified way to keep the dev console, save tools, content hot reload and
playtest log out of the funding demo, no data-verifier CI step and no build
versioning. This ADR fixes: four export presets (`playtest` and `demo` for Windows
and Linux), one dev-tools root `src/dev/` excluded from `demo` and *proved*
absent by a byte audit of the exported artifact with a positive control, a
tag-derived build version stamped at CI time, the CI step order (pins → import →
parse → data check → forbidden-API grep → gdUnit4), a `.godot/` policy (committed
class cache only, no CI cache), and a pin/upgrade procedure for Godot and gdUnit4.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pinned `4.7.2.stable.official.ed1daf0bf`) |
| **Domain** | Core (build, export and CI tooling; no runtime engine API except `OS.is_debug_build()` via `BuildFlavor`) |
| **Layer** | Core — `architecture.md` § Required ADRs lists ADR-0018 as non-critical ("Primera build de entrega, antes de M5"). Note the template's definition: Foundation would make `/create-stories` halt on it at `standard`. See Ordering Note: D1/D2 are needed at S0. |
| **Knowledge Risk** | HIGH (VERSION.md: 4.5–4.7 post-cutoff). Export is the least covered area of `docs/engine-reference/godot/`. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/current-best-practices.md` § Command Line — Tests and Parse Check; grep of the whole `docs/engine-reference/godot/` for `export`, `--import`, `crash` (only `current-best-practices.md` matches) |
| **Post-Cutoff APIs Used** | None in game code. CLI flags relied on and sourced: `--headless`, `--path`, `--import`, `--quit-after`, `--export-debug <preset>` (implies `--import`), `-s`/`--script`. |
| **Verification Required** | V-18-1 … V-18-10 (Validation Criteria). Every export-related behaviour below is `NOT VERIFIED` until those run. |

### Engine facts used, and their source status

| # | Fact | Status |
|---|------|--------|
| E1 | `--export-debug <preset>` exists and implies `--import` | Sourced: `current-best-practices.md` § Command Line |
| E2 | `--export-release <preset>` exists | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` (only `--export-debug` is listed; ADR-0005 A9 assumes it) |
| E3 | Export templates must match the editor version exactly; where they are installed; the archive name | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`. Observed 2026-11-10: `C:\Users\airlesme\AppData\Roaming\Godot\export_templates\` exists and is **empty** (no templates installed locally). |
| E4 | `export_presets.cfg` property names (resource filter, exclude filter, embed-PCK, export-mode) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` |
| E5 | `OS.is_debug_build()` is `true` in `--export-debug` and `false` in `--export-release` | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/` (same as ADR-0001 NS-4, ADR-0004 NS-15, ADR-0005 A9); this ADR relies on it only through `BuildFlavor`, and V-18-2 checks it |
| E6 | The first `--import` of a fresh project crashed on exit (139) in 3 of 17 runs on 4.7.1/4.7.2 (Windows, 2026-10-17), after writing the same `.godot/` files as a clean run; re-running exited 0; 4.6.1: 0 of 4 | Sourced: `current-best-practices.md` § Command Line. Linux rate unknown. |
| E7 | A fresh clone without `.godot/` class cache: gdUnit4 runner exits 1 having run nothing; `--import` / `--quit-after` exit 0 on a parse error (not parse checks) | Sourced: same section |
| E8 | gdUnit4 exit codes 0/100/101/103/104/105/1; 101 also means orphan nodes; `No test cases found` exits 0 | Sourced: same section |
| E9 | The class cache is `.godot/global_script_class_cache.cfg` and is deliberately committed (`.gitignore` lines 63–69) | Verified by reading `.gitignore` |
| E10 | Exported releases read scripts/resources absent from the PCK as missing (a `preload` of an excluded path breaks the export; `load()` of one returns null) | NOT SOURCEABLE — not covered by `docs/engine-reference/godot/`; V-18-5 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0005 (verifier `tools/data_check/`, `BuildFlavor`, D8.5 CI order), ADR-0001 (G-11, CA-29), ADR-0004 (G-12, AC-44, OI-10), ADR-0009 (Boot step 0 injects `BuildFlavor`) |
| **Enables** | Stories "S0 export", "S0 CI data gate"; the first delivery build; ADR-0010 D16 playtest log placement; ADR-0013 `HandsDebug` placement |
| **Blocks** | Any story whose acceptance criterion is "absent from the demo" (AC-44, AC-21 of GDD 18, CA-29); the funding-demo build |
| **Ordering Note** | D1 (presets), D5 (pins) and D6 (CI order) are needed at S0 (PLAN-TECNICO: "exporta una escena vacía en Windows y Linux"); D3/D4 become testable only when the first dev tool exists (S1+). V-18-2 (`BuildFlavor` per export mode) must run before ADR-0005's `BuildFlavor` wiring story. |

## Context

### Problem Statement

Seven requirements converge on "dev-only, and provably absent from the demo", plus
the test and data gates the GDDs promise, and none has a mechanism: ADR-0001 G-11,
ADR-0004 G-12, ADR-0005 D6.7, ADR-0010 D16 and its reconciliation path, ADR-0013's
`HandsDebug`, ADR-0002 D6's timer ban, and ADR-0005 D8.5's CI order all say
"ADR-0018 does it". The export cannot be exercised until presets and templates
exist, and a demo that ships the console (TR-state-018) or hot reload
(TR-content-012) fails acceptance, so this decision cannot wait until M5.

### Current State (verified by reading, 2026-11-10)

- `.github/workflows/tests.yml`: one job `Run GdUnit4 Tests` on `ubuntu-latest`;
  preflight that `addons/gdUnit4/bin/GdUnitCmdTool.gd` exists;
  `godot-gdunit-labs/gdUnit4-action@v1` with `godot-version: '4.7.2'`,
  `version: 'installed'`, `paths: tests/unit, tests/integration`; uploads `reports/`.
  Per the user (2026-11-10) this job **ran green on GitHub Actions**. No run id is
  recorded here and this author did not re-check; `tests/README.md` still says "CI
  not yet run" and "addon is not committed" (stale).
- gdUnit4 **6.2.3** committed in `addons/gdUnit4/` (`plugin.cfg` `version="6.2.3"`,
  read). 3 example tests pass on Godot 4.7.2 headless with the command in
  `tests/README.md` (exit 0; the two `127.0.0.1:0` errors are expected).
  The plugin is not enabled in `project.godot`; the command-line tool works without it.
- `project.godot` has no autoloads, no main scene, no input map; `project.yaml`
  `commands.build` is `[TO BE CONFIGURED]`.
- **No `export_presets.cfg`, and `.gitignore` line 71 ignores that filename.**
  PLAN-TECNICO § Build says "presets en repo". These contradict (see O7).
- `tools/` holds only `tools/godot/` (pinned portable editor + `godot.ps1`
  wrapper, `version.txt` with Windows archive and SHA-512). No `tools/godot/.gdignore`
  exists (ADR-0005 O9 asked for it). `tools/ci/`, `tools/data_check/`, `src/dev/`
  do not exist. `src/` has empty-ish subfolders only.
- Export templates: none installed locally (E3).
- `project.yaml` `commands.test` runs `-a res://tests`; the workflow runs
  `tests/unit` and `tests/integration` only.

### Constraints

- Godot 4.7.2 pinned; trunk-based on `main` (CLAUDE.md); solo/small team, GitHub Actions.
- Funding demo is the deliverable; Windows and Linux only (PLAN-TECNICO).
- Project rules: no skipped CI steps for speed; never disable a failing test;
  helpers emit observations, not verdicts (CLAUDE.md) — see D4 for how the audit
  respects that.
- This agent changes no game code; D3 is a rule for the programmers.
- Linux CI cannot run the Windows build; Windows verification is local.

### Requirements

- Export Windows and Linux with one command locally and in CI, from presets in the repo.
- Dev console (3), save dev tools (5), content hot reload (18), playtest log (9),
  hands debug (13) and the puzzle reconciliation path: present in dev/playtest
  builds, **absent** in the demo, with an automated check that has been seen to fail.
- A build identifies itself (version, commit) so a playtest log or a bug report can
  be tied to it.
- CI validates every JSON data file through the ADR-0005 verifier.
- A documented path for Godot and gdUnit4 updates, given the known 4.7.x import crash.

## Decision

### D1. Export presets: four, in the repo

| Preset name | Platform | Export command | Dev tools | Purpose |
|---|---|---|---|---|
| `playtest-windows` | Windows Desktop x86_64 | `--export-debug` | present | internal playtest, dev checks, playtest log |
| `playtest-linux` | Linux x86_64 | `--export-debug` | present | same |
| `demo-windows` | Windows Desktop x86_64 | `--export-release` (E2) | **absent** | funding demo |
| `demo-linux` | Linux x86_64 | `--export-release` (E2) | **absent** | funding demo |

Rules:

1. `export_presets.cfg` is **committed**: remove `export_presets.cfg` from
   `.gitignore` (O7). It holds no secret in the slice: no signing, no PCK
   encryption key, no store credentials, no custom Windows icon/metadata step
   (those are out of scope; adding any needs an ADR amendment and a secrets plan
   — where secrets live and who changes them is a user decision, not made here).
2. The `demo-*` presets are the only ones whose resource filter excludes
   `src/dev/*`, `tests/*`, `tools/*`, `prototypes/*`, `addons/gdUnit4/*`,
   `design/*`, `docs/*`, `production/*`, `reports/*`, `.claude/*` (exact property
   names: E4, NOT VERIFIED). `playtest-*` excludes the same **except** `src/dev/*`.
   Neither includes `tests/` or `addons/gdUnit4/`: a shipped test addon is never wanted.
3. `demo-*` must only be exported with `--export-release`; the build scripts
   hard-code the pairing, and D4's audit makes a mismatch visible anyway.
4. Output goes to `build/<preset>/` (gitignored; add to `.gitignore`).
5. PCK embedding: prefer a separate `.pck` next to the executable so the audit scans
   a file with no engine strings in it (E4; if the setting is unavailable, the D4
   patterns are specific enough to survive an embedded PCK — checked by V-18-6).
6. `use_custom_user_dir` (ADR-0004 OI-10): **not set**. The default `user://` stays
   until S-0004 step A1 is recorded on Windows and Linux; then ADR-0004 or this
   ADR is amended. Decision deferred on purpose, with this trigger.
7. Windows export from the Linux runner: allowed only if V-18-3 shows it works with
   no extra tooling; if it needs a tool this ADR has not sourced (e.g. a resource
   editor under Wine), the Windows presets build on a Windows runner instead, and
   O8 is closed with that.

**One-command local build:** `tools/build/export.ps1 -Preset <name>` (and
`tools/build/export.sh <name>` for Linux/CI) wrapping `tools/godot/godot.ps1`
(the existing pinned wrapper, which forwards `@args`); sets `project.yaml`
`commands.build` once V-18-3 passes. Steps inside: pin check → `--import` with the
D6 retry → `--export-*` → D4 audit → checksum file.

### D2. Export templates

1. Templates are installed from the official release of the *same* pinned version.
   The pin file `tools/godot/version.txt` (today: Windows archive + SHA-512) gains
   `TEMPLATES_ARCHIVE`, `TEMPLATES_SHA512`, `LINUX_ARCHIVE`, `LINUX_SHA512`, filled
   at S0 from the official `SHA512-SUMS.txt` (URL pattern already in that file's
   header). Archive file names and the install folder are E3: NOT SOURCEABLE; the
   S0 story records them after the first successful install (V-18-3).
2. Hash mismatch fails the step; nothing is "fetched latest".
3. The CI runner caches the downloaded archive (key = the pin file hash), not an
   installed tree.

### D3. Dev-tools layout rule (the mechanism behind "excluded")

A file exclusion only works if production code does not depend on the excluded
file. Rules, stated as must / must never for `/create-control-manifest`:

- Every dev-only artifact (script, scene, resource) **must** live under
  `res://src/dev/<system>/`. One root, one exclusion pattern, one audit pattern.
  This covers: dev console and `dev_force` (ADR-0001 G-11; 3), «borrar partida
  guardada» and «guardar ahora» (ADR-0004 G-12; 5), the content hot-reload body
  (ADR-0005 D6.7; 18), `PuzzlePlaytestLog` (ADR-0010 D16; 9), the puzzle
  reconciliation path (ADR-0010 monotony note; 9), `HandsDebug` (ADR-0013; 13).
- Scripts under `src/dev/` **must never** declare `class_name` (E9/E10: a global
  class name registered in the class cache but whose file is absent from the PCK is
  an unverified failure mode; path-based `preload` inside `src/dev/` avoids it).
  Tests reference dev scripts by `preload("res://src/dev/…")`.
- Code outside `src/dev/`, `tests/` and `tools/` **must never** contain the string
  `res://src/dev/` or `src/dev/` in a `preload`/`load` argument other than the
  single entry point below.
- Single entry point: `Boot` (ADR-0009) calls `DevTools.attach(ctx)` only when
  `ctx.flavor.is_debug()`; `DevTools` is the one non-dev file that names the dev
  root, and it loads `res://src/dev/dev_entry.gd` with a runtime `load()` (never
  `preload`), tolerating absence by logging one line and returning. `GameState`,
  `ContentDB`, `SaveService`, the puzzle framework and the hands rig expose only
  inert hooks (a settable `Callable` or an injected optional collaborator) that the
  dev entry fills. No dev behaviour lives in a production file behind an
  `if is_debug()` — that pattern leaves the code in the demo and is what the
  separate-script rule exists to prevent.
- Debug-only input actions (ADR-0006 owns them) **must** be prefixed `dev_`; they
  remain in `project.godot` in the demo, unbound to any handler. The D4 scan does not
  flag action names.
- Every file under `src/dev/` **must** carry a comment line with the literal marker
  `NIDO_DEV_ONLY_MARKER` (canary for D4).

Consequence for other ADRs: this **amends** ADR-0005 D6.7 (the release export
"compiles the method but `is_debug()` is false"): TR-content-012 and GDD 18 AC-21
say the demo has no reload, and a compiled-but-inert method is not that. See O1.

### D4. Verified exclusion: static gates on every push, artifact audit on every export

Two layers; the second has a positive control so a blind audit fails loudly.

**Layer 1 — static, in the test job (seconds), `tools/ci/check_dev_isolation.sh`:**

```
fail if any `class_name` line exists in src/dev/**
fail if any *.gd/*.tscn/*.tres outside {src/dev, tests, tools, prototypes}
   contains "src/dev/"  except src/core/composition/dev_tools.gd (allowlist, one line)
fail if any file under src/dev/ lacks NIDO_DEV_ONLY_MARKER
fail if export_presets.cfg: a preset named demo-* does not mention "src/dev/*"
   in its exclusion filter  (string check; property name E4)
fail if a demo-* preset is not paired with the release export mode  (E4)
print every finding as: SEVERITY path rule: message   (observation lines; exit
   code is the only verdict, as in ADR-0005 D8.2)
```

**Layer 2 — artifact audit, `tools/ci/audit_artifact.sh <preset-dir>`, run by
`tools/build/export.*` and by the export workflow after each `--export-*`:**

```
FORBIDDEN = ["src/dev/", "NIDO_DEV_ONLY_MARKER", "addons/gdUnit4/",
             "tools/data_check/", "tools/ci/", "tools/godot/",
             "tests/unit/", "tests/integration/", "prototypes/"]
scan all files in <preset-dir> as raw bytes for each ASCII pattern
if preset startswith "demo-":   any hit            -> exit 1 (name file + pattern)
if preset startswith "playtest-": "src/dev/" and the marker MUST hit
                                  no hit           -> exit 2 (audit is blind)
no files scanned or dir missing                    -> exit 2
```

The positive control (`playtest-*` must contain `src/dev/`) is what makes the
audit a gate that has been watched fail, per `.claude/rules/test-standards.md`
and `skill-authoring.md`. Assumption that PCK paths and script strings appear as
plain ASCII bytes: NOT VERIFIED (V-18-6). If they do not, the positive control
exits 2 and the audit design is replaced before this ADR is accepted.

**Layer 3 — behavioural smoke of the delivered binary (Linux only in CI; Windows
manually, D9):** run the exported `demo-linux` headless with `-- --boot-report`
(a user arg the game ignores otherwise) and require exit 0 and a stdout line
`[boot] flavor=release dev_tools=absent version=<v> commit=<sha>`; for
`playtest-linux`, `flavor=debug dev_tools=attached`. Requires Boot to print that
line (O3, request to ADR-0009). Whether an exported binary accepts `--headless`
and passes user args after `--` is NOT SOURCEABLE for exports (V-18-7).

### D5. Build versioning

1. Release version = git tag `vMAJOR.MINOR.PATCH` on `main` (trunk-based, release =
   tag, per the branching strategy). Pre-1.0: `v0.<n>.<fix>`; `n` increments per
   delivered demo or playtest wave; the first funding demo is a `v0.x.0`.
2. `application/config/version` in `project.godot` (name: E4-class, NOT VERIFIED)
   holds the release version; a CI check fails a tag build when it differs from the
   tag. On `main` between tags it holds the next intended version.
3. Build identity is stamped, not committed: tracked
   `assets/data/build/build-info.json` ships `{"version":"dev","commit":"dev",
   "run":0,"built_utc":"dev"}`; the export workflow overwrites it in the runner's
   workspace (never committed) with the tag, short SHA, run number and UTC time.
   `Boot` reads it through `DataReader` (needs a schema row in ADR-0005, O4) and
   shows version+commit on the title screen only in `playtest-*` builds.
4. Artifact name: `el-nido-<version>-<preset>-<shortsha>`; a `SHA256SUMS.txt`
   is generated beside it.
5. The save format version (`SaveCodec.FORMAT_VERSION`, ADR-0004 G-10) and the build
   version are **independent**; a build version bump never implies a save migration.

### D6. CI: steps, order, gates

Workflow files: `tests.yml` (keeps its job name `Run GdUnit4 Tests`: the comment in
that file says branch protection must require that name) and a new `export.yml`.

`tests.yml` job steps, in order (all blocking unless marked):

```
 1 checkout (lfs: true)                         [exists]
 2 preflight: addon present                      [exists]
 3 tools/ci/check_pins.sh                        [new]  version pins agree (D8)
 4 install pinned Godot (own step, from tools/godot/version.txt LINUX_*) [new]
 5 godot --headless --path . --import            [new]  retry rule below
 6 tools/ci/check_class_cache.sh                 [new]  ADVISORY until V-18-9
 7 parse check: godot --headless --path . -s res://.claude/scripts/godot-parse-check.gd -- <all .gd>  [new]
 8 tools/ci/check_dev_isolation.sh               [new]  D4 layer 1
 9 tools/ci/forbid_timers.sh                     [new]  ADR-0002 D6
10 data_check.gd (no flag)                       [new]  D7; absent verifier = failure once data exists
11 gdUnit4 action, paths: tests                  [exists, path widened]
12 upload reports/ (if: always())                [exists]
```

Rules:

- **Import retry (step 5; E6).** Run `--import`; if it exits 139 and nothing else,
  run it once more; any other non-zero, or a second 139, fails the job. Every retry
  emits a `::warning::` annotation so the real Linux crash rate becomes data (O9).
  This is a documented, bounded flake, not a blanket retry; no other step retries.
- **gdUnit4 gate.** Exit 0 passes; 100, 101 (including orphans), 103, 104, 105, 1
  fail (E8). A suite with zero tests is not a pass: a step counts `*_test.gd` files
  under `tests/` excluding `tests/**/example/` once the examples are deleted, and
  fails at 0. Whether the action itself fails on 101 is NOT VERIFIED (V-18-4).
- **Paths.** The action runs `tests` (matching `project.yaml` `commands.test`), not
  `tests/unit` + `tests/integration`, so `tests/smoke` and later folders are not
  silently outside CI.
- **Fuzz/oracle tests** (TR-puzzles-021 N_fuzz=1000, TR-puzzle1-018 …) run in this
  job with a fixed seed constant in the fixture (Determinism rule); on failure the
  test prints the seed. Suite time budget and `timeout-minutes` are set from the
  first measured run (O10).
- **Pins.** Third-party action `godot-gdunit-labs/gdUnit4-action@v1` is pinned to a
  commit SHA at S0 (SHA not looked up here); first-party `actions/*` stay on major tags.
  `ubuntu-latest` is replaced by an explicit image label when `export.yml` lands
  (availability NOT VERIFIED), so a runner image change cannot move two jobs differently.

`export.yml`:

```
on: push tags v* | workflow_dispatch | pull_request touching
    {export_presets.cfg, project.godot, src/dev/**, tools/build/**, tools/ci/**}
jobs:
  export (matrix: playtest-linux, demo-linux, playtest-windows, demo-windows):
    - checkout, install pinned Godot + templates (D2), stamp build-info.json (D5)
    - import (retry rule), data_check.gd [--hito=calidad on demo-* and tag builds]
    - godot --headless --path . --export-<debug|release> <preset> build/<preset>/...
    - tools/ci/audit_artifact.sh build/<preset>       # D4 layer 2
    - (linux presets) boot-report smoke                # D4 layer 3
    - sha256sum, upload-artifact (retention set per V-18-10)
  gate: on tag builds, the release is not "valid" unless all four matrix legs pass.
```

Export is **not** run on every push: it downloads templates and builds four
presets. That is a tiering decision, not a skipped step — layer 1 (the cheap half
of exclusion) and the whole test/data gate run on every push and PR; layer 2 runs
on tags, manual dispatch and on PRs that touch what could break it. Build-time
numbers are NOT MEASURED (O10); if layer 2 proves cheap, move it to every push
rather than widening the path filter.

### D7. CI validates JSON data with the ADR-0005 verifier

1. Command (ADR-0005 D8.1): `godot --headless --path . -s res://tools/data_check/data_check.gd -- [--hito=calidad]`,
   run after import and parse check (class cache must exist, E7).
2. Exit `0` pass (warnings allowed); `1` data errors; `2` the tool itself failed.
   CI fails on any non-zero and annotates `2` as "verifier broken", not "data bad".
3. Ordinary pushes/PRs: no flag. `--hito=calidad` (pending text and missing audio
   become errors) runs in `export.yml` for `demo-*` presets and on `v*` tags.
4. **Absence rule.** Step 10 fails if any `assets/data/**/*.json` exists and
   `tools/data_check/data_check.gd` does not. Data cannot exist unverified. Today
   `assets/data/` holds `.gitkeep` only, so the step is added by the S0 "CI data
   gate" story (ADR-0005 rollout), not before it; until then there is nothing to
   verify and nothing is skipped.
5. The verifier must not name any autoload (ADR-0005 G-15; E7), and it needs the
   committed class cache or a prior import, which step 5 provides.
6. Verifier output lines are observations; the exit code is the only verdict
   (CLAUDE.md helper rule). CI does not parse them for pass/fail.

### D8. Godot and gdUnit4: pin and upgrade

**Where the pin lives (single truth + three mirrors, `check_pins.sh` fails if any differ):**

| Item | File | Current |
|---|---|---|
| Godot (truth) | `tools/godot/version.txt` `VERSION=` | `4.7.2-stable` |
| CI | `tests.yml` / `export.yml` `godot-version` | `4.7.2` (`4.7.2-stable` ↔ `4.7.2`) |
| Project feature | `project.godot` `config/features` | `"4.7"` (minor only) |
| Docs | `docs/engine-reference/godot/VERSION.md` | 4.7, 4.7.2.stable.official.ed1daf0bf |
| gdUnit4 (truth) | `addons/gdUnit4/plugin.cfg` `version=` | `6.2.3` |
| gdUnit4 record | `tests/README.md` | 6.2.3 (header text stale, O5) |

**Godot patch update (4.7.x → 4.7.y).** Own commit/PR, never mixed with game work:
1. Bump `tools/godot/version.txt`, `godot-version`, VERSION.md; refresh
   `tools/godot/bin` through `setup.ps1`.
2. Re-run on a *fresh clone*, Windows and Linux: `--import` ×N (N ≥ 17, the sample
   size that exposed E6) recording exit-139 counts; the test suite for the exit
   matrix 0/100/101/105/1; `data_check.gd`; the parse check; all four exports with
   audit and smoke; the version-specific spikes whose results this repo recorded
   (S-0004, ADR-0005 A9, V-18-2).
3. Read the release notes for changes to export, `--import`, `FileAccess`, `user://`.
4. Compare `.godot/global_script_class_cache.cfg` before/after; commit it if changed.
**Godot minor (4.8):** not a patch update. Requires a superseding ADR (template
rule for HIGH risk) and a re-run of every spike.
**Freeze:** from S0 until the funding demo is delivered, Godot changes only for a
crash/regression fix that blocks the demo, with `technical-director` approval.

**gdUnit4 update.** Only when a Godot patch needs it, a bug blocks us, or a security
issue is reported — not for features. Replace `addons/gdUnit4/` wholesale from the
upstream release tag in a commit containing nothing else; **never edit addon files
in place** (a patched copy is an untracked fork). Check: runner exits 0/100/101/105
as in E8, the `127.0.0.1:0` noise unchanged, the 3+ tests pass on CI and locally, and
the upstream compatibility table (6.2.x lists up to 4.7.1; 4.7.2 not listed, yet
6.2.2 and 6.2.3 ran on it) for the pinned Godot. Record the tag in `tests/README.md`.

**Checks nobody automates: new upstream releases.** There is no Dependabot-style
watcher in this ADR; the devops owner checks both projects' releases at each
milestone gate (O11).

### D9. `.godot/` policy

1. `.godot/*` stays ignored **except** `global_script_class_cache.cfg`, which stays
   committed (E9). The exception is deliberate; the `.gitignore` comment explains it.
2. **No `actions/cache` of `.godot/`** in the slice. A fresh `--import` per run is
   the only state the export and tests are known to work from, and the project has
   almost no imported assets. Revisit when step 5 exceeds a threshold measured in
   O10. If a cache is ever added, its key must contain the Godot version, a hash of
   `project.godot` and of every source asset and `*.import`, and it must never be
   restored across a version change.
3. Step 6, `check_class_cache.sh`: after import, the committed cache file must equal
   the regenerated one. **Advisory until V-18-9** proves Windows and Linux produce
   identical files (ordering/line endings are NOT VERIFIED); then it becomes a
   blocking gate, which forces developers to commit a refreshed cache after adding a
   `class_name`. Exit criterion for "advisory": V-18-9 passes 5 consecutive runs.
4. A stale committed cache is not a CI blocker in step 5–11 because import
   regenerates it in the runner; the harm is a *developer's fresh clone* parsing
   wrongly, which step 6 targets.

### D10. Demo playtest record

Playtest builds (`playtest-*`) are the only ones that write the playtest log
(TR-puzzles-022); the demo never does. Collection and records:

1. **Machine log** — `PuzzlePlaytestLog` (ADR-0010 D16) writes to `user://`. Its
   first line **must** be the build identity of D5 (version, commit, preset). Format
   and fields are ADR-0010's; this ADR only adds the header line (O6).
2. **Human record** — one file per session, `production/qa/playtests/playtest-<YYYY-MM-DD>-<n>.md`, with: build artifact name + SHA-256, platform, tester code (no personal
   data), total time to finish (the slice's 15–30 min is "to be measured", slice-v0.3),
   puzzle table copied from the log, blockers, and a free-text section. The tester
   or the facilitator attaches the log file.
3. `tools/playtest/summarize_log.gd` may aggregate logs into a table for
   `production/qa/`. It is an observation helper: it prints numbers, never a verdict
   on whether a puzzle is "too hard".
4. A demo build that produces any log file named like the playtest log is a failed
   audit (covered by D4 patterns and the layer 3 smoke).
5. Screenshots required by the project's "run and observe" rule go to
   `production/qa/evidence/` (exists, `.gitkeep` only); CI neither produces nor
   judges them.

### D11. What is NOT automated

| Item | Why | Who/when |
|---|---|---|
| Visual fidelity, feel, atmosphere, glass/mirror shaders, flash safety (PEAT availability NOT VERIFIED) | `coding-standards`: not automated | playtest + `production/qa/evidence/` |
| A full playthrough of the exported demo | playtest territory | facilitator, per D10 |
| Running the Windows export | Linux runner cannot run it; no Windows runner decision made | manual on the dev machine before each tag; result in the tag's playtest record |
| Performance budgets (draw calls, ms, memory) | owned by ADR-0019/0020 per `architecture.md`; need target hardware | outside this ADR |
| Upstream release watching (Godot, gdUnit4, actions) | D8 | milestone gate |
| Publishing/distribution of the demo to funders | decision for `producer` and the user | manual |
| Signing, notarisation, store upload | not in slice scope (D1.1) | new ADR if needed |
| Promoting a build to a GitHub Release | needs `contents: write` and a human decision | manual, after the four legs are green |
| Accepting this ADR, merging `Accepted` | human only | user / `technical-director` |

## Alternatives Considered

### Alternative 1: Keep dev tools in production files behind `if flavor.is_debug()` (ADR-0005 D6.7 as written)
- **Description**: One class, dev branches inert in release.
- **Pros**: No layout rule; one file per system.
- **Cons**: Code ships in the demo, so "inexistente en el export" (TR-content-012,
  AC-21) and "excluida de la demo" (TR-save-022) are false by construction;
  depends on E5.
- **Estimated Effort**: Lower now, higher at demo audit.
- **Rejection Reason**: Contradicts three TRs; the audit has nothing to check except behaviour.

### Alternative 2: Per-system `dev/` folders (`src/core/data/dev/`)
- **Description**: Dev code beside its system.
- **Pros**: Locality.
- **Cons**: N exclusion patterns, N audit patterns, easy to forget one.
- **Estimated Effort**: Similar.
- **Rejection Reason**: One root makes the exclusion and the audit one line each.

### Alternative 3: Feature-tag based stripping (custom export features)
- **Description**: Mark dev scripts with a feature tag instead of a path filter.
- **Pros**: Could be expressed per-resource.
- **Cons**: Whether tags exclude files, not only gate behaviour, is NOT SOURCEABLE.
- **Estimated Effort**: Unknown.
- **Rejection Reason**: Cannot be sourced; path filters are the simpler mechanism to verify by bytes.

### Alternative 4: Export on every push
- **Description**: The four presets on every push and PR.
- **Pros**: Earliest detection; no path filter to maintain.
- **Cons**: Template download and four exports per push; unmeasured.
- **Estimated Effort**: Same to build.
- **Rejection Reason**: Not rejected on principle: tiered (D6) until O10 measures it; layer 1 runs on every push meanwhile.

### Alternative 5: Cache `.godot/` in CI
- **Description**: `actions/cache` on `.godot/`.
- **Pros**: Faster import; fewer exposures to the E6 crash.
- **Cons**: Cross-version stale state; unverified restore behaviour; the project has few assets, so the gain is small now.
- **Estimated Effort**: Low.
- **Rejection Reason**: Unproven benefit, real failure modes (D9.2).

### Alternative 6: Blanket retry on any CI failure
- **Description**: Re-run failed jobs automatically.
- **Pros**: Hides flakes.
- **Cons**: Hides real failures; violates "retry only a proven flake".
- **Estimated Effort**: Trivial.
- **Rejection Reason**: Only the documented 139-on-`--import` case is retried, once.

### Alternative 7: Replace the gdUnit4 action with the raw command
- **Description**: Run `GdUnitCmdTool.gd` directly, upload JUnit ourselves.
- **Pros**: One Godot install; exit code fully in our hands (settles V-18-4).
- **Cons**: Loses the action's check-run reporting that is already green; re-work.
- **Estimated Effort**: Medium.
- **Rejection Reason**: Not now. Reconsider if V-18-4 shows the action swallows 101.

## Consequences

### Positive
- "Absent from the demo" becomes a command with a positive control, not a promise.
- One dev root: reviewable in one glance; one exclusion line.
- Version and commit travel with every playtest log and bug report.
- Data cannot land unverified (absence rule) and the cheap gates run on every push.
- The import-crash flake is bounded and measured rather than hidden.

### Negative
- Amends ADR-0005 D6.7 and constrains ADR-0001, -0004, -0010, -0013 layouts (O1–O2).
- Dev tools must be written through hooks, which is more indirection.
- Export checks lag a push when only the path-filter job would have caught them.
- The Windows build is checked manually.
- Two Godot installs in the test job until Alternative 7 is revisited.

### Neutral
- `tests.yml` keeps its job name; `export.yml` is new; `export_presets.cfg` becomes tracked.

## Risks

| # | Risk | Mitigation |
|---|------|-----------|
| R1 | Byte scan sees no paths (encoding/compression/encryption of PCK), so the audit is blind | Positive control exits 2; V-18-6 before acceptance |
| R2 | `--export-*` or import crashes in CI (E6), Linux rate unknown | D6 retry rule + warnings; O9 |
| R3 | Templates unavailable/mismatched, install path unsourced | D2 hash-pinned; V-18-3 first |
| R4 | `OS.is_debug_build()` not what ADR-0005 assumes in exports | V-18-2; hooks use `BuildFlavor`, and D4 layer 2 does not rely on it |
| R5 | Windows export on Linux fails | D1.7 fallback to a Windows runner |
| R6 | Preset exclusion property semantics differ (E4) | V-18-5 reads the artifact, not the config |
| R7 | A dev script is referenced from production by a path the grep misses (string built at runtime) | Layer 2 only catches *shipped* files; layer 3 catches runtime attach; rule forbids built paths |
| R8 | Stale docs (`tests/README.md`) mislead | O5 |
| R9 | The green CI claim is the user's report, not a recorded run | Record the run id in tests/README.md when O5 is done |

## GDD Requirements Addressed

By range (provisional IDs from `docs/architecture/tr-baseline-provisional.md`;
`tr-registry.yaml` carries the same IDs). Because every ADR is `Proposed`, none of
these is "Covered" until this one is `Accepted`.

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| 3 Estado | TR-state-018 | D1/D3/D4: console in `src/dev/`, excluded from `demo-*`, byte audit + boot smoke (CA-29). Closes the part ADR-0001 deferred (G-11). Injectable log destination is ADR-0001's. |
| 5 Guardado | TR-save-022 | D3/D4 for the five tools and `request_save(&"dev")` (AC-44). Also takes `use_custom_user_dir` as a deferred decision (D1.6, ADR-0004 OI-10). |
| 18 Contenido | TR-content-012 | D3 moves the reload body out of production code (amends ADR-0005 D6.7); D4 proves absence. |
| 18 Contenido | TR-content-013 | D7 CI wiring of the verifier: exit codes, `--hito=calidad` at the demo. |
| 18 Contenido | TR-content-006, -014 | Run through `data_check.gd` in step 10 (checks themselves are ADR-0005 D8). |
| 9 Puzzles | TR-puzzles-021 | D6: fuzz/oracle tests are ordinary suite members with a fixed seed. |
| 9 Puzzles | TR-puzzles-022 | D3/D10: log only in `playtest-*`, absent in `demo-*`, identified by build version. |
| Tooling-domain test TRs | TR-puzzles-005, TR-settings-021, TR-scene-023, TR-director-027, TR-puzzle1-018, TR-puzzle2-017, TR-puzzle3-018, TR-pause-023, TR-title-018 | D6 step 11 (`tests` path, exit-code gate, zero-test guard); test locations follow `tests/unit/<system>/` and `tests/integration/<system>/` (this ADR does not write the tests). |
| 29 Shaders / 30 Accesibilidad | TR-shaders-008, TR-a11y-011 | Spike and luminance script live in `tools/`; nothing automated here beyond not shipping them (D1.2). A11y flash analysis tool availability stays NOT VERIFIED (D11). |
| ADR-0002 | D6 timer ban | `forbid_timers.sh` (step 9): fails on `create_timer(` or `Timer.new(` in any `.gd` outside `tests/` and `prototypes/`. ADR-0002's text does not cover `Timer` nodes in `.tscn`; proposed to extend (O12). |

Not addressed here and deferred to ADR-0019/0020 per `architecture.md`: performance
and memory budgets (TR-audio-021, TR-atmos-016, TR-shaders-009).

## Performance Implications
- **CPU/Memory (game)**: none; dev tools are absent from the demo, and attached in playtest builds only.
- **Load Time**: none expected; `DevTools.attach` is one `load()` in non-release flavor.
- **CI time**: NOT MEASURED. Test job gains import + parse + data check; export job adds templates + 4 exports (O10).
- **Network**: CI downloads Godot and templates once per run, hash-checked.

## Migration Plan

1. Remove `export_presets.cfg` and add `build/` in `.gitignore` (O7).
2. S0: install templates locally, create the four presets, run V-18-1…V-18-3,
   commit `export_presets.cfg`; set `commands.build`.
3. S0: add `tools/ci/` scripts, widen the tests path, add steps 3–9, create
   `export.yml`.
4. S0 "CI data gate": add `tools/data_check/` and step 10 (ADR-0005 rollout).
5. First dev tool story: create `src/dev/`, `DevTools.attach`, the marker; extend
   the layer 1 allowlist; ADR-0005 D6.7 amendment lands before ContentDB is coded.
6. Update `tests/README.md` (CI ran green; addon committed; version 6.2.3).
7. Before the funding demo: V-18-1…V-18-10 all recorded, Windows build run by hand.

**Rollback plan**: the CI additions are independent files/steps; each can be
reverted alone, leaving the existing test job intact. If the byte audit proves
blind (R1), fall back to layer 1 + layer 3 only and write that downgrade into an
amendment; do not ship the demo on a "provisional" audit.

## Validation Criteria

Run order matters: V-18-3 first, V-18-6 before acceptance. All are NOT RUN.

| ID | Check | Pass |
|----|-------|------|
| V-18-1 | Fresh clone, `export_presets.cfg` tracked, one-command local export of all four presets on Windows | four artifacts; each launches |
| V-18-2 | `BuildFlavor` value (`OS.is_debug_build()`) printed from editor run, `playtest-*` and `demo-*` (also ADR-0005 A9) | true / true / false |
| V-18-3 | Install templates of 4.7.2 locally and on the runner; record archive name and install folder; Windows export on Linux runner | exports succeed or R5 fallback adopted |
| V-18-4 | Add a test that leaks an orphan; confirm the action's job fails (exit 101); add a failing test, confirm failure; zero tests, confirm the guard fails | job red in each case |
| V-18-5 | Put a dummy file under `src/dev/` and a `class_name`-less script referenced only via `DevTools.attach`; export `demo-linux`; confirm the build runs and the file is absent; then add a `preload` from production code and confirm layer 1 fails | as stated |
| V-18-6 | Audit on `playtest-*` finds `src/dev/` and the marker; on `demo-*` finds none; temporarily remove the exclusion and see `demo-*` fail | positive control works, negative control fails |
| V-18-7 | Exported Linux binary runs `--headless` with `-- --boot-report` and prints the boot line; exit 0 | stdout and exit as D4 layer 3 |
| V-18-8 | Fresh-clone gate: delete `.godot/` but keep the committed class cache; import; parse check; data check; tests | all green; then remove the cache file and confirm the documented exit 1 |
| V-18-9 | Windows and Linux regenerate byte-identical `global_script_class_cache.cfg`, 5 runs | identical, then step 6 blocks |
| V-18-10 | Record import time, test job time, export job time, artifact size, retention setting | numbers in this ADR (replace "NOT MEASURED") |

**Test plan (tests this ADR needs, owned by `qa-lead`):**
`tests/unit/tools/check_dev_isolation_test.gd` over fixture trees (leak/clean);
`tests/unit/tools/forbid_timers_test.gd` (hit, test-dir exemption, tools included);
audit script fixtures: a directory containing the marker (demo → exit 1), a clean
one (exit 0), a playtest one without the marker (exit 2), an empty one (exit 2);
`check_pins.sh` fixture with a mismatched version (non-zero). Shell scripts are
tested by running them in CI on fixtures under `tests/fixtures/ci/`.

## Open Items

| ID | Item | Owner |
|----|------|-------|
| O1 | Amend ADR-0005 D6.7: hot-reload body moves to `src/dev/`, `ContentDB` keeps a hook; AC-21 stays satisfied by absence | technical-director → ADR-0005 author |
| O2 | ADR-0010 D16/reconciliation and ADR-0013 `HandsDebug`: place under `src/dev/`, no `class_name`; header line with build identity (D10.1) | lead-programmer |
| O3 | ADR-0009: `Boot` prints the `[boot] …` line on `--boot-report`; `DevTools.attach` in step 0/late | lead-programmer |
| O4 | ADR-0005: schema row for `assets/data/build/build-info.json` | technical-director |
| O5 | Update `tests/README.md` (CI green 2026-11-10 per user, addon committed, 6.2.3); record the run id | devops-engineer |
| O6 | Add `tools/godot/.gdignore` (ADR-0005 O9; not present) and make sure it does not affect the pinned wrapper | devops-engineer |
| O7 | `.gitignore` line 71 ignores `export_presets.cfg`; PLAN-TECNICO says presets in repo. Resolve by tracking the file | devops-engineer |
| O8 | Windows-on-Linux export: close with V-18-3 | devops-engineer |
| O9 | Measure Linux `--import` crash rate via retry annotations | devops-engineer |
| O10 | Measure times/sizes (V-18-10); set `timeout-minutes`, export triggering, cache revisit | devops-engineer |
| O11 | Milestone-gate check of upstream releases (D8) | devops-engineer |
| O12 | Propose extending ADR-0002 D6's ban to `Timer` nodes in `.tscn` | technical-director |

## Related

- Depends on / amends: ADR-0001 (G-11, CA-29), ADR-0004 (G-12, AC-44, OI-10, NS-8, NS-15), ADR-0005 (D6.7 **amended**, D8, A9, O9), ADR-0009 (Boot, `BuildFlavor`), ADR-0010 (D16), ADR-0013 (`HandsDebug`), ADR-0002 (D6).
- Contradictions with other documents: ADR-0005 D6.7 (compiled-but-inert reload vs TR-content-012); PLAN-TECNICO "presets en repo" vs `.gitignore` line 71; `tests/README.md` (stale CI/addon status); workflow `paths` vs `project.yaml` `commands.test`.
- `.github/workflows/tests.yml`, `project.yaml`, `docs/PLAN-TECNICO.md` § Build and S0, `docs/engine-reference/godot/current-best-practices.md` § Command Line, `docs/architecture/architecture.md` § Required ADRs (row ADR-0018), `docs/architecture/tr-baseline-provisional.md`, `docs/architecture/tr-registry.yaml`.
