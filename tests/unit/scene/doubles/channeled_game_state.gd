## Test double: a GameState with a real notice channel (schema from NoticeIds) and scripted facts.
## Counts reads per fact and writes. It is a Node: the suite must auto_free() it.
class_name ChanneledGameState extends ScriptedGameState

var facts: Dictionary = {}
var reads: Dictionary = {}
var test_channel: NoticeChannel = NoticeChannel.new(64, RecordingLog.new(), ErrorPolicy.new(), NoticeIds.SCHEMA)


func get_channel() -> NoticeChannel:
	return test_channel


func get_fact(fact: StringName) -> Variant:
	reads[fact] = int(reads.get(fact, 0)) + 1
	if fact == &"llamada_completada":
		return call_completed
	return facts.get(fact, false)
