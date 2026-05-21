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


func get_block_metric(uid: String) -> String:
	var inst := _field.get_instance(uid)
	if not inst.is_valid():
		return ""
	var lvl: int = maxi(1, inst.level)
	match inst.type_id:
		"studio":
			return "%.1f с · запись" % _pipeline.studio_duration_for(uid)
		"downloader":
			return "%.1f МБ/с" % _pipeline.download_speed_for(uid)
		"storage":
			return "%.0f ГБ диск" % (_storage.storage_capacity_for(uid) / GameConstants.MB_PER_GB)
		"uploader":
			return "%.1f МБ/с" % _pipeline.upload_speed_for(uid)
		"collector":
			return "+%.0f%% к кассе" % (GameBonus.effect_at_level("collector", lvl) * 100.0)
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
		"studio":
			_fill_studio_display(empty, uid)
		"downloader":
			_fill_downloader_display(empty, uid, chain_file)
		"storage":
			_fill_storage_display(empty)
		"uploader":
			_fill_uploader_display(empty, uid, chain_file)
		"collector":
			_fill_collector_display(empty, uid, chain_money)
	return empty


func _fill_studio_display(target: Dictionary, uid: String) -> void:
	target["action_text"] = "Записать"
	target["action_visible"] = true
	target["action_enabled"] = _pipeline.can_record_at(uid)
	if _data.get_phase() == GameStateData.Phase.RECORDING and _data.get_recording_studio_uid() == uid:
		target["status"] = "Запись %d%%" % int(_data.get_phase_progress() * 100.0)
		target["progress"] = _data.get_phase_progress()
		target["action_enabled"] = false
	elif _data.get_recorded_files() > 0:
		target["status"] = "Готово: %d файл." % _data.get_recorded_files()
	else:
		target["status"] = "Энергия %.0f" % _data.get_energy()


func _fill_downloader_display(target: Dictionary, uid: String, chain_file: Dictionary) -> void:
	target["action_text"] = "На диск"
	target["action_visible"] = not chain_file.is_empty()
	target["action_enabled"] = _pipeline.can_download_at(uid)
	var queue := _data.get_download_queue()
	if not queue.is_empty() and chain_file.get("downloader", "") == uid:
		var job: FileTransferJob = queue[0]
		target["status"] = "Качает %d%%" % int(job.progress * 100.0)
		target["progress"] = job.progress
		target["action_enabled"] = false
	elif _data.get_recorded_files() > 0:
		target["status"] = "В очереди: %d" % _data.get_recorded_files()
	else:
		target["status"] = "Ждёт запись"


func _fill_storage_display(target: Dictionary) -> void:
	var used_pct := 0.0
	if _storage.get_storage_capacity_mb() > 0.0:
		used_pct = _storage.get_storage_used_mb() / _storage.get_storage_capacity_mb() * 100.0
	target["status"] = "Диск %.0f%% · %d файл." % [used_pct, _data.get_stored_files().size()]
	if not _data.get_download_queue().is_empty():
		target["status"] = "Принимает файл..."
		target["progress"] = _data.get_download_queue()[0].progress


func _fill_uploader_display(target: Dictionary, uid: String, chain_file: Dictionary) -> void:
	target["action_text"] = "В сеть"
	target["action_visible"] = not chain_file.is_empty()
	target["action_enabled"] = _pipeline.can_upload_at(uid)
	var queue := _data.get_upload_queue()
	if not queue.is_empty() and chain_file.get("uploader", "") == uid:
		var job: FileTransferJob = queue[0]
		target["status"] = "Грузит %d%%" % int(job.progress * 100.0)
		target["progress"] = job.progress
		target["action_enabled"] = false
	else:
		target["status"] = "Сейф $%.0f" % _data.get_uploader_balance()


func _fill_collector_display(target: Dictionary, uid: String, chain_money: Dictionary) -> void:
	target["action_text"] = "В кассу"
	target["action_visible"] = not chain_money.is_empty()
	target["action_enabled"] = _pipeline.can_collect_at(uid)
	var inst := _field.get_instance(uid)
	target["status"] = "Бонус +%.0f%%" % (
		GameBonus.effect_at_level("collector", inst.level) * 100.0
	)
