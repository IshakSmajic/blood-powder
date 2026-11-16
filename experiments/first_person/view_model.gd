extends Node3D
## Primitive first-person hands/weapons. Presentation reads tick deadlines only.

var unit: CombatUnit
var sword: Node3D
var pistol: Node3D
var flash: MeshInstance3D
var _start: int = -999
var _hit: int = -999
var _recovery_tick: int = -999
var _shot: int = -999

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	sword = Node3D.new()
	add_child(sword)
	pistol = Node3D.new()
	add_child(pistol)
	# Right sleeve, hand, guard and a broad low-poly steel blade.
	part(sword, Vector3(.15, .17, .35), Vector3(0, -.13, .08), Color("74383c"))
	part(sword, Vector3(.12, .16, .12), Vector3(0, 0, -.02), Color("c29879"))
	part(sword, Vector3(.07, .24, .065), Vector3(0, .03, -.08), Color("4c352c"))
	part(sword, Vector3(.35, .055, .11), Vector3(0, .18, -.08), Color("bb914c"))
	part(sword, Vector3(.095, .77, .045), Vector3(0, .59, -.08), Color("aebfc7"))
	part(sword, Vector3(.025, .72, .052), Vector3(0, .58, -.08), Color("d8e1dd"))
	# Left hand flintlock: wooden stock, brass furniture and an iron barrel.
	part(pistol, Vector3(.15, .17, .26), Vector3(0, -.12, .06), Color("74383c"))
	part(pistol, Vector3(.12, .13, .15), Vector3(0, -.03, -.08), Color("c29879"))
	part(pistol, Vector3(.08, .19, .11), Vector3(0, .015, -.10), Color("5b3625"))
	part(pistol, Vector3(.10, .10, .36), Vector3(0, .11, -.23), Color("63432d"))
	part(pistol, Vector3(.065, .065, .37), Vector3(0, .17, -.28), Color("9ca6a7"))
	part(pistol, Vector3(.12, .035, .07), Vector3(0, .11, -.20), Color("c6a05c"))
	part(pistol, Vector3(.025, .08, .06), Vector3(.065, .18, -.08), Color("494a47"))
	flash = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = .075
	sphere.height = .15
	flash.mesh = sphere
	flash.position = Vector3(0, .17, -.5)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("ffe4a0")
	flash.material_override = material
	pistol.add_child(flash)
	EventBus.combat_event.connect(_on_event)
	reset_visuals()


func part(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = at
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	visual.material_override = material
	parent.add_child(visual)


func reset_visuals() -> void:
	_start = -999
	_hit = -999
	_recovery_tick = -999
	_shot = -999
	_process(0)


func _on_event(tick: int, event: StringName, payload: Dictionary) -> void:
	if payload.get("source", -1) != unit.unit_id: return
	if event == &"attack_windup_started":
		_start = tick
		_hit = payload.hit_tick
		_recovery_tick = unit.attack.ready_tick
	elif event == &"attack_cancelled":
		_start = -999
	elif event == &"ability_cast_completed" and payload.ability == "flintlock":
		_shot = tick


func _process(_delta: float) -> void:
	var tick := SimClock.state.tick
	sword.position = Vector3(.43, -.48, -.70)
	sword.rotation_degrees = Vector3(-12, -12, -18)
	if _start >= 0 and tick >= _start and tick <= _recovery_tick:
		if tick <= _hit:
			var phase := (tick - _start) / float(maxi(1, _hit - _start))
			if phase < .6:
				sword.rotation_degrees = Vector3(-12, -12, -18).lerp(Vector3(-40, 15, -55), phase / .6)
			else:
				var contact := (phase - .6) / .4
				sword.position = sword.position.lerp(Vector3(-.08, -.38, -.85), contact)
				sword.rotation_degrees = Vector3(-40, 15, -55).lerp(Vector3(-60, -15, 65), contact)
		else:
			var phase := clampf((tick - _hit) / 20.0, 0, 1)
			sword.position = Vector3(-.08, -.38, -.85).lerp(sword.position, phase)
			sword.rotation_degrees = Vector3(-60, -15, 65).lerp(Vector3(-12, -12, -18), phase)
	pistol.position = Vector3(-.36, -.30, -.62)
	pistol.rotation = Vector3.ZERO
	var recoil := 1.0 - clampf((tick - _shot) / 12.0, 0, 1)
	if tick >= _shot:
		pistol.position.z += recoil * .11
		pistol.rotation.x = recoil * .18
	flash.visible = tick >= _shot and tick < _shot + 4
