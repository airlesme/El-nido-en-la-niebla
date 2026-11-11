## Test double for FileStore: dict path -> bytes, counts accesses, injectable failures (ADR-0009 D9).
## Example: `var s := MemoryFileStore.new(); s.put_text("a.json", "{}"); s.read_bytes("a.json")`.
class_name MemoryFileStore extends FileStore

## path -> PackedByteArray
var files: Dictionary = {}
## path -> Error to return instead of the content.
var failures: Dictionary = {}
## Total number of read_bytes calls.
var access_count: int = 0
## path -> number of read_bytes calls.
var access_by_path: Dictionary = {}


func put_text(path: String, text: String) -> void:
	files[path] = text.to_utf8_buffer()


func put_bytes(path: String, bytes: PackedByteArray) -> void:
	files[path] = bytes


func fail(path: String, err: Error) -> void:
	failures[path] = err


func accesses_of(path: String) -> int:
	return int(access_by_path.get(path, 0))


func read_bytes(path: String) -> PackedByteArray:
	access_count += 1
	access_by_path[path] = accesses_of(path) + 1
	if failures.has(path):
		_last_error = failures[path] as Error
		return PackedByteArray()
	if not files.has(path):
		_last_error = ERR_FILE_NOT_FOUND
		return PackedByteArray()
	_last_error = OK
	return files[path] as PackedByteArray
