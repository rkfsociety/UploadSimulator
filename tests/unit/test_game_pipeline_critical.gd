extends RefCounted
## Критические сценарии пайплайна: переполнение очереди/загрузчика, разрыв цепочки, загрузка сейва.

var case_count := 6


func run() -> Array[String]:
	var errors: Array[String] = []
	_test_full_download_queue_drains(errors)
	_test_downloader_overflow_clears_pending_downloads(errors)
	_test_disconnect_cancels_active_transfer(errors)
	_test_save_load_restores_queues(errors)
	_test_tick_auto_enqueues_download(errors)
	_test_download_with_network_only(errors)
	return errors


func _test_download_with_network_only(errors: Array[String]) -> void:
	var stack := _make_stack()
	var data: GameStateData = stack.data
	var pipeline: GamePipelineService = stack.pipeline
	var wiring: GameWiringService = stack.wiring
	var uids := _wire_download_only(stack)
	if uids.is_empty():
		errors.append("скачивание без uploader: размещение")
		stack.host.free()
		return
	if not pipeline.check_enqueue_download().is_ok():
		errors.append("скачивание без uploader: check_enqueue_download")
	stack.host.free()


func _wire_download_only(stack: Dictionary) -> Dictionary:
	var field: GameFieldService = stack.field
	var wiring: GameWiringService = stack.wiring
	var data: GameStateData = stack.data
	data.add_block_stock("network", 1)
	data.add_block_stock("text_downloader", 1)
	var n := field.place_block("network", 0, 0)
	var d := field.place_block("text_downloader", 8, 0)
	if not n.is_ok() or not d.is_ok():
		return {}
	wiring.try_connect_ports(n.get_uid(), "net_out", d.get_uid(), "net_in")
	return {"network": n.get_uid(), "downloader": d.get_uid()}


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


func _test_full_download_queue_drains(errors: Array[String]) -> void:
	var stack := _make_stack()
	var data: GameStateData = stack.data
	var pipeline: GamePipelineService = stack.pipeline
	var uids := _wire_file_chain(stack)
	if uids.is_empty():
		errors.append("drain-тест: цепочка")
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
	while steps < 500:
		var had_work := false
		if not data.get_download_queue().is_empty():
			pipeline._tick_download_queue(0.02)
			had_work = true
		if not data.get_wire_transfers().is_empty():
			pipeline._tick_wire_transfers(0.02)
			had_work = true
		if not had_work:
			break
		steps += 1
	if not data.get_download_queue().is_empty() or not data.get_wire_transfers().is_empty():
		errors.append("полная очередь: после тика очередь и провода должны опустеть")
	var stored := data.get_module_files(uids.downloader).size()
	if stored != GameConstants.MAX_QUEUE_JOBS:
		errors.append(
			"полная очередь: в Text Downloader %d файлов, ожидалось %d" % [stored, GameConstants.MAX_QUEUE_JOBS]
		)
	stack.host.free()


func _test_downloader_overflow_clears_pending_downloads(errors: Array[String]) -> void:
	var stack := _make_stack()
	var data: GameStateData = stack.data
	var pipeline: GamePipelineService = stack.pipeline
	var uids := _wire_file_chain(stack)
	if uids.is_empty():
		errors.append("переполнение: цепочка")
		stack.host.free()
		return
	var cap := BlockDefs.max_stored_files("text_downloader")
	for _i in cap:
		var filler := StoredFileEntry.new()
		filler.size_bytes = 1000.0
		filler.apply_bounds()
		data.get_module_files(uids.downloader).append(filler)
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
	pipeline._tick_download_queue(0.05)
	pipeline._tick_wire_transfers(0.05)
	if not data.get_download_queue().is_empty():
		errors.append("переполнение Text Downloader: очередь скачивания должна очиститься")
	if data.get_module_files(uids.downloader).size() != cap:
		errors.append("переполнение Text Downloader: лишний файл не должен попасть внутрь")
	stack.host.free()


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
	wiring.disconnect_output_port(uids.network, "net_out")
	if not data.get_download_queue().is_empty():
		errors.append("после отключения сети очередь скачивания должна быть пуста")
	if not data.get_upload_queue().is_empty():
		errors.append("после отключения очередь выгрузки должна быть пуста")
	if not data.get_wire_transfers().is_empty():
		errors.append("после отключения передачи по проводам должны быть пусты")
	if data.get_phase() != GameStateData.Phase.IDLE:
		errors.append("после отключения фаза должна быть IDLE")
	stack.host.free()


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
	data.add_block_stock("network", 1)
	data.add_block_stock("text_downloader", 1)
	data.add_block_stock("uploader", 1)
	var n := field.place_block("network", 0, 0)
	var d := field.place_block("text_downloader", 8, 0)
	var u := field.place_block("uploader", 32, 0)
	if not n.is_ok() or not d.is_ok() or not u.is_ok():
		return {}
	wiring.try_connect_ports(n.get_uid(), "net_out", d.get_uid(), "net_in")
	wiring.try_connect_ports(d.get_uid(), "file_out", u.get_uid(), "file_in")
	wiring.try_connect_ports(u.get_uid(), "net_out", n.get_uid(), "net_in")
	return {
		"network": n.get_uid(),
		"downloader": d.get_uid(),
		"uploader": u.get_uid(),
	}


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
	signal wire_transfers_changed
	signal operation_failed(code: int, message: String)
