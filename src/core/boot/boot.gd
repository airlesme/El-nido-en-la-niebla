## Single composition root (ADR-0009 D3): the only file that names an autoload.
## Skeleton (S0): builds platform objects and the context, then runs setup() in D2 order.
## TODO(ADR-0009): LogSink, FatalErrorHandler, FileStore, DataValidator (step 4),
## Shell.setup_ui (step 11) and SceneLoader.request_title() (step 13).
class_name Boot extends Node


func _ready() -> void:
	compose()


## Builds the global context from the autoloads, runs setup() and freezes it.
func compose() -> ServiceContext:
	var ctx: ServiceContext = ServiceContext.new()
	ctx.flavor = BuildFlavor.from_engine()
	ctx.real_clock = RealClock.new()
	ctx.content = ContentDBAutoload
	ctx.state = GameStateAutoload
	ctx.clock = GameClockAutoload
	ctx.input = InputRouterAutoload
	ctx.settings = SettingsAutoload
	ctx.audio = AudioDirectorAutoload
	ctx.save = SaveServiceAutoload
	ctx.scenes = SceneLoaderAutoload
	ctx.director = SceneDirectorAutoload
	# ADR-0009 D2 boot order (differs from registration order).
	ctx.content.setup(ctx)
	ctx.state.setup(ctx)
	ctx.clock.setup(ctx)
	ctx.input.setup(ctx)
	ctx.settings.setup(ctx)
	ctx.audio.setup(ctx)
	ctx.scenes.setup(ctx)
	ctx.director.setup(ctx)
	ctx.save.setup(ctx)
	ctx.freeze()
	return ctx
