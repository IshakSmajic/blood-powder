class_name StatusEffects
extends RefCounted
## Integer deadlines; different slows coexist but only the strongest applies.

var effects: Dictionary = {}


func apply(kind: StringName, tick: int, duration: int, magnitude: float = 0.0, source: StringName = &"default", source_id: int = -1) -> void:
	if duration <= 0:
		return
	var key := String(kind) if kind in [&"root", &"stun", &"burn"] else "%s:%s" % [kind, source]
	var prior: Dictionary = effects.get(key, {})
	var expires := tick + duration
	if kind in [&"root", &"stun"]:
		expires = maxi(expires, int(prior.get("expires", 0)))
	effects[key] = {"kind": kind, "expires": expires, "magnitude": magnitude,
		"source_id": source_id, "next_pulse": int(prior.get("next_pulse", tick + 30))}


func advance(tick: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for key in effects.keys():
		var entry: Dictionary = effects[key]
		if entry.kind == &"burn":
			while entry.next_pulse <= mini(tick, entry.expires):
				events.append({"event": &"burn_pulse", "amount": entry.magnitude, "source_id": entry.source_id, "tick": entry.next_pulse})
				entry.next_pulse += 30
		if tick >= entry.expires:
			events.append({"event": &"status_expired", "kind": entry.kind})
			effects.erase(key)
	return events


func has(kind: StringName) -> bool:
	for entry in effects.values():
		if entry.kind == kind:
			return true
	return false


func move_multiplier() -> float:
	var slow: float = 0.0
	var buff: float = 0.0
	for entry in effects.values():
		if entry.kind == &"slow": slow = maxf(slow, clampf(entry.magnitude, 0.0, 1.0))
		if entry.kind == &"speed_buff": buff += maxf(0.0, entry.magnitude)
	return (1.0 + buff) * (1.0 - slow)


func cleanse() -> Array[StringName]:
	var removed: Array[StringName] = []
	for key in effects.keys():
		var kind: StringName = effects[key].kind
		if kind in [&"slow", &"root", &"stun"]:
			if not removed.has(kind): removed.append(kind)
			effects.erase(key)
	return removed


func clear() -> void:
	effects.clear()


func summary(tick: int) -> String:
	var labels: Array[String] = []
	for entry in effects.values():
		labels.append("%s %.1fs" % [entry.kind, maxf(0.0, (entry.expires - tick) / 60.0)])
	return ", ".join(labels)
