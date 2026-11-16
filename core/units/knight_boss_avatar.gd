class_name KnightBossAvatar
extends CharacterAvatar
## Retargeted low-poly boss. Simulation owns every hit and attack deadline.

const MODEL_PATH := "res://assets/characters/enemies/knight_boss.glb"
const BOSS_SCALE := 1.25
# Three successive basic attacks trace the full heavy combo, rather than
# compressing its 4.33 seconds into a single 1.67-second attack cycle.
const COMBO_BOUNDARIES := [0.0, 1.45, 2.90, 4.333333]
const COMBO_IMPACTS := [0.73, 2.10, 3.53]
var combo_step: int = 0
var _slam_start: int = -1
var _slam_hit: int = -1


func _ready() -> void:
	name = "KnightBossAvatar"
	dressed = false
	rotation.y = PI
	_model = scene(MODEL_PATH).instantiate()
	_model.scale = Vector3.ONE * BOSS_SCALE
	add_child(_model)
	skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# Make loop flags instance-local; imported resources may be shared by previews.
	for library_name in animation_player.get_animation_library_list():
		var library := animation_player.get_animation_library(library_name).duplicate(true) as AnimationLibrary
		animation_player.remove_animation_library(library_name)
		animation_player.add_animation_library(library_name, library)
	for role in [&"idle", &"run"]:
		animation_player.get_animation(role).loop_mode = Animation.LOOP_LINEAR
	_flash = StandardMaterial3D.new()
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.albedo_color = Color(1, 1, 1, 0)
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		mesh.material_overlay = _flash
		model_height = maxf(model_height, mesh.mesh.get_aabb().end.y * BOSS_SCALE)
	EventBus.combat_event.connect(_on_event)
	reset_pose()


func reset_pose() -> void:
	combo_step = 0
	_slam_start = -1
	_slam_hit = -1
	super.reset_pose()


func combo_time(visual_tick: float) -> float:
	var first: float = COMBO_BOUNDARIES[combo_step]
	var impact: float = COMBO_IMPACTS[combo_step]
	var last: float = COMBO_BOUNDARIES[combo_step + 1]
	if visual_tick <= _hit_tick:
		return lerpf(first, impact, clampf((visual_tick - _attack_start) / maxf(1.0, _hit_tick - _attack_start), 0.0, 1.0))
	return lerpf(impact, last, clampf((visual_tick - _hit_tick) / maxf(1.0, _ready_tick - _hit_tick), 0.0, 1.0))


func _process(delta: float) -> void:
	if not is_instance_valid(unit): return
	var tick := SimClock.state.tick
	var previous := _visual_tick
	_visual_tick = float(tick) if SimClock.state.paused else clampf(_visual_tick + delta * 60.0 * SimClock.state.speed_tenths / 10.0, tick, tick + 1.0)
	var elapsed := maxf(0.0, _visual_tick - previous) / 60.0
	_loop_time += elapsed
	if not unit.alive():
		preview(&"death", maxf(0.0, (_visual_tick - _death_start) / 60.0), elapsed)
	elif _slam_hit >= 0 and tick <= _slam_hit:
		# The sword slam's contact pose meets the existing 60-tick AoE deadline.
		preview(&"slam", 0.60 * clampf((_visual_tick - _slam_start) / maxf(1.0, _slam_hit - _slam_start), 0.0, 1.0), elapsed)
	elif unit.statuses.has(&"stun"):
		return
	elif unit.state in ["Attack windup", "Attack backswing"]:
		preview(&"combo", combo_time(_visual_tick), elapsed)
	elif _slam_hit >= 0 and tick < _slam_hit + 56 and unit.velocity.length_squared() < 0.001:
		preview(&"slam", 0.60 + (_visual_tick - _slam_hit) / 60.0, elapsed)
	else:
		preview(&"run" if unit.state in ["Moving", "Chasing"] and unit.velocity.length_squared() > 0.001 else &"idle", _loop_time, elapsed)


func _on_event(tick: int, event: StringName, payload: Dictionary) -> void:
	if not is_instance_valid(unit): return
	if event == &"unit_died" and payload.unit == unit.unit_id:
		_death_start = tick
	if payload.get("source", -1) != unit.unit_id: return
	if event == &"attack_windup_started":
		# Restart at the first beat after a chase/pause instead of jumping into
		# the middle of a combo that the player has not seen wind up.
		combo_step = (_attack_serial % 3) if tick <= _ready_tick + 12 else 0
		_attack_serial = combo_step + 1
		_attack_start = tick
		_hit_tick = payload.hit_tick
		_ready_tick = unit.attack.ready_tick
	elif event == &"attack_cancelled":
		_attack_serial = 0
	elif event == &"elite_slam_started":
		_slam_start = tick
		_slam_hit = payload.end_tick
		_attack_serial = 0
