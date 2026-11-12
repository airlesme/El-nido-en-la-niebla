## Port that names the floor surface under the Player (ADR-0012 § Key Interfaces «SurfaceProbe», D10).
## Production adapter: reads `get_slide_collision(i).get_collider().get_meta("surface")` (S-0012-C NP-8, C-R24);
## unit tests use a fake. Example: `class Fake extends SurfaceProbe: func floor_surface() -> StringName: return &"wood"`.
@abstract
class_name SurfaceProbe extends RefCounted

## Surface used when the floor carries no `surface` metadata (the only value in the slice, GDD 2 OQ 6).
const DEFAULT_SURFACE: StringName = &"default"


## Label of the floor under the Player; `&"default"` when unlabelled.
@abstract func floor_surface() -> StringName
