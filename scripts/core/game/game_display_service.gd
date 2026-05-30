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
		"downloader":
			return (
				"Качество: +%.0f%%"
				% (GameBonus.effect_at_level("downloader", lvl) * 100.0)
			)
		"storage":
			return "Вместимость: %d файл." % int(_storage.storage_capacity_for(uid))
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
		for inst: BlockInstance in _data.get_placed_blocks():
			if inst.type_id == "storage":
				out.append(inst.uid)
	if not _data.get_upload_queue().is_empty():
		for key in ["network", "uploader"]:
			var uid: String = str(chain_file.get(key, ""))
			if uid != "" and uid not in out:
				out.append(uid)
		for inst: BlockInstance in _data.get_placed_blocks():
			if inst.type_id == "storage" and inst.uid not in out:
				out.append(inst.uid)
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
		"downloader":
			_fill_downloader_display(empty, uid, chain_file)
		"storage":
			_fill_storage_display(empty)
		"uploader":
			_fill_uploader_display(empty, uid, chain_file)
		"collector":
			_fill_collector_display(empty, uid, chain_money)
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
		target["status"] = "Канал подключён к загрузчику и аплоудеру"
		return
	target["status"] = "Подключите net_out → загрузчик и аплоудер → net_in"


func _fill_downloader_display(target: Dictionary, uid: String, chain_file: Dictionary) -> void:
	target["action_visible"] = false
	target["action_enabled"] = false
	var queue := _data.get_download_queue()
	if not queue.is_empty() and chain_file.get("downloader", "") == uid:
		var job: FileTransferJob = queue[0]
		target["status"] = (
			"Качает: %s · %d%%"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0)]
		)
		target["progress"] = job.progress
	elif _pipeline.can_download_at(uid):
		target["status"] = "Качает автоматически из сети"
	else:
		target["status"] = _downloader_idle_hint(chain_file)


func _downloader_idle_hint(chain_file: Dictionary) -> String:
	if chain_file.is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_CHAIN).get_message()
	var check := _pipeline.check_enqueue_download()
	if not check.is_ok():
		return check.get_message()
	return "Скачивание недоступно"


func _fill_storage_display(target: Dictionary) -> void:
	var cap := int(_storage.get_storage_capacity_files())
	target["status"] = "Занято: %d / %d файл." % [_storage.get_storage_used_files(), cap]
	var dl_queue := _data.get_download_queue()
	if not dl_queue.is_empty():
		var job: FileTransferJob = dl_queue[0]
		target["status"] = (
			"Принимает: %s · %d%%"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0)]
		)
		target["progress"] = job.progress


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
	if not _data.get_stored_files().is_empty():
		var next: StoredFileEntry = _data.get_stored_files()[0]
		target["status"] = "На диске: %s" % FileDefs.get_type_label(next.file_type_id)
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
