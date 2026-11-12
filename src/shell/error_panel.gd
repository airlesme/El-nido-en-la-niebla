## Error panel above the curtain (GDD R11/R14, ADR-0003 «Failure», C-R12, C-X08).
## Shown by SceneLoader through its error-panel port when a load fails. The curtain stays black
## underneath; the only action is «Volver al título» (`ui_aceptar` or the cursor). `pausa` and
## `ui_atrás` are never handled here (AC-22 logic lives in SceneLoader). Runs with the tree
## paused (PROCESS_MODE_ALWAYS) and uses no Timer/Tween (ADR-0002 D6).
## Example: `loader.set_error_panel_port(panel.show_error); panel.set_unload_port(loader.request_full_unload)`.
class_name ErrorPanel extends CanvasLayer


## Emitted when the player accepts the single action (after the unload was requested).
signal return_to_title_requested

## TODO(localization): move to the text table once the content epic defines the keys (ADR-0005).
const TEXT_MESSAGE: String = "No se ha podido cargar la escena.\nVuelve al título para continuar."
const TEXT_ACTION: String = "Volver al título"
const ACTION_ACCEPT: StringName = &"ui_aceptar"

var _unload_port: Callable = Callable()
var _cause: StringName = &""

@onready var _message: Label = %Message
@onready var _action: Button = %Action


func _init() -> void:
	# C-R12: explicit, never inherited, so the panel works while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_message.text = TEXT_MESSAGE
	_action.text = TEXT_ACTION
	_action.pressed.connect(_on_action_pressed)
	_apply_visible(false)


## Wires the action. `unload` is `Callable() -> bool` (e.g. `SceneLoader.request_full_unload`).
func set_unload_port(unload: Callable) -> void:
	_unload_port = unload


## Shows the panel for a failure cause (the cause is kept for diagnostics, not shown to the player).
func show_error(cause: StringName) -> void:
	_cause = cause
	_apply_visible(true)
	_action.grab_focus()


## True while the panel is on screen.
func is_showing() -> bool:
	return visible


## Cause of the failure being shown, or `&""`.
func get_cause() -> StringName:
	return _cause


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not InputMap.has_action(ACTION_ACCEPT):
		return
	if event.is_action_pressed(ACTION_ACCEPT):
		get_viewport().set_input_as_handled()
		_accept()


func _on_action_pressed() -> void:
	_accept()


func _accept() -> void:
	if not visible:
		return
	if _unload_port.is_valid() and _unload_port.call() == true:
		_apply_visible(false)
		_cause = &""
		return_to_title_requested.emit()


func _apply_visible(shown: bool) -> void:
	visible = shown
	_action.disabled = not shown
	_action.focus_mode = Control.FOCUS_ALL if shown else Control.FOCUS_NONE
