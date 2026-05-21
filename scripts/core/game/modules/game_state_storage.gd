extends RefCounted
class_name GameStateStorage
## Ёмкость и занятость диска.

var _svc: GameStorageService


func _init(svc: GameStorageService) -> void:
	_svc = svc


func get_storage_capacity_mb() -> float:
	return _svc.get_storage_capacity_mb()


func get_storage_used_mb() -> float:
	return _svc.get_storage_used_mb()


func has_storage_space(for_mb: float) -> bool:
	return _svc.has_storage_space(for_mb)


func get_storage_free_mb() -> float:
	return _svc.get_storage_free_mb()
