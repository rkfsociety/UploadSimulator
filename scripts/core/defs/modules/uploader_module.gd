extends RefCounted
## Аплоудер — выгрузка файлов в сеть, сейф дохода.

const TYPE_ID := "uploader"


static func build() -> Dictionary:
	return {
		"name": "Аплоудер",
		"icon": "⬆",
		"color": Color(0.25, 1.0, 0.55, 1.0),
		"desc": "Отправляет файлы в сеть через канал; копит доход",
		"cells_w": 5,
		"cells_h": 3,
		"unlocked_at_start": true,
		"diamond_unlock_cost": 0,
		"shop_cost": 85,
		"upgrade_base": 38,
		"upgrade_mult": 1.48,
		"effect_per_level": 0.05,
		"ports":
		{
			"file_in": {"kind": "file", "dir": "in"},
			"net_out": {"kind": "net", "dir": "out"},
			"money_out": {"kind": "money", "dir": "out"},
		},
	}


static func wire_pairs() -> Array:
	return [["uploader", "network"], ["uploader", "collector"]]


static func in_starter_kit() -> bool:
	return true
