extends Node
## Gameplay subscribers run synchronously on this signal, inside _physics_process.

signal tick_advanced(tick: int)
signal reset_performed(seed_value: int)

const State = preload("res://core/simulation/tick_state.gd")
var state: TickState = State.new()


func _ready() -> void:
	process_physics_priority = -100


func _physics_process(_delta: float) -> void:
	if state.advance_physics_frame():
		tick_advanced.emit(state.tick)


func reset(seed_value: int = State.DEFAULT_SEED) -> void:
	state.reset(seed_value)
	reset_performed.emit(seed_value)


func seconds_to_ticks(seconds: float) -> int:
	return State.seconds_to_ticks(seconds)
