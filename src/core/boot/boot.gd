## Single composition root (ADR-0009 D3): the only file that names an autoload.
## Skeleton (S0): builds platform objects and the context, then runs setup() in D2 order.
## TODO(ADR-0009): FileStore in ServiceContext (step 4 builds its own meanwhile),
## Shell.setup_ui (step 11) and SceneLoader.request_title() (step 13).
class_name Boot extends Node


## User argument (after `--`) that makes Boot print the report and exit 0 (ADR-0018 D4 layer 3).
const BOOT_REPORT_ARG: String = "--boot-report"

## Fact catalog, relative to `assets/data/` (a registered DataCatalog row).
const STATE_CATALOG: String = "state/flags.json"

var _writers: Dictionary = {} # int owner id -> FactWriter (private table, EB-014 ADR-fallback)


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


## Boot step 4 (ADR-0009 D2): DataValidator.run(ctx) in debug only; release never builds nor calls it.
## Example: `Boot.run_data_validation(ctx, FileStore.new())`.
static func run_data_validation(ctx: ServiceContext, files: FileStore) -> void:
	if not ctx.flavor.is_debug():
		return
	var reader: DataReader = DataReader.new(files, ctx.flavor)
	DataValidator.new(reader, ctx.logger).run(ctx)


## Boot step 2 (ADR-0009 D2): `state.setup(ctx)` then the fact catalog load (EB-014). A load error goes
## through `ctx.fatal` as CATALOGO_INVALIDO (dev stops via ErrorPolicy). Returns true when READY.
## `setup` stays I/O-free (F-R26): the read happens here, in the synchronous boot sequence (F-R27).
## Example: `Boot.wire_state(ctx)` with `ctx.state`, `ctx.files`, `ctx.fatal` already set.
static func wire_state(ctx: ServiceContext) -> bool:
	ctx.state.setup(ctx)
	return ctx.state.load_catalog(STATE_CATALOG) == OK


## The `FactWriter` bound to `owner_id`, created once and kept in a private table (ADR-0001 D7: only
## Boot obtains writers; it hands them to systems 9, 19, 20 and 22). `ctx.state` must be set.
## TODO(boot-owner): ADR-0009 does not fix where the table lives (Open Items C9); it stays here.
## Example: `var w: FactWriter = boot.writer_for_owner(20)`.
func writer_for_owner(owner_id: int, ctx: ServiceContext) -> FactWriter:
	if not _writers.has(owner_id):
		_writers[owner_id] = ctx.state.writer_for(owner_id)
	return _writers[owner_id]


## Builds the global context from the autoloads, runs setup() and freezes it.
func compose() -> ServiceContext:
	var ctx: ServiceContext = ServiceContext.new()
	ctx.flavor = BuildFlavor.from_engine()
	ctx.logger = LogSink.new()
	ctx.files = FileStore.new()
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
	wire_state(ctx)
	if ctx.fatal.has_failed(): # invalid or missing flags.json: do not enter the game (CA-26)
		return ctx
	ctx.clock.setup(ctx)
	# Step 4.
	run_data_validation(ctx, ctx.files)
	if ctx.fatal.has_failed(): # a fatal call stops the sequence (ADR-0009 D2)
		return ctx
	ctx.input.setup(ctx) # step 5: loads default_bindings.json (EC-015)
	if ctx.fatal.has_failed(): # invalid bindings: do not enter the game
		return ctx
	# TODO(carga-005): hand `ctx.input.contexts_port()` to SceneLoader (4) and SceneDirector (21) when
	# their setup accepts it (src/scene is outside EC-015).
	ctx.settings.setup(ctx)
	ctx.audio.setup(ctx)
	ctx.scenes.setup(ctx)
	ctx.director.setup(ctx)
	ctx.save.setup(ctx)
	ctx.freeze()
	return ctx
