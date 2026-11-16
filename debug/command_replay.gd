class_name CommandReplay
extends RefCounted
## Variant binary preserves exact Vector3/float values. No objects are deserialized.
const VERSION: int = 1
var commands: Array[Dictionary] = []
var playing: bool = false
var cursor: int = 0
var end_tick: int = 0
var expected_log: PackedByteArray
var result: String = ""
var seed_value: int = 1337
var class_name_value: String = "Captain"
var mode: String = "Training"
var tuning: Dictionary = {}
var valid: bool = true
var map_id: String = "graybox"

func begin(arena: Node3D) -> void:
	commands.clear()
	playing = false
	cursor = 0
	end_tick = 0
	expected_log.clear()
	result = ""
	valid = true
	seed_value = SimClock.state.rng.seed
	class_name_value = arena.active_class
	mode = arena.mode
	map_id = "battlefield" if arena.battlefield_enabled else "graybox"
	tuning = DebugConfig._overrides.duplicate(true)

func record(command: UnitCommand, tick: int) -> void:
	if playing: return
	commands.append({"tick": tick, "kind": int(command.kind), "point": command.point, "slot": String(command.slot), "target": command.target.unit_id if is_instance_valid(command.target) else -1, "keg": command.target is PowderKeg})

func feed(arena: Node3D, tick: int) -> void:
	while cursor < commands.size() and int(commands[cursor].tick) <= tick - 1:
		var row := commands[cursor]
		var target: Node3D
		if row.target >= 0:
			for candidate in arena._targets():
				if candidate.unit_id == row.target and (candidate is PowderKeg) == row.keg:
					target = candidate
					break
		var command := UnitCommand.create(row.kind, row.point, target)
		command.slot = StringName(row.slot)
		arena.player.queue_command(command, row.tick)
		cursor += 1

func save_run(arena: Node3D, path: String) -> Error:
	if playing or not valid or SimClock.state.tick < 1: return ERR_UNAVAILABLE
	if FileAccess.file_exists(path): return ERR_ALREADY_EXISTS
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if error != OK: return error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_var({"version": VERSION, "map": map_id, "engine": Engine.get_version_info().string, "seed": seed_value, "class": class_name_value, "mode": mode, "tuning": tuning, "commands": commands, "end_tick": SimClock.state.tick, "log": var_to_bytes(arena.combat_log.rows)})
	file.flush()
	return file.get_error()

func read_run(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 64000000: return {}
	var value: Variant = file.get_var(false)
	if not value is Dictionary: return {}
	for key in ["version", "engine", "seed", "class", "mode", "tuning", "commands", "end_tick", "log"]:
		if not value.has(key): return {}
	if value.version != VERSION or value.engine != Engine.get_version_info().string: return {}
	if value.get("class") not in ["Captain", "Hunter"] or value.mode not in ["Training", "Challenge"]: return {}
	if not value.seed is int or not value.end_tick is int or value.end_tick < 1: return {}
	if not value.tuning is Dictionary or not value.commands is Array or not value.log is PackedByteArray: return {}
	var previous: int = -1
	for row in value.commands:
		if not row is Dictionary: return {}
		for key in ["tick", "kind", "point", "slot", "target", "keg"]:
			if not row.has(key): return {}
		if not row.tick is int or row.tick < previous or row.tick > value.end_tick: return {}
		if not row.kind is int or row.kind < 0 or row.kind > UnitCommand.Kind.CAST: return {}
		if not row.point is Vector3 or not row.point.is_finite() or not row.target is int or not row.keg is bool: return {}
		if row.slot not in ["Q", "W", "E", "R"]: return {}
		previous = row.tick
	for path_key in value.tuning:
		if not path_key is String or not path_key.begins_with("res://data/") or not value.tuning[path_key] is Dictionary: return {}
		for field in value.tuning[path_key]:
			if not value.tuning[path_key][field] is float and not value.tuning[path_key][field] is int and not value.tuning[path_key][field] is bool: return {}
	return value

func finish(arena: Node3D, tick: int) -> void:
	if not playing or tick < end_tick: return
	result = "REPLAY MATCH" if var_to_bytes(arena.combat_log.rows) == expected_log else "REPLAY MISMATCH"
	SimClock.state.set_paused(true)
