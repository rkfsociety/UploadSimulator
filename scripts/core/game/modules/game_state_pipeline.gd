extends RefCounted
class_name GameStatePipeline
## Очереди: скачивание, выгрузка, сбор денег.

var _svc: GamePipelineService


func _init(svc: GamePipelineService) -> void:
	_svc = svc


func can_download_at(uid: String) -> bool:
	return _svc.can_download_at(uid)


func can_upload_at(uid: String) -> bool:
	return _svc.can_upload_at(uid)


func can_collect_at(uid: String) -> bool:
	return _svc.can_collect_at(uid)


func check_download_at(uid: String) -> GameOperationResult:
	return _svc.check_download_at(uid)


func check_upload_at(uid: String) -> GameOperationResult:
	return _svc.check_upload_at(uid)


func check_collect_at(uid: String) -> GameOperationResult:
	return _svc.check_collect_at(uid)


func check_enqueue_download() -> GameOperationResult:
	return _svc.check_enqueue_download()


func check_enqueue_upload() -> GameOperationResult:
	return _svc.check_enqueue_upload()


func check_collect_money() -> GameOperationResult:
	return _svc.check_collect_money()


func can_enqueue_download() -> bool:
	return _svc.can_enqueue_download()


func can_enqueue_upload() -> bool:
	return _svc.can_enqueue_upload()


func can_collect_money() -> bool:
	return _svc.can_collect_money()


func collect_money(collector_uid: String) -> GameOperationResult:
	return _svc.collect_money(collector_uid)


func run_block_action(uid: String) -> GameOperationResult:
	return _svc.run_block_action(uid)


func enqueue_download() -> GameOperationResult:
	return _svc.enqueue_download()


func enqueue_upload() -> GameOperationResult:
	return _svc.enqueue_upload()


func get_phase_label() -> String:
	return _svc.get_phase_label()


func apply_publish(job: FileTransferJob) -> void:
	_svc.apply_publish(job)


func finish_publish_pause() -> void:
	_svc.finish_publish_pause()


func network_download_speed(network_uid: String) -> float:
	return _svc.network_download_speed(network_uid)


func network_upload_speed(network_uid: String) -> float:
	return _svc.network_upload_speed(network_uid)
