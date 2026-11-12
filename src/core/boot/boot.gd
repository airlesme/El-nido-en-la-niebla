## Single composition root (ADR-0009 D3): the only file that names an autoload.
## Skeleton (S0): builds platform objects and the context, then runs setup() in D2 order.
## TODO(ADR-0009): FileStore in ServiceContext (step 4 builds its own meanwhile),
## Shell.setup_ui (step 11) and SceneLoader.request_title() (step 13).
class_name Boot extends Node


## User argument (after `--`) that makes Boot print the report and exit 0 (ADR-0018 D4 layer 3).
const BOOT_REPORT_ARG: String = "--boot-report"

## User argument (after `--`) that disables the automatic new game of M1 (no title yet).
const NO_AUTOSTART_ARG: String = "--no-autostart"

## Fact catalog, relative to `assets/data/` (a registered DataCatalog row).
const STATE_CATALOG: String = "state/flags.json"

var _writers: Dictionary = {} # int owner id -> FactWriter (private table, EB-014 ADR-fallback)


func _ready() -> void:
	var ctx: ServiceContext = compose()
	# TODO(ADR-0018 O3/D5): dev_tools and commit come from DevTools.attach and build-info.json.
	print(format_report_line(ctx.flavor, _project_version(), "dev", "absent"))
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if wants_boot_report(user_args):
		get_tree().quit(0)
		return
	if ctx.fatal.has_failed():
		return
	# Step 10 (ADR-0009 D2): the Shell pieces are siblings of Boot; unique names resolve before their _ready.
	var shell: Node = get_parent()
	var slot: Node3D = shell.get_node_or_null("%" + String(Shell.WORLD_SLOT_NAME)) as Node3D
	var curtain: Curtain = shell.get_node_or_null("%" + String(Shell.CURTAIN_NAME)) as Curtain
	var panel: ErrorPanel = shell.get_node_or_null("%" + String(Shell.ERROR_PANEL_NAME)) as ErrorPanel
	if slot == null or curtain == null:
		ctx.logger.line(LogSink.LEVEL_ERROR, "boot: Shell without WorldSlot/Curtain, the loader stays dormant")
		return
	if wire_scene_loading(ctx, slot, curtain.set_alpha, panel) and wants_auto_start(user_args):
		start_new_game(ctx)


## True unless the user args (after `--`) contain `--no-autostart` (tests, tools and the future title).
static func wants_auto_start(user_args: PackedStringArray) -> bool:
	return not user_args.has(NO_AUTOSTART_ARG)


## Wires the load sequence of the SceneLoader (ADR-0003 D4/D5, ADR-0009 D2): the real `SceneSource`, the Shell's
## WorldSlot, the `LoadTransitions` data, the real clock, `contexts_port()` of the input and the curtain sink
## (`Callable(alpha: float)`). With a panel, also its error port and its unload port (story CP-014).
## Returns false (fatal already raised by the data read) when the transitions data is invalid.
## TODO(carga-005): `contexts_port()` is not yet handed to SceneDirector (21): its `setup` does not accept it.
## Example: `Boot.wire_scene_loading(ctx, world_slot, curtain.set_alpha, error_panel)`.
static func wire_scene_loading(ctx: ServiceContext, slot: Node3D, alpha_sink: Callable, panel: ErrorPanel) -> bool:
	var transitions: LoadTransitions = LoadTransitions.load_from(DataReader.new(ctx.files, ctx.flavor), ctx.fatal)
	if transitions == null:
		return false
	ctx.scenes.set_source(SceneSource.new())
	ctx.scenes.wire_sequence(slot, transitions, ctx.real_clock, ctx.input.contexts_port(), alpha_sink)
	if panel != null:
		ctx.scenes.set_error_panel_port(panel.show_error)
		panel.set_unload_port(ctx.scenes.request_full_unload)
	return true


## M1 has no title: the boot asks for the new game itself. The curtain starts black (no fade-out from nothing).
## `control_final` is `exploracion` because the Director (21) does not exist yet; with `ninguno` 21 would do the hand-off.
## TODO(director-21): switch to `FinalControl.NINGUNO` when SceneDirector owns the hand-off.
## Returns false when the loader rejected the request.
## Example: `Boot.start_new_game(ctx)`.
static func start_new_game(ctx: ServiceContext) -> bool:
	ctx.scenes.prime_curtain_dark()
	return ctx.scenes.request_load(SceneLoader.Destination.PLANTA, SceneLoader.Reason.PARTIDA_NUEVA,
			SceneLoader.FinalControl.EXPLORACION)


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
	# `contexts_port()` reaches SceneLoader (4) in `wire_scene_loading`; SceneDirector (21) still has no port (TODO(carga-005)).
	ctx.settings.setup(ctx)
	ctx.audio.setup(ctx)
	ctx.scenes.setup(ctx)
	ctx.director.setup(ctx)
	ctx.save.setup(ctx)
	ctx.freeze()
	return ctx
