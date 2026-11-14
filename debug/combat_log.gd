class_name CombatLog
extends RefCounted
## Whole-arena-run log. The HUD independently keeps a short display window.

var rows: Array[Dictionary] = []


func record(tick: int, event: StringName, payload: Dictionary) -> void:
	rows.append({"tick": tick, "event": String(event), "payload": payload.duplicate(true)})


func clear() -> void:
	rows.clear()


func export_csv(path: String) -> Error:
	if FileAccess.file_exists(path): return ERR_ALREADY_EXISTS
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if error != OK: return error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_csv_line(PackedStringArray(["tick", "event", "source", "target", "value", "extra"]))
	for row in rows:
		var payload: Dictionary = row.payload.duplicate(true)
		var source: Variant = payload.get("source", payload.get("unit", ""))
		var target: Variant = payload.get("target", "")
		var value: Variant = payload.get("amount", payload.get("value", ""))
		for key in ["source", "target", "amount", "value"]: payload.erase(key)
		file.store_csv_line(PackedStringArray([str(row.tick), row.event, str(source), str(target),
			str(value), JSON.stringify(payload)]))
	file.flush()
	error = file.get_error()
	file.close()
	return error
