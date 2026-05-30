extends RefCounted
## Хранилище — диск для скачанных файлов (в штуках).

const TYPE_ID := "storage"


static func build() -> Dictionary:
	return {
		"name": "Хранилище",
		"icon": "💾",
		"color": Color(0.58, 0.35, 1.0, 1.0),
		"desc": "Диск для скачанных файлов",
		"cells_w": 5,
		"cells_h": 3,
		"unlocked_at_start": true,
		"diamond_unlock_cost": 0,
		"shop_cost": 90,
		"upgrade_base": 40,
		"upgrade_mult": 1.5,
		"capacity_files_per_level": 1.0,
		"ports":
		{
			"file_in": {"kind": "file", "dir": "in"},
			"file_out": {"kind": "file", "dir": "out"},
		},
	}


static func wire_pairs() -> Array:
	return [["storage", "uploader"]]


static func in_starter_kit() -> bool:
	return true
