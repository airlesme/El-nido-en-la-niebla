extends GdUnitTestSuite
# Verifica NS-4 y NS-5 de ADR-0003 en Godot 4.7.2 (S-0003-B).
## S-0003-B: box Area3D zone (T-PAS-1, X 9.0-10.0) vs 0.05 m SphereShape3D sensor moved at 1.6 m/s
## along +X at 60 Hz under Jolt: entry centre X range, doubles/misses, simultaneous entries,
## late `monitoring = true` with the sensor already inside, identical results at 30/60/144 fps.

const SENSOR_RADIUS: float = 0.05
const SPEED: float = 1.6
const TICK_DT: float = 1.0 / 60.0
const ZONE_FACE_X: float = 9.0
const LANES: int = 100
## ADR-0003 claims entry centre X in [8.923, 8.95]. Observed on 4.7.2: (8.95, 8.95 + one tick step],
## i.e. the first tick AFTER the sphere surface touches the face at X 9.0. The ADR range is recorded
## as FAIL in ADR-0003 § Spike Results; the asserts below pin the observed band.
const ADR_RANGE_LO: float = 8.923
const ADR_RANGE_HI: float = 8.95
const TOUCH_X: float = ZONE_FACE_X - SENSOR_RADIUS
const BAND_LO: float = TOUCH_X - 1e-4
const BAND_HI: float = TOUCH_X + SPEED * TICK_DT + 1e-4
const LAYER_ZONE_SENSOR: int = 1 << 5  # layer bit 6, arbitrary name "zone_sensor" for the spike
const LAYER_ZONE: int = 1 << 6


class Mover extends Node:
	var sensors: Array[Area3D] = []
	var active: bool = true

	func _physics_process(_delta: float) -> void:
		if not active:
			return
		for s: Area3D in sensors:
			s.position.x += 1.6 / 60.0


func _make_zone(center: Vector3, size: Vector3, node_name: String) -> Area3D:
	var zone: Area3D = Area3D.new()
	zone.name = node_name
	zone.collision_layer = 0
	zone.collision_mask = LAYER_ZONE_SENSOR
	zone.monitoring = true
	zone.monitorable = false
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	zone.add_child(cs)
	zone.position = center
	return zone


func _make_sensor(pos: Vector3) -> Area3D:
	var s: Area3D = Area3D.new()
	s.collision_layer = LAYER_ZONE_SENSOR
	s.collision_mask = 0
	s.monitoring = false
	s.monitorable = true
	var cs: CollisionShape3D = CollisionShape3D.new()
	var sp: SphereShape3D = SphereShape3D.new()
	sp.radius = SENSOR_RADIUS
	cs.shape = sp
	s.add_child(cs)
	s.position = pos
	return s


## 100 lanes in parallel, each with its own tick phase. Returns {entries: Array[float], per_lane: Array[int], ticks: Array[int]}.
func _run_crossings() -> Dictionary:
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	var mover: Mover = Mover.new()
	root.add_child(mover)
	var entries: Array[float] = []
	var per_lane: Array[int] = []
	var ticks: Array[int] = []
	per_lane.resize(LANES)
	per_lane.fill(0)
	for k: int in LANES:
		var z: float = float(k) * 1.0
		var zone: Area3D = _make_zone(Vector3(9.5, 0.0, z), Vector3(1.0, 2.0, 0.8), "T-PAS-1_%d" % k)
		var phase: float = float(k) / float(LANES) * SPEED * TICK_DT
		var sensor: Area3D = _make_sensor(Vector3(8.0 + phase, 0.0, z))
		root.add_child(zone)
		root.add_child(sensor)
		mover.sensors.append(sensor)
		zone.area_entered.connect(func(_a: Area3D) -> void:
			entries.append(sensor.position.x)
			per_lane[k] += 1
			ticks.append(Engine.get_physics_frames()))
	var start_frames: int = Engine.get_physics_frames()
	while Engine.get_physics_frames() - start_frames < 90:  # 1.5 s: 1.6 m/s covers 2.4 m, > 1 m needed
		await get_tree().physics_frame
	mover.active = false
	await get_tree().physics_frame
	return {"entries": entries, "per_lane": per_lane, "ticks": ticks}


func _summarize(r: Dictionary) -> Dictionary:
	var entries: Array[float] = r["entries"]
	var lo: float = INF
	var hi: float = -INF
	var out_of_range: int = 0
	var out_of_adr_range: int = 0
	for x: float in entries:
		lo = minf(lo, x)
		hi = maxf(hi, x)
		if x < BAND_LO or x > BAND_HI:
			out_of_range += 1
		if x < ADR_RANGE_LO - 1e-4 or x > ADR_RANGE_HI + 1e-4:
			out_of_adr_range += 1
	var doubles: int = 0
	var misses: int = 0
	for n: int in (r["per_lane"] as Array[int]):
		if n > 1:
			doubles += 1
		if n == 0:
			misses += 1
	return {"count": entries.size(), "min_x": lo, "max_x": hi, "out_of_touch_band": out_of_range, "out_of_adr_range": out_of_adr_range, "doubles": doubles, "misses": misses}


func test_hundred_crossings_enter_once_in_first_tick_after_surface_touch() -> void:
	# Arrange / Act
	var r: Dictionary = await _run_crossings()
	var s: Dictionary = _summarize(r)
	print("S-0003-B 100 crossings: ", s)

	# Assert
	assert_int(int(s["count"])).is_equal(LANES)
	assert_int(int(s["doubles"])).is_equal(0)
	assert_int(int(s["misses"])).is_equal(0)
	assert_int(int(s["out_of_touch_band"])).is_equal(0)


func test_two_zones_with_coincident_faces_report_in_the_same_physics_tick() -> void:
	# Arrange
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	var mover: Mover = Mover.new()
	root.add_child(mover)
	var stamps: Dictionary = {}
	var order: Array[String] = []
	for zname: String in ["T-B", "T-A"]:  # added B first on purpose
		var zone: Area3D = _make_zone(Vector3(9.5, 0.0, 0.0), Vector3(1.0, 2.0, 0.8), zname)
		root.add_child(zone)
		zone.area_entered.connect(func(_a: Area3D) -> void:
			stamps[zname] = Engine.get_physics_frames()
			order.append(zname))
	var sensor: Area3D = _make_sensor(Vector3(8.0, 0.0, 0.0))
	root.add_child(sensor)
	mover.sensors.append(sensor)

	# Act
	var start: int = Engine.get_physics_frames()
	while Engine.get_physics_frames() - start < 70:
		await get_tree().physics_frame
	print("S-0003-B coincident faces: stamps=", stamps, " callback order=", order)

	# Assert
	assert_int(stamps.size()).is_equal(2)
	assert_int(int(stamps["T-A"])).is_equal(int(stamps["T-B"]))


func test_enabling_monitoring_with_sensor_already_inside_reports_one_entry_within_two_ticks() -> void:
	# Arrange: sensor inside the zone, zone monitoring off
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	var zone: Area3D = _make_zone(Vector3(9.5, 0.0, 0.0), Vector3(1.0, 2.0, 0.8), "T-LATE")
	zone.monitoring = false
	var sensor: Area3D = _make_sensor(Vector3(9.5, 0.0, 0.0))
	root.add_child(zone)
	root.add_child(sensor)
	var entry_frames: Array[int] = []
	zone.area_entered.connect(func(_a: Area3D) -> void: entry_frames.append(Engine.get_physics_frames()))
	for i: int in 5:
		await get_tree().physics_frame
	var count_before: int = entry_frames.size()

	# Act
	var enable_frame: int = Engine.get_physics_frames()
	zone.monitoring = true
	for i: int in 6:
		await get_tree().physics_frame
	var deltas: Array[int] = []
	for f: int in entry_frames:
		deltas.append(f - enable_frame)
	print("S-0003-B late monitoring: entries_before_enable=", count_before, " entries_after=", entry_frames.size(), " ticks_after_enable=", deltas)

	# Assert
	assert_int(count_before).is_equal(0)
	assert_int(entry_frames.size()).is_equal(1)
	assert_int(deltas[0]).is_less_equal(2)


func test_results_are_identical_at_30_60_and_144_fps_with_physics_at_60_hz() -> void:
	# Arrange
	var summaries: Array[Dictionary] = []
	var xs_by_rate: Array[Array] = []
	var original_fps: int = Engine.max_fps

	# Act
	for fps: int in [30, 60, 144]:
		Engine.max_fps = fps
		var r: Dictionary = await _run_crossings()
		summaries.append(_summarize(r))
		var xs: Array = (r["entries"] as Array[float]).duplicate()
		xs.sort()
		xs_by_rate.append(xs)
	Engine.max_fps = original_fps
	print("S-0003-B fps 30: ", summaries[0], "\nS-0003-B fps 60: ", summaries[1], "\nS-0003-B fps 144: ", summaries[2])
	var identical_30: bool = xs_by_rate[0] == xs_by_rate[1]
	var identical_144: bool = xs_by_rate[2] == xs_by_rate[1]
	print("S-0003-B sorted entry X identical 30==60: ", identical_30, " 144==60: ", identical_144)

	# Assert
	for s: Dictionary in summaries:
		assert_int(int(s["count"])).is_equal(LANES)
		assert_int(int(s["doubles"])).is_equal(0)
		assert_int(int(s["out_of_touch_band"])).is_equal(0)
	assert_bool(identical_30).is_true()
	assert_bool(identical_144).is_true()
