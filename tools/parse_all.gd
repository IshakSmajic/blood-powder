extends SceneTree
## Explicitly load every GDScript, including code not reached by the main scene.

var _count: int = 0
var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_scan("res://")
	if _failed:
		quit(1)
	else:
		print("PARSE PASS: loaded %d scripts" % _count)
		quit(0)


func _scan(path: String) -> void:
	for filename in DirAccess.get_files_at(path):
		if filename.ends_with(".gd"):
			var script := load(path.path_join(filename)) as GDScript
			_count += 1
			if script == null or not script.can_instantiate():
				push_error("Script cannot be loaded: " + path.path_join(filename))
				_failed = true
	for directory in DirAccess.get_directories_at(path):
		if not directory.begins_with(".") and directory != "builds":
			_scan(path.path_join(directory))
