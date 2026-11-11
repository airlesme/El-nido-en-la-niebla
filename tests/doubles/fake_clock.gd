## Test double for GameClock: never self-advances. It is a Node, so the suite must auto_free() it.
## TODO(ADR-0002): integer-tick advance()/set_paused() once GameClock's API is signed.
class_name FakeClock extends GameClock


func _process(_delta: float) -> void:
	return
