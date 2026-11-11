## Shared input vocabulary (ADR-0006 § Key Interfaces; system 1): enums and value classes only.
## The rest of the game knows logical actions, never engine events: `InputBinding` stores
## (`kind`, `code`, `axis_dir`), never an `InputEvent`.
## `Device` values are NOT engine device ids; never compare an engine `device` with them
## (spike S-0006-D: `DEVICE_ID_KEYBOARD` = 16, `DEVICE_ID_MOUSE` = 32, `DEVICE_ID_EMULATION` = -1).
## Example: `var b := InputTypes.InputBinding.new(); b.kind = InputTypes.RawKind.KEY; b.code = KEY_E`.
class_name InputTypes extends RefCounted

## Input contexts (GDD 1 rule 5).
enum Context { EXPLORACION, INSPECCION, LECTURA, VISTA_CERCANA, ORDENADOR, LLAMADA, MENU, SIN_CONTROL }
## Logical device families (not engine device ids).
enum Device { KEYBOARD_MOUSE = 0, GAMEPAD = 1, ACTIVE = -1 }
## Kind of a raw event or of a binding.
enum RawKind { KEY, MOUSE_BUTTON, MOUSE_MOTION, PAD_BUTTON, PAD_AXIS }
## Phase of a delivered action.
enum Phase { PRESSED, RELEASED, TAP, LONG, GESTURE_START, GESTURE_UPDATE, GESTURE_END, CANCELLED }
## Why a pause was requested.
enum PauseCause { ACTION, FOCUS_LOST, PAD_LOST }
## Gamepad glyph family.
enum PadFamily { XBOX, PLAYSTATION, GENERIC }
## Outcome of a rebind attempt (declared here; behaviour belongs to ADR-0007 stories).
enum RebindStatus { ASSIGNED, CONFLICT_SWAPPABLE, CONFLICT_NOT_SWAPPABLE, MINIMUM_VIOLATION,
		BACK_ONLY_PRINTABLE, SET_INCOMPLETE, DUPLICATE, NOT_REBINDABLE, INVALID_INPUT }

const OWNER_SCENE_LOADER: StringName = &"scene_loader"
const OWNER_SCENE_DIRECTOR: StringName = &"scene_director"
const OWNER_INPUT_ROUTER: StringName = &"input_router"


## One raw input sample, already detached from the engine event.
class RawInput extends RefCounted:
	var kind: RawKind
	## Keycode, mouse button index, JOY_BUTTON_*, or axis index.
	var code: int
	## Joypad id for PAD_*; unused for keyboard/mouse (never compared with 0).
	var device: int
	var pressed: bool
	## PAD_AXIS raw value.
	var value: float
	## MOUSE_MOTION relative pixels (S-0006-D).
	var motion: Vector2
	## Mouse position, logical px (ViewportMapper).
	var position: Vector2


## One assignment of a physical action: a key, button, mouse motion or axis half.
## Example: `b.kind = RawKind.PAD_AXIS; b.code = JOY_AXIS_LEFT_Y; b.axis_dir = -1`.
class InputBinding extends RefCounted:
	var kind: RawKind
	var code: int
	## -1/+1 for an axis half; 0 otherwise.
	var axis_dir: int = 0

	## True when `o` is the same assignment (kind, code and axis_dir).
	func equals(o: InputBinding) -> bool:
		return kind == o.kind and code == o.code and axis_dir == o.axis_dir


## One action delivered to the game.
class ActionEvent extends RefCounted:
	var action: StringName
	var phase: Phase
	## Cursor contexts (logical px).
	var position: Vector2
	## agarrar: delta p px; rotar: (delta phi degrees, 0).
	var delta: Vector2
	## PointerTarget.id at press, &"" if none.
	var target_id: StringName


## Result of a rebind attempt. Declared only; filled by the rebinding stories.
class RebindResult extends RefCounted:
	var status: RebindStatus
	var action: StringName
	var device: Device
	var slot: int
	var binding: InputBinding
	var conflict_action: StringName = &""
	var conflict_slot: int = -1
