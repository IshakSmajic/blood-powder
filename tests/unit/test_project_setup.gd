extends GutTest


func test_fixed_simulation_settings() -> void:
	assert_eq(Engine.physics_ticks_per_second, 60)
	assert_eq(Engine.max_physics_steps_per_frame, 8)
	assert_true(ProjectSettings.get_setting("physics/common/physics_interpolation"))
	assert_eq(ProjectSettings.get_setting("physics/3d/physics_engine"), "Jolt Physics")
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "forward_plus")


func test_all_game_bindings_exist_and_consumables_stay_reserved() -> void:
	var actions := ["move_attack", "select_inspect", "attack_move", "stop", "hold_position",
		"ability_q", "ability_w", "ability_e", "ability_r", "center_camera", "toggle_camera_lock",
		"zoom_in", "zoom_out", "pause_menu", "debug_panel", "debug_ranges", "debug_states",
		"debug_log", "debug_reset", "debug_class", "debug_slower", "debug_faster", "debug_pause", "debug_step"]
	for action in actions:
		assert_true(InputMap.has_action(action), action)
		assert_eq(InputMap.action_get_events(action).size(), 1, action)
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				assert_false(event.physical_keycode in [KEY_1, KEY_2, KEY_3, KEY_4], action)
	assert_eq(InputMap.action_get_events("debug_panel")[0].physical_keycode, KEY_F1)
	assert_eq(InputMap.action_get_events("debug_step")[0].physical_keycode, KEY_F10)
	assert_eq(InputMap.action_get_events("pause_menu")[0].physical_keycode, KEY_ESCAPE)
	assert_eq(InputMap.action_get_events("move_attack")[0].button_index, MOUSE_BUTTON_RIGHT)


func test_session_override_falls_back_after_reset() -> void:
	DebugConfig.set_override("test://stats", &"health", 1200)
	assert_eq(DebugConfig.resolve("test://stats", &"health", 1000), 1200)
	assert_eq(DebugConfig.resolve("test://other", &"health", 1000), 1000)
	DebugConfig.clear_overrides()
	assert_eq(DebugConfig.resolve("test://stats", &"health", 1000), 1000)
