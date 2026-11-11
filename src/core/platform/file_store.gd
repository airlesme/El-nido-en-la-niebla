## File-reading seam (ADR-0009 D9; CD-001). The only place (with JsonText) that touches FileAccess.
## Production implementation reads from the real filesystem / res://; tests inject MemoryFileStore.
## TODO(ADR-0009): signature not fixed by any Accepted ADR (read-only minimum proposed by CD-001);
## writing/renaming is left to ADR-0004. Register as Open Item in ADR-0009, lead-programmer review pending.
## Example: `var bytes := store.read_bytes("res://assets/data/x.json"); if store.last_error() != OK: ...`.
class_name FileStore extends RefCounted

var _last_error: Error = OK


## Reads the whole file as raw bytes. On failure returns an empty array and `last_error()` is
## non-OK (e.g. ERR_FILE_NOT_FOUND); an existing empty file also returns empty with OK.
## The open error is read immediately after opening (F-R57).
func read_bytes(path: String) -> PackedByteArray:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		_last_error = FileAccess.get_open_error()
		if _last_error == OK:
			_last_error = FAILED
		return PackedByteArray()
	_last_error = OK
	return f.get_buffer(f.get_length())


## Error of the most recent `read_bytes` call (OK when it succeeded).
func last_error() -> Error:
	return _last_error
