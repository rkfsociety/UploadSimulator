extends RefCounted
class_name GamePipelineService
## Очереди: скачивание из сети, выгрузка, сбор денег.

var _data: GameStateData
var _host: Node
var _field: GameFieldService
var _wiring: GameWiringService
var _storage: GameStorageService
var _rng := RandomNumberGenerator.new()


func _init(
	data: GameStateData,
	host: Node,
	field: GameFieldService,
	wiring: GameWiringService,
	storage: GameStorageService,
) -> void:
	_data = data
	_host = host
	_field = field
	_wiring = wiring
	_storage = storage
	_rng.randomize()


func tick(delta: float) -> void:
	_tick_download_queue(delta)
	_tick_upload_queue(delta)


func download_speed_for(uid: String) -> float:
	var inst := _field.get_instance(uid)
	return GameBonus.speed_scaled(GameConstants.BASE_DOWNLOAD_SPEED_BPS, inst.type_id, inst.level)


func upload_speed_for(uid: String) -> float:
	var inst := _field.get_instance(uid)
	return GameBonus.speed_scaled(GameConstants.BASE_UPLOAD_SPEED_BPS, inst.type_id, inst.level)


func can_download_at(uid: String) -> bool:
	var chain := _wiring.get_file_chain()
	return can_enqueue_download() and chain.get("downloader", "") == uid


func can_upload_at(uid: String) -> bool:
	var chain := _wiring.get_file_chain()
	return can_enqueue_upload() and chain.get("uploader", "") == uid


func can_collect_at(uid: String) -> bool:
	var chain := _wiring.get_money_chain()
	return can_collect_money() and chain.get("to_uid", "") == uid


func can_enqueue_download() -> bool:
	var chain := _wiring.get_file_chain()
	if _data.get_phase() != GameStateData.Phase.IDLE or chain.is_empty():
		return false
	if _data.get_download_queue().size() >= GameConstants.MAX_QUEUE_JOBS:
		return false
	return _storage.has_storage_space(GameConstants.MIN_DOWNLOAD_RESERVE_BYTES)


func can_enqueue_upload() -> bool:
	var chain := _wiring.get_file_chain()
	return (
		_data.get_phase() == GameStateData.Phase.IDLE
		and not chain.is_empty()
		and not _data.get_stored_files().is_empty()
		and _data.get_upload_queue().size() < GameConstants.MAX_QUEUE_JOBS
	)


func can_collect_money() -> bool:
	var chain := _wiring.get_money_chain()
	return (
		_data.get_phase() == GameStateData.Phase.IDLE
		and not chain.is_empty()
		and _data.get_uploader_balance() >= GameConstants.MIN_COLLECT_BALANCE
	)


## Переводит весь сейф аплоудера в общую кассу (нужен провод money_out → money_in).
func collect_money(collector_uid: String) -> bool:
	if collector_uid == "" or not can_collect_at(collector_uid):
		return false
	var chain := _wiring.get_money_chain()
	var uploader_uid: String = str(chain.get("from_uid", ""))
	var safe: float = _data.get_uploader_balance()
	var inst := _field.get_instance(collector_uid)
	var bonus: float = GameBonus.effect_at_level("collector", inst.level)
	var payout: float = safe * (1.0 + bonus)
	_data.set_uploader_balance(0.0)
	_data.add_money(payout)
	var uploader_name: String = BlockDefs.TYPES.get(_field.get_instance_type(uploader_uid), {}).get(
		"name", "Аплоудер"
	)
	_host.log_message.emit(
		"Коллектор: $%.0f из %s → касса (баланс $%.0f)" % [payout, uploader_name, _data.get_money()]
	)
	_notify_field_and_stats()
	return true


func run_block_action(uid: String) -> bool:
	match _field.get_instance_type(uid):
		"downloader":
			return enqueue_download()
		"uploader":
			return enqueue_upload()
		"collector":
			return collect_money(uid)
	return false


func enqueue_download() -> bool:
	if not can_enqueue_download():
		return false
	var chain := _wiring.get_file_chain()
	var dl_uid: String = chain.get("downloader", "")
	var file_type_id := FileDefs.DEFAULT_TYPE
	var dl_level := _field.get_instance_level(dl_uid)
	var quality := 1.0 + float(dl_level) * GameConstants.QUALITY_PER_DOWNLOADER_LEVEL
	var assets_bytes := _rng.randf_range(
		GameConstants.DOWNLOAD_ASSETS_BYTES_MIN, GameConstants.DOWNLOAD_ASSETS_BYTES_MAX
	)
	var payload_bytes := (
		_rng.randf_range(GameConstants.DOWNLOAD_PAYLOAD_BYTES_MIN, GameConstants.DOWNLOAD_PAYLOAD_BYTES_MAX)
		* quality
	)
	var total_bytes := assets_bytes + payload_bytes
	if not _storage.has_storage_space(total_bytes):
		_host.log_message.emit("Мало места на диске.")
		_host.stats_changed.emit()
		return false
	var job := FileTransferJob.new()
	job.file_type_id = file_type_id
	job.title = FileDefs.get_type_label(file_type_id)
	job.quality = quality
	job.size_bytes = total_bytes
	job.duration = total_bytes / download_speed_for(dl_uid)
	job.progress = 0.0
	_data.get_download_queue().append(job)
	_notify_queue_and_field()
	_host.log_message.emit("Скачивание из сети: %s..." % job.title)
	_host.stats_changed.emit()
	return true


func enqueue_upload() -> bool:
	if not can_enqueue_upload():
		return false
	var chain := _wiring.get_file_chain()
	var up_uid: String = chain.get("uploader", "")
	var entry: StoredFileEntry = _data.get_stored_files().pop_front()
	var job := FileTransferJob.new()
	job.quality = entry.quality
	job.size_bytes = entry.size_bytes
	job.duration = entry.size_bytes / upload_speed_for(up_uid)
	job.progress = 0.0
	job.file_type_id = entry.file_type_id
	job.title = entry.title
	_data.get_upload_queue().append(job)
	_notify_queue_and_field()
	_host.log_message.emit("Выгрузка: %s..." % FileDefs.get_type_label(job.file_type_id))
	_host.stats_changed.emit()
	return true


func get_phase_label() -> String:
	match _data.get_phase():
		GameStateData.Phase.SETTLING:
			return "Завершение выгрузки"
		_:
			if not _data.get_download_queue().is_empty():
				return "Скачивание"
			if not _data.get_upload_queue().is_empty():
				return "Выгрузка"
			return "Свободен"


func _tick_download_queue(delta: float) -> void:
	if _data.get_phase() != GameStateData.Phase.IDLE or _data.get_download_queue().is_empty():
		return
	var queue := _data.get_download_queue()
	var job: FileTransferJob = queue[0]
	job.progress += delta / maxf(job.duration, GameConstants.MIN_JOB_DURATION_SEC)
	queue[0] = job
	_host.queue_changed.emit()
	_host.field_changed.emit()
	if job.progress < 1.0:
		return
	queue.pop_front()
	var stored := StoredFileEntry.new()
	stored.title = job.title
	stored.file_type_id = job.file_type_id
	stored.quality = job.quality
	stored.size_bytes = job.size_bytes
	_data.get_stored_files().append(stored)
	_host.field_changed.emit()
	_host.stats_changed.emit()


func _tick_upload_queue(delta: float) -> void:
	if _data.get_phase() != GameStateData.Phase.IDLE or _data.get_upload_queue().is_empty():
		return
	var queue := _data.get_upload_queue()
	var job: FileTransferJob = queue[0]
	job.progress += delta / maxf(job.duration, GameConstants.MIN_JOB_DURATION_SEC)
	queue[0] = job
	_host.queue_changed.emit()
	_host.field_changed.emit()
	if job.progress < 1.0:
		return
	queue.pop_front()
	_host.field_changed.emit()
	if _host.has_method("run_publish_pause"):
		_host.run_publish_pause(job)


func apply_publish(job: FileTransferJob) -> void:
	_data.add_uploaded_files(1)
	var revenue := job.size_bytes * GameConstants.REVENUE_PER_BYTE * job.quality
	_data.set_uploader_balance(_data.get_uploader_balance() + revenue)
	_data.set_phase(GameStateData.Phase.SETTLING)
	_host.log_message.emit(
		"Выгружен %s: +$%.1f в аплоудер"
		% [FileDefs.get_type_label(job.file_type_id), revenue]
	)


func finish_publish_pause() -> void:
	_data.set_phase(GameStateData.Phase.IDLE)
	_notify_field_and_stats()


func _notify_field_and_stats() -> void:
	_host.field_changed.emit()
	_host.stats_changed.emit()


func _notify_queue_and_field() -> void:
	_host.queue_changed.emit()
	_host.field_changed.emit()
