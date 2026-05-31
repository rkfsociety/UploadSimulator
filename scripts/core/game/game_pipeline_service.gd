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
	_tick_wire_transfers(delta)
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
	if _has_active_upload_transfer():
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
	var chain := _wiring.get_download_chain()
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
	var chain := _wiring.get_download_chain()
	if chain.is_empty():
		return (
			GameOperationResult
			. fail(
				GameOperationResult.Code.PIPELINE_NO_CHAIN,
				"Подключите Text Downloader к сети (net_out → net_in).",
			)
		)
	if _data.get_download_queue().size() >= GameConstants.MAX_QUEUE_JOBS:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_DOWNLOAD_QUEUE_FULL)
	var dl_uid: String = str(chain.get("downloader", ""))
	if not _storage.has_module_space(dl_uid, 1):
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_STORAGE)
	return GameOperationResult.ok()


func check_enqueue_upload() -> GameOperationResult:
	if _data.get_phase() != GameStateData.Phase.IDLE:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_PHASE_BUSY)
	var chain := _wiring.get_file_chain()
	if chain.is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_CHAIN)
	var dl_uid: String = str(chain.get("downloader", ""))
	if _data.get_module_files(dl_uid).is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_FILES)
	if _has_active_upload_transfer():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_PHASE_BUSY)
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
	var payout: float = safe
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
	var chain := _wiring.get_download_chain()
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
	var dl_uid: String = str(chain.get("downloader", ""))
	var up_uid: String = str(chain.get("uploader", ""))
	var net_uid: String = str(chain.get("network", ""))
	var files := _data.get_module_files(dl_uid)
	if files.is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_NO_FILES)
	var entry: StoredFileEntry = files.pop_front()
	var speed := download_speed_for(dl_uid)
	var duration := GameValueBounds.job_duration_from_bytes(entry.size_bytes, speed)
	var transfer := (
		WireFileTransfer
		. from_entry(
			WireFileTransfer.Purpose.TO_UPLOADER,
			dl_uid,
			"file_out",
			up_uid,
			"file_in",
			entry,
			duration,
		)
	)
	_data.get_wire_transfers().append(transfer)
	_notify_wire_transfers()
	_host.log_message.emit("Выгрузка: %s..." % FileDefs.get_type_label(transfer.file_type_id))
	_host.stats_changed.emit()
	return GameOperationResult.ok()


func get_phase_label() -> String:
	var dl := not _data.get_download_queue().is_empty()
	var up := _has_active_upload_transfer() or not _data.get_upload_queue().is_empty()
	var wire := not _data.get_wire_transfers().is_empty()
	if _data.get_phase() == GameStateData.Phase.SETTLING:
		return "Завершение выгрузки + скачивание" if dl else "Завершение выгрузки"
	if dl and up:
		return "Скачивание + выгрузка"
	if dl:
		return "Скачивание"
	if up:
		return "Выгрузка"
	if wire:
		return "Передача по проводу"
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
		_host.log_message.emit("Text Downloader переполнен: очередь скачивания очищена.")
		_host.queue_changed.emit()
		_host.field_changed.emit()
		_host.stats_changed.emit()
		return
	_host.field_changed.emit()
	_host.stats_changed.emit()


func _tick_wire_transfers(delta: float) -> void:
	var transfers := _data.get_wire_transfers()
	if transfers.is_empty():
		return
	var changed := false
	var i := 0
	while i < transfers.size():
		var transfer: WireFileTransfer = transfers[i]
		transfer.progress = GameValueBounds.progress(transfer.progress + delta / transfer.duration)
		transfers[i] = transfer
		if transfer.progress < 1.0:
			i += 1
			changed = true
			continue
		transfers.remove_at(i)
		_complete_wire_transfer(transfer)
		changed = true
	if changed:
		_notify_wire_transfers()


func _complete_wire_transfer(transfer: WireFileTransfer) -> void:
	match transfer.purpose:
		WireFileTransfer.Purpose.TO_UPLOADER:
			_start_network_upload_from_transit(transfer)
		WireFileTransfer.Purpose.TO_NETWORK:
			if _host.has_method("run_publish_pause"):
				_host.run_publish_pause(transfer.to_job())
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
	var diamonds_spawned := _spawn_diamond_pickup_for_upload()
	var revenue := GameValueBounds.money(
		job.size_bytes * GameConstants.REVENUE_PER_BYTE * job.quality
	)
	_data.set_uploader_balance(_data.get_uploader_balance() + revenue)
	_data.set_phase(GameStateData.Phase.SETTLING)
	if diamonds_spawned > 0:
		_host.log_message.emit(
			(
				"Выгружен %s: +$%.1f в загрузчик, ◆%d на карте (нажмите, чтобы собрать)"
				% [FileDefs.get_type_label(job.file_type_id), revenue, diamonds_spawned]
			)
		)
	else:
		_host.log_message.emit(
			"Выгружен %s: +$%.1f в загрузчик" % [FileDefs.get_type_label(job.file_type_id), revenue]
		)


func finish_publish_pause() -> void:
	_data.set_phase(GameStateData.Phase.IDLE)
	_notify_field_and_stats()


func cancel_file_transfer_queues() -> void:
	cancel_upload_transfers()
	cancel_download_queues()
	if _data.get_phase() == GameStateData.Phase.SETTLING:
		_data.set_phase(GameStateData.Phase.IDLE)
	_notify_queue_and_field()
	_notify_wire_transfers()


func cancel_download_queues() -> void:
	_data.get_download_queue().clear()
	_notify_queue_and_field()


func cancel_upload_transfers() -> void:
	_return_upload_queue_to_storage()
	_return_upload_wire_transfers_to_storage()
	if _data.get_phase() == GameStateData.Phase.SETTLING:
		_data.set_phase(GameStateData.Phase.IDLE)
	_notify_wire_transfers()
	_host.field_changed.emit()


func _try_store_completed_download(job: FileTransferJob) -> bool:
	var chain := _wiring.get_download_chain()
	var dl_uid: String = str(chain.get("downloader", ""))
	if dl_uid == "" or not _storage.can_store_in_module(dl_uid, 1):
		return false
	var stored := StoredFileEntry.new()
	stored.title = job.title
	stored.file_type_id = job.file_type_id
	stored.quality = job.quality
	stored.size_bytes = job.size_bytes
	stored.apply_bounds()
	_data.get_module_files(dl_uid).append(stored)
	return true


func _start_network_upload_from_transit(transfer: WireFileTransfer) -> void:
	var chain := _wiring.get_file_chain()
	var up_uid: String = str(chain.get("uploader", ""))
	var net_uid: String = str(chain.get("network", ""))
	if up_uid == "" or net_uid == "":
		_restore_wire_transfer_to_downloader(transfer)
		return
	var up_speed := upload_speed_for(up_uid)
	var duration := GameValueBounds.job_duration_from_bytes(transfer.size_bytes, up_speed)
	var entry := StoredFileEntry.new()
	entry.title = transfer.title
	entry.file_type_id = transfer.file_type_id
	entry.quality = transfer.quality
	entry.size_bytes = transfer.size_bytes
	entry.apply_bounds()
	var net_transfer := (
		WireFileTransfer
		. from_entry(
			WireFileTransfer.Purpose.TO_NETWORK,
			up_uid,
			"net_out",
			net_uid,
			"net_in",
			entry,
			duration,
		)
	)
	_data.get_wire_transfers().append(net_transfer)
	_notify_wire_transfers()


func _restore_wire_transfer_to_downloader(transfer: WireFileTransfer) -> void:
	var dl_uid := transfer.from_uid
	if dl_uid == "":
		return
	var entry := StoredFileEntry.new()
	entry.title = transfer.title
	entry.file_type_id = transfer.file_type_id
	entry.quality = transfer.quality
	entry.size_bytes = transfer.size_bytes
	entry.apply_bounds()
	_data.get_module_files(dl_uid).insert(0, entry)


func _return_upload_wire_transfers_to_storage() -> void:
	var chain := _wiring.get_file_chain()
	var dl_uid: String = str(chain.get("downloader", ""))
	if dl_uid == "":
		return
	var transfers := _data.get_wire_transfers()
	for i in range(transfers.size() - 1, -1, -1):
		var transfer: WireFileTransfer = transfers[i]
		if (
			transfer.purpose != WireFileTransfer.Purpose.TO_NETWORK
			and transfer.purpose != WireFileTransfer.Purpose.TO_UPLOADER
		):
			continue
		var entry := StoredFileEntry.new()
		entry.title = transfer.title
		entry.file_type_id = transfer.file_type_id
		entry.quality = transfer.quality
		entry.size_bytes = transfer.size_bytes
		entry.apply_bounds()
		_data.get_module_files(dl_uid).insert(0, entry)
		transfers.remove_at(i)


func _return_upload_queue_to_storage() -> void:
	var chain := _wiring.get_file_chain()
	var dl_uid: String = str(chain.get("downloader", ""))
	if dl_uid == "":
		_data.get_upload_queue().clear()
		return
	for job: FileTransferJob in _data.get_upload_queue():
		var entry := StoredFileEntry.new()
		entry.title = job.title
		entry.file_type_id = job.file_type_id
		entry.quality = job.quality
		entry.size_bytes = job.size_bytes
		entry.apply_bounds()
		_data.get_module_files(dl_uid).append(entry)
	_data.get_upload_queue().clear()


func _has_active_upload_transfer() -> bool:
	var chain := _wiring.get_file_chain()
	var up_uid: String = str(chain.get("uploader", ""))
	if up_uid == "":
		return false
	if _data.find_upload_wire_transfer(up_uid) != null:
		return true
	for transfer: WireFileTransfer in _data.get_wire_transfers():
		if transfer.purpose == WireFileTransfer.Purpose.TO_UPLOADER:
			return true
	return false


func _notify_wire_transfers() -> void:
	_host.blocks_progress_changed.emit()
	if _host.has_signal("wire_transfers_changed"):
		_host.wire_transfers_changed.emit()


func _network_transfer_speed(is_download: bool) -> float:
	if is_download:
		var chain := _wiring.get_download_chain()
		var net_uid: String = str(chain.get("network", ""))
		if net_uid == "":
			return 0.0
		return _speed_for_network_uid(net_uid, true)
	var chain := _wiring.get_file_chain()
	var net_uid: String = str(chain.get("network", ""))
	if net_uid == "":
		return 0.0
	return _speed_for_network_uid(net_uid, false)


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


func _spawn_diamond_pickup_for_upload() -> int:
	var chain := _wiring.get_file_chain()
	var up_uid: String = str(chain.get("uploader", ""))
	if up_uid != "":
		var inst := _field.get_instance(up_uid)
		if inst.is_valid():
			var origin := GridDefs.cell_to_pixel(inst.gx, inst.gy)
			var sz := GridDefs.block_pixel_size(inst.type_id)
			var center := origin + sz * 0.5
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var offset := Vector2(rng.randf_range(-28.0, 28.0), rng.randf_range(-52.0, -8.0))
			return _premium.spawn_upload_pickup(center + offset)
	return _premium.spawn_upload_pickup(GridDefs.world_center_pixel())


func _notify_field_and_stats() -> void:
	_host.field_changed.emit()
	_host.stats_changed.emit()


func _notify_queue_and_field() -> void:
	_host.queue_changed.emit()
	_host.field_changed.emit()
