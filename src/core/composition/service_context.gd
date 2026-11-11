## Typed bag of injected services. Built by Boot; read-only after freeze() (ADR-0009 D3).
## TODO(ADR-0009): logger, fatal, files, ui, flash_guard, scene and for_scene() once
## LogSink, FatalErrorHandler, FileStore, UiPorts, FlashGuard and SceneServices exist.
class_name ServiceContext extends RefCounted

# --- Platform (layer 0) ---
var flavor: BuildFlavor
var real_clock: RealClock

# --- Foundation and Core: the 9 autoloads ---
var content: ContentDB
var state: GameState
var clock: GameClock
var input: InputRouter
var settings: Settings
var audio: AudioDirector
var save: SaveService
var scenes: SceneLoader
var director: SceneDirector

var _frozen: bool = false


## Seals the global context. Any later assignment is a programming error.
func freeze() -> void:
	_frozen = true


## True once Boot has sealed the context.
func is_frozen() -> bool:
	return _frozen
