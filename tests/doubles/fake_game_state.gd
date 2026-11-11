## Test double for GameState (setup() is skipped). It is a Node, so the suite must auto_free() it.
## TODO(ADR-0001): in-memory facts and writer-id recording once GameState's API exists.
class_name FakeGameState extends GameState
