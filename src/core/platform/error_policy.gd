## "Dev halts, release continues" seam (ADR-0001 Key Interfaces, G-8).
## Base class is inert (never strict); the production implementation is ErrorPolicyDefault.
## Example: `ctx.errors.fail("invalid write")` stops a dev build, does nothing in release.
class_name ErrorPolicy extends RefCounted


## Dev: report and stop execution. Release: no-op.
func fail(_msg: String) -> void:
	return


## True in dev builds, where `fail()` stops execution.
func is_strict() -> bool:
	return false
