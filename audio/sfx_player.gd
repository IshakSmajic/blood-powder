extends Node
## Procedural offline sound effects. Cosmetic randomness never uses SimClock RNG.

var arena: Node3D
var _streams: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _active_players: int = 0


func configure(owner_arena: Node3D) -> void:
	arena = owner_arena
	_rng.randomize()
	_ensure_buses()
	for kind in [&"swing", &"impact", &"crit", &"shot", &"place", &"explosion", &"cannon", &"whoosh", &"landing", &"heal", &"warning", &"ui"]:
		_streams[kind] = _build_stream(kind)
	EventBus.combat_event.connect(_on_combat_event)


func _exit_tree() -> void:
	if EventBus.combat_event.is_connected(_on_combat_event):
		EventBus.combat_event.disconnect(_on_combat_event)


func clear_transients() -> void:
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D:
			child.stop()
			child.free()
	_active_players = 0


func _ensure_buses() -> void:
	for bus_name in [&"SFX", &"UI"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")


func _build_stream(kind: StringName) -> AudioStreamWAV:
	var duration := 0.62 if kind == &"explosion" else 0.44 if kind in [&"cannon", &"warning"] else 0.25 if kind in [&"shot", &"landing", &"impact", &"crit"] else 0.18
	var rate := 22050
	var frames := int(duration * rate)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var seed_value := int(kind.hash()) ^ 91743
	var noise_rng := RandomNumberGenerator.new()
	noise_rng.seed = absi(seed_value) + 1
	var start_hz := 180.0
	var end_hz := 90.0
	var noise_mix := 0.0
	match kind:
		&"swing": start_hz = 720.0; end_hz = 190.0; noise_mix = 0.48
		&"impact": start_hz = 150.0; end_hz = 48.0; noise_mix = 0.32
		&"crit": start_hz = 310.0; end_hz = 76.0; noise_mix = 0.7
		&"shot": start_hz = 960.0; end_hz = 70.0; noise_mix = 0.88
		&"place": start_hz = 260.0; end_hz = 82.0; noise_mix = 0.2
		&"explosion": start_hz = 120.0; end_hz = 34.0; noise_mix = 0.82
		&"cannon": start_hz = 82.0; end_hz = 28.0; noise_mix = 0.76
		&"whoosh": start_hz = 530.0; end_hz = 140.0; noise_mix = 0.9
		&"landing": start_hz = 110.0; end_hz = 42.0; noise_mix = 0.4
		&"heal": start_hz = 440.0; end_hz = 740.0; noise_mix = 0.04
		&"warning": start_hz = 92.0; end_hz = 135.0; noise_mix = 0.06
		&"ui": start_hz = 580.0; end_hz = 430.0; noise_mix = 0.0
	for frame in range(frames):
		var t := frame / float(rate)
		var fraction := frame / float(maxi(1, frames - 1))
		var envelope := pow(maxf(0.0, 1.0 - fraction), 2.4)
		if kind == &"warning": envelope *= 0.55 + 0.45 * sin(fraction * PI * 7.0)
		var frequency := lerpf(start_hz, end_hz, fraction)
		var tone := sin(TAU * frequency * t) * (1.0 - noise_mix)
		var noise := noise_rng.randf_range(-1.0, 1.0) * noise_mix
		var sample := clampf((tone + noise) * envelope * 0.58, -1.0, 1.0)
		var pcm := int(roundi(sample * 32767.0))
		data[frame * 2] = pcm & 0xff
		data[frame * 2 + 1] = (pcm >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream


func _play(kind: StringName, point: Vector3, spatial: bool = true) -> void:
	if _active_players >= 24 or not _streams.has(kind): return
	_active_players += 1
	var player: Node
	if spatial:
		var emitter := AudioStreamPlayer3D.new()
		emitter.position = point
		emitter.unit_size = 12.0
		emitter.max_distance = 38.0
		emitter.volume_db = -7.0
		emitter.bus = "SFX"
		player = emitter
	else:
		var emitter := AudioStreamPlayer.new()
		emitter.bus = "UI"
		emitter.volume_db = -9.0
		player = emitter
	add_child(player)
	player.set("stream", _streams[kind])
	player.set("pitch_scale", _rng.randf_range(0.95, 1.05))
	player.finished.connect(func() -> void:
		_active_players = maxi(0, _active_players - 1)
		player.queue_free())
	player.call("play")


func play_ui() -> void:
	_play(&"ui", Vector3.ZERO, false)


func _on_combat_event(tick: int, event: StringName, payload: Dictionary) -> void:
	var point: Vector3 = payload.get("position", Vector3.ZERO)
	match event:
		&"attack_windup_started":
			if payload.get("source", -1) == 0: _play(&"swing", _unit_position(0))
		&"damage_dealt":
			_play(&"crit" if payload.get("crit", false) else &"impact", point)
		&"ability_cast_completed":
			if payload.get("ability", "") == "flintlock": _play(&"shot", _unit_position(int(payload.get("source", -1))))
		&"keg_placed":
			_play(&"place", point)
		&"keg_exploded":
			_play(&"explosion", point)
		&"broadside_wave":
			_play(&"cannon", payload.get("impact", point))
		&"leap_started":
			_play(&"whoosh", point)
		&"leap_landed":
			_play(&"landing", point)
		&"healing_received":
			_play(&"heal", point)
		&"elite_slam_started":
			_play(&"warning", point)
		&"elite_slam_hit":
			_play(&"cannon", point)
		&"ability_cast_failed":
			if payload.get("source", -1) == 0: play_ui()
		&"wave_started", &"challenge_finished":
			play_ui()


func _unit_position(unit_id: int) -> Vector3:
	if not is_instance_valid(arena): return Vector3.ZERO
	for unit in arena.units:
		if unit.unit_id == unit_id: return unit.global_position
	return Vector3.ZERO
