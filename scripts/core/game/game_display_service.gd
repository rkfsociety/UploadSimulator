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
		"network":
			var dl := ByteFormat.format_speed_bps(_pipeline.network_download_speed(uid))
			var ul := ByteFormat.format_speed_bps(_pipeline.network_upload_speed(uid))
			return "↓ %s  ↑ %s" % [dl, ul]
		_:
			if BlockDefs.is_downloader_type(inst.type_id):
				var cap := _storage.max_files_for(uid)
				var used := _storage.get_downloader_used_files(uid, _wiring.get_file_chain())
				return "Файлы: %d / %d" % [used, cap]
			match inst.type_id:
				"uploader":
					return (
						"Скорость ↑: %s"
						% ByteFormat.format_speed_bps(_pipeline.upload_speed_for(uid))
					)
				"collector":
					return (
						"Бонус к сбору: +%.0f%%"
						% (GameBonus.effect_at_level("collector", lvl) * 100.0)
					)
	return ""


func get_progress_block_uids() -> Array[String]:
	var out: Array[String] = []
	var chain_file := _wiring.get_file_chain()
	if not _data.get_download_queue().is_empty():
		for key in ["network", "downloader"]:
			var uid: String = str(chain_file.get(key, ""))
			if uid != "" and uid not in out:
				out.append(uid)
	if not _data.get_upload_queue().is_empty():
		for key in ["network", "downloader", "uploader"]:
			var uid: String = str(chain_file.get(key, ""))
			if uid != "" and uid not in out:
				out.append(uid)
	return out


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
		"network":
			_fill_network_display(empty, uid, chain_file)
		"uploader":
			_fill_uploader_display(empty, uid, chain_file)
		"collector":
			_fill_collector_display(empty, uid, chain_money)
		_:
			if BlockDefs.is_downloader_type(inst.type_id):
				_fill_downloader_display(empty, uid, chain_file)
	return empty


func _fill_network_display(target: Dictionary, uid: String, chain_file: Dictionary) -> void:
	target["action_visible"] = false
	target["action_enabled"] = false
	var in_chain: bool = chain_file.get("network", "") == uid
	if not _data.get_download_queue().is_empty() and in_chain:
		target["status"] = "Канал: скачивание"
		return
	if not _data.get_upload_queue().is_empty() and in_chain:
		target["status"] = "Канал: выгрузка"
		return
	if in_chain:
		target["status"] = "Канал готов"
		return
	target["status"] = "Подключите загрузчик и аплоудер"


func _fill_downloader_display(target: Dictionary, uid: String, chain_file: Dictionary) -> void:
	target["action_visible"] = false
	target["action_enabled"] = false
	var cap := _storage.max_files_for(uid)
	var used := _storage.get_downloader_used_files(uid, chain_file)
	var queue := _data.get_download_queue()
	if not queue.is_empty() and chain_file.get("downloader", "") == uid:
		var job: FileTransferJob = queue[0]
		target["status"] = (
			"Качает: %s · %d%% · %d/%d"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0), used, cap]
		)
		target["progress"] = job.progress
	elif _pipeline.can_download_at(uid):
		var ft := FileDefs.get_type_label(BlockDefs.get_downloader_file_type(_field.get_instance_type(uid)))
		target["status"] = "Качает %s · %d/%d" % [ft, used, cap]
	else:
		target["status"] = _downloader_idle_hint(chain_file, uid, used, cap)


func _downloader_idle_hint(chain_file: Dictionary, uid: String, used: int, cap: int) -> String:
	if chain_file.is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_CHAIN).get_message()
	if used >= cap:
		return "Переполнен: %d / %d файлов" % [used, cap]
	var check := _pipeline.check_enqueue_download()
	if not check.is_ok():
		return check.get_message()
	return "Скачивание недоступно"


func _fill_uploader_display(target: Dictionary, uid: String, chain_file: Dictionary) -> void:
	target["action_visible"] = false
	target["action_enabled"] = false
	var queue := _data.get_upload_queue()
	if not queue.is_empty() and chain_file.get("uploader", "") == uid:
		var job: FileTransferJob = queue[0]
		target["status"] = (
			"Грузит: %s · %d%%"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0)]
		)
		target["progress"] = job.progress
		return
	if _pipeline.can_upload_at(uid):
		target["status"] = "Выгружает автоматически через сеть"
		return
	if chain_file.is_empty():
		target["status"] = GameOperationResult.fail(
			GameOperationResult.Code.PIPELINE_NO_CHAIN
		).get_message()
		return
	var dl_uid: String = str(chain_file.get("downloader", ""))
	if not _data.get_downloader_files(dl_uid).is_empty():
		var next: StoredFileEntry = _data.get_downloader_files(dl_uid)[0]
		target["status"] = "В загрузчике: %s" % FileDefs.get_type_label(next.file_type_id)
		return
	var safe := _data.get_uploader_balance()
	if safe >= GameConstants.MIN_COLLECT_BALANCE and not _wiring.get_money_chain().is_empty():
		target["status"] = "В сейфе $%.0f → коллектор" % safe
	else:
		target["status"] = "Сейф пуст"


func _fill_collector_display(target: Dictionary, uid: String, chain_money: Dictionary) -> void:
	target["action_visible"] = false
	target["action_enabled"] = false
	if chain_money.is_empty():
		target["status"] = GameOperationResult.fail(
			GameOperationResult.Code.PIPELINE_NO_MONEY_CHAIN
		).get_message()
		return
	var safe := _data.get_uploader_balance()
	if safe < GameConstants.MIN_COLLECT_BALANCE:
		target["status"] = "Собирает доход в кассу автоматически"
		return
	var inst := _field.get_instance(uid)
	var bonus: float = GameBonus.effect_at_level("collector", inst.level)
	var payout: float = safe * (1.0 + bonus)
	if bonus > 0.0:
		target["status"] = "Забирает $%.0f → касса (+%.0f%%)" % [payout, bonus * 100.0]
	else:
		target["status"] = "Забирает $%.0f → касса" % payout
