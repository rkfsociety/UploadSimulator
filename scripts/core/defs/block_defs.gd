extends RefCounted
class_name BlockDefs
## Реестр типов блоков: сборка из отдельных файлов в `defs/modules/`.

const _NetworkModule := preload("res://scripts/core/defs/modules/network_module.gd")
const _TextDownloaderModule := preload("res://scripts/core/defs/modules/text_downloader_module.gd")
const _UploaderModule := preload("res://scripts/core/defs/modules/uploader_module.gd")
const _CollectorModule := preload("res://scripts/core/defs/modules/collector_module.gd")

const _MODULE_SCRIPTS: Array = [
	_NetworkModule,
	_TextDownloaderModule,
	_UploaderModule,
	_CollectorModule,
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
const _VALID_PORT_KINDS: Array[String] = ["file", "money", "net"]
const _VALID_PORT_DIRS: Array[String] = ["in", "out"]

const DEFAULT_CELLS_W := 6
const DEFAULT_CELLS_H := 3
const MIN_CELLS_W := 3
const MIN_CELLS_H := 2

static var TYPES: Dictionary = {}
static var ALLOWED_WIRES: Array[Array] = []
static var PORT_DEFS: Dictionary = {}


static func _static_init() -> void:
	_register_modules()
	_build_port_defs()
	_validate_defs()


static func _register_modules() -> void:
	TYPES.clear()
	ALLOWED_WIRES.clear()
	for module_script: Variant in _MODULE_SCRIPTS:
		var type_id: String = str(module_script.TYPE_ID)
		if TYPES.has(type_id):
			push_error("BlockDefs: дублирующий TYPE_ID «%s»." % type_id)
			continue
		TYPES[type_id] = module_script.build()
		for pair: Variant in module_script.wire_pairs():
			if pair is Array and (pair as Array).size() == 2:
				ALLOWED_WIRES.append([str(pair[0]), str(pair[1])])


static func sync_limits_from_balance() -> void:
	pass


static func get_block_color(type_id: String) -> Color:
	return TYPES.get(type_id, {}).get("color", Color(0.0, 0.88, 1.0, 1.0))


static func cells_w(type_id: String) -> int:
	return int(TYPES.get(type_id, {}).get("cells_w", DEFAULT_CELLS_W))


static func cells_h(type_id: String) -> int:
	return int(TYPES.get(type_id, {}).get("cells_h", DEFAULT_CELLS_H))


static func cells_size(type_id: String) -> Vector2i:
	return Vector2i(cells_w(type_id), cells_h(type_id))


static func starter_kit_types() -> Array[String]:
	var ids: Array[String] = []
	for module_script: Variant in _MODULE_SCRIPTS:
		if module_script.in_starter_kit():
			ids.append(str(module_script.TYPE_ID))
	return ids


static func is_downloader_type(type_id: String) -> bool:
	return TYPES.get(type_id, {}).has("file_type_id")


static func get_downloader_file_type(type_id: String) -> String:
	return str(TYPES.get(type_id, {}).get("file_type_id", ""))


static func is_upgradeable(type_id: String) -> bool:
	return bool(TYPES.get(type_id, {}).get("upgradable", true))


static func is_singleton_type(type_id: String) -> bool:
	return bool(TYPES.get(type_id, {}).get("singleton_on_field", false))


static func max_stored_files(type_id: String) -> int:
	return int(TYPES.get(type_id, {}).get("max_stored_files", 0))


static func stores_files(type_id: String) -> bool:
	return max_stored_files(type_id) > 0


static func downloader_type_ids() -> Array[String]:
	var ids: Array[String] = []
	for type_id in TYPES:
		if is_downloader_type(type_id):
			ids.append(type_id)
	ids.sort()
	return ids


static func starter_kit_cost() -> int:
	var total := 0
	for type_id in starter_kit_types():
		total += int(TYPES[type_id]["shop_cost"])
	return total


static func is_unlocked_at_start(type_id: String) -> bool:
	return bool(TYPES.get(type_id, {}).get("unlocked_at_start", false))


static func diamond_unlock_cost(type_id: String) -> int:
	return int(TYPES.get(type_id, {}).get("diamond_unlock_cost", 0))


static func requires_diamond_unlock(type_id: String) -> bool:
	return not is_unlocked_at_start(type_id) and diamond_unlock_cost(type_id) > 0


static func get_diamond_lockable_type_ids() -> Array[String]:
	var ids: Array[String] = []
	for type_id in TYPES:
		if requires_diamond_unlock(type_id):
			ids.append(type_id)
	ids.sort()
	return ids


static func is_allowed_wire(
	from_type: String, from_port: String, to_type: String, to_port: String
) -> bool:
	var resolved := resolve_wire_ports(from_type, to_type)
	if resolved.is_empty():
		return false
	return resolved["from_port"] == from_port and resolved["to_port"] == to_port


static func resolve_wire_ports(from_type: String, to_type: String) -> Dictionary:
	if not _is_allowed_type_pair(from_type, to_type):
		return {}
	var from_ports: Dictionary = PORT_DEFS.get(from_type, {})
	var to_ports: Dictionary = PORT_DEFS.get(to_type, {})
	for out_port_id in from_ports:
		var out_def: Dictionary = from_ports[out_port_id]
		if out_def.get("dir", "") != "out":
			continue
		var out_kind := str(out_def.get("kind", ""))
		for in_port_id in to_ports:
			var in_def: Dictionary = to_ports[in_port_id]
			if in_def.get("dir", "") != "in":
				continue
			if str(in_def.get("kind", "")) == out_kind:
				return {"from_port": out_port_id, "to_port": in_port_id}
	return {}


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
	if is_upgradeable(type_id):
		if not type_def.has("effect_per_level") and not type_def.has("capacity_files_per_level"):
			push_error(
				"BlockDefs: тип «%s» должен иметь effect_per_level или capacity_files_per_level." % type_id
			)
	if is_downloader_type(type_id):
		var ft := get_downloader_file_type(type_id)
		if ft == "" or not FileDefs.TYPES.has(ft):
			push_error(
				"BlockDefs: загрузчик «%s» ссылается на неизвестный file_type_id «%s»." % [type_id, ft]
			)
		if max_stored_files(type_id) <= 0:
			push_error("BlockDefs: тип загрузчика «%s» должен иметь max_stored_files > 0." % type_id)
	if stores_files(type_id) and not is_downloader_type(type_id):
		push_error("BlockDefs: max_stored_files сейчас только у типов загрузчиков (Text Downloader и др.).")
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
				+ "(нужен out и in с одинаковым kind)."
			)
			% [from_type, to_type]
		)
