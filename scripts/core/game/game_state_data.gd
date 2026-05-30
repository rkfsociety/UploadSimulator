extends RefCounted
class_name GameStateData
## Инкапсулированное состояние игры (без публичных полей).

const _SaveConstants := preload("res://scripts/core/save/save_constants.gd")

enum Phase { IDLE, SETTLING }

var _money: float = 0.0
var _network_balance: float = 0.0
var _env_upgrade_levels: Dictionary = {}
# Типы модулей, открытые в магазине ◆ (потом покупка за $ в магазине модулей)
var _unlocked_module_types: Dictionary = {}

var _block_stock: Dictionary = {}
var _placed_blocks: Array[BlockInstance] = []
var _wire_connections: Array[WireLink] = []

var _phase: Phase = Phase.IDLE
var _uploaded_files: int = 0
var _download_queue: Array[FileTransferJob] = []
var _stored_files: Array[StoredFileEntry] = []
var _upload_queue: Array[FileTransferJob] = []

var _uid_counter: int = 0


func _init() -> void:
	reset_to_initial()


## Сброс к стартовому состоянию (новая игра): касса = стоимость базового набора,
## открыты только стартовые типы, поле/очереди/счётчики пусты.
func reset_to_initial() -> void:
	_money = float(BlockDefs.starter_kit_cost())
	_network_balance = 0.0
	_env_upgrade_levels.clear()
	_unlocked_module_types.clear()
	for type_id in BlockDefs.starter_kit_types():
		_unlocked_module_types[type_id] = true
	_block_stock.clear()
	_placed_blocks.clear()
	_wire_connections.clear()
	_phase = Phase.IDLE
	_uploaded_files = 0
	_download_queue.clear()
	_stored_files.clear()
	_upload_queue.clear()
	_uid_counter = 0


func get_money() -> float:
	return _money


func set_money(value: float) -> void:
	_money = GameValueBounds.money(value)


func add_money(amount: float) -> void:
	_money = GameValueBounds.money(_money + GameValueBounds.money_delta(amount))


func try_spend_money(amount: float) -> bool:
	var spend := GameValueBounds.money_delta(amount)
	if spend <= 0.0 or _money < spend:
		return false
	_money -= spend
	return true


func get_env_upgrade_level(upgrade_id: String) -> int:
	return int(_env_upgrade_levels.get(upgrade_id, 0))


func set_env_upgrade_level(upgrade_id: String, level: int) -> void:
	_env_upgrade_levels[upgrade_id] = GameValueBounds.env_level(level)


func is_module_type_unlocked(type_id: String) -> bool:
	if BlockDefs.is_unlocked_at_start(type_id):
		return true
	return _unlocked_module_types.has(type_id)


func unlock_module_type(type_id: String) -> void:
	_unlocked_module_types[type_id] = true


# Множитель от улучшений среды (download_speed, upload_speed, storage_capacity)
func get_env_multiplier(effect_key: String) -> float:
	var mult := 1.0
	for upgrade_id in EnvironmentUpgradeDefs.UPGRADES:
		var def: Dictionary = EnvironmentUpgradeDefs.UPGRADES[upgrade_id]
		if str(def.get("effect_key", "")) != effect_key:
			continue
		var lvl: int = get_env_upgrade_level(upgrade_id)
		mult += float(lvl) * float(def.get("effect_per_level", 0.0))
	return mult


func get_network_balance() -> float:
	return _network_balance


func set_network_balance(value: float) -> void:
	_network_balance = GameValueBounds.money(value)


func get_block_stock(type_id: String) -> int:
	return int(_block_stock.get(type_id, 0))


func set_block_stock(type_id: String, count: int) -> void:
	_block_stock[type_id] = GameValueBounds.count(count)


func add_block_stock(type_id: String, delta: int = 1) -> void:
	_block_stock[type_id] = GameValueBounds.count(get_block_stock(type_id) + delta)


func get_placed_blocks() -> Array[BlockInstance]:
	return _placed_blocks


func get_wire_connections() -> Array[WireLink]:
	return _wire_connections


func get_phase() -> Phase:
	return _phase


func set_phase(value: Phase) -> void:
	_phase = value


func get_uploaded_files() -> int:
	return _uploaded_files


func add_uploaded_files(delta: int = 1) -> void:
	_uploaded_files = GameValueBounds.count(_uploaded_files + delta)


func get_download_queue() -> Array[FileTransferJob]:
	return _download_queue


func get_stored_files() -> Array[StoredFileEntry]:
	return _stored_files


func get_upload_queue() -> Array[FileTransferJob]:
	return _upload_queue


func next_uid() -> String:
	_uid_counter += 1
	return "blk_%d" % _uid_counter


func get_uid_counter() -> int:
	return _uid_counter


func set_uid_counter(value: int) -> void:
	_uid_counter = maxi(0, value)


func export_save_dict() -> Dictionary:
	# Сериализация всего состояния для SaveBackend
	var unlocked: Array[String] = []
	for type_id: Variant in _unlocked_module_types.keys():
		unlocked.append(str(type_id))
	var placed: Array = []
	for inst: BlockInstance in _placed_blocks:
		placed.append(inst.to_dict())
	var wires: Array = []
	for link: WireLink in _wire_connections:
		wires.append(link.to_dict())
	var downloads: Array = []
	for job: FileTransferJob in _download_queue:
		downloads.append(job.to_dict())
	var stored: Array = []
	for entry: StoredFileEntry in _stored_files:
		stored.append(entry.to_dict())
	var uploads: Array = []
	for job: FileTransferJob in _upload_queue:
		uploads.append(job.to_dict())
	return {
		"format_version": _SaveConstants.FORMAT_VERSION,
		"money": _money,
		"network_balance": _network_balance,
		"env_upgrade_levels": _env_upgrade_levels.duplicate(),
		"unlocked_module_types": unlocked,
		"block_stock": _block_stock.duplicate(),
		"placed_blocks": placed,
		"wire_connections": wires,
		"phase": int(_phase),
		"uploaded_files": _uploaded_files,
		"uid_counter": _uid_counter,
		"download_queue": downloads,
		"stored_files": stored,
		"upload_queue": uploads,
	}


func import_save_dict(payload: Dictionary) -> void:
	var migrated := _migrate_save_payload(payload)
	set_money(float(migrated.get("money", _money)))
	set_network_balance(
		float(migrated.get("network_balance", migrated.get("uploader_balance", _network_balance)))
	)
	_env_upgrade_levels = {}
	var env_raw: Variant = migrated.get("env_upgrade_levels", {})
	if env_raw is Dictionary:
		for upgrade_id: Variant in (env_raw as Dictionary).keys():
			set_env_upgrade_level(
				str(upgrade_id),
				GameValueBounds.env_level(int((env_raw as Dictionary)[upgrade_id])),
			)
	_unlocked_module_types = {}
	for type_id: Variant in migrated.get("unlocked_module_types", []):
		_unlocked_module_types[str(type_id)] = true
	_block_stock = {}
	var stock_raw: Variant = migrated.get("block_stock", {})
	if stock_raw is Dictionary:
		for type_id: Variant in (stock_raw as Dictionary).keys():
			set_block_stock(str(type_id), int((stock_raw as Dictionary)[type_id]))
	_placed_blocks.clear()
	for item: Variant in migrated.get("placed_blocks", []):
		if item is Dictionary:
			_placed_blocks.append(BlockInstance.from_dict(item as Dictionary))
	_wire_connections.clear()
	for item: Variant in migrated.get("wire_connections", []):
		if item is Dictionary:
			_wire_connections.append(WireLink.from_dict(item as Dictionary))
	_phase = int(migrated.get("phase", Phase.IDLE)) as Phase
	_uploaded_files = GameValueBounds.count(int(migrated.get("uploaded_files", 0)))
	set_uid_counter(int(migrated.get("uid_counter", 0)))
	_download_queue.clear()
	for item: Variant in migrated.get("download_queue", []):
		if item is Dictionary:
			_download_queue.append(FileTransferJob.from_dict(item as Dictionary))
	_stored_files.clear()
	for item: Variant in migrated.get("stored_files", []):
		if item is Dictionary:
			_stored_files.append(StoredFileEntry.from_dict(item as Dictionary))
	_upload_queue.clear()
	for item: Variant in migrated.get("upload_queue", []):
		if item is Dictionary:
			_upload_queue.append(FileTransferJob.from_dict(item as Dictionary))


## Миграция сохранений v1 (downloader/uploader) → v2 (network).
static func _migrate_save_payload(payload: Dictionary) -> Dictionary:
	var version: int = int(payload.get("format_version", 0))
	if version >= SaveConstants.FORMAT_VERSION:
		return payload
	var out: Dictionary = payload.duplicate(true)
	if version >= 1:
		_migrate_v1_modules_to_network(out)
	out["format_version"] = SaveConstants.FORMAT_VERSION
	return out


static func _migrate_v1_modules_to_network(payload: Dictionary) -> void:
	if payload.has("uploader_balance") and not payload.has("network_balance"):
		payload["network_balance"] = payload["uploader_balance"]

	var stock: Dictionary = {}
	var stock_raw: Variant = payload.get("block_stock", {})
	if stock_raw is Dictionary:
		stock = (stock_raw as Dictionary).duplicate()
	var network_stock := int(stock.get("network", 0))
	network_stock += int(stock.get("downloader", 0)) + int(stock.get("uploader", 0))
	stock.erase("downloader")
	stock.erase("uploader")
	if network_stock > 0:
		stock["network"] = network_stock
	payload["block_stock"] = stock

	var unlocked: Array = []
	var unlocked_raw: Variant = payload.get("unlocked_module_types", [])
	var had_legacy := false
	if unlocked_raw is Array:
		for type_id: Variant in unlocked_raw:
			var tid := str(type_id)
			if tid == "downloader" or tid == "uploader":
				had_legacy = true
			elif tid != "network":
				unlocked.append(tid)
	if had_legacy and "network" not in unlocked:
		unlocked.append("network")
	payload["unlocked_module_types"] = unlocked

	var placed_raw: Array = []
	var placed_src: Variant = payload.get("placed_blocks", [])
	if placed_src is Array:
		placed_raw = placed_src as Array

	var uploader_to_network: Dictionary = {}
	var fallback_network_uid := ""
	for item: Variant in placed_raw:
		if not item is Dictionary:
			continue
		var block: Dictionary = item as Dictionary
		var type_id := str(block.get("type_id", block.get("type", "")))
		if type_id == "downloader":
			fallback_network_uid = str(block.get("uid", ""))

	var uploader_removed := 0
	var migrated_placed: Array = []
	for item: Variant in placed_raw:
		if not item is Dictionary:
			continue
		var block: Dictionary = (item as Dictionary).duplicate(true)
		var type_id := str(block.get("type_id", block.get("type", "")))
		if type_id == "downloader":
			block["type_id"] = "network"
			if block.has("type"):
				block["type"] = "network"
			fallback_network_uid = str(block.get("uid", ""))
			migrated_placed.append(block)
		elif type_id == "uploader":
			uploader_removed += 1
			var up_uid := str(block.get("uid", ""))
			if fallback_network_uid != "":
				uploader_to_network[up_uid] = fallback_network_uid
			else:
				block["type_id"] = "network"
				if block.has("type"):
					block["type"] = "network"
				fallback_network_uid = str(block.get("uid", ""))
				migrated_placed.append(block)
		else:
			migrated_placed.append(block)
	payload["placed_blocks"] = migrated_placed

	if uploader_removed > 0 and fallback_network_uid != "":
		stock["network"] = int(stock.get("network", 0)) + uploader_removed
		payload["block_stock"] = stock

	var wires_raw: Array = []
	var wires_src: Variant = payload.get("wire_connections", [])
	if wires_src is Array:
		wires_raw = wires_src as Array
	var migrated_wires: Array = []
	for item: Variant in wires_raw:
		if not item is Dictionary:
			continue
		var link: Dictionary = (item as Dictionary).duplicate(true)
		var from_uid := str(link.get("from_uid", ""))
		var to_uid := str(link.get("to_uid", ""))
		if uploader_to_network.has(from_uid):
			link["from_uid"] = uploader_to_network[from_uid]
		if uploader_to_network.has(to_uid):
			link["to_uid"] = uploader_to_network[to_uid]
		migrated_wires.append(link)
	payload["wire_connections"] = migrated_wires
