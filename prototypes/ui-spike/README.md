# ui-spike (PROTOTYPE - NOT FOR PRODUCTION)

Status: concluded (2026-11-11). Findings: ADR-0016 / ADR-0007 `## Spike Results (2026-11-11)`.

## Hypothesis
ADR-0016 SP-16A + ADR-0007 SP-1/SP-3: under `canvas_items` + `expand` + `fractional` the dynamic font is
re-rasterised at the final size (crisp at 720p..2160p), logical viewport and scale follow `s = min(W/1920, H/1080)`,
and runtime `Theme.set_font_size` (text scale 1.00 / 1.50) re-lays out by the next frame.
No Atkinson font is in the repo yet: the engine's built-in default font stands in (dynamic, not MSDF).

## Run
One window per size; the engine captures its own frames (never the desktop):

    godot --path prototypes/ui-spike --resolution 1280x720 --write-movie <abs>/out.png --fixed-fps 30 --quit-after 12 -- --scale=1.0

Stdout prints `SPIKE ...` lines: window size, logical size, scale `s`, glyph cap-height in real px and the
anti-aliasing edge width. Pick one numbered PNG per size; delete the rest.

## How the per-size runs were done
`--write-movie` records at the project's `viewport_width x viewport_height`, not at the `--resolution` window size.
For each size a throwaway copy of this folder (outside the repo, scratchpad) had those two keys set to the target
size; `main.gd` forces `content_scale_size = 1920x1080` so the stretch geometry is the production one.
