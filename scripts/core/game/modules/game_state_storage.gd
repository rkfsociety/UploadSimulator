extends RefCounted
class_name GameStateStorage
## Ёмкость и занятость диска.

var _svc: GameStorageService


func _init(svc: GameStorageService) -> void:
	_svc = svc


func get_storage_capacity_bytes() -> float:
	return _svc.get_storage_capacity_bytes()


func get_storage_used_bytes() -> float:
	return _svc.get_storage_used_bytes()


func has_storage_space(for_bytes: float) -> bool:
	return _svc.has_storage_space(for_bytes)


func get_storage_free_bytes() -> float:
	return _svc.get_storage_free_bytes()
