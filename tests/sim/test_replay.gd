extends GutTest

const Arena = preload("res://world/arena.tscn")
var arena: Node3D
var tick: int = 0
var paths: Array[String] = []

func before_each() -> void:
	DebugConfig.clear_overrides()
	arena = Arena.instantiate()
	add_child_autofree(arena)
	SimClock.state.set_paused(true)
	for i in range(3): await get_tree().physics_frame
	while not arena.navigation_ready: await get_tree().physics_frame
	arena.mode = "Challenge"
	arena.reset_arena()
	SimClock.state.set_paused(true)
	tick = 0

func after_each() -> void:
	for path in paths: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	paths.clear()
	DebugConfig.clear_overrides()
	SimClock.reset()

func step() -> void:
	# Extra render/physics frames during playback must not alter combat.
	if arena.replay.playing: await get_tree().physics_frame
	await get_tree().physics_frame
	tick += 1
	SimClock.state.tick = tick
	arena.simulate_tick(tick)

func output() -> String:
	var path := "res://.local/test_exports/replay_%d.bpr" % Time.get_ticks_usec()
	paths.append(path)
	return path

func test_challenge_commands_seed_tuning_and_log_reproduce_byte_for_byte() -> void:
	arena.player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, Vector3(0, 0, 5)), 0)
	while tick < 220: await step()
	var target: CombatUnit = arena.units[1]
	arena.player.queue_command(UnitCommand.create(UnitCommand.Kind.ATTACK, Vector3.ZERO, target), tick)
	while tick < 260: await step()
	var command := UnitCommand.create(UnitCommand.Kind.CAST, Vector3.ZERO, target)
	arena.player.queue_command(command, tick)
	while tick < 600: await step()
	var path := output()
	var expected: PackedByteArray = var_to_bytes(arena.combat_log.rows)
	var expected_rows: Array = arena.combat_log.rows.duplicate(true)
	assert_eq(arena.replay.save_run(arena, path), OK)
	assert_eq(arena.replay.save_run(arena, path), ERR_ALREADY_EXISTS)
	assert_eq(arena.load_replay(path), OK)
	SimClock.state.set_paused(true)
	tick = 0
	while tick < 600:
		await step()
	assert_eq(arena.replay.result, "REPLAY MATCH")
	if var_to_bytes(arena.combat_log.rows) != expected:
		for i in mini(expected_rows.size(), arena.combat_log.rows.size()):
			if var_to_bytes(expected_rows[i]) != var_to_bytes(arena.combat_log.rows[i]):
				print("FIRST REPLAY DIFFERENCE ", i, " expected=", expected_rows[i], " actual=", arena.combat_log.rows[i])
				break
	assert_true(var_to_bytes(arena.combat_log.rows) == expected, "Whole combat log bytes match")
	assert_true(SimClock.state.paused)

func test_invalid_replay_is_rejected_without_resetting_arena() -> void:
	var path := output()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var({"version": 100})
	file.close()
	arena.player.health = 321.0
	assert_eq(arena.load_replay(path), ERR_INVALID_DATA)
	assert_eq(arena.player.health, 321.0)

func test_debug_mutation_requires_reset_before_recording_again() -> void:
	arena.queue_debug_status(&"slow")
	assert_eq(arena.replay.save_run(arena, output()), ERR_UNAVAILABLE)
	arena.reset_arena()
	assert_true(arena.replay.valid)
