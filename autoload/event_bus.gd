extends Node
## Presentation and logging notifications. Gameplay must not depend on listeners.

signal combat_event(tick: int, event_name: StringName, payload: Dictionary)


func publish(event_name: StringName, payload: Dictionary = {}) -> void:
	combat_event.emit(SimClock.state.tick, event_name, payload.duplicate(true))
