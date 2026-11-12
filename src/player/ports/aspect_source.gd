## Port that gives the width / height ratio of the 3D view (ADR-0012 § Key Interfaces «AspectSource», D3).
## Production adapter: `ViewportAspectSource`; tests use fixed values. In M1 F5 does not exist (TR-player-008 deferred),
## so the Player only stores the port.
## Example: `class Fixed extends AspectSource: func aspect() -> float: return 16.0 / 9.0`.
@abstract
class_name AspectSource extends RefCounted

## Aspect used when the view has no height yet.
const FALLBACK_ASPECT: float = 16.0 / 9.0


## Width / height of the 3D view.
@abstract func aspect() -> float
