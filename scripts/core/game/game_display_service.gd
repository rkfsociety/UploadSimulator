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
		"network":
			var dl := ByteFormat.format_speed_bps(_pipeline.download_speed_for(uid))
			var ul := ByteFormat.format_speed_bps(_pipeline.upload_speed_for(uid))
			return "↓ %s  ↑ %s" % [dl, ul]
		"storage":
			return "Вместимость: %d файл." % int(_storage.storage_capacity_for(uid))
		"collector":
			return (
				"Бонус к сбору: +%.0f%%"
				% (GameBonus.effect_at_level("collector", lvl) * 100.0)
			)
	return ""


## Uid модулей, у которых меняется прогресс/статус во время активных очередей.
## Скачивание и выгрузка идут одновременно — обновляем сеть и хранилище.
func get_progress_block_uids() -> Array[String]:
	var out: Array[String] = []
	var chain_file := _wiring.get_file_chain()
	var net_uid: String = str(chain_file.get("network", ""))
	if not _data.get_download_queue().is_empty() and net_uid != "":
		out.append(net_uid)
		for inst: BlockInstance in _data.get_placed_blocks():
			if inst.type_id == "storage":
				out.append(inst.uid)
	if not _data.get_upload_queue().is_empty():
		if net_uid != "" and net_uid not in out:
			out.append(net_uid)
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
		"storage":
			_fill_storage_display(empty)
		"collector":
			_fill_collector_display(empty, uid, chain_money)
	return empty


## UI сети: скачивает и выгружает автоматически — только статус и прогресс.
func _fill_network_display(target: Dictionary, uid: String, chain_file: Dictionary) -> void:
	target["action_visible"] = false
	target["action_enabled"] = false
	var dl_queue := _data.get_download_queue()
	var up_queue := _data.get_upload_queue()
	var in_chain: bool = chain_file.get("network", "") == uid
	if not dl_queue.is_empty() and in_chain:
		var job: FileTransferJob = dl_queue[0]
		target["status"] = (
			"Качает: %s · %d%%"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0)]
		)
		target["progress"] = job.progress
		return
	if not up_queue.is_empty() and in_chain:
		var job: FileTransferJob = up_queue[0]
		target["status"] = (
			"Грузит: %s · %d%%"
			% [FileDefs.get_type_label(job.file_type_id), int(job.progress * 100.0)]
		)
		target["progress"] = job.progress
		return
	if _pipeline.can_download_at(uid) and _pipeline.can_upload_at(uid):
		target["status"] = "Скачивает и выгружает автоматически"
		return
	if _pipeline.can_download_at(uid):
		target["status"] = "Качает автоматически из интернета"
		return
	if _pipeline.can_upload_at(uid):
		target["status"] = "Выгружает автоматически в сеть"
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
	var safe := _data.get_network_balance()
	if safe >= GameConstants.MIN_COLLECT_BALANCE and not _wiring.get_money_chain().is_empty():
		target["status"] = "В сейфе $%.0f → коллектор" % safe
	else:
		target["status"] = _network_idle_hint(chain_file)


func _network_idle_hint(chain_file: Dictionary) -> String:
	if chain_file.is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_CHAIN).get_message()
	var check := _pipeline.check_enqueue_download()
	if not check.is_ok():
		return check.get_message()
	check = _pipeline.check_enqueue_upload()
	if not check.is_ok():
		return check.get_message()
	return "Сеть свободна"


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


## UI коллектора: собирает доход автоматически, ручной кнопки нет — только статус.
func _fill_collector_display(target: Dictionary, uid: String, chain_money: Dictionary) -> void:
	target["action_visible"] = false
	target["action_enabled"] = false
	if chain_money.is_empty():
		target["status"] = GameOperationResult.fail(
			GameOperationResult.Code.PIPELINE_NO_MONEY_CHAIN
		).get_message()
		return
	var safe := _data.get_network_balance()
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
