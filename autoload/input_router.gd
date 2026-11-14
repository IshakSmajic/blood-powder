extends Node
## Converts raw inputs to actions; the active arena resolves world targets.

signal reset_requested
signal pause_menu_requested
signal world_action(action: StringName)

var gameplay_blocked: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_released("move_attack"):
		world_action.emit(&"move_release")
		return
	if gameplay_blocked and not event.is_action_pressed("pause_menu") and not event.is_action_pressed("debug_reset"):
		return
	if event.is_action_pressed("debug_reset"):
		reset_requested.emit()
	elif event.is_action_pressed("debug_pause"):
		SimClock.state.set_paused(not SimClock.state.paused)
	elif event.is_action_pressed("debug_step"):
		SimClock.state.request_step()
	elif event.is_action_pressed("debug_slower"):
		SimClock.state.set_speed(SimClock.state.speed_tenths - 1)
	elif event.is_action_pressed("debug_faster"):
		SimClock.state.set_speed(SimClock.state.speed_tenths + 1)
	elif event.is_action_pressed("pause_menu"):
		pause_menu_requested.emit()
	else:
		for action in [&"move_attack", &"select_inspect", &"attack_move", &"stop", &"hold_position",
			&"toggle_camera_lock", &"zoom_in", &"zoom_out", &"debug_panel", &"debug_ranges", &"debug_states", &"debug_log", &"ability_q", &"ability_e"]:
			if event.is_action_pressed(action):
				world_action.emit(action)
				get_viewport().set_input_as_handled()
				return
		return
	get_viewport().set_input_as_handled()
