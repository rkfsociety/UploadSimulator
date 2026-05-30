extends RefCounted
## Text Downloader — скачивает текстовые файлы из сети.

const TYPE_ID := "text_downloader"


static func build() -> Dictionary:
	return {
		"name": "Text Downloader",
		"icon": "📄",
		"color": Color(0.0, 0.88, 1.0, 1.0),
		"desc": "Скачивает текстовые файлы из сети и передаёт на диск",
		"file_type_id": "text",
		"cells_w": 5,
		"cells_h": 3,
		"unlocked_at_start": true,
		"diamond_unlock_cost": 0,
		"shop_cost": 75,
		"upgrade_base": 35,
		"upgrade_mult": 1.45,
		"effect_per_level": 0.1,
		"ports":
		{
			"net_in": {"kind": "net", "dir": "in"},
			"file_out": {"kind": "file", "dir": "out"},
		},
	}


static func wire_pairs() -> Array:
	return [["text_downloader", "storage"]]


static func in_starter_kit() -> bool:
	return true
