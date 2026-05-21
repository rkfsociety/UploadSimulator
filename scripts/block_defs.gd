extends RefCounted
class_name BlockDefs
## Описание типов блоков: покупка в магазине и улучшения на поле.

const TYPES := {
	"studio":
	{
		"name": "Студия",
		"icon": "🎬",
		"color": Color(1.0, 0.25, 0.78, 1.0),
		"desc": "Запись видео на носитель",
		"shop_cost": 55,
		"upgrade_base": 28,
		"upgrade_mult": 1.4,
		"effect_per_level": 0.1,
	},
	"downloader":
	{
		"name": "Загрузчик",
		"icon": "⬇",
		"color": Color(0.0, 0.88, 1.0, 1.0),
		"desc": "Скачивает файлы из интернета",
		"shop_cost": 75,
		"upgrade_base": 35,
		"upgrade_mult": 1.45,
		"effect_per_level": 0.1,
	},
	"storage":
	{
		"name": "Хранилище",
		"icon": "💾",
		"color": Color(0.58, 0.35, 1.0, 1.0),
		"desc": "Диск для скачанных роликов",
		"shop_cost": 90,
		"upgrade_base": 40,
		"upgrade_mult": 1.5,
		"capacity_gb_per_level": 40.0,
	},
	"uploader":
	{
		"name": "Аплоудер",
		"icon": "⬆",
		"color": Color(0.25, 1.0, 0.55, 1.0),
		"desc": "Выгружает в интернет, копит доход",
		"shop_cost": 85,
		"upgrade_base": 38,
		"upgrade_mult": 1.48,
		"effect_per_level": 0.12,
	},
	"collector":
	{
		"name": "Коллектор",
		"icon": "💰",
		"color": Color(1.0, 0.78, 0.15, 1.0),
		"desc": "Переводит деньги в кассу",
		"shop_cost": 65,
		"upgrade_base": 30,
		"upgrade_mult": 1.4,
		"effect_per_level": 0.05,
	},
}

const ALLOWED_WIRES: Array[Array] = [
	["downloader", "file_out", "storage", "file_in"],
	["storage", "file_out", "uploader", "file_in"],
	["uploader", "money_out", "collector", "money_in"],
]


static func get_block_color(type_id: String) -> Color:
	return TYPES.get(type_id, {}).get("color", Color(0.0, 0.88, 1.0, 1.0))


static func starter_kit_types() -> Array[String]:
	return ["studio", "downloader", "storage", "uploader", "collector"]


static func starter_kit_cost() -> int:
	var total := 0
	for type_id in starter_kit_types():
		total += int(TYPES[type_id]["shop_cost"])
	return total


const PORT_DEFS := {
	"studio": {},
	"downloader": {"file_out": {"kind": "file", "dir": "out"}},
	"storage":
	{"file_in": {"kind": "file", "dir": "in"}, "file_out": {"kind": "file", "dir": "out"}},
	"uploader":
	{"file_in": {"kind": "file", "dir": "in"}, "money_out": {"kind": "money", "dir": "out"}},
	"collector": {"money_in": {"kind": "money", "dir": "in"}},
}
