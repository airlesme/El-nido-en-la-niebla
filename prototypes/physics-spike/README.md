# physics-spike (PROTOTYPE - NOT FOR PRODUCTION)

Status: in-progress. Headless numeric parts are done as gdUnit4 tests in
`tests/unit/engine_facts/adr0011_*`, `adr0003_*`, `adr0012_*`. This project holds only what needs a window.

## Hypotheses (NEEDS_WINDOWED)
- ADR-0011 S-0011-C: logical viewport height under `canvas_items`/`expand` at 1920x1080, 1920x1200, 2560x1600; a rendered 0,10 m quad at 0,35 m matches `ViewMetrics` within +-2 px.
- ADR-0012 S-0012-A/B: eye X per frame while walking at caps 30/60/144/uncapped (interpolation fraction from the engine); FOV axis at resized windows (16:9, 4:3, 21:9, 32:9); 15,1 s corridor walk (AC-06).

## Run
Windowed (not headless), one run per size and cap:

    godot --path prototypes/physics-spike --resolution 1920x1200 -- --fps=144 --seconds=3
    godot --path prototypes/physics-spike --resolution 2560x1600 -- --fps=30

Read the printed `window=`, `logical viewport=`, `rendered quad height px=` and the per-frame lines
(`ticks=`, `dx=`: dx must be about 1,6 m/s * dt and monotonic). Resize the window by hand for the aspect cases.

## Findings
Not run yet (needs a display). Record results in ADR-0011 / ADR-0012 `## Spike Results (2026-11-11)`.
