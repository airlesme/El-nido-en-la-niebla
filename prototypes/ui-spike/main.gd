# PROTOTYPE - NOT FOR PRODUCTION
# ADR-0016 SP-16A / ADR-0007 SP-1, SP-3: probe scene. Prints SPIKE lines and measures glyph pixels from the engine's own frame.
extends Node

const SIZES: Array[int] = [24, 32, 44]
var _frame: int = 0
var _labels: Array[Label] = []
var _scale_text: float = 1.0
var _root: Control
var _theme: Theme


func _ready() -> void:
	# Base size is always 1920x1080 (ADR-0007 D7); the project viewport size is overridden per run only so the movie writer records at native size.
	get_window().content_scale_size = Vector2i(1920, 1080)
	for f: String in OS.get_cmdline_user_args():
		if f.begins_with("--force-size="):
			var p: PackedStringArray = f.substr(13).split("x")
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_position(Vector2i(0, -200))
			DisplayServer.window_set_size(Vector2i(int(p[0]), int(p[1])))
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--scale="):
			_scale_text = float(a.substr(8))
	_theme = Theme.new()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = _theme
	add_child(_root)
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	# 1920x1080-anchored frame, centred (shows free axis under expand)
	var frame: ReferenceRect = ReferenceRect.new()
	frame.border_color = Color(0.2, 0.8, 0.3)
	frame.border_width = 2.0
	frame.editor_only = false
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.size = Vector2(1920, 1080)
	frame.position = -frame.size * 0.5
	_root.add_child(frame)
	for corner: Array in [["TL", Control.PRESET_TOP_LEFT], ["TR", Control.PRESET_TOP_RIGHT], ["BL", Control.PRESET_BOTTOM_LEFT], ["BR", Control.PRESET_BOTTOM_RIGHT]]:
		var l: Label = Label.new()
		l.text = corner[0]
		l.add_theme_font_size_override("font_size", 32)
		_root.add_child(l)
		l.set_anchors_and_offsets_preset(corner[1])
	var y: float = 140.0
	for s: int in SIZES:
		var l: Label = Label.new()
		l.text = "HIHI " + str(s) + "px: Hay alguien en el nido? El turno de noche acaba pronto."
		l.add_theme_font_size_override("font_size", s)
		l.position = Vector2(200, y)
		_root.add_child(l)
		_labels.append(l)
		y += 90.0
	# subtitle sample with 2 px outline
	var sub: Label = Label.new()
	sub.text = "No deberias estar aqui a estas horas.\nLa puerta del almacen sigue cerrada."
	sub.add_theme_font_size_override("font_size", 44)
	sub.add_theme_constant_override("outline_size", 2)
	sub.add_theme_color_override("font_outline_color", Color.BLACK)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	sub.position.y -= 160.0
	_root.add_child(sub)
	# inline glyph via add_image (SP-16D)
	var rtl: RichTextLabel = RichTextLabel.new()
	rtl.fit_content = true
	rtl.custom_minimum_size = Vector2(900, 0)
	rtl.position = Vector2(200, 480)
	rtl.add_theme_font_size_override("normal_font_size", 32)
	var img: Image = Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.9, 0.9, 0.2))
	rtl.add_image(ImageTexture.create_from_image(img), 32, 32)
	rtl.add_text(" Pulsa para interactuar (glifo en linea)")
	_root.add_child(rtl)
	print("SPIKE start window=", DisplayServer.window_get_size(), " mode=", get_window().content_scale_mode, " aspect=", get_window().content_scale_aspect,
		" content_scale_size=", get_window().content_scale_size, " scale_mode=", get_window().content_scale_stretch)


func _apply_text_scale(f: float) -> void:
	_theme.set_default_font_size(int(round(32.0 * f)))


func _process(_d: float) -> void:
	_frame += 1
	if _frame == 6:
		_report()
	if _frame == 12:
		get_tree().quit()


func _report() -> void:
	var vp: Viewport = get_viewport()
	var img: Image = vp.get_texture().get_image()
	var t: Transform2D = vp.get_final_transform()
	var win: Vector2i = DisplayServer.window_get_size()
	var logical: Vector2 = vp.get_visible_rect().size
	var s_exp: float = minf(float(win.x) / 1920.0, float(win.y) / 1080.0)
	print("SPIKE window=", win, " logical_viewport=", logical, " final_transform_scale=", t.get_scale(), " s_expected=", s_exp,
		" image=", img.get_size(), " logical_expected=", Vector2(float(win.x) / s_exp, float(win.y) / s_exp))
	for l: Label in _labels:
		var fs: int = l.get_theme_font_size("font_size")
		# first glyph 'H' region: logical rect of the first two chars
		var w: float = l.get_theme_font("font").get_string_size("H", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var r: Rect2 = Rect2(l.global_position, Vector2(w, l.size.y))
		var px: Rect2 = t * r
		var x0: int = maxi(int(floor(px.position.x)), 0)
		var x1: int = mini(int(ceil(px.end.x)), img.get_width() - 1)
		var y0: int = maxi(int(floor(px.position.y)), 0)
		var y1: int = mini(int(ceil(px.end.y)), img.get_height() - 1)
		var top: int = 100000
		var bot: int = -1
		for yy: int in range(y0, y1 + 1):
			for xx: int in range(x0, x1 + 1):
				if img.get_pixel(xx, yy).get_luminance() > 0.5:
					top = mini(top, yy)
					bot = maxi(bot, yy)
		var cap_px: int = bot - top + 1 if bot >= 0 else -1
		# edge width: scan the middle row of the H, count intermediate pixels (0.15..0.85 of the final luminance)
		var ym: int = (top + bot) / 2 if bot >= 0 else y0
		var inter: int = 0
		var strong: int = 0
		var runs: Array[int] = []
		var cur: int = 0
		for xx: int in range(x0, x1 + 1):
			var v: float = img.get_pixel(xx, ym).get_luminance()
			if v > 0.9:
				strong += 1
			if v > 0.12 and v < 0.85:
				cur += 1
			elif cur > 0:
				runs.append(cur)
				cur = 0
		if cur > 0:
			runs.append(cur)
		var worst: int = 0
		for r2: int in runs:
			worst = maxi(worst, r2)
		print("SPIKE glyph font_size=", fs, " logical_px expected_cap~", snappedf(float(fs) * 0.714, 0.1), " real_cap_px=", cap_px,
			" real_font_px=", snappedf(float(fs) * t.get_scale().x, 0.1), " edge_transition_max_run_px=", worst, " strong_px=", strong)
