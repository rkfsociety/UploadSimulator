extends RefCounted
class_name BlockDefs
## Описание типов блоков: покупка в магазине, порты и разрешённые соединения.

const TYPES := {
	"downloader":
	{
		"name": "Загрузчик",
		"icon": "⬇",
		"color": Color(0.0, 0.88, 1.0, 1.0),
		"desc": "Скачивает файлы из интернета",
		"cells_w": 6,
		"cells_h": 3,
		"unlocked_at_start": true,
		"diamond_unlock_cost": 0,
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
		"desc": "Диск для скачанных файлов",
		"cells_w": 7,
		"cells_h": 3,
		"unlocked_at_start": true,
		"diamond_unlock_cost": 0,
		"shop_cost": 90,
		"upgrade_base": 40,
		"upgrade_mult": 1.5,
		# Маркер модуля-хранилища: вместимость в штуках файлов растёт с уровнем
		# (база и прирост за уровень — из GameBalanceConfig).
		"capacity_files_per_level": 1.0,
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
		"cells_w": 6,
		"cells_h": 3,
		"unlocked_at_start": true,
		"diamond_unlock_cost": 0,
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
		"desc": "Забирает деньги из сейфа аплоудера в общую кассу",
		"cells_w": 5,
		"cells_h": 3,
		"unlocked_at_start": true,
		"diamond_unlock_cost": 0,
		"shop_cost": 65,
		"upgrade_base": 30,
		"upgrade_mult": 1.4,
		"effect_per_level": 0.05,
		"ports": {"money_in": {"kind": "money", "dir": "in"}},
	},
}

# Разрешённые пары типов (только эти три; обход хранилища невозможен на уровне типов).
# У каждого типа в TYPES ровно один out нужного kind — иначе resolve_wire_ports вернёт {}.
const ALLOWED_WIRES: Array[Array] = [
	["downloader", "storage"],
	["storage", "uploader"],
	["uploader", "collector"],
]

const _REQUIRED_TYPE_KEYS: Array[String] = [
	"name",
	"icon",
	"color",
	"desc",
	"unlocked_at_start",
	"diamond_unlock_cost",
	"shop_cost",
	"upgrade_base",
	"upgrade_mult",
	"ports",
]
const _VALID_PORT_KINDS: Array[String] = ["file", "money"]
const _VALID_PORT_DIRS: Array[String] = ["in", "out"]

# Размер следа модуля по умолчанию (клетки), если тип не задал свой
const DEFAULT_CELLS_W := 6
const DEFAULT_CELLS_H := 3
# Минимум: ширина под текст и порты; высота — хотя бы основная панель + полоса улучшения
const MIN_CELLS_W := 3
const MIN_CELLS_H := 2

# Собирается из TYPES["ports"] при загрузке класса
static var PORT_DEFS: Dictionary = {}


static func _static_init() -> void:
	_build_port_defs()
	_validate_defs()


# Вместимость диска за уровень — из GameBalanceConfig (без записи в const TYPES)
static func sync_limits_from_balance() -> void:
	pass


static func get_block_color(type_id: String) -> Color:
	return TYPES.get(type_id, {}).get("color", Color(0.0, 0.88, 1.0, 1.0))


## Ширина следа модуля в клетках (своя у каждого типа; иначе значение по умолчанию).
static func cells_w(type_id: String) -> int:
	return int(TYPES.get(type_id, {}).get("cells_w", DEFAULT_CELLS_W))


## Высота следа модуля в клетках.
static func cells_h(type_id: String) -> int:
	return int(TYPES.get(type_id, {}).get("cells_h", DEFAULT_CELLS_H))


## Размер следа модуля в клетках (ширина, высота).
static func cells_size(type_id: String) -> Vector2i:
	return Vector2i(cells_w(type_id), cells_h(type_id))


static func starter_kit_types() -> Array[String]:
	return ["downloader", "storage", "uploader", "collector"]


static func starter_kit_cost() -> int:
	var total := 0
	for type_id in starter_kit_types():
		total += int(TYPES[type_id]["shop_cost"])
	return total


# Модуль доступен в магазине $ без открытия в ◆
static func is_unlocked_at_start(type_id: String) -> bool:
	return bool(TYPES.get(type_id, {}).get("unlocked_at_start", false))


# Цена открытия типа в магазине улучшений (0 — уже открыт или не продаётся в ◆)
static func diamond_unlock_cost(type_id: String) -> int:
	return int(TYPES.get(type_id, {}).get("diamond_unlock_cost", 0))


# Нужно сначала открыть за алмазы, потом покупать за $
static func requires_diamond_unlock(type_id: String) -> bool:
	return not is_unlocked_at_start(type_id) and diamond_unlock_cost(type_id) > 0


# Типы для вкладки «Новые модули» в магазине ◆ (ещё не открыты игроком)
static func get_diamond_lockable_type_ids() -> Array[String]:
	var ids: Array[String] = []
	for type_id in TYPES:
		if requires_diamond_unlock(type_id):
			ids.append(type_id)
	ids.sort()
	return ids


# Проверяет, разрешено ли соединение указанных портов между типами блоков
static func is_allowed_wire(
	from_type: String, from_port: String, to_type: String, to_port: String
) -> bool:
	var resolved := resolve_wire_ports(from_type, to_type)
	if resolved.is_empty():
		return false
	return resolved["from_port"] == from_port and resolved["to_port"] == to_port


# Единственная пара портов out→in для пары типов; при двух out на типе — пусто (ошибка конфига).
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
		elif not is_unlocked_at_start(type_id):
			push_error("BlockDefs: стартовый тип «%s» должен иметь unlocked_at_start." % type_id)
		elif diamond_unlock_cost(type_id) > 0:
			push_error("BlockDefs: стартовый тип «%s» не должен требовать алмазы." % type_id)
	for type_id in TYPES:
		if requires_diamond_unlock(type_id) and diamond_unlock_cost(type_id) <= 0:
			push_error(
				"BlockDefs: тип «%s» с unlocked_at_start=false нужен diamond_unlock_cost > 0." % type_id
			)


static func _validate_type(type_id: String, type_def: Dictionary) -> void:
	for key in _REQUIRED_TYPE_KEYS:
		if not type_def.has(key):
			push_error("BlockDefs: тип «%s» не содержит обязательное поле «%s»." % [type_id, key])
	if not type_def.has("effect_per_level") and not type_def.has("capacity_files_per_level"):
		push_error(
			"BlockDefs: тип «%s» должен иметь effect_per_level или capacity_files_per_level." % type_id
		)
	if cells_w(type_id) < MIN_CELLS_W or cells_h(type_id) < MIN_CELLS_H:
		push_error(
			"BlockDefs: тип «%s» — размер %dx%d меньше минимума %dx%d клеток."
			% [type_id, cells_w(type_id), cells_h(type_id), MIN_CELLS_W, MIN_CELLS_H]
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
