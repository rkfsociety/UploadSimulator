extends RefCounted
class_name GamePipelineService
## Очереди: скачивание из сети, выгрузка, сбор денег.

var _data: GameStateData
var _host: Node
var _field: GameFieldService
var _wiring: GameWiringService
var _storage: GameStorageService
var _premium: PremiumCurrencyService
var _rng := RandomNumberGenerator.new()


func _init(
	data: GameStateData,
	host: Node,
	field: GameFieldService,
	wiring: GameWiringService,
	storage: GameStorageService,
	premium: PremiumCurrencyService,
) -> void:
	_data = data
	_host = host
	_field = field
	_wiring = wiring
	_storage = storage
	_premium = premium
	_rng.randomize()


func tick(delta: float) -> void:
	_auto_enqueue_download()
	_auto_enqueue_upload()
	_tick_download_queue(delta)
	_tick_upload_queue(delta)
	_auto_collect_money()


func _auto_enqueue_download() -> void:
	if not _data.get_download_queue().is_empty():
		return
	if not can_enqueue_download():
		return
	enqueue_download()


func _auto_enqueue_upload() -> void:
	if not _data.get_upload_queue().is_empty():
		return
	if not can_enqueue_upload():
		return
	enqueue_upload()


func _auto_collect_money() -> void:
	var chain := _wiring.get_money_chain()
	var collector_uid := str(chain.get("to_uid", ""))
	if collector_uid == "":
		return
	if not can_collect_money():
		return
	collect_money(collector_uid)


## Скорость скачивания — только от уровня модуля «Сеть» в цепочке.
func download_speed_for(_uid: String) -> float:
	return _network_transfer_speed(true)


## Скорость выгрузки — только от уровня модуля «Сеть» в цепочке.
func upload_speed_for(_uid: String) -> float:
	return _network_transfer_speed(false)


func network_download_speed(network_uid: String) -> float:
	return _speed_for_network_uid(network_uid, true)


func network_upload_speed(network_uid: String) -> float:
	return _speed_for_network_uid(network_uid, false)


func can_download_at(uid: String) -> bool:
	return check_download_at(uid).is_ok()


func can_upload_at(uid: String) -> bool:
	return check_upload_at(uid).is_ok()


func can_collect_at(uid: String) -> bool:
	return check_collect_at(uid).is_ok()


func can_enqueue_download() -> bool:
	return check_enqueue_download().is_ok()


func can_enqueue_upload() -> bool:
	return check_enqueue_upload().is_ok()


func can_collect_money() -> bool:
	return check_collect_money().is_ok()


func check_download_at(uid: String) -> GameOperationResult:
	var chain := _wiring.get_file_chain()
	if chain.get("downloader", "") != uid:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_WRONG_MODULE)
	return check_enqueue_download()


func check_upload_at(uid: String) -> GameOperationResult:
	var chain := _wiring.get_file_chain()
	if chain.get("uploader", "") != uid:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_WRONG_MODULE)
	return check_enqueue_upload()


func check_collect_at(uid: String) -> GameOperationResult:
	var chain := _wiring.get_money_chain()
	if chain.get("to_uid", "") != uid:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_WRONG_MODULE)
	return check_collect_money()


func check_enqueue_download() -> GameOperationResult:
	var chain := _wiring.get_file_chain()
	if chain.is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_CHAIN)
	if _data.get_download_queue().size() >= GameConstants.MAX_QUEUE_JOBS:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_DOWNLOAD_QUEUE_FULL)
	var up_uid: String = str(chain.get("uploader", ""))
	if not _storage.has_module_space(up_uid, 1):
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_STORAGE)
	return GameOperationResult.ok()


func check_enqueue_upload() -> GameOperationResult:
	if _data.get_phase() != GameStateData.Phase.IDLE:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_PHASE_BUSY)
	var chain := _wiring.get_file_chain()
	if chain.is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_CHAIN)
	var up_uid: String = str(chain.get("uploader", ""))
	if _data.get_module_files(up_uid).is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_FILES)
	if _data.get_upload_queue().size() >= GameConstants.MAX_QUEUE_JOBS:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_UPLOAD_QUEUE_FULL)
	return GameOperationResult.ok()


func check_collect_money() -> GameOperationResult:
	if _data.get_phase() != GameStateData.Phase.IDLE:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_PHASE_BUSY)
	if _wiring.get_money_chain().is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_MONEY_CHAIN)
	if _data.get_uploader_balance() < GameConstants.MIN_COLLECT_BALANCE:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_SAFE_EMPTY)
	return GameOperationResult.ok()


func collect_money(collector_uid: String) -> GameOperationResult:
	var check := check_collect_at(collector_uid)
	if not check.is_ok():
		return check
	var chain := _wiring.get_money_chain()
	var uploader_uid: String = str(chain.get("from_uid", ""))
	var safe: float = _data.get_uploader_balance()
	var inst := _field.get_instance(collector_uid)
	var bonus: float = GameBonus.effect_at_level("collector", inst.level)
	var payout: float = safe * (1.0 + bonus)
	_data.set_uploader_balance(0.0)
	_data.add_money(payout)
	var uploader_name: String = BlockDefs.TYPES.get(_field.get_instance_type(uploader_uid), {}).get(
		"name", "Загрузчик"
	)
	_host.log_message.emit(
		"Коллектор: $%.0f из %s → касса (баланс $%.0f)" % [payout, uploader_name, _data.get_money()]
	)
	_notify_field_and_stats()
	return GameOperationResult.ok()


func run_block_action(uid: String) -> GameOperationResult:
	var type_id := _field.get_instance_type(uid)
	if BlockDefs.is_downloader_type(type_id):
		return enqueue_download()
	match type_id:
		"uploader":
			return enqueue_upload()
		"collector":
			return collect_money(uid)
	return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_WRONG_MODULE)


func enqueue_download() -> GameOperationResult:
	var check := check_enqueue_download()
	if not check.is_ok():
		return check
	var chain := _wiring.get_file_chain()
	var dl_uid: String = chain.get("downloader", "")
	var dl_type := _field.get_instance_type(dl_uid)
	var file_type_id := BlockDefs.get_downloader_file_type(dl_type)
	if file_type_id == "" or not FileDefs.is_downloadable_type(file_type_id):
		return GameOperationResult.fail(GameOperationResult.Code.FILE_TYPE_UNSUPPORTED)
	var speed_bps := download_speed_for(dl_uid)
	var total_bytes := FileDefs.random_download_size_bytes(file_type_id, speed_bps, _rng)
	var job := FileTransferJob.new()
	job.file_type_id = file_type_id
	job.title = FileDefs.get_type_label(file_type_id)
	job.quality = 1.0
	job.size_bytes = GameValueBounds.size_bytes(total_bytes)
	job.duration = GameValueBounds.job_duration_from_bytes(job.size_bytes, speed_bps)
	job.progress = 0.0
	job.apply_bounds()
	_data.get_download_queue().append(job)
	_notify_queue_and_field()
	_host.log_message.emit("Скачивание из сети: %s..." % job.title)
	_host.stats_changed.emit()
	return GameOperationResult.ok()


func enqueue_upload() -> GameOperationResult:
	var check := check_enqueue_upload()
	if not check.is_ok():
		return check
	var chain := _wiring.get_file_chain()
	var up_uid: String = str(chain.get("uploader", ""))
	var files := _data.get_module_files(up_uid)
	if files.is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_FILES)
	var entry: StoredFileEntry = files.pop_front()
	var job := FileTransferJob.new()
	job.quality = entry.quality
	job.size_bytes = GameValueBounds.size_bytes(entry.size_bytes)
	var up_speed := upload_speed_for(up_uid)
	job.duration = GameValueBounds.job_duration_from_bytes(job.size_bytes, up_speed)
	job.progress = 0.0
	job.file_type_id = entry.file_type_id
	job.title = entry.title
	job.apply_bounds()
	_data.get_upload_queue().append(job)
	_notify_queue_and_field()
	_host.log_message.emit("Выгрузка: %s..." % FileDefs.get_type_label(job.file_type_id))
	_host.stats_changed.emit()
	return GameOperationResult.ok()


func get_phase_label() -> String:
	var dl := not _data.get_download_queue().is_empty()
	var up := not _data.get_upload_queue().is_empty()
	if _data.get_phase() == GameStateData.Phase.SETTLING:
		return "Завершение выгрузки + скачивание" if dl else "Завершение выгрузки"
	if dl and up:
		return "Скачивание + выгрузка"
	if dl:
		return "Скачивание"
	if up:
		return "Выгрузка"
	return "Свободен"


func _tick_download_queue(delta: float) -> void:
	if _data.get_download_queue().is_empty():
		return
	var queue := _data.get_download_queue()
	var job: FileTransferJob = queue[0]
	job.progress = GameValueBounds.progress(job.progress + delta / job.duration)
	queue[0] = job
	if job.progress < 1.0:
		_host.blocks_progress_changed.emit()
		return
	queue.pop_front()
	if not _try_store_completed_download(job):
		queue.clear()
		_host.log_message.emit("Загрузчик переполнен: очередь скачивания очищена.")
		_host.queue_changed.emit()
		_host.field_changed.emit()
		_host.stats_changed.emit()
		return
	_host.field_changed.emit()
	_host.stats_changed.emit()


func _tick_upload_queue(delta: float) -> void:
	if _data.get_phase() != GameStateData.Phase.IDLE or _data.get_upload_queue().is_empty():
		return
	var queue := _data.get_upload_queue()
	var job: FileTransferJob = queue[0]
	job.progress = GameValueBounds.progress(job.progress + delta / job.duration)
	queue[0] = job
	if job.progress < 1.0:
		_host.blocks_progress_changed.emit()
		return
	queue.pop_front()
	_host.field_changed.emit()
	if _host.has_method("run_publish_pause"):
		_host.run_publish_pause(job)


func apply_publish(job: FileTransferJob) -> void:
	_data.add_uploaded_files(1)
	var diamonds_granted := _premium.grant_upload_reward()
	var revenue := GameValueBounds.money(
		job.size_bytes * GameConstants.REVENUE_PER_BYTE * job.quality
	)
	_data.set_uploader_balance(_data.get_uploader_balance() + revenue)
	_data.set_phase(GameStateData.Phase.SETTLING)
	_host.log_message.emit(
		"Выгружен %s: +$%.1f в загрузчик, +◆%d"
		% [FileDefs.get_type_label(job.file_type_id), revenue, diamonds_granted]
	)


func finish_publish_pause() -> void:
	_data.set_phase(GameStateData.Phase.IDLE)
	_notify_field_and_stats()


func cancel_file_transfer_queues() -> void:
	_return_upload_queue_to_storage()
	_data.get_download_queue().clear()
	if _data.get_phase() == GameStateData.Phase.SETTLING:
		_data.set_phase(GameStateData.Phase.IDLE)
	_notify_queue_and_field()


func _try_store_completed_download(job: FileTransferJob) -> bool:
	var chain := _wiring.get_file_chain()
	var up_uid: String = str(chain.get("uploader", ""))
	if up_uid == "" or not _storage.can_store_in_module(up_uid, 1):
		return false
	var stored := StoredFileEntry.new()
	stored.title = job.title
	stored.file_type_id = job.file_type_id
	stored.quality = job.quality
	stored.size_bytes = job.size_bytes
	stored.apply_bounds()
	_data.get_module_files(up_uid).append(stored)
	return true


func _return_upload_queue_to_storage() -> void:
	var chain := _wiring.get_file_chain()
	var up_uid: String = str(chain.get("uploader", ""))
	if up_uid == "":
		_data.get_upload_queue().clear()
		return
	for job: FileTransferJob in _data.get_upload_queue():
		var entry := StoredFileEntry.new()
		entry.title = job.title
		entry.file_type_id = job.file_type_id
		entry.quality = job.quality
		entry.size_bytes = job.size_bytes
		entry.apply_bounds()
		_data.get_module_files(up_uid).append(entry)
	_data.get_upload_queue().clear()


func _network_transfer_speed(is_download: bool) -> float:
	var chain := _wiring.get_file_chain()
	var net_uid: String = str(chain.get("network", ""))
	if net_uid == "":
		return 0.0
	return _speed_for_network_uid(net_uid, is_download)


func _speed_for_network_uid(network_uid: String, is_download: bool) -> float:
	var base := (
		GameConstants.BASE_DOWNLOAD_SPEED_BPS
		if is_download
		else GameConstants.BASE_UPLOAD_SPEED_BPS
	)
	var effect_key := "download_speed" if is_download else "upload_speed"
	var speed := (
		GameBonus.speed_scaled(base, "network", _field.get_instance_level(network_uid))
		* _data.get_env_multiplier(effect_key)
	)
	return GameValueBounds.speed_bps(speed)


func _notify_field_and_stats() -> void:
	_host.field_changed.emit()
	_host.stats_changed.emit()


func _notify_queue_and_field() -> void:
	_host.queue_changed.emit()
	_host.field_changed.emit()
