extends RefCounted
class_name BlockDefs
## Описание типов блоков: покупка в магазине, порты и разрешённые соединения.

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
		"ports": {},
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
		"ports": {"file_out": {"kind": "file", "dir": "out"}},
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
		"capacity_bytes_per_level": 40.0 * 1024.0 * GameConstants.BYTE_SIZE_SCALE,
		"ports":
		{
			"file_in": {"kind": "file", "dir": "in"},
			"file_out": {"kind": "file", "dir": "out"},
		},
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
		"ports":
		{
			"file_in": {"kind": "file", "dir": "in"},
			"money_out": {"kind": "money", "dir": "out"},
		},
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
		"ports": {"money_in": {"kind": "money", "dir": "in"}},
	},
}

# Разрешённые пары типов блоков (порты подбираются автоматически по kind/dir)
const ALLOWED_WIRES: Array[Array] = [
	["downloader", "storage"],
	["storage", "uploader"],
	["uploader", "collector"],
]

const _REQUIRED_TYPE_KEYS: Array[String] = [
	"name", "icon", "color", "desc", "shop_cost", "upgrade_base", "upgrade_mult", "ports"
]
const _VALID_PORT_KINDS: Array[String] = ["file", "money"]
const _VALID_PORT_DIRS: Array[String] = ["in", "out"]

# Собирается из TYPES["ports"] при загрузке класса
static var PORT_DEFS: Dictionary = {}


static func _static_init() -> void:
	_build_port_defs()
	_validate_defs()


static func get_block_color(type_id: String) -> Color:
	return TYPES.get(type_id, {}).get("color", Color(0.0, 0.88, 1.0, 1.0))


static func starter_kit_types() -> Array[String]:
	return ["studio", "downloader", "storage", "uploader", "collector"]


static func starter_kit_cost() -> int:
	var total := 0
	for type_id in starter_kit_types():
		total += int(TYPES[type_id]["shop_cost"])
	return total


# Проверяет, разрешено ли соединение указанных портов между типами блоков
static func is_allowed_wire(
	from_type: String, from_port: String, to_type: String, to_port: String
) -> bool:
	var resolved := resolve_wire_ports(from_type, to_type)
	if resolved.is_empty():
		return false
	return resolved["from_port"] == from_port and resolved["to_port"] == to_port


# Возвращает единственную пару портов out→in для разрешённого соединения типов
static func resolve_wire_ports(from_type: String, to_type: String) -> Dictionary:
	if not _is_allowed_type_pair(from_type, to_type):
		return {}
	var from_ports: Dictionary = PORT_DEFS.get(from_type, {})
	var to_ports: Dictionary = PORT_DEFS.get(to_type, {})
	var out_port := ""
	var out_kind := ""
	for port_id in from_ports:
		var def: Dictionary = from_ports[port_id]
		if def.get("dir", "") != "out":
			continue
		if out_port != "":
			return {}
		out_port = port_id
		out_kind = str(def.get("kind", ""))
	var in_port := ""
	for port_id in to_ports:
		var def: Dictionary = to_ports[port_id]
		if def.get("dir", "") == "in" and str(def.get("kind", "")) == out_kind:
			in_port = port_id
	if out_port == "" or in_port == "":
		return {}
	return {"from_port": out_port, "to_port": in_port}


static func _build_port_defs() -> void:
	PORT_DEFS.clear()
	for type_id in TYPES:
		var type_def: Dictionary = TYPES[type_id]
		var ports: Variant = type_def.get("ports", {})
		if ports is Dictionary:
			PORT_DEFS[type_id] = (ports as Dictionary).duplicate(true)
		else:
			PORT_DEFS[type_id] = {}


static func _is_allowed_type_pair(from_type: String, to_type: String) -> bool:
	for pair in ALLOWED_WIRES:
		if pair.size() == 2 and pair[0] == from_type and pair[1] == to_type:
			return true
	return false


static func _validate_defs() -> void:
	for type_id in TYPES:
		_validate_type(type_id, TYPES[type_id])
	for pair in ALLOWED_WIRES:
		_validate_wire_pair(pair)
	for type_id in starter_kit_types():
		if not TYPES.has(type_id):
			push_error("BlockDefs: стартовый набор ссылается на неизвестный тип «%s»." % type_id)


static func _validate_type(type_id: String, type_def: Dictionary) -> void:
	for key in _REQUIRED_TYPE_KEYS:
		if not type_def.has(key):
			push_error("BlockDefs: тип «%s» не содержит обязательное поле «%s»." % [type_id, key])
	if not type_def.has("effect_per_level") and not type_def.has("capacity_bytes_per_level"):
		push_error(
			"BlockDefs: тип «%s» должен иметь effect_per_level или capacity_bytes_per_level." % type_id
		)
	var ports: Dictionary = PORT_DEFS.get(type_id, {})
	for port_id in ports:
		_validate_port(type_id, port_id, ports[port_id])


static func _validate_port(type_id: String, port_id: String, port_def: Dictionary) -> void:
	if not port_def.has("kind") or not port_def.has("dir"):
		push_error("BlockDefs: порт «%s.%s» должен содержать kind и dir." % [type_id, port_id])
		return
	var kind: String = str(port_def["kind"])
	var dir: String = str(port_def["dir"])
	if kind not in _VALID_PORT_KINDS:
		push_error("BlockDefs: порт «%s.%s» — неизвестный kind «%s»." % [type_id, port_id, kind])
	if dir not in _VALID_PORT_DIRS:
		push_error("BlockDefs: порт «%s.%s» — неизвестный dir «%s»." % [type_id, port_id, dir])


static func _validate_wire_pair(pair: Array) -> void:
	if pair.size() != 2:
		push_error("BlockDefs: ALLOWED_WIRES — элемент должен быть парой из двух типов.")
		return
	var from_type: String = str(pair[0])
	var to_type: String = str(pair[1])
	if not TYPES.has(from_type):
		push_error("BlockDefs: ALLOWED_WIRES — неизвестный тип «%s»." % from_type)
	if not TYPES.has(to_type):
		push_error("BlockDefs: ALLOWED_WIRES — неизвестный тип «%s»." % to_type)
	var resolved := resolve_wire_ports(from_type, to_type)
	if resolved.is_empty():
		push_error(
			(
				"BlockDefs: нет совместимых портов для соединения «%s» → «%s» "
				+ "(нужен ровно один out и один in с одинаковым kind)."
			)
			% [from_type, to_type]
		)
