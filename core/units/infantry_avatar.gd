class_name InfantryAvatar
extends CharacterAvatar
## Imported soldier presentation. Attack contact follows the simulation deadline.

const MODEL_PATH := "res://assets/characters/enemies/infantry_soldier.glb"
const ATTACK_IMPACT: float = 15.0 / 30.0 # Source local frame 16, zero-based time.
const RUN_SPEED: float = 2.13454689355
const CLIPS := {&"idle": "INF_Idle", &"run": "INF_Run", &"walk": "INF_Walk", &"attack_a": "INF_Attack", &"attack_b": "INF_Attack", &"hit": "INF_HitReaction", &"death": "INF_Death"}

func _ready() -> void:
	name = "InfantryAvatar"
	dressed = false
	rotation.y = PI
	_model = scene(MODEL_PATH).instantiate()
	add_child(_model)
	skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var library := AnimationLibrary.new()
	for role in CLIPS:
		var source: String = CLIPS[role]
		var clip := animation_player.get_animation(source).duplicate(true) as Animation
		clip.loop_mode = Animation.LOOP_LINEAR if role in [&"idle", &"run", &"walk"] else Animation.LOOP_NONE
		library.add_animation(role, clip)
	for library_name in animation_player.get_animation_library_list():
		animation_player.remove_animation_library(library_name)
	animation_player.add_animation_library(&"", library)
	_flash = StandardMaterial3D.new()
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.albedo_color = Color(1, 1, 1, 0)
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		mesh.material_overlay = _flash
		# Equipment AABBs are local to their bone; body/armor define bind height.
		if "Body" in mesh.name or "Armor" in mesh.name:
			model_height = maxf(model_height, mesh.mesh.get_aabb().end.y)
	EventBus.combat_event.connect(_on_event)
	reset_pose()


func attack_time(visual_tick: float) -> float:
	var length := animation_player.get_animation(&"attack_a").length
	if visual_tick <= _hit_tick:
		return ATTACK_IMPACT * clampf((visual_tick - _attack_start) / maxf(1.0, _hit_tick - _attack_start), 0.0, 1.0)
	return lerpf(ATTACK_IMPACT, length, clampf((visual_tick - _hit_tick) / maxf(1.0, _ready_tick - _hit_tick), 0.0, 1.0))


func _process(delta: float) -> void:
	if not is_instance_valid(unit): return
	var tick := SimClock.state.tick
	var previous := _visual_tick
	_visual_tick = float(tick) if SimClock.state.paused else clampf(_visual_tick + delta * 60.0 * SimClock.state.speed_tenths / 10.0, tick, tick + 1.0)
	var elapsed := maxf(0.0, _visual_tick - previous) / 60.0
	if not unit.alive():
		preview(&"death", maxf(0.0, (_visual_tick - _death_start) / 60.0), elapsed)
	elif unit.statuses.has(&"stun"):
		return
	elif unit.state in ["Attack windup", "Attack backswing"]:
		preview(_attack_role, attack_time(_visual_tick), elapsed)
	else:
		var moving := unit.state in ["Moving", "Chasing"] and unit.velocity.length_squared() > 0.001
		_loop_time += elapsed * (unit.velocity.length() / RUN_SPEED if moving else 1.0)
		preview(&"run" if moving else &"idle", _loop_time, elapsed)
