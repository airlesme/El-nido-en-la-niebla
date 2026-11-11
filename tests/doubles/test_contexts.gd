## Factory for contexts made only of doubles. Overrides replace single services (ADR-0009 D9).
## Nodes created here (FakeClock, FakeGameState) are NOT freed: pass them as overrides you
## auto_free(), or call free_nodes() on the context's nodes at the end of the suite.
## Example: `var ctx: ServiceContext = TestContexts.make({&"fatal": my_handler})`.
class_name TestContexts extends RefCounted


## Builds a frozen ServiceContext of doubles. Keys: &"logger", &"fatal", &"real_clock", &"clock", &"state", &"flavor".
static func make(overrides: Dictionary = {}) -> ServiceContext:
	var c: ServiceContext = ServiceContext.new()
	c.logger = overrides.get(&"logger", RecordingLog.new())
	c.flavor = overrides.get(&"flavor", BuildFlavor.new(true))
	c.real_clock = overrides.get(&"real_clock", FakeRealClock.new())
	c.fatal = overrides.get(&"fatal", RecordingFatalHandler.new())
	c.state = overrides.get(&"state", FakeGameState.new())
	c.clock = overrides.get(&"clock", FakeClock.new())
	# One line per field as each replaced class appears (ADR-0009 D9).
	c.freeze()
	return c
