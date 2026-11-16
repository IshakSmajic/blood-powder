extends GutTest


func before_each() -> void:
	SimClock.state.set_paused(true)


func after_each() -> void:
	SimClock.reset()


func make_boss() -> KnightBossAvatar:
	var avatar := KnightBossAvatar.new()
	add_child_autofree(avatar)
	return avatar


func test_exported_boss_has_scaled_skinned_mesh_and_all_gameplay_roles() -> void:
	var avatar := make_boss()
	assert_eq(avatar.skeleton.get_bone_count(), 16)
	assert_between(avatar.model_height, 2.7, 3.2)
	for role in [&"idle", &"run", &"combo", &"slam", &"death"]:
		assert_true(avatar.animation_player.has_animation(role), String(role))
	assert_almost_eq(avatar.animation_player.get_animation(&"combo").length, 130.0 / 30.0, 0.01)
	assert_eq(avatar.animation_player.get_animation(&"combo").loop_mode, Animation.LOOP_NONE)
	assert_eq(avatar.animation_player.get_animation(&"idle").loop_mode, Animation.LOOP_LINEAR)
	var triangles: int = 0
	for mesh in avatar._model.find_children("*", "MeshInstance3D", true, false):
		assert_not_null(mesh.skin)
		for surface in mesh.mesh.get_surface_count():
			triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size() / 3
	assert_eq(triangles, 1416)


func test_combo_beats_reach_contact_on_authoritative_hit_ticks() -> void:
	var avatar := make_boss()
	avatar._attack_start = 100
	avatar._hit_tick = 130
	avatar._ready_tick = 200
	for beat in range(3):
		avatar.combo_step = beat
		assert_almost_eq(avatar.combo_time(100), KnightBossAvatar.COMBO_BOUNDARIES[beat], 0.0001)
		assert_almost_eq(avatar.combo_time(130), KnightBossAvatar.COMBO_IMPACTS[beat], 0.0001)
		assert_almost_eq(avatar.combo_time(200), KnightBossAvatar.COMBO_BOUNDARIES[beat + 1], 0.0001)


func test_imported_motion_remains_finite_and_bounded_across_all_clips() -> void:
	var avatar := make_boss()
	for role in [&"idle", &"run", &"combo", &"slam", &"death"]:
		var clip := avatar.animation_player.get_animation(role)
		for fraction in [0.0, 0.15, 0.33, 0.5, 0.67, 0.85, 1.0]:
			avatar.preview(role, clip.length * fraction)
			for bone in avatar.skeleton.get_bone_count():
				var pose := avatar.skeleton.get_bone_global_pose(bone)
				assert_true(pose.is_finite(), "%s bone %d" % [role, bone])
				assert_lt(pose.origin.length(), 5.0, "Mesh stays near its gameplay origin")


func test_attack_events_chain_three_beats_and_reset_after_interruption() -> void:
	var unit := EnemyUnit.new()
	unit.unit_id = 7
	autofree(unit)
	autofree(unit.movement) # Unit is deliberately outside the tree in this event fixture.
	var avatar := make_boss()
	avatar.unit = unit
	for index in range(4):
		var tick := 100 + index * 100
		unit.attack.ready_tick = tick + 100
		avatar._on_event(tick, &"attack_windup_started", {"source": 7, "hit_tick": tick + 30})
		assert_eq(avatar.combo_step, index % 3)
	avatar._on_event(410, &"attack_cancelled", {"source": 7})
	unit.attack.ready_tick = 520
	avatar._on_event(420, &"attack_windup_started", {"source": 7, "hit_tick": 450})
	assert_eq(avatar.combo_step, 0)
