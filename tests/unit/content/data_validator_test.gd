## CD-003: DataCatalog registry, RefIndex, DataValidator sweep/run and Boot step 4 (ADR-0005 D1, D3).
extends GdUnitTestSuite

const ROOT: String = "res://assets/data/"


## narrative/lines.json test schema: { lines: [ {id, next?: ref content_key} ] }.
class LinesSchema extends DataSchema:
	func version() -> int:
		return 1

	func root() -> FieldSpec:
		var rec: FieldSpec = object_({"id": id_("^[A-Z_0-9]+$")},
				{"next": nullable(id_("^[A-Z_0-9]+$", &"content_key")),
				"status": enum_([&"active", &"retired"] as Array[StringName])})
		return object_({"lines": array_(rec, 0, &"id")})


## narrative/ui.json test schema: { ui: [ {id} ] }.
class UiSchema extends DataSchema:
	func version() -> int:
		return 1

	func root() -> FieldSpec:
		return object_({"ui": array_(object_({"id": id_("^[A-Z_0-9]+$")}), 0, &"id")})


## state/flags.json test schema: facts with an optional enum values list and a fact ref.
class StubFlagsSchema extends DataSchema:
	func version() -> int:
		return 1

	func root() -> FieldSpec:
		var fact: FieldSpec = object_({"name": id_("^[a-z][a-z0-9_]*$")},
				{"values": array_(string_()), "mirror": id_("^[a-z][a-z0-9_]*$", &"fact")})
		return object_({"facts": array_(fact, 0, &"name")})


var _store: MemoryFileStore
var _log: RecordingLog
var _fatal: RecordingFatalHandler
var _ctx: ServiceContext


func before_test() -> void:
	_store = MemoryFileStore.new()
	_log = RecordingLog.new()
	_fatal = RecordingFatalHandler.new()
	_ctx = _make_ctx(BuildFlavor.new(true))


## Context of doubles WITHOUT the Node fakes: TestContexts.make builds FakeClock/FakeGameState even
## when overridden (eager `get` default), leaving 2 orphan Nodes per call.
func _make_ctx(flavor: BuildFlavor) -> ServiceContext:
	var c: ServiceContext = ServiceContext.new()
	c.logger = _log
	c.flavor = flavor
	c.fatal = _fatal
	c.freeze()
	return c


func _put(rel: String, text: String) -> void:
	_store.put_text(ROOT + rel, text)


func _entries() -> Array[DataCatalog.Entry]:
	var out: Array[DataCatalog.Entry] = []
	out.append(DataCatalog.Entry.new("state/flags.json", StubFlagsSchema.new()))
	out.append(DataCatalog.Entry.new("narrative/lines.json", LinesSchema.new()))
	out.append(DataCatalog.Entry.new("narrative/ui.json", UiSchema.new()))
	return out


func _validator(entries: Array[DataCatalog.Entry], debug: bool = true) -> DataValidator:
	return DataValidator.new(DataReader.new(_store, BuildFlavor.new(debug)), _log, entries)


func _rules(issues: Array[DataIssue]) -> PackedStringArray:
	var p: PackedStringArray = PackedStringArray()
	for i: DataIssue in issues:
		p.append("%s|%s|%s" % [i.file, i.json_path, i.rule])
	return p


func _put_valid() -> void:
	_put("state/flags.json", '{"schema_version":1,"facts":[{"name":"door","values":["open","shut"]}]}')
	_put("narrative/lines.json", '{"schema_version":1,"lines":[{"id":"VO_1"},{"id":"VO_2","next":"VO_1"}]}')
	_put("narrative/ui.json", '{"schema_version":1,"ui":[{"id":"UI_A"}]}')


# --- DataCatalog -------------------------------------------------------------

func test_registry_lists_m1_rows_in_fixed_order() -> void:
	# Act
	var paths: PackedStringArray = PackedStringArray()
	for e: DataCatalog.Entry in DataCatalog.registry():
		paths.append(e.rel_path)

	# Assert
	assert_array(Array(paths)).is_equal([
		"state/flags.json",
		"narrative/lines.json", "narrative/nonverbal.json", "narrative/documents.json",
		"narrative/mails.json", "narrative/tasks.json", "narrative/hints.json",
		"narrative/ui.json", "narrative/objects.json", "narrative/names.json", "narrative/groups.json",
		"input/default_bindings.json", "player/player.json",
		"interaction/interactables.json", "interaction/interaction_config.json",
		"puzzles/puzzles.json"])


func test_registry_every_row_follows_the_path_convention() -> void:
	for e: DataCatalog.Entry in DataCatalog.registry():
		assert_bool(DataCatalog.is_valid_path(e.rel_path)).is_true()


func test_registry_rows_carry_owner_and_fatal_code() -> void:
	var by_path: Dictionary = {}
	for e: DataCatalog.Entry in DataCatalog.registry():
		by_path[e.rel_path] = e
	var lines: DataCatalog.Entry = by_path["narrative/lines.json"]
	var puzzles: DataCatalog.Entry = by_path["puzzles/puzzles.json"]
	assert_int(lines.owner).is_equal(18)
	assert_str(lines.fatal_code).is_equal("CONTENIDO_INVALIDO")
	assert_int(puzzles.load_point).is_equal(DataCatalog.LoadPoint.SCENE)
	assert_str(puzzles.fatal_code).is_equal("DATOS_ESCENA_INVALIDOS")


func test_entries_only_returns_rows_with_a_schema() -> void:
	for e: DataCatalog.Entry in DataCatalog.entries():
		assert_object(e.schema).is_not_null()


func test_is_valid_path_rejects_outside_the_convention() -> void:
	for bad: String in ["flags.json", "state/my-flags.json", "State/flags.json", "state/Flags.json",
			"a/b/c.json", "state/flags.JSON", "state/flags.txt", "state/ñ.json", "", "/flags.json",
			"state/.json", "state//flags.json"]:
		assert_bool(DataCatalog.is_valid_path(bad)).is_false()


func test_is_valid_path_accepts_snake_case_one_folder() -> void:
	assert_bool(DataCatalog.is_valid_path("input/default_bindings.json")).is_true()
	assert_bool(DataCatalog.is_valid_path("p1/p1_view2.json")).is_true()


# --- RefIndex ----------------------------------------------------------------

func test_ref_index_has_distinguishes_kind_and_id() -> void:
	var idx: RefIndex = RefIndex.new()
	idx.add(&"fact", &"door")

	assert_bool(idx.has(&"fact", &"door")).is_true()
	assert_bool(idx.has(&"fact", &"window")).is_false()
	assert_bool(idx.has(&"item", &"door")).is_false()


func test_ref_index_retired_and_fact_values() -> void:
	var idx: RefIndex = RefIndex.new()
	idx.add_retired(&"VO_OLD")
	idx.set_fact_values(&"door", ["open", "shut"])

	assert_bool(idx.is_retired(&"VO_OLD")).is_true()
	assert_bool(idx.is_retired(&"VO_NEW")).is_false()
	assert_bool(idx.fact_accepts(&"door", &"open")).is_true()
	assert_bool(idx.fact_accepts(&"door", &"ajar")).is_false()
	assert_bool(idx.fact_accepts(&"unknown", &"open")).is_false()


# --- DataValidator.sweep -----------------------------------------------------

func test_sweep_valid_fixtures_returns_no_issues() -> void:
	_put_valid()

	var issues: Array[DataIssue] = _validator(_entries()).sweep(_entries())

	assert_array(issues).is_empty()


func test_sweep_missing_ref_and_duplicate_id_across_files_returns_both() -> void:
	# Arrange: VO_9 -> missing target; UI_A appears in ui.json and again in lines.json
	_put("state/flags.json", '{"schema_version":1,"facts":[{"name":"door"}]}')
	_put("narrative/lines.json",
			'{"schema_version":1,"lines":[{"id":"VO_1","next":"VO_404"},{"id":"UI_A"}]}')
	_put("narrative/ui.json", '{"schema_version":1,"ui":[{"id":"UI_A"}]}')

	# Act
	var issues: Array[DataIssue] = _validator(_entries()).sweep(_entries())

	# Assert: both reported, the sweep did not stop at the first
	var rules: PackedStringArray = _rules(issues)
	assert_array(Array(rules)).contains_exactly_in_any_order([
		"narrative/ui.json|ui[0].id|dup_id",
		"narrative/lines.json|lines[0].next|ref_missing"])


func test_sweep_reference_to_retired_id_is_an_error() -> void:
	_put("state/flags.json", '{"schema_version":1,"facts":[]}')
	_put("narrative/lines.json",
			'{"schema_version":1,"lines":[{"id":"VO_OLD","status":"retired"},{"id":"VO_2","next":"VO_OLD"}]}')
	_put("narrative/ui.json", '{"schema_version":1,"ui":[]}')

	var issues: Array[DataIssue] = _validator(_entries()).sweep(_entries())

	assert_array(Array(_rules(issues))).is_equal(["narrative/lines.json|lines[1].next|ref_retired"])


func test_sweep_fact_ref_resolves_against_flags() -> void:
	_put("state/flags.json",
			'{"schema_version":1,"facts":[{"name":"a"},{"name":"b","mirror":"a"},{"name":"c","mirror":"zz"}]}')
	_put("narrative/lines.json", '{"schema_version":1,"lines":[]}')
	_put("narrative/ui.json", '{"schema_version":1,"ui":[]}')

	var issues: Array[DataIssue] = _validator(_entries()).sweep(_entries())

	assert_array(Array(_rules(issues))).is_equal(["state/flags.json|facts[2].mirror|ref_missing"])


func test_sweep_kind_without_provider_is_not_flagged() -> void:
	# No flags entry registered: &"fact" refs cannot be resolved, so they are skipped (not false errors).
	var only: Array[DataCatalog.Entry] = [DataCatalog.Entry.new("state/flags.json", StubFlagsSchema.new())]
	_put("state/flags.json", '{"schema_version":1,"facts":[]}')
	assert_array(_validator(only).sweep(only)).is_empty()
	var no_flags: Array[DataCatalog.Entry] = [DataCatalog.Entry.new("narrative/ui.json", UiSchema.new())]
	_put("narrative/ui.json", '{"schema_version":1,"ui":[{"id":"UI_A"}]}')
	assert_array(_validator(no_flags).sweep(no_flags)).is_empty()


func test_sweep_missing_file_reports_issue_and_continues_with_the_rest() -> void:
	_put("narrative/lines.json", '{"schema_version":1,"lines":[{"id":"VO_1","next":"NOPE"}]}')
	_put("narrative/ui.json", '{"schema_version":1,"ui":[]}')
	# state/flags.json is absent

	var issues: Array[DataIssue] = _validator(_entries()).sweep(_entries())

	var rules: Array = Array(_rules(issues))
	assert_int(rules.size()).is_equal(2)
	assert_bool(rules.has("narrative/lines.json|lines[0].next|ref_missing")).is_true()


func test_sweep_duplicate_id_inside_one_file_is_reported_once_by_the_reader() -> void:
	_put("state/flags.json", '{"schema_version":1,"facts":[]}')
	_put("narrative/lines.json", '{"schema_version":1,"lines":[{"id":"VO_1"},{"id":"VO_1"}]}')
	_put("narrative/ui.json", '{"schema_version":1,"ui":[]}')

	var issues: Array[DataIssue] = _validator(_entries()).sweep(_entries())

	var dups: int = 0
	for i: DataIssue in issues:
		if i.rule == &"dup_id":
			dups += 1
	assert_int(dups).is_greater_equal(1)


# --- DataValidator.run -------------------------------------------------------

func test_run_valid_data_logs_nothing_and_raises_no_fatal() -> void:
	_put_valid()

	_validator(_entries()).run(_ctx)

	assert_bool(_fatal.has_failed()).is_false()
	assert_array(_log.lines).is_empty()


func test_run_narrative_error_raises_contenido_invalido_with_count_and_first() -> void:
	_put("state/flags.json", '{"schema_version":1,"facts":[]}')
	_put("narrative/lines.json", '{"schema_version":1,"lines":[{"id":"VO_1","next":"NOPE"}]}')
	_put("narrative/ui.json", '{"schema_version":1,"ui":[]}')
	var entries: Array[DataCatalog.Entry] = _entries()
	entries[1].fatal_code = FatalErrorHandler.CONTENIDO_INVALIDO

	_validator(entries).run(_ctx)

	assert_int(_fatal.calls.size()).is_equal(1)
	assert_str(_fatal.calls[0][&"code"]).is_equal("CONTENIDO_INVALIDO")
	var detail: Dictionary = _fatal.calls[0][&"detail"]
	assert_int(detail[&"count"]).is_equal(1)
	assert_str(detail[&"file"]).is_equal("narrative/lines.json")
	assert_str(detail[&"param"]).is_equal("lines[0].next")


func test_run_catalog_error_raises_catalogo_invalido_and_logs_every_issue() -> void:
	_put("state/flags.json", '{"schema_version":1,"facts":[{"name":"a","mirror":"x"},{"name":"b","mirror":"y"}]}')
	_put("narrative/lines.json", '{"schema_version":1,"lines":[]}')
	_put("narrative/ui.json", '{"schema_version":1,"ui":[]}')

	_validator(_entries()).run(_ctx)

	assert_int(_fatal.calls.size()).is_equal(1)
	assert_str(_fatal.calls[0][&"code"]).is_equal("CATALOGO_INVALIDO")
	assert_int((_fatal.calls[0][&"detail"] as Dictionary)[&"count"]).is_equal(2)
	assert_int(_log.lines.size()).is_equal(2)
	assert_str(_log.lines[0][&"level"]).is_equal("error")


func test_run_warnings_are_logged_but_never_fatal() -> void:
	# An object declared open_with_warning would do; a clamp needs release. Use the open object here.
	var schema: DataSchema = OpenSchema.new()
	var entries: Array[DataCatalog.Entry] = [DataCatalog.Entry.new("narrative/ui.json", schema)]
	_put("narrative/ui.json", '{"schema_version":1,"ui":[{"id":"UI_A","extra":1}]}')

	_validator(entries).run(_ctx)

	assert_bool(_fatal.has_failed()).is_false()
	assert_int(_log.lines.size()).is_equal(1)
	assert_str(_log.lines[0][&"level"]).is_equal("warn")


class OpenSchema extends DataSchema:
	func version() -> int:
		return 1

	func root() -> FieldSpec:
		var rec: FieldSpec = open_with_warning(object_({"id": id_("^[A-Z_0-9]+$")}))
		return object_({"ui": array_(rec)})


# --- Boot step 4 ---------------------------------------------------------------

func test_boot_validation_step_release_flavor_reads_nothing() -> void:
	var release_ctx: ServiceContext = _make_ctx(BuildFlavor.new(false))

	Boot.run_data_validation(release_ctx, _store)

	assert_int(_store.access_count).is_equal(0)
	assert_bool(_fatal.has_failed()).is_false()


func test_boot_validation_step_debug_flavor_runs_the_sweep() -> void:
	# EB-005 registered state/flags.json; its file arrives with EB-006, so until then the real
	# catalog sweep reads that row and the missing file is the (expected) fatal.
	Boot.run_data_validation(_ctx, _store)

	assert_int(_store.accesses_of(ROOT + "state/flags.json")).is_equal(1)
