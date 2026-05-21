extends RefCounted
class_name GamePipelineService
## Очереди, запись, скачивание, выгрузка, сбор денег.

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
	_regen_energy(delta)
	_tick_active_phase(delta)
	_tick_download_queue(delta)
	_tick_upload_queue(delta)


func download_speed_for(uid: String) -> float:
	var inst := _field.get_instance(uid)
	return GameBonus.speed_scaled(
		GameConstants.BASE_DOWNLOAD_SPEED_MBPS, inst.type_id, inst.level
	)


func upload_speed_for(uid: String) -> float:
	var inst := _field.get_instance(uid)
	return GameBonus.speed_scaled(
		GameConstants.BASE_UPLOAD_SPEED_MBPS, inst.type_id, inst.level
	)


func studio_duration_for(uid: String) -> float:
	var inst := _field.get_instance(uid)
	return GameBonus.duration_scaled(
		GameConstants.STUDIO_BASE_DURATION_SEC, inst.type_id, inst.level
	)


func can_record() -> bool:
	return (
		_data.get_phase() == GameStateData.Phase.IDLE
		and _field.has_block_on_field("studio")
		and _any_studio_can_record()
	)


func can_record_at(uid: String) -> bool:
	if _field.get_instance_type(uid) != "studio" or _data.get_phase() != GameStateData.Phase.IDLE:
		return false
	return (
		_data.get_energy() >= GameConstants.RECORD_ENERGY_COST
		and _data.get_download_queue().size() < GameConstants.MAX_QUEUE_JOBS
		and _data.get_upload_queue().size() < GameConstants.MAX_QUEUE_JOBS
		and _storage.has_storage_space(GameConstants.RAW_FILE_MB)
	)


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
	if (
		_data.get_phase() != GameStateData.Phase.IDLE
		or chain.is_empty()
		or _data.get_recorded_files() <= 0
	):
		return false
	if _data.get_download_queue().size() >= GameConstants.MAX_QUEUE_JOBS:
		return false
	return _storage.has_storage_space(GameConstants.MIN_DOWNLOAD_RESERVE_MB)


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


func collect_money() -> bool:
	if not can_collect_money():
		return false
	var chain := _wiring.get_money_chain()
	var uid: String = chain.get("to_uid", "")
	var inst := _field.get_instance(uid)
	var bonus: float = GameBonus.effect_at_level("collector", inst.level)
	var payout: float = _data.get_uploader_balance() * (1.0 + bonus)
	_data.set_uploader_balance(0.0)
	_data.add_money(payout)
	_host.log_message.emit("Коллектор: $%.0f → касса" % payout)
	_notify_field_and_stats()
	return true


func start_recording_at(uid: String) -> bool:
	if not can_record_at(uid):
		return false
	_data.set_energy(_data.get_energy() - GameConstants.RECORD_ENERGY_COST)
	_data.set_recording_studio_uid(uid)
	_data.set_phase(GameStateData.Phase.RECORDING)
	_data.set_phase_progress(0.0)
	_data.set_phase_duration(studio_duration_for(uid))
	_notify_field_and_stats()
	_host.log_message.emit("Студия: запись...")
	return true


func run_block_action(uid: String) -> bool:
	match _field.get_instance_type(uid):
		"studio":
			return start_recording_at(uid)
		"downloader":
			return enqueue_download()
		"uploader":
			return enqueue_upload()
		"collector":
			return collect_money()
	return false


func enqueue_download() -> bool:
	if not can_enqueue_download():
		return false
	var chain := _wiring.get_file_chain()
	var dl_uid: String = chain.get("downloader", "")
	_data.add_recorded_files(-1)
	var title := _random_title()
	var dl_level := _field.get_instance_level(dl_uid)
	var quality := 1.0 + float(dl_level) * GameConstants.QUALITY_PER_DOWNLOADER_LEVEL
	var assets_mb := _rng.randf_range(
		GameConstants.DOWNLOAD_ASSETS_MB_MIN, GameConstants.DOWNLOAD_ASSETS_MB_MAX
	)
	var video_mb := _rng.randf_range(
		GameConstants.DOWNLOAD_VIDEO_MB_MIN, GameConstants.DOWNLOAD_VIDEO_MB_MAX
	) * quality
	var total_mb := assets_mb + video_mb
	if not _storage.has_storage_space(total_mb - GameConstants.RAW_FILE_MB):
		_data.add_recorded_files(1)
		_host.log_message.emit("Мало места на диске.")
		_host.stats_changed.emit()
		return false
	var job := FileTransferJob.new()
	job.title = title
	job.quality = quality
	job.size_mb = total_mb
	job.duration = assets_mb / download_speed_for(dl_uid)
	job.progress = 0.0
	_data.get_download_queue().append(job)
	_notify_queue_and_field()
	_host.log_message.emit("Скачивание «%s»..." % title)
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
	job.size_mb = entry.size_mb
	job.duration = entry.size_mb / upload_speed_for(up_uid)
	job.progress = 0.0
	job.title = entry.title
	_data.get_upload_queue().append(job)
	_notify_queue_and_field()
	_host.log_message.emit("Выгрузка «%s»..." % entry.title)
	_host.stats_changed.emit()
	return true


func get_phase_label() -> String:
	match _data.get_phase():
		GameStateData.Phase.RECORDING:
			return "Запись"
		GameStateData.Phase.PUBLISHED:
			return "Опубликовано"
		_:
			if not _data.get_download_queue().is_empty():
				return "Скачивание"
			if not _data.get_upload_queue().is_empty():
				return "Выгрузка"
			return "Свободен"


func _regen_energy(delta: float) -> void:
	if _data.get_phase() == GameStateData.Phase.RECORDING:
		return
	if _data.get_energy() < _data.get_max_energy():
		_data.set_energy(
			minf(_data.get_energy() + GameConstants.ENERGY_REGEN_PER_SEC * delta, _data.get_max_energy())
		)
		_host.stats_changed.emit()


func _tick_active_phase(delta: float) -> void:
	if _data.get_phase() == GameStateData.Phase.IDLE or _data.get_phase() == GameStateData.Phase.PUBLISHED:
		return
	_data.set_phase_progress(
		_data.get_phase_progress() + delta / maxf(_data.get_phase_duration(), GameConstants.MIN_JOB_DURATION_SEC)
	)
	_host.stats_changed.emit()
	_host.field_changed.emit()
	if _data.get_phase_progress() < 1.0:
		return
	_data.set_phase_progress(1.0)
	if _data.get_phase() == GameStateData.Phase.RECORDING:
		_data.add_recorded_files(1)
		_data.set_phase(GameStateData.Phase.IDLE)
		_data.set_phase_progress(0.0)
		_data.set_recording_studio_uid("")
		_host.field_changed.emit()
		_host.log_message.emit("Файл записан → загрузчик «На диск»")


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
	stored.quality = job.quality
	stored.size_mb = job.size_mb
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
	_data.add_published_files(1)
	var views := int(
		round(
			_rng.randi_range(GameConstants.PUBLISH_VIEWS_MIN, GameConstants.PUBLISH_VIEWS_MAX)
			* job.quality
		)
	)
	var revenue := float(views) * GameConstants.REVENUE_PER_VIEW
	_data.set_uploader_balance(_data.get_uploader_balance() + revenue)
	_data.set_phase(GameStateData.Phase.PUBLISHED)
	_host.log_message.emit("«%s» +$%.1f в аплоудер" % [job.title, revenue])


func finish_publish_pause() -> void:
	_data.set_phase(GameStateData.Phase.IDLE)
	_notify_field_and_stats()


func _any_studio_can_record() -> bool:
	for inst: BlockInstance in _data.get_placed_blocks():
		if inst.type_id == "studio" and can_record_at(inst.uid):
			return true
	return false


func _random_title() -> String:
	var topics: Array[String] = ["Обзор", "Гайд", "Влог", "Стрим"]
	var things: Array[String] = ["игры", "патча", "сетапа", "мода"]
	return "%s %s" % [
		topics[_rng.randi_range(0, topics.size() - 1)],
		things[_rng.randi_range(0, things.size() - 1)],
	]


func _notify_field_and_stats() -> void:
	_host.field_changed.emit()
	_host.stats_changed.emit()


func _notify_queue_and_field() -> void:
	_host.queue_changed.emit()
	_host.field_changed.emit()
