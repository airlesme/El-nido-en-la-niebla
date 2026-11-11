## Single composition root (ADR-0009 D3): the only file that names an autoload.
## Skeleton (S0): builds platform objects and the context, then runs setup() in D2 order.
## TODO(ADR-0009): FileStore, DataValidator (step 4),
## Shell.setup_ui (step 11) and SceneLoader.request_title() (step 13).
class_name Boot extends Node


## User argument (after `--`) that makes Boot print the report and exit 0 (ADR-0018 D4 layer 3).
const BOOT_REPORT_ARG: String = "--boot-report"


func _ready() -> void:
	var ctx: ServiceContext = compose()
	# TODO(ADR-0018 O3/D5): dev_tools and commit come from DevTools.attach and build-info.json.
	print(format_report_line(ctx.flavor, _project_version(), "dev", "absent"))
	if wants_boot_report(OS.get_cmdline_user_args()):
		get_tree().quit(0)


## Builds the `[boot]` line ADR-0018 D4 layer 3 greps for.
## Example: `format_report_line(BuildFlavor.new(false), "0.1.0", "abc1234", "absent")`
## returns `[boot] flavor=release dev_tools=absent version=0.1.0 commit=abc1234`.
static func format_report_line(flavor: BuildFlavor, version: String, commit: String, dev_tools: String) -> String:
	var name: String = "debug" if flavor.is_debug() else "release"
	return "[boot] flavor=%s dev_tools=%s version=%s commit=%s" % [name, dev_tools, version, commit]


## True when the user args (those after `--`) contain `--boot-report`.
static func wants_boot_report(user_args: PackedStringArray) -> bool:
	return user_args.has(BOOT_REPORT_ARG)


## Picks the FatalErrorHandler variant by BuildFlavor (ADR-0009 D8): Debug stops via ErrorPolicy, Release only logs.
static func make_fatal_handler(flavor: BuildFlavor, logger: LogSink) -> FatalErrorHandler:
	if flavor.is_debug():
		return DebugFatalHandler.new(logger, ErrorPolicyDefault.new(flavor))
	return ReleaseFatalHandler.new(logger)


func _project_version() -> String:
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	return version if not version.is_empty() else "dev"


## Builds the global context from the autoloads, runs setup() and freezes it.
func compose() -> ServiceContext:
	var ctx: ServiceContext = ServiceContext.new()
	ctx.flavor = BuildFlavor.from_engine()
	ctx.logger = LogSink.new()
	ctx.real_clock = RealClock.new()
	ctx.fatal = make_fatal_handler(ctx.flavor, ctx.logger)
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
