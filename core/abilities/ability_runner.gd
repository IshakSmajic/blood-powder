class_name AbilityRunner
extends RefCounted

var data: AbilityData
var ready_tick: int = 0
var completion_tick: int = -1
var cooldown_ticks: int = 180


func value(field: StringName) -> float:
	return float(DebugConfig.resolve(data.resource_path, field, data.get(field)))


func start(tick: int) -> String:
	if completion_tick >= 0: return "Casting"
	if tick < ready_tick: return "On cooldown"
	cooldown_ticks = maxi(1, roundi(value(&"cooldown") * 60.0))
	ready_tick = tick + cooldown_ticks
	completion_tick = tick + maxi(0, roundi(value(&"cast_time") * 60.0))
	return ""


func take_completion(tick: int) -> bool:
	if completion_tick < 0 or tick < completion_tick: return false
	completion_tick = -1
	return true


func interrupt() -> void:
	# A committed cast keeps its cooldown even if stunned before completion.
	completion_tick = -1


func reset() -> void:
	ready_tick = 0
	completion_tick = -1
