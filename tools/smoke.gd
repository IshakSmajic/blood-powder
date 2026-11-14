extends SceneTree
## Runs the actual main scene until it has emitted 600 consecutive sim ticks.

var _received: int = 0
var _frames: int = 0
var _clock: Node
var _room: Node


func _initialize() -> void:
	call_deferred("_start")


func _start() -> void:
	_clock = root.get_node("SimClock")
	_clock.tick_advanced.connect(_on_tick)
	var scene: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene"))
	_room = scene.instantiate()
	root.add_child(_room)
	current_scene = _room
	for singleton in ["SimClock", "EventBus", "DebugConfig", "InputRouter"]:
		if not root.has_node(singleton):
			push_error("Missing autoload: " + singleton)
			quit(1)
			return
	if _room.find_children("Floor", "", true, false).is_empty() or not _room.has_node("Camera"):
		push_error("Test room is missing floor or camera")
		quit(1)


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames > 700:
		push_error("Smoke test did not finish within 700 physics frames")
		quit(1)
	return false


func _on_tick(tick: int) -> void:
	_received += 1
	if tick != _received:
		push_error("Simulation tick sequence was interrupted")
		quit(1)
	if _received == 600:
		print("SMOKE PASS: main scene ran 600 consecutive simulation ticks")
		quit(0)
