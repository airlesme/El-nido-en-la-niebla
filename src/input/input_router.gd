## Input contexts and sin-control owner (system 1).
## Story EC-002 part: owns the `EngineInputAdapter` child and `feed(raw)`, which resolves at most one
## action per raw event. Stack, sinks, latches, gestures: later stories (003+).
## Registered as autoload `InputRouterAutoload` (ADR-0009 D1).
## TODO(ADR-0006): the rest of the public API (enter/exit, sinks, movement...) arrives with its stories.
class_name InputRouter extends Node

## Provisional: emitted by `feed` with the first action bound to the raw event.
## TODO(ADR-0006): replaced by context-aware delivery (D6) in story 003.
signal action_fed(action: StringName, pressed: bool)

var _adapter: EngineInputAdapter
var _table: BindingTable


func _init() -> void:
	# ADR-0009 D2: explicit, never inherited. No I/O, no autoload reads here.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if _adapter == null:
		_adapter = EngineInputAdapter.new()
		_adapter.name = "EngineInputAdapter"
		add_child(_adapter)
	if not _adapter.raw.is_connected(feed):
		_adapter.raw.connect(feed)


## Composition point, called once by Boot (ADR-0009 D2/D3). Never called by systems.
func setup(_ctx: ServiceContext) -> void:
	# TODO(ADR-0006): load the binding table and subscribe (ADR-0009 D2 boot order).
	return


## The engine adapter (child node); null before the router enters the tree.
func adapter() -> EngineInputAdapter:
	return _adapter


## Injects the binding table used by `feed`. TODO(ADR-0006): `setup` will own this in story 003.
func use_table(table: BindingTable) -> void:
	_table = table


## Single entry of raw input; called only by the adapter and by tests. Resolves the FIRST action bound
## to `raw` (F-R46) and emits `action_fed`; axes and mouse motion without a binding emit nothing.
## Example: `router.feed(raw_e_pressed)` emits `action_fed(&"interactuar", true)`.
func feed(raw: InputTypes.RawInput) -> void:
	if raw == null or _table == null:
		return
	var actions: Array[StringName] = _table.actions_for(raw)
	if actions.is_empty():
		return
	action_fed.emit(actions[0], raw.pressed)
