extends RefCounted
class_name GameStateEnvironment
## API улучшений (алмазы).

var _svc: GameEnvironmentService


func _init(svc: GameEnvironmentService) -> void:
	_svc = svc


func get_upgrade_level(upgrade_id: String) -> int:
	return _svc.get_upgrade_level(upgrade_id)


func diamond_cost(upgrade_id: String) -> int:
	return _svc.diamond_cost(upgrade_id)


func can_buy_upgrade(upgrade_id: String) -> bool:
	return _svc.can_buy_upgrade(upgrade_id)


func check_buy_upgrade(upgrade_id: String) -> GameOperationResult:
	return _svc.check_buy_upgrade(upgrade_id)


func buy_upgrade(upgrade_id: String) -> GameOperationResult:
	return _svc.buy_upgrade(upgrade_id)


func is_module_unlocked(type_id: String) -> bool:
	return _svc.is_module_unlocked(type_id)


func module_unlock_diamond_cost(type_id: String) -> int:
	return _svc.module_unlock_diamond_cost(type_id)


func can_unlock_module(type_id: String) -> bool:
	return _svc.can_unlock_module(type_id)


func check_unlock_module(type_id: String) -> GameOperationResult:
	return _svc.check_unlock_module(type_id)


func unlock_module(type_id: String) -> GameOperationResult:
	return _svc.unlock_module(type_id)


func get_lockable_module_type_ids() -> Array[String]:
	return _svc.get_lockable_module_type_ids()
