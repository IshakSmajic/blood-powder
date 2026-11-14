extends Node
## Session-only overrides; explicit exports write standalone project data files.

signal override_changed(resource_path: String, field: StringName)
signal overrides_cleared

var _overrides: Dictionary = {}


func set_override(resource_path: String, field: StringName, value: Variant) -> void:
	if not _overrides.has(resource_path):
		_overrides[resource_path] = {}
	_overrides[resource_path][field] = value
	override_changed.emit(resource_path, field)


func resolve(resource_path: String, field: StringName, fallback: Variant) -> Variant:
	return _overrides.get(resource_path, {}).get(field, fallback)


func clear_overrides() -> void:
	_overrides.clear()
	overrides_cleared.emit()


func export_overrides(path: String) -> Error:
	if FileAccess.file_exists(path): return ERR_ALREADY_EXISTS
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if error != OK: return error
	var snapshot := TuningSnapshot.new()
	snapshot.created_at = Time.get_datetime_string_from_system()
	snapshot.engine_version = Engine.get_version_info().string
	snapshot.overrides = _overrides.duplicate(true)
	return ResourceSaver.save(snapshot, path)
