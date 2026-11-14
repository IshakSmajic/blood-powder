extends GutTest

var _paths: Array[String] = []


func before_each() -> void:
	DebugConfig.clear_overrides()


func after_each() -> void:
	DebugConfig.clear_overrides()
	for path in _paths: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_paths.clear()


func output(extension: String) -> String:
	var path := "res://.local/test_exports/export_%d_%d.%s" % [Time.get_ticks_usec(), _paths.size(), extension]
	_paths.append(path)
	return path


func test_tuning_snapshot_roundtrips_without_editing_source_resource() -> void:
	var source := "res://data/stats/captain.tres"
	var original := FileAccess.get_file_as_string(source)
	DebugConfig.set_override(source, &"move_speed", 3.8)
	DebugConfig.set_override("res://data/abilities/training_pulse.tres", &"cooldown", 2.5)
	var path := output("tres")
	assert_eq(DebugConfig.export_overrides(path), OK)
	DebugConfig.set_override(source, &"move_speed", 4.5)
	var snapshot := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as TuningSnapshot
	assert_not_null(snapshot)
	assert_eq(snapshot.schema_version, 1)
	assert_almost_eq(float(snapshot.overrides[source][&"move_speed"]), 3.8, 0.00001)
	assert_eq(FileAccess.get_file_as_string(source), original)
	assert_almost_eq(float(DebugConfig.resolve(source, &"move_speed", 0.0)), 4.5, 0.00001)
	assert_eq(DebugConfig.export_overrides(path), ERR_ALREADY_EXISTS)


func test_empty_tuning_snapshot_does_not_invent_overrides() -> void:
	var path := output("tres")
	assert_eq(DebugConfig.export_overrides(path), OK)
	var snapshot := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as TuningSnapshot
	assert_true(snapshot.overrides.is_empty())


func test_csv_roundtrips_quoted_multiline_payload_and_original_tick() -> void:
	var log := CombatLog.new()
	var payload := {"source": 2, "target": 3, "amount": 70.5, "reason": "quoted \"value\", next\nline"}
	log.record(16, &"damage_dealt", payload)
	payload.reason = "changed after recording"
	var path := output("csv")
	assert_eq(log.export_csv(path), OK)
	var file := FileAccess.open(path, FileAccess.READ)
	assert_eq(file.get_csv_line(), PackedStringArray(["tick", "event", "source", "target", "value", "extra"]))
	var row := file.get_csv_line()
	assert_eq(row.size(), 6)
	assert_eq(row[0], "16")
	assert_eq(row[1], "damage_dealt")
	assert_eq(row[2], "2")
	assert_eq(row[3], "3")
	assert_eq(row[4], "70.5")
	var extra: Dictionary = JSON.parse_string(row[5])
	assert_eq(extra.reason, "quoted \"value\", next\nline")
	file.close()
	assert_eq(log.export_csv(path), ERR_ALREADY_EXISTS)


func test_full_log_retains_rows_beyond_hud_window_and_clear_starts_new_run() -> void:
	var log := CombatLog.new()
	for tick in range(250): log.record(tick, &"order_issued", {"source": 0})
	assert_eq(log.rows.size(), 250)
	assert_eq(log.rows[0].tick, 0)
	assert_eq(log.rows[249].tick, 249)
	log.clear()
	assert_eq(log.rows.size(), 0)
	log.record(1, &"unit_respawned", {"unit": 4})
	var path := output("csv")
	assert_eq(log.export_csv(path), OK)
	var file := FileAccess.open(path, FileAccess.READ)
	file.get_csv_line()
	var row := file.get_csv_line()
	assert_eq(row[0], "1")
	assert_eq(row[2], "4")
	file.close()
