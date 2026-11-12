## S-0003-C (ADR-0003 § Spike Results): hitch of the synchronous `planta` load between steps 3 and 4, measured with the
## real RealClock in one fresh process per run. Prints `[s0003c] instantiate_ms=.. worst_frame_ms=..`.
## `instantiate_ms`: `SceneSource.instantiate` (load + instantiate of planta.tscn); `worst_frame_ms`: the longest
## gap between two consecutive frames from the request until READY (the visible hitch, render included).
## Run: `Godot --path <repo> res://tools/evidence/s0003c_measure.tscn` (windowed, quits by itself).
extends Node

## SceneSource that times `instantiate`.
class TimedSource extends SceneSource:
	var instantiate_usec: int = 0

	func instantiate(destination: StringName) -> Node:
		var t0: int = Time.get_ticks_usec()
		var n: Node = super.instantiate(destination)
		instantiate_usec = Time.get_ticks_usec() - t0
		return n

var _loader: SceneLoader
var _ctx: ServiceContext
var _source: TimedSource = TimedSource.new()
var _last_usec: int = 0
var _worst_usec: int = 0
var _frames: int = 0


func _ready() -> void:
	var slot: Node3D = Node3D.new()
	add_child(slot)
	var ctx: ServiceContext = ServiceContext.new()
	ctx.flavor = BuildFlavor.new(false)
	ctx.logger = LogSink.new()
	ctx.fatal = ReleaseFatalHandler.new(ctx.logger)
	ctx.files = FileStore.new()
	ctx.real_clock = RealClock.new()
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
	_ctx = ctx
	Boot.wire_scene_loading(ctx, slot, func(_a: float) -> void: pass, null)
	_loader.set_source(_source)
	# Let the window settle for a few frames before the request so the first frame gap is not start-up cost.
	_frames = -10


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	_frames += 1
	if _frames == 0:
		Boot.start_new_game(_ctx)
		_last_usec = now
		return
	if _frames < 0:
		return
	_worst_usec = maxi(_worst_usec, now - _last_usec)
	_last_usec = now
	if _loader.get_state() == SceneLoader.State.READY:
		print("[s0003c] instantiate_ms=%.2f worst_frame_ms=%.2f frames=%d" % [
				float(_source.instantiate_usec) / 1000.0, float(_worst_usec) / 1000.0, _frames])
		get_tree().quit(0)
