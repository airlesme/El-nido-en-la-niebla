## Closed registry of notice names and payload schemas (ADR-0001 D3, D4, § Notice Name Registry).
## Every named notice of GDD 3 rule 10 is one `StringName` constant here; no other script spells a
## notice name as a string literal (G-2). Adding a notice needs an ADR-0001 amendment plus the
## GDD 3 rule 10 row.
## Settings' own channel (`settings_applied`, ADR-0007) is NOT in this registry.
## `SCHEMA` maps notice name -> { payload key (StringName) -> [Variant.Type, optional: bool] }.
## `NoticeChannel` validates it in debug builds only. Keys marked "proposed" in the ADR (double
## dagger) may change only through the ADR that owns the payload.
## Example:
## [codeblock]
## channel.notify(NoticeIds.SCENE_READY, {&"destino": &"hall"})
## [/codeblock]
class_name NoticeIds extends RefCounted

# Type shorthands used by SCHEMA (SN = StringName, F = float, I = int, A = Array, D = Dictionary).
const _SN: int = TYPE_STRING_NAME
const _F: int = TYPE_FLOAT
const _I: int = TYPE_INT
const _A: int = TYPE_ARRAY
const _D: int = TYPE_DICTIONARY

# --- System 3 (state) ---
const STATE_RESET: StringName = &"state_reset"
const STATE_RESTORED: StringName = &"state_restored"
## Also emitted by Settings' own channel instance.
const NOTICES_DROPPED: StringName = &"notices_dropped"

# --- System 1 (input) ---
const INPUT_DEVICE_CHANGED: StringName = &"input_device_changed"
const INPUT_CONTEXT_CHANGED: StringName = &"input_context_changed"
const NO_CONTROL_ABSORBED: StringName = &"no_control_absorbed"

# --- System 4 (scenes) ---
const SCENE_LOAD_STARTED: StringName = &"scene_load_started"
const SCENE_READY: StringName = &"scene_ready"
const SCENE_LOAD_FINISHED: StringName = &"scene_load_finished"
const SCENE_LOAD_FAILED: StringName = &"scene_load_failed"
const FULL_UNLOAD_REQUESTED: StringName = &"full_unload_requested"
const FULL_UNLOAD_COMPLETED: StringName = &"full_unload_completed"
const ZONE_ENTERED: StringName = &"zone_entered"
## «partida terminada»: system 4 is the SOLE emitter (CA-36).
const GAME_FINISHED: StringName = &"game_finished"

# --- System 5 (save) ---
const SAVE_AT_RISK: StringName = &"save_at_risk"
const SAVE_RECOVERED: StringName = &"save_recovered"

# --- System 7 (interaction / close views / reading) ---
const CLOSE_VIEW_OPENED: StringName = &"close_view_opened"
const CLOSE_VIEW_CLOSED: StringName = &"close_view_closed"
const READING_OPENED: StringName = &"reading_opened"
const READING_COMPLETED: StringName = &"reading_completed"
const READING_CLOSED: StringName = &"reading_closed"
const READING_DISCARDED: StringName = &"reading_discarded"
const MODES_CLOSED: StringName = &"modes_closed"
## Consumers other than system 24 must filter with `InteractionNotice.is_done` (D11, G-12).
const INTERACTION_EXECUTED: StringName = &"interaction_executed"

# --- Shared requests (7, 8, 9, 10, 15, 17, 19, 21, 22, 25) ---
const SOUND_REQUESTED: StringName = &"sound_requested"
const LINE_REQUESTED: StringName = &"line_requested"

# --- System 8 / 21 (world) ---
const DOOR_OPENED: StringName = &"door_opened"
const ELEVATOR_CALLED: StringName = &"elevator_called"
const ELEVATOR_REJECTED: StringName = &"elevator_rejected"
const SCENE_EFFECT_REQUESTED: StringName = &"scene_effect_requested"
## System 21 is the sole emitter.
const OBJECT_STATE_REQUESTED: StringName = &"object_state_requested"
const END_CARD_REQUESTED: StringName = &"end_card_requested"

# --- System 9 (puzzles); the EV_ names are fixed by the GDD and kept literally ---
const EV_PUZZLE_SOLVED_P1: StringName = &"EV_PUZZLE_SOLVED_P1"
const EV_PUZZLE_SOLVED_P2: StringName = &"EV_PUZZLE_SOLVED_P2"
const EV_PUZZLE_SOLVED_P3: StringName = &"EV_PUZZLE_SOLVED_P3"
const EV_PUZZLE_SOLVED_P4: StringName = &"EV_PUZZLE_SOLVED_P4"
const EV_PUZZLE_SOLVED_P5: StringName = &"EV_PUZZLE_SOLVED_P5"
const EV_PUZZLE_SOLVED_P6: StringName = &"EV_PUZZLE_SOLVED_P6"
const COMPARTMENT_COMPLETED: StringName = &"compartment_completed"
const PUZZLE_ACTIVATED: StringName = &"puzzle_activated"
const PUZZLE_RESOLUTION_INTERRUPTED: StringName = &"puzzle_resolution_interrupted"
const HINT_APPLIED: StringName = &"hint_applied"
const PUZZLE_IDLE: StringName = &"puzzle_idle"
const PUZZLE_FEEDBACK: StringName = &"puzzle_feedback"
const PUZZLES_CONFIGURED: StringName = &"puzzles_configured"

# --- Systems 22 / 23 (calls and lines) ---
const CALL_STARTED: StringName = &"call_started"
const CALL_COMPLETED: StringName = &"call_completed"
const LINE_STARTED: StringName = &"line_started"
const LINE_FINISHED: StringName = &"line_finished"
const LINE_NO_AUDIO: StringName = &"line_no_audio"
const LINE_FAILED: StringName = &"line_failed"

# --- System 25 (pause); names fixed by GDD 25 ---
const PAUSE_OPENED: StringName = &"pause_opened"
const PAUSE_CLOSED: StringName = &"pause_closed"

## notice name -> { key -> [Variant.Type, optional] }. An empty dictionary means "no payload".
const SCHEMA: Dictionary = {
	&"state_reset": {},
	&"state_restored": {},
	&"notices_dropped": {},
	&"input_device_changed": {&"dispositivo": [_SN, false]},
	&"input_context_changed": {&"anterior": [_SN, false], &"contexto": [_SN, false]},
	&"no_control_absorbed": {&"dueno": [_SN, false]},
	&"scene_load_started": {
		&"destino": [_SN, false], &"motivo": [_SN, false],
		&"control_final": [_SN, false], &"D_carga": [_F, false],
	},
	&"scene_ready": {&"destino": [_SN, false]},
	&"scene_load_finished": {
		&"destino": [_SN, false], &"motivo": [_SN, false],
		&"control_final": [_SN, false], &"t_since_started_s": [_F, false],
	},
	&"scene_load_failed": {&"destino": [_SN, false], &"motivo": [_SN, false], &"causa": [_SN, false]},
	&"full_unload_requested": {},
	&"full_unload_completed": {},
	&"zone_entered": {&"zona": [_SN, false]},
	&"game_finished": {},
	&"save_at_risk": {},
	&"save_recovered": {},
	&"close_view_opened": {&"vista": [_SN, false]},
	&"close_view_closed": {&"vista": [_SN, false], &"motivo": [_SN, false]},
	&"reading_opened": {&"doc": [_SN, false]},
	&"reading_completed": {&"doc": [_SN, false]},
	&"reading_closed": {&"doc": [_SN, false], &"motivo": [_SN, false]},
	&"reading_discarded": {&"doc": [_SN, false], &"motivo": [_SN, false]},
	&"modes_closed": {&"lista": [_A, false]},
	&"interaction_executed": {&"id": [_SN, false], &"verbo": [_SN, false], &"resultado": [_SN, false]},
	&"sound_requested": {
		&"sound_id": [_SN, false], &"fuente": [_SN, true],
		&"accion": [_SN, false], &"valor": [_F, true],
	},
	&"line_requested": {
		&"line_id": [_SN, false], &"fuente": [_SN, true],
		&"fallback_s": [_F, true], &"puzzle": [_SN, true],
	},
	&"door_opened": {&"puerta": [_SN, false]},
	&"elevator_called": {},
	&"elevator_rejected": {},
	&"scene_effect_requested": {
		&"id": [_SN, false], &"objetivo": [_SN, true],
		&"duracion": [_F, false], &"parametros": [_D, false],
	},
	&"object_state_requested": {&"objeto": [_SN, false], &"estado": [_SN, false]},
	&"end_card_requested": {&"titulo_key": [_SN, false], &"rotulo_key": [_SN, false], &"duracion_s": [_F, false]},
	&"EV_PUZZLE_SOLVED_P1": {&"puzzle": [_SN, false], &"rewards": [_A, false], &"choice": [_SN, true]},
	&"EV_PUZZLE_SOLVED_P2": {&"puzzle": [_SN, false], &"rewards": [_A, false], &"choice": [_SN, true]},
	&"EV_PUZZLE_SOLVED_P3": {&"puzzle": [_SN, false], &"rewards": [_A, false], &"choice": [_SN, true]},
	&"EV_PUZZLE_SOLVED_P4": {&"puzzle": [_SN, false], &"rewards": [_A, false], &"choice": [_SN, true]},
	&"EV_PUZZLE_SOLVED_P5": {&"puzzle": [_SN, false], &"rewards": [_A, false], &"choice": [_SN, true]},
	&"EV_PUZZLE_SOLVED_P6": {&"puzzle": [_SN, false], &"rewards": [_A, false], &"choice": [_SN, true]},
	&"compartment_completed": {&"n": [_I, false]},
	&"puzzle_activated": {&"puzzle": [_SN, false], &"ajar_cm": [_F, true]},
	&"puzzle_resolution_interrupted": {&"puzzle": [_SN, false]},
	&"hint_applied": {&"id": [_SN, false], &"nivel": [_I, false], &"text_key": [_SN, true]},
	&"puzzle_idle": {&"id": [_SN, false], &"nivel": [_I, false]},
	&"puzzle_feedback": {
		&"puzzle": [_SN, false], &"sound_id": [_SN, false],
		&"text_key": [_SN, true], &"element": [_SN, true],
	},
	&"puzzles_configured": {},
	&"call_started": {},
	&"call_completed": {},
	&"line_started": {&"line_id": [_SN, false], &"duracion_s": [_F, false], &"canal": [_SN, false]},
	&"line_finished": {&"line_id": [_SN, false], &"motivo": [_SN, false]},
	&"line_no_audio": {&"line_id": [_SN, false], &"t_lectura_s": [_F, false]},
	&"line_failed": {&"line_id": [_SN, false], &"t_lectura_s": [_F, false]},
	&"pause_opened": {},
	&"pause_closed": {},
}
