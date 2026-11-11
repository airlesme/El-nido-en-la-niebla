# ADR-0008: Audio Buses, Voice Queue and Process Mode

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stories that reference this ADR stay `Blocked` while it is `Proposed`.

## Date

2026-11-10

## Last Verified

2026-11-10 — against `docs/engine-reference/godot/VERSION.md` (pin 4.7.2),
`docs/engine-reference/godot/modules/audio.md`, `design/gdd/director-de-audio.md`
(GDD 23, rounds 1–10) and ADR-0001, ADR-0002, ADR-0003, ADR-0009 (all `Proposed`).

## Decision Makers

technical-director (autonomous batch mode, `project.yaml` `modes.automation:
autonomous`; defaults recorded per decision). User approval pending at batch close.

## Summary

System 23 (`AudioDirector`) needs a fixed bus tree, a bounded player pool, three
per-channel voice queues that always answer exactly once, its own per-player
pause under a paused tree, and a budget of ≤ 24 voices / ≤ 24 MB / ≤ 40 MB. Decided:
an `ALWAYS` autoload that owns **every** audio player of the game as a pool of 24
`VoiceSlot`s behind an injectable `AudioBackend` port; all fades, ducking and
room levels are tick-driven dB ramps on bus volumes (no `Tween`, no runtime
filters: band-pass, low-pass and the `VO_G_07` limiter are **baked into files**);
rooms are computed from listener position against `AudioRoomVolume` boxes (no
`Area3D`); pause uses `stream_paused` (ADR-0002 S8) with a seek-resume fallback.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2.stable) |
| **Domain** | Audio |
| **Layer** | Core |
| **Knowledge Risk** | HIGH — Godot 4.5–4.7 are post-cutoff (`VERSION.md`); `modules/audio.md` covers only a small subset of what 23 needs (table below) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/audio.md` (whole file: 4.7 `area_mask` default `0`, `tap_back_pos` removal, `AudioStreamPlayer`/`3D`, `max_distance`, `attenuation_model`, `unit_size`, `AudioServer.set_bus_volume_db`/`get_bus_index`/`set_bus_mute`, pooling, `finished`); ADR-0002 § Engine Compatibility NS-8, NS-9 and § Spike Plan S8, S9 |
| **Post-Cutoff APIs Used** | None by name. The 4.7 change **`area_mask` defaults to `0`** (`modules/audio.md`) is *avoided by design*: no `Area3D` bus override is used (D8) |
| **Verification Required** | ADR-0002 S8 (`stream_paused`) and S9 (audio under tree pause), plus this ADR's spike claims SA1–SA10 (§ Spike Plan), on 4.7.2, before `Accepted` |

**What the engine reference covers (sourceable, used here):**

| Fact | Source |
|---|---|
| `AudioStreamPlayer` / `AudioStreamPlayer3D`, `stream`, `play()`, `playing`, `bus` | `modules/audio.md` § Playing Audio, § Object Pooling |
| `volume_db` is a player property (tween target in the fade example) | `modules/audio.md` § Playing Audio |
| `AudioStreamPlayer3D.max_distance`, `attenuation_model` (`ATTENUATION_INVERSE_DISTANCE`), `unit_size` | `modules/audio.md` § 3D Spatial Audio |
| `AudioServer.set_bus_volume_db(idx, db)`, `AudioServer.get_bus_index(name)`, `AudioServer.set_bus_mute(idx, bool)` | `modules/audio.md` § Audio Buses |
| `finished` signal is the timing mechanism (not `_process` polling of playback) | `modules/audio.md` § Common Mistakes |
| Pre-created player pool instead of runtime node creation | `modules/audio.md` § Object Pooling, § Common Mistakes |
| 4.7: `area_mask` on `AudioStreamPlayer2D`/`3D` defaults to `0`; `audio_bus_override` on an `Area3D` stops working until it is set back to layer `1` | `modules/audio.md` § 4.7 Changes |

**NOT SOURCEABLE behaviours (never filled in from memory).** Each entry reads
`NOT SOURCEABLE — <what> not covered by docs/engine-reference/godot/modules/audio.md`.
Identifiers are the names the GDD uses with ‡; their existence and spelling in
4.7.2 is part of what the spike confirms. **Not repeated here:** ADR-0002 NS-8
(`stream_paused` holds and resumes position → S8) and NS-9 (an `ALWAYS` player
keeps playing under tree pause → S9); this ADR consumes their results.

| # | Behaviour this ADR depends on | Status | Spike |
|---|---|---|---|
| NA-1 | Creating buses at runtime: `AudioServer.add_bus`, `bus_count`, `set_bus_name`, `set_bus_send` (child → parent routing) | NOT SOURCEABLE — runtime bus creation not covered by `modules/audio.md` (only volume, index, mute) | SA1 |
| NA-2 | A player on a **muted** bus (or at −80 dB) keeps advancing and still emits `finished` at the natural end (R37 "silenciar no acorta") | NOT SOURCEABLE — playback on a muted bus not covered by `modules/audio.md` | SA2 |
| NA-3 | `AudioStream.get_length()` returns the duration of an imported OGG / WAV | NOT SOURCEABLE — stream length not covered by `modules/audio.md` | SA3 |
| NA-4 | `get_playback_position()`, `play(from_position)` and `stop()` on both player types | NOT SOURCEABLE — `stop()`, seek and position getter not covered by `modules/audio.md` (only `play()`) | SA4 |
| NA-5 | Missing vs broken file: `ResourceLoader.exists(path)` false for a missing resource in an export; `load(path)` returns `null` (no crash) for a corrupt one | NOT SOURCEABLE — resource existence / load failure not covered by `modules/audio.md` | SA5 |
| NA-6 | Detecting the dummy audio driver / no output device at startup (R46) | NOT SOURCEABLE — driver / device detection not covered by `modules/audio.md` | SA6 |
| NA-7 | A runtime limiter effect on a bus (`AudioEffectHardLimiter` or similar), `add_bus_effect`, `set_bus_effect_enabled`; ceiling in dBFS | NOT SOURCEABLE — bus effects not covered by `modules/audio.md` (only `AudioEffectSpectrumAnalyzer.tap_back_pos` removal) | SA7 (fallback path only) |
| NA-8 | An `AudioStreamPlayer3D` whose parent is a plain `Node` autoload under `root` renders in the same `World3D` as the world scene, and the current `Camera3D` is the listener without an `AudioListener3D` | NOT SOURCEABLE — listener and world binding not covered by `modules/audio.md` | SA8 |
| NA-9 | `pitch_scale` (±3 % steps, F5) and seamless looping of an imported OGG (`loop` import / stream property) | NOT SOURCEABLE — pitch and loop flags not covered by `modules/audio.md` | SA9 |
| NA-10 | OGG Vorbis kept compressed in memory and decoded during playback; WAV held decoded in memory (the meaning of "streaming" vs "preload" in F7) | NOT SOURCEABLE — import/decoding model not covered by `modules/audio.md` | SA10 (measurement) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (`Proposed`): notice names and payloads `line_requested`, `sound_requested`, `line_started`, `line_finished`, `line_no_audio`, `line_failed`, `puzzle_feedback`, `close_view_*`, `scene_load_started`, `scene_ready`, `full_unload_*`, `state_reset`, `state_restored`, `pause_opened`/`pause_closed`; anything emitted during a delivery is queued (I-5). ADR-0002 (`Proposed`): `AudioDirector` `ALWAYS`, `GameClock` for line clocks, `RealClock` for ramps during pause, D4 order, S8/S9. ADR-0009 (`Proposed`): autoload #6, `setup(ctx)` at boot step 7 after Settings, `SceneBindable` bind/unbind, no I/O in `_init`/`_ready`. ADR-0003 (`Proposed`): load sequence (unbind before free, «escena lista» after configure, full unload while paused). All four must be `Accepted` before this ADR is implemented |
| **Enables** | ADR-0017 (scene director: `scene_effect_requested` / `object_state_requested` payloads that 23 consumes — 23's reactions are fixed here, payload shape there); ADR-0007 (Settings: the `SettingsPort` read here is its consumer contract); ADR-0016 (subtitles: `line_started` timing and the `seg_b_inicio_s` decision, D11) |
| **Blocks** | Epic for system 23; audio-dependent stories of 9 (`LINE` steps, TR-puzzles-013), 21 (voice channels, TR-director-009/-026), 22 (interrupt, fallback, TR-call-011/-015/-016) and 26 (line timing) |
| **Ordering Note** | `architecture.md` § Required ADRs: 0004–0008 depend on 0001 and 0002. The audio spike (SA1–SA10) runs in the same throwaway project as ADR-0002's pause spike (`prototypes/spike-pause/`) and reuses its harness; S8 and S9 are run there once and read by both ADRs |

## Context

### Problem Statement

GDD 23 defines 50 rules for a persistent audio director: three simultaneous
voice channels with a strict "exactly one answer per accepted line" contract
that 9, 21, 22 and 26 rely on to never hang; priority-based polyphony; fixed
ducking; per-room rain; accessibility (`reducir_sobresaltos`, limiter on
`VO_G_07`); per-player pause while the volume sample keeps sounding; and
silent-but-timed playback when a bus is muted. It deliberately defers to "the
audio ADR" six engine questions (OQ 12: dB ramp, ceiling limiter, per-source
filter, `finished` as sole end, `stream_paused`, listener), the title audio
(OQ 3), and the subtitle segment hand-off (OQ 9 / QQ-22). Every audio story is
`Blocked` until these are fixed, and ADR-0002 already pinned 23's process mode
and clocks, so the remaining choices must fit under it.

### Current State

No audio code exists. The GDD is complete (10 review rounds). Engine coverage
is thin: `modules/audio.md` documents players, three bus calls, 3D attenuation
basics and pooling; nearly everything else 23 needs is NOT SOURCEABLE (NA-1…10
plus ADR-0002 NS-8/NS-9).

### Constraints

- Godot 4.7.2, GDScript, typed; single developer; vertical slice ~15–30 min.
- ADR-0002: `AudioDirector` is `ALWAYS`; **all** `AudioStreamPlayer*` of the game
  live under it, none under `WorldSlot`; line clocks on `GameClock`; sample and
  pause ramps on `RealClock`; `SceneTreeTimer`/`Timer` banned (D6).
- ADR-0009: no I/O, no reads of other autoloads and no subscriptions in
  `_init`/`_ready`; everything in `setup(ctx)`; scene services only inside a
  bind window; never `get_node("/root/…")`.
- ADR-0001: 23 never emits a response inside the delivery of the request; the
  bus queues it (I-5), delivered within the frame.
- Budgets (GDD 23 R50/F7, †): ≤ 24 simultaneous voices, effects resident
  ≤ 10 MB, audio in memory ≤ 24 MB, audio on disk ≤ 40 MB.
- Gameplay values data-driven: every † of GDD 23 Tuning Knobs in
  `assets/data/audio/audio_settings.json`; sound records in `audio_catalog.json`.
- Unit tests must not need an audio device (headless CI): the engine must sit
  behind an injectable port.

### Requirements

- Fixed bus tree of GDD 23 R3; `Master` at 0 dB; no `vol_maestro`.
- Exactly one response per accepted «línea pedida», ≤ 1 frame, never from
  within the request's delivery; no response for rejected IDs (R7b) and none
  for lines cancelled by load (R42).
- Per-channel queue of 1 with `t_cola_canal_s`; ceiling, watchdog, interrupt.
- Ducking (F2), partial silence (R29), pause level (R41), load attenuation (R42)
  and player volume (F1) composed per bus without fighting each other.
- Pause: voices and one-shots hold position; ambience/drone continue at −6 dB;
  sample never paused; a «terminada» due during pause comes out on resume.
- Rain level and muffling per room without `Area3D` (or with `area_mask` = 1).
- No device → every line answers «sin audio» at once (R46).
- Within the budgets above, with a development warning when one is exceeded.

## Decision

### D1 — Bus tree: created in code at `setup()`, validated by name

The tree of GDD 23 R3 is built by **one** class, `AudioBusBuilder`, called from
`AudioDirector.setup(ctx)` (never from `_init`/`_ready`, ADR-0009 D2). It is
idempotent: an existing bus with the right name is reused, so an editor-made
`default_bus_layout` (if one ever exists) and the code agree instead of
duplicating. After building, every one of the 11 names is checked with
`AudioServer.get_bus_index()` (sourceable); a missing bus is a fatal boot error
(`AUDIO_BUSES_INVALIDOS` ‡ through `ctx.fatal`, ADR-0009 D8) in debug and a
logged degrade to `Master` in release.

```text
Master (0 dB, never touched)
├── Voice            ← vol_voces                     · UI_VOL_MUESTRA (sample, P1)
│   ├── Voice_Vera       VO_V_*   (2D, dry)
│   ├── Voice_Mega       MEGA_*   (2D, distance law by 23, D9)
│   └── Voice_Guardian   VO_G_*   (3D at SPK_D01C / 2D at SPK_V02)
├── Effects          ← vol_efectos
│   ├── Fx_Puzzle        P2 feedback, SFX_CLICK_SUBTLE, SFX_FRAME_TURN
│   ├── Fx_World         ← ducking   · P2 call sounds, P3 world
│   └── Fx_Steps         P4
├── Ambience         ← vol_efectos · ducking · partial silence · pause · load
└── Music            ← vol_musica  · ducking · partial silence · pause · load
```

Runtime creation (NA-1) was preferred over an editor `.tres` layout because the
tree is then diffable, reviewable and reproducible in headless tests; if SA1
fails, the fallback is an editor-authored `default_bus_layout` with the same
names, and the builder degrades to validation only. Either way the rest of 23
addresses buses **by name only**.

**No bus effects in the shipped configuration.** Band-pass of `SPK_D01C` /
`SPK_V02`, the soft low-pass of `C01`, the muffled rain of `B`/`D`
(`lp_sala_hz`) and the `VO_G_07` limiter are all **baked** (D7). The tree carries
no `AudioEffect*`, which removes NA-7 from the main path.

### D2 — Player pool: 24 `VoiceSlot`s, all under `AudioDirector`

`AudioDirector` creates `max_voces_total` (24†) `VoiceSlot`s at `setup()`. Each
slot owns **one** `AudioStreamPlayer` and **one** `AudioStreamPlayer3D` (48
nodes; only one of the pair plays at a time), children of `AudioDirector`
(ADR-0002 D2: no player under `WorldSlot`). A slot is one voice of the
budget whichever player it uses. Positional slots copy the marker's
`global_position` when they start and, for moving sources (`SFX_CHAIRS_ROLL`,
`SFX_TYPING_FAR`, R20), every frame from 23's own path (NA-8).

Slots are **partitioned by class** (counts in `audio_settings.json`, sum =
`max_voces_total`), so reservations of GDD 23 R23 hold by construction:

| Class | Slots † | Holds | Stealable |
|---|---|---|---|
| `VOICE` | 3 | one per channel: `Voice_Vera`, `Voice_Mega`, `Voice_Guardian` | never (P1) |
| `SAMPLE` | 1 | volume sample (`UI_VOL_MUESTRA` / `SFX_CLICK_SUBTLE`) | never; restarted by the next sample |
| `LOOP` | 6 | `MUS_DRONE`, `AMB_RAIN` open, `AMB_RAIN` muffled (D7), `AMB_FAN`, `SFX_PHONE_BUZZ`, `SFX_FRAME_TURN` | never (P5; the two P2 loops count once, R23) |
| `SHARED` | 14 | P2 one-shots, P3, P4 (steps capped at `max_pasos` 2† concurrent) | F6 below |

(The GDD's "realce" reserved loop is not a separate stream: `LLUVIA_REALCE` is
a gain on the rain layer, so that reservation hosts the muffled rain.)

**Stealing (F6) inside `SHARED`.** On a request with no free shared slot:
candidate = the oldest slot with the highest `prioridad_num` among
non-protected slots (P2 is protected while P2-active ≤ `max_sfx_p2`); if the
candidate's priority ≥ the newcomer's, it fades out over `t_interrupt_s` and the
newcomer takes it; otherwise a P3/P4 newcomer is dropped with a log line. A P2
newcomer above `max_sfx_p2` steals the oldest P2. `VoicePool` is a pure
`RefCounted` (no nodes) so F6 is unit-tested without a backend.

### D3 — Voice channels: queue of 1, one answer, deadlines on `GameClock`

Each channel is a `VoiceChannel` state machine (pure `RefCounted`), one per
prefix (`VO_V_` → Vera, `MEGA_` → Mega, `VO_G_` → Guardian; R9):

```text
            request (audio OK, channel idle, not paused)
  IDLE ─────────────────────────────────────────────► PLAYING ──finished──► IDLE  «terminada»(fin)
   ▲  │ request while PLAYING/PAUSED                    │  ├─ now ≥ ceiling    → fade t_fade_corte_s → «terminada»(corte)
   │  └──────────► QUEUED (1) ──channel frees──► PLAYING│  ├─ now ≥ watchdog   → stop → «terminada»(watchdog)
   │          │ 2nd request or wait > t_cola_canal_s    │  ├─ interrupt        → fade t_interrupt_s → «terminada»(interrumpida)
   │          └──► «fallida» (canal_ocupado, logged)    │  └─ stall (D3.5)      → fade t_interrupt_s → «fallida»
   └──────────── load / full unload / state reset: cancel without any signal (R42, R45)
```

1. **Acceptance.** `line_id` must exist in 18 (`LineTextSource.has_line`) and
   must not be a catalog sound ID (R7b): rejected → log, **no** answer. Same
   `line_id` as the active or queued line → ignored and logged (the single
   answer reaches every subscriber, R10).
2. **Immediate answers.** `audio` null / file missing (NA-5) / no device (D10)
   → `line_no_audio {line_id, t_lectura_s}`; file present but `load()` fails →
   `line_failed {line_id, t_lectura_s}`; unknown text in 18 →
   `line_failed` with `t_lectura_s = t_min_lect_s`. Emitted with
   `GameState.notify()` from the handler: ADR-0001 I-5 queues it and delivers it
   in the same frame (≤ 1 frame, never inside the request's delivery). Lines
   without audio occupy no channel and cause no ducking (R47).
3. **Deadlines** are **game time** (`GameClock.now()`; frozen in pause, ADR-0002
   D5), anchored at **playback start** (R12 wording: "si el audio dura más"):
   `ceiling = start + fallback_s + line_grace_s` (only with `fallback_s`; fade
   starts at `ceiling − t_fade_corte_s`); `watchdog = start + min(duration +
   t_watchdog_s, t_linea_audio_max_s)`. Queue timeout is anchored at the
   request: `queued_at + t_cola_canal_s`.
4. **Duration** = `AudioStream.get_length()` (NA-3) unless the catalog's
   `lineas.<id>.duracion_s` overrides it (D6); if neither is available,
   `t_linea_audio_max_s` is used and the watchdog alone ends the line.
5. **Stall detection (R48, "fallo a mitad").** While PLAYING and not paused,
   if `get_playback_position()` (NA-4) has not advanced for `t_atasco_s`
   (0.5† game time, new knob) the line is stopped with `t_interrupt_s` and
   answered `line_failed` (never also `line_finished`). If SA4 shows the getter
   is unusable, stall detection is disabled and a mid-file failure surfaces as
   `line_finished(watchdog)` — a recorded deviation from R48 (OI-4).
6. **Pause hold.** While 23's own `_paused` flag is set (from `pause_opened`,
   never from `GameClock.paused_changed`, ADR-0002 G-6), any end detected
   (`finished` racing the pause frame) is stored and emitted right after
   `pause_closed`. Requests accepted during pause queue and start on resume
   (Edge Cases of 23).

### D4 — «línea iniciada» and the per-line notices

`line_started {line_id, duracion_s, canal}` (ADR-0001 registry; `canal` is the
bus name, e.g. `&"Voice_Guardian"`) is emitted **in the frame the slot's
`play()` is called**, i.e. after any queue wait and after a pause (D3.6). It is
emitted only for lines with audio, at most once per line, and is not a
response. `duracion_s` is the D3.4 duration (the ceiling does not shorten it:
26 decides its own window). Lines whose bus is muted still emit it (R37).

### D5 — Gain composition: per-bus contribution ramps, tick-driven

All level changes are **linear-in-dB ramps** computed by 23 in `_process` and
pushed with `AudioServer.set_bus_volume_db` (sourceable) or per-player
`volume_db` (sourceable). **23 never uses `Tween`** (avoids ADR-0002 NS-5 and
keeps every ramp testable with a fake clock). `BusMixer` (pure `RefCounted`)
keeps, per bus, named contributions, each a `DbRamp(current, target, rate,
time_source)`:

| Contribution | Buses | Time source | Rule |
|---|---|---|---|
| `vol` | `Voice`, `Effects`, `Ambience`, `Music` | `RealClock` | F1 / R36, `rampa_vol_s`; «ajustes aplicados» and `setup()` snap without ramp |
| `duck` | `Music`, `Ambience`, `Fx_World` | `GameClock` | F2: target = min over active voiced channels; attack / hold / release |
| `partial` | `Ambience`, `Music` | `GameClock` | R29, 1.0 s |
| `pause` | `Ambience`, `Music` | `RealClock` | R41, `pausa_amb_db`, 0.05 s |
| `load` | `Ambience`, `Music` | `RealClock` | R42 b, `atenuacion_carga_db` during the curtain; back in `t_entrada_capa_s` |

`bus_db = Σ contributions`, with `duck + partial ≥ duck_total_min_db` (−12†).
**Silence (TR-settings-017):** when `vol` reaches −80 dB on a silent setting,
the bus is also `set_bus_mute(true)` (linear gain exactly 0, never `−inf` or
`log(0)`); un-silencing unmutes first, then ramps up. If SA2 shows a muted bus
stops `finished`, mute is dropped and −80 dB alone is used (OI-2).

**Per-sound gains** (player `volume_db`): `trim_db + sobresalto_db + paso_db`
(F5) plus per-player fades (cut, interrupt, steal, load, layer in/out, buzz
attack `t_ataque_buzz_s`), each a `DbRamp` on the slot. Spatial attenuation is
the engine's (3D slots) or 23's own distance law (D9).

### D6 — Data: `audio_catalog.json` and `audio_settings.json`

Both under `assets/data/audio/`, read through `ctx.files` (ADR-0009) in
`setup()`, validated by `DataValidator` in debug/CI (ADR-0005 ‡). Schema of the
catalog (one owner: 23; lines stay in 18):

```json
{
  "version": 1,
  "sonidos": {
    "SFX_PHONE_BUZZ": {
      "bus": "Fx_World", "prioridad": 2, "archivos": ["res://assets/audio/sfx/sfx_world_phone_buzz_loop.ogg"],
      "lazo": true, "posicional": true, "fuente_defecto": "V02", "perfil_fuente": "3d_near",
      "trim_db": -2.0, "sobresalto": true, "precarga": true, "pedido_por": ["21", "22"]
    }
  },
  "lineas": {
    "VO_G_07": { "fuente_defecto": "SPK_D01C", "duracion_s": null,
                 "variantes": { "reducir_sobresaltos": "res://assets/audio/vo/vo_g_07_limited.ogg" } }
  },
  "fuentes_por_prefijo": { "MEGA_": "C01", "VO_G_12": "SPK_V02", "VO_G_13": "SPK_V02", "VO_G_14_": "SPK_V02", "VO_V_": null },
  "perfiles_fuente": {
    "3d_near":  { "tipo": "3d", "unit_size": 2.0, "max_distance": 12.0 },
    "pa_c01":   { "tipo": "ley_23", "piso_db": "piso_mega_db" },
    "earpiece": { "tipo": "2d" }
  }
}
```

- `sonidos` holds every record of GDD 23 § Datos (`id` is the key). `prioridad`
  is the number 1–5; `precarga` is derived by the validator from duration
  (< 1.0 s → `true`) and may only be overridden downward for long loops.
- `lineas` holds **only** what 23 owns about a line: default source overrides,
  a duration override (`null` = use `get_length()`), and baked variants.
  Text, `audio` path and segments remain 18's (R4).
- Values that are tuning knobs (`piso_mega_db`, `unit_size`, …) are referenced
  by knob name or stored here and nowhere else; `audio_settings.json` holds the
  numbers of GDD 23 Tuning Knobs (key = knob name) plus the pool partition
  (`slots_voice`, `slots_sample`, `slots_loop`, `slots_shared`, `max_pasos`)
  and the new knob `t_atasco_s`.
- An unknown `sound_id` in a request is ignored and logged (R6, R49); an
  unknown `fuente` plays 2D with the source profile and a log line.

### D7 — Filters and limiter: baked, not runtime

| Treatment | Decision | Runtime fallback (only if the asset route fails) |
|---|---|---|
| `SPK_D01C` 250–5 000 Hz, `SPK_V02` 300–3 400 Hz band | Baked in the recordings (already D23-22) | — (not offered: would need a bus per source) |
| `C01` soft low-pass | Baked into every `MEGA_*` file | — |
| Rain muffled in `B`/`D` (`lp_sala_hz` 2 500†) | **Two rain loops**: `amb_env_rain_loop` and `amb_env_rain_muffled_loop` (low-passed offline at `lp_sala_hz`), both always playing on `Ambience`; F8 crossfades them over `t_estancia_s` by room | none needed |
| `VO_G_07` limiter at `techo_limitador_dbfs` (−10†) with `reducir_sobresaltos` | **Baked variant** `vo_g_07_limited.ogg` (`lineas.VO_G_07.variantes`), chosen at `play()` time when the option is on ("from its next playback", Edge Cases of 23) | Enable a limiter effect on `Voice_Guardian` only while `VO_G_07` plays (NA-7, SA7). Valid because the channel plays one line at a time |

Why baked: zero NOT SOURCEABLE DSP on the main path; AC-23-14's −10 dBFS ±0.5 is
measured once, offline, on the file; and `lp_sala_hz` becomes an authoring
parameter (changing it means re-rendering one loop, recorded in Tuning).

### D8 — Rooms without `Area3D`

Scenes place `AudioRoomVolume` nodes (`Node3D`, script ‡, no physics): `room:
StringName` ∈ `V, C, A, B, D, R` and `size: Vector3` (box in local space).
`AudioSceneIndex.room_at(p)` returns the **smallest** box containing the
listener position, or `C` with one log line per entry into unlabelled space
(R19). The listener position comes from `Player` in the bind window (D12);
with no player, the origin (Edge Cases of 23). Pure math, no `Area3D`, no
collision layers, so the 4.7 `area_mask = 0` default (`modules/audio.md`) is
irrelevant. **Rule:** no system may use an `Area3D` `audio_bus_override` in
the slice; if a later ADR does, it must set `area_mask` to layer `1`
explicitly (`modules/audio.md` § 4.7 Changes).

### D9 — Sources: 3D where the engine law fits, 23's law where a floor is needed

| Source | Player | Attenuation |
|---|---|---|
| `SPK_D01C` (`VO_G_07`), `V02` buzz, `AMB_FAN`, world P3, chairs/typing | `AudioStreamPlayer3D` | `ATTENUATION_INVERSE_DISTANCE` with `unit_size` / `max_distance` from the profile (sourceable); `AMB_FAN` `max_distance` 8 m† |
| `C01` (`MEGA_*`) | `AudioStreamPlayer` (2D) | 23's law: `−min(piso_mega_db, k · distance_to_C01 + muro_db(room))` per frame — the ≤ 12 dB floor of AC-23-24 holds **by construction**, no NOT SOURCEABLE clamp needed. Loses panning, acceptable for a ceiling PA ("plana", R33) |
| `SPK_V02` earpiece, `VO_V_*`, sample, drone, rain | `AudioStreamPlayer` (2D) | none |

Listener: the current `Camera3D` (NA-8, SA8). No `AudioListener3D` is added
unless SA8 fails, in which case `Player` (ADR-0012 ‡) carries one and makes it
current at «escena lista».

### D10 — No audio device: decided once at `setup()`

`AudioBackend.device_available()` is evaluated once in `setup()`. The
production implementation is the only file that names the detection API
(NA-6); SA6 picks it among candidates the spike lists; if no API is reliable,
the fallback probe is: play a silent 0.5 s stream on a slot and check, after
0.5 s of `RealClock`, that the playback position advanced (NA-4). `false` →
mode `sin_dispositivo` (R46): every accepted line answers `line_no_audio` at
once, effects and layers are not started, no ducking, no player warning.
A device lost **mid-session** is out of scope: lines then end by watchdog
(never hang) and the mode is re-evaluated at next launch (OI-5).

### D11 — QQ-22: «línea iniciada» and `seg_b_inicio_s`

- «línea iniciada» is **confirmed** as 23's contract to 26 with the ADR-0001
  payload unchanged (`line_id`, `duracion_s`, `canal`), timing per D4.
- `seg_b_inicio_s` is **not** an audio field and is **not** added to the
  payload. With audio, `VO_G_07`'s inter-segment pause is inside the file
  (R16), so the B-segment offset is a property of *that recording*: it lives
  in 18 as an optional per-segment field next to the text (26 R13 already
  reads it from 18 and falls back to F2). 23 neither reads nor forwards it.
  Consequence: the ADR-0001 schema stays frozen; 18 gets one optional field
  (‡, change request for `base-de-contenido-narrativo.md`).

### D12 — Lifecycle: setup, bind window, load, pause, title

| Moment | 23 does |
|---|---|
| `setup(ctx)` (boot step 7, ADR-0009) | Read both JSON files; build buses (D1); create pool (D2); evaluate device (D10); read `Settings` directly and **snap** all `vol` contributions (no ramp; the «ajustes aplicados» of boot step 6 happened before 23 existed); preload `precarga` sounds; subscribe to the bus and to the settings channel |
| `bind_scene(scene_ctx)` (via `SceneBindable` adapter, before «escena lista») | Store `AudioSceneIndex` from `scene_ctx.scene` (markers with `audio_id`, `AudioRoomVolume`, surface tags; built by the scene root ‡) as **pending**; connect `Player.paso` → `on_paso` (soft) in a `SubscriptionBag` |
| `scene_ready {destino}` | Activate the pending index; start drone and both rain loops if not running (rain at room level, never inferring the blackout, R43); start `AMB_FAN` if `destino = planta`, stop it for `recepcion`; `load` contribution back to 0 in `t_entrada_capa_s` |
| `scene_load_started` | Cancel **without signal** active, paused and queued lines and all shared one-shots (fade `t_fade_carga_s`, `RealClock`); `load` → `atenuacion_carga_db`; drop the index (stop resolving sources) |
| `unbind_scene()` (before the instance is freed) | Release the `SubscriptionBag`; null every scene reference (idempotent with the line above) |
| `full_unload_requested` | Same as `scene_load_started` **including paused voices** (R42 e), plus layers out in `t_salida_capa_s`; after «completada» no slot is playing (AC-23-17) |
| `pause_opened` | `_paused = true`; `stream_paused = true` on every playing `VOICE` and `SHARED` slot and on the `LOOP` slots `SFX_PHONE_BUZZ` / `SFX_FRAME_TURN` (world-object loops: F1 applies `pausa_dB` only to `Ambience`/`Music`); `pause` contribution → `pausa_amb_db`; `SAMPLE` untouched; dev watchdog `t_pausa_max_s` armed on `RealClock` |
| `pause_closed` | Unpause those slots; `pause` → 0; emit held ends (D3.6). With nothing paused (after a full unload) it is a no-op without error (D23-28) |
| `state_reset` / `state_restored` | Discard the queues; re-apply layers as at `scene_ready` (R45) |
| Title | **Silent** (GDD 23 OQ 3 default, 27 OQ 1): no drone, no rain on the title. 23 still serves `sound_requested` (25's UI clicks) and the volume sample in the title's Options |

**Per-player pause mechanism.** Primary: `stream_paused` (ADR-0002 NS-8, S8).
If S8 fails: **seek-resume** — store `get_playback_position()`, `stop()`, and on
resume `play(from_position)` (NA-4, SA4); the slot keeps its line state so no
signal changes. If both fail, R41 cannot hold and the issue is escalated to the
user as a design change (pausing voices by muting would let them run on).

**Volume sample (R25).** Played on every `vol_voces` / `vol_efectos` change
notice from Settings (the only place those values change is Options, in the
pause menu or the title), throttled by `t_muestra_min_s` on `RealClock`, never
on «ajustes aplicados», never for `vol_musica`. It uses the `SAMPLE` slot,
which is never paused (ADR-0002 D5).

### D13 — Streaming vs preload, memory and disk

| Category | Format | Load | "Streaming" here means |
|---|---|---|---|
| One-shots < 1.0 s (`precarga`) | WAV 16-bit mono 44.1 kHz | `load()` in `setup()`, held for the session | — (decoded in memory) |
| One-shots ≥ 1.0 s, voices | OGG Vorbis mono q4–5 | voices: `load()` on first request, cached by path for the session; long SFX: `setup()` | compressed in memory, decoded while playing (NA-10) |
| Loops: rain ×2, fan, drone | OGG, seamless loop (NA-9) | `setup()` | idem |

Estimate (F7 + this ADR): effects ≈ 3.7 MB resident; voices ≈ 1.5 MB
compressed (+ 0.2 MB `VO_G_07` limited variant); drone + rain ≈ 6 MB, + 2.4 MB
muffled rain; fan ≈ 1 MB† → **≈ 15 MB resident, ≈ 15 MB on disk**, against
24 MB / 40 MB. Development check: on each load 23 sums
`duration × bytes_per_second` per format (F7) for everything cached and logs a
warning above `mem_efectos_mb` / `mem_total_mb`; voice count above
`max_voces_total` cannot happen (pool size) and attempts are counted and logged.
SA10 replaces the estimate with a profiler measurement (AC-23-28).

### Architecture Diagram

```text
root
├── GameState (bus) ──notices──► AudioDirector (autoload #6, PROCESS_MODE_ALWAYS)
│     line_requested · sound_requested · puzzle_feedback · scene_effect_requested ·
│     object_state_requested · close_view_* · scene_load_started · scene_ready ·
│     full_unload_* · state_reset/restored · pause_opened/closed
│   ◄──notices── line_started · line_finished · line_no_audio · line_failed
├── Settings ──SettingsPort (read in setup + change channel, ADR-0007 ‡)──► AudioDirector
├── GameClock (game time: line deadlines, ducking, rooms, LLUVIA_*)  RealClock (vol, pause, load, sample)
└── AudioDirector
     ├── logic (RefCounted, unit-tested):  VoiceChannel ×3 · VoicePool (F6) · BusMixer (F1/F2/R29/R41/R42)
     │                                     RoomModel (F8) · ReadTime (F3) · StepModel (F5) · Dedup (R18)
     ├── AudioBackend port ── GodotAudioBackend (ONLY file naming NA-1…NA-10 APIs) | FakeAudioBackend (tests)
     │      └── VoiceSlot ×24  [AudioStreamPlayer + AudioStreamPlayer3D] → buses of D1
     └── bind window: AudioSceneIndex (markers audio_id, AudioRoomVolume, surfaces) · Player.paso → on_paso
Shell/WorldSlot/[planta|recepcion]  — no audio players; only AudioMarker / AudioRoomVolume data nodes
```

### Key Interfaces

GDScript, typed. Single `#` comments so `Grep ^#` on this ADR does not match
code; real source uses `##` doc comments on public APIs. Engine calls that are
NOT SOURCEABLE appear **only** in `GodotAudioBackend`.

```gdscript
# src/audio/audio_backend.gd — port; production and fake implementations.
class_name AudioBackend extends RefCounted

signal slot_finished(slot: int)

enum LoadStatus { OK, MISSING, BROKEN }

class LoadResult:
	var status: LoadStatus = LoadStatus.MISSING
	var stream: AudioStream = null
	var length_s: float = -1.0   # -1 = unknown (NA-3)

func build_buses(spec: Array[AudioBusSpec]) -> bool: return false        # NA-1
func has_bus(bus: StringName) -> bool: return false                       # get_bus_index (sourceable)
func set_bus_db(bus: StringName, db: float) -> void: pass                 # sourceable
func set_bus_muted(bus: StringName, muted: bool) -> void: pass            # sourceable call; NA-2 effect
func device_available() -> bool: return false                             # NA-6
func load_stream(path: String) -> LoadResult: return LoadResult.new()     # NA-5
func create_slots(count: int) -> void: pass                               # pooled players (sourceable pattern)
func slot_play(slot: int, stream: AudioStream, bus: StringName, positional: bool,
		volume_db: float, pitch: float, from_s: float = 0.0) -> bool: return false   # NA-4 (from_s), NA-9 (pitch)
func slot_stop(slot: int) -> void: pass                                   # NA-4
func slot_set_paused(slot: int, paused: bool) -> void: pass               # ADR-0002 NS-8, fallback NA-4
func slot_set_volume_db(slot: int, db: float) -> void: pass               # sourceable
func slot_set_position(slot: int, world_pos: Vector3) -> void: pass       # NA-8
func slot_set_3d_profile(slot: int, unit_size: float, max_distance: float) -> void: pass  # sourceable
func slot_position_s(slot: int) -> float: return -1.0                     # NA-4; -1 = unsupported
func slot_is_playing(slot: int) -> bool: return false                     # sourceable (`playing`)
```

```gdscript
# src/audio/voice_channel.gd — one per channel; no nodes, no engine calls.
class_name VoiceChannel extends RefCounted

enum State { IDLE, PLAYING, CUTTING, QUEUED_ONLY }

class Line:
	var line_id: StringName
	var stream: AudioStream
	var duration_s: float
	var fallback_s: float = -1.0    # -1 = no ceiling
	var fuente: StringName
	var requested_at_s: float       # game time
	var started_at_s: float = -1.0
	var ending: StringName = &""    # pending motivo while fading / held in pause

var bus: StringName
var slot: int                       # its VOICE slot
var active: Line = null
var queued: Line = null
var _last_pos_s: float = 0.0
var _pos_changed_at_s: float = 0.0

func is_busy() -> bool:
	return active != null

func has_line(id: StringName) -> bool:
	return (active != null and active.line_id == id) or (queued != null and queued.line_id == id)
```

```gdscript
# src/audio/audio_director.gd — autoload #6 (ADR-0009). Excerpts.
class_name AudioDirector extends Node

const FADE_NONE: float = 0.0

var _state: GameState
var _clock: GameClock
var _real: RealClock                 # ADR-0002 name; ADR-0009 ctx.real_clock (OI-7 resolved)
var _settings: SettingsPort          # ADR-0007 ‡
var _lines: LineTextSource           # adapter over ContentDB (18) ‡
var _log: LogSink
var _backend: AudioBackend
var _cfg: AudioConfig                # parsed audio_settings.json + audio_catalog.json
var _channels: Dictionary[StringName, VoiceChannel] = {}
var _pool: VoicePool
var _mixer: BusMixer
var _rooms: RoomModel
var _index: AudioSceneIndex = null   # active only between scene_ready and load start
var _pending_index: AudioSceneIndex = null
var _paused: bool = false
var _held_ends: Array[Callable] = []
var _no_device: bool = false
var _subs := SubscriptionBag.new()
var _last_real_ms: int = 0

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # ADR-0002 D2 / ADR-0009 D2 (NS-2)

# Boot step 7. All I/O and subscriptions happen here, never in _init/_ready.
func setup(ctx: ServiceContext, backend: AudioBackend, lines: LineTextSource) -> void:
	_state = ctx.state; _clock = ctx.clock; _real = ctx.real_clock
	_settings = ctx.settings.as_port(); _log = ctx.logger
	_backend = backend; _lines = lines
	_cfg = AudioConfig.load_from(ctx.files, _log)            # both JSON files
	if not AudioBusBuilder.new(_backend).build(_cfg.bus_spec()):
		ctx.fatal.raise_fatal(&"AUDIO_BUSES_INVALIDOS", {})
		return
	_backend.create_slots(_cfg.pool_size())
	_pool = VoicePool.new(_cfg)
	_mixer = BusMixer.new(_cfg)
	_rooms = RoomModel.new(_cfg)
	for prefix: StringName in _cfg.channel_prefixes():
		_channels[prefix] = VoiceChannel.new()   # bus + VOICE slot from _cfg
	_no_device = not _backend.device_available()
	_mixer.snap_volumes(_settings)                           # R36: no ramp before any layer
	_preload_resident()
	_backend.slot_finished.connect(_on_slot_finished)
	_subs.add(_state.subscribe_notice(&"line_requested", _on_line_requested))
	_subs.add(_state.subscribe_notice(&"sound_requested", _on_sound_requested))
	_subs.add(_state.subscribe_notice(&"pause_opened", _on_pause_opened))
	_subs.add(_state.subscribe_notice(&"pause_closed", _on_pause_closed))
	_subs.add(_state.subscribe_notice(&"scene_load_started", _on_load_started))
	_subs.add(_state.subscribe_notice(&"full_unload_requested", _on_full_unload))
	# … scene_ready, close_view_*, puzzle_feedback, scene_effect_requested,
	#   object_state_requested, state_reset, state_restored, settings change channel
	_last_real_ms = _real.now_ms()

func _on_line_requested(p: Dictionary) -> void:
	var id: StringName = p.get(&"line_id", &"")
	if _cfg.is_sound_id(id) or not _lines.has_line(id):
		if _cfg.is_sound_id(id):
			_log.line(&"warn", "line_requested with sound id %s rejected (R7b)" % id)
			return                                              # no answer at all
		_answer(&"line_failed", id, _cfg.t_min_lect_s)        # unknown text: R Edge Cases
		return
	var ch: VoiceChannel = _channel_for(id)
	if ch.has_line(id):
		_log.line(&"info", "duplicate line %s ignored (R10)" % id)
		return
	var t_read: float = ReadTime.compute(_lines.char_count(id), _lines.pause_count(id), _cfg)
	if _no_device:
		_answer(&"line_no_audio", id, t_read); return
	var path: String = _cfg.line_path(id, _lines.audio_path(id), _settings.reduce_startle())
	if path.is_empty():
		_answer(&"line_no_audio", id, t_read); return
	var res: AudioBackend.LoadResult = _load_cached(path)
	match res.status:
		AudioBackend.LoadStatus.MISSING: _answer(&"line_no_audio", id, t_read); return
		AudioBackend.LoadStatus.BROKEN: _answer(&"line_failed", id, t_read); return
	var line := VoiceChannel.Line.new()
	line.line_id = id; line.stream = res.stream
	line.duration_s = _cfg.duration_override(id, res.length_s)
	line.fallback_s = float(p.get(&"fallback_s", -1.0))
	line.fuente = p.get(&"fuente", _cfg.default_source(id))
	line.requested_at_s = _clock.now()
	if not ch.is_busy() and not _paused:
		_start_line(ch, line)
	elif ch.queued == null:
		ch.queued = line
	else:
		_answer(&"line_failed", id, t_read)                    # canal_ocupado (logged)

# Always through the bus: ADR-0001 I-5 queues it when called inside a delivery.
func _answer(notice: StringName, id: StringName, t_read: float) -> void:
	_state.notify(notice, {&"line_id": id, &"t_lectura_s": t_read})

func _start_line(ch: VoiceChannel, line: VoiceChannel.Line) -> void:
	ch.active = line
	line.started_at_s = _clock.now()
	var positional: bool = _cfg.source_is_3d(line.fuente)
	_backend.slot_play(ch.slot, line.stream, ch.bus, positional, _source_gain_db(line.fuente), 1.0)
	if positional and _index != null:
		_backend.slot_set_position(ch.slot, _index.position_of(line.fuente))
	_state.notify(&"line_started", {&"line_id": line.line_id,
			&"duracion_s": line.duration_s, &"canal": ch.bus})

func _on_slot_finished(slot: int) -> void:
	var ch: VoiceChannel = _channel_by_slot(slot)
	if ch == null or ch.active == null:
		_pool.release(slot); return
	_end_line(ch, &"fin")

func _end_line(ch: VoiceChannel, motivo: StringName) -> void:
	var id: StringName = ch.active.line_id
	ch.active = null
	var emit := func() -> void: _state.notify(&"line_finished", {&"line_id": id, &"motivo": motivo})
	if _paused:
		_held_ends.append(emit)                                  # D3.6 / AC-23-18
	else:
		emit.call()
	if ch.queued != null and not _paused:
		var next: VoiceChannel.Line = ch.queued
		ch.queued = null
		_start_line(ch, next)

func _process(_delta: float) -> void:
	var now_ms: int = _real.now_ms()
	var real_dt: float = float(now_ms - _last_real_ms) / 1000.0
	_last_real_ms = now_ms
	var game_now: float = _clock.now()
	var game_dt: float = _clock.delta()
	for ch: VoiceChannel in _channels.values():
		_tick_channel(ch, game_now)                              # queue timeout, ceiling, watchdog, stall
	_mixer.set_duck_target(DuckModel.target(_voiced_channels(), _cfg))
	if _index != null:
		_rooms.update(_index.room_at(_player.rayo_vision().origen), game_dt)   # ADR-0012 OI-1
		_mixer.set_rain_mix(_rooms.open_db(), _rooms.muffled_db())
		_update_moving_sources(game_dt)
	_mixer.tick(real_dt, game_dt)
	for bus: StringName in _mixer.dirty_buses():
		_backend.set_bus_db(bus, _mixer.bus_db(bus))
		_backend.set_bus_muted(bus, _mixer.is_silent(bus))
	_pool.tick_fades(real_dt, game_dt, _backend)

func _tick_channel(ch: VoiceChannel, now: float) -> void:
	if ch.queued != null and now >= ch.queued.requested_at_s + _cfg.t_cola_canal_s:
		var q: StringName = ch.queued.line_id
		ch.queued = null
		_answer(&"line_failed", q, ReadTime.compute(_lines.char_count(q), _lines.pause_count(q), _cfg))
	var a: VoiceChannel.Line = ch.active
	if a == null or _paused:
		return
	if a.fallback_s >= 0.0:
		var ceiling: float = a.started_at_s + a.fallback_s + _cfg.line_grace_s
		if now >= ceiling - _cfg.t_fade_corte_s and a.ending == &"":
			a.ending = &"corte"
			_pool.fade_out(ch.slot, _cfg.t_fade_corte_s, &"game")
		if now >= ceiling:
			_backend.slot_stop(ch.slot); _end_line(ch, &"corte"); return
	var wd: float = a.started_at_s + minf(a.duration_s + _cfg.t_watchdog_s, _cfg.t_linea_audio_max_s)
	if now >= wd:
		_backend.slot_stop(ch.slot); _end_line(ch, &"watchdog"); return
	if _stalled(ch, now):
		_backend.slot_stop(ch.slot)
		var id: StringName = a.line_id
		ch.active = null
		_answer(&"line_failed", id, ReadTime.compute(_lines.char_count(id), _lines.pause_count(id), _cfg))

func _on_pause_opened(_p: Dictionary) -> void:
	_paused = true
	for slot: int in _pool.pausable_playing_slots():         # VOICE, SHARED, phone/frame loops
		_backend.slot_set_paused(slot, true)
	_mixer.set_pause(true)                                    # Ambience/Music → pausa_amb_db, RealClock

func _on_pause_closed(_p: Dictionary) -> void:
	if not _paused:
		return                                                # after a full unload: nothing to resume
	_paused = false
	for slot: int in _pool.paused_slots():
		_backend.slot_set_paused(slot, false)
	_mixer.set_pause(false)
	var held: Array[Callable] = _held_ends.duplicate()
	_held_ends.clear()
	for f: Callable in held:
		f.call()
	for ch: VoiceChannel in _channels.values():
		if not ch.is_busy() and ch.queued != null:
			var next: VoiceChannel.Line = ch.queued
			ch.queued = null
			_start_line(ch, next)

func _on_load_started(_p: Dictionary) -> void:
	_cancel_all_silently(_cfg.t_fade_carga_s)                 # no notices (R42, D23-6)
	_held_ends.clear()                                        # «Nueva partida» from pause (ADR-0002 D4)
	_mixer.set_load(true)
	_index = null

func _on_full_unload(_p: Dictionary) -> void:
	_cancel_all_silently(_cfg.t_fade_carga_s)                 # includes paused voices (R42 e)
	_held_ends.clear()
	_paused = false                                           # later pause_closed is a no-op
	_mixer.fade_layers_out(_cfg.t_salida_capa_s)
	_index = null

# Direct signal of 2 (rule 31 of 2), connected in bind_scene().
func on_paso(superficie: StringName, intensidad: float) -> void:
	if _no_device or _paused:
		return
	_play_step(superficie, StepModel.gain_db(intensidad, _cfg))   # F5; t_paso_min_s; no repeat
```

```gdscript
# src/audio/bus_mixer.gd — pure; one DbRamp per (bus, contribution).
class_name DbRamp extends RefCounted

var current_db: float
var target_db: float
var rate_db_s: float          # |Δ| / duration, recomputed on every set_target
var uses_game_time: bool

func set_target(db: float, duration_s: float) -> void:
	target_db = db
	rate_db_s = INF if duration_s <= 0.0 else absf(target_db - current_db) / duration_s

func tick(real_dt: float, game_dt: float) -> bool:
	var dt: float = game_dt if uses_game_time else real_dt
	if is_equal_approx(current_db, target_db):
		return false
	var step: float = rate_db_s * dt
	current_db = target_db if step >= absf(target_db - current_db) \
		else current_db + signf(target_db - current_db) * step
	return true
```

Ports used (all ‡, owned elsewhere): `SettingsPort.volume_db(group) -> float`,
`is_silent(group) -> bool`, `reduce_startle() -> bool` and a change channel
(ADR-0007); `LineTextSource.has_line(id)`, `char_count(id)`, `pause_count(id)`,
`audio_path(id)` over `ContentDB` (18; ADR-0005 for schema); `SceneServices`
gains `audio_index: AudioSceneIndex` built by the scene root (ADR-0009 D3
amendment, OI-6); `Player.paso(superficie, intensidad)` signal and
`rayo_vision().origen` / `.direccion` as the listener pose (ADR-0012 D10,
OI-1: closed API, no `listener_position()`).

### Implementation Guidelines

1. `AudioDirector` **must** set `process_mode = PROCESS_MODE_ALWAYS` in `_init()`
   and **must never** do I/O, read another service or subscribe outside `setup()`.
2. **All** `AudioStreamPlayer` / `AudioStreamPlayer3D` nodes of the game **must**
   be `VoiceSlot` children of `AudioDirector`; scenes **must never** contain
   audio players (only `AudioMarker` / `AudioRoomVolume` data nodes).
3. Only `src/audio/godot_audio_backend.gd` **may** name NA-1…NA-10 APIs and
   `stream_paused`; every other file talks to `AudioBackend`.
4. 23 **must never** use `Tween`, `SceneTreeTimer` or `Timer` (ADR-0002 D6);
   every ramp is a `DbRamp` with an explicit time source per D5.
5. Line deadlines, ducking, room interpolation, `LLUVIA_*`, phone pulses, chair
   paths and step / dedup intervals **must** use `GameClock`; volume, pause,
   load/layer fades, sample throttle and the dev pause watchdog **must** use
   `RealClock`.
6. Every response **must** go through `GameState.notify()`; 23 **must never**
   emit a second response for a line, nor any response for a rejected or
   load-cancelled line.
7. 23 **must** read the pause only from `pause_opened` / `pause_closed`, never
   from `GameClock.paused_changed` or `is_paused()` (ADR-0002 G-6).
8. Buses **must** be addressed by name from `AudioConfig`; no bus index or name
   literal outside `AudioBusBuilder` and `audio_settings.json`.
9. No `AudioEffect*` on any bus in the shipped configuration; the SA7 limiter
   fallback is the only permitted exception and needs this ADR amended.
10. No `Area3D` `audio_bus_override` in the slice; any future use **must** set
    `area_mask` to layer `1` (`modules/audio.md` § 4.7 Changes).
11. Every tuning value **must** come from `audio_settings.json` /
    `audio_catalog.json`; tests use fixture copies, not literals.
12. Scene subscriptions (`Player.paso`) **must** live in a `SubscriptionBag`
    released in `unbind_scene()` (TR-scene-009).

## Spike Plan

**Where:** `prototypes/spike-pause/` (ADR-0002's throwaway project and harness,
4.7.2, Jolt). **Owner:** engine-programmer, reviewed by technical-director.
**Run once, read by both ADRs:** ADR-0002 **S8** (`stream_paused`) and **S9**
(audio under tree pause) are *not* duplicated here; their rows decide D12's
pause mechanism. Every probe logs which API names parsed. **H** = headless
gdUnit4 where an audio driver is not needed or a position getter suffices;
**L** = windowed with listening / capture (the headless run may use the dummy
driver, which is exactly what SA6 must distinguish).

| # | Claim | Prototype and measurement | PASS | On FAIL |
|---|---|---|---|---|
| SA1 | NA-1 runtime bus tree — **H** | `AudioBusBuilder` builds D1; dump names, sends, count | 11 buses with the right parent; idempotent second call adds none | Editor `default_bus_layout`; builder validates only (D1) |
| SA2 | NA-2 muted bus keeps time — **H** + **L** | 4.0 s tone on `Voice_Vera`; mute at 1.0 s; also −80 dB variant | `finished` at 4.0 s ±0.05 in both; position advances while muted | Drop `set_bus_mute`, −80 dB only (OI-2); TR-settings-017 "exactly 0" then stays PV |
| SA3 | NA-3 `get_length()` — **H** | OGG and WAV of known length | Within ±0.01 s | Catalog `duracion_s` mandatory for every line (validator) |
| SA4 | NA-4 `stop()`, `get_playback_position()`, `play(from)` — **H** + **L** | 10 s marked tone; position at 3 s; stop; `play(3.0)` | Position ±0.05; resume audibly at 3 s; `stop()` emits no `finished` (record either way) | No stall detection (OI-4); no seek-resume fallback for S8 |
| SA5 | NA-5 missing vs broken — **H** (exported build) | Missing path, zero-byte OGG, truncated OGG, in an export | Missing → `exists` false; broken → `load` null without crash; truncated: record whether it fails at load or mid-play | Treat every load failure as `line_failed`; missing detected by catalog validator at build time |
| SA6 | NA-6 no device — **L** | Launch with the dummy driver and with a real device unplugged; candidate APIs + D10 probe | One method distinguishes both cases deterministically at `setup()` | D10 probe alone; if probe is also unreliable, `sin_dispositivo` only via a command-line flag (dev/QA), recorded deviation from R46 |
| SA7 | NA-7 limiter (fallback only) — **L** + offline measure | Limiter on `Voice_Guardian` enabled during a `VO_G_07` stand-in with a door hit; record output | Peak ≤ −10 dBFS ±0.5; line fully audible; enable/disable mid-session without clicks | Baked variant is the only route (already primary) |
| SA8 | NA-8 3D under an autoload, listener — **L** | `AudioStreamPlayer3D` child of a `Node` autoload, world scene with `Camera3D`; move source left/right/away | Panning and inverse-distance attenuation follow the camera | `AudioListener3D` on `Player` (D9) |
| SA9 | NA-9 pitch and loops — **L** | Step at `pitch_scale` 0.97/1.03; rain loop 60 s across wrap | Pitch audibly applied; no click at the loop seam | Pre-rendered pitch variants; loop crossfade baked in the file |
| SA10 | NA-10 memory — measurement | Load the full catalog + all voices; profiler / monitor | ≤ 24 MB audio; effects ≤ 10 MB | Lower OGG quality / shorter loops; AC-23-28 stays open |

**Decision Rule:** S8 PASS → `stream_paused`; S8 FAIL and SA4 PASS →
seek-resume; both FAIL → escalate R41 to the user. S9 FAIL is ADR-0002's
(variant B; 23 is unaffected because it never relied on the tree). Every other
FAIL selects the fallback in its row; none changes the D1–D13 structure.
**Cost:** ~1.5 developer-days on top of ADR-0002's spike (harness reused):
SA1–SA5 0.5 d; SA6–SA9 listening 0.5 d; SA10 and report 0.5 d.

## Test Plan

Unit tests in `tests/unit/audio/` (gdUnit4), all with `FakeAudioBackend`,
`FakeRealClock`, a `GameClock` driven by `advance()`, a recording bus double
(ADR-0001) and fixture copies of both JSON files. No device, no file I/O.

| Test file | Covers |
|---|---|
| `test_voice_channel_contract.gd` | AC-23-01, -02, -02b, -03, -06, TR-audio-006/-007/-008: one answer per accepted line, ≤ 1 frame, never inside the delivery; reject `SFX_*` without answer; duplicate `line_id`; queue of 1; `t_cola_canal_s` timeout; `canal_ocupado` |
| `test_voice_deadlines.gd` | AC-23-04, -05, -07, TR-audio-009/-010/-011, TR-call-011: ceiling 16.0 s ±0.05 with 0.3 s fade; `finished` at 13.2 s; watchdog `duración + 1.0`; `t_linea_audio_max_s`; interrupt ≤ 0.3 s; interrupt of nothing; stall → `line_failed` only |
| `test_line_started.gd` | D4, D11: emitted at `play()` after queue and after pause; once; not for no-audio lines; payload keys exactly `line_id`, `duracion_s`, `canal` |
| `test_read_time.gd` | F3 / AC-23-02, -02b: 1.83, 5.70, 2.77, 14.0, 16.4 (±0.01) |
| `test_bus_mixer.gd` | AC-23-10, -11, -13, TR-audio-003/-004/-014, TR-settings-017: −10 dB at step 15; silence → −80 + mute, never `−inf`; 0.05 s ramp; snap at setup; ducking min not sum; −12 floor; partial silence |
| `test_pause.gd` | AC-23-18, -32 (logic part), AC-23-17, -34, TR-audio-015/-016, TR-puzzles-013: paused slots, loops at −6 on `RealClock`, sample not paused, ceiling frozen, held `line_finished` released on `pause_closed`; full unload while paused discards and the later `pause_closed` is a no-op |
| `test_load_lifecycle.gd` | AC-23-17, -19, -20, -29, TR-audio-012b/-016/-017/-018: silent cancellation; −18 dB curtain; recovery 3.0 s; fan stop at `recepcion`; drone/rain not restarted; no blackout inference; `LUCES_APAGON` duration 0 → −60 same frame |
| `test_voice_pool.gd` | AC-23-21, TR-audio-013: partition sums to 24; P3 steals oldest P3; drop with only P1/P2/P5; P2 protection up to `max_sfx_p2` |
| `test_rooms.gd` | AC-23-15, AC-23-16, TR-audio-017: `room_at` smallest box, default `C` + one log; C→B −9 dB in 1.5 s; open/muffled crossfade; `LLUVIA_*` timings |
| `test_steps_and_dedup.gd` | AC-23-22, TR-audio-012/-020: −13.96 / −9.10 / −6 dB; `t_paso_min_s`; no repeat; `t_dedup_s`; unknown `sound_id` / `fuente` |
| `test_no_device.gd` | AC-23-27, TR-audio-019: every line `line_no_audio` ≤ 1 frame, no ducking, no slots used |
| `test_sources_and_startle.gd` | AC-23-09, AC-23-23, AC-23-26, TR-audio-023/-024: default sources; `C01` law ≤ `piso_mega_db`; buzz loop idempotent, 0.1 s stop, 3 pulses; startle −6 dB and 0.25 s attack; limited `VO_G_07` variant chosen from next playback; sample throttle 0.4 s, none for `vol_musica` |

Integration (`tests/integration/audio/`): AC-23-08 (9 and 22 complete with 23
absent), call and P5 end-to-end with the real bus and fake backend
(TR-call-015/-016, TR-director-009/-026). Windowed / measurement evidence in
`production/qa/evidence/`: AC-23-14 (offline peak of the baked file), AC-23-24,
-25, -28, -31 (loudness and memory), AC-23-32 (listening, after S8). Playtest:
AC-23-30, -33.

## Alternatives Considered

### Alternative 1: Runtime DSP (bus per source, low-pass and limiter effects)
- **Description**: Child buses per source (`Voice_Guardian_Phone`, …) with band-pass effects; `AudioEffectLowPassFilter` on `Ambience` with cutoff ramped per room; limiter effect on a dedicated bus.
- **Pros**: One rain file; filters tunable without re-rendering; GDD's `lp_sala_hz` live.
- **Cons**: Breaks the fixed tree of R3 (D23-22); every effect is NOT SOURCEABLE (NA-7); AC-23-14 measured on a live chain; CPU per effect.
- **Estimated Effort**: Similar code, more spike work (+0.5 d) and more risk.
- **Rejection Reason**: Adds NS surface for no player-visible gain; baked assets cost ≈ 2.6 MB disk.

### Alternative 2: `Area3D` room volumes with `audio_bus_override`
- **Description**: Each room an `Area3D` routing players to a room bus (reverb / low-pass), `area_mask` set to `1` per the 4.7 change.
- **Pros**: Engine-native; physical overlap handled by physics.
- **Cons**: Needs per-room buses (breaks R3); the 4.7 `area_mask = 0` default is a silent-failure trap; collision layers shared with ADR-0003's zone sensors; rain is 2D and would not be routed anyway.
- **Estimated Effort**: Higher (physics layers, more buses).
- **Rejection Reason**: The only thing rooms change is two gains; box math is simpler and unit-testable.

### Alternative 3: Players placed in the world scene at each marker
- **Description**: `AudioStreamPlayer3D` nodes inside `planta.tscn` at `C01`, `SPK_D01C`, `V02`; 23 looks them up by `audio_id`.
- **Pros**: Positions authored visually; no per-frame position copy.
- **Cons**: Contradicts ADR-0002 D2 (players under `WorldSlot` would be frozen by tree pause, including loops that must continue); unbounded node count; polyphony not centrally enforced; freed with the scene mid-fade.
- **Estimated Effort**: Lower at first, higher in edge cases.
- **Rejection Reason**: Violates an accepted constraint of ADR-0002 and R1 ("no node references to the plant").

### Alternative 4: `Tween`-based fades and ducking
- **Description**: `create_tween().tween_property(player, "volume_db", …)` (the `modules/audio.md` pattern) for every fade.
- **Pros**: Sourceable pattern; little code.
- **Cons**: Tween pause semantics are ADR-0002 NS-5; a tween on an `ALWAYS` node keeps running in pause, so game-time fades would need a per-tween pause mode; composing five contributions on one bus with competing tweens is fragile; not testable with a fake clock.
- **Estimated Effort**: Lower code, higher test effort.
- **Rejection Reason**: Determinism and the clock split of ADR-0002 D5.

### Alternative 5: Carry `seg_b_inicio_s` in «línea iniciada»
- **Description**: 23 reads the offset (from 18 or its catalog) and adds it to `line_started`.
- **Pros**: 26 gets everything in one notice.
- **Cons**: Changes ADR-0001's frozen payload; 23 would relay text-timing data it does not own.
- **Estimated Effort**: Similar.
- **Rejection Reason**: The offset belongs to the recording's text segmentation (18); 26 already reads 18.

## Consequences

### Positive
- The "never hangs" contract is a pure state machine tested headlessly; the engine sits behind one port.
- All DSP is offline: no runtime filter or limiter on the main path; NS surface reduced to playback, pause, length, position, device.
- Rooms, ducking, pause and load levels compose deterministically in one place (`BusMixer`).
- Polyphony and reservations cannot be exceeded (pool size = budget).
- ADR-0001's payload schema stays frozen (D11).

### Negative
- Two extra assets (muffled rain loop, limited `VO_G_07`) and a re-render whenever `lp_sala_hz` or `techo_limitador_dbfs` change: those knobs become authoring parameters, not runtime ones.
- `MEGA_*` loses stereo panning (2D with 23's distance law).
- Per-frame position copy for moving 3D sources (tiny CPU cost).
- `SceneServices` gains a field (ADR-0009 amendment) and 18 an optional field (`seg_b_inicio_s`).

### Neutral
- The title is silent (GDD default); changing it is a data change in D12 (start the drone on the title's `scene_ready`).
- Phone buzz and frame-turn loops pause with the world (interpretation of R41 against F1; OI-3).

## Risks

- **S8 and SA4 both fail** → R41 cannot hold. *Mitigation:* escalation path defined (D12); AC-23-18 / -32 stay PV until then.
- **SA2 fails** (muted bus stops time) → −80 dB only; mute is then not "exactly 0" (TR-settings-017 PV). *Mitigation:* −80 dB is inaudible; watchdog guarantees the answer.
- **SA6 finds no reliable device check** → `sin_dispositivo` only by flag. *Mitigation:* without a device, lines still end by watchdog, so 9/21/22 never hang (R8).
- **Mid-file decode failure undetectable** (SA4/SA5) → `watchdog` instead of `line_failed` (OI-4). *Mitigation:* both are single answers; requesters treat them alike after their own timeout.
- **Memory estimate wrong** (NA-10) → SA10 measures before content lock; OGG quality and loop length are the levers.
- **Content mismatch** between 18's `audio` paths and files → caught by `DataValidator` in CI (missing → `line_no_audio` at runtime, never a crash).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| director-de-audio.md (23) | TR-audio-001: persistent, `ALWAYS`, after 3 and 6 | Autoload #6, `_init` sets `ALWAYS`, `setup()` at boot step 7 (D12) |
| director-de-audio.md | TR-audio-002…005: bus tree, group volumes, F1, catalog / settings data | D1, D5, D6 |
| director-de-audio.md | TR-audio-006…011: one answer, `SFX_*` rejection, channels and queue, ceiling, watchdog, interrupt | D3, D4, Key Interfaces |
| director-de-audio.md | TR-audio-012, -012b: dedup, unknown IDs, scene markers by «escena lista» | D6, D8, D12 |
| director-de-audio.md | TR-audio-013: polyphony 24, P1–P5, `max_sfx_p2` | D2 |
| director-de-audio.md | TR-audio-014: ducking | D5 |
| director-de-audio.md | TR-audio-015: own per-player pause, sample not paused, game-time line clocks | D3.6, D12; mechanism from ADR-0002 S8 |
| director-de-audio.md | TR-audio-016…018: load / full unload, persistent layers, rain per room, no persistence, no blackout inference | D7, D8, D12 |
| director-de-audio.md | TR-audio-019: no device | D10 |
| director-de-audio.md | TR-audio-020: steps | D2 (`max_pasos`), Key Interfaces `on_paso` |
| director-de-audio.md | TR-audio-021: budgets, streaming vs preload | D2, D13 |
| director-de-audio.md | TR-audio-022: baked filters, runtime filter decided | D7 |
| director-de-audio.md | TR-audio-023: `reducir_sobresaltos`, limiter | D5 per-sound gains, D7 baked variant (SA7 fallback) |
| director-de-audio.md | TR-audio-024: volume sample | D12 |
| director-de-audio.md | TR-audio-025: loudness | Authoring targets of D13 formats; measured (AC-23-31), no runtime normalisation |
| director-de-audio.md | OQ 3 (title), OQ 9 (segments), OQ 12 (engine pending items) | D12 (silent title), D11, Engine Compatibility + Spike Plan |
| llamada-telefonica.md (22) | TR-call-011, -015, -016 | `interrupt` ≤ 0.3 s (D3); immediate `line_no_audio`/`line_failed` (D3.2); voice-only `line_requested`, SFX by `sound_requested` (D3.1) |
| director-de-escenas.md (21) | TR-director-009, -026 | Channels by prefix with `t_cola_canal_s` owned by 23 (D3); failed / no-audio answered once, never retried by 23 |
| marco-de-puzles.md (9) | TR-puzzles-013 | Ceiling `fallback_s + line_grace_s`; answers during pause held to resume (D3.6) |
| ajustes-persistentes.md (6) | TR-settings-017 | −80 dB + `set_bus_mute` → linear 0, never `−inf` (D5; SA2) |
| subtitulos.md (26) | R6, R8, R13 (`line_started`, `seg_b_inicio_s`) | D4, D11 |

## Performance Implications
- **CPU**: one `_process` on an `ALWAYS` node: 3 channel ticks, ≤ 24 slot fades, ≤ 14 bus pushes only when dirty, one room query over ≤ 10 boxes. Negligible against a 16.6 ms frame (target < 0.1 ms; measured in SA10).
- **Memory**: ≈ 15 MB estimated (D13) against 24 MB; 48 player nodes.
- **Load Time**: `setup()` preloads ≈ 4 MB of WAV and the loops once at boot; voices load on first request (≤ ≈ 200 kB each; hitch measured in SA10, cached afterwards).
- **Network**: none.

## Migration Plan

No existing code. Order: `AudioBackend` + `FakeAudioBackend` → `DbRamp`/`BusMixer`
→ `VoiceChannel` + contract tests → `VoicePool` → `RoomModel` → `AudioDirector`
wiring → `GodotAudioBackend` after the spike report → assets (muffled rain,
limited `VO_G_07`) at content lock.

**Rollback plan**: every engine-dependent choice is isolated in
`GodotAudioBackend` or a data file; the spike fallbacks (editor bus layout,
seek-resume, −80 dB only, listener node, runtime limiter) swap implementations
behind the port without touching the logic classes or their tests.

## Validation Criteria

We will know this decision was right if:
- All unit tests of § Test Plan pass headless in CI with no audio device.
- ADR-0002 S8/S9 and SA1–SA10 are reported PASS or resolved by their row's fallback, and § Engine Compatibility rows move to "verified 4.7.2 — spike report <date>".
- In a full slice playthrough with logging, every `line_requested` has exactly one answer (log audit script over the bus trace), and no line ever waits beyond its requester's ceiling.
- AC-23-28 measures ≤ 24 voices, ≤ 24 MB in memory, ≤ 40 MB on disk; AC-23-14 measures the baked `VO_G_07` peak ≤ −10 dBFS ±0.5.
- AC-23-32 passes by listening: the sample plays while a paused line holds position and resumes from it.

## Spike Results (2026-11-11)

Godot 4.7.2 stable, Windows, `--headless` (audio driver `Dummy`).
`tests/unit/engine_facts/adr0008_audio_buses_and_playback_test.gd`: 8 tests, PASS, run alone (SA9 and SA2 repeated 3x, stable).
Streams are `AudioStreamWAV` generated in code: there is **no .ogg/.wav asset in the repo**. Status stays `Proposed`;
ADR-0002 S8/S9 (pause) were not part of this run.

| Spike | Result | Observed value | Fallback needed |
|---|---|---|---|
| SA1 | PASS | `add_bus` + `set_bus_name` + `set_bus_send` build the tree by code (1 → 6 buses; `Voice_Vera` send = `Voice`); a second pass guarded by `get_bus_index(name) == -1` adds none; unknown name → -1. The 11-bus D1 layout itself was not built (builder not written) | No |
| SA2 | PASS | Player on a muted bus: position advanced 0.006→0.284 s in 0.3 s wall, `playing` stayed true, `finished` after 1240–1280 ms for a 1200 ms stream (jitter ≤ 80 ms in the test runner; ADR tolerance ±50 ms **not** met by wall-clock timing, but the overshoot is runner/Dummy-chunk latency and also appears at -80 dB: 781–859 ms for 800 ms). Muting does not shorten or stall playback | No (keep `set_bus_mute`; re-measure `finished` timing in a windowed build with a real device) |
| SA3 | PASS (WAV); OGG NEEDS_ASSET | `AudioStreamWAV.get_length()` = 2.5 for 2.5 s. OGG length needs a real .ogg | Catalog `duracion_s` if OGG fails |
| SA4 | PASS (numbers); resume audibly NEEDS_LISTENING | `stop()` sets `playing` false, `finished` **not** emitted (0). `play(3.0)` + 0.2 s wall → position 3.10–3.19. **`get_playback_position()` lags wall time by ~0.1–0.2 s and is chunk-quantised** (0.28 s after 0.5 s wall) — the ADR's ±0.05 s criterion does not hold for absolute position; resume-from-position on S8 must tolerate ~0.2 s | Treat position as ±0.25 s; no seek-resume fallback beyond that |
| SA5 | PARTIAL; export part NEEDS_EXPORT | `ResourceLoader.exists("res://.../does_not_exist.ogg")` = false. `AudioStreamOggVorbis.load_from_file` on a zero-byte file returns `null` with an engine error logged, no crash. `exists` for a missing file in an **exported** build and truncated-OGG behaviour: not run | Treat every load failure as `line_failed` |
| SA6 | PARTIAL | `AudioServer.get_driver_name()` = `"Dummy"` under `--headless`; `get_output_device_list()` = `["Default"]`, `get_output_device()` = `"Default"`, mix rate 44100. `get_driver_name() == "Dummy"` is a deterministic no-device/CI signal; the "real device unplugged" case with a real driver is NEEDS_MANUAL (hardware) | D10 probe / command-line flag if unplugged is indistinguishable |
| SA7 | NEEDS_LISTENING + offline measure | Limiter on `Voice_Guardian`; baked variant remains primary | — |
| SA8 | NEEDS_LISTENING | 3D panning/attenuation under an autoload node needs ears or a recorded output | `AudioListener3D` on `Player` |
| SA9 | PASS (numbers); audible parts NEEDS_LISTENING | `pitch_scale` is applied: simultaneous players at 0.97/1.0/1.03/2.0 reached 1.35/1.40/1.44/2.79 s in the same wall time (ratio 2.0/1.0 = 1.996; 1.03/0.97 = 1.06, expected 1.062). `AudioStreamWAV` loop flags round-trip (`LOOP_FORWARD`, `loop_end` = 22050). Seamlessness of an imported OGG loop at the seam: not measured | Pre-rendered pitch variants if audible |
| SA10 | NEEDS_ASSET | Memory with the real catalog; no audio assets yet | — |

## Open Items

| # | Item | Owner | When |
|---|---|---|---|
| OI-1 | ADR-0002 S8 result selects `stream_paused` or seek-resume (D12) | engine-programmer → technical-director | Spike |
| OI-2 | SA2: keep or drop `set_bus_mute` for silence; TR-settings-017 PV until then | engine-programmer | Spike |
| OI-3 | R41 says "lazos … siguen" while F1 applies `pausa_dB` only to `Ambience`/`Music`; this ADR pauses `SFX_PHONE_BUZZ` / `SFX_FRAME_TURN` with the world. GDD 23 R41 text should name the layers explicitly | game-designer (23) | Next GDD 23 round |
| OI-4 | R48 "fallo a mitad" depends on SA4/SA5; if undetectable, GDD 23 accepts `watchdog` as the answer | technical-director / 23 | Spike |
| OI-5 | Device lost mid-session (headphones unplugged) not handled beyond watchdog | technical-director | Post-slice |
| OI-6 | **Resolved 2026-11-10 (applied in ADR-0009 D3/D6).** ADR-0009 D3 amendment: `SceneServices.audio_index`; `AudioDirector` as a `SceneBindable` consumer (adapter) alongside 21 and `Shell` | technical-director (ADR-0009) | Before ADR-0009 `Accepted` |
| OI-7 | **Resolved: `RealClock` (ADR-0002).** Naming: ADR-0002 calls the real clock `RealClock`; ADR-0009 types `ctx.real_clock` as `MonotonicClock`. This ADR uses `RealClock`; one name must be chosen | technical-director | Before ADR-0002/0009 `Accepted` |
| OI-8 | 18 adds optional `seg_b_inicio_s` per segment of `VO_G_07` (D11); 26 OQ 1 closes with "from 18" | narrative / 18, 26 | Next GDD round |
| OI-9 | `ContentDB` must expose `has_line`, `char_count`, `pause_count`, `audio_path` (`LineTextSource`); `Settings` the `SettingsPort` and change channel | ADR-0005 / ADR-0007 | With those ADRs |
| OI-10 | New knobs: `t_atasco_s` (0.5†), `max_pasos` (2†), pool partition (3/1/6/14†), `muro_db(room)` for the `C01` law; add to GDD 23 Tuning Knobs | game-designer (23) | Next GDD 23 round |
| OI-11 | Title audio stays silent (OQ 3 of 23 / OQ 1 of 27 default); user may revisit (tone) | user | Batch review |

## Related

- ADR-0001 Event bus and fact contract — depends on (notice names, I-5 queuing).
- ADR-0002 Pause and game time — depends on (`ALWAYS`, clocks, D4 order, S8/S9); implements its delegated per-player pause.
- ADR-0003 Scene loading — depends on (load sequence, unbind before free, unload under pause).
- ADR-0009 Service composition — depends on (autoload #6, boot step 7, `SceneBindable`); requests amendment OI-6, naming OI-7.
- ADR-0005 / ADR-0007 / ADR-0012 / ADR-0016 / ADR-0017 — ports and payloads referenced with ‡.
- `design/gdd/director-de-audio.md` (23), `subtitulos.md` (26), `llamada-telefonica.md` (22), `director-de-escenas.md` (21), `marco-de-puzles.md` (9), `ajustes-persistentes.md` (6).
- `docs/architecture/architecture.md` § Required ADRs row ADR-0008, QQ-22; `docs/architecture/tr-baseline-provisional.md`.
- Future code: `src/audio/` (`audio_director.gd`, `audio_backend.gd`, `godot_audio_backend.gd`, `voice_channel.gd`, `voice_pool.gd`, `bus_mixer.gd`, `room_model.gd`, `audio_bus_builder.gd`); tests `tests/unit/audio/`.
