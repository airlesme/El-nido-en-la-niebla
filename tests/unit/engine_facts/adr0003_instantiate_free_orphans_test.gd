extends GdUnitTestSuite
# Verifica NS-1..NS-3 de ADR-0003 en Godot 4.7.2 (S-0003-A).
## S-0003-A: instantiate/free x10 of a >= 50 node packed scene (3 bus-subscribing elements,
## one Area3D, a Player stub): node/orphan/object counts, queue_free timing, also with the tree
## paused. Engine-level fact only: the real SceneLoader/Shell do not exist yet (S0 stage).

const CYCLES: int = 10
const ElementScript: GDScript = preload("res://tests/unit/engine_facts/fixtures/scene_element_probe.gd")


class FakeBus extends Object:
	signal event_emitted


var _bus: FakeBus
var _packed: PackedScene


func before_test() -> void:
	_bus = FakeBus.new()
	Engine.set_meta(&"adr0003_bus", _bus)
	_packed = _build_packed_planta()


func after_test() -> void:
	get_tree().paused = false
	if Engine.has_meta(&"adr0003_bus"):
		Engine.remove_meta(&"adr0003_bus")
	if is_instance_valid(_bus):
		_bus.free()


func _build_packed_planta() -> PackedScene:
	var root: Node3D = Node3D.new()
	root.name = "Planta"
	for i: int in 60:
		var n: Node3D = Node3D.new()
		n.name = "Geo_%d" % i
		root.add_child(n)
		n.owner = root
	for i: int in 3:
		var e: Node3D = Node3D.new()
		e.set_script(ElementScript)
		e.name = "Element_%d" % i
		e.set("disconnect_on_exit", i < 2)  # element 2 relies on engine cleanup
		root.add_child(e)
		e.owner = root
	var zone: Area3D = Area3D.new()
	zone.name = "Zone"
	root.add_child(zone)
	zone.owner = root
	var cs: CollisionShape3D = CollisionShape3D.new()
	cs.shape = BoxShape3D.new()
	zone.add_child(cs)
	cs.owner = root
	var player: CharacterBody3D = CharacterBody3D.new()
	player.name = "PlayerStub"
	root.add_child(player)
	player.owner = root
	var ps: PackedScene = PackedScene.new()
	var err: int = ps.pack(root)
	root.free()
	assert_int(err).is_equal(OK)
	return ps


func _snapshot() -> Dictionary:
	return {
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"static_mem": Performance.get_monitor(Performance.MEMORY_STATIC),
		"subs": _bus.get_signal_connection_list(&"event_emitted").size(),
	}


## Runs CYCLES instantiate/queue_free loops. Returns {first, last, valid_at_u1 (Array[bool]), valid_at_u0}.
func _run_cycles(paused_during_free: bool) -> Dictionary:
	var slot: Node = auto_free(Node.new())
	add_child(slot)
	await get_tree().process_frame
	var baseline: Dictionary = _snapshot()
	var first: Dictionary = {}
	var valid_u0: Array[bool] = []
	var valid_u1: Array[bool] = []
	for c: int in CYCLES:
		var inst: Node = _packed.instantiate()
		slot.add_child(inst)
		await get_tree().process_frame
		if paused_during_free:
			get_tree().paused = true
		slot.remove_child(inst)
		inst.queue_free()
		valid_u0.append(is_instance_valid(inst))  # same frame as queue_free
		await get_tree().process_frame  # U+1
		valid_u1.append(is_instance_valid(inst))
		if paused_during_free:
			get_tree().paused = false
		if c == 0:
			first = _snapshot()
	await get_tree().process_frame
	return {"baseline": baseline, "first": first, "last": _snapshot(), "valid_u0": valid_u0, "valid_u1": valid_u1}


func test_ten_instantiate_free_cycles_return_to_baseline_without_orphans() -> void:
	# Arrange / Act
	var r: Dictionary = await _run_cycles(false)
	print("S-0003-A normal baseline=", r["baseline"], " cycle1=", r["first"], " cycle10=", r["last"])
	print("S-0003-A normal valid_at_same_frame=", r["valid_u0"], " valid_at_U+1=", r["valid_u1"])

	# Assert
	var first: Dictionary = r["first"]
	var last: Dictionary = r["last"]
	assert_int(int(last["nodes"])).is_equal(int(first["nodes"]))
	assert_int(int(last["orphans"])).is_equal(0)
	assert_int(int(last["subs"])).is_equal(int((r["baseline"] as Dictionary)["subs"]))
	assert_array(r["valid_u1"]).contains_exactly([false, false, false, false, false, false, false, false, false, false])


func test_ten_instantiate_free_cycles_with_tree_paused_return_to_baseline() -> void:
	# Arrange / Act
	var r: Dictionary = await _run_cycles(true)
	print("S-0003-A paused baseline=", r["baseline"], " cycle1=", r["first"], " cycle10=", r["last"])
	print("S-0003-A paused valid_at_same_frame=", r["valid_u0"], " valid_at_U+1=", r["valid_u1"])

	# Assert
	var first: Dictionary = r["first"]
	var last: Dictionary = r["last"]
	assert_int(int(last["nodes"])).is_equal(int(first["nodes"]))
	assert_int(int(last["orphans"])).is_equal(0)
	assert_int(int(last["subs"])).is_equal(int((r["baseline"] as Dictionary)["subs"]))
	assert_array(r["valid_u1"]).contains_exactly([false, false, false, false, false, false, false, false, false, false])


func test_object_and_static_memory_growth_over_ten_cycles_is_recorded() -> void:
	# Arrange / Act
	var r: Dictionary = await _run_cycles(false)
	var first: Dictionary = r["first"]
	var last: Dictionary = r["last"]
	var d_obj: int = int(last["objects"]) - int(first["objects"])
	var d_mem: float = float(last["static_mem"]) - float(first["static_mem"])
	print("S-0003-A OBJECT_COUNT delta(c1->c10)=", d_obj, " MEMORY_STATIC delta bytes=", d_mem)

	# Assert: no object leak across cycles
	assert_int(d_obj).is_equal(0)
