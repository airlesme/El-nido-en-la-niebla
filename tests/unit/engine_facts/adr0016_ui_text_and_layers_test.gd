extends GdUnitTestSuite
# Verifica NS-SP-16B/16C/16D/16E de ADR-0016 en Godot 4.7.2 (parte headless).
## SP-16B: CanvasLayer.layer / process_mode (ALWAYS vs PAUSABLE) under tree pause; viewport visible rect.
## SP-16C: InputEvent.is_echo(), is_action_pressed(allow_echo), accept_event() vs native focus move.
## SP-16D: RichTextLabel.add_image signature and ImageUnit member names (via ClassDB).
## SP-16E: Label.get_line_count() with the headless text server (recorded, may be NEEDS_WINDOWED).
## SP-16A (font crispness) is NEEDS_WINDOWED: prototypes/ui-spike/.

class _Counter extends Node:
	var n: int = 0
	func _process(_d: float) -> void:
		n += 1


class _AcceptingButton extends Button:
	var seen: int = 0
	func _gui_input(event: InputEvent) -> void:
		if event.is_action_pressed(&"ui_right"):
			seen += 1
			accept_event()


func test_canvas_layer_layer_is_settable_and_readable_in_order() -> void:
	# Arrange
	var layers: Array[int] = [0, 5, 10, 20, 90]
	var nodes: Array[CanvasLayer] = []

	# Act
	for l: int in layers:
		var cl: CanvasLayer = CanvasLayer.new()
		cl.layer = l
		add_child(auto_free(cl))
		nodes.append(cl)

	# Assert
	for i: int in layers.size():
		assert_int(nodes[i].layer).is_equal(layers[i])
	print("SP-16B CanvasLayer.layer round-trip OK for ", layers)


func test_always_layer_runs_and_pausable_layer_freezes_under_tree_pause() -> void:
	# Arrange
	var always_layer: CanvasLayer = CanvasLayer.new()
	always_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var pausable_layer: CanvasLayer = CanvasLayer.new()
	pausable_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	var c_always: _Counter = _Counter.new()
	var c_pausable: _Counter = _Counter.new()
	always_layer.add_child(c_always)
	pausable_layer.add_child(c_pausable)
	add_child(auto_free(always_layer))
	add_child(auto_free(pausable_layer))
	await get_tree().process_frame
	await get_tree().process_frame

	# Act
	get_tree().paused = true
	var a0: int = c_always.n
	var p0: int = c_pausable.n
	for i: int in 5:
		await get_tree().process_frame
	var a1: int = c_always.n
	var p1: int = c_pausable.n
	get_tree().paused = false
	print("SP-16B under pause: always ", a0, "->", a1, " pausable ", p0, "->", p1)

	# Assert
	assert_int(a1 - a0).is_greater_equal(4)
	assert_int(p1 - p0).is_equal(0)


func test_child_layer_inherits_process_mode_from_parent_when_unset() -> void:
	# Arrange
	var parent: Node = Node.new()
	parent.process_mode = Node.PROCESS_MODE_ALWAYS
	var cl: CanvasLayer = CanvasLayer.new()
	parent.add_child(cl)
	add_child(auto_free(parent))

	# Act
	var effective_always: bool = cl.can_process()
	get_tree().paused = true
	var while_paused: bool = cl.can_process()
	get_tree().paused = false
	print("SP-16B INHERIT default mode=", cl.process_mode, " can_process while paused=", while_paused)

	# Assert
	assert_int(cl.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_bool(effective_always).is_true()
	assert_bool(while_paused).is_true()


func test_subviewport_visible_rect_equals_size() -> void:
	# Arrange
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(2560, 1080)

	# Act
	add_child(auto_free(vp))

	# Assert
	assert_vector(vp.get_visible_rect().size).is_equal(Vector2(2560, 1080))


func test_echo_key_event_is_not_an_action_press_unless_echo_allowed() -> void:
	# Arrange
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = KEY_RIGHT
	ev.physical_keycode = KEY_RIGHT
	ev.pressed = true
	ev.echo = true

	# Act
	var plain: bool = ev.is_action_pressed(&"ui_right")
	var with_echo: bool = ev.is_action_pressed(&"ui_right", true)
	print("SP-16C is_echo=", ev.is_echo(), " is_action_pressed(no echo)=", plain, " (allow_echo)=", with_echo)

	# Assert
	assert_bool(ev.is_echo()).is_true()
	assert_bool(plain).is_false()
	assert_bool(with_echo).is_true()


func _focus_probe(accept: bool) -> Array:
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(400, 200)
	vp.gui_embed_subwindows = true
	add_child(auto_free(vp))
	var a: _AcceptingButton = _AcceptingButton.new()
	var b: Button = Button.new()
	a.text = "A"
	b.text = "B"
	b.position = Vector2(150, 0)
	a.focus_neighbor_right = NodePath("../B")
	b.name = &"B"
	a.name = &"A"
	vp.add_child(a)
	vp.add_child(b)
	if not accept:
		a.set_script(null)
	a.grab_focus()
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = KEY_RIGHT
	ev.physical_keycode = KEY_RIGHT
	ev.pressed = true
	vp.push_input(ev)
	var res: Array = [vp.gui_get_focus_owner() == b, vp.gui_get_focus_owner() == a, a.get_script() != null and a.seen]
	return res


func test_accept_event_stops_native_focus_move_for_ui_right() -> void:
	# Act
	var with_accept: Array = _focus_probe(true)
	var native: Array = _focus_probe(false)
	print("SP-16C focus moved to B: with accept_event=", with_accept[0], " native (no handler)=", native[0], " handler seen=", with_accept[2])

	# Assert: native moves focus; accept_event keeps it (record either way if the harness cannot route it)
	assert_bool(native[0]).is_true()
	assert_bool(with_accept[0]).is_false()


func test_rich_text_label_add_image_signature_and_image_unit_names() -> void:
	# Arrange
	var found: Dictionary = {}
	for m: Dictionary in ClassDB.class_get_method_list("RichTextLabel", true):
		if m["name"] == "add_image":
			var names: Array[String] = []
			for a: Dictionary in m["args"]:
				names.append("%s:%d" % [a["name"], a["type"]])
			found["args"] = names
	var enums: PackedStringArray = ClassDB.class_get_enum_list("RichTextLabel", true)
	var unit_members: PackedStringArray = ClassDB.class_get_enum_constants("RichTextLabel", "ImageUnit") if enums.has("ImageUnit") else PackedStringArray()
	print("SP-16D add_image args=", found.get("args"), " enums=", enums, " ImageUnit=", unit_members)

	# Assert
	assert_bool(found.has("args")).is_true()
	assert_bool(enums.has("ImageUnit")).is_true()
	assert_int(unit_members.size()).is_greater(1)


func test_rich_text_label_add_image_with_units_builds_and_counts_a_paragraph() -> void:
	# Arrange
	var rtl: RichTextLabel = RichTextLabel.new()
	rtl.fit_content = true
	add_child(auto_free(rtl))
	var img: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex: ImageTexture = ImageTexture.create_from_image(img)

	# Act
	rtl.add_image(tex, 24, 24)
	rtl.add_text(" pulsar")
	print("SP-16D add_image(tex,24,24) ok; paragraphs=", rtl.get_paragraph_count(), " text='", rtl.get_parsed_text(), "'")

	# Assert
	assert_int(rtl.get_paragraph_count()).is_equal(1)


func test_label_line_count_under_headless_text_server_is_recorded() -> void:
	# Arrange
	var lab: Label = Label.new()
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.custom_minimum_size = Vector2(300, 0)
	lab.size = Vector2(300, 100)
	lab.text = "Esta es una linea de subtitulo bastante larga que debe partirse en varias lineas al ancho dado."
	add_child(auto_free(lab))
	await get_tree().process_frame

	# Act
	var lines: int = lab.get_line_count()
	var ts: String = DisplayServer.get_name()
	print("SP-16E display=", ts, " line_count=", lines, " (headless text server may report 1; real value NEEDS_WINDOWED)")

	# Assert: API exists and returns a positive count
	assert_int(lines).is_greater_equal(1)
