## Real-time source (unscaled, monotonic within a session). ADR-0002 Key Interfaces.
## Tests use a subclass that overrides now_ms() (FakeRealClock).
class_name RealClock extends RefCounted


## Milliseconds since an arbitrary origin.
func now_ms() -> int:
	return Time.get_ticks_msec()
