class_name DamageResolver
extends RefCounted


static func resolve(raw: float, resist: float, penetration: float = 0.0) -> float:
	var effective := resist * (1.0 - clampf(penetration, 0.0, 1.0))
	var multiplier := 100.0 / (100.0 + effective) if effective >= 0.0 else 2.0 - 100.0 / (100.0 - effective)
	return maxf(0.0, raw) * multiplier
