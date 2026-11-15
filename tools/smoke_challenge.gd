extends "res://tools/smoke.gd"

func _start() -> void:
	super._start()
	_room.mode = "Challenge"
	_room.reset_arena()

func _on_tick(tick: int) -> void:
	if is_instance_valid(_room) and _room.navigation_ready and tick == 10:
		_room.player.queue_command(UnitCommand.create(UnitCommand.Kind.MOVE, Vector3(0, 0, 5)), tick)
	if tick == 600 and (_room.challenge.wave != 1 or _room.units.size() != 5):
		push_error("Challenge smoke did not spawn four first-wave enemies")
		quit(1)
		return
	super._on_tick(tick)
