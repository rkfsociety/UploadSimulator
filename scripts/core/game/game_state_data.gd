extends RefCounted
class_name GameStateData
## Инкапсулированное состояние игры (без публичных полей).

enum Phase { IDLE, SETTLING }

var _money: float = 0.0
var _uploader_balance: float = 0.0

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
	# Касса при старте — сумма shop_cost базового набора (см. BlockDefs.starter_kit_types)
	_money = float(BlockDefs.starter_kit_cost())


func get_money() -> float:
	return _money


func set_money(value: float) -> void:
	_money = value


func add_money(amount: float) -> void:
	_money += amount


func try_spend_money(amount: float) -> bool:
	if _money < amount:
		return false
	_money -= amount
	return true


func get_uploader_balance() -> float:
	return _uploader_balance


func set_uploader_balance(value: float) -> void:
	_uploader_balance = value


func get_block_stock(type_id: String) -> int:
	return int(_block_stock.get(type_id, 0))


func set_block_stock(type_id: String, count: int) -> void:
	_block_stock[type_id] = count


func add_block_stock(type_id: String, delta: int = 1) -> void:
	_block_stock[type_id] = get_block_stock(type_id) + delta


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
	_uploaded_files += delta


func get_download_queue() -> Array[FileTransferJob]:
	return _download_queue


func get_stored_files() -> Array[StoredFileEntry]:
	return _stored_files


func get_upload_queue() -> Array[FileTransferJob]:
	return _upload_queue


func next_uid() -> String:
	_uid_counter += 1
	return "blk_%d" % _uid_counter
