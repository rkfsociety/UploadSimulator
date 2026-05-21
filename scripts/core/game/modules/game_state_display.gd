extends RefCounted
class_name GameStateDisplay
## Метрики и UI-состояние блоков на поле.

var _svc: GameDisplayService


func _init(svc: GameDisplayService) -> void:
	_svc = svc


func get_instance_status_line(uid: String) -> String:
	return _svc.get_instance_status_line(uid)


func get_block_metric(uid: String) -> String:
	return _svc.get_block_metric(uid)


func get_block_display(uid: String) -> Dictionary:
	return _svc.get_block_display(uid)
