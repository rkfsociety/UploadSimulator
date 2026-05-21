extends RefCounted
class_name GameStateData
## Инкапсулированное состояние игры (без публичных полей).

enum Phase { IDLE, RECORDING, UPLOADING, PUBLISHED }

var _money: float = float(BlockDefs.starter_kit_cost())
var _uploader_balance: float = 0.0
var _subscribers: int = 0
var _total_views: int = 0
var _energy: float = GameConstants.START_ENERGY
var _max_energy: float = GameConstants.START_ENERGY

var _block_stock: Dictionary = {}
var _recording_studio_uid: String = ""
var _placed_blocks: Array[BlockInstance] = []
var _wire_connections: Array[WireLink] = []

var _phase: Phase = Phase.IDLE
var _phase_progress: float = 0.0
var _phase_duration: float = 1.0
var _recorded_files: int = 0
var _published_files: int = 0
var _download_queue: Array[FileTransferJob] = []
var _stored_files: Array[StoredFileEntry] = []
var _upload_queue: Array[FileTransferJob] = []

var _uid_counter: int = 0


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


func get_subscribers() -> int:
	return _subscribers


func get_total_views() -> int:
	return _total_views


func get_energy() -> float:
	return _energy


func set_energy(value: float) -> void:
	_energy = value


func get_max_energy() -> float:
	return _max_energy


func get_block_stock(type_id: String) -> int:
	return int(_block_stock.get(type_id, 0))


func set_block_stock(type_id: String, count: int) -> void:
	_block_stock[type_id] = count


func add_block_stock(type_id: String, delta: int = 1) -> void:
	_block_stock[type_id] = get_block_stock(type_id) + delta


func get_recording_studio_uid() -> String:
	return _recording_studio_uid


func set_recording_studio_uid(uid: String) -> void:
	_recording_studio_uid = uid


func get_placed_blocks() -> Array[BlockInstance]:
	return _placed_blocks


func get_wire_connections() -> Array[WireLink]:
	return _wire_connections


func get_phase() -> Phase:
	return _phase


func set_phase(value: Phase) -> void:
	_phase = value


func get_phase_progress() -> float:
	return _phase_progress


func set_phase_progress(value: float) -> void:
	_phase_progress = value


func get_phase_duration() -> float:
	return _phase_duration


func set_phase_duration(value: float) -> void:
	_phase_duration = value


func get_recorded_files() -> int:
	return _recorded_files


func set_recorded_files(value: int) -> void:
	_recorded_files = value


func add_recorded_files(delta: int = 1) -> void:
	_recorded_files += delta


func get_published_files() -> int:
	return _published_files


func add_published_files(delta: int = 1) -> void:
	_published_files += delta


func get_download_queue() -> Array[FileTransferJob]:
	return _download_queue


func get_stored_files() -> Array[StoredFileEntry]:
	return _stored_files


func get_upload_queue() -> Array[FileTransferJob]:
	return _upload_queue


func next_uid() -> String:
	_uid_counter += 1
	return "blk_%d" % _uid_counter
