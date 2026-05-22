extends RefCounted
class_name GameStateEnvironment
## API улучшений среды (алмазы).

var _svc: GameEnvironmentService


func _init(svc: GameEnvironmentService) -> void:
	_svc = svc


func get_upgrade_level(upgrade_id: String) -> int:
	return _svc.get_upgrade_level(upgrade_id)


func diamond_cost(upgrade_id: String) -> int:
	return _svc.diamond_cost(upgrade_id)


func can_buy_upgrade(upgrade_id: String) -> bool:
	return _svc.can_buy_upgrade(upgrade_id)


func buy_upgrade(upgrade_id: String) -> bool:
	return _svc.buy_upgrade(upgrade_id)
