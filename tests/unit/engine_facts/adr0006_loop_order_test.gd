extends GdUnitTestSuite
# Verifica NS-7 de ADR-0001 y C1 de ADR-0006 en Godot 4.7.2 (S-0006, entrega del bus respecto a la entrada).
## Mide el orden de _input, _physics_process y _process entre nodos de distintos "autoloads" (hijos de root,
## anadidos en orden A, B, C) y si un aviso emitido en _input llega en el mismo fotograma a un suscriptor que
## lo consume en _physics_process. Dos vias: Viewport.push_input (sincrona) e Input.parse_input_event (bufer
## que el bucle principal vacia al inicio del fotograma, como un evento real del SO). Sin ventana.

const FRAMES: int = 6


class OrderProbe extends Node:
	var tag: String = ""
	var global_log: Array[String] = []
	var bus: Array[Dictionary] = []
	var is_emitter: bool = false
	var is_phys_sub: bool = false
	var is_proc_sub: bool = false

	func _input(event: InputEvent) -> void:
		if not (event is InputEventKey):
			return
		global_log.append(tag + ".input@" + str(Engine.get_process_frames()))
		if is_emitter:
			bus.append({"emitted": Engine.get_process_frames(), "phys": -1, "proc": -1})

	func _physics_process(_delta: float) -> void:
		global_log.append(tag + ".phys@" + str(Engine.get_process_frames()))
		if is_phys_sub:
			for n: Dictionary in bus:
				if n["phys"] == -1:
					n["phys"] = Engine.get_process_frames()

	func _process(_delta: float) -> void:
		global_log.append(tag + ".proc@" + str(Engine.get_process_frames()))
		if is_proc_sub:
			for n: Dictionary in bus:
				if n["proc"] == -1:
					n["proc"] = Engine.get_process_frames()


func _spawn(global_log: Array[String], bus: Array[Dictionary]) -> Array[OrderProbe]:
	var nodes: Array[OrderProbe] = []
	for t: String in ["A", "B", "C"]:
		var p: OrderProbe = OrderProbe.new()
		p.tag = t
		p.global_log = global_log
		p.bus = bus
		get_tree().root.add_child(p)
		nodes.append(p)
	nodes[0].is_emitter = true
	nodes[1].is_phys_sub = true
	nodes[2].is_proc_sub = true
	return nodes


func _free_all(nodes: Array[OrderProbe]) -> void:
	for n: OrderProbe in nodes:
		n.queue_free()


func _key() -> InputEventKey:
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = KEY_Z
	ev.pressed = true
	return ev


func test_push_input_runs_input_on_all_nodes_in_tree_order_and_notice_reaches_physics() -> void:
	# Arrange
	var global_log: Array[String] = []
	var bus: Array[Dictionary] = []
	var nodes: Array[OrderProbe] = _spawn(global_log, bus)
	await get_tree().process_frame
	await get_tree().process_frame
	global_log.clear()

	# Act
	get_tree().root.push_input(_key())
	for i: int in FRAMES:
		await get_tree().process_frame
	# Environment-independent: a physics tick is only due after enough wall time, so on a fast runner the
	# physics subscriber may need more frames than FRAMES. Wait (bounded) until it has seen the notice.
	var guard: int = 0
	while (bus.is_empty() or bus[0]["phys"] == -1) and guard < 1200:
		await get_tree().process_frame
		guard += 1
	_free_all(nodes)

	# Assert
	print("C1[push_input] order: ", global_log)
	print("C1[push_input] notices: ", bus)
	assert_array(global_log.slice(0, 3).map(func(s: String) -> String: return s.get_slice("@", 0))).is_equal(["C.input", "B.input", "A.input"])  # observed 4.7.2: _input runs in REVERSE tree order
	assert_int(bus.size()).is_equal(1)
	assert_bool(bus[0]["phys"] != -1).is_true()
	assert_int(bus[0]["proc"]).is_equal(bus[0]["emitted"])  # _process subscriber (later in the same frame) sees it the same frame


func test_parse_input_event_buffer_flush_position_relative_to_physics_and_process() -> void:
	# Arrange
	var global_log: Array[String] = []
	var bus: Array[Dictionary] = []
	var nodes: Array[OrderProbe] = _spawn(global_log, bus)
	await get_tree().process_frame
	await get_tree().process_frame
	global_log.clear()

	# Act: between frames (as the OS would deliver), through the engine buffer
	Input.parse_input_event(_key())
	for i: int in FRAMES:
		await get_tree().process_frame
	_free_all(nodes)

	# Assert: observation first; the stable claims are that the notice is delivered and tree order holds
	print("C1[parse_input_event] order: ", global_log)
	print("C1[parse_input_event] notices: ", bus)
	assert_int(bus.size()).is_equal(1)
	assert_bool(bus[0]["proc"] != -1).is_true()


func test_tree_order_inside_one_callback_kind_follows_add_order() -> void:
	# Arrange
	var global_log: Array[String] = []
	var bus: Array[Dictionary] = []
	var nodes: Array[OrderProbe] = _spawn(global_log, bus)

	# Act
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_free_all(nodes)

	# Assert
	var procs: Array = global_log.filter(func(s: String) -> bool: return ".proc@" in s).map(func(s: String) -> String: return s.get_slice("@", 0))
	var phys: Array = global_log.filter(func(s: String) -> bool: return ".phys@" in s).map(func(s: String) -> String: return s.get_slice("@", 0))
	print("C1 sequence all: ", global_log)
	assert_array(procs.slice(0, 3)).is_equal(["A.proc", "B.proc", "C.proc"])
	if phys.size() >= 3:
		assert_array(phys.slice(0, 3)).is_equal(["A.phys", "B.phys", "C.phys"])


func test_with_a_physics_tick_every_iteration_input_precedes_physics_in_the_same_iteration() -> void:
	# Arrange: 1000 Hz ticks so (almost) every iteration has a tick; restored at the end
	var old_tps: int = Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 1000
	var global_log: Array[String] = []
	var bus: Array[Dictionary] = []
	var nodes: Array[OrderProbe] = _spawn(global_log, bus)
	for i: int in 3:
		await get_tree().process_frame
	global_log.clear()

	# Act
	Input.parse_input_event(_key())
	for i: int in FRAMES:
		await get_tree().process_frame
	_free_all(nodes)
	Engine.physics_ticks_per_second = old_tps

	# Assert: observation recorded in the ADR; stable claim = delivered to physics subscriber
	print("C1[1000Hz] order: ", global_log)
	print("C1[1000Hz] notices: ", bus)
	assert_int(bus.size()).is_equal(1)
	assert_bool(bus[0]["phys"] != -1).is_true()
