class_name EnemyUnit
extends CombatUnit

var driver: RefCounted
var ranged: bool = false

func _create_avatar() -> CharacterAvatar:
	return KnightBossAvatar.new() if stats.resource_path.get_file() == "elite.tres" else InfantryAvatar.new()

func _hit(tick: int, ignore_range: bool = false) -> void:
	if is_instance_valid(_victim) and _victim == driver.arena.player and not driver.arena.player_visible_to(self, tick): return
	if not ranged:
		super._hit(tick, ignore_range)
		return
	if not is_instance_valid(_victim) or not _victim.alive() or not in_attack_range(_victim): return
	driver.launch(_victim, tick)
