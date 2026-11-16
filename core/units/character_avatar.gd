class_name CharacterAvatar
extends Node3D
## Visual-only stock character. It never drives movement, attack ticks, or damage.

const BODY_PATH = "res://assets/characters/base/superhero_male.glb"
const OUTFIT_PATH = "res://assets/characters/outfits/male_ranger.glb"
static var _head_meshes: Array[Dictionary] = []
static var _scenes: Dictionary = {}

var unit: CombatUnit
var dressed: bool = true
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var current_role: StringName = &"idle"
var sample_time: float = 0.0
var model_height: float = 0.0
var head_triangle_count: int = 0
var _model: Node3D
var _flash: StandardMaterial3D
var _attack_role: StringName = &"attack_a"
var _attack_serial: int = 0
var _attack_start: int = 0
var _hit_tick: int = 0
var _ready_tick: int = 0
var _cast_start: int = 0
var _cast_end: int = 0
var _death_start: int = 0
var _visual_tick: float = 0.0
var _loop_time: float = 0.0
var _blend_from: Array[Transform3D] = []
var _blend_left: float = 0.0
var _blend_duration: float = 0.05
var _cast_role: StringName = &"cast"
var _howl_tick: int = -9999
var _blade_material: StandardMaterial3D
var _sword: Node3D
var _pistol: Node3D
var _visual_hit_stop_left: float = 0.0
var _flash_tween: Tween


func _ready() -> void:
	name = "StockAvatar"
	# Quaternius models face +Z; our actor faces -Z.
	rotation.y = PI
	_model = scene(OUTFIT_PATH if dressed else BODY_PATH).instantiate()
	add_child(_model)
	skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	if dressed:
		_add_head()
		_add_weapon()
	_flash = StandardMaterial3D.new()
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.albedo_color = Color(1, 1, 1, 0)
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		mesh.material_overlay = _flash
		var bounds: AABB = mesh.mesh.get_aabb()
		model_height = maxf(model_height, bounds.end.y)
		if not dressed:
			var grey := StandardMaterial3D.new()
			grey.albedo_color = Color("979fa5")
			grey.roughness = 1.0
			mesh.material_override = grey
		elif mesh.name in ["Male_Ranger_Body", "Male_Ranger_Head_Hood", "Male_Ranger_Legs"]:
			var cloth := mesh.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
			cloth.albedo_texture = null
			cloth.albedo_color = Color("79383e") if mesh.name != "Male_Ranger_Legs" else Color("302c32")
			mesh.material_override = cloth
	animation_player = AnimationPlayer.new()
	animation_player.name = "AvatarAnimations"
	_model.add_child(animation_player)
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation_player.root_node = animation_player.get_path_to(skeleton.get_parent())
	animation_player.add_animation_library(&"", AvatarLibrary.library_for("ranger" if dressed else "base", skeleton))
	EventBus.combat_event.connect(_on_event)
	reset_pose()
	print("AVATAR: %s | height %.3f m | %d bones | %d animations" % ["ranger" if dressed else "base", model_height, skeleton.get_bone_count(), animation_player.get_animation_list().size()])


func _add_head() -> void:
	if _head_meshes.is_empty():
		var base := scene(BODY_PATH).instantiate()
		for original in base.find_children("*", "MeshInstance3D", true, false):
			var cropped := ArrayMesh.new()
			var triangles: int = 0
			for surface in range(original.mesh.get_surface_count()):
				var arrays: Array = original.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				var bone_indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
				var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
				var influences: int = bone_indices.size() / vertices.size()
				var allowed := PackedByteArray()
				allowed.resize(vertices.size())
				for vertex in range(vertices.size()):
					var head_weight: float = 0.0
					for influence in range(influences):
						var index := vertex * influences + influence
						if original.skin.get_bind_name(bone_indices[index]) in [&"Head", &"neck_01"]:
							head_weight += weights[index]
					allowed[vertex] = 1 if vertices[vertex].y >= 1.54 and head_weight >= 0.95 else 0
				var kept := PackedInt32Array()
				for index in range(0, indices.size(), 3):
					if allowed[indices[index]] and allowed[indices[index + 1]] and allowed[indices[index + 2]]:
						kept.append_array(indices.slice(index, index + 3))
				if kept.is_empty(): continue
				arrays[Mesh.ARRAY_INDEX] = kept
				# Preserve custom attribute encodings and bone-weight format.
				var flags: int = original.mesh.surface_get_format(surface)
				cropped.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
				cropped.surface_set_material(cropped.get_surface_count() - 1, original.mesh.surface_get_material(surface))
				triangles += kept.size() / 3
			if triangles > 0:
				_head_meshes.append({"mesh": cropped, "skin": original.skin, "name": original.name, "triangles": triangles})
		base.free()
	for data in _head_meshes:
		var head := MeshInstance3D.new()
		head.name = "BaseHead_" + String(data.name)
		head.mesh = data.mesh
		head.skin = data.skin
		head.skeleton = NodePath("..")
		skeleton.add_child(head)
		head_triangle_count += data.triangles


static func scene(path: String) -> PackedScene:
	if not _scenes.has(path): _scenes[path] = load(path)
	return _scenes[path]


func _add_weapon() -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = "SwordAttachment"
	attachment.bone_name = "hand_r"
	skeleton.add_child(attachment)
	_sword = Node3D.new()
	attachment.add_child(_sword)
	for part in [[Vector3(0.045, 0.045, 0.65), Vector3(0, 0, 0.43), Color("b8c2c8")],
		[Vector3(0.20, 0.05, 0.045), Vector3(0, 0, 0.10), Color("b98e51")],
		[Vector3(0.065, 0.065, 0.16), Vector3(0, 0, 0), Color("574033")]]:
		var piece := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[0]
		piece.mesh = box
		piece.position = part[1]
		var material := StandardMaterial3D.new()
		material.albedo_color = part[2]
		piece.material_override = material
		if _sword.get_child_count() == 0: _blade_material = material
		_sword.add_child(piece)
	_pistol = Node3D.new()
	attachment.add_child(_pistol)
	for part in [[Vector3(0.09, 0.11, 0.26), Vector3(0, 0, 0.16), Color("61422c")],
		[Vector3(0.07, 0.18, 0.09), Vector3(0, -0.07, 0.035), Color("61422c")],
		[Vector3(0.065, 0.065, 0.32), Vector3(0, 0.025, 0.38), Color("8b9297")]]:
		var piece := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[0]
		piece.mesh = box
		piece.position = part[1]
		var material := StandardMaterial3D.new()
		material.albedo_color = part[2]
		piece.material_override = material
		_pistol.add_child(piece)
	_pistol.hide()


func set_flash(value: bool) -> void:
	_flash.albedo_color = Color(1, 1, 1, 1 if value else 0)


func flash_hit() -> void:
	if _flash_tween != null and _flash_tween.is_running(): _flash_tween.kill()
	set_flash(true)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "albedo_color", Color(1, 1, 1, 0), 0.05)


func hit_stop_visual(seconds: float) -> void:
	_visual_hit_stop_left = maxf(_visual_hit_stop_left, seconds)


func reset_pose() -> void:
	_howl_tick = -9999
	_attack_serial = 0
	_loop_time = 0.0
	_visual_tick = SimClock.state.tick
	_model.position.y = 0.0
	_model.show()
	_blend_left = 0.0
	preview(&"idle", 0.0)


func preview(role: StringName, time: float, elapsed: float = 0.0) -> void:
	if dressed:
		_sword.visible = role not in [&"shoot", &"throw"]
		_pistol.visible = role == &"shoot"
	if animation_player.current_animation != role:
		_blend_from.clear()
		if elapsed > 0.0:
			for bone in range(skeleton.get_bone_count()): _blend_from.append(skeleton.get_bone_pose(bone))
			var profile: AnimProfile = AvatarLibrary.PROFILES.get(role)
			_blend_duration = maxf(0.001, profile.blend_in if profile != null else 0.05)
			_blend_left = _blend_duration
		else:
			_blend_left = 0.0
		animation_player.play(role)
	current_role = role
	var animation := animation_player.get_animation(role)
	sample_time = fposmod(time, animation.length) if animation.loop_mode != Animation.LOOP_NONE else clampf(time, 0.0, animation.length)
	animation_player.seek(sample_time, true)
	if _blend_left > 0.0 and elapsed > 0.0:
		_blend_left = maxf(0.0, _blend_left - elapsed)
		var weight := 1.0 - _blend_left / _blend_duration
		for bone in range(skeleton.get_bone_count()):
			var pose := _blend_from[bone].interpolate_with(skeleton.get_bone_pose(bone), weight)
			skeleton.set_bone_pose_position(bone, pose.origin)
			skeleton.set_bone_pose_rotation(bone, pose.basis.get_rotation_quaternion())
			skeleton.set_bone_pose_scale(bone, pose.basis.get_scale())
	skeleton.force_update_all_bone_transforms()


func _process(delta: float) -> void:
	if not is_instance_valid(unit): return
	_visual_hit_stop_left = maxf(0.0, _visual_hit_stop_left - delta)
	if _visual_hit_stop_left > 0.0: return
	var tick := SimClock.state.tick
	if _blade_material != null:
		var ready: bool = unit.alive() and unit.cast_controller != null and not unit.cast_controller is HunterController and tick >= unit.cast_controller.passive.ready_tick
		if unit.cast_controller is HunterController: ready = unit.alive() and unit.cast_controller.ferocity.empowered()
		_blade_material.emission_enabled = ready
		_blade_material.emission = Color("f48c35")
		_blade_material.emission_energy_multiplier = 1.5 if ready else 0.0
	if unit.cast_controller is HunterController:
		set_camouflage(unit.cast_controller.camouflaged(tick))
	var previous := _visual_tick
	_visual_tick = float(tick) if SimClock.state.paused else clampf(_visual_tick + delta * 60.0 * SimClock.state.speed_tenths / 10.0, tick, tick + 1.0)
	_loop_time += maxf(0.0, _visual_tick - previous) / 60.0
	var elapsed_sim := maxf(0.0, _visual_tick - previous) / 60.0
	if not unit.alive():
		var elapsed := maxf(0.0, (_visual_tick - _death_start) / 60.0)
		preview(&"death", elapsed * (1.2 if unit.team == 1 else 1.0), elapsed_sim)
		var duration := 2.0 if unit.team == 1 else 3.0
		_model.position.y = -0.5 * clampf((elapsed - duration + 0.3) / 0.3, 0.0, 1.0)
	elif unit.statuses.has(&"stun") and not (unit.active_cast != null and unit.cast_controller != null and unit.cast_controller.cast_survives_stun(unit.active_cast)):
		return # Freeze the current visual pose while simulation handles the stun.
	elif unit.cast_controller is HunterController and tick - _howl_tick < 15:
		preview(&"cast", animation_player.get_animation(&"cast").length * clampf((tick - _howl_tick) / 15.0, 0.0, 1.0), elapsed_sim)
	elif unit.state == "Airborne":
		preview(&"leap", _loop_time, elapsed_sim)
	elif unit.state in ["Attack windup", "Attack backswing"]:
		var profile: AnimProfile = AvatarLibrary.PROFILES[_attack_role]
		var length := animation_player.get_animation(_attack_role).length
		var phase: float
		if _visual_tick <= _hit_tick:
			phase = profile.hit_time * clampf((_visual_tick - _attack_start) / maxf(1.0, _hit_tick - _attack_start), 0.0, 1.0)
		else:
			phase = profile.hit_time + (length - profile.hit_time) * clampf((_visual_tick - _hit_tick) / maxf(1.0, _ready_tick - _hit_tick), 0.0, 1.0)
		preview(_attack_role, phase, elapsed_sim)
	elif unit.state == "Casting":
		var length := animation_player.get_animation(_cast_role).length
		preview(_cast_role, length * clampf((_visual_tick - _cast_start) / maxf(1.0, _cast_end - _cast_start), 0.0, 1.0), elapsed_sim)
	else:
		preview(&"run" if unit.state in ["Moving", "Chasing"] and unit.velocity.length_squared() > 0.001 else &"idle", _loop_time, elapsed_sim)


func _on_event(tick: int, event: StringName, payload: Dictionary) -> void:
	if not is_instance_valid(unit): return
	if event == &"unit_died" and payload.unit == unit.unit_id:
		_death_start = tick
	if payload.get("source", -1) != unit.unit_id: return
	if event == &"attack_windup_started":
		_attack_role = &"attack_a" if _attack_serial % 2 == 0 else &"attack_b"
		_attack_serial += 1
		_attack_start = tick
		_hit_tick = payload.hit_tick
		_ready_tick = unit.attack.ready_tick
	elif event == &"ability_cast_started":
		if payload.ability == "howl": _howl_tick = tick
		_cast_start = tick
		_cast_end = payload.get("completion_tick", unit.ability.completion_tick)
		_cast_role = &"shoot" if payload.ability == "flintlock" else &"throw" if payload.ability in ["powder_keg", "bola"] else &"cast"


func set_hunter_style(hunter: bool) -> void:
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		if material == null and mesh.mesh.get_surface_count() > 0:
			material = mesh.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
			mesh.material_override = material
		if material == null: continue
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if hunter else BaseMaterial3D.TRANSPARENCY_DISABLED
		var color := material.albedo_color
		color.a = 1.0
		if mesh.name in ["Male_Ranger_Body", "Male_Ranger_Head_Hood"]: color = Color("426454") if hunter else Color("79383e")
		material.albedo_color = color


func set_camouflage(active: bool) -> void:
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		var material := mesh.material_override as StandardMaterial3D
		if material == null: continue
		var color := material.albedo_color
		color.a = 0.3 if active else 1.0
		material.albedo_color = color
