extends GdUnitTestSuite
## EB-014: Boot wires GameState (setup + catalog load) and hands out FactWriters.
## Uses the real assets/data/state/flags.json through the real FileStore; no window needed.

## ErrorPolicy double that records fail() calls and never quits the tree.
class SpyPolicy extends ErrorPolicy:
	var fails: Array[String] = []

	func fail(msg: String) -> void:
		fails.append(msg)

	func is_strict() -> bool:
		return true

var _log: RecordingLog
var _fatal: RecordingFatalHandler


func before_test() -> void:
	_log = RecordingLog.new()
	_fatal = RecordingFatalHandler.new()


func _ctx(debug: bool, files: FileStore, state: GameState) -> ServiceContext:
	var c: ServiceContext = ServiceContext.new()
	c.logger = _log
	c.flavor = BuildFlavor.new(debug)
	c.fatal = _fatal
	c.files = files
	c.state = state
	return c


func test_wire_state_real_catalog_debug_is_ready_with_20_facts() -> void:
	var state: GameState = auto_free(GameState.new())
	var ctx: ServiceContext = _ctx(true, FileStore.new(), state)

	var ok: bool = Boot.wire_state(ctx)

	assert_bool(ok).is_true()
	assert_int(state.get_status()).is_equal(GameState.Status.READY)
	assert_int(state.fact_count()).is_equal(20)
	assert_bool(_fatal.has_failed()).is_false()


func test_wire_state_real_catalog_release_is_ready() -> void:
	var state: GameState = auto_free(GameState.new())
	var ctx: ServiceContext = _ctx(false, FileStore.new(), state)

	var ok: bool = Boot.wire_state(ctx)

	assert_bool(ok).is_true()
	assert_int(state.get_status()).is_equal(GameState.Status.READY)
	assert_bool(_fatal.has_failed()).is_false()


func test_wire_state_missing_catalog_raises_fatal_and_stays_unloaded() -> void:
	var state: GameState = auto_free(GameState.new())
	var ctx: ServiceContext = _ctx(true, MemoryFileStore.new(), state)

	var ok: bool = Boot.wire_state(ctx)

	assert_bool(ok).is_false()
	assert_int(state.get_status()).is_equal(GameState.Status.UNLOADED)
	assert_int(_fatal.calls.size()).is_equal(1)
	assert_str(String(_fatal.calls[0][&"code"])).is_equal("CATALOGO_INVALIDO")


func test_wire_state_corrupt_catalog_raises_fatal_and_stays_unloaded() -> void:
	var store: MemoryFileStore = MemoryFileStore.new()
	store.put_text("res://assets/data/state/flags.json", "{ not json")
	var state: GameState = auto_free(GameState.new())
	var ctx: ServiceContext = _ctx(true, store, state)

	var ok: bool = Boot.wire_state(ctx)

	assert_bool(ok).is_false()
	assert_int(state.get_status()).is_equal(GameState.Status.UNLOADED)
	assert_str(String(_fatal.calls[0][&"code"])).is_equal("CATALOGO_INVALIDO")


func test_boot_writer_invalid_write_in_dev_calls_fail() -> void:
	var state: GameState = auto_free(GameState.new())
	var ctx: ServiceContext = _ctx(true, FileStore.new(), state)
	Boot.wire_state(ctx)
	var spy: SpyPolicy = SpyPolicy.new()
	state.set_error_policy(spy)
	var boot: Boot = auto_free(Boot.new())

	boot.writer_for_owner(9, ctx).write(&"pos_L", 99)

	assert_int(spy.fails.size()).is_equal(1)
	assert_int(state.get_fact(&"pos_L") as int).is_equal(2)


func test_boot_writer_for_owner_is_created_once_per_owner() -> void:
	var state: GameState = auto_free(GameState.new())
	var ctx: ServiceContext = _ctx(true, FileStore.new(), state)
	Boot.wire_state(ctx)
	var boot: Boot = auto_free(Boot.new())

	var first: FactWriter = boot.writer_for_owner(20, ctx)
	var again: FactWriter = boot.writer_for_owner(20, ctx)
	var other: FactWriter = boot.writer_for_owner(22, ctx)

	assert_bool(first == again).is_true()
	assert_bool(first == other).is_false()
