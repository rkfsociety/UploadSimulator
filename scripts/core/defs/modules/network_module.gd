extends RefCounted
## Модуль «Сеть» — канал в интернет, задаёт скорость передачи.

const TYPE_ID := "network"


static func build() -> Dictionary:
	return {
		"name": "Сеть",
		"icon": "🌐",
		"color": Color(0.12, 0.94, 0.78, 1.0),
		"desc": "Канал в интернет; скорость скачивания и выгрузки растёт с уровнем",
		"cells_w": 5,
		"cells_h": 3,
		"unlocked_at_start": true,
		"diamond_unlock_cost": 0,
		"shop_cost": 55,
		"upgrade_base": 32,
		"upgrade_mult": 1.44,
		"effect_per_level": 0.12,
		"ports":
		{
			"net_out": {"kind": "net", "dir": "out"},
			"net_in": {"kind": "net", "dir": "in"},
		},
	}


static func wire_pairs() -> Array:
	return [["network", "text_downloader"]]


static func in_starter_kit() -> bool:
	return true
