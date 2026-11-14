extends Node
## M0 routes setup controls only. World picking and Commands arrive in M1.

signal reset_requested
signal pause_menu_requested


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
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
		return
	get_viewport().set_input_as_handled()
