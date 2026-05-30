extends RefCounted
## Коллектор — переводит сейф аплоудера в общую кассу.

const TYPE_ID := "collector"


static func build() -> Dictionary:
	return {
		"name": "Коллектор",
		"icon": "💰",
		"color": Color(1.0, 0.78, 0.15, 1.0),
		"desc": "Забирает деньги из сейфа аплоудера в общую кассу",
		"cells_w": 4,
		"cells_h": 3,
		"unlocked_at_start": true,
		"diamond_unlock_cost": 0,
		"shop_cost": 65,
		"upgradable": false,
		"upgrade_base": 0,
		"upgrade_mult": 1.0,
		"ports": {"money_in": {"kind": "money", "dir": "in"}},
	}


static func wire_pairs() -> Array:
	return []


static func in_starter_kit() -> bool:
	return true
