extends SceneTree
## Verify selected stock assets load as scenes with their expected skeletons/clips.

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/asset_manifest.json"))
	for entry in manifest.assets:
		var path: String = "res://" + entry.path
		var packed := load(path) as PackedScene
		if packed == null:
			_fail("Cannot import " + path)
			continue
		var instance := packed.instantiate()
		root.add_child(instance)
		var skeletons := instance.find_children("*", "Skeleton3D", true, false)
		if skeletons.size() != 1:
			_fail("Expected one skeleton in " + path)
		else:
			var skeleton := skeletons[0] as Skeleton3D
			if skeleton.get_bone_count() != int(entry.joint_count):
				_fail("Unexpected bone count in " + path)
		var clips: Array[String] = []
		for player in instance.find_children("*", "AnimationPlayer", true, false):
			for clip in player.get_animation_list():
				clips.append(clip)
		for expected_clip in entry.animations:
			# Godot consumes the standard _Loop suffix and enables looping.
			var imported_clip: String = expected_clip
			if not clips.has(imported_clip) and imported_clip.ends_with("_Loop"):
				imported_clip = imported_clip.trim_suffix("_Loop")
			if not clips.has(imported_clip):
				_fail("Missing animation " + expected_clip + " in " + path)
		print("ASSET: %s | skeletons=%d | clips=%d" % [entry.path, skeletons.size(), clips.size()])
		root.remove_child(instance)
		instance.free()
	var environment_paths: Array[String] = []
	for path in DirAccess.get_files_at("res://assets/environment/dungeon"):
		if path.ends_with(".glb"): environment_paths.append("res://assets/environment/dungeon/" + path)
	for path in DirAccess.get_files_at("res://assets/environment/foliage"):
		if path.ends_with(".glb"): environment_paths.append("res://assets/environment/foliage/" + path)
	environment_paths.sort()
	for path in environment_paths:
		var packed := load(path) as PackedScene
		if packed == null:
			_fail("Cannot import environment asset " + path)
			continue
		var instance := packed.instantiate()
		if instance.find_children("*", "MeshInstance3D", true, false).is_empty():
			_fail("Environment asset has no visible mesh " + path)
		instance.free()
		print("ENVIRONMENT: %s" % path.trim_prefix("res://"))
	if _failures == 0:
		print("ASSETS PASS: %d character/animation scenes and %d environment models loaded" % [manifest.assets.size(), environment_paths.size()])
	quit(0 if _failures == 0 else 1)


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)
