extends GdUnitTestSuite
# Verifica NS-SP-1/SP-2/SP-3/SP-5/SP-6 de ADR-0007 en Godot 4.7.2 (parte headless).
## SP-1/SP-2 geometry: embedded Window in a SubViewport with content_scale_mode CANVAS_ITEMS, aspect EXPAND,
##   base 1920x1080, measured at 1280x720, 1920x1080, 2560x1440, 3840x2160, 1280x800, 1920x1200, 2560x1080
##   (logical visible rect and final-transform scale vs s = min(W/1920, H/1080)). Real window values: prototypes/ui-spike/.
## SP-3: Theme.set_default_font_size / set_font_size re-lays out a container by the next frame.
## SP-5: DisplayServer window mode get under the dummy display (set/Alt+Enter is NEEDS_WINDOWED).
## SP-6: JSON failure detection, NaN stringify, ints parsed as float (shared with ADR-0004/0005).
## SP-4 (AccessKit/Narrator) is NEEDS_MANUAL_SCREEN_READER.

const BASE: Vector2i = Vector2i(1920, 1080)
const SIZES: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160),
	Vector2i(1280, 800), Vector2i(1920, 1200), Vector2i(2560, 1080)]


func _stretch_window(size: Vector2i, aspect: Window.ContentScaleAspect, mode: Window.ContentScaleMode) -> Window:
	var host: SubViewport = SubViewport.new()
	host.size = Vector2i(4096, 2304)
	host.gui_embed_subwindows = true
	add_child(auto_free(host))
	var w: Window = Window.new()
	w.size = size
	w.content_scale_size = BASE
	w.content_scale_mode = mode
	w.content_scale_aspect = aspect
	host.add_child(w)
	return w


func test_canvas_items_expand_logical_rect_and_scale_match_min_formula() -> void:
	# Arrange / Act / Assert per size
	var worst_scale: float = 0.0
	var worst_logical: float = 0.0
	for sz: Vector2i in SIZES:
		var w: Window = _stretch_window(sz, Window.CONTENT_SCALE_ASPECT_EXPAND, Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)
		await get_tree().process_frame
		var s_exp: float = minf(float(sz.x) / 1920.0, float(sz.y) / 1080.0)
		var logical: Vector2 = w.get_visible_rect().size
		var scale: Vector2 = w.get_final_transform().get_scale()
		var logical_exp: Vector2 = Vector2(float(sz.x) / s_exp, float(sz.y) / s_exp)
		print("SP-1 window=", sz, " logical=", logical, " expected=", logical_exp, " scale=", scale, " s_exp=", s_exp)
		worst_scale = maxf(worst_scale, absf(scale.x - s_exp))
		worst_logical = maxf(worst_logical, maxf(absf(logical.x - logical_exp.x), absf(logical.y - logical_exp.y)))
	print("SP-1 worst scale err=", worst_scale, " worst logical err px=", worst_logical)

	# Assert
	assert_float(worst_scale).is_less(0.001)
	assert_float(worst_logical).is_less(1.0)


func test_16_10_keeps_width_1920_and_grows_height_to_1200() -> void:
	# Arrange
	var w: Window = _stretch_window(Vector2i(1920, 1200), Window.CONTENT_SCALE_ASPECT_EXPAND, Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)
	await get_tree().process_frame

	# Act
	var logical: Vector2 = w.get_visible_rect().size

	# Assert
	assert_vector(logical).is_equal_approx(Vector2(1920, 1200), Vector2(1.0, 1.0))


func test_21_9_keeps_height_1080_and_grows_width() -> void:
	# Arrange
	var w: Window = _stretch_window(Vector2i(2560, 1080), Window.CONTENT_SCALE_ASPECT_EXPAND, Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)
	await get_tree().process_frame

	# Act
	var logical: Vector2 = w.get_visible_rect().size

	# Assert
	assert_vector(logical).is_equal_approx(Vector2(2560, 1080), Vector2(1.0, 1.0))


func test_scale_mode_property_and_min_size_exist_and_roundtrip() -> void:
	# Arrange
	var w: Window = _stretch_window(Vector2i(1280, 720), Window.CONTENT_SCALE_ASPECT_EXPAND, Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)

	# Act
	w.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	w.min_size = Vector2i(1280, 720)
	w.size = Vector2i(800, 600)
	print("SP-2 stretch=", w.content_scale_stretch, " min_size=", w.min_size, " size after set 800x600 (embedded)=", w.size, " (OS-level minimum NEEDS_WINDOWED)")

	# Assert
	assert_int(w.content_scale_stretch).is_equal(Window.CONTENT_SCALE_STRETCH_FRACTIONAL)
	assert_vector(Vector2(w.min_size)).is_equal(Vector2(1280, 720))
	assert_bool(w.size.x >= 1280 and w.size.y >= 720).is_true()


func test_theme_font_size_change_relayouts_container_by_next_frame() -> void:
	# Arrange
	var theme: Theme = Theme.new()
	theme.set_default_font_size(32)
	var box: VBoxContainer = VBoxContainer.new()
	box.theme = theme
	var lab: Label = Label.new()
	lab.text = "Opcion de prueba"
	box.add_child(lab)
	add_child(auto_free(box))
	await get_tree().process_frame
	var h0: float = box.get_combined_minimum_size().y
	var w0: float = box.get_combined_minimum_size().x

	# Act
	var t0: int = Time.get_ticks_usec()
	theme.set_default_font_size(48)
	var cost_us: int = Time.get_ticks_usec() - t0
	await get_tree().process_frame
	var h1: float = box.get_combined_minimum_size().y
	var w1: float = box.get_combined_minimum_size().x
	print("SP-3 min size 32->48 (x1.5): ", Vector2(w0, h0), " -> ", Vector2(w1, h1), " set cost us=", cost_us, " box.size=", box.size)

	# Assert
	assert_float(h1).is_greater(h0 * 1.3)
	assert_float(w1).is_greater(w0 * 1.3)
	assert_int(cost_us).is_less(2000)


func test_display_server_window_mode_is_readable_under_headless() -> void:
	# Act
	var mode: int = DisplayServer.window_get_mode()
	var name: String = DisplayServer.get_name()
	print("SP-5 display=", name, " window_mode=", mode, " (set/Alt+Enter poll NEEDS_WINDOWED)")

	# Assert
	# The display server name is environment-dependent (headless locally, a real server on CI):
	# only the readable, non-negative window mode is asserted.
	assert_str(name).is_not_empty()
	assert_int(mode).is_greater_equal(0)


func test_json_parse_failure_is_detectable_without_exceptions() -> void:
	# Arrange
	var j: JSON = JSON.new()

	# Act
	var err: int = j.parse("{\"a\": 1,")

	# Assert
	assert_int(err).is_not_equal(OK)
	assert_int(j.get_error_line()).is_greater_equal(0)  # observed 0 for a one-line input (line is 0-based here)
	print("SP-6 parse err=", err, " msg='", j.get_error_message(), "'")


func test_json_nan_inf_and_int_as_float_behaviour_is_recorded() -> void:
	# Arrange
	var s_nan: String = JSON.stringify({"v": NAN})
	var s_inf: String = JSON.stringify({"v": INF})
	var back_nan: Variant = JSON.parse_string(s_nan)
	var back_int: Variant = JSON.parse_string("{\"n\": 3}")
	print("SP-6 stringify(NAN)=", s_nan, " stringify(INF)=", s_inf, " parse(nan-string)=", back_nan, " int parsed type=", typeof(back_int["n"]), " (TYPE_FLOAT=", TYPE_FLOAT, ")")

	# Assert: ints come back as float; NaN must never be trusted in a settings file
	assert_int(typeof(back_int["n"])).is_equal(TYPE_FLOAT)
	assert_bool(back_nan is Dictionary).is_true()
	assert_bool((back_nan as Dictionary)["v"] == null).is_true()  # NaN stringifies to null: not round-trippable


func test_json_null_and_string_nan_decode_cases_do_not_crash() -> void:
	# Arrange
	var cases: Array[String] = ["{\"v\": null}", "{\"v\": \"nan\"}", "{\"v\": NaN}", "{\"v\": 1e999}"]

	# Act
	var types: Array[int] = []
	for c: String in cases:
		var r: Variant = JSON.parse_string(c)
		types.append(typeof(r))
		print("SP-6 decode ", c, " -> ", r)

	# Assert: every case returns without a crash (value or null)
	assert_int(types.size()).is_equal(cases.size())
