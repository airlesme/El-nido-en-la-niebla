extends SceneTree
## Child-process probe for V-ENG-5 (run by adr0001_callback_error_test.gd, not a test itself).
## Isolated in its own process because gdUnit4 reports any script error as a test error.


class Probe:
	var log: Array[String] = []

	func ok(tag: String) -> void:
		log.append(tag)

	func bad(tag: String) -> void:
		log.append(tag + ":before")
		var nothing = null
		nothing.nonexistent_method()
		log.append(tag + ":after")


func _init() -> void:
	var probe: Probe = Probe.new()
	var queue: Array[Callable] = [probe.ok.bind("a"), probe.bad.bind("b"), probe.ok.bind("c")]
	var bound: int = queue.size()
	var i: int = 0
	while i < bound:
		queue[i].call()
		i += 1
	print("PROBE_RESULT log=", ",".join(probe.log), " reached_end=", i == bound)
	quit()
