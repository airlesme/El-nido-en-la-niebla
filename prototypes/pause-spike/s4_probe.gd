# PROTOTYPE - NOT FOR PRODUCTION
extends Node
## PAUSABLE probe for the S4 manual test: counts frames and input events.

var owner_ref: Node


func _process(_delta: float) -> void:
	if owner_ref != null:
		owner_ref.note_pausable_tick()


func _input(_event: InputEvent) -> void:
	if owner_ref != null:
		owner_ref.note_pausable_event()
