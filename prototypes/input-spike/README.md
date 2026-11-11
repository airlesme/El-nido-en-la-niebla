# input-spike (PROTOTYPE - NOT FOR PRODUCTION)

Minimal harness for the parts of ADR-0006 spikes S-0006-A..E that need a physical pad or a real window.
The synthetic part runs in CI: `tests/unit/engine_facts/adr0006_*`. Not needed to run the game.

Run: `<godot> --path prototypes/input-spike` (windowed, 4.7.2). Output goes to stdout and
`user://input_spike.log`. Keys: `P` pause toggle, `C`/`V`/`H` mouse captured/visible/hidden, `Esc` quit.

| Spike | Do | Record |
|---|---|---|
| S-0006-A | Leave an Xbox-layout pad and a PlayStation pad untouched 5 s, then move sticks. Press A/south, B/east, Start. Hold a key. | resting `|value|` per axis (<= 0,05?), button index of south/east/start, `echo=true` lines while holding a key |
| S-0006-B | Start the harness with the pad plugged in (`START pad` line) | `name` and `guid` for DualSense, DualShock 4, Xbox |
| S-0006-C | Unplug/replug the pad, with and without `P` pause | `joy_connection_changed` lines; disconnect seen <= 0,5 s in both states |
| S-0006-D | `C`, move the mouse 200 px; repeat at `--resolution 1920x1080` and `--resolution 2560x1440`. Press `C`, Alt-Tab away and back, check `mode=` | `relative` sum vs real motion at both sizes; mode after return |
| S-0006-E | Alt-Tab away with and without `P` | exactly one `FOCUS_OUT` per loss |

Without a pad only S-0006-D and S-0006-E apply.
