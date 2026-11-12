## Main scene root (ADR-0003 D1/D2): never unloaded, never replaced by change_scene_*.
## Children, in order: Boot (composition root, MUST be first so compose() runs before any
## sibling's _ready), WorldSlot (at most one game scene, touched only by SceneLoader), and
## the CanvasLayers HUD < Subtitles < PauseMenu < Curtain < ErrorPanel (C-R12).
## TODO(lead-programmer): amend ADR-0009 ("Boot is the first autoload" -> "Boot is the first child of Shell").
class_name Shell extends Node


## Node names the rest of the code relies on.
const WORLD_SLOT_NAME: StringName = &"WorldSlot"
const CURTAIN_NAME: StringName = &"Curtain"
const ERROR_PANEL_NAME: StringName = &"ErrorPanel"

@onready var world_slot: Node3D = %WorldSlot
@onready var curtain: Curtain = %Curtain
@onready var error_panel: ErrorPanel = %ErrorPanel

## TODO(carga-014): boot.gd must wire `scene_loader.set_error_panel_port(error_panel.show_error)` and
## `error_panel.set_unload_port(scene_loader.request_full_unload)` (owner: CP-006/boot).
