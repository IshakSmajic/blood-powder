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
var _fail_label: Label
var _fail_left: float = 0.0
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
	header.add_child(_label("BLOOD & POWDER   /   M1 FOUNDATION", 24, Color("e8d6bb")))
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
		slots.add_child(slot)
	footer.add_child(_label("Q: Training Pulse — nearby magic damage + slow. W/E/R and passive await class mechanics.", 16, Color("bcb5ac")))
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
	var fields := VBoxContainer.new()
	_debug.add_child(fields)
	fields.add_child(_label("PLAYER LIVE TUNING", 20))
	var animation_lab := Button.new()
	animation_lab.text = "Open Animation Lab"
	animation_lab.pressed.connect(func() -> void: get_tree().call_deferred("change_scene_to_file", "res://debug/anim_lab.tscn"))
	fields.add_child(animation_lab)
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
		row.add_child(spinner)
	_debug.hide()
	fields.add_child(_label("TRAINING PULSE", 18))
	for property in arena.player.ability.data.get_property_list():
		if not property.usage & PROPERTY_USAGE_EDITOR or property.type != TYPE_FLOAT: continue
		var field := StringName(property.name)
		var row := HBoxContainer.new()
		fields.add_child(row)
		var label := _label(String(field).replace("_", " "), 14)
		label.custom_minimum_size.x = 170
		row.add_child(label)
		var spinner := SpinBox.new()
		spinner.min_value = 0.0
		spinner.max_value = 1.0 if field == &"slow_fraction" else 10000.0
		spinner.step = 0.05
		spinner.value = arena.player.ability.value(field)
		spinner.value_changed.connect(func(value: float) -> void: DebugConfig.set_override(arena.player.ability.data.resource_path, field, value))
		row.add_child(spinner)
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
	_pulse_slot.usable = player.alive() and not player.statuses.has(&"stun") and player.ability.completion_tick < 0
	_fail_left = maxf(0.0, _fail_left - delta)
	_fail_label.visible = _fail_left > 0.0
	_fail_label.position = get_viewport().get_mouse_position() + Vector2(16, 16)
	var unit: CombatUnit = arena.selected
	_selected.text = "%s · HP %d · armor %.0f · MR %.0f" % [unit.unit_name, ceili(unit.health), unit.stat(&"armor"), unit.stat(&"magic_resist")] if is_instance_valid(unit) else "LMB inspect a unit"
	if arena.show_states:
		_selected.text += "\n%s · ready in %d ticks · hit tick %d" % [player.state, maxi(0, player.attack.ready_tick - SimClock.state.tick), player.attack.hit_tick]
	if is_instance_valid(unit):
		var effects := unit.statuses.summary(SimClock.state.tick)
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


func _on_event(tick: int, event: StringName, payload: Dictionary) -> void:
	if event == &"ability_cast_failed" and payload.source == arena.player.unit_id:
		_fail_label.text = payload.reason
		_fail_left = 0.6
		_pulse_slot.flash_failure()
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
