class_name AttackCycle
extends RefCounted
## Absolute integer tick deadlines. Cancelling a committed backswing never refunds.

var ready_tick: int = 0
var hit_tick: int = -1


func start(tick: int, attack_speed: float, windup_fraction: float) -> bool:
	if tick < ready_tick or hit_tick >= 0:
		return false
	var period := maxi(1, roundi(60.0 / maxf(attack_speed, 0.01)))
	ready_tick = tick + period
	hit_tick = tick + maxi(1, roundi(period * clampf(windup_fraction, 0.0, 1.0)))
	return true


func take_hit(tick: int) -> bool:
	if hit_tick < 0 or tick < hit_tick:
		return false
	hit_tick = -1
	return true


func cancel(tick: int) -> bool:
	if hit_tick < 0 or tick >= hit_tick:
		return false
	hit_tick = -1
	ready_tick = tick
	return true


func reset() -> void:
	ready_tick = 0
	hit_tick = -1
