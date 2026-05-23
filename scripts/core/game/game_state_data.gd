extends RefCounted
class_name GameStateData
## Инкапсулированное состояние игры (без публичных полей).

enum Phase { IDLE, SETTLING }

var _money: float = 0.0
var _uploader_balance: float = 0.0
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
	_diamonds = GameConstants.START_DIAMONDS
	# Касса при старте — сумма shop_cost базового набора (см. BlockDefs.starter_kit_types)
	_money = float(BlockDefs.starter_kit_cost())
	for type_id in BlockDefs.starter_kit_types():
		_unlocked_module_types[type_id] = true


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


func get_uploader_balance() -> float:
	return _uploader_balance


func set_uploader_balance(value: float) -> void:
	_uploader_balance = GameValueBounds.money(value)


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
		"format_version": SaveConstants.FORMAT_VERSION,
		"money": _money,
		"uploader_balance": _uploader_balance,
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
	# Восстановление состояния из снимка (вызывается GameSaveSnapshot)
	_money = float(payload.get("money", _money))
	_uploader_balance = float(payload.get("uploader_balance", _uploader_balance))
	_env_upgrade_levels = {}
	var env_raw: Variant = payload.get("env_upgrade_levels", {})
	if env_raw is Dictionary:
		_env_upgrade_levels = (env_raw as Dictionary).duplicate()
	_unlocked_module_types = {}
	for type_id: Variant in payload.get("unlocked_module_types", []):
		_unlocked_module_types[str(type_id)] = true
	_block_stock = {}
	var stock_raw: Variant = payload.get("block_stock", {})
	if stock_raw is Dictionary:
		_block_stock = (stock_raw as Dictionary).duplicate()
	_placed_blocks.clear()
	for item: Variant in payload.get("placed_blocks", []):
		if item is Dictionary:
			_placed_blocks.append(BlockInstance.from_dict(item as Dictionary))
	_wire_connections.clear()
	for item: Variant in payload.get("wire_connections", []):
		if item is Dictionary:
			_wire_connections.append(WireLink.from_dict(item as Dictionary))
	_phase = int(payload.get("phase", Phase.IDLE)) as Phase
	_uploaded_files = int(payload.get("uploaded_files", 0))
	set_uid_counter(int(payload.get("uid_counter", 0)))
	_download_queue.clear()
	for item: Variant in payload.get("download_queue", []):
		if item is Dictionary:
			_download_queue.append(FileTransferJob.from_dict(item as Dictionary))
	_stored_files.clear()
	for item: Variant in payload.get("stored_files", []):
		if item is Dictionary:
			_stored_files.append(StoredFileEntry.from_dict(item as Dictionary))
	_upload_queue.clear()
	for item: Variant in payload.get("upload_queue", []):
		if item is Dictionary:
			_upload_queue.append(FileTransferJob.from_dict(item as Dictionary))
