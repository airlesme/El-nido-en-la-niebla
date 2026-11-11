## Test double for RealClock: time is set by the test (ADR-0009 D9).
class_name FakeRealClock extends RealClock

var ms: int = 0


func now_ms() -> int:
	return ms
