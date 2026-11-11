extends GdUnitTestSuite
# Verifica NA-1, NA-2, NA-3 (WAV), NA-4, NA-5 (parcial), NA-6 (parcial), NA-9 de ADR-0008 en Godot 4.7.2 (driver Dummy).
## SA1 runtime bus tree; SA2 muted bus keeps time; SA3 get_length (WAV generated in code; OGG NEEDS_ASSET);
## SA4 stop/position/play(from); SA5 load of missing/zero-byte file (no export: NEEDS_EXPORT for ResourceLoader.exists);
## SA6 driver/device query under the Dummy driver; SA9 pitch_scale and loop flags (audible seam NEEDS_LISTENING).
## SA7, SA8 (needs a listener/ears), SA10 (memory with real assets) are NEEDS_*.

const RATE: int = 22050


func _tone(seconds: float, loop: bool = false) -> AudioStreamWAV:
	var n: int = int(seconds * RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n * 2)
	for i: int in n:
		var v: int = int(sin(TAU * 440.0 * float(i) / float(RATE)) * 8000.0)
		data.encode_s16(i * 2, v)
	var s: AudioStreamWAV = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = n
	return s


func _make_bus(bus_name: String, parent: String = "Master") -> int:
	AudioServer.add_bus()
	var idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, parent)
	return idx


func after_test() -> void:
	# remove any bus created by a test (keep Master at 0)
	while AudioServer.bus_count > 1:
		AudioServer.remove_bus(AudioServer.bus_count - 1)


func test_runtime_bus_tree_is_built_with_sends_and_second_pass_is_idempotent() -> void:
	# Arrange
	var names: Array[String] = ["Music", "SFX", "Voice", "Voice_Vera", "Voice_Guardian"]
	var parents: Array[String] = ["Master", "Master", "Master", "Voice", "Voice"]
	var before: int = AudioServer.bus_count

	# Act
	for i: int in names.size():
		_make_bus(names[i], parents[i])
	var after_first: int = AudioServer.bus_count
	for i: int in names.size():
		if AudioServer.get_bus_index(names[i]) == -1:
			_make_bus(names[i], parents[i])
	var after_second: int = AudioServer.bus_count
	var vera: int = AudioServer.get_bus_index("Voice_Vera")
	print("SA1 buses before=", before, " after first=", after_first, " second=", after_second, " Voice_Vera send=", AudioServer.get_bus_send(vera))

	# Assert
	assert_int(after_first).is_equal(before + 5)
	assert_int(after_second).is_equal(after_first)
	assert_str(String(AudioServer.get_bus_send(vera))).is_equal("Voice")
	assert_int(AudioServer.get_bus_index("Nope")).is_equal(-1)


func test_player_on_muted_bus_keeps_advancing_and_finishes_on_time() -> void:
	# Arrange
	var idx: int = _make_bus("Voice_Vera")
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = _tone(1.2)
	p.bus = &"Voice_Vera"
	add_child(auto_free(p))
	var done: Array[int] = [-1]
	var t0: int = Time.get_ticks_msec()
	p.finished.connect(func() -> void: done[0] = Time.get_ticks_msec() - t0)

	# Act
	p.play()
	await get_tree().create_timer(0.3).timeout
	AudioServer.set_bus_mute(idx, true)
	var pos_mute: float = p.get_playback_position()
	await get_tree().create_timer(0.3).timeout
	var pos_later: float = p.get_playback_position()
	var playing_while_muted: bool = p.playing
	var waited: float = 0.0
	while done[0] < 0 and waited < 3.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	print("SA2 muted bus: pos at mute=", pos_mute, " 0.3 s later=", pos_later, " playing=", playing_while_muted, " finished after ms=", done[0], " (stream 1200 ms)")

	# Assert (tolerance wider than ADR's +-0.05 s: test-runner scheduling jitter)
	assert_bool(playing_while_muted).is_true()
	assert_float(pos_later).is_greater(pos_mute + 0.15)
	assert_int(done[0]).is_greater(1000)
	assert_int(done[0]).is_less(1500)


func test_player_on_minus_80_db_bus_also_finishes_on_time() -> void:
	# Arrange
	var idx: int = _make_bus("Voice_Vera")
	AudioServer.set_bus_volume_db(idx, -80.0)
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = _tone(0.8)
	p.bus = &"Voice_Vera"
	add_child(auto_free(p))
	var done: Array[int] = [-1]
	var t0: int = Time.get_ticks_msec()
	p.finished.connect(func() -> void: done[0] = Time.get_ticks_msec() - t0)

	# Act
	p.play()
	var waited: float = 0.0
	while done[0] < 0 and waited < 3.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	print("SA2 -80 dB: finished after ms=", done[0], " (stream 800 ms)")

	# Assert
	assert_int(done[0]).is_greater(700)
	assert_int(done[0]).is_less(1200)


func test_wav_get_length_matches_generated_duration() -> void:
	# Arrange
	var s: AudioStreamWAV = _tone(2.5)

	# Act
	var len: float = s.get_length()
	print("SA3 WAV get_length=", len, " (expected 2.5)")

	# Assert (OGG length: NEEDS_ASSET, no .ogg in the repo yet)
	assert_float(len).is_equal_approx(2.5, 0.01)


func test_stop_position_and_play_from_work_and_stop_emits_no_finished() -> void:
	# Arrange
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = _tone(5.0)
	add_child(auto_free(p))
	var finished_count: Array[int] = [0]
	p.finished.connect(func() -> void: finished_count[0] += 1)

	# Act
	p.play()
	await get_tree().create_timer(0.5).timeout
	var pos_before_stop: float = p.get_playback_position()
	p.stop()
	await get_tree().process_frame
	await get_tree().process_frame
	var playing_after_stop: bool = p.playing
	p.play(3.0)
	await get_tree().create_timer(0.2).timeout
	var pos_resumed: float = p.get_playback_position()
	p.stop()
	print("SA4 pos before stop=", pos_before_stop, " playing after stop=", playing_after_stop, " pos after play(3.0)+0.2 s=", pos_resumed, " finished emitted=", finished_count[0])

	# Assert
	assert_float(pos_before_stop).is_between(0.15, 0.8)  # observed ~0.28 after 0.5 s wall: the getter lags (mix-chunk quantised)
	assert_bool(playing_after_stop).is_false()
	assert_float(pos_resumed).is_between(3.0, 3.6)
	assert_int(finished_count[0]).is_equal(0)


func test_loading_missing_and_zero_byte_files_returns_null_without_crash() -> void:
	# Arrange
	var path: String = "user://adr0008_zero_byte.ogg"
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.close()

	# Act
	var missing_exists: bool = ResourceLoader.exists("res://assets/audio/does_not_exist.ogg")
	var zero: Variant = AudioStreamOggVorbis.load_from_file(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("SA5 exists(missing)=", missing_exists, " load_from_file(zero-byte)=", zero)

	# Assert (export-only part of NA-5 stays NEEDS_EXPORT)
	assert_bool(missing_exists).is_false()
	assert_object(zero).is_null()


func test_audio_driver_and_device_query_under_dummy_driver() -> void:
	# Act
	var driver: String = AudioServer.get_driver_name()
	var devices: PackedStringArray = AudioServer.get_output_device_list()
	var device: String = AudioServer.get_output_device()
	print("SA6 driver='", driver, "' devices=", devices, " current='", device, "' mix_rate=", AudioServer.get_mix_rate())

	# Assert: under --headless the driver is Dummy (a deterministic signal for the no-device case)
	assert_str(driver).is_equal("Dummy")


func test_pitch_scale_changes_playback_speed_and_loop_flag_roundtrips() -> void:
	# Arrange: simultaneous players cancel wall-clock jitter; the position getter is chunk-quantised and lags
	var pitches: Array[float] = [0.97, 1.0, 1.03, 2.0]
	var players: Array[AudioStreamPlayer] = []
	for pv: float in pitches:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.stream = _tone(6.0)
		p.pitch_scale = pv
		add_child(auto_free(p))
		players.append(p)
	var loop_stream: AudioStreamWAV = _tone(1.0, true)

	# Act
	for p: AudioStreamPlayer in players:
		p.play()
	await get_tree().create_timer(1.5).timeout
	var pos: Array[float] = []
	for p: AudioStreamPlayer in players:
		pos.append(p.get_playback_position())
		p.stop()
	var ratio_2x: float = pos[3] / pos[1]
	var ratio_step: float = pos[2] / pos[0]
	print("SA9 positions at 0.97/1.0/1.03/2.0 = ", pos, " ratio(2.0/1.0)=", ratio_2x, " ratio(1.03/0.97)=", ratio_step, " (expected 2.0 / 1.062) loop_mode=", loop_stream.loop_mode, " loop_end=", loop_stream.loop_end)

	# Assert (ratio 1.03/0.97 measured ~1.06 and recorded; audible step and loop seam NEEDS_LISTENING)
	assert_float(ratio_2x).is_between(1.7, 2.3)
	assert_int(loop_stream.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)
