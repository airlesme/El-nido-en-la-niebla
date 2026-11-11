# Test Infrastructure

**Engine**: Godot 4.7 (4.7.2 installed locally and pinned in CI)
**Test Framework**: GdUnit4 6.2.3 (installed in `addons/gdUnit4/`; 3 example tests PASS with Godot 4.7.2 headless on 2026-11-10; CI not yet run on GitHub)
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-11-10

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Installing GdUnit4

The addon is not committed. Until `addons/gdUnit4/` is committed, no test can
run locally or in CI (the workflow's preflight step fails on purpose).

1. Open Godot -> Asset Store (AssetLib before Godot 4.7) -> search "GdUnit4" -> install it
2. Enable the plugin: Project -> Project Settings -> Plugins -> GdUnit4
3. Restart the editor
4. Verify `res://addons/gdUnit4/bin/GdUnitCmdTool.gd` exists (capital U)
5. Commit `addons/gdUnit4/` (CI uses `version: installed`, i.e. the committed copy)

**Compatible version**: `.claude/skills/test-setup/references/3-directories.md`
records gdUnit4 6.2.2 as verified with Godot 4.7.2. This was NOT VERIFIED
independently for this repo (no network access during setup): confirm it when
installing, then record the version here. It is deliberately not pinned.

Installing the addon edits `project.godot` (`[editor_plugins]` enabling it); that
change is made by the editor, not by this setup.

## Running Tests

```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

Local Godot: `C:\Users\airlesme\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe`
(not part of the repo; `godot` is not on PATH locally).

Exit codes: 0 all pass, 100 a test failed, 101 passed but leaked nodes (warning),
103/104 gdUnit4 could not run, 105 a test script does not parse, 1 the runner
failed to load (no `.godot/` cache or addon missing). `No test cases found` with
exit 0 is NOT a pass. Two `ERROR:` lines about `127.0.0.1:0` are expected.

## Test Naming

File `[system]_[feature]_test.gd`, function `test_[scenario]_[expected]`
(`.claude/rules/test-standards.md`). Example tests live in
`tests/unit/example/` and `tests/integration/example/`; delete them once real
tests exist.

## Story Type -> Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Retained screenshot of each screen touched | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run on every push to `main` and every pull request. A failed suite blocks
merging. The workflow has not been executed yet.


## Verified 2026-11-10

GdUnit4 **6.2.3** (`godot-gdunit-labs/gdUnit4`, tag v6.2.3, copied from the source `addons/gdUnit4`) runs on Godot 4.7.2.stable: `Overall Summary: 3 test cases | 0 errors | 0 failures | 0 orphans`, exit code 0. The line `Remote Debugger: Unable to connect to host '127.0.0.1:0'` printed by the documented command is expected noise (port 0) and does not affect the result. The addon is not enabled in `project.godot` (the command-line tool works without it).

## CI run (declared)

Last green run reported by the developer on 2026-11-11: https://github.com/airlesme/El-nido-en-la-niebla/actions/runs/42980040179. Not independently verified: the repository is private (the public GitHub API returns 404) and no `gh` is available here.
