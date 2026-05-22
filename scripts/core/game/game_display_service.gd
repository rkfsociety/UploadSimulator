extends RefCounted
class_name GameDisplayService
## Метрики и UI-состояние блоков на поле.

var _data: GameStateData
var _field: GameFieldService
var _wiring: GameWiringService
var _storage: GameStorageService
var _pipeline: GamePipelineService


func _init(
	data: GameStateData,
	field: GameFieldService,
	wiring: GameWiringService,
	storage: GameStorageService,
	pipeline: GamePipelineService,
) -> void:
	_data = data
	_field = field
	_wiring = wiring
	_storage = storage
	_pipeline = pipeline


func get_instance_status_line(uid: String) -> String:
	return str(get_block_display(uid).get("status", ""))


## Постоянные характеристики модуля (скорость, ёмкость и т.д.).
func get_block_metric(uid: String) -> String:
	var inst := _field.get_instance(uid)
	if not inst.is_valid():
		return ""
	var lvl: int = maxi(1, inst.level)
	match inst.type_id:
		"downloader":
			return (
				"Скорость: %s"
				% ByteFormat.format_speed_bps(_pipeline.download_speed_for(uid))
			)
		"storage":
			return "Ёмкость: %s" % ByteFormat.format_bytes(_storage.storage_capacity_for(uid))
		"uploader":
			return (
				"Скорость: %s" % ByteFormat.format_speed_bps(_pipeline.upload_speed_for(uid))
			)
		"collector":
			return (
				"Бонус к сбору: +%.0f%%"
				% (GameBonus.effect_at_level("collector", lvl) * 100.0)
			)
	return ""


func get_block_display(uid: String) -> Dictionary:
	var inst := _field.get_instance(uid)
	var empty := {
		"status": "",
		"action_text": "",
		"action_enabled": false,
		"action_visible": false,
		"progress": -1.0,
	}
	if not inst.is_valid():
		return empty
	var chain_file := _wiring.get_file_chain()
	var chain_money := _wiring.get_money_chain()
	match inst.type_id:
		"downloader":
			_fill_downloader_display(empty, uid, chain_file)
		"storage":
			_fill_storage_display(empty)
		"uploader":
			_fill_uploader_display(empty, uid, chain_file)
		"collector":
			_fill_collector_display(empty, uid, chain_money)
	return empty


func _fill_downloader_display(target: Dictionary, uid: String, chain_file: Dictionary) -> void:
	target["action_text"] = "Из сети"
	target["action_visible"] = not chain_file.is_empty()
	target["action_enabled"] = _pipeline.can_download_at(uid)
	var queue := _data.get_download_queue()
	if not queue.is_empty() and chain_file.get("downloader", "") == uid:
		var job: FileTransferJob = queue[0]
		target["status"] = (
			"Качает: %s · %d%%"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0)]
		)
		target["progress"] = job.progress
		target["action_enabled"] = false
	elif _pipeline.can_download_at(uid):
		target["status"] = "Готов: скачать %s из интернета" % FileDefs.get_type_label(
			FileDefs.DEFAULT_TYPE
		)
	else:
		target["status"] = _downloader_idle_hint(chain_file)


func _downloader_idle_hint(chain_file: Dictionary) -> String:
	if chain_file.is_empty():
		return "Соедини с хранилищем"
	if _data.get_download_queue().size() >= GameConstants.MAX_QUEUE_JOBS:
		return "Очередь скачивания заполнена"
	if not _storage.has_storage_space(GameConstants.MIN_DOWNLOAD_RESERVE_BYTES):
		return "Мало места на диске"
	if _data.get_phase() != GameStateData.Phase.IDLE:
		return _pipeline.get_phase_label()
	return "Скачивание недоступно"


func _fill_storage_display(target: Dictionary) -> void:
	var used_pct := 0.0
	if _storage.get_storage_capacity_bytes() > 0.0:
		used_pct = (
			_storage.get_storage_used_bytes() / _storage.get_storage_capacity_bytes() * 100.0
		)
	target["status"] = "Занято: %.0f%% · %d файл." % [used_pct, _data.get_stored_files().size()]
	var dl_queue := _data.get_download_queue()
	if not dl_queue.is_empty():
		var job: FileTransferJob = dl_queue[0]
		target["status"] = (
			"Принимает: %s · %d%%"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0)]
		)
		target["progress"] = job.progress


func _fill_uploader_display(target: Dictionary, uid: String, chain_file: Dictionary) -> void:
	target["action_text"] = "В сеть"
	target["action_visible"] = not chain_file.is_empty()
	target["action_enabled"] = _pipeline.can_upload_at(uid)
	var queue := _data.get_upload_queue()
	if not queue.is_empty() and chain_file.get("uploader", "") == uid:
		var job: FileTransferJob = queue[0]
		target["status"] = (
			"Грузит: %s · %d%%"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0)]
		)
		target["progress"] = job.progress
		target["action_enabled"] = false
	elif not _data.get_stored_files().is_empty():
		var next: StoredFileEntry = _data.get_stored_files()[0]
		target["status"] = "На диске: %s" % FileDefs.get_type_label(next.file_type_id)
	else:
		target["status"] = "Сейф: $%.0f" % _data.get_uploader_balance()


func _fill_collector_display(target: Dictionary, uid: String, chain_money: Dictionary) -> void:
	target["action_text"] = "В кассу"
	target["action_visible"] = not chain_money.is_empty()
	target["action_enabled"] = _pipeline.can_collect_at(uid)
	var balance := _data.get_uploader_balance()
	if balance >= GameConstants.MIN_COLLECT_BALANCE:
		target["status"] = "Можно собрать: $%.0f" % balance
	else:
		target["status"] = "В аплоудере: $%.0f" % balance
