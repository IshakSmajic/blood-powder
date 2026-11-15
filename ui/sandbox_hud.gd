extends CanvasLayer

signal resume_requested
signal restart_requested

var arena: Node3D
var _status: Label
var _selected: Label
var _log: Label
var _debug: PanelContainer
var _menu: PanelContainer
var _events: Array[String] = []
var _pulse_slot: Control
var _e_slot: Control
var _passive_slot: Control
var _r_slot: Control
var _w_slot: Control
var _fail_label: Label
var _fail_left: float = 0.0
var _tuning_fields: Array[Dictionary] = []
var _training_fields: Array[Dictionary] = []
var _export_status: Label
const Slot = preload("res://ui/ability_slot.gd")


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var header := VBoxContainer.new()
	header.position = Vector2(24, 18)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(header)
	header.add_child(_label("BLOOD & POWDER   /   " + ("M2 POWDER CAPTAIN" if arena.captain != null else "M1 FOUNDATION"), 24, Color("e8d6bb")))
	_status = _label("Baking navigation…", 16)
	header.add_child(_status)
	_selected = _label("", 16)
	header.add_child(_selected)
	var footer := VBoxContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -220
	footer.offset_left = 24
	footer.offset_right = -24
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(footer)
	var slots := HBoxContainer.new()
	slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(slots)
	for key in ["P", "Q", "W", "E", "R"]:
		var slot := Slot.new()
		slot.key_label = key
		slot.usable = key == "Q"
		if key == "Q":
			slot.ability = arena.player.ability
			_pulse_slot = slot
		if key == "P" and arena.captain != null:
			slot.ability = arena.captain.passive
			_passive_slot = slot
		if key == "R" and arena.captain != null:
			slot.ability = arena.captain.r
			slot.usable = true
			_r_slot = slot
		if key == "W" and arena.captain != null:
			slot.ability = arena.captain.w
			slot.usable = true
			_w_slot = slot
		if key == "E" and arena.captain != null:
			slot.ability = arena.captain.e
			slot.charge_pool = arena.captain.charges
			slot.usable = true
			_e_slot = slot
		slots.add_child(slot)
	footer.add_child(_label("Q: Flintlock at cursor target · W: heal + cleanse · E: place keg · R: Broadside at cursor · RMB: attack keg · wait for 1 pip to detonate" if arena.captain != null else "Q: Training Pulse — nearby magic damage + slow. W/E/R and passive await class mechanics.", 16, Color("bcb5ac")))
	footer.add_child(_label("RMB move / attack · hold RMB ground to steer · A then LMB attack-move · S stop · H hold", 17))
	footer.add_child(_label("Y camera lock · Space center · wheel zoom · F1 tuning · F2 ranges · F3 state · F4 log", 17))
	footer.add_child(_label("F5 reset · F7/F8 speed · F9 pause · F10 step · Esc menu", 17))
	_log = _label("", 14)
	_log.position = Vector2(24, 160)
	_log.visible = false
	root.add_child(_log)
	_debug = PanelContainer.new()
	_debug.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_debug.offset_left = -330
	_debug.offset_right = -20
	_debug.offset_top = 20
	root.add_child(_debug)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(310, 720)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_debug.add_child(scroll)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(fields)
	fields.add_child(_label("PLAYER LIVE TUNING", 20))
	var animation_lab := Button.new()
	animation_lab.text = "Open Animation Lab"
	animation_lab.pressed.connect(func() -> void: get_tree().call_deferred("change_scene_to_file", "res://debug/anim_lab.tscn"))
	fields.add_child(animation_lab)
	for label in ["Export tuning (.tres)", "Reset tuning to file", "Export combat log (.csv)"]:
		var button := Button.new()
		button.text = label
		fields.add_child(button)
		match label:
			"Export tuning (.tres)": button.pressed.connect(_export_tuning)
			"Reset tuning to file": button.pressed.connect(DebugConfig.clear_overrides)
			_: button.pressed.connect(_export_combat_log)
	_export_status = _label("Exports go into the project's debug_exports folder.", 14)
	_export_status.custom_minimum_size.x = 270
	_export_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fields.add_child(_export_status)
	if arena.training_enabled:
		fields.add_child(_label("TRAINING DUMMIES", 18))
		_add_training_option(fields, "Behavior", arena.training_settings, &"behavior", [0, 1, 2], ["Stationary", "Strafe", "Chase slowly"])
		for field in [&"strafe_distance", &"strafe_speed", &"chase_speed", &"chase_stop_distance"]:
			_add_training_numeric(fields, field)
		_add_training_option(fields, "Enemies attack kegs", arena.training_settings, &"enemies_attack_kegs", [false, true], ["Off", "On"])
		_add_training_option(fields, "Count", arena.training_settings, &"dummy_count", [1, 2, 3, 4, 5], ["1", "2", "3", "4", "5"])
		_add_training_option(fields, "Armor", arena.training_settings, &"dummy_armor", [0.0, 50.0, 100.0], ["0", "50", "100"])
		_add_training_option(fields, "Health", arena.training_settings, &"dummy_health", [2000.0, 10000.0], ["2000", "10,000"])
		_add_training_option(fields, "Infinite health", arena.training_settings, &"infinite_health", [false, true], ["Off", "On"])
		_add_training_option(fields, "Counts as Elite", arena.training_settings, &"elite", [false, true], ["Off", "On"])
		for action in [&"reset_damage", &"restore_player"]:
			var button := Button.new()
			button.text = "Reset damage / DPS" if action == &"reset_damage" else "Restore player health"
			button.pressed.connect(func() -> void: arena.queue_training_action(action))
			fields.add_child(button)
		fields.add_child(_label("Dummy changes reset targets on the next tick.", 12))
	for property in arena.player.stats.get_property_list():
		if not property.usage & PROPERTY_USAGE_EDITOR or property.type != TYPE_FLOAT:
			continue
		var field := StringName(property.name)
		if field == &"gameplay_radius":
			# Collider/navmesh radius changes require rebuilding both together.
			continue
		var row := HBoxContainer.new()
		fields.add_child(row)
		var label := _label(String(field).replace("_", " "), 14)
		label.custom_minimum_size.x = 170
		row.add_child(label)
		var spinner := SpinBox.new()
		spinner.min_value = 0.01 if field in [&"max_health", &"attack_speed", &"gameplay_radius", &"selection_radius"] else -100.0 if field in [&"armor", &"magic_resist"] else 0.0
		spinner.max_value = 1.0 if field in [&"windup_fraction", &"crit_chance"] else 10000.0
		spinner.step = 0.001 if field in [&"attack_speed", &"windup_fraction", &"crit_chance"] else 0.05
		spinner.value = arena.player.stat(field)
		spinner.value_changed.connect(func(value: float) -> void: DebugConfig.set_override(arena.player.stats.resource_path, field, value))
		_tuning_fields.append({"control": spinner, "resource": arena.player.stats, "field": field})
		row.add_child(spinner)
	_debug.hide()
	fields.add_child(_label(arena.player.ability.data.display_name.to_upper(), 18))
	_add_ability_fields(fields, arena.player.ability, ["cooldown", "cast_time", "damage", "range", "projectile_speed", "ad_ratio"] if arena.captain != null else [])
	if arena.captain != null:
		fields.add_child(_label("SEARING EDGE (damage per burn pulse)", 18))
		_add_ability_fields(fields, arena.captain.passive, ["cooldown", "damage", "burn_duration", "speed_fraction", "speed_duration"])
		fields.add_child(_label("BROADSIDE", 18))
		_add_ability_fields(fields, arena.captain.r, ["cooldown", "cast_time", "radius", "damage", "slow_fraction", "slow_duration", "duration", "first_wave_delay", "cluster_interval", "wave_interval", "cluster_count", "waves_per_cluster", "cannonballs_per_wave"])
		fields.add_child(_label("RATION", 18))
		_add_ability_fields(fields, arena.captain.w, ["cooldown", "cast_time", "heal_flat", "heal_missing_fraction"])
		fields.add_child(_label("POWDER KEG", 18))
		_add_training_option(fields, "Decay tier", arena.captain.e.data, &"decay_interval", [2.0, 1.0, 0.5], ["2.0 seconds", "1.0 second", "0.5 seconds"])
		_add_ability_fields(fields, arena.captain.e, ["cooldown", "cast_time", "radius", "slow_fraction", "slow_duration", "range", "charges", "recharge", "decay_interval", "lifetime", "connection_distance", "chain_delay", "minimum_spacing", "armor_penetration", "crit_bonus", "elite_bonus"])
	fields.add_child(_label("APPLY TO PLAYER", 18))
	var status_grid := GridContainer.new()
	status_grid.columns = 3
	fields.add_child(status_grid)
	for kind in [&"slow", &"root", &"stun", &"burn", &"speed_buff", &"cleanse"]:
		var button := Button.new()
		button.text = String(kind).replace("_", " ").capitalize()
		button.pressed.connect(func() -> void: arena.queue_debug_status(kind))
		status_grid.add_child(button)
	_fail_label = _label("", 18, Color("ef8270"))
	_fail_label.hide()
	root.add_child(_fail_label)
	_menu = PanelContainer.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_menu.offset_left = -180
	_menu.offset_right = 180
	_menu.offset_top = -100
	root.add_child(_menu)
	var buttons := VBoxContainer.new()
	_menu.add_child(buttons)
	buttons.add_child(_label("PAUSED", 24))
	for item in ["Resume", "Restart", "Quit"]:
		var button := Button.new()
		button.text = item
		buttons.add_child(button)
		match item:
			"Resume": button.pressed.connect(func() -> void: resume_requested.emit())
			"Restart": button.pressed.connect(func() -> void: restart_requested.emit())
			"Quit": button.pressed.connect(func() -> void: get_tree().quit())
	_menu.hide()
	EventBus.combat_event.connect(_on_event)
	DebugConfig.overrides_cleared.connect(_sync_tuning_fields)


func _process(delta: float) -> void:
	var player: CombatUnit = arena.player
	_status.text = "%s · tick %06d · %.1f× · %s · HP %d/%d · %s" % [
		"PAUSED" if SimClock.state.paused else "TRAINING", SimClock.state.tick,
		SimClock.state.speed_tenths / 10.0, "CAM LOCKED" if arena.camera.locked else "CAM FREE",
		ceili(player.health), ceili(player.stat(&"max_health")), "A + click armed" if arena.attack_move_armed else ""]
	if not arena.navigation_ready:
		_status.text = "Baking navigation…"
	var status_text := player.statuses.summary(SimClock.state.tick)
	if not status_text.is_empty(): _status.text += "\n" + status_text
	_pulse_slot.usable = player.alive() and not player.statuses.has(&"stun") and player.active_cast == null
	_fail_left = maxf(0.0, _fail_left - delta)
	_fail_label.visible = _fail_left > 0.0
	_fail_label.position = get_viewport().get_mouse_position() + Vector2(16, 16)
	if _passive_slot != null: _passive_slot.usable = player.alive() and SimClock.state.tick >= arena.captain.passive.ready_tick
	if _r_slot != null: _r_slot.usable = _pulse_slot.usable
	if _w_slot != null: _w_slot.usable = player.alive() and player.active_cast == null
	if _e_slot != null:
		_e_slot.usable = _pulse_slot.usable and arena.captain.charges.available > 0
		_status.text += "\nKeg charges %d / %d" % [arena.captain.charges.available, arena.captain.charges.maximum]
	var unit: Node3D = arena.selected if is_instance_valid(arena.selected) else null
	_selected.text = "%s · HP %d · armor %.0f · MR %.0f" % [unit.unit_name, ceili(unit.health), unit.stat(&"armor"), unit.stat(&"magic_resist")] if is_instance_valid(unit) else "LMB inspect a unit"
	if is_instance_valid(unit) and unit is CombatUnit and unit.team != 0:
		_selected.text += " · %s · Damage %.1f · DPS %.1f" % ["Infinite HP" if unit.training_infinite else "Finite HP", unit.training_damage, unit.training_dps(SimClock.state.tick)]
	if arena.show_states:
		_selected.text += "\n%s · ready in %d ticks · hit tick %d" % [player.state, maxi(0, player.attack.ready_tick - SimClock.state.tick), player.attack.hit_tick]
	if is_instance_valid(unit) and unit is CombatUnit:
		var effects: String = unit.statuses.summary(SimClock.state.tick)
		if not effects.is_empty(): _selected.text += "\n" + effects
	if _log.visible:
		_log.text = "\n".join(_events.slice(maxi(0, _events.size() - 14)))


func toggle_debug() -> void:
	_debug.visible = not _debug.visible


func toggle_log() -> void:
	_log.visible = not _log.visible


func show_menu(value: bool) -> void:
	_menu.visible = value


func clear_log() -> void:
	_events.clear()


func _sync_tuning_fields() -> void:
	for binding in _training_fields:
		binding.control.select(binding.values.find(binding.resource.get(binding.field)))
	for binding in _tuning_fields:
		binding.control.set_value_no_signal(binding.resource.get(binding.field))


func _export_path(prefix: String, extension: String) -> String:
	var folder := "res://debug_exports"
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	if error != OK:
		_export_status.text = "Could not create export folder: " + error_string(error)
		return ""
	var ignore_path := folder.path_join(".gdignore")
	if not FileAccess.file_exists(ignore_path):
		var ignore := FileAccess.open(ignore_path, FileAccess.WRITE)
		if ignore != null: ignore.close()
	var stem := "%s_%s_%d" % [prefix, Time.get_datetime_string_from_system().replace(":", "-"), Time.get_ticks_usec()]
	var path := folder.path_join(stem + "." + extension)
	var suffix: int = 1
	while FileAccess.file_exists(path):
		path = folder.path_join(stem + "_" + str(suffix) + "." + extension)
		suffix += 1
	return path


func _export_tuning() -> void:
	var path := _export_path("tuning", "tres")
	if path.is_empty(): return
	var error := DebugConfig.export_overrides(path)
	_export_status.text = "Saved " + ProjectSettings.globalize_path(path) if error == OK else "Export failed: " + error_string(error)


func _export_combat_log() -> void:
	var path := _export_path("combat", "csv")
	if path.is_empty(): return
	var error: Error = arena.combat_log.export_csv(path)
	_export_status.text = "Saved %d rows to %s" % [arena.combat_log.rows.size(), ProjectSettings.globalize_path(path)] if error == OK else "Export failed: " + error_string(error)


func _on_event(tick: int, event: StringName, payload: Dictionary) -> void:
	if event == &"ability_cast_failed" and payload.source == arena.player.unit_id:
		_fail_label.text = payload.reason
		_fail_left = 0.6
		var failed_slot: Control = _e_slot if payload.get("slot", &"Q") == &"E" else _w_slot if payload.get("slot", &"Q") == &"W" else _r_slot if payload.get("slot", &"Q") == &"R" else _pulse_slot
		if failed_slot != null: failed_slot.flash_failure()
	_events.append("%06d  %s  %s" % [tick, event, str(payload)])
	if _events.size() > 200:
		_events.pop_front()


func _label(text: String, size: int, color: Color = Color("d3dae1")) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_ability_fields(container: VBoxContainer, runner: AbilityRunner, allowed: Array) -> void:
	for property in runner.data.get_property_list():
		if not property.usage & PROPERTY_USAGE_EDITOR or property.type not in [TYPE_FLOAT, TYPE_INT]: continue
		var field := StringName(property.name)
		if not allowed.is_empty() and not allowed.has(String(field)): continue
		var row := HBoxContainer.new()
		container.add_child(row)
		var label := _label(String(field).replace("_", " "), 14)
		label.custom_minimum_size.x = 170
		row.add_child(label)
		var spinner := SpinBox.new()
		spinner.min_value = 3 if field == &"charges" else 0.0
		spinner.max_value = 32 if field == &"cannonballs_per_wave" else 5 if field == &"charges" else 1.0 if field in [&"slow_fraction", &"armor_penetration", &"crit_bonus", &"heal_missing_fraction"] else 10000.0
		spinner.step = 1.0 if property.type == TYPE_INT else 0.01
		spinner.value = runner.value(field)
		spinner.value_changed.connect(func(value: float) -> void: DebugConfig.set_override(runner.data.resource_path, field, value))
		_tuning_fields.append({"control": spinner, "resource": runner.data, "field": field})
		row.add_child(spinner)


func _add_training_option(container: VBoxContainer, title: String, data: Resource, field: StringName, values: Array, labels: Array) -> void:
	var row := HBoxContainer.new()
	container.add_child(row)
	var label := _label(title, 14)
	label.custom_minimum_size.x = 170
	row.add_child(label)
	var option := OptionButton.new()
	for text in labels: option.add_item(text)
	option.select(values.find(DebugConfig.resolve(data.resource_path, field, data.get(field))))
	option.item_selected.connect(func(index: int) -> void: DebugConfig.set_override(data.resource_path, field, values[index]))
	row.add_child(option)
	_training_fields.append({"control": option, "resource": data, "field": field, "values": values})


func _add_training_numeric(container: VBoxContainer, field: StringName) -> void:
	var data: Resource = arena.training_settings
	var row := HBoxContainer.new()
	container.add_child(row)
	var label := _label(String(field).replace("_", " ").capitalize(), 14)
	label.custom_minimum_size.x = 170
	row.add_child(label)
	var spinner := SpinBox.new()
	spinner.min_value = 0.0
	spinner.max_value = 100.0
	spinner.step = 0.05
	spinner.value = float(DebugConfig.resolve(data.resource_path, field, data.get(field)))
	spinner.value_changed.connect(func(value: float) -> void: DebugConfig.set_override(data.resource_path, field, value))
	row.add_child(spinner)
	_tuning_fields.append({"control": spinner, "resource": data, "field": field})
