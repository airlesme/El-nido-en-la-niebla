## Evidence runner for CP-015 (AC-11a, AC-12a, C-M1-7). Run with the engine's movie writer, never a desktop capture:
## `Godot --path <repo> --write-movie <abs>/movie.avi --fixed-fps 20 res://tools/evidence/carga_015_capture.tscn -- --out=<abs dir>`
## Boots the real Shell pieces + SceneLoader + planta + Player with a FORCED RealClock (50 ms per frame), so the
## curtain alpha at every frame is deterministic. Each viewport image is taken in `frame_post_draw` and stored with the
## alpha applied in that very frame. Prints `[evidence] ...` lines; writes the PNGs into `--out`.
extends Node

const DT_MS: int = 50
const SETTLE_FRAMES: int = 8
const OUT_ARG: String = "--out="

var _clock: FakeRealClock = FakeRealClock.new()
var _loader: SceneLoader
var _shell: Shell
var _player: Player
var _out: String = ""
var _alpha: float = -1.0
var _frame: int = 0
var _stage: int = 0
var _stage_frame: int = 0
var _saved_black: bool = false
var _saved_half: bool = false
var _half_alpha: float = -1.0
var _half_lum: float = -1.0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(OUT_ARG):
			_out = arg.substr(OUT_ARG.length())
	var packed: PackedScene = load("res://src/shell/shell.tscn")
	_shell = packed.instantiate() as Shell
	var boot: Node = _shell.get_node("Boot")
	_shell.remove_child(boot)
	boot.free()
	add_child(_shell)
	var ctx: ServiceContext = ServiceContext.new()
	ctx.flavor = BuildFlavor.new(false)
	ctx.logger = LogSink.new()
	ctx.fatal = ReleaseFatalHandler.new(ctx.logger)
	ctx.files = FileStore.new()
	ctx.real_clock = _clock
	ctx.state = GameState.new()
	ctx.clock = GameClock.new()
	ctx.content = ContentDB.new()
	ctx.input = InputRouter.new()
	ctx.scenes = SceneLoader.new()
	for n: Node in [ctx.state, ctx.clock, ctx.content, ctx.input, ctx.scenes]:
		add_child(n)
	Boot.wire_state(ctx)
	ctx.clock.setup(ctx)
	ctx.input.setup(ctx)
	ctx.scenes.setup(ctx)
	_loader = ctx.scenes
	var sink: Callable = func(a: float) -> void:
		_alpha = a
		_shell.curtain.set_alpha(a)
	Boot.wire_scene_loading(ctx, _shell.world_slot, sink, _shell.error_panel)
	RenderingServer.frame_post_draw.connect(_on_post_draw)
	Boot.start_new_game(ctx)


func _process(_delta: float) -> void:
	_frame += 1
	_clock.ms += DT_MS # parent first: the loader's `tick` of this frame sees the new time
	if _stage == 0 and _loader.get_state() == SceneLoader.State.READY:
		var root: GameSceneRoot = _shell.world_slot.get_child(0) as GameSceneRoot
		_player = root.get_player() as Player
		_stage = 1
		_stage_frame = 0
	elif _stage >= 1:
		_stage_frame += 1


func _on_post_draw() -> void:
	if _out.is_empty():
		return
	var img: Image = get_viewport().get_texture().get_image()
	if _stage == 0:
		if not _saved_black and _alpha >= 1.0 and _shell.world_slot.get_child_count() > 0:
			_saved_black = true
			img.save_png(_out.path_join("carga-015-curtain-a100.png"))
			print("[evidence] a100 frame=%d alpha=%.4f center=%s corners=%s lum=%.4f" % [
					_frame, _alpha, img.get_pixel(img.get_width() / 2, img.get_height() / 2),
					[img.get_pixel(0, 0), img.get_pixel(img.get_width() - 1, 0), img.get_pixel(0, img.get_height() - 1),
					img.get_pixel(img.get_width() - 1, img.get_height() - 1)], _lum(img)])
		elif _saved_black and not _saved_half and _alpha <= 0.5 and _alpha >= 0.0:
			_saved_half = true
			_half_alpha = _alpha
			_half_lum = _lum(img)
			img.save_png(_out.path_join("carga-015-curtain-a050.png"))
			print("[evidence] a050 frame=%d alpha=%.4f lum=%.4f" % [_frame, _alpha, _half_lum])
		return
	if _stage == 1 and _stage_frame == SETTLE_FRAMES:
		var ref: float = _lum(img)
		img.save_png(_out.path_join("carga-015-despacho.png"))
		print("[evidence] despacho frame=%d alpha=%.4f lum_ref=%.4f ratio_half=%.4f (alpha %.4f -> expected %.4f)" % [
				_frame, _alpha, ref, _half_lum / ref, _half_alpha, 1.0 - _half_alpha])
		print("[evidence] player feet=%s velocity=%s" % [_player.global_position, _player.velocity])
		_player.colocar(Vector3(8.0, 0.0, -1.8), 0.0, 0.0)
		_stage = 2
		_stage_frame = 0
	elif _stage == 2 and _stage_frame == SETTLE_FRAMES:
		img.save_png(_out.path_join("carga-015-archivo.png"))
		print("[evidence] archivo frame=%d feet=%s" % [_frame, _player.global_position])
		_stage = 3
		get_tree().quit(0)


## Mean luma (0.2126 R + 0.7152 G + 0.0722 B, sRGB values) over a 32 x 18 grid of pixels.
func _lum(img: Image) -> float:
	var sum: float = 0.0
	var n: int = 0
	for gy: int in 18:
		for gx: int in 32:
			var c: Color = img.get_pixel(gx * (img.get_width() - 1) / 31, gy * (img.get_height() - 1) / 17)
			sum += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			n += 1
	return sum / float(n)
