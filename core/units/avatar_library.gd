class_name AvatarLibrary
extends RefCounted
## Load stock animations once; cache rest-compensated libraries per target rig.

static var _sources: Dictionary = {}
static var _libraries: Dictionary = {}
const PROFILES = {
	&"attack_a": preload("res://data/anim_profiles/attack_a.tres"),
	&"attack_b": preload("res://data/anim_profiles/attack_b.tres")}


static func source(index: int) -> Dictionary:
	if _sources.has(index): return _sources[index]
	var path := "res://assets/animations/ual%d/ual%d_standard.glb" % [index, index]
	var instance := (load(path) as PackedScene).instantiate()
	var skeleton := instance.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var player := instance.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var clips: Dictionary = {}
	for clip in player.get_animation_list(): clips[clip] = player.get_animation(clip)
	var bones: Dictionary = {}
	for i in range(skeleton.get_bone_count()):
		var parent := skeleton.get_bone_parent(i)
		bones[skeleton.get_bone_name(i)] = {"local": skeleton.get_bone_rest(i),
			"global": skeleton.get_bone_global_rest(i),
			"parent_global": skeleton.get_bone_global_rest(parent) if parent >= 0 else Transform3D.IDENTITY}
	_sources[index] = {"clips": clips, "bones": bones}
	instance.free()
	return _sources[index]


static func library_for(key: String, skeleton: Skeleton3D) -> AnimationLibrary:
	if _libraries.has(key): return _libraries[key]
	var library := AnimationLibrary.new()
	for entry in [[&"idle", 1, &"Idle"], [&"run", 1, &"Jog_Fwd"],
		[&"death", 1, &"Death01"], [&"cast", 1, &"Spell_Simple_Shoot"], [&"rest", 1, &"A_TPose"]]:
		var data := source(entry[1])
		var clip := adapt(data.clips[entry[2]], data.bones, skeleton)
		clip.loop_mode = Animation.LOOP_LINEAR if entry[0] in [&"idle", &"run"] else Animation.LOOP_NONE
		library.add_animation(entry[0], clip)
	for role in PROFILES:
		var profile: AnimProfile = PROFILES[role]
		var data := source(2)
		var combined := join(data.clips[profile.clip_name], data.clips[profile.recovery_clip])
		library.add_animation(role, adapt(combined, data.bones, skeleton))
	_libraries[key] = library
	return library


static func join(first: Animation, recovery: Animation) -> Animation:
	var clip := first.duplicate(true) as Animation
	clip.loop_mode = Animation.LOOP_NONE
	clip.length = first.length + recovery.length
	for track in range(recovery.get_track_count()):
		var path := recovery.track_get_path(track)
		var type := recovery.track_get_type(track)
		var destination := clip.find_track(path, type)
		if destination < 0:
			destination = clip.add_track(type)
			clip.track_set_path(destination, path)
		for key in range(recovery.track_get_key_count(track)):
			clip.track_insert_key(destination, first.length + recovery.track_get_key_time(track, key),
				recovery.track_get_key_value(track, key), recovery.track_get_key_transition(track, key))
	return clip


static func adapt(original: Animation, bones: Dictionary, target: Skeleton3D) -> Animation:
	var clip := original.duplicate(true) as Animation
	var source_height: float = bones["pelvis"].global.origin.y
	var target_height := target.get_bone_global_rest(target.find_bone("pelvis")).origin.y
	var height_ratio := target_height / maxf(0.001, source_height)
	for track in range(clip.get_track_count() - 1, -1, -1):
		var path := clip.track_get_path(track)
		if path.get_subname_count() != 1:
			clip.remove_track(track)
			continue
		var name := String(path.get_subname(0))
		var bone := target.find_bone(name)
		if bone < 0 or not bones.has(name):
			clip.remove_track(track)
			continue
		clip.track_set_path(track, NodePath("Skeleton3D:" + name))
		var source_bone: Dictionary = bones[name]
		var parent := target.get_bone_parent(bone)
		var parent_rest := target.get_bone_global_rest(parent) if parent >= 0 else Transform3D.IDENTITY
		var left: Quaternion = parent_rest.basis.get_rotation_quaternion().inverse() * source_bone.parent_global.basis.get_rotation_quaternion()
		var right: Quaternion = source_bone.global.basis.get_rotation_quaternion().inverse() * target.get_bone_global_rest(bone).basis.get_rotation_quaternion()
		for key in range(clip.track_get_key_count(track)):
			var value: Variant = clip.track_get_key_value(track, key)
			match clip.track_get_type(track):
				Animation.TYPE_ROTATION_3D:
					clip.track_set_key_value(track, key, (left * value * right).normalized())
				Animation.TYPE_POSITION_3D:
					# Retain target proportions; transfer only animated displacement.
					var delta: Vector3 = value - source_bone.local.origin
					if name == "root": delta = Vector3.ZERO
					clip.track_set_key_value(track, key, target.get_bone_rest(bone).origin + (left * delta) * height_ratio)
	return clip
