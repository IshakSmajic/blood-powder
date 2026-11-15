extends GutTest

var arena: Node3D


func before_each() -> void:
	DebugConfig.clear_overrides()
	arena = preload("res://world/arena.tscn").instantiate()
	add_child_autofree(arena)
	SimClock.state.set_paused(true)
	for i in range(3): await get_tree().physics_frame


func after_each() -> void:
	InputRouter.gameplay_blocked = false
	for code in [KEY_TAB, KEY_F1, KEY_F6]:
		var release := key(code)
		release.keycode = code
		release.pressed = false
		send_key(release)
	SimClock.reset()
	DebugConfig.clear_overrides()


func key(code: Key, physical: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	if physical: event.physical_keycode = code
	else: event.keycode = code
	return event


func button(action: String) -> Button:
	return arena._hud.find_child(action, true, false) as Button


func test_tab_opens_and_closes_tools_even_with_gui_focus() -> void:
	var field := arena._hud.find_children("*", "SpinBox", true, false)[0] as SpinBox
	arena._hud.toggle_debug()
	field.get_line_edit().grab_focus()
	send_key(key(KEY_TAB))
	await get_tree().process_frame
	assert_false(arena._hud._debug.visible)
	send_key(key(KEY_TAB, false))
	await get_tree().process_frame
	assert_true(arena._hud._debug.visible)


func test_f1_reserved_shortcut_works_before_focused_gui_and_ignores_echo() -> void:
	arena._hud.toggle_debug()
	var field := arena._hud.find_children("*", "SpinBox", true, false)[0] as SpinBox
	field.get_line_edit().grab_focus()
	send_key(key(KEY_F1))
	await get_tree().process_frame
	assert_false(arena._hud._debug.visible)
	var repeat := key(KEY_F1)
	repeat.echo = true
	send_key(repeat)
	await get_tree().process_frame
	assert_false(arena._hud._debug.visible)


func test_mouse_toolbar_reaches_tools_overlays_and_clock_without_function_keys() -> void:
	button("debug_panel").pressed.emit()
	assert_true(arena._hud._debug.visible)
	button("debug_ranges").pressed.emit()
	assert_true(arena.show_ranges)
	button("debug_states").pressed.emit()
	assert_true(arena.show_states)
	button("debug_log").pressed.emit()
	assert_true(arena._hud._log.visible)
	button("debug_slower").pressed.emit()
	assert_eq(SimClock.state.speed_tenths, 9)
	button("debug_faster").pressed.emit()
	assert_eq(SimClock.state.speed_tenths, 10)
	button("debug_pause").pressed.emit()
	assert_false(SimClock.state.paused)
	button("debug_pause").pressed.emit()
	assert_true(SimClock.state.paused)
	button("debug_step").pressed.emit()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(SimClock.state.tick, 1)
	button("debug_reset").pressed.emit()
	assert_eq(SimClock.state.tick, 0)
	assert_true(arena._hud._debug.visible)


func test_toolbar_respects_menu_block_and_survives_class_switch() -> void:
	InputRouter.gameplay_blocked = true
	button("debug_ranges").pressed.emit()
	assert_false(arena.show_ranges)
	InputRouter.gameplay_blocked = false
	send_key(key(KEY_F6))
	assert_eq(arena._queued_class, "Hunter")
	button("debug_step").pressed.emit()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_not_null(arena.hunter)
	button("debug_panel").pressed.emit()
	assert_true(arena._hud._debug.visible)
	button("debug_ranges").pressed.emit()
	assert_true(arena.show_ranges)


func send_key(event: InputEventKey) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
