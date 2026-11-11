## Optional per-file semantic checks that a FieldSpec tree cannot express (ADR-0005 D2.2):
## cycles, injectivity, ordering. Run by DataReader after a clean normalisation.
## Subclass and override `check`; the base does nothing.
## Example: `class OrderRules extends FileRules: func check(value, file, issues): ...`.
class_name FileRules extends RefCounted


## Inspects the normalised `value` of `file` and appends DataIssues. Never throws.
func check(_value: Variant, _file: String, _issues: Array[DataIssue]) -> void:
	pass
