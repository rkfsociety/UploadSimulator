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


func can_enqueue_download() -> bool:
	return _svc.can_enqueue_download()


func can_enqueue_upload() -> bool:
	return _svc.can_enqueue_upload()


func can_collect_money() -> bool:
	return _svc.can_collect_money()


func collect_money(collector_uid: String) -> bool:
	return _svc.collect_money(collector_uid)


func run_block_action(uid: String) -> bool:
	return _svc.run_block_action(uid)


func enqueue_download() -> bool:
	return _svc.enqueue_download()


func enqueue_upload() -> bool:
	return _svc.enqueue_upload()


func get_phase_label() -> String:
	return _svc.get_phase_label()


func apply_publish(job: FileTransferJob) -> void:
	_svc.apply_publish(job)


func finish_publish_pause() -> void:
	_svc.finish_publish_pause()
