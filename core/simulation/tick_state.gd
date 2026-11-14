class_name TickState
extends RefCounted
## Integer-only simulation pacing. One simulation tick is always 1/60 second.

const TICKS_PER_SECOND: int = 60
const DEFAULT_SEED: int = 1337

var tick: int = 0
var paused: bool = false
var speed_tenths: int = 10
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _remainder: int = 0
var _step_requested: bool = false


func _init() -> void:
	reset()


static func seconds_to_ticks(seconds: float) -> int:
	return roundi(seconds * TICKS_PER_SECOND)


func reset(seed_value: int = DEFAULT_SEED) -> void:
	tick = 0
	paused = false
	speed_tenths = 10
	_remainder = 0
	_step_requested = false
	rng.seed = seed_value


func set_speed(value: int) -> void:
	speed_tenths = clampi(value, 1, 10)


func set_paused(value: bool) -> void:
	paused = value
	_step_requested = false


func request_step() -> void:
	if paused:
		_step_requested = true


func advance_physics_frame() -> bool:
	if paused:
		if not _step_requested:
			return false
		_step_requested = false
	else:
		_remainder += speed_tenths
		if _remainder < 10:
			return false
		_remainder -= 10
	tick += 1
	return true
