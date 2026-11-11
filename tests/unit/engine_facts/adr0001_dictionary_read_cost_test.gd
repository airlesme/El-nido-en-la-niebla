extends GdUnitTestSuite
# Verifica NS-2 de ADR-0001 en Godot 4.7.2 (V-ENG-2).
## 35 fact reads per step x 10,000 steps: Dictionary<StringName,Variant> vs indexed Array.
## Headless time on this machine is NOT a substitute for measuring with the running game.

const FACTS: int = 35
const STEPS: int = 10000
const BUDGET_MS_PER_STEP: float = 0.02


func _make_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for i: int in FACTS:
		keys.append(StringName("fact_%d" % i))
	return keys


func _ms_per_step_dictionary() -> float:
	var keys: Array[StringName] = _make_keys()
	var dict: Dictionary = {}
	for k: StringName in keys:
		dict[k] = 1
	var sink: int = 0
	var t0: int = Time.get_ticks_usec()
	for s: int in STEPS:
		for k: StringName in keys:
			sink += dict[k]
	var us: int = Time.get_ticks_usec() - t0
	return (float(us) / 1000.0) / float(STEPS) + (0.0 if sink >= 0 else 1.0)


func _ms_per_step_array() -> float:
	var values: Array = []
	for i: int in FACTS:
		values.append(1)
	var sink: int = 0
	var t0: int = Time.get_ticks_usec()
	for s: int in STEPS:
		for i: int in FACTS:
			sink += values[i]
	var us: int = Time.get_ticks_usec() - t0
	return (float(us) / 1000.0) / float(STEPS) + (0.0 if sink >= 0 else 1.0)


func test_get_fact_at_35_reads_per_step_under_budget() -> void:
	# Arrange / Act
	var ms: float = _ms_per_step_array()
	print("V-ENG-2 Array indexed: %.5f ms/step (budget %.3f)" % [ms, BUDGET_MS_PER_STEP])

	# Assert
	assert_float(ms).is_less(BUDGET_MS_PER_STEP)


func test_dictionary_stringname_35_reads_per_step_under_budget() -> void:
	# Arrange / Act
	var ms: float = _ms_per_step_dictionary()
	print("V-ENG-2 Dictionary<StringName>: %.5f ms/step (budget %.3f)" % [ms, BUDGET_MS_PER_STEP])

	# Assert
	assert_float(ms).is_less(BUDGET_MS_PER_STEP)
