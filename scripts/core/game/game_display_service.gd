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
				var used := _storage.get_module_used_files(uid, _wiring.get_download_chain())
				return "Файлы: %d / %d · %s" % [
					used,
					cap,
					FileDefs.get_type_label(BlockDefs.get_downloader_file_type(inst.type_id)),
				]
			match inst.type_id:
				"uploader":
					return "Сейф $%.0f · ↑ %s" % [
						_data.get_uploader_balance(),
						ByteFormat.format_speed_bps(_pipeline.upload_speed_for(uid)),
					]
				"collector":
					return (
						"Бонус к сбору: +%.0f%%"
						% (GameBonus.effect_at_level("collector", lvl) * 100.0)
					)
	return ""


func get_progress_block_uids() -> Array[String]:
	var out: Array[String] = []
	var dl_chain := _wiring.get_download_chain()
	var chain_file := _wiring.get_file_chain()
	if not _data.get_download_queue().is_empty():
		for key in ["network", "downloader"]:
			var uid: String = str(dl_chain.get(key, ""))
			if uid != "" and uid not in out:
				out.append(uid)
	var up_uid: String = str(chain_file.get("uploader", ""))
	var upload_transfer := _data.find_upload_wire_transfer(up_uid)
	if upload_transfer != null:
		for key in ["network", "uploader"]:
			var uid: String = str(chain_file.get(key, ""))
			if uid != "" and uid not in out:
				out.append(uid)
	elif not _data.get_upload_queue().is_empty():
		for key in ["network", "uploader"]:
			var uid: String = str(chain_file.get(key, ""))
			if uid != "" and uid not in out:
				out.append(uid)
	for transfer: WireFileTransfer in _data.get_wire_transfers():
		if transfer.purpose == WireFileTransfer.Purpose.TO_UPLOADER:
			for key in ["downloader", "uploader"]:
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
			_fill_network_display(empty, uid, chain_file, _wiring.get_download_chain())
		"uploader":
			_fill_uploader_display(empty, uid, chain_file)
		"collector":
			_fill_collector_display(empty, uid, chain_money)
		_:
			if BlockDefs.is_downloader_type(inst.type_id):
				_fill_downloader_display(empty, uid, chain_file, _wiring.get_download_chain())
	return empty


func _fill_network_display(
	target: Dictionary, uid: String, chain_file: Dictionary, dl_chain: Dictionary
) -> void:
	target["action_visible"] = false
	target["action_enabled"] = false
	var in_download: bool = dl_chain.get("network", "") == uid
	var in_upload: bool = chain_file.get("network", "") == uid
	if not _data.get_download_queue().is_empty() and in_download:
		target["status"] = "Канал: скачивание"
		return
	if not _data.get_upload_queue().is_empty() and in_upload:
		target["status"] = "Канал: выгрузка"
		return
	var up_uid: String = str(chain_file.get("uploader", ""))
	if _data.find_upload_wire_transfer(up_uid) != null and in_upload:
		target["status"] = "Канал: выгрузка"
		return
	if in_download or in_upload:
		target["status"] = "Канал готов"
		return
	target["status"] = "Подключите Text Downloader к сети"


func _fill_downloader_display(
	target: Dictionary, uid: String, chain_file: Dictionary, dl_chain: Dictionary
) -> void:
	target["action_visible"] = false
	target["action_enabled"] = false
	var cap := _storage.max_files_for(uid)
	var used := _storage.get_module_used_files(uid, dl_chain)
	var queue := _data.get_download_queue()
	if not queue.is_empty() and dl_chain.get("downloader", "") == uid:
		var job: FileTransferJob = queue[0]
		target["status"] = (
			"Качает: %s · %d%% · %d/%d"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0), used, cap]
		)
		target["progress"] = job.progress
		return
	for transfer: WireFileTransfer in _data.get_wire_transfers():
		if (
			transfer.purpose == WireFileTransfer.Purpose.TO_UPLOADER
			and transfer.from_uid == uid
		):
			target["status"] = (
				"В сеть: %s · %d%% · %d/%d"
				% [FileDefs.get_type_label(transfer.file_type_id), int(transfer.progress * 100.0), used, cap]
			)
			target["progress"] = transfer.progress
			return
	if _pipeline.can_download_at(uid):
		var ft := FileDefs.get_type_label(BlockDefs.get_downloader_file_type(_field.get_instance_type(uid)))
		target["status"] = "Качает %s · %d/%d" % [ft, used, cap]
	elif not _data.get_module_files(uid).is_empty():
		target["status"] = "Хранит %d/%d · ждёт выгрузку" % [used, cap]
	else:
		target["status"] = _downloader_idle_hint(dl_chain)


func _downloader_idle_hint(dl_chain: Dictionary) -> String:
	if dl_chain.is_empty():
		return "Подключите к сети (net_out → net_in)"
	var check := _pipeline.check_enqueue_download()
	if not check.is_ok():
		return check.get_message()
	return "Скачивание недоступно"


func _fill_uploader_display(target: Dictionary, uid: String, chain_file: Dictionary) -> void:
	target["action_visible"] = false
	target["action_enabled"] = false
	var safe := _data.get_uploader_balance()
	var upload_transfer := _data.find_upload_wire_transfer(uid)
	if upload_transfer != null and chain_file.get("uploader", "") == uid:
		target["status"] = (
			"Грузит в сеть: %s · %d%% · сейф $%.0f"
			% [
				FileDefs.get_type_label(upload_transfer.file_type_id),
				int(upload_transfer.progress * 100.0),
				safe,
			]
		)
		target["progress"] = upload_transfer.progress
		return
	for transfer: WireFileTransfer in _data.get_wire_transfers():
		if (
			transfer.purpose == WireFileTransfer.Purpose.TO_UPLOADER
			and transfer.to_uid == uid
		):
			target["status"] = (
				"Принимает %s · %d%% · сейф $%.0f"
				% [FileDefs.get_type_label(transfer.file_type_id), int(transfer.progress * 100.0), safe]
			)
			target["progress"] = transfer.progress
			return
	var queue := _data.get_upload_queue()
	if not queue.is_empty() and chain_file.get("uploader", "") == uid:
		var job: FileTransferJob = queue[0]
		target["status"] = (
			"Грузит в сеть: %s · %d%% · сейф $%.0f"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0), safe]
		)
		target["progress"] = job.progress
		return
	if _pipeline.can_upload_at(uid):
		target["status"] = "Выгружает в сеть · сейф $%.0f" % safe
		return
	if chain_file.is_empty():
		target["status"] = GameOperationResult.fail(
			GameOperationResult.Code.PIPELINE_NO_CHAIN
		).get_message()
		return
	if safe >= GameConstants.MIN_COLLECT_BALANCE and not _wiring.get_money_chain().is_empty():
		target["status"] = "Сейф $%.0f → коллектор" % safe
	else:
		target["status"] = "Ждёт файлы от Text Downloader · сейф $%.0f" % safe


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
		target["status"] = "Переводит деньги загрузчика в кассу автоматически"
		return
	var inst := _field.get_instance(uid)
	var bonus: float = GameBonus.effect_at_level("collector", inst.level)
	var payout: float = safe * (1.0 + bonus)
	if bonus > 0.0:
		target["status"] = "Забирает $%.0f → касса (+%.0f%%)" % [payout, bonus * 100.0]
	else:
		target["status"] = "Забирает $%.0f → касса" % payout
