extends RefCounted
class_name GameBonus
## Единый расчёт бонусов от уровня модуля.


static func effect_at_level(type_id: String, level: int) -> float:
	var lvl := maxi(1, level)
	var per_level: float = float(BlockDefs.TYPES.get(type_id, {}).get("effect_per_level", 0.0))
	return float(lvl) * per_level


static func speed_scaled(base_speed: float, type_id: String, level: int) -> float:
	return base_speed * (1.0 + effect_at_level(type_id, level))


static func duration_scaled(base_duration: float, type_id: String, level: int) -> float:
	return base_duration / (1.0 + effect_at_level(type_id, level))


static func storage_capacity_mb(level: int) -> float:
	var lvl := maxi(1, level)
	var extra_gb: float = (
		float(lvl - 1) * float(BlockDefs.TYPES["storage"]["capacity_gb_per_level"])
	)
	return (GameConstants.BASE_STORAGE_GB + extra_gb) * GameConstants.MB_PER_GB


static func upgrade_cost(type_id: String, level: int) -> int:
	var def: Dictionary = BlockDefs.TYPES.get(type_id, {})
	var base_cost: float = float(def.get("upgrade_base", GameConstants.DEFAULT_UPGRADE_BASE))
	var mult: float = float(def.get("upgrade_mult", GameConstants.DEFAULT_UPGRADE_MULT))
	return int(round(base_cost * pow(mult, float(level))))
