# PROTOTYPE - NOT FOR PRODUCTION
extends Node
## S4 manual: input and focus while SceneTree.paused (ADR-0002, NS-4).
## Run: godot --path prototypes/pause-spike res://s4_manual.tscn
## P toggles pause. Everything on screen is described in the README (S4 manual).

var _pausable_probe: Node
var _pausable_events: int = 0
var _always_events: int = 0
var _ticks: int = 0
var _tick_label: Label
var _state_label: Label
var _counts_label: Label
var _log: RichTextLabel
var _buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# PAUSABLE world: counts frames and input events. Must freeze in pause.
	_pausable_probe = Node.new()
	_pausable_probe.name = "PausableProbe"
	_pausable_probe.process_mode = Node.PROCESS_MODE_PAUSABLE
	_pausable_probe.set_script(load("res://s4_probe.gd"))
	add_child(_pausable_probe)
	_pausable_probe.set("owner_ref", self)

	# ALWAYS UI layer: buttons that must keep focus navigation in pause.
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var box := VBoxContainer.new()
	box.position = Vector2(40, 30)
	box.custom_minimum_size = Vector2(900, 0)
	layer.add_child(box)

	_state_label = Label.new()
	box.add_child(_state_label)
	_tick_label = Label.new()
	box.add_child(_tick_label)
	_counts_label = Label.new()
	box.add_child(_counts_label)

	for i in 3:
		var b := Button.new()
		b.text = "Boton %d (ALWAYS)" % (i + 1)
		b.focus_entered.connect(_on_focus.bind(b))
		b.pressed.connect(_on_pressed.bind(b))
		box.add_child(b)
		_buttons.append(b)
	_buttons[0].grab_focus()

	_log = RichTextLabel.new()
	_log.custom_minimum_size = Vector2(900, 330)
	_log.scroll_following = true
	box.add_child(_log)

	Input.joy_connection_changed.connect(_on_joy_changed)
	_say("Listo. P = pausar/reanudar. Teclado: flechas/Tab/Enter. Mando: stick/cruceta/A. Conecta y desconecta el mando en pausa.")
	_say("Mandos detectados ahora: %s" % [Input.get_connected_joypads()])
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _input(event: InputEvent) -> void:
	_always_events += 1
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		get_tree().paused = not get_tree().paused
		_say("PAUSA = %s" % get_tree().paused)
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		_say("[ALWAYS] boton de mando %d (dispositivo %d)" % [event.button_index, event.device])
	elif event is InputEventKey and event.pressed and not event.echo:
		_say("[ALWAYS] tecla %s" % OS.get_keycode_string(event.keycode))


func note_pausable_event() -> void:
	_pausable_events += 1


func note_pausable_tick() -> void:
	_ticks += 1


func _refresh() -> void:
	_state_label.text = "paused = %s" % get_tree().paused
	_tick_label.text = "Frames del mundo PAUSABLE: %d (deben congelarse en pausa)" % _ticks
	_counts_label.text = "Eventos de entrada: ALWAYS=%d  PAUSABLE=%d (PAUSABLE no debe subir en pausa)" % [_always_events, _pausable_events]


func _on_focus(b: Button) -> void:
	_say("foco -> %s (paused=%s)" % [b.text, get_tree().paused])


func _on_pressed(b: Button) -> void:
	_say("pulsado -> %s (paused=%s)" % [b.text, get_tree().paused])


func _on_joy_changed(device: int, connected: bool) -> void:
	_say("MANDO %d %s (paused=%s)" % [device, "CONECTADO" if connected else "DESCONECTADO", get_tree().paused])


func _say(text: String) -> void:
	print("S4 ", text)
	if _log != null:
		_log.append_text(text + "\n")
