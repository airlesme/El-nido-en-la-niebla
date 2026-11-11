# bus-spike (ADR-0001 V-ENG-4)

PROTOTYPE - NOT FOR PRODUCTION

**Hypothesis (NS-4):** which of `assert`, `OS.is_debug_build()`, `push_error` stops execution in a
debug build and is a no-op in a release export.

**Run:** from this folder, with Godot 4.7.2:

```
godot --headless --path . --import
godot --headless --path . --export-release "demo-windows" build/demo-windows/bus-spike.exe
godot --headless --path . --export-debug   "demo-windows" build/debug/bus-spike-debug.exe
build/demo-windows/bus-spike.exe --headless
build/debug/bus-spike-debug.exe --headless
```

Separate project on purpose: the root `project.godot` is untouched. `build/` and `.godot/` are ignored.

**Status:** concluded (2026-11-11, 4.7.2.stable.official.ed1daf0bf, Windows x86_64).

## Findings (observed)

| Call | Release export | Debug export / editor headless (no debugger attached) |
|---|---|---|
| `OS.is_debug_build()` | `false` (`has_feature("release")` true) | `true` |
| `push_error(...)` | logs `ERROR:` to stderr, execution continues | logs with GDScript backtrace, execution continues |
| `assert(false, msg)` | **stripped: no-op, code after it runs** | `SCRIPT ERROR: Assertion failed`, aborts the **current function only**; the caller continues (the debugger would pause only with an editor attached) |

Consequences for `ErrorPolicy`: `assert` is the only call that is dev-only by itself, but in a headless
or exported-debug run it does not stop the process; a real "dev halt" needs an explicit
`get_tree().quit(1)` (or the debugger) behind `OS.is_debug_build()`. `push_error` never halts anywhere,
so it is the release logging path. Pause-on-assert in the editor was not testable here (no editor session).
