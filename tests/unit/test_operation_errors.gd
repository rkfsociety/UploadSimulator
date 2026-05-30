extends RefCounted
## Коды ошибок пайплайна и поля.

var case_count := 4


func run() -> Array[String]:
	var errors: Array[String] = []
	var host := _TestHost.new()
	var data := GameStateData.new()
	var field := GameFieldService.new(data, host)
	var wiring := GameWiringService.new(data, host, field)
	var storage := GameStorageService.new(data, field)
	var premium := PremiumCurrencyService.new(host, data)
	var pipeline := GamePipelineService.new(data, host, field, wiring, storage, premium)
	_test_buy_no_money(errors, field, data)
	_test_download_queue_full(errors, data, field, wiring, pipeline)
	_test_file_type(errors)
	_test_place_occupied(errors, host)
	return errors


func _test_buy_no_money(
	errors: Array[String], field: GameFieldService, data: GameStateData
) -> void:
	# Свежая GameStateData стартует с кассой = стоимость набора ($315) — обнуляем для теста
	data.set_money(0.0)
	var check := field.check_buy_block("text_downloader")
	if check.is_ok():
		errors.append("покупка без денег должна падать")
	elif check.code != GameOperationResult.Code.FIELD_INSUFFICIENT_MONEY:
		errors.append("код покупки без денег")


func _test_download_queue_full(
	errors: Array[String],
	data: GameStateData,
	field: GameFieldService,
	wiring: GameWiringService,
	pipeline: GamePipelineService,
) -> void:
	data.add_block_stock("network", 1)
	data.add_block_stock("text_downloader", 1)
	data.add_block_stock("uploader", 1)
	var n := field.place_block("network", 0, 0)
	var d := field.place_block("text_downloader", 8, 0)
	var u := field.place_block("uploader", 32, 0)
	if not n.is_ok() or not d.is_ok() or not u.is_ok():
		errors.append("размещение модулей для очереди")
		return
	wiring.try_connect_ports(n.get_uid(), "net_out", d.get_uid(), "net_in")
	wiring.try_connect_ports(d.get_uid(), "file_out", u.get_uid(), "file_in")
	wiring.try_connect_ports(u.get_uid(), "net_out", n.get_uid(), "net_in")
	for _i in GameConstants.MAX_QUEUE_JOBS:
		var job := FileTransferJob.new()
		job.size_bytes = 100.0
		job.duration = 1.0
		data.get_download_queue().append(job)
	var check := pipeline.check_enqueue_download()
	if check.is_ok():
		errors.append("полная очередь скачивания должна блокировать")
	elif check.code != GameOperationResult.Code.PIPELINE_DOWNLOAD_QUEUE_FULL:
		errors.append("код полной очереди скачивания")


func _test_file_type(errors: Array[String]) -> void:
	if FileDefs.is_downloadable_type("text"):
		pass
	else:
		errors.append("text должен быть доступен")
	if FileDefs.is_downloadable_type("image"):
		errors.append("image пока не для скачивания")
	var unsupported := GameOperationResult.fail(GameOperationResult.Code.FILE_TYPE_UNSUPPORTED)
	if unsupported.get_message().is_empty():
		errors.append("сообщение FILE_TYPE_UNSUPPORTED")


func _test_place_occupied(errors: Array[String], host: Node) -> void:
	# Изоляция: своё поле, чтобы клетки не были заняты из предыдущих подтестов
	var data := GameStateData.new()
	var field := GameFieldService.new(data, host)
	data.add_block_stock("uploader", 2)
	var first := field.place_block("uploader", 0, 0)
	if not first.is_ok():
		errors.append("первый uploader")
		return
	var second := field.check_place_block("uploader", 0, 0)
	if second.is_ok():
		errors.append("вторая установка в занятую клетку")
	elif second.code != GameOperationResult.Code.FIELD_CELL_OCCUPIED:
		errors.append("код занятой клетки")


class _TestHost:
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
