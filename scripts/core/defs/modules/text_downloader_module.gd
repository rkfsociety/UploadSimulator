extends RefCounted
## Text Downloader — скачивает текстовые файлы из сети и передаёт в Загрузчик.

const TYPE_ID := "text_downloader"


static func build() -> Dictionary:
	return {
		"name": "Text Downloader",
		"icon": "📄",
		"color": Color(0.0, 0.88, 1.0, 1.0),
		"desc": "Скачивает текстовые файлы из сети и передаёт в Загрузчик",
		"file_type_id": "text",
		"upgradable": false,
		"cells_w": 5,
		"cells_h": 3,
		"unlocked_at_start": true,
		"diamond_unlock_cost": 0,
		"shop_cost": 75,
		"upgrade_base": 0,
		"upgrade_mult": 1.0,
		"ports":
		{
			"net_in": {"kind": "net", "dir": "in"},
			"file_out": {"kind": "file", "dir": "out"},
		},
	}


static func wire_pairs() -> Array:
	return [["text_downloader", "uploader"]]


static func in_starter_kit() -> bool:
	return true
