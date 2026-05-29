extends RefCounted
class_name GameStateStorage
## Вместимость и занятость диска (в штуках файлов).

var _svc: GameStorageService


func _init(svc: GameStorageService) -> void:
	_svc = svc


func get_storage_capacity_files() -> float:
	return _svc.get_storage_capacity_files()


func get_storage_used_files() -> int:
	return _svc.get_storage_used_files()


func has_storage_space(count: int = 1) -> bool:
	return _svc.has_storage_space(count)


func get_storage_free_files() -> float:
	return _svc.get_storage_free_files()
