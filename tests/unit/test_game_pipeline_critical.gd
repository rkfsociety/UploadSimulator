extends RefCounted
## Критические сценарии пайплайна: переполнение очереди/диска, разрыв цепочки, загрузка сейва.

var case_count := 5


func run() -> Array[String]:
	var errors: Array[String] = []
	_test_full_download_queue_drains(errors)
	_test_storage_overflow_clears_pending_downloads(errors)
	_test_disconnect_cancels_active_transfer(errors)
	_test_save_load_restores_queues(errors)
	_test_tick_auto_enqueues_download(errors)
	return errors


## Автоскачивание: при собранной цепочке tick сам ставит задачу в очередь без кнопки.
func _test_tick_auto_enqueues_download(errors: Array[String]) -> void:
	var stack := _make_stack()
	var data: GameStateData = stack.data
	var pipeline: GamePipelineService = stack.pipeline
	if _wire_file_chain(stack).is_empty():
		errors.append("автоскачивание: размещение цепочки")
		stack.host.free()
		return
	if not data.get_download_queue().is_empty():
		errors.append("автоскачивание: очередь должна быть пуста до тика")
	pipeline.tick(0.0)
	if data.get_download_queue().size() != 1:
		errors.append("автоскачивание: tick должен поставить ровно одну задачу")
	stack.host.free()


## Полная очередь скачивания: активные задачи доигрываются до конца (FIFO).
func _test_full_download_queue_drains(errors: Array[String]) -> void:
	var stack := _make_stack()
	var data: GameStateData = stack.data
	var field: GameFieldService = stack.field
	var pipeline: GamePipelineService = stack.pipeline
	# Без хранилища на поле ёмкость диска = 0 — файлы не сохранятся
	data.add_block_stock("storage", 1)
	if not field.place_block("storage", 0, 0).is_ok():
		errors.append("place_block storage для drain-теста")
		stack.host.free()
		return
	for _i in GameConstants.MAX_QUEUE_JOBS:
		var job := FileTransferJob.new()
		job.size_bytes = 40.0
		job.duration = 0.02
		job.progress = 0.0
		job.apply_bounds()
		data.get_download_queue().append(job)
	var steps := 0
	while not data.get_download_queue().is_empty() and steps < 500:
		pipeline.tick(0.02)
		steps += 1
	if not data.get_download_queue().is_empty():
		errors.append("полная очередь: после тика очередь должна опустеть")
	if data.get_stored_files().size() != GameConstants.MAX_QUEUE_JOBS:
		errors.append(
			"полная очередь: на диске %d файлов, ожидалось %d"
			% [data.get_stored_files().size(), GameConstants.MAX_QUEUE_JOBS]
		)
	stack.host.free()


## Нет хранилища: завершённый файл некуда класть — ожидающие задачи сбрасываются.
func _test_storage_overflow_clears_pending_downloads(errors: Array[String]) -> void:
	var stack := _make_stack()
	var data: GameStateData = stack.data
	var pipeline: GamePipelineService = stack.pipeline
	# Хранилище на поле не размещено → вместимость 0 файлов
	var filler := StoredFileEntry.new()
	filler.size_bytes = 1000.0
	filler.apply_bounds()
	data.get_stored_files().append(filler)
	var finishing := FileTransferJob.new()
	finishing.size_bytes = 200.0
	finishing.duration = 0.01
	finishing.progress = 0.99
	finishing.apply_bounds()
	data.get_download_queue().append(finishing)
	var waiting := FileTransferJob.new()
	waiting.size_bytes = 100.0
	waiting.duration = 1.0
	waiting.progress = 0.0
	waiting.apply_bounds()
	data.get_download_queue().append(waiting)
	pipeline.tick(0.05)
	if not data.get_download_queue().is_empty():
		errors.append("переполнение диска: очередь скачивания должна очиститься")
	if data.get_stored_files().size() != 1:
		errors.append("переполнение диска: лишний файл не должен попасть на диск")
	stack.host.free()


## Отключение провода во время передачи сбрасывает очереди файлов.
func _test_disconnect_cancels_active_transfer(errors: Array[String]) -> void:
	var stack := _make_stack()
	var data: GameStateData = stack.data
	var wiring: GameWiringService = stack.wiring
	var pipeline: GamePipelineService = stack.pipeline
	var uids := _wire_file_chain(stack)
	if uids.is_empty():
		errors.append("размещение цепочки для отключения")
		stack.host.free()
		return
	var job := FileTransferJob.new()
	job.size_bytes = 500.0
	job.duration = 2.0
	job.progress = 0.4
	job.apply_bounds()
	data.get_download_queue().append(job)
	wiring.disconnect_output_port(uids.downloader, "file_out")
	if not data.get_download_queue().is_empty():
		errors.append("после отключения загрузчика очередь скачивания должна быть пуста")
	if not data.get_upload_queue().is_empty():
		errors.append("после отключения очередь выгрузки должна быть пуста")
	if data.get_phase() != GameStateData.Phase.IDLE:
		errors.append("после отключения фаза должна быть IDLE")
	stack.host.free()


## Сохранение и загрузка восстанавливают очереди и прогресс задач.
func _test_save_load_restores_queues(errors: Array[String]) -> void:
	var host := _PipelineTestHost.new()
	var data := GameStateData.new()
	var premium := PremiumCurrencyService.new(host)
	var backend := MemorySaveBackend.new()
	var save_svc := GameSaveService.new(data, premium, host, backend)
	var dl_job := FileTransferJob.new()
	dl_job.title = "test.txt"
	dl_job.size_bytes = 800.0
	dl_job.duration = 3.0
	dl_job.progress = 0.35
	dl_job.apply_bounds()
	data.get_download_queue().append(dl_job)
	var up_job := FileTransferJob.new()
	up_job.title = "up.txt"
	up_job.size_bytes = 400.0
	up_job.duration = 2.0
	up_job.progress = 0.1
	up_job.apply_bounds()
	data.get_upload_queue().append(up_job)
	data.set_phase(GameStateData.Phase.IDLE)
	if not save_svc.save("critical"):
		errors.append("save critical slot")
		host.free()
		return
	var loaded_data := GameStateData.new()
	var loaded_premium := PremiumCurrencyService.new(host, 0)
	var load_svc := GameSaveService.new(loaded_data, loaded_premium, host, backend)
	if not load_svc.load("critical"):
		errors.append("load critical slot")
		host.free()
		return
	if loaded_data.get_download_queue().size() != 1:
		errors.append("load: размер download_queue")
	elif not is_equal_approx(loaded_data.get_download_queue()[0].progress, 0.35):
		errors.append("load: progress download_queue")
	if loaded_data.get_upload_queue().size() != 1:
		errors.append("load: размер upload_queue")
	elif not is_equal_approx(loaded_data.get_upload_queue()[0].progress, 0.1):
		errors.append("load: progress upload_queue")
	host.free()


func _make_stack() -> Dictionary:
	var host := _PipelineTestHost.new()
	var data := GameStateData.new()
	var field := GameFieldService.new(data, host)
	var wiring := GameWiringService.new(data, host, field)
	var storage := GameStorageService.new(data, field)
	var premium := PremiumCurrencyService.new(host)
	var pipeline := GamePipelineService.new(data, host, field, wiring, storage, premium)
	wiring.bind_pipeline(pipeline)
	return {
		"host": host,
		"data": data,
		"field": field,
		"wiring": wiring,
		"storage": storage,
		"premium": premium,
		"pipeline": pipeline,
	}


func _wire_file_chain(stack: Dictionary) -> Dictionary:
	var field: GameFieldService = stack.field
	var wiring: GameWiringService = stack.wiring
	var data: GameStateData = stack.data
	data.add_block_stock("downloader", 1)
	data.add_block_stock("storage", 1)
	data.add_block_stock("uploader", 1)
	var d := field.place_block("downloader", 0, 0)
	var s := field.place_block("storage", 12, 0)
	var u := field.place_block("uploader", 24, 0)
	if not d.is_ok() or not s.is_ok() or not u.is_ok():
		return {}
	wiring.try_connect_ports(d.get_uid(), "file_out", s.get_uid(), "file_in")
	wiring.try_connect_ports(s.get_uid(), "file_out", u.get_uid(), "file_in")
	return {"downloader": d.get_uid(), "storage": s.get_uid(), "uploader": u.get_uid()}


class _PipelineTestHost:
	extends Node

	signal log_message(text: String)
	signal wiring_changed
	signal field_changed
	signal stats_changed
	signal block_purchased(type_id: String)
	signal placement_requested(type_id: String)
	signal queue_changed
	signal blocks_progress_changed
	signal operation_failed(code: int, message: String)
