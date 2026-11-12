extends GdUnitTestSuite
## T-I4: ZoneHub + ZoneTrigger against real Area3D under Jolt (AC-05a, AC-05b). No window.

const SENSOR_RADIUS: float = 0.05
const INSIDE: Vector3 = Vector3(9.5, 0.0, 0.0)
const OUTSIDE: Vector3 = Vector3(0.0, 0.0, 0.0)

var _root: Node3D
var _hub: ZoneHub
## Each element: {id: StringName, tick: int}
var _notices: Array[Dictionary] = []


func before_test() -> void:
	_notices = []
	_root = auto_free(Node3D.new())
	add_child(_root)
	_hub = ZoneHub.new()
	_root.add_child(_hub)
	var sink: Array[Dictionary] = _notices
	_hub.configure(func(notice: StringName, payload: Dictionary) -> void:
		if notice == NoticeIds.ZONE_ENTERED:
			sink.append({"id": payload[&"zona"], "tick": Engine.get_physics_frames()}))


func after_test() -> void:
	_notices = []
	_hub = null
	_root = null


func _make_zone(id: StringName, center: Vector3) -> ZoneTrigger:
	var zone: ZoneTrigger = ZoneTrigger.new()
	zone.zone_id = id
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.0, 2.0, 0.8)
	cs.shape = box
	zone.add_child(cs)
	zone.position = center
	_root.add_child(zone)
	_hub.register(zone)
	return zone


func _make_sensor(pos: Vector3) -> Area3D:
	var s: Area3D = Area3D.new()
	s.collision_layer = ZoneTrigger.LAYER_ZONE_SENSOR
	s.collision_mask = 0
	s.monitoring = false
	s.monitorable = true
	var cs: CollisionShape3D = CollisionShape3D.new()
	var sp: SphereShape3D = SphereShape3D.new()
	sp.radius = SENSOR_RADIUS
	cs.shape = sp
	s.add_child(cs)
	s.position = pos
	_root.add_child(s)
	return s


func _ticks(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func test_enter_exit_enter_emits_twice_with_same_id() -> void:
	# Arrange
	_make_zone(&"T-PAS-1", INSIDE)
	var sensor: Area3D = _make_sensor(OUTSIDE)
	_hub.set_enabled(true)
	await _ticks(3)

	# Act
	sensor.position = INSIDE
	await _ticks(4)
	sensor.position = OUTSIDE
	await _ticks(4)
	sensor.position = INSIDE
	await _ticks(4)

	# Assert
	assert_int(_notices.size()).is_equal(2)
	assert_str(String(_notices[0]["id"])).is_equal("T-PAS-1")
	assert_str(String(_notices[1]["id"])).is_equal("T-PAS-1")


func test_overlapping_zones_entered_together_emit_in_id_order() -> void:
	# Arrange: T-PAS-2 registered first on purpose
	_make_zone(&"T-PAS-2", INSIDE)
	_make_zone(&"T-PAS-1", INSIDE)
	var sensor: Area3D = _make_sensor(OUTSIDE)
	_hub.set_enabled(true)
	await _ticks(3)

	# Act
	sensor.position = INSIDE
	await _ticks(4)

	# Assert
	assert_int(_notices.size()).is_equal(2)
	assert_str(String(_notices[0]["id"])).is_equal("T-PAS-1")
	assert_str(String(_notices[1]["id"])).is_equal("T-PAS-2")


func test_spawn_inside_emits_only_after_enable_in_a_later_tick() -> void:
	# Arrange: sensor already inside, hub disabled ("black wait")
	_make_zone(&"T-D-OUT", INSIDE)
	_make_sensor(INSIDE)
	await _ticks(6)
	var before: int = _notices.size()

	# Act
	var enable_tick: int = Engine.get_physics_frames()
	_hub.set_enabled(true)
	await _ticks(6)

	# Assert
	assert_int(before).is_equal(0)
	assert_int(_notices.size()).is_equal(1)
	assert_int(int(_notices[0]["tick"])).is_greater(enable_tick)


func test_disabling_hub_stops_new_entries() -> void:
	# Arrange
	_make_zone(&"T-PAS-1", INSIDE)
	var sensor: Area3D = _make_sensor(OUTSIDE)
	_hub.set_enabled(true)
	await _ticks(3)
	_hub.set_enabled(false)

	# Act
	sensor.position = INSIDE
	await _ticks(4)

	# Assert
	assert_int(_notices.size()).is_equal(0)
	assert_bool(_hub.is_enabled()).is_false()


func test_zone_registered_after_enable_inherits_monitoring() -> void:
	# Arrange / Act
	_hub.set_enabled(true)
	var zone: ZoneTrigger = _make_zone(&"T-LATE", INSIDE)

	# Assert
	assert_bool(zone.monitoring).is_true()
	assert_int(zone.collision_mask).is_equal(ZoneTrigger.LAYER_ZONE_SENSOR)
