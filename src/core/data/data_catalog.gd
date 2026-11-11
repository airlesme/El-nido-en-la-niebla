## Registry of loadable data files (ADR-0005 D1).
## TODO(CD-003): story 003 adds the full registry (ALL, LoadPoint, ordering). CD-002 only needs
## the minimal Entry type that DataReader.read_file consumes.
class_name DataCatalog extends RefCounted


## One registered file: its path relative to assets/data/ and its schema.
class Entry extends RefCounted:
	## Path relative to assets/data/, e.g. "puzzles/puzzles.json".
	var rel_path: String
	## The single schema of this file (same object for tiers L, B and C).
	var schema: DataSchema


	func _init(p_rel_path: String, p_schema: DataSchema) -> void:
		rel_path = p_rel_path
		schema = p_schema
