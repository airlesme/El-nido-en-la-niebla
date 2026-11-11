# PROTOTYPE - NOT FOR PRODUCTION
# Question: which call halts in a debug build and which is a no-op in a release export (NS-4)?
# Date: 2026-11-11
extends Node
## ADR-0001 V-ENG-4 spike: what stops execution in a debug build and what is a no-op in release.
## Prints SPIKE lines to stdout; the last line is only reached if assert(false) did not halt.


func _ready() -> void:
	print("SPIKE is_debug_build=", OS.is_debug_build(), " release=", OS.has_feature("release"), " debug=", OS.has_feature("debug"), " editor=", OS.has_feature("editor"))
	push_error("SPIKE push_error called")
	print("SPIKE after push_error: execution continued")
	push_warning("SPIKE push_warning called")
	print("SPIKE after push_warning: execution continued")
	_assert_probe()
	print("SPIKE after assert-probe caller: execution continued")
	get_tree().quit()


func _assert_probe() -> void:
	print("SPIKE before assert(false)")
	assert(false, "SPIKE assert(false) fired")
	print("SPIKE after assert(false): NOT halted")
