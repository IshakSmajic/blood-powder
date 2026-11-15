extends Node
## Converts raw inputs to actions; the active arena resolves world targets.

signal reset_requested
signal pause_menu_requested
signal world_action(action: StringName)

var gameplay_blocked: bool = false


const DEBUG_ACTIONS: Array[StringName] = [&"debug_panel", &"debug_class", &"debug_ranges", &"debug_states", &"debug_log", &"debug_reset", &"debug_pause", &"debug_step", &"debug_slower", &"debug_faster"]


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo: return
	if not gameplay_blocked and event.pressed and not event.alt_pressed and not event.ctrl_pressed and not event.meta_pressed and (event.physical_keycode == KEY_TAB or event.keycode == KEY_TAB):
		activate_debug(&"debug_panel")
		get_viewport().set_input_as_handled()
		return
	for action in DEBUG_ACTIONS:
		if event.is_action_pressed(action):
			activate_debug(action)
			get_viewport().set_input_as_handled()
			return


func activate_debug(action: StringName) -> void:
	if action not in DEBUG_ACTIONS: return
	if gameplay_blocked and action != &"debug_reset": return
	match action:
		&"debug_reset": reset_requested.emit()
		&"debug_pause": SimClock.state.set_paused(not SimClock.state.paused)
		&"debug_step": SimClock.state.request_step()
		&"debug_slower": SimClock.state.set_speed(SimClock.state.speed_tenths - 1)
		&"debug_faster": SimClock.state.set_speed(SimClock.state.speed_tenths + 1)
		_: world_action.emit(action)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	if event.is_action_released("move_attack"):
		world_action.emit(&"move_release")
		return
	if gameplay_blocked and not event.is_action_pressed("pause_menu") and not event.is_action_pressed("debug_reset"): return
	for action in DEBUG_ACTIONS:
		if event.is_action_pressed(action):
			activate_debug(action)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause_menu"):
		pause_menu_requested.emit()
		get_viewport().set_input_as_handled()
		return
	for action in [&"move_attack", &"select_inspect", &"attack_move", &"stop", &"hold_position", &"toggle_camera_lock", &"zoom_in", &"zoom_out", &"ability_q", &"ability_w", &"ability_e", &"ability_r"]:
		if event.is_action_pressed(action):
			world_action.emit(action)
			get_viewport().set_input_as_handled()
			return
