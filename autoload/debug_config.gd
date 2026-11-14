extends Node
## Session-only overrides. No config files are read or written by this service.

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
