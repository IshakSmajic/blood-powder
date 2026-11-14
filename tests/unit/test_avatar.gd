extends GutTest


func before_each() -> void:
	DebugConfig.clear_overrides()
	SimClock.state.set_paused(true)


func after_each() -> void:
	SimClock.reset()


func make_avatar(dressed: bool = true) -> CharacterAvatar:
	var avatar := CharacterAvatar.new()
	avatar.dressed = dressed
	add_child_autofree(avatar)
	return avatar


func test_stock_character_has_head_skeleton_and_expected_animation_roles() -> void:
	var avatar := make_avatar()
	assert_eq(avatar.skeleton.get_bone_count(), 65)
	assert_gt(avatar.head_triangle_count, 100)
	assert_between(avatar.model_height, 1.7, 2.0)
	for role in [&"idle", &"run", &"attack_a", &"attack_b", &"cast", &"death", &"rest"]:
		assert_true(avatar.animation_player.has_animation(role), String(role))
	for mesh in avatar.find_children("*", "MeshInstance3D", true, false):
		assert_false(mesh.mesh is CapsuleMesh, "Stock visual must replace the placeholder capsule")


func test_rest_pose_compensation_preserves_target_proportions() -> void:
	for dressed in [true, false]:
		var avatar := make_avatar(dressed)
		avatar.preview(&"rest", 0.0)
		var max_position_error: float = 0.0
		var max_rotation_error: float = 0.0
		for bone in range(avatar.skeleton.get_bone_count()):
			var rest := avatar.skeleton.get_bone_rest(bone)
			var pose := avatar.skeleton.get_bone_pose(bone)
			max_position_error = maxf(max_position_error, rest.origin.distance_to(pose.origin))
			max_rotation_error = maxf(max_rotation_error, 1.0 - absf(rest.basis.get_rotation_quaternion().dot(pose.basis.get_rotation_quaternion())))
		assert_lt(max_position_error, 0.001)
		assert_lt(max_rotation_error, 0.001)


func test_cropped_head_has_no_torso_triangles_and_fits_outfit_rest_pose() -> void:
	var avatar := make_avatar()
	var min_height: float = INF
	var max_rest_error: float = 0.0
	var triangle_count: int = 0
	for mesh in avatar.find_children("BaseHead_*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var influences: int = bones.size() / vertices.size()
			var skin_transforms: Array[Transform3D] = []
			for bind in range(mesh.skin.get_bind_count()):
				var bone := avatar.skeleton.find_bone(mesh.skin.get_bind_name(bind))
				skin_transforms.append(avatar.skeleton.get_bone_global_rest(bone) * mesh.skin.get_bind_pose(bind))
			triangle_count += indices.size() / 3
			for vertex in indices:
				min_height = minf(min_height, vertices[vertex].y)
				var skinned := Vector3.ZERO
				for influence in range(influences):
					var index := vertex * influences + influence
					skinned += (skin_transforms[bones[index]] * vertices[vertex]) * weights[index]
				max_rest_error = maxf(max_rest_error, skinned.distance_to(vertices[vertex]))
	assert_gt(triangle_count, 100)
	assert_gte(min_height, 1.539)
	assert_lt(max_rest_error, 0.002)


func test_adapted_library_is_shared_and_strikes_include_recovery() -> void:
	var first := make_avatar()
	var second := make_avatar()
	assert_same(first.animation_player.get_animation_library(&""), second.animation_player.get_animation_library(&""))
	for role in AvatarLibrary.PROFILES:
		var profile: AnimProfile = AvatarLibrary.PROFILES[role]
		var source: Animation = AvatarLibrary.source(2).clips[profile.clip_name]
		var combined := first.animation_player.get_animation(role)
		assert_gt(combined.length, source.length)
		assert_gt(profile.hit_time, 0.0)
		assert_lt(profile.hit_time, source.length)


func test_animation_samples_have_finite_bounded_bone_poses() -> void:
	var avatar := make_avatar()
	var finite: bool = true
	var max_distance: float = 0.0
	for role in [&"idle", &"run", &"attack_a", &"attack_b", &"cast", &"death"]:
		var length := avatar.animation_player.get_animation(role).length
		for fraction in [0.0, 0.25, 0.5, 0.75, 0.99]:
			avatar.preview(role, length * fraction)
			for bone in range(avatar.skeleton.get_bone_count()):
				var pose := avatar.skeleton.get_bone_global_pose(bone)
				finite = finite and pose.origin.is_finite() and pose.basis.is_finite()
				max_distance = maxf(max_distance, pose.origin.length())
	assert_true(finite)
	assert_lt(max_distance, 4.0)


func test_visual_sampling_cannot_change_unit_position_health_or_attack_deadlines() -> void:
	var unit := CombatUnit.new()
	unit.stats = preload("res://data/stats/captain.tres")
	unit.spawn_point = Vector3(1, 0, 3)
	add_child_autofree(unit)
	unit.attack.start(1, 0.658, 0.164)
	for i in range(30): unit.avatar.preview(&"attack_a", i / 60.0)
	assert_eq(unit.position, Vector3(1, 0, 3))
	assert_eq(unit.health, 1200.0)
	assert_eq(unit.attack.hit_tick, 16)
	assert_eq(unit.attack.ready_tick, 92)


func test_animation_lab_steps_frames_without_advancing_simulation() -> void:
	var lab := preload("res://debug/anim_lab.tscn").instantiate()
	add_child_autofree(lab)
	lab.step(1)
	assert_almost_eq(lab.time, 1.0 / 60.0, 0.00001)
	lab.step(-1)
	assert_eq(lab.time, 0.0)
	lab.set_character(1)
	assert_false(lab.avatar.dressed)
	assert_eq(lab.avatar.skeleton.get_bone_count(), 65)
	assert_eq(SimClock.state.tick, 0)
	assert_true(SimClock.state.paused)
