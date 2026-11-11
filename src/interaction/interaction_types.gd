## Shared enums and constants of the interaction system (ADR-0011 Key Interfaces, `interaction_types.gd`).
## Only the enums and constants fixed by the ADR live here; the inner value classes (`ContactInfo`,
## `PointerEvent`) arrive with the stories that use them (IP-002 and later).
## Example: `InteractionTypes.LAYER_INTERACTABLE` is `1 << 2` (bit 3 of the 3D physics layers).
class_name InteractionTypes extends RefCounted

enum InteractResult { SI, NO, SIN_EFECTO }
enum InteractOutcome { HECHO, SIN_EFECTO }
enum Mode { NINGUNO, INSPECCION, LECTURA, VISTA, ORDENADOR }
enum Fase { INICIO, ACTUALIZACION, FIN, CANCELACION }
enum FovAxis { VERTICAL, HORIZONTAL }

const RESULTADO_HECHO: StringName = &"HECHO"
const RESULTADO_SIN_EFECTO: StringName = &"SIN_EFECTO"
const RESULTADO_GESTO_RECHAZADO: StringName = &"GESTO_RECHAZADO"
const RESULTADO_TOQUE_CORTO: StringName = &"TOQUE_CORTO"
## Sentinel of `duracion_pie` (not INF: survives JSON and clamping).
const PIE_PERSISTENTE: float = -1.0
## World geometry, bit 1 (ADR-0011 D1): the only layer the occlusion ray masks.
const OCCLUSION_MASK: int = 1 << 0
## Interactable pick volumes, bit 3 (ADR-0011 D1).
const LAYER_INTERACTABLE: int = 1 << 2


## F1 contact of one pick volume (ADR-0011 Key Interfaces). Instances live in a pre-sized pool that is
## refilled every step (G-10), never allocated per step.
class ContactInfo extends RefCounted:
	## `PickRegistry` index of the entry.
	var entry: int = -1
	## Axis depth of the contact point (m).
	var d_c: float = 0.0
	## Distance from the box to the eye ray (m); 0 when `contains_axis`.
	var delta: float = 0.0
	var contains_axis: bool = false
	var contact_point: Vector3 = Vector3.ZERO
