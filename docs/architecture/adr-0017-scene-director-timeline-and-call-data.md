# ADR-0017: Scene director timeline and call data

## Status

Accepted (2026-11-11) — no spike required; A1–A6 amendments recorded in Open Items to apply when the first story touches them (C3 amendment in ADR-0008)

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories referencing a `Proposed` ADR are set `Blocked`; epics require
> `Accepted`. An agent that believes this ADR is ready escalates; it does not
> edit this field.

## Date

2026-11-10

## Last Verified

2026-11-10 — against Godot 4.7 references in `docs/engine-reference/godot/`
(pin 4.7.2), ADR-0001…0009 (all `Proposed`, reconciled 2026-11-10), GDD 21
(round 10), GDD 22 (round 9), GDD 9 F8, GDD 23 D23-27, GDD 27 rules 23–25,
GDD 28 rules 9, 18, 21.

## Decision Makers

technical-director (autonomous mode, `modes.automation: autonomous`; user
approval at batch end). Inputs: GDD authors of 21, 22, 9, 23, 27, 28.

## Summary

Systems 21 (`SceneDirector`, persistent autoload #9) and 22 (`CallController`,
`planta` scene node) need data formats, a game-time sequencing primitive and
the payloads of three notices the bus registry left ‡ (QQ-20). This ADR fixes
`director/scenes.json`, `director/director_config.json` and `call/call.json`;
one polled, cancellable **cue timeline** (`CueTimeline`) and one **step chain**
(`StepChain`) with an event-or-cap wait (`LineWait`), all reading `GameClock`;
the payloads of `scene_effect_requested`, `object_state_requested` and
`end_card_requested`; the 22 state machine on `GameClock` deadlines (20 s wait,
variants, interrupt); and the runtime contract of the 16 s P5 reveal as a
client of `StepChain` (its data stays with ADR-0010).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable) |
| **Domain** | Core (timing, data); Events |
| **Layer** | Feature |
| **Knowledge Risk** | LOW — pure GDScript `RefCounted` logic over project classes (`GameClock`, `GameState`, `InputContexts`); the only engine surface is `Node._process`, `process_mode` (owned by ADR-0002) and JSON parsing (owned by ADR-0005) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `breaking-changes.md` (4.7 "Overrides inherit a typed return"; 4.5 `@abstract`); `current-best-practices.md` (`@abstract`, autoload `--check-only` caveat l. 220); `deprecated-apis.md` (cached references in `_process`); `modules/audio.md` (anti-pattern "`_process()` for audio timing" — not applicable: no audio timing here, 23 answers by notice) |
| **Post-Cutoff APIs Used** | GDScript 4.7 typed-return override rule (any `StepChain` step subclass overriding a typed method needs an explicit `return`); typed `Dictionary[K, V]` as already caveated in ADR-0002 § Key Interfaces notes. No `@abstract` is required by this ADR |
| **Verification Required** | (V1) parse check on 4.7.2 of every class in § Key Interfaces; (V2) per-frame order between `GameClock._process` and `SceneDirector._process` — **NOT SOURCEABLE — autoload/tree processing order and `process_priority` not covered by `docs/engine-reference/godot/`**; the design tolerates either order (± 1 frame, D2.4), the test pins the order explicitly |

> Knowledge Risk is LOW, but if the project upgrades from 4.7 the V1 parse
> check reruns before this ADR's stories close.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (bus, `NoticeIds`, payload schema, I-5 same-frame delivery), ADR-0002 (`GameClock` `now`/`deadline`/`is_due`, `reset_session`, D6 timer ban, `SceneDirector` `ALWAYS`), ADR-0003 (D6 handoff, «terminada» payload with `control_final`/`t_since_started_s`, `request_fade_out`, `request_full_unload`), ADR-0004 (seal by `call_started`; 22 never calls `request_save`), ADR-0005 (registry rows `director/*`, `call/call.json`, record isolation, tiers L/B/C), ADR-0006 (`InputContexts` signatures, owner `&"scene_director"`), ADR-0007 (`SettingsReader` for `reducir_movimiento`), ADR-0008 (voice channels, queue of 1, `t_cola_canal_s`, `t_interrupt_s`, line answers), ADR-0009 (autoload #9, `setup(ctx)`, `SceneBindable`, `ServiceContext`) |
| **Enables** | ADR-0010 (P5 `DEFERRED` reveal reuses `StepChain`/`LineWait`), ADR-0014 (28 consumes `scene_effect_requested`), ADR-0016 (end-card host layer) |
| **Blocks** | Epic 21 «Director de escenas»; epic 22 «Llamada telefónica»; 28 effect stories; 27 end-card story; M3 |
| **Ordering Note** | Stories of 21/22 may start once ADR-0001/0002/0003/0009 are `Accepted`; the 9 P5 reveal story also needs ADR-0010. Amendments A1–A6 (§ Open Items) are applied in the target ADRs at the next reconciliation, not here |

## Context

### Problem Statement

GDD 21 rule 3 and GDD 22 Tuning Knobs leave three things to "the ADR of timed
events": the data format of scenes and call times, the timeline executor, and
the payloads of «efecto de escena pedido», «estado de objeto pedido» and
«tarjeta final pedida» (ADR-0001 registry rows marked "‡ ADR-0017";
`architecture.md` QQ-20). Without them 21 and 22 cannot be implemented and 28,
23 and 27 have no input contract. Three systems (9 P5, 21 cierre, 22) also
share one pattern — "wait for a line, or a cap, in game time" — that would
otherwise be written three times with three subtly different deadline bugs.

### Current State

Design only. ADR-0005 fixed the file paths and the JSON roots
(`director/scenes.json`, `director/director_config.json`, `call/call.json`)
and deferred fields, the `orden` catalog and ranges to this ADR. ADR-0002
gives `GameClock` and forbids `Timer`/`SceneTreeTimer`. ADR-0003 delivers
«carga de escena terminada» `{destino, motivo, control_final, t_since_started_s}`
and calls `GameClock.reset_session()` in step 4 of every load. ADR-0008 owns
the per-channel voice queue (queue of 1, `t_cola_canal_s`) and answers every
accepted line exactly once.

### Constraints

- All game time from `GameClock` (ADR-0002 G-1); no `Timer`, no
  `create_timer` (G-3); pause freezes everything by construction.
- `GameClock.reset_session()` runs at step 4 of **every** load (ADR-0003):
  game time restarts at 0 and the schedule is cleared. Nothing in 21 may carry
  an absolute game-time value across a load.
- 21 is an autoload (`ALWAYS`), so its `_process` runs during pause; frozen
  `GameClock.now()` is what stops it.
- 21 never writes facts (TR-director-007); 22 is the only writer of the three
  call facts (TR-call-014).
- Notices are delivered FIFO, non-reentrant, same frame (ADR-0001 D5, I-5).
- Data-driven values (coding standards); IDs of the slice kept literally.
- Solo developer, slice timeline: one mechanism, small surface, testable
  headlessly with a manually advanced `GameClock`.

### Requirements

- Cues fire in the first frame with `t_rel ≥ t_i`, all due cues in table
  order, once each (TR-director-005); ± 1 frame (TR-director-006).
- Cancel without side effects on «carga de escena fallida», unrequested
  «iniciada», `no_control_absorbed` (`dueno = &"scene_director"`), full unload
  (TR-director-002, -014).
- `ESC8_CIERRE` bounded by `D_cierre` = 25,8 s with hard cap `t_duro` = 24,8 s
  (TR-director-022).
- Call: game-time machine, ± 0,05 s (TR-call-005), 20 s wait once
  (TR-call-010), interrupt (TR-call-011), never blocked by audio
  (TR-call-015).
- P5 reveal: 16,0 s nominal, [2,0, 18,0] s range (GDD 9 F8), frozen in pause,
  cancellable by view close, replayed from step 1 after reload.
- No per-frame allocation in the steady state; < 0,05 ms CPU per frame for 21
  and 22 together on the reference machine (ADR-0019 sets the real budget).

## Decision

Ten sub-decisions, D1–D10. Values marked † are GDD-proposed and live in data.

### D1 — `director/scenes.json`: declarative trigger + conditions + cues; procedural rules stay in code

`scenes.json` describes **what** each scene emits and **when**; the five
procedural rules that depend on load reasons, stack state or the call
(rule 8 handoff, rule 11 cancellation, rule 14 resume, rule 15 `V02`
hand-back, rule 17 elevator) are code in `SceneDirector`, parametrised by
`director_config.json`. Rationale: those rules have one instance each in the
slice; encoding them as data would be a scripting language with one user.

Root (ADR-0005 D2.5, fields fixed here):

```json
{ "schema_version": 1,
  "scenes": [
    { "id": "ESC1_LLEGADA", "tipo": "dirigida",
      "disparador": { "kind": "scene_ready", "destino": "planta", "motivo": "partida_nueva" },
      "condiciones": [],
      "t_fin": 14.0,
      "linea_de_tiempo": [
        { "t_rel": 1.5,  "orden": "linea",  "line_id": "VO_V_01" },
        { "t_rel": 6.0,  "orden": "linea",  "line_id": "MEGA_01", "fuente": "C01" },
        { "t_rel": 12.0, "orden": "efecto", "efecto": "TELEFONO_PULSOS", "objetivo": "V02",
          "duracion": 3.0, "parametros": { "pulsos": 3, "pulso_s": 1.0 } },
        { "t_rel": 12.0, "orden": "efecto", "efecto": "TELEFONO_MENSAJE", "objetivo": "V02",
          "duracion": 0.0, "parametros": { "text_key": "TEL_MENSAJE_JUGAMOS" } },
        { "t_rel": 12.0, "orden": "marca",  "marca": "mensaje_telefono_pendiente", "valor": true }
      ] },
    { "id": "ESC4_PASILLO_MEGA", "tipo": "momento",
      "disparador": { "kind": "notice", "notice": "zone_entered", "match": { "zona": "T-PAS-1" } },
      "condiciones": [ { "fact": "caja_completa", "value": false },
                       { "marca": "esc4_mega_hecha", "value": false } ],
      "al_disparar": [ { "marca": "esc4_mega_hecha", "valor": true } ],
      "linea_de_tiempo": [
        { "t_rel": 0.0, "orden": "linea", "line_id": "MEGA_02", "fuente": "C01" },
        { "t_rel": 2.0, "orden": "efecto", "efecto": "LUCES_PARPADEO", "objetivo": "C03",
          "duracion": 1.15, "parametros": { "veces": 3, "caida_s": 0.15 },
          "si_reducir_movimiento": { "duracion": 0.6, "parametros": { "veces": 1, "caida_s": 0.6 } } }
      ] },
    { "id": "ESC7_APAGON", "tipo": "momento",
      "disparador": { "kind": "notice", "notice": "zone_entered", "match": { "zona": "T-D-OUT" } },
      "condiciones": [ { "fact": "caja_completa", "value": true },
                       { "marca": "apagon_activo", "value": false } ],
      "al_disparar": [ { "marca": "apagon_activo", "valor": true },
                       { "marca": "mensaje_telefono_pendiente", "valor": false } ],
      "linea_de_tiempo": [
        { "t_rel": 0.0,  "orden": "efecto", "efecto": "LUCES_APAGON", "objetivo": "C03", "duracion": 0.4, "parametros": {} },
        { "t_rel": 1.0,  "orden": "efecto", "efecto": "SILLAS_RODANDO", "duracion": 3.0, "parametros": {} },
        { "t_rel": 4.5,  "orden": "efecto", "efecto": "TECLEO_LEJANO",  "duracion": 3.0, "parametros": {} },
        { "t_rel": 60.0, "knob": "t_timbre_pasillo_s", "orden": "estado_objeto",
          "objeto": "V02", "estado": "vibrando",
          "solo_si": [ { "fact": "llamada_iniciada", "value": false } ] }
      ] },
    { "id": "ESC8_CIERRE", "tipo": "dirigida",
      "disparador": { "kind": "notice", "notice": "reading_completed", "match": { "doc": "R01" } },
      "condiciones": [ { "fact": "llamada_completada", "value": true },
                       { "marca": "cierre_iniciado", "value": false } ],
      "al_disparar": [ { "marca": "cierre_iniciado", "valor": true } ],
      "linea_de_tiempo": [],
      "cadena": "CIERRE" }
  ] }
```

Field rules:

1. **`disparador.kind`** ∈ {`scene_ready`, `notice`, `fact_changed`}.
   `scene_ready` matches `destino` and optionally `motivo` (the `motivo` comes
   from the preceding `scene_load_started`, cached by 21). `notice` names a
   `NoticeIds` constant from the allow-list {`zone_entered`,
   `interaction_executed`, `reading_completed`, `EV_PUZZLE_SOLVED_P2`,
   `elevator_called`} and an exact-match `match` object on payload keys;
   `interaction_executed` **must** include `"resultado": "HECHO"` (ADR-0001
   D11, validated). `fact_changed` names a fact and the new value
   (`formulario_leido` → `true`, `llamada_completada` → `true`).
2. **`condiciones`** and cue-level **`solo_si`**: conjunction of
   `{fact, value}` (read from `GameState` at evaluation time) and
   `{marca, value}` (volatile flag). `condiciones` are evaluated at the
   trigger; `solo_si` at the cue's emission (the `¬llamada_iniciada` guard of
   the 60 s ring, D21-28).
3. **`marca`** names are the closed set of TR-director-015:
   `esc4_mega_hecha`, `esc4_reflejo_hecho`, `apagon_activo`,
   `mensaje_telefono_pendiente`, `cierre_iniciado`. `al_disparar` sets them in
   the trigger frame, before any cue; `orden: marca` sets one at its `t_rel`.
   Volatile flags are never facts and never saved.
4. **`orden`** catalog (closes ADR-0005's "`orden` ENUM ‡"): `linea`
   (`line_id`, `fuente?`; prefix **must** be `VO_V_` or `MEGA_`, rule 7),
   `efecto` (`efecto`, `objetivo?`, `duracion`, `parametros`, optional
   `si_reducir_movimiento` overlay merged over `duracion`/`parametros`),
   `estado_objeto` (`objeto`, `estado`), `marca` (`marca`, `valor`). Control
   (`exploración`), fades, the end card and the full unload are **not** cue
   orders: the first is implied by `t_fin`, the rest only exist in the
   `CIERRE` chain (D4).
5. **`t_rel`** FLOAT ≥ 0, non-decreasing in table order; `knob` is a
   traceability label naming the GDD 21 Tuning Knob that value implements
   (`t_timbre_pasillo_s`, `retardo_restaurar_s`, `d_vo04_s`, `d_vo08_s`,
   `d_realce_lluvia_s`); the value lives in the cue, once.
6. **`dirigida`** requires `t_fin` (1–30) and either a `cadena` or
   `t_fin ≥ last t_rel`; `duracion_declarada` is **computed** at load as
   `t_fin + h_decl_s` (F2) and may appear in the file only if equal
   (± 0,001) — two sources for one number is the drift ADR-0005 forbids.
   `momento` must not have `t_fin` or `cadena`.
7. **`cadena`** names a code chain (`CIERRE` only in the slice; D4) whose
   step durations come from `director_config.json`.

The full slice catalog (11 records of GDD 21 rule 4) is authored from that
table literally; the four records above are the normative examples.

**`director/director_config.json`** (fatal `CATALOGO_INVALIDO` if invalid,
ADR-0005 registry):

| Key | Default | Range | GDD 21 source |
|---|---|---|---|
| `h_decl_s` | 1.0† | 0.5–3.0 | F2 |
| `t_linea_max_s` | 8.0† | 4–15 | F3, F4 |
| `t_modos_max_s` | 2.0† | 1.0–3.0 | F4, rule 20 |
| `g_post_lectura_s` | 3.0 | 1–6 | rule 21 |
| `g_entre_lineas_s` | 3.0 | 1–6 | F3 |
| `g_pre_fundido_s` | 2.0 | 1–4 | F3 |
| `t_tarjeta_s` | 3.0 | 2–5 | F3 |
| `ascensor_t_fin_s` | 6.0 | 1–30 | rule 18 (mirrors `ESC8_ASCENSOR.t_fin`; validated equal) |
| `cierre_lineas` | `{"A":"VO_V_12A","B":"VO_V_12B","C":"VO_V_12C","D":"VO_V_12D"}` | keys = `respuesta_llamada` values | rule 22 (2) |
| `cierre_linea_final` | `"VO_V_12E"` | `VO_V_*` | rule 22 (4) |
| `tarjeta` | `{"titulo_key":"UI_TITULO_JUEGO","rotulo_key":"UI_CONTINUARA"}` ‡ | `content_key` refs | rule 22 (7), GDD 27 rule 24 |

Not in this file, by single-owner rule: `t_cola_canal_s` and `t_interrupt_s`
(23, ADR-0008), `margen_E` (1, ADR-0006), `d_cierre` (4's `load_transitions`
row `cierre`, read through `SceneLoader`, A2), `atenuacion_reducida_s` (it is
the `si_reducir_movimiento` overlay value in the `ESC4_PASILLO_MEGA` cue).

### D2 — `CueTimeline`: one polled run per active scene, origin-relative, cancel-by-drop

1. **Run.** Starting a scene creates a `CueRun` (`RefCounted`) holding the
   scene record, `origin_s = clock.now()` and `next` = 0. `t_rel` is **always
   recomputed** as `clock.now() − origin_s`; it is never accumulated. This
   equals F1 (`t_rel(n) = t_rel(n−1) + Δ_juego(n)`) exactly, because
   `GameClock` already integrates the clamped, pause-aware Δ (ADR-0002 D1),
   and it satisfies G-1 (no private integrator).
2. **Tick.** `SceneDirector._process` (autoload, `ALWAYS`) calls
   `tick()` on every live run once per frame. `tick` emits every cue with
   `t_rel ≥ cue.t_rel`, in table order, once, then (for `dirigida` with
   control) requests `exploración` if `t_rel ≥ t_fin`. A run is also ticked
   **immediately on start** inside the trigger's delivery, so `t_rel = 0` cues
   leave in the trigger frame (bus I-5: queued and delivered in the same drain).
3. **Pause / focus / pad.** Nothing to do: `clock.now()` is frozen, so no cue
   becomes due; the already-emitted effects freeze with the tree or by their
   executors (28, 23). No run is cancelled by pause.
4. **Frame order.** If `GameClock._process` runs after `SceneDirector._process`
   in a frame, cues lag one frame; GDD 21 tolerates ± 1 frame
   (TR-director-006). **NOT SOURCEABLE — tree processing order of autoloads
   not covered by `docs/engine-reference/godot/`**; tests call
   `clock.advance()` then `director.tick_for_test()` explicitly.
5. **Cancellation = drop.** Cancelling a run removes it from the live list:
   no callback, no order, no stack operation, no fact. There are no
   `GameClock.schedule()` handles to leak, which is why polling beats
   `schedule()` here (reset_session would silently clear them anyway).
6. **Load boundary.** On every `scene_load_started` the director drops **all**
   live runs **before** step 4's `reset_session()` (it reaches 21 in the
   frame of step 1). Armed scenes (`ESC1_LLEGADA`, `ESC8_ASCENSOR`,
   `ESC8_CIERRE`) hold no origin until their trigger. Defensive rule: a
   run observing `clock.now() < origin_s` is dropped and reported through
   `ErrorPolicy` (dev halt) — it can only mean a missed load boundary.
7. **Origin of the two load scenes.** `ESC1_LLEGADA` and `ESC8_ASCENSOR`
   start at `scene_ready` (TR-director-006), i.e. after `reset_session()`, so
   their origin is ≈ 0 of the new session.

### D3 — `StepChain` and `LineWait`: sequential steps with event-or-cap waits

A `StepChain` is an ordered list of steps; each step starts when the previous
one ends. Kinds: `ACT` (instant callable), `WAIT_S` (duration on
`GameClock.deadline`), `WAIT_LINE` (`LineWait`), `WAIT_NOTICE` (named notice
or cap). The chain is ticked by its owner (21's `_process`, 9's framework
tick) and may carry a **hard deadline** after which it jumps to a declared
final step. Cancellation is drop (D2.5).

`LineWait` implements `espera = min(evento, tope)` (GDD 21 F4, GDD 9 F8,
GDD 22 rule 25) over the ADR-0008 answers, keyed by `line_id`:

| Answer received | `SILENT_READ_TIME` policy (21) | `SILENT_FALLBACK` policy (9, 22) |
|---|---|---|
| `line_finished {line_id}` | done now | done now |
| `line_no_audio` / `line_failed {line_id, t_lectura_s}` | done at `answer + t_lectura_s` | done at `start + fallback_s` |
| nothing | done at `start + cap_s` | done at `start + fallback_s + line_grace_s` |
| any of the above | never later than `start + cap_s` | never later than `start + fallback_s + line_grace_s` |

`start` = the frame the line was requested. For 9 this reproduces F8 exactly
(`T_line = min(t_terminada, fallback_s + line_grace_s)`; `fallback_s` on
silent; `fallback_s + line_grace_s` on nothing). Answers for another
`line_id`, or after the wait is done or dropped, are ignored — that is how a
cancelled chain survives a late `line_finished(interrumpida)`.

### D4 — `ESC8_CIERRE` as the `CIERRE` chain (rules 20–22, F3)

```text
 trigger reading_completed{doc=R01} ∧ llamada_completada ∧ ¬cierre_iniciado → cierre_iniciado = true
 S0 WAIT_S      g_post_lectura_s (3,0)
 S1 ACT         interaction.cerrar_modos()                       (scene service, bind window)
 S2 WAIT_NOTICE modes_closed, cap t_modos_max_s (2,0)            (cap → log, continue)
 S3 ACT         input.open_no_control(&"scene_director", D_cierre)  false → degrade (rule 8e), continue as momento
                 hard deadline armed: t_duro = D_cierre − h_decl_s from this step
 S4 ACT+WAIT_LINE cierre_lineas[respuesta_llamada], cap t_linea_max_s   (unset → log, skip line, S5 still runs)
 S5 WAIT_S      g_entre_lineas_s (3,0)
 S6 ACT+WAIT_LINE cierre_linea_final (VO_V_12E), cap t_linea_max_s
 S7 WAIT_S      g_pre_fundido_s (2,0)
 S8 ACT+WAIT_S  scenes.request_fade_out(&"cierre"); wait scenes.fade_duration_s(&"cierre")  (A2)
 S9 ACT+WAIT_S  emit end_card_requested{…, duracion_s = t_tarjeta_s}; wait t_tarjeta_s
 S10 FINAL      go inactive (D6) and scenes.request_full_unload(); never close_no_control
 hard deadline reached in S4…S9 → jump to S10 (rule 22, F3)
```

`D_cierre` is computed at load from the config (`2·t_linea_max_s +
g_entre_lineas_s + g_pre_fundido_s + d_cierre + t_tarjeta_s + h_decl_s` =
25,8 s nominal) and logged; with every line answer missing the chain takes
exactly 24,8 s, so the hard deadline only acts on a fade or card anomaly.
S0–S2 run before control is taken (the player may close the book); S3 is the
only `open_no_control` the director ever makes (TR-director-013).
`reducir_movimiento` reaches `d_cierre` through 4 (0,1 s), so the chain reads
the duration from 4 instead of keeping a copy.

### D5 — Payloads of the three ‡ notices (closes QQ-20; amends ADR-0001 registry)

| Constant | Payload (keys literal, `NoticeIds.SCHEMA`) | Emitter / consumers |
|---|---|---|
| `&"scene_effect_requested"` | `id: SN` (closed `SceneEffects` set below), `objetivo: SN?` (scene ID such as `C03`, `C02`, `V02`), `duracion: F` (≥ 0; 0 = jump to end state, used by the reduced blackout), `parametros: Dictionary` (per-effect schema, `SceneEffects.PARAMS`; `{}` when none) | 21 only → 28 (light, rain, reflection), 23 (sound-bearing effects, R21), `V02` presenter (`TELEFONO_*`) |
| `&"object_state_requested"` | `objeto: SN` (`V02`, `ASCENSOR_RECEPCION` ‡), `estado: SN` (`V02`: `reposo`/`vibrando`; elevator: `abierto`) | 21 only (TR-director-019) → 22 (`V02` only, TR-call-017), 23 (buzz loop start/stop; door sound), the object's presenter node |
| `&"end_card_requested"` | `titulo_key: SN`, `rotulo_key: SN` (both `content_key`, ADR-0005 refs), `duracion_s: F` | 21 only → the end-card presenter (GDD 27 draws it; host in Shell, OI-4) |

`SceneEffects` (closed; one row per GDD 21/28 effect ID): `TELEFONO_PULSOS`
{`pulsos`: I, `pulso_s`: F}, `TELEFONO_MENSAJE` ‡ {`text_key`: SN},
`LLUVIA_REALCE` {}, `LUCES_PARPADEO` {`veces`: I, `caida_s`: F},
`REFLEJO_RETARDADO` {`retardo_s`: F, `gradual`: bool}, `LUCES_APAGON` {},
`SILLAS_RODANDO` {}, `TECLEO_LEJANO` {}, `LUCES_RESTAURAR` {},
`LLUVIA_VUELVE` {}, `LLUVIA_CESA` {}. `TELEFONO_SUENA` (GDD 21 rule 4) and
`PUERTAS_ASCENSOR_ABREN` (rule 18) are **object states**, not effects: they
change a persistent state that 22/23/the presenter must be able to read back,
which an effect does not (C3). Executors **must not** answer; 21 never waits
on them (TR-director-008).

### D6 — Director lifecycle and the cancellation matrix

States: `IDLE` (no scene session), `ACTIVE`, `INACTIVE` (full unload, rule 1).

| Input | `ACTIVE` behaviour | Volatile flags |
|---|---|---|
| `scene_load_started` requested by 21 (`recepcion`) | drop all runs; arm `ESC8_ASCENSOR` | kept |
| `scene_load_started` not requested by 21 | drop all runs; if `motivo = partida_nueva` arm `ESC1_LLEGADA` | cleared |
| `scene_load_failed` | drop all runs and armed scenes; no stack op | kept until the next reset |
| `no_control_absorbed {dueno = &"scene_director"}` | drop the run that held control; no stack op; await «terminada» (rule 11b) | cleared |
| `scene_load_finished {control_final = ninguno}` with an armed `dirigida` | F5: `M = (D_carga + margen_E) − t_since_started_s`; `M ≥ 0` → `transfer_no_control(&"scene_director", duracion_declarada)`; true → run has control; if `t_rel ≥ t_fin` → `request_exploration` same frame; false or `M < 0` → degrade to momento + log, never retry | — |
| `full_unload_requested` (own S10 or 4's) | → `INACTIVE`: drop runs, stop ticking, ignore all but `full_unload_completed` | kept |
| `full_unload_completed` | → `IDLE` | cleared |
| `state_reset`, `state_restored` | drop runs | cleared |

`D_carga` and `motivo` are cached from the matching `scene_load_started`
(ADR-0003 step 1). `margen_E` is read from `InputContexts` ‡ (A3), never
copied. Resume (rule 14) and the `V02` hand-back (rule 15) are code paths
that emit the same orders through the same `CueEmitter`, so the log of
emitted orders is uniform for AC-21-25.

### D7 — `CallController` (22): explicit state machine on `GameClock` deadlines

22 keeps the linear enum of TR-call-001 and one `_deadline_s` per timed
state; no `StepChain` (the `OPCIONES` state is open-ended and has a parallel
wait, which a chain expresses badly). Per frame, in its scene node's
`_process` (pausable `WorldSlot` subtree; `GameClock` is the clock either way):

| State | Enter | Leaves when |
|---|---|---|
| `DESCOLGANDO` | `sound_requested{SFX_PHONE_BUZZ, stop}` | `is_due(t_pick_s)` |
| `SILENCIO` | — | `is_due(t_sil_s)` |
| `RESPIRACION` | `sound_requested{SFX_CALL_BREATH, play}` | `is_due(t_resp_s)` |
| `LINEA` | `carta_variante` set → `line_requested{linea_variante[v]}` + `LineWait(SILENT_FALLBACK)`; unset → warn, no line | wait done / immediately if unset |
| `ANTES_OPCIONES` | — | `is_due(t_ante_s)` |
| `OPCIONES.ESPERA` | show options, cursor on; `_guard = deadline(t_guarda_opciones_s)`; `_wait = deadline(t_espera_s)` (both from appearance) | choice accepted (after guard) → `RESPUESTA`; `is_due(_wait)` and `!_signal_done` → `SENAL` |
| `OPCIONES.SENAL` | `_signal_done = true`; `sound_requested{SFX_BREATH_BROKEN, play}`; after `t_breath_s` → `line_requested{linea_senal[t4_decision]}` | choice → interrupt (below) → `RESPUESTA`; line done → back to `ESPERA` with no further deadline |
| `RESPUESTA` | write `respuesta_llamada` (rejected → read stored value, log); hide options; `line_requested{linea_respuesta[v]}` + `LineWait(SILENT_FALLBACK)` | wait done |
| `CIERRE` | `is_due(t_cierre_s)` → `SFX_PHONE_END`, write `llamada_completada`, `call_completed`, request `HAND_PHONE_PUTDOWN` | gesture end or `is_due(t_putdown_s)` → release `llamada`, `V02 reposo`, `COMPLETADA` |

- **20 s wait, once:** `_signal_done` makes `SENAL` reachable once per call;
  after it `ESPERA` has no deadline (TR-call-010).
- **Choice during `SENAL`:** `sound_requested{SFX_BREATH_BROKEN, interrupt}`
  and, if the `VO_G_14_*` line is active, the voice interrupt of ADR-0008 D3
  (fade `t_interrupt_s`, answer `line_finished(interrumpida)`). The response
  line is requested at once; 23's queue of 1 starts it after the fade, which
  is the `+ t_interrupt_s` of F3. If 23 cannot interrupt, the same queue makes
  it wait for the end of `VO_G_14_*` (≤ `t_cola_canal_s`), the accepted
  degradation of rule 15.
- **`t_corte_senal_s` does not exist** (retired by D23-27; 22 cites 23's
  `t_interrupt_s`). `call.json` rejects the key (C1).
- **Variants:** `carta_variante` A/B/C → `VO_G_12A/B/C`; `respuesta_llamada`
  A–D → `VO_G_13A–D` (and 21's `VO_V_12A–D`, D1 config); `t4_decision`
  `returned`/`assigned` → `VO_G_14_RET`/`VO_G_14_ASG`, unset → `VO_G_14_RET`
  + one warning (TR-call-023).
- **Pause** freezes every deadline by construction; the options keep focus.
  **Unload** frees the node: no state crosses a load; resume is rule 30
  (`V02 vibrando` + buzz once, after `scene_ready` and the first return to
  `exploración`).
- **Fallback durations** come from 18 per line (`ContentDB`), never from
  `call.json` (C2).

`call/call.json`:

```json
{ "schema_version": 1,
  "times": { "t_pick_s": 0.8, "t_sil_s": 2.0, "t_resp_s": 2.0, "t_ante_s": 1.0,
             "t_guarda_opciones_s": 0.6, "t_espera_s": 20.0, "t_breath_s": 4.0,
             "t_cierre_s": 1.0, "line_grace_s": 2.0, "t_putdown_s": 0.6 },
  "keys": { "opciones": ["UI_LLAMADA_OPCION_A", "UI_LLAMADA_OPCION_B",
                         "UI_LLAMADA_OPCION_C", "UI_LLAMADA_OPCION_D"],
            "linea_variante":  { "A": "VO_G_12A", "B": "VO_G_12B", "C": "VO_G_12C" },
            "linea_respuesta": { "A": "VO_G_13A", "B": "VO_G_13B", "C": "VO_G_13C", "D": "VO_G_13D" },
            "linea_senal":     { "returned": "VO_G_14_RET", "assigned": "VO_G_14_ASG", "sin_fijar": "VO_G_14_RET" },
            "sonidos": { "timbre": "SFX_PHONE_BUZZ", "respiracion": "SFX_CALL_BREATH",
                         "senal": "SFX_BREATH_BROKEN", "fin": "SFX_PHONE_END" } } }
```

Ranges (closes ADR-0005 "ranges ‡"): `t_pick_s` 0.8 fixed (± 0.001, it is
the `ANIM_PHONE_PICKUP` length); `t_sil_s`, `t_resp_s` 1.0–4.0; `t_ante_s`
0.5–2.0; `t_guarda_opciones_s` 0–1.0; `t_espera_s` 10–40; `t_breath_s` 4.0
(= `SFX_BREATH_BROKEN` length, B-sweep warns on mismatch with 23's catalog
duration when known); `t_cierre_s` 0.5–2.0; `line_grace_s` 1.0–4.0;
`t_putdown_s` 0.3–0.8. Key maps must be total over the fact's declared
values (`flags.json`); `opciones` has exactly 4 entries in A–D order
(TR-call-007, not a knob). Invalid → scene-load failure of 4 (ADR-0005 row).

### D8 — P5 reveal (GDD 9 F8) runs on `StepChain`; its data stays in `puzzles.json` (ADR-0010)

The 16 s reveal is owned by 9 (GDD 9 rules 17–19, F8). This ADR fixes its
**runtime** contract so 9, 10, 15 and 23 meet one executor; the
`resolution.steps` schema remains ADR-0010's.

```text
 commit (P5 aligned, hold_s 0,8)          9 writes pendiente_revelacion = true
 S1 OVERLAY_FADE  WAIT_S 1,2  (reveal_fade_s)
 S2 OUTLINE       WAIT_S 0,8  (reveal_outline_s †)
 S3 LINE VO_G_07  line_requested{VO_G_07, fallback_s 14,0, puzzle P5} + LineWait(SILENT_FALLBACK, fallback 14,0, grace 2,0)
 END              write caja_c3 = true, then pendiente_revelacion = false, then the solved notice
 T_seq ∈ [2,0, 18,0] s; 16,0 s nominal (no audio, or 14,0 s audio)
```

- **Pause:** frozen by `GameClock`; no extra code (TR-puzzles-014).
- **Interruption** (`atrás`, view closed by the player or by `cerrar_modos`):
  drop the chain, write nothing, emit `puzzle_resolution_interrupted{P5}`;
  `pendiente_revelacion` stays true (AC-21 of 9). Stopping `VO_G_07` on
  interruption is ADR-0010's call with ADR-0008 (OI-6); the dropped
  `LineWait` ignores any late answer either way.
- **Load during the reveal:** the controller is freed with the scene; 23
  cancels lines without answer (ADR-0008 D3); on reload P5 is `ACTIVE` with
  `pendiente_revelacion` and replays from S1 on the next commit (rule 19).
- **No director involvement:** 21 never emits orders during P5 (GDD 21
  rule 4, scenes 2 and 6 are not 21's).

### D9 — Validation (tier L in `setup`, tier B/C sweep; ADR-0005 D3)

`ScenesFileRules` ‡ per record (release: drop record + one log line; debug/CI:
`ERROR`): unique `id`; `tipo`; `disparador.kind` and allow-listed notice;
`interaction_executed` match contains `resultado: HECHO`; facts exist in
`flags.json` and values are in their type/enum; `marca` in the closed set;
`orden` in the catalog with its required keys; `efecto` in `SceneEffects`
with `parametros` matching `PARAMS`; `line_id` exists in 18 and has prefix
`VO_V_`/`MEGA_`; `text_key` exists; `t_rel` ≥ 0 and non-decreasing;
`dirigida`/`momento` field rules (D1.6); `cadena` known; `knob` in the GDD 21
list. Cross-file (tier B/C only): `ascensor_t_fin_s` = `ESC8_ASCENSOR.t_fin`;
computed `D_cierre` logged; scenes 2/6 IDs absent. `CallFileRules` ‡: D7
ranges and totals; unknown keys in `times` are `ERROR` (that is what rejects
`t_corte_senal_s` and `fallback_s`).

### D10 — Voice channels: 21 does not queue; 23 does

GDD 21 rule 7 and AC-21-26 describe a per-channel deferral with cap
`t_cola_canal_s`. ADR-0008 D3 already implements exactly that in 23 (queue of
1 per channel, timeout → `line_failed(canal_ocupado)`, logged). 21 therefore
emits `line_requested` at the cue time and never holds lines itself; the
observable behaviour of rule 7 is unchanged and has one owner (C4). 21 waits
on a line only inside the `CIERRE` chain (D4).

**No lines under the curtain (ADR-0016 OI-4 / C5).** The `Curtain` is drawn
above subtitles, so a line started while it covers the screen would be
heard but unreadable. 21 **must not** emit `line_requested` while a load or
its own `cierre` fade has the curtain at α > 0; a cue whose time falls in
that window is emitted when the curtain has lifted (scene cues only start
after «carga de escena terminada», so in practice this binds the `CIERRE`
chain and the title transition).

### Architecture Diagram

```text
 Boot step 9: SceneDirector.setup(ctx) ─► DataReader(director/scenes.json, director_config.json)
                                           └─► SceneCatalog (normalised, invalid records dropped)

 bus (GameState NoticeChannel) ──AVISO──► SceneDirector (autoload #9, ALWAYS)
   scene_load_started/finished/failed,     │  TriggerIndex: notice/fact/scene_ready → [SceneRecord]
   scene_ready, zone_entered,              │  VolatileFlags (5 marcas)
   interaction_executed, reading_completed,│  live: Array[CueRun]  ── tick() each _process ──┐
   EV_PUZZLE_SOLVED_P2, elevator_called,   │  chain: StepChain (CIERRE) + LineWait            │
   call_started, fact changes,             │                                                 ▼
   line_* answers, no_control_absorbed,    │                          CueEmitter ──AVISO──► line_requested ─► 23
   full_unload_*, state_reset/restored     │                                     ──AVISO──► scene_effect_requested ─► 28, 23, V02
                                           │                                     ──AVISO──► object_state_requested ─► 22, 23, presenters
                                           │                                     ──AVISO──► end_card_requested ─► end-card presenter (27)
                                           ├──SYNC──► InputContexts: transfer / open / request_exploration
                                           ├──SYNC──► SceneLoader: request_load(recepcion) / request_fade_out / request_full_unload
                                           └──SYNC (bind window)──► scene.interaction.cerrar_modos()
              reads ◄── GameClock.now() (frozen in pause) · GameState facts · SettingsReader(reducir_movimiento)

 planta: CallController (22, scene node) ── GameClock deadlines ── LineWait ──► line_requested / sound_requested
 planta: PuzzleFramework (9) ── P5 StepChain ── LineWait ──► line_requested (VO_G_07)
```

### Key Interfaces

All ‡ (proposed here). GDScript, typed. Top-level comments use a single `#`
as in ADR-0002; real sources use `##` doc comments on public APIs.

```gdscript
# src/director/timeline/clock_source.gd — what the timeline primitives need from GameClock.
# GameClock already satisfies it; tests pass a real GameClock with NullPauseBackend
# and drive it with advance() (ADR-0002 Key Interfaces).
# (No separate interface class: GameClock is injected directly.)

# src/director/timeline/cue.gd
class_name Cue extends RefCounted
var t_rel: float
var orden: StringName                 # &"linea" | &"efecto" | &"estado_objeto" | &"marca"
var args: Dictionary                  # normalised keys of D1.4
var reduced_overlay: Dictionary = {}  # si_reducir_movimiento, merged at emission
var only_if: Array[Condition] = []    # solo_si


# src/director/timeline/scene_record.gd — one normalised scenes.json record.
class_name SceneRecord extends RefCounted
enum Kind { MOMENTO, DIRIGIDA }
var id: StringName
var kind: Kind
var trigger: Trigger
var conditions: Array[Condition] = []
var on_fire: Dictionary[StringName, bool] = {}   # al_disparar marcas
var cues: Array[Cue] = []                        # non-decreasing t_rel (validated)
var t_fin: float = -1.0
var declared_s: float = -1.0                     # t_fin + h_decl_s, computed at load
var chain: StringName = &""                      # &"CIERRE" or empty
```

```gdscript
# src/director/timeline/cue_run.gd — one live run. Pure logic; no nodes.
class_name CueRun extends RefCounted

var record: SceneRecord
var origin_s: float
var has_control: bool = false
var finished: bool = false
var _next: int = 0

func _init(rec: SceneRecord, now_s: float) -> void:
	record = rec
	origin_s = now_s

func t_rel(now_s: float) -> float:
	return now_s - origin_s

# Emits every due cue in table order, once (F1). Returns false if the run must be
# dropped (clock went backwards: a missed load boundary, D2.6).
func tick(now_s: float, emitter: CueEmitter, control: ControlPort) -> bool:
	var t: float = t_rel(now_s)
	if t < 0.0:
		return false
	while _next < record.cues.size() and t >= record.cues[_next].t_rel:
		emitter.emit_cue(record.cues[_next])     # evaluates solo_si and the overlay
		_next += 1
	if record.kind == SceneRecord.Kind.DIRIGIDA and has_control and t >= record.t_fin:
		has_control = false
		control.request_exploration()            # never «cerrar» (rule 8b)
	finished = _next >= record.cues.size() and not has_control
	return true
```

```gdscript
# src/director/timeline/line_wait.gd — espera = min(evento, tope) over ADR-0008 answers.
class_name LineWait extends RefCounted

enum Silent { READ_TIME, FALLBACK }

var line_id: StringName
var _clock: GameClock
var _policy: Silent
var _start_s: float
var _fallback_s: float
var _cap_deadline_s: float
var _done_at_s: float = INF
var _done: bool = false

# Construct in the frame the line is requested.
# cap_s: 21 passes t_linea_max_s; 9 and 22 pass fallback_s + line_grace_s.
func _init(clock: GameClock, id: StringName, policy: Silent, cap_s: float, fallback_s: float = 0.0) -> void:
	_clock = clock
	line_id = id
	_policy = policy
	_start_s = clock.now()
	_fallback_s = fallback_s
	_cap_deadline_s = clock.deadline(cap_s)

# Called by the owner's bus handlers for line_finished / line_no_audio / line_failed.
# Answers for another line_id, or after done, are ignored (late interrumpida etc.).
func on_answer(notice: StringName, payload: Dictionary) -> void:
	if _done or payload.get(&"line_id", &"") != line_id:
		return
	var at: float
	if notice == NoticeIds.LINE_FINISHED:
		at = _clock.now()
	elif _policy == Silent.READ_TIME:
		at = _clock.deadline(float(payload.get(&"t_lectura_s", 0.0)))   # 21 F4: subtitle time
	else:
		at = _start_s + _fallback_s                                     # 9 F8 / 22 rule 25: from request
	_done_at_s = minf(at, _cap_deadline_s)

func is_done() -> bool:
	if not _done and (_clock.now() >= _done_at_s or _clock.is_due(_cap_deadline_s)):
		_done = true
	return _done
```

> `LineWait` has no `Timer` and holds no `GameClock.schedule()` handle, so
> dropping it is free (D2.5). With `FALLBACK` a silent answer ends the wait at
> `start + fallback_s` (F8: measured from the request, so a fault 7 s into
> `VO_G_07` still gives 16,0 s).

```gdscript
# src/director/timeline/step_chain.gd — sequential steps with a hard deadline.
class_name StepChain extends RefCounted

enum Kind { ACT, WAIT_S, WAIT_LINE, WAIT_NOTICE, FINAL }

class Step:
	var kind: Kind
	var action: Callable = Callable()   # ACT / FINAL; WAIT_LINE returns the LineWait to poll
	var wait_s: float = 0.0             # WAIT_S, and the cap of WAIT_NOTICE
	var notice: StringName = &""        # WAIT_NOTICE

var _clock: GameClock
var _steps: Array[Step] = []
var _i: int = -1
var _deadline_s: float = -1.0           # current WAIT_S / WAIT_NOTICE cap
var _line: LineWait = null
var _notice_seen: bool = false
var _hard_deadline_s: float = INF
var done: bool = false

func _init(clock: GameClock, steps: Array[Step]) -> void:
	_clock = clock
	_steps = steps

func start() -> void:
	_advance()

# Armed by a step (CIERRE S3): from now, reaching after_s jumps to the FINAL step.
func arm_hard_deadline(after_s: float) -> void:
	_hard_deadline_s = _clock.deadline(after_s)

func on_notice(name: StringName) -> void:
	if not done and _i >= 0 and _steps[_i].kind == Kind.WAIT_NOTICE and _steps[_i].notice == name:
		_notice_seen = true

func on_line_answer(notice: StringName, payload: Dictionary) -> void:
	if _line != null:
		_line.on_answer(notice, payload)

func tick() -> void:
	if done:
		return
	if _clock.is_due(_hard_deadline_s) and _steps[_i].kind != Kind.FINAL:
		_jump_to_final()
		return
	var s: Step = _steps[_i]
	var finished: bool = false
	match s.kind:
		Kind.WAIT_S:
			finished = _clock.is_due(_deadline_s)
		Kind.WAIT_NOTICE:
			finished = _notice_seen or _clock.is_due(_deadline_s)
		Kind.WAIT_LINE:
			finished = _line == null or _line.is_done()
	if finished:
		_advance()

func _advance() -> void:
	while true:
		_i += 1
		if _i >= _steps.size():
			done = true
			return
		var s: Step = _steps[_i]
		match s.kind:
			Kind.ACT:
				s.action.call()
				continue                        # instant: chain on in the same frame
			Kind.FINAL:
				s.action.call()
				done = true
				return
			Kind.WAIT_S, Kind.WAIT_NOTICE:
				_deadline_s = _clock.deadline(s.wait_s)
				_notice_seen = false
				return
			Kind.WAIT_LINE:
				_line = s.action.call()         # emits line_requested, returns LineWait or null (unset variant)
				return

func _jump_to_final() -> void:
	_i = _steps.size() - 2                      # FINAL is always the last step (validated at build)
	_advance()
```

```gdscript
# src/director/scene_director.gd — autoload #9 (ADR-0009), process_mode ALWAYS (ADR-0002).
class_name SceneDirector extends Node

enum Life { IDLE, ACTIVE, INACTIVE }
const OWNER: StringName = &"scene_director"

var _state: GameState
var _clock: GameClock
var _input: InputContexts
var _scenes: SceneLoader
var _content: ContentDB
var _settings: SettingsReader           # A1: added to ADR-0009's peer list
var _log: LogSink
var _catalog: SceneCatalog
var _cfg: DirectorConfig
var _emitter: CueEmitter
var _flags: Dictionary[StringName, bool] = {}
var _life: Life = Life.IDLE
var _runs: Array[CueRun] = []
var _armed: Dictionary[StringName, SceneRecord] = {}   # by trigger: &"scene_ready:planta", …
var _chain: StepChain = null
var _load_reason: StringName = &""
var _load_declared_s: float = 0.0
var _own_load_pending: bool = false
var _scene_ctx: ServiceContext = null    # bind window only (ADR-0009 D6)

func setup(ctx: ServiceContext) -> void:
	_state = ctx.state; _clock = ctx.clock; _input = ctx.input
	_scenes = ctx.scenes; _content = ctx.content; _settings = ctx.settings; _log = ctx.logger
	_cfg = DirectorConfig.load(ctx)                 # fatal CATALOGO_INVALIDO on error
	_catalog = SceneCatalog.load(ctx, _cfg)         # record isolation (D9)
	_emitter = CueEmitter.new(_state, _settings, _flags, _log)
	_subscribe_all()                                # never unsubscribed (TR-director-001)
	_clear_flags()

func _process(_delta: float) -> void:
	if _life != Life.ACTIVE:
		return
	var now: float = _clock.now()
	for i: int in range(_runs.size() - 1, -1, -1):
		var run: CueRun = _runs[i]
		if not run.tick(now, _emitter, _control_for(run)):
			_log.line(&"error", "director: clock went backwards, run %s dropped" % run.record.id)
			_runs.remove_at(i)
		elif run.finished:
			_runs.remove_at(i)
	if _chain != null:
		_chain.tick()

# --- load boundary (D2.6, D6) -------------------------------------------------
func _on_scene_load_started(p: Dictionary) -> void:
	if _life == Life.INACTIVE:
		return
	_life = Life.ACTIVE
	_runs.clear(); _chain = null
	_load_reason = p[&"motivo"]; _load_declared_s = p[&"D_carga"]
	if _own_load_pending:
		_own_load_pending = false
		_arm(&"ESC8_ASCENSOR")
	else:
		_clear_flags(); _armed.clear()
		if _load_reason == &"partida_nueva":
			_arm(&"ESC1_LLEGADA")

func _on_scene_ready(p: Dictionary) -> void:
	var rec: SceneRecord = _armed_for_ready(p[&"destino"], _load_reason)
	if rec != null:
		_start(rec)                                 # origin = now, after reset_session (D2.7)
	elif _load_reason == &"reanudar":
		_apply_resume()                             # rule 14 (code path, same emitter)

func _on_scene_load_finished(p: Dictionary) -> void:
	if p[&"control_final"] != &"ninguno":
		return
	var run: CueRun = _directed_run()
	if run == null:
		return
	var margin: float = (_load_declared_s + _input.no_control_margin_s()) - float(p[&"t_since_started_s"])  # F5, A3
	if margin >= 0.0 and _input.transfer_no_control(OWNER, run.record.declared_s):
		run.has_control = true
		if run.t_rel(_clock.now()) >= run.record.t_fin:
			run.has_control = false
			_input.request_exploration(OWNER)
	else:
		_log.line(&"warning", "director: handoff rejected (M=%.2f), %s degraded to momento" % [margin, run.record.id])

func _on_no_control_absorbed(p: Dictionary) -> void:
	if p[&"dueno"] != OWNER:
		return
	_runs.clear(); _chain = null; _clear_flags()   # no orders, no stack ops (rule 11b)

func _on_scene_load_failed(_p: Dictionary) -> void:
	_runs.clear(); _chain = null; _armed.clear()   # no orders; 4 restores menú (rule 11a)

func _on_full_unload_requested(_p: Dictionary) -> void:
	_runs.clear(); _chain = null
	_life = Life.INACTIVE                           # flags kept until «completada» (rule 1)

func _on_full_unload_completed(_p: Dictionary) -> void:
	_clear_flags(); _armed.clear()
	_life = Life.IDLE

# --- triggers ------------------------------------------------------------------
func _on_trigger(rec: SceneRecord) -> void:
	if _life != Life.ACTIVE or not _emitter.conditions_hold(rec.conditions):
		return
	for m: StringName in rec.on_fire:
		_flags[m] = rec.on_fire[m]
	if rec.chain == &"CIERRE":
		_chain = CierreChain.build(self, _clock, _cfg, _input, _scenes, _scene_ctx, _emitter)
		_chain.start()
		return
	_start(rec)

func _start(rec: SceneRecord) -> void:
	var run := CueRun.new(rec, _clock.now())
	_runs.append(run)
	run.tick(_clock.now(), _emitter, _control_for(run))   # t_rel = 0 cues leave now (D2.2)

func _on_elevator_called(_p: Dictionary) -> void:
	_own_load_pending = true
	if not _scenes.request_load(SceneLoader.Destination.RECEPCION, SceneLoader.Reason.RECEPCION,
			SceneLoader.FinalControl.NINGUNO):
		_own_load_pending = false
		_state.notify(NoticeIds.ELEVATOR_REJECTED, {})   # no retry (rule 17)

func _clear_flags() -> void:
	for m: StringName in [&"esc4_mega_hecha", &"esc4_reflejo_hecho", &"apagon_activo",
			&"mensaje_telefono_pendiente", &"cierre_iniciado"]:
		_flags[m] = false

# Test seam (D2.4): same as one _process, called after clock.advance().
func tick_for_test() -> void:
	_process(0.0)
```

```gdscript
# src/director/cue_emitter.gd — the only place 21 emits orders (one log for AC-21-25).
class_name CueEmitter extends RefCounted

func emit_cue(cue: Cue) -> void:
	if not conditions_hold(cue.only_if):
		return                                         # e.g. 60 s ring with llamada_iniciada
	match cue.orden:
		&"linea":
			_notify(NoticeIds.LINE_REQUESTED, {&"line_id": cue.args[&"line_id"],
				&"fuente": cue.args.get(&"fuente", &"")})
		&"efecto":
			var args: Dictionary = cue.args
			if not cue.reduced_overlay.is_empty() and _settings.get_bool(&"reducir_movimiento"):
				args = args.merged(cue.reduced_overlay, true)   # read at each firing (rule 23)
			_notify(NoticeIds.SCENE_EFFECT_REQUESTED, {&"id": args[&"efecto"],
				&"objetivo": args.get(&"objetivo", &""), &"duracion": float(args[&"duracion"]),
				&"parametros": args.get(&"parametros", {})})
		&"estado_objeto":
			_notify(NoticeIds.OBJECT_STATE_REQUESTED, {&"objeto": cue.args[&"objeto"],
				&"estado": cue.args[&"estado"]})
		&"marca":
			_flags[cue.args[&"marca"]] = bool(cue.args[&"valor"])
```

> `fuente` is optional in the registry (`SN?`); the emitter omits the key when
> empty in the real code (abridged). `SettingsReader.get_bool` is ADR-0007's
> reader ‡ (reconciliation item 23 still pending on its exact name).

```gdscript
# src/call/call_controller.gd — system 22, node in planta. Abridged: options UI, cursor,
# V02 re-assert (rule 33) and resume (rule 30) omitted.
class_name CallController extends Node

enum S { INACTIVA, DESCOLGANDO, SILENCIO, RESPIRACION, LINEA, ANTES_OPCIONES,
		ESPERA, SENAL, RESPUESTA, CIERRE, COLGANDO, COMPLETADA }
# ESPERA/SENAL are the OPCIONES substates; COLGANDO is the putdown tail of CIERRE
# (not an extra GDD state: externally reported as CIERRE).

var _s: S = S.INACTIVA
var _clock: GameClock
var _cfg: CallConfig                     # call/call.json, validated in configurar()
var _deadline_s: float = INF
var _guard_s: float = INF
var _wait_s: float = INF
var _signal_done: bool = false
var _signal_line: LineWait = null
var _line: LineWait = null

func _process(_delta: float) -> void:
	match _s:
		S.DESCOLGANDO:     if _clock.is_due(_deadline_s): _enter(S.SILENCIO)
		S.SILENCIO:        if _clock.is_due(_deadline_s): _enter(S.RESPIRACION)
		S.RESPIRACION:     if _clock.is_due(_deadline_s): _enter(S.LINEA)
		S.LINEA:           if _line == null or _line.is_done(): _enter(S.ANTES_OPCIONES)
		S.ANTES_OPCIONES:  if _clock.is_due(_deadline_s): _enter(S.ESPERA)
		S.ESPERA:          if not _signal_done and _clock.is_due(_wait_s): _enter(S.SENAL)
		S.SENAL:
			if _signal_line == null and _clock.is_due(_deadline_s):
				_signal_line = _request_line(_cfg.signal_line(_fact(&"t4_decision")))
			elif _signal_line != null and _signal_line.is_done():
				_s = S.ESPERA                        # no new deadline: unlimited wait (rule 14)
		S.RESPUESTA:       if _line == null or _line.is_done(): _enter(S.CIERRE)
		S.CIERRE:          if _clock.is_due(_deadline_s): _close_call()
		S.COLGANDO:        if _clock.is_due(_deadline_s): _finish()   # or gesture end, whichever first

func _enter(next: S) -> void:
	_s = next
	match next:
		S.SILENCIO:       _deadline_s = _clock.deadline(_cfg.t_sil_s)
		S.RESPIRACION:    _sound(&"respiracion", &"play"); _deadline_s = _clock.deadline(_cfg.t_resp_s)
		S.LINEA:          _line = _request_line(_cfg.variant_line(_fact(&"carta_variante")))  # null if unset (warn)
		S.ANTES_OPCIONES: _deadline_s = _clock.deadline(_cfg.t_ante_s)
		S.ESPERA:
			_show_options()
			_guard_s = _clock.deadline(_cfg.t_guarda_opciones_s)
			_wait_s = _clock.deadline(_cfg.t_espera_s)     # from appearance, guard included (D22-6)
		S.SENAL:
			_signal_done = true
			_sound(&"senal", &"play")
			_deadline_s = _clock.deadline(_cfg.t_breath_s)
		S.CIERRE:         _deadline_s = _clock.deadline(_cfg.t_cierre_s)

# From the options UI (mouse or ui_aceptar/seleccionar). First accepted choice wins.
func choose(option: StringName) -> void:
	if (_s != S.ESPERA and _s != S.SENAL) or not _clock.is_due(_guard_s):
		return                                      # guard: ignored, not queued (TR-call-008)
	if _s == S.SENAL:
		_sound(&"senal", &"interrupt")              # ADR-0008: fade t_interrupt_s (no t_corte_senal_s)
		if _signal_line != null:
			_interrupt_line(_signal_line.line_id)   # voice interrupt form owned by ADR-0008 D3
	var stored: StringName = _write_answer(option)  # rejected → stored value + log (rule 17)
	_hide_options()
	_s = S.RESPUESTA
	_line = _request_line(_cfg.answer_line(stored))

func _request_line(id: StringName) -> LineWait:
	if id == &"":
		return null
	var fb: float = _content.get_line(id).fallback_s        # per line, from 18 (C2)
	_notify(NoticeIds.LINE_REQUESTED, {&"line_id": id, &"fallback_s": fb})
	return LineWait.new(_clock, id, LineWait.Silent.FALLBACK, fb + _cfg.line_grace_s, fb)
```

`CierreChain.build` (abridged) returns a `StepChain` with the D4 steps; its
`WAIT_LINE` action picks `cfg.cierre_lineas[respuesta_llamada]`, returns
`null` (skip, log) when the fact is unset, and constructs
`LineWait(READ_TIME, cap = t_linea_max_s)`; its S3 action calls
`open_no_control` and `arm_hard_deadline(D_cierre − h_decl_s)`; its FINAL
action sets `_life = INACTIVE` **before** `request_full_unload()` so the
`full_unload_requested` echo finds the director already inactive.

### Implementation Guidelines

- **G-1** Timeline, chain and call code **must** read time only through the
  injected `GameClock` (`now`, `deadline`, `is_due`); `t_rel` **must** be
  `now − origin`, never an accumulator. **Must never** use `Timer`,
  `create_timer`, `GameClock.schedule()` or `await` on time (D2.5).
- **G-2** 21 **must** drop every live run and its chain on
  `scene_load_started`, `scene_load_failed`, `no_control_absorbed`
  (`dueno = &"scene_director"`), `full_unload_requested`, `state_reset` and
  `state_restored`; dropping **must not** emit any order, stack operation or
  fact.
- **G-3** 21 is the **only** emitter of `scene_effect_requested`,
  `object_state_requested` and `end_card_requested`; every emission **must**
  go through `CueEmitter`. Executors **must never** answer these notices.
- **G-4** 21 **must never** request `VO_G_*` lines nor queue lines itself
  (D10); 22 **must never** request `SFX_*` through `line_requested`
  (TR-call-016).
- **G-5** `reducir_movimiento` **must** be read at each emission of a cue
  with `si_reducir_movimiento`, never cached at boot.
- **G-6** 21 **must** reach `cerrar_modos()` only through the scene context
  held between `bind_scene()` and `unbind_scene()` (ADR-0009 D6).
- **G-7** No value of `scenes.json`, `director_config.json` or `call.json`
  may be duplicated as a code constant; single-owner values (D1 last
  paragraph, C1, C2) **must** be read from their owner.
- **G-8** 22's `choose()` **must** ignore input before the guard deadline and
  any second choice; the first accepted choice is final.
- **G-9** Every `LineWait` **must** be constructed in the frame its
  `line_requested` is emitted, and its owner **must** forward every
  `line_finished`/`line_no_audio`/`line_failed` to it.

## Alternatives Considered

### Alternative 1: `GameClock.schedule()` callbacks per cue

- **Description**: On scene start, schedule one callback per cue; cancel the
  handles on any cancellation input.
- **Pros**: No per-frame polling; uses an existing API.
- **Cons**: Same-frame cues depend on `_insert_sorted` stability for table
  order; `reset_session()` at every load silently clears handles, so a
  cancelled run and a cleared run look the same; handle bookkeeping for ~11
  scenes; callbacks run inside `GameClock._process`, coupling 21's emission
  order to clock internals.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Cancellation-by-drop is simpler and provably
  side-effect free (TR-director-014); polling cost is negligible (§ Performance).

### Alternative 2: `AnimationPlayer` / `Tween` tracks as timelines

- **Description**: Author each scene as an animation with method-call tracks.
- **Pros**: Visual editing in the editor.
- **Cons**: Engine-driven time, frozen by the tree pause rather than by
  `GameClock` (ADR-0002 D1: presentation only); variant B breaks it; method
  tracks skip or double-fire on hitches depending on settings not covered
  by `docs/engine-reference/godot/`; data no longer validated by ADR-0005;
  the autoload has no scene to host it.
- **Estimated Effort**: Higher (plus tests through the scene tree).
- **Rejection Reason**: Violates G-1 of ADR-0002 and the data-driven rule.

### Alternative 3: Fully data-driven director (rules 8, 11, 14, 15, 17 as data)

- **Description**: Express handoff, resume, elevator and cancellation in a
  rule language inside `scenes.json`.
- **Pros**: Everything tunable without code.
- **Cons**: A scripting language with one user per rule; validation becomes
  semantic; testing moves from GDScript to data fixtures.
- **Estimated Effort**: 2–3× the chosen approach.
- **Rejection Reason**: Over-engineering for an 11-scene slice (Simplicity).

### Alternative 4: 22 built on `StepChain`

- **Description**: Express the whole call as a chain.
- **Pros**: One primitive for 9, 21 and 22.
- **Cons**: `OPCIONES` is an open-ended wait with a parallel one-shot timer and
  an interrupting input; a chain needs special steps for it, and TR-call-001
  reads naturally as an enum.
- **Rejection Reason**: The explicit machine is clearer; 22 still reuses
  `LineWait`.

### Alternative 5: 21 keeps its own per-channel line queue (GDD 21 rule 7 literal)

- **Rejection Reason**: Duplicates ADR-0008 D3 with the same knob; two owners
  of one behaviour (D10, C4).

## Consequences

### Positive

- One timing model for 9, 21 and 22: pause, hitch clamp and load boundary
  behave identically by construction.
- Cancellation cannot leak orders: there is nothing scheduled to fire.
- QQ-20 closed: 28, 23, 22 and 27 have typed, validated inputs.
- Every slice duration lives in exactly one file with one owner.
- Fully headless-testable with a real `GameClock` and `advance()`.

### Negative

- Five procedural rules stay in code; changing their logic needs a
  programmer (accepted: one instance each).
- Polling costs a loop per frame even when nothing is due (bounded, tiny).
- Cross-ADR amendments A1–A6 are needed before stories start.
- `t_breath_s` and `t_pick_s` duplicate asset lengths; mismatch is only
  warned by the boot sweep.

### Neutral

- `TELEFONO_SUENA` and `PUERTAS_ASCENSOR_ABREN` become object states (C3).
- AC-21-26 is verified as an integration test with 23 instead of a unit test
  of 21.

## Risks

- **R1 Missed load boundary** (a run survives `reset_session`) → D2.6
  negative-`t_rel` guard + test T-21-07.
- **R2 Autoload processing order** (NOT SOURCEABLE) → ± 1 frame tolerated;
  integration test checks AC-21-05b at ± 1 frame.
- **R3 23 never answers** (unload, bug) → every wait capped (`LineWait`,
  `WAIT_NOTICE`, CIERRE hard deadline).
- **R4 End card host** not decided (title scene not loaded during
  `recepcion`) → OI-4 before the 27 story; until then a Shell stub.
- **R5 `cerrar_modos()` after unbind** → G-6; chain dropped on unload.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| director-de-escenas.md (21) | TR-director-003…004: scenes as data, record-level validation | D1, D9 |
| director-de-escenas.md (21) | TR-director-005…006: game-time clock, table order, once, from «escena lista», ± 1 frame | D2 |
| director-de-escenas.md (21) | TR-director-007…008: reads facts only; orders by bus without waiting | D1.2, D5, G-3 |
| director-de-escenas.md (21) | TR-director-009: two voice channels, per-channel deferral | D10 (via ADR-0008 D3) |
| director-de-escenas.md (21) | TR-director-010…013, -025: handoff, declared duration, degrade on rejection, `exploración` at end, F5 | D1.6, D6, `_on_scene_load_finished` |
| director-de-escenas.md (21) | TR-director-014…016: cancellation, volatile flags, resume | D2.5–6, D6, `_apply_resume` |
| director-de-escenas.md (21) | TR-director-017…019: corridor once per load, blackout, `V02` states | D1 (`marca`, `solo_si`), D5 |
| director-de-escenas.md (21) | TR-director-020: elevator request / rejection | `_on_elevator_called` |
| director-de-escenas.md (21) | TR-director-021…023: `cerrar_modos` + cap, CIERRE chain, `D_cierre`/`t_duro`, trigger by first `R01` reading | D3, D4 |
| director-de-escenas.md (21) | TR-director-024: `reducir_movimiento` read per firing | D1.4 overlay, G-5 |
| director-de-escenas.md (21) | TR-director-026: no retry, catalog IDs only | D9 (`line_id`/`text_key` refs), D10 |
| director-de-escenas.md (21) | TR-director-027: test clock, real Entrada, doubles of 4 | § Validation Criteria |
| llamada-telefonica.md (22) | TR-call-001…005: linear machine, `can_interact`, descolgar order, resume without re-write, timed sequence ± 0,05 s | D7 |
| llamada-telefonica.md (22) | TR-call-006…009: `llamada` context, fixed options, guard, choice rules | D7, G-8 |
| llamada-telefonica.md (22) | TR-call-010…012: 20 s signal once, interrupt, answer write | D7 |
| llamada-telefonica.md (22) | TR-call-013…016: close order, sole writer, audio fault tolerance, voice-only lines | D7, D3 (`LineWait FALLBACK`), G-4 |
| llamada-telefonica.md (22) | TR-call-017…020: `V02` ownership, resume ring, context rejection, hands | D5 (`object_state_requested`), D7 |
| llamada-telefonica.md (22) | TR-call-021…024: subtitle of the signal, times in `call.json`, unset variants, `V01` open | D7 (`call.json`, variants); TR-call-021/-024 are 26/7 behaviour, unaffected |
| marco-de-puzles.md (9) | F8: P5 reveal 16,0 s nominal, pause, interruption, replay | D8 (runtime only; schema ADR-0010) |
| atmosfera-reactiva.md (28) | «efecto de escena pedido» {id, objetivo, duración, parámetros}; duration 0 for the reduced blackout | D5 |
| pantalla-de-titulo.md (27) | Rules 23–24: end card triggered by 21, fixed `t_tarjeta_s` | D4 S9, D5 |

## Performance Implications

- **CPU**: per frame, 21 iterates ≤ 3 live runs and one chain (O(due cues),
  usually 0 emissions); 22 one `match`. Estimated well under 0,05 ms; no
  allocation in the steady state (runs created only on triggers).
- **Memory**: catalog of ~11 records, < 50 KB.
- **Load Time**: three small JSON files parsed at boot / `configurar()`; < 5 ms.
- **Network**: N/A.

## Migration Plan

New code; no existing implementation. Amendments A1–A6 go to the target ADRs
at the next reconciliation; GDD text changes G-a…G-e through
`/propagate-design-change`.

**Rollback plan**: the primitives are isolated in `src/director/timeline/`;
replacing polling with `schedule()` (Alternative 1) touches `CueRun` and
`StepChain` only; payloads are versioned through `NoticeIds.SCHEMA`.

## Validation Criteria

### Test Plan

Unit tests in `tests/unit/director_de_escenas/`, `tests/unit/llamada_telefonica/`,
`tests/unit/timeline/`; integration in `tests/integration/director_de_escenas/`
and `tests/integration/llamada_telefonica/`. All use a real `GameClock`
(`NullPauseBackend`, `advance()`), `RecordingBus` and doubles from ADR-0009 D9.

| ID | File | Checks | Covers |
|---|---|---|---|
| T-TL-01 | `test_cue_run_order.gd` | 5,9 → 6,4 s in one frame emits `MEGA_01` only; equal `t_rel` in table order; each once | F1, AC-21-03, TR-director-005 |
| T-TL-02 | `test_cue_run_pause.gd` | `pause()` → no emission for 100 frames; resume continues from same `t_rel` | AC-21-03, TR-director-005 |
| T-TL-03 | `test_line_wait.gd` | finished / no_audio (READ_TIME, FALLBACK) / nothing / foreign id / late answer after drop | F4, F8, TR-call-015 |
| T-TL-04 | `test_step_chain.gd` | sequential waits, `WAIT_NOTICE` cap, hard deadline jumps to FINAL, drop emits nothing | D3 |
| T-21-01 | `test_scenes_file_rules.gd` | duplicate id, unknown `orden`, decreasing `t_rel`, `VO_G_*` line, missing `HECHO` filter → record dropped, rest loads | AC-21-01, TR-director-004 |
| T-21-02 | `test_cierre_chain.gd` | no line answers → FINAL at 24,8 s ± 1 frame, `open_no_control(25,8)`; four `respuesta_llamada` values differ only in `VO_V_12x` | AC-21-21, AC-21-25 |
| T-21-03 | `test_reduced_motion.gd` | overlay used iff setting true at firing; changed between firings | AC-21-11, AC-21-27 |
| T-21-04 | `test_volatile_flags.gd` | corridor once per load; cleared per D6 matrix | AC-21-09, -10, TR-director-015 |
| T-21-05 | `test_blackout_ring_guard.gd` | 60 s cue suppressed with `llamada_iniciada` | AC-21-14b |
| T-21-06 | `test_payload_schema.gd` | three notices validate against `NoticeIds.SCHEMA` | D5 |
| T-21-07 | `test_load_boundary.gd` | `reset_session()` with a live run → run dropped, error logged | R1 |
| I-21-01 | `test_handoff_new_game.gd` | real Entrada, double of 4: transfer in «terminada» frame, 15,0 s declared, `exploración` at 14,0 | AC-21-04, -05, -05b |
| I-21-02 | `test_absorbed_cancel.gd` | AC-21-23b/c with `D_carga` 0,5 s, manual frames | AC-21-23b, -23c |
| I-21-03 | `test_full_unload_inactive.gd` | inactive until «completada», no orders | AC-21-29 |
| I-21-04 | `test_voice_channels_with_23.gd` | same-channel second line waits / fails after `t_cola_canal_s`; cross-channel no wait | AC-21-26 |
| T-22-01 | `test_call_timeline.gd` | options at 10,8 s; earliest completion 16,4 s ± 0,05 | TR-call-005, F2, F3 |
| T-22-02 | `test_call_wait_signal.gd` | signal once at 20 s from appearance; paused time excluded; no second signal | TR-call-010, AC of 22 |
| T-22-03 | `test_call_choice.gd` | guard ignores, first choice wins, choose during SENAL → interrupt requests then answer line | TR-call-008, -009, -011, -012 |
| T-22-04 | `test_call_json_rules.gd` | `t_corte_senal_s` or `fallback_s` in `times` → ERROR; key maps total | C1, C2, TR-call-022 |
| T-22-05 | `test_call_variants_unset.gd` | unset `carta_variante` → no 12x + warning; unset `t4_decision` → `VO_G_14_RET` | TR-call-023 |
| T-9-P5 | (ADR-0010 suite) `test_p5_reveal.gd` | 16,0 s no audio; 15,2 s with 13,2 s audio; interruption writes nothing | AC-20/-21/-22 of 9 |

Visual/feel items (blackout, flicker, reflection, end card) are PV evidence in
`production/qa/evidence/`, not automated.

### We will know this was right if

- All T-/I- tests pass deterministically in CI on 4.7.2 headless.
- In M3 playtest no directed scene leaves the player without control beyond
  its declared duration, and no order appears after a cancel in the order log.
- 28, 23 and 27 implement their consumers without asking for a payload change.

## Open Items

| # | Item | Owner | Before |
|---|---|---|---|
| A1 | **Applied 2026-11-10 (A1–A5 applied in ADR-0009, -0003, -0006, -0001, -0005; A6 pending).** ADR-0009: `SceneDirector` peers add `settings` (`SettingsReader`, `reducir_movimiento`) | ADR-0009 | 21 story |
| A2 | ADR-0003: `SceneLoader.fade_duration_s(reason) -> float` ‡ so 21 reads `d_cierre` from 4 (single owner; 0,1 s with `reducir_movimiento`) | ADR-0003 | CIERRE story |
| A3 | ADR-0006: `InputContexts.no_control_margin_s()` ‡ (`margen_E`) for F5 | ADR-0006 | 21 story |
| A4 | ADR-0001 registry: replace the three "‡ ADR-0017" payload rows with D5; add `SceneEffects` schema | ADR-0001 | 21/28 stories |
| A5 | ADR-0005 D2.5: `scenes.json` adds `al_disparar`, `cadena`, cue fields (D1); `call.json` `times` drops `fallback_s`, adds `t_pick_s`, `t_breath_s`; ranges per D7 | ADR-0005 | 21/22 stories |
| A6 | ADR-0008: confirm the voice-interrupt request form 22 uses for `VO_G_14_*` (`sound_requested{accion: interrupt}` with a line id, or a line-specific request) | ADR-0008 | 22 story |
| OI-1 | Object ID of the reception elevator doors (`ASCENSOR_RECEPCION` ‡) and its states | level design / GDD 8, 21 | ESC8 story |
| OI-2 | Executor of `TELEFONO_PULSOS`/`TELEFONO_MENSAJE` on `V02` (presenter node owned by 7's catalog?) and text keys `TEL_MENSAJE_*` ‡ in 18 | GDD 7, 18, 21 | ESC1 story |
| OI-3 | Keys `UI_TITULO_JUEGO`, `UI_CONTINUARA` ‡ in 18 | GDD 18 | 27 story |
| OI-4 | End-card host: 27 lives in `title.tscn`, not loaded during `recepcion`; needs a Shell-level presenter above the Curtain (ADR-0016 layer order) | ADR-0016, GDD 27 | 27 story |
| OI-5 | Engine verification V2 (autoload process order) recorded in `docs/engine-reference/godot/modules/` | engine-programmer | Accepted |
| OI-6 | Stopping `VO_G_07` when the P5 reveal is interrupted | ADR-0010 + ADR-0008 | P5 story |

### Contradictions found in the sources

| # | Between | Resolution in this ADR |
|---|---|---|
| C1 | Brief / ADR-0005 list `t_corte_senal_s` as a call knob vs GDD 22 Tuning Knobs and GDD 23 D23-27 (retired; `t_interrupt_s` of 23) | GDD wins: not in `call.json`, rejected by validation |
| C2 | ADR-0005 D2.5 puts `fallback_s` in `call.json` `times` vs GDD 22 ("por línea, de 18") | Per line from 18; A5 |
| C3 | GDD 21 rule 4 calls `TELEFONO_SUENA` / `PUERTAS_ASCENSOR_ABREN` effects vs rule 6c / GDD 23 (object states) | Object states (D5); GDD 21 rule 4 wording to align (G-a) |
| C4 | GDD 21 rule 7 / AC-21-26 (21 defers lines) vs ADR-0008 D3 (23 queues) | 23 owns the queue (D10); GDD 21 rule 7 wording (G-b) |
| C5 | Brief places the P5 16 s reveal in this ADR vs `architecture.md` (ADR-0010 owns `puzzles.json` and 9) | Runtime contract here (D8), schema in ADR-0010 |
| C6 | GDD 21 Tuning Knobs path `assets/data/scenes/*` vs ADR-0005 `director/*` | ADR-0005 wins (already G14 of the reconciliation) |
| C7 | GDD 27 rule 24 "27 pinta la tarjeta" vs ADR-0003 (title not in `WorldSlot` during `recepcion`) | OI-4 |
| C8 | GDD 22 DESCOLGANDO 0,8 s and `T_breath` 4,0 s have no `call.json` key | `t_pick_s`, `t_breath_s` added (A5) |

GDD propagation (G-a…G-e): G-a GDD 21 rule 4 object states; G-b GDD 21 rule 7
deferral by 23; G-c GDD 21 Tuning Knobs path and knob location (cue vs
config); G-d GDD 22 Tuning Knobs `t_pick_s`, `t_breath_s`, `fallback_s` from 18;
G-e GDD 27 end-card host.

## Related

- ADR-0001 — registry rows amended by A4; I-5 same-frame delivery.
- ADR-0002 — `GameClock`, G-1/G-3; `reset_session()` load boundary.
- ADR-0003 — handoff D6, «terminada» payload, `request_fade_out`, A2.
- ADR-0004 — seal by `call_started` (22 never saves).
- ADR-0005 — file registry and validation tiers, A5.
- ADR-0006 — `InputContexts`, A3.
- ADR-0007 — `SettingsReader`.
- ADR-0008 — voice channels, interrupt, A6.
- ADR-0009 — autoload #9, `SceneBindable`, A1.
- ADR-0010 — P5 reveal data and controller (consumer of D3/D8).
- `design/gdd/director-de-escenas.md`, `design/gdd/llamada-telefonica.md`,
  `design/gdd/marco-de-puzles.md` (F8), `design/gdd/atmosfera-reactiva.md`,
  `design/gdd/pantalla-de-titulo.md`.
