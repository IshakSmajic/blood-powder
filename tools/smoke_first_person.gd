extends SceneTree

var lab: Node3D
var _frames: int = 0

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	lab = load("res://experiments/first_person/captain_lab.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	lab.set_capture(true)
	root.get_node("SimClock").tick_advanced.connect(_on_tick)

func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames > 700:
		push_error("First-person experiment did not run 600 ticks")
		quit(1)
	return false

func _on_tick(tick: int) -> void:
	if tick == 3: lab._actions.append(&"Q")
	if tick == 180:
		lab._keys[KEY_W] = true
	if tick == 230:
		lab._keys.clear()
		lab.player.sword_held = true
	if tick == 600:
		if lab.total_damage <= 0 or lab.dummy.avatar.get_script().resource_path != "res://core/units/infantry_avatar.gd":
			push_error("First-person pistol did not hit the soldier")
			quit(1)
		else:
			print("SMOKE PASS: first-person Captain ran 600 ticks with pistol, movement and soldier")
			quit(0)
