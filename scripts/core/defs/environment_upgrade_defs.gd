extends RefCounted
class_name EnvironmentUpgradeDefs
## Глобальные улучшения за алмазы (магазин ◆). Сейчас пусто — новые типы добавляются сюда.

const UPGRADES := {}

const _REQUIRED_KEYS: Array[String] = [
	"name",
	"icon",
	"desc",
	"diamond_cost_base",
	"diamond_cost_mult",
	"max_level",
	"effect_per_level",
	"effect_key"
]


static func _static_init() -> void:
	for upgrade_id in UPGRADES:
		_validate(upgrade_id, UPGRADES[upgrade_id])


static func get_upgrade_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in UPGRADES.keys():
		ids.append(str(k))
	ids.sort()
	return ids


# Стоимость следующего уровня в алмазах
static func diamond_cost_for_level(upgrade_id: String, current_level: int) -> int:
	var def: Dictionary = UPGRADES.get(upgrade_id, {})
	var base: float = float(def.get("diamond_cost_base", 1))
	var mult: float = float(def.get("diamond_cost_mult", 1.4))
	return int(round(base * pow(mult, float(current_level))))


static func is_max_level(upgrade_id: String, level: int) -> bool:
	return level >= int(UPGRADES.get(upgrade_id, {}).get("max_level", 0))


static func _validate(upgrade_id: String, def: Dictionary) -> void:
	for key in _REQUIRED_KEYS:
		if not def.has(key):
			push_error("EnvironmentUpgradeDefs: «%s» без поля «%s»." % [upgrade_id, key])
