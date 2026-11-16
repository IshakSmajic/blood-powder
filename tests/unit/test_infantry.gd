extends GutTest

func before_each() -> void:
	SimClock.state.set_paused(true)

func after_each() -> void:
	SimClock.reset()

func test_imported_soldier_retains_equipment_palette_skin_and_animation() -> void:
	var avatar := InfantryAvatar.new()
	add_child_autofree(avatar)
	assert_eq(avatar.skeleton.get_bone_count(), 20)
	assert_between(avatar.model_height, 2.2, 2.4)
	var meshes := avatar._model.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes.size(), 4, "Body, armor, sword and shield")
	for mesh in meshes:
		for surface in mesh.mesh.get_surface_count():
			var material: StandardMaterial3D = mesh.mesh.surface_get_material(surface)
			assert_true(material.vertex_color_use_as_albedo)
			assert_false(material.vertex_color_is_srgb)
	for role in InfantryAvatar.CLIPS:
		assert_true(avatar.animation_player.has_animation(role))
		var clip := avatar.animation_player.get_animation(role)
		for fraction in [0.0, 0.5, 1.0]:
			avatar.preview(role, clip.length * fraction)
			for bone in avatar.skeleton.get_bone_count():
				var pose := avatar.skeleton.get_bone_global_pose(bone)
				assert_true(pose.is_finite())
				assert_lt(pose.origin.length(), 4.0)
	assert_eq(avatar.animation_player.get_animation(&"run").loop_mode, Animation.LOOP_LINEAR)
	assert_eq(avatar.animation_player.get_animation(&"death").loop_mode, Animation.LOOP_NONE)
	avatar.preview(&"death", 100.0)
	assert_almost_eq(avatar.sample_time, avatar.animation_player.get_animation(&"death").length, 0.0001)

func test_soldier_contact_maps_to_hit_deadline_and_recovery_to_ready_deadline() -> void:
	var avatar := InfantryAvatar.new()
	add_child_autofree(avatar)
	avatar._attack_start = 100
	avatar._hit_tick = 120
	avatar._ready_tick = 180
	assert_almost_eq(avatar.attack_time(100), 0.0, 0.0001)
	assert_almost_eq(avatar.attack_time(120), InfantryAvatar.ATTACK_IMPACT, 0.0001)
	assert_almost_eq(avatar.attack_time(180), avatar.animation_player.get_animation(&"attack_a").length, 0.0001)
