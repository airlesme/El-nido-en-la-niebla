## Normalised value of one file plus every issue found reading it (ADR-0005 Key Interfaces).
## Example: `if result.has_errors(): log(result.first_error().format())`.
class_name DataResult extends RefCounted

## Normalised value; null when the file could not be parsed.
var value: Variant = null
## Every issue found, in discovery order.
var issues: Array[DataIssue] = []


## True when at least one issue has ERROR severity.
func has_errors() -> bool:
	return first_error() != null


## First ERROR issue, or null when there is none.
func first_error() -> DataIssue:
	for i: DataIssue in issues:
		if i.severity == DataIssue.Severity.ERROR:
			return i
	return null
